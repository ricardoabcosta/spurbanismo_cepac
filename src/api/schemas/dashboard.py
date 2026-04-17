"""
Schemas Pydantic v2 para os endpoints do Dashboard Executivo (T16).
"""
from __future__ import annotations

from datetime import date, datetime
from decimal import Decimal
from typing import Literal, Optional
from uuid import UUID

from pydantic import BaseModel, Field


# ---------------------------------------------------------------------------
# Alertas
# ---------------------------------------------------------------------------

class AlertaSetorialOut(BaseModel):
    """Trava ativa em um setor."""

    setor: str
    tipo: Literal["TETO_NR_EXCEDIDO", "RESERVA_R_VIOLADA"]
    mensagem: str


# ---------------------------------------------------------------------------
# Ocupação por setor (dados para gráfico de barras)
# ---------------------------------------------------------------------------

class OcupacaoSetorOut(BaseModel):
    """Ocupação de um setor — série para o gráfico de barras."""

    nome: str
    estoque_total: Decimal
    consumido_r: Decimal
    consumido_nr: Decimal
    em_analise_r: Decimal
    em_analise_nr: Decimal
    disponivel: Decimal = Field(
        ..., description="estoque_total − consumido_total − em_analise_total"
    )
    percentual_ocupado: float = Field(
        ..., description="(consumido_total / estoque_total) × 100"
    )
    teto_nr: Optional[Decimal] = Field(
        default=None, description="Teto NR do setor (NULL = sem teto específico)"
    )
    saldo_nr_liquido: Optional[Decimal] = Field(
        default=None, description="teto_nr − (consumido_nr + em_analise_nr)"
    )
    bloqueado_nr: bool = Field(
        ..., description="True quando nr_total_comprometido >= teto_nr"
    )


# ---------------------------------------------------------------------------
# Snapshot principal
# ---------------------------------------------------------------------------

class DashboardSnapshotOut(BaseModel):
    """
    Todos os indicadores do Dashboard em uma única resposta.

    Usado para polling a cada 60 s. Com o param `data` (DIRETOR apenas),
    reconstrói o estado do dashboard em uma data passada.
    """

    gerado_em: datetime

    # Big Numbers
    custo_total_incorrido: Decimal = Field(
        ..., description="Custo total acumulado em R$ (da última medição de obra)"
    )
    capacidade_total_operacao: Decimal = Field(
        ..., description="Soma dos estoques totais de todos os setores em m²"
    )
    saldo_geral_disponivel: Decimal = Field(
        ...,
        description="capacidade_total − consumido_total − em_analise_total (exclui Em Análise do saldo livre)",
    )
    cepacs_em_circulacao: int = Field(
        ..., description="CEPACs emitidos em circulação (de parametro_sistema)"
    )

    # Velocímetro 2029
    prazo_percentual_decorrido: float = Field(
        ..., description="0.0 – 100.0 — % do prazo OUCAE decorrido"
    )
    prazo_dias_restantes: int
    prazo_zona: Literal["VERDE", "AMARELO", "VERMELHO"]

    alertas: list[AlertaSetorialOut]
    setores: list[OcupacaoSetorOut]


# ---------------------------------------------------------------------------
# Medições de obra
# ---------------------------------------------------------------------------

class MedicaoOut(BaseModel):
    """Medição mensal de obra (série histórica do Custo Total Incorrido)."""

    id: UUID
    data_referencia: date
    valor_medicao: Decimal
    valor_acumulado: Decimal
    descricao: Optional[str] = None
    numero_processo_sei: str
    created_at: datetime

    model_config = {"from_attributes": True}
