"""
DashboardRepository — indicadores consolidados para o Dashboard Executivo (T16).

Todas as funções recebem AsyncSession. Nenhuma lógica de negócio reside aqui —
apenas consultas e agregações. A lógica de alertas está em _calcular_alertas().

Fontes dos big numbers:
  custo_total_incorrido   → medicao_obra.valor_acumulado (mais recente)
  capacidade_total        → SUM(setor.estoque_total_m2)
  saldo_geral_disponivel  → capacidade_total − consumido − em_analise (todos setores)
  cepacs_em_circulacao    → parametro_sistema WHERE chave = 'cepacs_em_circulacao'

Velocímetro 2029 (D3):
  inicio = 2004-01-01  fim = 2029-12-31
  zona VERDE 0–60 %  |  AMARELO 60–85 %  |  VERMELHO 85–100 %
"""
from __future__ import annotations

import math
from datetime import date, datetime, time, timezone
from decimal import Decimal
from typing import Optional

from dataclasses import dataclass

from sqlalchemy import select, text
from sqlalchemy.ext.asyncio import AsyncSession

from src.core.models.configuracao_operacao import ConfiguracaoOperacao
from src.core.models.medicao_obra import MedicaoObra
from src.core.models.parametro_sistema import ParametroSistema
from src.core.models.setor import Setor
from src.core.repositories import saldo_repository


# ---------------------------------------------------------------------------
# DTOs internos (sem dependência de FastAPI/Pydantic)
# ---------------------------------------------------------------------------

@dataclass
class OcupacaoSetorDTO:
    nome: str
    estoque_total: Decimal
    consumido_r: Decimal
    consumido_nr: Decimal
    consumido_r_aca: Decimal
    consumido_nr_aca: Decimal
    consumido_r_nuvem: Decimal
    consumido_nr_nuvem: Decimal
    em_analise_r: Decimal
    em_analise_nr: Decimal
    disponivel: Decimal
    percentual_ocupado: float
    teto_nr: Optional[Decimal]
    saldo_nr_liquido: Optional[Decimal]
    bloqueado_nr: bool


@dataclass
class AlertaDTO:
    setor: str
    tipo: str   # "TETO_NR_EXCEDIDO" | "RESERVA_R_VIOLADA"
    mensagem: str

# ---------------------------------------------------------------------------
# Constantes do Velocímetro
# ---------------------------------------------------------------------------

_DATA_INICIO_OUCAE = date(2004, 1, 1)   # D3
_DATA_FIM_OUCAE = date(2029, 12, 31)
_DIAS_TOTAIS = (_DATA_FIM_OUCAE - _DATA_INICIO_OUCAE).days  # 9 496 dias


# ---------------------------------------------------------------------------
# Setores
# ---------------------------------------------------------------------------

async def buscar_setores(session: AsyncSession) -> list[Setor]:
    """Retorna todos os setores ordenados por nome."""
    result = await session.execute(select(Setor).order_by(Setor.nome))
    return list(result.scalars().all())


# ---------------------------------------------------------------------------
# Parâmetros do sistema
# ---------------------------------------------------------------------------

async def buscar_cepacs_em_circulacao(session: AsyncSession) -> int:
    """
    Retorna o total de CEPACs em circulação (D5 — fonte: planilha XLSX).

    Padrão 193.779 se o parâmetro ainda não foi carregado.
    """
    result = await session.execute(
        select(ParametroSistema).where(
            ParametroSistema.chave == "cepacs_em_circulacao"
        )
    )
    param = result.scalar_one_or_none()
    if param is None:
        return 193_779  # valor da planilha (D5)
    return int(param.valor)


# ---------------------------------------------------------------------------
# Custo Total Incorrido (medicao_obra)
# ---------------------------------------------------------------------------

async def buscar_custo_total_incorrido(
    session: AsyncSession,
    data_limite: Optional[datetime] = None,
) -> Decimal:
    """
    Retorna o valor_acumulado da medição mais recente.

    Se `data_limite` for informado (snapshot histórico), retorna a medição
    com data_referencia <= data_limite.

    Retorna Decimal("0") quando não há medições (T17 ainda não executada).
    """
    stmt = (
        select(MedicaoObra.valor_acumulado)
        .order_by(MedicaoObra.data_referencia.desc())
        .limit(1)
    )
    if data_limite is not None:
        stmt = stmt.where(MedicaoObra.data_referencia <= data_limite.date())

    result = await session.execute(stmt)
    valor = result.scalar_one_or_none()
    return Decimal(str(valor)) if valor is not None else Decimal("0")


