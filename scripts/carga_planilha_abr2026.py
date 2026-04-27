"""
Carga da planilha OUCAE → tabelas `proposta` e `certidao` (PostgreSQL).

Planilha : docs/estudo_cepac.ods  aba "Dados"
Banco     : DATABASE_URL em .env (psycopg2, síncrono)

Comportamento (duas fases):

  FASE 1 — PROPOSTA (uma linha por AE-XXXX)
    Para cada código único, seleciona a linha "representativa":
      1. Se existe linha com SITUACAO = 'VALIDA'    → a mais recente por DATA CERTIDAO
      2. Se existe linha com SITUACAO = 'ANALISE'   → a mais recente por DATA CERTIDAO
      3. Senão (CANCELADA ou sem data)              → a mais recente por DATA CERTIDAO
    UPSERT na tabela proposta com campos do nível do empreendimento.

  FASE 2 — CERTIDÃO (uma linha por linha da planilha)
    Para cada linha, UPSERT na tabela certidao.
    ON CONFLICT em numero_certidao.
    Linhas sem número de certidão recebem fallback ({codigo}-{idx}).

Ao final imprime:
  - Propostas inseridas / atualizadas
  - Certidões inseridas / atualizadas / puladas
  - Contagem por situação no banco

Uso:
    python scripts/carga_planilha_abr2026.py

    # Produção (Azure):
    DATABASE_URL="postgresql+asyncpg://cepacadmin:SENHA@cepac-pgdb.postgres.database.azure.com:5432/cepac?ssl=require" \\
        python scripts/carga_planilha_abr2026.py
"""
from __future__ import annotations

import logging
import os
import re
import sys
from collections import defaultdict
from datetime import date
from decimal import Decimal, InvalidOperation
from pathlib import Path

# ---------------------------------------------------------------------------
# Dependências externas (odfpy + psycopg2)
# ---------------------------------------------------------------------------
try:
    from odf.opendocument import load
    from odf.table import Table, TableRow, TableCell
    from odf.text import P as OdfP
except ImportError:
    print("ERRO: instale odfpy →  pip install odfpy", file=sys.stderr)
    sys.exit(1)

try:
    import psycopg2
    import psycopg2.extras
except ImportError:
    print("ERRO: instale psycopg2 →  pip install psycopg2-binary", file=sys.stderr)
    sys.exit(1)

# ---------------------------------------------------------------------------
# Configuração de logging
# ---------------------------------------------------------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger("carga_proposta")

# ---------------------------------------------------------------------------
# Caminhos
# ---------------------------------------------------------------------------
SCRIPT_DIR = Path(__file__).parent
REPO_ROOT = SCRIPT_DIR.parent
ODS_PATH = REPO_ROOT / "docs" / "estudo_cepac.ods"
ENV_PATH = REPO_ROOT / ".env"

HEADER_COUNT = 33  # colunas válidas (0-32); 33+ são vazias/auxiliares

# ---------------------------------------------------------------------------
# Mapeamentos de enums
# ---------------------------------------------------------------------------
STATUS_PA_MAP: dict[str, str] = {
    "ANALISE":    "ANALISE",
    "DEFERIDO":   "DEFERIDO",
    "INDEFERIDO": "INDEFERIDO",
}

REQUERIMENTO_MAP: dict[str, str] = {
    "VINCULACAO":    "VINCULACAO",
    "ALTERACAO":     "ALTERACAO",
    "DESVINCULACAO": "DESVINCULACAO",
}

SITUACAO_MAP: dict[str, str] = {
    "ANALISE":   "ANALISE",
    "VALIDA":    "VALIDA",
    "CANCELADA": "CANCELADA",
}

# Prioridade para seleção de linha representativa (menor índice = maior prioridade)
SITUACAO_PRIORIDADE: dict[str, int] = {
    "VALIDA":    0,
    "ANALISE":   1,
    "CANCELADA": 2,
}

