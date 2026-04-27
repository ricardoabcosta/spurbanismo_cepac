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
    consumido_r_aca: Decimal = Field(..., description="R consumido via ACA (sem NUVEM)")
    consumido_nr_aca: Decimal = Field(..., description="NR consumido via ACA (sem NUVEM)")
    consumido_r_nuvem: Decimal = Field(..., description="R consumido via NUVEM (sem ACA)")
    consumido_nr_nuvem: Decimal = Field(..., description="NR consumido via NUVEM (sem ACA)")
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
        ..., description="SUM(setor.estoque_total_m2) + reserva_tecnica_m2 da configuracao_operacao"
    )
    saldo_geral_disponivel: Decimal = Field(
        ...,
        description="capacidade_total − consumido_total − em_analise_total (exclui Em Análise do saldo livre)",
    )
    total_consumido_m2: Decimal = Field(
        ..., description="SUM(consumido_r + consumido_nr) de todos os setores (ACA + NUVEM)"
    )
    total_em_analise_m2: Decimal = Field(
        ..., description="SUM(em_analise_r + em_analise_nr) de todos os setores"
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


# ---------------------------------------------------------------------------
# CEPACs por setor e snapshot global
# ---------------------------------------------------------------------------

class CepacSetorOut(BaseModel):
    nome: str
    cepacs_convertidos_aca: int
    cepacs_convertidos_parametros: int
    cepacs_desvinculados_aca: int
    cepacs_desvinculados_parametros: int

    model_config = {"from_attributes": True}


class CepacSnapshotOut(BaseModel):
    cepacs_totais: int
    cepacs_leiloados: int
    cepacs_colocacao_privada: int
    setores: list[CepacSetorOut]

    model_config = {"from_attributes": True}


# ---------------------------------------------------------------------------
# Gráficos analíticos
# ---------------------------------------------------------------------------

class GraficosOut(BaseModel):
    g1_evolucao: list[dict]
    g1_total_cepacs: int
    g1_media_ano: int
    g1_ano_pico: int
    g1_crescimento_pct: float

    g2_por_setor: list[dict]
    g2_total_aca: int
    g2_total_parametros: int
    g2_proporcao: str

    g3_total_propostas: int
    g3_deferidas: int
    g3_indeferidas: int
    g3_taxa_aprovacao: float
    g3_por_mes: list[dict]

    g4_uso: list[dict]
    g4_mais_comum: str
    g4_tipos_ativos: int

    g5_top_setores: list[dict]
    g5_setor_lider: str
    g5_total_top10: int
    g5_setores_ativos: int

    g6_histograma: list[dict]
    g6_tempo_medio: float
    g6_tempo_minimo: float
    g6_tempo_maximo: float

    g7_scatter: list[dict]
    g7_area_media: float
    g7_media_cepac_m2: float
    g7_correlacao: float