# ---------------------------------------------------------------------------
# Ocupação setorial
# ---------------------------------------------------------------------------

async def calcular_ocupacao_setores(
    session: AsyncSession,
    data_limite: Optional[datetime] = None,
    setores: Optional[list[Setor]] = None,
) -> list[OcupacaoSetorDTO]:
    """
    Calcula a ocupação de cada setor.

    Reutiliza saldo_repository.calcular_saldo() para consistência com o
    RulesEngine e o endpoint GET /saldo/{setor}.

    `data_limite` permite snapshot point-in-time (passado pelo snapshot histórico).
    `setores` pode ser passado para evitar query duplicada.
    """
    if setores is None:
        setores = await buscar_setores(session)

    data_ref: Optional[date] = None
    if data_limite is not None:
        data_ref = data_limite.date()

    resultado: list[OcupacaoSetorDTO] = []

    for setor in setores:
        saldo = await saldo_repository.calcular_saldo(session, setor.nome, data_ref)

        consumido_r_aca = saldo.r_consumido_aca
        consumido_nr_aca = saldo.nr_consumido_aca
        consumido_r_nuvem = saldo.r_consumido_nuvem
        consumido_nr_nuvem = saldo.nr_consumido_nuvem
        consumido_r = consumido_r_aca + consumido_r_nuvem
        consumido_nr = consumido_nr_aca + consumido_nr_nuvem
        em_analise_r = saldo.r_em_analise
        em_analise_nr = saldo.nr_em_analise

        consumido_total = consumido_r + consumido_nr
        em_analise_total = em_analise_r + em_analise_nr
        disponivel = setor.estoque_total_m2 - consumido_total - em_analise_total

        if setor.estoque_total_m2 > 0:
            percentual_ocupado = float(
                consumido_total / setor.estoque_total_m2 * 100
            )
        else:
            percentual_ocupado = 0.0

        # Teto NR e saldo líquido
        teto_nr = setor.teto_nr_m2 if setor.teto_nr_m2 else None
        nr_comprometido = consumido_nr + em_analise_nr
        if teto_nr is not None:
            saldo_nr_liquido = teto_nr - nr_comprometido
            bloqueado_nr = nr_comprometido >= teto_nr
        else:
            saldo_nr_liquido = None
            bloqueado_nr = False

        resultado.append(
            OcupacaoSetorDTO(
                nome=setor.nome,
                estoque_total=setor.estoque_total_m2,
                consumido_r=consumido_r,
                consumido_nr=consumido_nr,
                consumido_r_aca=consumido_r_aca,
                consumido_nr_aca=consumido_nr_aca,
                consumido_r_nuvem=consumido_r_nuvem,
                consumido_nr_nuvem=consumido_nr_nuvem,
                em_analise_r=em_analise_r,
                em_analise_nr=em_analise_nr,
                disponivel=disponivel,
                percentual_ocupado=round(percentual_ocupado, 2),
                teto_nr=teto_nr,
                saldo_nr_liquido=saldo_nr_liquido,
                bloqueado_nr=bloqueado_nr,
            )
        )

    return resultado


# ---------------------------------------------------------------------------
# Alertas
# ---------------------------------------------------------------------------

