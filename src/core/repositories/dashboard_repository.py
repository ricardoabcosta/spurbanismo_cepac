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

from datetime import date, datetime, time, timezone
from decimal import Decimal
from typing import Optional

from dataclasses import dataclass

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

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

        consumido_r = saldo.r_consumido_aca + saldo.r_consumido_nuvem
        consumido_nr = saldo.nr_consumido_aca + saldo.nr_consumido_nuvem
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
        data_limite = datetime.combine(data_referencia, time.max).replace(
            tzinfo=timezone.utc
        )

    setores = await buscar_setores(session)
    setores_ocupacao = await calcular_ocupacao_setores(session, data_limite, setores)
    alertas = calcular_alertas(setores_ocupacao, setores)

    capacidade_total = sum(s.estoque_total_m2 for s in setores)
    saldo_geral = sum(occ.disponivel for occ in setores_ocupacao)

    custo = await buscar_custo_total_incorrido(session, data_limite)
    cepacs = await buscar_cepacs_em_circulacao(session)
    pct, dias_rest, zona = calcular_velocimetro(data_referencia)

    return {
        "gerado_em": datetime.now(tz=timezone.utc),
        "custo_total_incorrido": custo,
        "capacidade_total_operacao": capacidade_total,
        "saldo_geral_disponivel": saldo_geral,
        "cepacs_em_circulacao": cepacs,
        "prazo_percentual_decorrido": pct,
        "prazo_dias_restantes": dias_rest,
        "prazo_zona": zona,
        "alertas": alertas,
        "setores": setores_ocupacao,
    }