# Valor do enum tipo_certidao_enum no banco (com cedilha/acento conforme migration 003)
TIPO_CERTIDAO_VINCULACAO = "VINCULAÇÃO"

# ---------------------------------------------------------------------------
# Leitura do .env
# ---------------------------------------------------------------------------

def load_env(env_path: Path) -> None:
    """Carrega pares KEY=VALUE do .env no os.environ (sem sobrescrever)."""
    if not env_path.exists():
        return
    with env_path.open() as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, _, value = line.partition("=")
            key = key.strip()
            value = value.strip().strip('"').strip("'")
            if key and key not in os.environ:
                os.environ[key] = value


# ---------------------------------------------------------------------------
# Helpers de parsing
# ---------------------------------------------------------------------------

def _cell_value(cell) -> str:
    """Extrai texto de uma célula ODF."""
    parts: list[str] = []
    for p in cell.getElementsByType(OdfP):
        text = str(p)
        if text:
            parts.append(text)
    return " ".join(parts).strip()


def read_sheet(doc, sheet_name: str) -> list[list[str]]:
    """Lê todas as linhas de uma aba, expandindo repeat de células."""
    for sheet in doc.spreadsheet.getElementsByType(Table):
        if sheet.getAttribute("name") == sheet_name:
            rows: list[list[str]] = []
            for row in sheet.getElementsByType(TableRow):
                cells: list[str] = []
                for cell in row.getElementsByType(TableCell):
                    repeat = cell.getAttribute("numbercolumnsrepeated")
                    repeat = int(repeat) if repeat else 1
                    val = _cell_value(cell)
                    # Bloco gigante de células vazias no fim — comprime para 1
                    if repeat > 20 and val == "":
                        cells.append(val)
                    else:
                        for _ in range(repeat):
                            cells.append(val)
                rows.append(cells)
            return rows
    log.error("Aba '%s' não encontrada no ODS.", sheet_name)
    return []


def or_none(value: str) -> str | None:
    """Retorna None se string vazia, senão retorna a string limpa."""
    v = value.strip()
    return v if v else None


def clean_semicolon(value: str) -> str | None:
    """Remove ponto-e-vírgula(s) no final e espaços extras."""
    v = value.strip().rstrip(";").strip()
    return v if v else None


def parse_decimal_ptbr(value: str) -> Decimal | None:
    """
    Converte número PT-BR (ponto como milhar, vírgula como decimal) para Decimal.
    Exemplos: "4.977,32" → Decimal("4977.32")  |  "0,00" → Decimal("0.00")
    """
    v = value.strip()
    if not v:
        return None
    v = v.replace(".", "").replace(",", ".")
    try:
        return Decimal(v)
    except InvalidOperation:
        return None


def parse_integer_ptbr(value: str) -> int | None:
    """
    Converte inteiro PT-BR (pode ter ponto de milhar) para int.
    Exemplos: "2.291" → 2291  |  "0" → 0
    """
    v = value.strip()
    if not v:
        return None
    v = v.replace(".", "").replace(",", "")
    try:
        return int(v)
    except ValueError:
        return None


def parse_date(value: str) -> date | None:
    """
    Parse de data DD/MM/AAAA com dia e mês sem zero à esquerda aceitos.
    Exemplos: "18/11/2025" → date(2025,11,18)  |  "3/2/2026" → date(2026,2,3)
    """
    v = value.strip()
    if not v:
        return None
    m = re.fullmatch(r"(\d{1,2})/(\d{1,2})/(\d{4})", v)
    if not m:
        return None
    try:
        return date(int(m.group(3)), int(m.group(2)), int(m.group(1)))
    except ValueError:
        return None