def calcular_alertas(
    setores_ocupacao: list[OcupacaoSetorDTO],
    setores_orm: list[Setor],
) -> list[AlertaDTO]:
    """
    Deriva os alertas ativos a partir da ocupação já calculada.

    Tipos de alerta:
    - TETO_NR_EXCEDIDO  : nr_comprometido >= teto_nr (ex: Berrini)
    - RESERVA_R_VIOLADA : nr_comprometido > estoque_total − reserva_r (ex: Chucri Zaidan)
    """
    setor_map = {s.nome: s for s in setores_orm}

    alertas: list[AlertaDTO] = []

    for occ in setores_ocupacao:
        setor_orm = setor_map.get(occ.nome)
        nr_comprometido = occ.consumido_nr + occ.em_analise_nr

        # TETO_NR_EXCEDIDO
        if occ.bloqueado_nr:
            alertas.append(
                AlertaDTO(
                    setor=occ.nome,
                    tipo="TETO_NR_EXCEDIDO",
                    mensagem=(
                        f"{occ.nome}: teto NR atingido "
                        f"({nr_comprometido:,.2f} m² comprometidos, "
                        f"teto {occ.teto_nr:,.2f} m²)."
                    ),
                )
            )

        # RESERVA_R_VIOLADA (apenas setores com reserva_r_m2)
        if setor_orm and setor_orm.reserva_r_m2:
            nr_max_sem_violar = occ.estoque_total - setor_orm.reserva_r_m2
            if nr_comprometido > nr_max_sem_violar:
                alertas.append(
                    AlertaDTO(
                        setor=occ.nome,
                        tipo="RESERVA_R_VIOLADA",
                        mensagem=(
                            f"{occ.nome}: pedidos NR invadem a reserva residencial "
                            f"protegida de {setor_orm.reserva_r_m2:,.2f} m²."
                        ),
                    )
                )

    return alertas


# ---------------------------------------------------------------------------
# Velocímetro 2029
# ---------------------------------------------------------------------------

def calcular_velocimetro(
    data_referencia: Optional[date] = None,
) -> tuple[float, int, str]:
    """
    Calcula percentual decorrido, dias restantes e zona do Velocímetro 2029.

    Retorna (percentual_decorrido, dias_restantes, zona).

    Fórmula (D3):
      inicio = 2004-01-01  |  fim = 2029-12-31
      % = (hoje − início) / (fim − início) × 100
      VERDE 0–60 %  |  AMARELO 60–85 %  |  VERMELHO 85–100 %
    """
    hoje = data_referencia or date.today()

    dias_decorridos = max(0, (hoje - _DATA_INICIO_OUCAE).days)
    dias_restantes = max(0, (_DATA_FIM_OUCAE - hoje).days)

    percentual = min(100.0, dias_decorridos / _DIAS_TOTAIS * 100)

    if percentual < 60.0:
        zona = "VERDE"
    elif percentual < 85.0:
        zona = "AMARELO"
    else:
        zona = "VERMELHO"

    return round(percentual, 2), dias_restantes, zona


# ---------------------------------------------------------------------------
# Medições (série histórica)
# ---------------------------------------------------------------------------

async def listar_medicoes(session: AsyncSession) -> list[MedicaoObra]:
    """
    Retorna todas as medições de obra ordenadas por data_referencia DESC.
    """
    result = await session.execute(
        select(MedicaoObra).order_by(MedicaoObra.data_referencia.desc())
    )
    return list(result.scalars().all())


# ---------------------------------------------------------------------------
# Snapshot completo (entry point usado pela rota)
# ---------------------------------------------------------------------------

async def montar_graficos(session: AsyncSession) -> dict:
    """
    Monta os dados para os 7 gráficos analíticos do dashboard.

    Todas as queries usam sqlalchemy.text() para máxima performance.
    Retorna um dict compatível com GraficosOut.
    """

    def _pearson(xs: list[float], ys: list[float]) -> float:
        n = len(xs)
        if n < 2:
            return 0.0
        mx, my = sum(xs) / n, sum(ys) / n
        num = sum((x - mx) * (y - my) for x, y in zip(xs, ys))
        dx = math.sqrt(sum((x - mx) ** 2 for x in xs))
        dy = math.sqrt(sum((y - my) ** 2 for y in ys))
        if dx == 0 or dy == 0:
            return 0.0
        return round(num / (dx * dy), 2)

    _MESES_PT = {
        "01": "Jan", "02": "Fev", "03": "Mar", "04": "Abr",
        "05": "Mai", "06": "Jun", "07": "Jul", "08": "Ago",
        "09": "Set", "10": "Out", "11": "Nov", "12": "Dez",
    }

    # ------------------------------------------------------------------ G1
    g1_rows = (await session.execute(text(
        "SELECT EXTRACT(YEAR FROM data_certidao)::int AS ano, SUM(cepac_total)::int AS total "
        "FROM proposta "
        "WHERE data_certidao IS NOT NULL AND cepac_total IS NOT NULL AND cepac_total > 0 "
        "GROUP BY ano ORDER BY ano"
    ))).fetchall()

    g1_evolucao = [{"ano": r.ano, "total": r.total} for r in g1_rows]
    g1_total_cepacs = sum(r["total"] for r in g1_evolucao)
    g1_media_ano = round(g1_total_cepacs / len(g1_evolucao)) if g1_evolucao else 0
    g1_ano_pico = max(g1_evolucao, key=lambda x: x["total"])["ano"] if g1_evolucao else 0
    if len(g1_evolucao) >= 2:
        ultimo = g1_evolucao[-1]["total"]
        penultimo = g1_evolucao[-2]["total"]
        g1_crescimento_pct = round((ultimo - penultimo) / penultimo * 100, 1) if penultimo else 0.0
    else:
        g1_crescimento_pct = 0.0

    # ------------------------------------------------------------------ G2
    g2_rows = (await session.execute(text(
        "SELECT s.nome AS setor, "
        "       COALESCE(SUM(p.cepac_aca), 0)::int AS cepac_aca, "
        "       COALESCE(SUM(p.cepac_parametros), 0)::int AS cepac_parametros "
        "FROM proposta p JOIN setor s ON s.id = p.setor_id "
        "GROUP BY s.nome ORDER BY s.nome"
    ))).fetchall()

    g2_por_setor = [{"setor": r.setor, "cepac_aca": r.cepac_aca, "cepac_parametros": r.cepac_parametros} for r in g2_rows]
    g2_total_aca = sum(r["cepac_aca"] for r in g2_por_setor)
    g2_total_parametros = sum(r["cepac_parametros"] for r in g2_por_setor)
    if g2_total_parametros:
        g2_proporcao = f"{round(g2_total_aca / g2_total_parametros, 1)}:1"
    else:
        g2_proporcao = "0.0:1"

    # ------------------------------------------------------------------ G3
    g3_status_rows = (await session.execute(text(
        "SELECT status_pa, COUNT(*)::int AS total FROM proposta GROUP BY status_pa"
    ))).fetchall()

    g3_deferidas = 0
    g3_indeferidas = 0
    g3_total_propostas = 0
    for r in g3_status_rows:
        g3_total_propostas += r.total
        if r.status_pa == "DEFERIDO":
            g3_deferidas = r.total
        elif r.status_pa == "INDEFERIDO":
            g3_indeferidas = r.total

    g3_taxa_aprovacao = round(g3_deferidas / g3_total_propostas * 100, 1) if g3_total_propostas else 0.0

    g3_mes_rows = (await session.execute(text(
        "SELECT TO_CHAR(data_autuacao, 'YYYY-MM') AS mes, "
        "       SUM(CASE WHEN status_pa = 'DEFERIDO' THEN 1 ELSE 0 END)::int AS deferidas, "
        "       SUM(CASE WHEN status_pa = 'INDEFERIDO' THEN 1 ELSE 0 END)::int AS indeferidas "
        "FROM proposta "
        "WHERE data_autuacao IS NOT NULL "
        "  AND data_autuacao >= (CURRENT_DATE - INTERVAL '12 months') "
        "GROUP BY mes ORDER BY mes"
    ))).fetchall()

    g3_por_mes = [
        {
            "mes": _MESES_PT.get(r.mes.split("-")[1], r.mes),
            "deferidas": r.deferidas,
            "indeferidas": r.indeferidas,
        }
        for r in g3_mes_rows
    ]

    # ------------------------------------------------------------------ G4
    g4_rows = (await session.execute(text(
        "SELECT uso_aca, COALESCE(SUM(cepac_total), 0)::int AS total "
        "FROM proposta "
        "WHERE uso_aca IS NOT NULL AND cepac_total IS NOT NULL "
        "GROUP BY uso_aca ORDER BY total DESC"
    ))).fetchall()

    g4_uso = [{"uso": r.uso_aca, "total": r.total} for r in g4_rows]
    g4_mais_comum = g4_uso[0]["uso"] if g4_uso else ""
    g4_tipos_ativos = len(g4_uso)

    # ------------------------------------------------------------------ G5
    g5_rows = (await session.execute(text(
        "SELECT s.nome AS setor, COALESCE(SUM(p.cepac_total), 0)::int AS total "
        "FROM proposta p JOIN setor s ON s.id = p.setor_id "
        "WHERE p.cepac_total IS NOT NULL "
        "GROUP BY s.nome ORDER BY total DESC LIMIT 10"
    ))).fetchall()

    g5_top_setores = [{"setor": r.setor, "total": r.total} for r in g5_rows]
    g5_setor_lider = g5_top_setores[0]["setor"] if g5_top_setores else ""
    g5_total_top10 = sum(r["total"] for r in g5_top_setores)

    g5_ativos_row = (await session.execute(text(
        "SELECT COUNT(*)::int AS total FROM setor WHERE ativo = true"
    ))).fetchone()
    g5_setores_ativos = g5_ativos_row.total if g5_ativos_row else 0

    # ------------------------------------------------------------------ G6
    _g6_subquery = (
        "SELECT (data_certidao - data_autuacao) AS dias "
        "FROM proposta "
        "WHERE data_certidao IS NOT NULL AND data_autuacao IS NOT NULL "
        "  AND data_certidao >= data_autuacao"
    )
    g6_hist_rows = (await session.execute(text(
        "SELECT "
        "  CASE "
        "    WHEN dias <= 15 THEN '0-15 dias' "
        "    WHEN dias <= 30 THEN '16-30 dias' "
        "    WHEN dias <= 45 THEN '31-45 dias' "
        "    WHEN dias <= 60 THEN '46-60 dias' "
        "    WHEN dias <= 75 THEN '61-75 dias' "
        "    WHEN dias <= 90 THEN '76-90 dias' "
        "    ELSE '90+ dias' "
        "  END AS faixa, "
        "  ARRAY_POSITION(ARRAY['0-15 dias','16-30 dias','31-45 dias','46-60 dias','61-75 dias','76-90 dias','90+ dias'], "
        "    CASE WHEN dias<=15 THEN '0-15 dias' WHEN dias<=30 THEN '16-30 dias' WHEN dias<=45 THEN '31-45 dias' "
        "         WHEN dias<=60 THEN '46-60 dias' WHEN dias<=75 THEN '61-75 dias' WHEN dias<=90 THEN '76-90 dias' "
        "         ELSE '90+ dias' END) AS ordem, "
        "  COUNT(*)::int AS quantidade "
        f"FROM ({_g6_subquery}) t "
        "GROUP BY faixa, ordem ORDER BY ordem"
    ))).fetchall()

    g6_histograma = [{"faixa": r.faixa, "quantidade": r.quantidade} for r in g6_hist_rows]

    g6_stats_row = (await session.execute(text(
        f"SELECT AVG(dias)::float AS media, MIN(dias)::float AS minimo, MAX(dias)::float AS maximo "
        f"FROM ({_g6_subquery}) t"
    ))).fetchone()

    g6_tempo_medio = round(g6_stats_row.media, 1) if g6_stats_row and g6_stats_row.media is not None else 0.0
    g6_tempo_minimo = g6_stats_row.minimo if g6_stats_row and g6_stats_row.minimo is not None else 0.0
    g6_tempo_maximo = g6_stats_row.maximo if g6_stats_row and g6_stats_row.maximo is not None else 0.0

    # ------------------------------------------------------------------ G7
    g7_rows = (await session.execute(text(
        "SELECT aca_total_m2::float AS area_m2, cepac_total "
        "FROM proposta "
        "WHERE aca_total_m2 IS NOT NULL AND cepac_total IS NOT NULL "
        "  AND aca_total_m2 > 0 AND cepac_total > 0 "
        "ORDER BY aca_total_m2"
    ))).fetchall()

    g7_scatter = [{"area_m2": r.area_m2, "cepac_total": r.cepac_total} for r in g7_rows]
    if g7_scatter:
        areas = [r["area_m2"] for r in g7_scatter]
        cepacs_vals = [r["cepac_total"] for r in g7_scatter]
        g7_area_media = round(sum(areas) / len(areas), 2)
        g7_media_cepac_m2 = round(sum(cepacs_vals) / sum(areas), 4) if sum(areas) else 0.0
        g7_correlacao = _pearson(areas, [float(v) for v in cepacs_vals])
    else:
        g7_area_media = 0.0
        g7_media_cepac_m2 = 0.0
        g7_correlacao = 0.0

    return {
        "g1_evolucao": g1_evolucao,
        "g1_total_cepacs": g1_total_cepacs,
        "g1_media_ano": g1_media_ano,
        "g1_ano_pico": g1_ano_pico,
        "g1_crescimento_pct": g1_crescimento_pct,
        "g2_por_setor": g2_por_setor,
        "g2_total_aca": g2_total_aca,
        "g2_total_parametros": g2_total_parametros,
        "g2_proporcao": g2_proporcao,
        "g3_total_propostas": g3_total_propostas,
        "g3_deferidas": g3_deferidas,
        "g3_indeferidas": g3_indeferidas,
        "g3_taxa_aprovacao": g3_taxa_aprovacao,
        "g3_por_mes": g3_por_mes,
        "g4_uso": g4_uso,
        "g4_mais_comum": g4_mais_comum,
        "g4_tipos_ativos": g4_tipos_ativos,
        "g5_top_setores": g5_top_setores,
        "g5_setor_lider": g5_setor_lider,
        "g5_total_top10": g5_total_top10,
        "g5_setores_ativos": g5_setores_ativos,
        "g6_histograma": g6_histograma,
        "g6_tempo_medio": g6_tempo_medio,
        "g6_tempo_minimo": g6_tempo_minimo,
        "g6_tempo_maximo": g6_tempo_maximo,
        "g7_scatter": g7_scatter,
        "g7_area_media": g7_area_media,
        "g7_media_cepac_m2": g7_media_cepac_m2,
        "g7_correlacao": g7_correlacao,
    }