def detect_tipo_processo(pa16: str, pa12: str) -> tuple[str | None, str | None]:
    """
    Retorna (numero_pa, tipo_processo).
    SEI = 16 dígitos (formato XXXX.XXXX/XXXXXXX-X)
    SIMPROC = 12 dígitos (formato antigo)
    """
    sei = pa16.strip()
    simproc = pa12.strip()
    if sei:
        return sei, "SEI"
    if simproc:
        return simproc, "SIMPROC"
    return None, None


# ---------------------------------------------------------------------------
# DATABASE_URL — converte formato SQLAlchemy / asyncpg → psycopg2
# ---------------------------------------------------------------------------

def get_dsn() -> tuple[str, dict]:
    """
    Lê DATABASE_URL do ambiente.
    Aceita formato SQLAlchemy (postgresql+asyncpg://...) ou DSN puro.

    Retorna (dsn, connect_kwargs) onde connect_kwargs pode conter
    sslmode='require' quando ?ssl=require está presente.
    """
    raw = os.environ.get("DATABASE_URL", "")
    if not raw:
        raise RuntimeError(
            "DATABASE_URL não encontrada. "
            "Defina em .env ou exporte a variável de ambiente."
        )

    # Normalizar prefixo para psycopg2
    dsn = re.sub(r"^postgresql\+asyncpg://", "postgresql://", raw)

    connect_kwargs: dict = {}
    if "ssl=require" in dsn or "sslmode=require" in dsn:
        dsn = re.sub(r"[?&]ssl=require", "", dsn)
        dsn = re.sub(r"[?&]sslmode=require", "", dsn)
        dsn = re.sub(r"\?$", "", dsn)
        connect_kwargs["sslmode"] = "require"

    # Senhas com '@' quebram o parsing de URL — usar psycopg2.connect(**params)
    # Parse manual via urllib para lidar com '@' na senha
    from urllib.parse import urlparse, unquote
    parsed = urlparse(dsn)
    if parsed.hostname:
        pg_kwargs = {
            "host": parsed.hostname,
            "port": parsed.port or 5432,
            "dbname": parsed.path.lstrip("/"),
            "user": unquote(parsed.username or ""),
            "password": unquote(parsed.password or ""),
        }
        pg_kwargs.update(connect_kwargs)
        return "", pg_kwargs  # dsn vazio → usar só kwargs

    return dsn, connect_kwargs


# ---------------------------------------------------------------------------
# Seleção da linha representativa de um AE-XXXX
# ---------------------------------------------------------------------------

def _selecionar_representativa(
    linhas: list[tuple[int, list[str]]],
    cell_fn,
) -> list[str]:
    """
    Dado um grupo de linhas do mesmo AE-XXXX, retorna a linha representativa.

    Critério:
      1. SITUACAO = VALIDA    → mais recente por DATA CERTIDAO
      2. SITUACAO = ANALISE   → mais recente por DATA CERTIDAO
      3. SITUACAO = CANCELADA → mais recente por DATA CERTIDAO
      Empate em data → última na planilha (maior original_idx).
    """
    melhor = max(
        linhas,
        key=lambda item: (
            -SITUACAO_PRIORIDADE.get(
                cell_fn(item[1], "SITUACAO").strip().upper(), 99
            ),
            parse_date(cell_fn(item[1], "DATA CERTIDAO")) or date.min,
            item[0],
        ),
    )
    return melhor[1]


# ---------------------------------------------------------------------------
# Carga principal (síncrona via psycopg2)
# ---------------------------------------------------------------------------