async def montar_snapshot(
    session: AsyncSession,
    data_referencia: Optional[date] = None,
) -> dict:
    """
    Monta todos os indicadores do dashboard em um único dicionário.

    `data_referencia` ativa o modo histórico point-in-time.
    """
    # Converter para datetime com fim-de-dia UTC para queries de movimentação
    data_limite: Optional[datetime] = None
    if data_referencia is not None:
        data_limite = datetime.combine(data_referencia, time.max)  # naive — TIMESTAMP WITHOUT TIME ZONE

    setores = await buscar_setores(session)
    setores_ocupacao = await calcular_ocupacao_setores(session, data_limite, setores)
    alertas = calcular_alertas(setores_ocupacao, setores)

    cfg_result = await session.execute(
        select(ConfiguracaoOperacao).where(ConfiguracaoOperacao.id == 1)
    )
    cfg = cfg_result.scalar_one_or_none()
    reserva_tecnica = cfg.reserva_tecnica_m2 if cfg else Decimal("0")

    capacidade_total = sum(s.estoque_total_m2 for s in setores) + reserva_tecnica
    saldo_geral = sum(occ.disponivel for occ in setores_ocupacao)
    total_consumido = sum(occ.consumido_r + occ.consumido_nr for occ in setores_ocupacao)
    total_em_analise = sum(occ.em_analise_r + occ.em_analise_nr for occ in setores_ocupacao)

    custo = await buscar_custo_total_incorrido(session, data_limite)
    cepacs = await buscar_cepacs_em_circulacao(session)
    pct, dias_rest, zona = calcular_velocimetro(data_referencia)

    return {
        "gerado_em": datetime.now(tz=timezone.utc),
        "custo_total_incorrido": custo,
        "capacidade_total_operacao": capacidade_total,
        "saldo_geral_disponivel": saldo_geral,
        "total_consumido_m2": total_consumido,
        "total_em_analise_m2": total_em_analise,
        "cepacs_em_circulacao": cepacs,
        "prazo_percentual_decorrido": pct,
        "prazo_dias_restantes": dias_rest,
        "prazo_zona": zona,
        "alertas": alertas,
        "setores": setores_ocupacao,
    }