def carregar(dsn: str, connect_kwargs: dict, ods_path: Path) -> None:
    log.info("Conectando ao banco...")
    conn = psycopg2.connect(**connect_kwargs) if not dsn else psycopg2.connect(dsn, **connect_kwargs)
    conn.autocommit = False

    try:
        cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

        # ------------------------------------------------------------------
        # 1. Pré-carregar lookup de setores: nome → UUID
        # ------------------------------------------------------------------
        cur.execute("SELECT id, nome FROM setor")
        setor_map: dict[str, str] = {}
        for r in cur.fetchall():
            setor_map[r["nome"].upper()] = str(r["id"])
        log.info("Setores carregados: %s", list(setor_map.keys()))

        # ------------------------------------------------------------------
        # 2. Ler planilha
        # ------------------------------------------------------------------
        log.info("Lendo planilha: %s", ods_path)
        doc = load(str(ods_path))
        dados = read_sheet(doc, "Dados")

        if not dados:
            log.error("Aba 'Dados' vazia ou não encontrada.")
            return

        header = dados[0][:HEADER_COUNT]
        col = {h: i for i, h in enumerate(header)}
        data_rows = [
            row for row in dados[1:]
            if any(c.strip() for c in row[:HEADER_COUNT])
        ]
        log.info("Total de linhas não-vazias na planilha: %d", len(data_rows))

        codigo_idx = col.get("CODIGO", 0)
        registros = [
            r for r in data_rows
            if (r[codigo_idx] if codigo_idx < len(r) else "").strip()
        ]
        log.info("Linhas com CODIGO preenchido (serão carregadas): %d", len(registros))

        # ------------------------------------------------------------------
        # Função auxiliar para acessar célula por nome de coluna
        # ------------------------------------------------------------------
        def cell(row: list[str], col_name: str) -> str:
            idx = col.get(col_name)
            if idx is None:
                return ""
            return row[idx] if idx < len(row) else ""

        # ------------------------------------------------------------------
        # FASE 1 — PROPOSTA
        # Agrupar linhas por código e selecionar a representativa
        # ------------------------------------------------------------------
        grupos: dict[str, list[tuple[int, list[str]]]] = defaultdict(list)
        for original_idx, row in enumerate(registros):
            codigo = cell(row, "CODIGO").strip()
            grupos[codigo].append((original_idx, row))

        log.info("Códigos únicos encontrados: %d", len(grupos))

        UPSERT_PROPOSTA_SQL = """
            INSERT INTO proposta (
                codigo,
                numero_pa,
                tipo_processo,
                data_autuacao,
                status_pa,
                interessado,
                cnpj,
                cpf,
                endereco,
                setor_id,
                requerimento,
                contribuinte_sq,
                contribuinte_lote,
                area_terreno_m2,
                situacao_certidao,
                data_proposta,
                resp_data,
                cross_check
            )
            VALUES (
                %(codigo)s,
                %(numero_pa)s,
                %(tipo_processo)s,
                %(data_autuacao)s,
                %(status_pa)s,
                %(interessado)s,
                %(cnpj)s,
                %(cpf)s,
                %(endereco)s,
                %(setor_id)s::uuid,
                %(requerimento)s,
                %(contribuinte_sq)s,
                %(contribuinte_lote)s,
                %(area_terreno_m2)s,
                %(situacao_certidao)s,
                %(data_proposta)s,
                %(resp_data)s,
                %(cross_check)s
            )
            ON CONFLICT (codigo) DO UPDATE SET
                numero_pa           = EXCLUDED.numero_pa,
                tipo_processo       = EXCLUDED.tipo_processo,
                data_autuacao       = EXCLUDED.data_autuacao,
                status_pa           = EXCLUDED.status_pa,
                interessado         = EXCLUDED.interessado,
                cnpj                = EXCLUDED.cnpj,
                cpf                 = EXCLUDED.cpf,
                endereco            = EXCLUDED.endereco,
                setor_id            = EXCLUDED.setor_id,
                requerimento        = EXCLUDED.requerimento,
                contribuinte_sq     = EXCLUDED.contribuinte_sq,
                contribuinte_lote   = EXCLUDED.contribuinte_lote,
                area_terreno_m2     = EXCLUDED.area_terreno_m2,
                situacao_certidao   = EXCLUDED.situacao_certidao,
                data_proposta       = EXCLUDED.data_proposta,
                resp_data           = EXCLUDED.resp_data,
                cross_check         = EXCLUDED.cross_check,
                updated_at          = now()
            RETURNING id, xmax
        """

        cnt_prop_inserido = 0
        cnt_prop_atualizado = 0
        cnt_prop_erro = 0
        erros_prop: list[str] = []

        # codigo → UUID da proposta no banco (para fase 2)
        proposta_id_map: dict[str, str] = {}

        for codigo, linhas in sorted(grupos.items()):
            representativa = _selecionar_representativa(linhas, cell)
            row = representativa

            # --- Setor lookup ---
            setor_nome_raw = cell(row, "SETOR OUC").strip()
            setor_id = setor_map.get(setor_nome_raw.upper())
            if setor_id is None:
                msg = (
                    f"codigo={codigo!r}: setor não encontrado → "
                    f"{setor_nome_raw!r}"
                )
                log.warning("SKIP proposta %s", msg)
                erros_prop.append(msg)
                cnt_prop_erro += 1
                continue

            # --- Processo administrativo ---
            numero_pa, tipo_processo = detect_tipo_processo(
                cell(row, "PA (16 digitos)"),
                cell(row, "PA (12 digitos)"),
            )

            # --- tipo_interessado ---
            cnpj = clean_semicolon(cell(row, "CNPJ"))
            cpf = clean_semicolon(cell(row, "CPF"))

            # --- Status PA ---
            status_pa_raw = cell(row, "STATUS PA").strip().upper()
            status_pa = STATUS_PA_MAP.get(status_pa_raw, "ANALISE")

            # --- Requerimento ---
            req_raw = cell(row, "REQUERIMENTO").strip().upper()
            requerimento = REQUERIMENTO_MAP.get(req_raw)
            if requerimento is None:
                msg = (
                    f"codigo={codigo!r}: requerimento inválido → "
                    f"{cell(row, 'REQUERIMENTO')!r}"
                )
                log.warning("SKIP proposta %s", msg)
                erros_prop.append(msg)
                cnt_prop_erro += 1
                continue

            # --- Interessado / documentos ---
            interessado = or_none(cell(row, "INTERESSADO"))
            endereco = or_none(cell(row, "ENDEREÇO"))

            # --- Contribuinte ---
            contribuinte_sq = clean_semicolon(cell(row, "CONTRIBUINTE - SQ"))
            contribuinte_lote = clean_semicolon(cell(row, "CONTRIBUINTE - L"))

            # --- Áreas ---
            area_terreno_m2 = parse_decimal_ptbr(cell(row, "ÁREA DO TERRENO"))

            # --- Situação certidão (da linha representativa) ---
            situacao_raw = cell(row, "SITUACAO").strip().upper()
            situacao_certidao_proposta = SITUACAO_MAP.get(situacao_raw)

            # --- Data proposta (DATA CERTIDAO  da linha representativa) ---
            data_proposta = parse_date(cell(row, "DATA CERTIDAO"))

            # --- Data de autuação ---
            data_autuacao = parse_date(cell(row, "DATA AUTUACAO PA"))

            # --- Controle ---
            resp_data = or_none(cell(row, "RESP/DATA"))
            cross_check = or_none(cell(row, "CROSS-CHECK"))

            try:
                cur.execute(
                    UPSERT_PROPOSTA_SQL,
                    {
                        "codigo": codigo,
                        "numero_pa": numero_pa,
                        "tipo_processo": tipo_processo,
                        "data_autuacao": data_autuacao,
                        "status_pa": status_pa,
                        "interessado": interessado,
                        "cnpj": cnpj,
                        "cpf": cpf,
                        "endereco": endereco,
                        "setor_id": setor_id,
                        "requerimento": requerimento,
                        "contribuinte_sq": contribuinte_sq,
                        "contribuinte_lote": contribuinte_lote,
                        "area_terreno_m2": area_terreno_m2,
                        "situacao_certidao": situacao_certidao_proposta,
                        "data_proposta": data_proposta,
                        "resp_data": resp_data,
                        "cross_check": cross_check,
                    },
                )
                result = cur.fetchone()
                proposta_id_map[codigo] = str(result["id"])
                # xmax == 0 → INSERT; xmax != 0 → UPDATE
                if result["xmax"] == 0:
                    cnt_prop_inserido += 1
                else:
                    cnt_prop_atualizado += 1

            except Exception as exc:
                conn.rollback()
                msg = f"codigo={codigo!r}: erro SQL proposta → {exc}"
                log.error(msg)
                erros_prop.append(msg)
                cnt_prop_erro += 1
                continue

        conn.commit()
        log.info(
            "Fase 1 concluída: %d inseridas, %d atualizadas, %d erros",
            cnt_prop_inserido, cnt_prop_atualizado, cnt_prop_erro,
        )

        # ------------------------------------------------------------------
        # FASE 2 — CERTIDÃO (uma linha por linha da planilha)
        # ------------------------------------------------------------------

        UPSERT_CERTIDAO_SQL = """
            INSERT INTO certidao (
                proposta_id,
                numero_certidao,
                tipo,
                data_emissao,
                situacao,
                numero_processo_sei,
                uso_aca,
                aca_r_m2,
                aca_nr_m2,
                aca_total_m2,
                tipo_contrapartida,
                valor_oodc_rs,
                cepac_aca,
                cepac_parametros,
                cepac_total,
                nuvem_r_m2,
                nuvem_nr_m2,
                nuvem_total_m2,
                nuvem_cepac,
                contribuinte_sq,
                contribuinte_lote,
                obs
            )
            VALUES (
                %(proposta_id)s::uuid,
                %(numero_certidao)s,
                %(tipo)s,
                %(data_emissao)s,
                %(situacao)s,
                %(numero_processo_sei)s,
                %(uso_aca)s,
                %(aca_r_m2)s,
                %(aca_nr_m2)s,
                %(aca_total_m2)s,
                %(tipo_contrapartida)s,
                %(valor_oodc_rs)s,
                %(cepac_aca)s,
                %(cepac_parametros)s,
                %(cepac_total)s,
                %(nuvem_r_m2)s,
                %(nuvem_nr_m2)s,
                %(nuvem_total_m2)s,
                %(nuvem_cepac)s,
                %(contribuinte_sq)s,
                %(contribuinte_lote)s,
                %(obs)s
            )
            ON CONFLICT (numero_certidao) DO UPDATE SET
                proposta_id         = EXCLUDED.proposta_id,
                tipo                = EXCLUDED.tipo,
                data_emissao        = EXCLUDED.data_emissao,
                situacao            = EXCLUDED.situacao,
                numero_processo_sei = EXCLUDED.numero_processo_sei,
                uso_aca             = EXCLUDED.uso_aca,
                aca_r_m2            = EXCLUDED.aca_r_m2,
                aca_nr_m2           = EXCLUDED.aca_nr_m2,
                aca_total_m2        = EXCLUDED.aca_total_m2,
                tipo_contrapartida  = EXCLUDED.tipo_contrapartida,
                valor_oodc_rs       = EXCLUDED.valor_oodc_rs,
                cepac_aca           = EXCLUDED.cepac_aca,
                cepac_parametros    = EXCLUDED.cepac_parametros,
                cepac_total         = EXCLUDED.cepac_total,
                nuvem_r_m2          = EXCLUDED.nuvem_r_m2,
                nuvem_nr_m2         = EXCLUDED.nuvem_nr_m2,
                nuvem_total_m2      = EXCLUDED.nuvem_total_m2,
                nuvem_cepac         = EXCLUDED.nuvem_cepac,
                contribuinte_sq     = EXCLUDED.contribuinte_sq,
                contribuinte_lote   = EXCLUDED.contribuinte_lote,
                obs                 = EXCLUDED.obs
            RETURNING xmax
        """

        cnt_cert_inserido = 0
        cnt_cert_atualizado = 0
        cnt_cert_pulado = 0
        erros_cert: list[str] = []

        for linha_idx, row in enumerate(registros):
            codigo = cell(row, "CODIGO").strip()

            # Pular se não tiver proposta_id (setor não encontrado / erro fase 1)
            proposta_id = proposta_id_map.get(codigo)
            if proposta_id is None:
                cnt_cert_pulado += 1
                continue

            # --- Número de certidão (com fallback, max 20 chars) ---
            numero_certidao_raw = or_none(cell(row, "CERTIDAO"))
            if numero_certidao_raw is None:
                numero_certidao = f"{codigo}-{linha_idx}"[:20]
            else:
                numero_certidao = numero_certidao_raw[:20]

            # --- Situação ---
            situacao_raw = cell(row, "SITUACAO").strip().upper()
            situacao = SITUACAO_MAP.get(situacao_raw, "ANALISE")

            # --- Tipo de certidão (enum PostgreSQL com cedilha) ---
            tipo_certidao = TIPO_CERTIDAO_VINCULACAO

            # --- Data emissão ---
            data_emissao = parse_date(cell(row, "DATA CERTIDAO"))

            # --- Número processo SEI (coluna PA 16 dígitos) ---
            numero_processo_sei, _ = detect_tipo_processo(
                cell(row, "PA (16 digitos)"),
                cell(row, "PA (12 digitos)"),
            )

            # --- Dados ACA ---
            uso_aca = or_none(cell(row, "USO DA ACA"))
            aca_r_m2 = parse_decimal_ptbr(cell(row, "ACA-R"))
            aca_nr_m2 = parse_decimal_ptbr(cell(row, "ACA-NR"))
            aca_total_m2 = parse_decimal_ptbr(cell(row, "ACA-TOTAL"))

            # --- Contrapartida ---
            tipo_contrapartida = or_none(cell(row, "TIPO DE CONTRAPARTIDA"))
            valor_oodc_rs = parse_decimal_ptbr(cell(row, "VALOR R$"))

            # --- CEPACs ---
            cepac_aca = parse_integer_ptbr(cell(row, "CEPAC ACA"))
            cepac_parametros = parse_integer_ptbr(cell(row, "CEPAC PARAMETROS"))
            cepac_total = parse_integer_ptbr(cell(row, "TOTAL CEPAC"))

            # --- NUVEM ---
            nuvem_r_m2 = parse_decimal_ptbr(cell(row, "NUVEM m² - R"))
            nuvem_nr_m2 = parse_decimal_ptbr(cell(row, "NUVEM m² -nR"))
            nuvem_total_m2 = parse_decimal_ptbr(cell(row, "NUVEM m²"))
            nuvem_cepac = parse_integer_ptbr(cell(row, "NUVEM CEPAC"))

            # --- Contribuinte ---
            contribuinte_sq = clean_semicolon(cell(row, "CONTRIBUINTE - SQ"))
            contribuinte_lote = clean_semicolon(cell(row, "CONTRIBUINTE - L"))

            # --- Obs ---
            obs = or_none(cell(row, "OBS"))

            try:
                cur.execute(
                    UPSERT_CERTIDAO_SQL,
                    {
                        "proposta_id": proposta_id,
                        "numero_certidao": numero_certidao,
                        "tipo": tipo_certidao,
                        "data_emissao": data_emissao,
                        "situacao": situacao,
                        "numero_processo_sei": numero_processo_sei,
                        "uso_aca": uso_aca,
                        "aca_r_m2": aca_r_m2,
                        "aca_nr_m2": aca_nr_m2,
                        "aca_total_m2": aca_total_m2,
                        "tipo_contrapartida": tipo_contrapartida,
                        "valor_oodc_rs": valor_oodc_rs,
                        "cepac_aca": cepac_aca,
                        "cepac_parametros": cepac_parametros,
                        "cepac_total": cepac_total,
                        "nuvem_r_m2": nuvem_r_m2,
                        "nuvem_nr_m2": nuvem_nr_m2,
                        "nuvem_total_m2": nuvem_total_m2,
                        "nuvem_cepac": nuvem_cepac,
                        "contribuinte_sq": contribuinte_sq,
                        "contribuinte_lote": contribuinte_lote,
                        "obs": obs,
                    },
                )
                result = cur.fetchone()
                if result["xmax"] == 0:
                    cnt_cert_inserido += 1
                else:
                    cnt_cert_atualizado += 1

            except Exception as exc:
                conn.rollback()
                msg = f"codigo={codigo!r} certidao={numero_certidao!r}: erro SQL → {exc}"
                log.error(msg)
                erros_cert.append(msg)
                cnt_cert_pulado += 1
                continue

        conn.commit()
        log.info(
            "Fase 2 concluída: %d inseridas, %d atualizadas, %d puladas",
            cnt_cert_inserido, cnt_cert_atualizado, cnt_cert_pulado,
        )

        # ------------------------------------------------------------------
        # Contagem por situação no banco
        # ------------------------------------------------------------------
        cur.execute(
            "SELECT situacao_certidao AS situacao, COUNT(*) AS total "
            "FROM proposta "
            "WHERE situacao_certidao IS NOT NULL "
            "GROUP BY situacao_certidao ORDER BY situacao_certidao"
        )
        situacao_proposta_counts = cur.fetchall()

        cur.execute(
            "SELECT situacao, COUNT(*) AS total "
            "FROM certidao GROUP BY situacao ORDER BY situacao"
        )
        situacao_certidao_counts = cur.fetchall()

    finally:
        conn.close()

    # ------------------------------------------------------------------
    # Relatório final
    # ------------------------------------------------------------------
    print()
    print("=" * 60)
    print("  RESULTADO DA CARGA")
    print("=" * 60)
    print()
    print("  PROPOSTAS")
    print(f"    Inseridas                  : {cnt_prop_inserido:>6}")
    print(f"    Atualizadas                : {cnt_prop_atualizado:>6}")
    print(f"    Erros/puladas              : {cnt_prop_erro:>6}")
    print()
    print("  CERTIDOES")
    print(f"    Inseridas                  : {cnt_cert_inserido:>6}")
    print(f"    Atualizadas                : {cnt_cert_atualizado:>6}")
    print(f"    Puladas (sem proposta/erro): {cnt_cert_pulado:>6}")
    print()
    print("  CONTAGEM POR situacao_certidao (tabela proposta)")
    for row in situacao_proposta_counts:
        print(f"    {str(row['situacao']):<20}: {row['total']:>6}")
    print()
    print("  CONTAGEM POR situacao (tabela certidao)")
    for row in situacao_certidao_counts:
        print(f"    {str(row['situacao']):<20}: {row['total']:>6}")
    print("=" * 60)

    all_erros = erros_prop + erros_cert
    if all_erros:
        print("\nDETALHE DOS ERROS:")
        for e in all_erros:
            print(f"  - {e}")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main() -> None:
    load_env(ENV_PATH)

    if not ODS_PATH.exists():
        log.error("Planilha não encontrada: %s", ODS_PATH)
        sys.exit(1)

    try:
        dsn, connect_kwargs = get_dsn()
    except RuntimeError as e:
        log.error(str(e))
        sys.exit(1)

    dsn_log = re.sub(r":([^@/]+)@", ":***@", dsn)
    log.info("DSN: %s (kwargs=%s)", dsn_log, connect_kwargs)

    carregar(dsn, connect_kwargs, ODS_PATH)


if __name__ == "__main__":
    main()
