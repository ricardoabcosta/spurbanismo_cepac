"""
Schemas Pydantic v2 para os endpoints de administração (/admin).
"""
from __future__ import annotations

from datetime import date, datetime
from decimal import Decimal
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field

from src.core.models.enums import PapelUsuarioEnum


class SetorIn(BaseModel):
    """Payload para criar ou atualizar um setor."""
    nome: str = Field(..., min_length=1, max_length=100)
    estoque_total_m2: Decimal = Field(..., gt=0)
    teto_nr_m2: Decimal = Field(..., gt=0)
    teto_r_m2: Optional[Decimal] = Field(None, gt=0)
    reserva_r_m2: Optional[Decimal] = Field(None, gt=0)
    piso_r_percentual: Optional[Decimal] = Field(None, ge=0, le=100)
    bloqueio_nr: bool = False
    ativo: bool = True
    cepacs_convertidos_aca: int = 0
    cepacs_convertidos_parametros: int = 0
    cepacs_desvinculados_aca: int = 0
    cepacs_desvinculados_parametros: int = 0
    operacao_urbana_id: int = Field(..., gt=0)
    setor_pai_id: Optional[UUID] = None
    fator_equivalencia_f1: Optional[Decimal] = Field(None, ge=0)
    fator_equivalencia_f2: Optional[Decimal] = Field(None, ge=0)


class SetorOut(BaseModel):
    """Representação de um setor para o cliente."""
    id: UUID
    nome: str
    estoque_total_m2: Decimal
    teto_nr_m2: Decimal
    teto_r_m2: Optional[Decimal]
    reserva_r_m2: Optional[Decimal]
    piso_r_percentual: Optional[Decimal]
    bloqueio_nr: bool
    ativo: bool
    created_at: datetime
    cepacs_convertidos_aca: int
    cepacs_convertidos_parametros: int
    cepacs_desvinculados_aca: int
    cepacs_desvinculados_parametros: int
    operacao_urbana_id: int
    setor_pai_id: Optional[UUID]
    fator_equivalencia_f1: Optional[Decimal]
    fator_equivalencia_f2: Optional[Decimal]

    model_config = {"from_attributes": True}


class OperacaoUrbanaIn(BaseModel):
    """Payload para criar ou atualizar uma Operação Urbana Consorciada."""
    nome: str = Field(..., min_length=1, max_length=100)
    sigla: str = Field(..., min_length=1, max_length=5)
    lei_vigente: Optional[str] = None
    estoque_maximo_global_r: Optional[Decimal] = Field(None, ge=0)
    estoque_maximo_global_nr: Optional[Decimal] = Field(None, ge=0)
    possui_nuvem: bool = False
    valor_cepac_ref: Optional[Decimal] = Field(None, ge=0)
    data_ultima_posicao: Optional[date] = None
    ativo: bool = True
    teto_r_nao_incentivado_m2: Optional[Decimal] = Field(None, ge=0)
    # Campos migrados de configuracao_operacao (Fase 3, Opção B):
    reserva_tecnica_m2: Decimal = Field(Decimal("0"), ge=0)
    cepacs_leiloados: int = Field(0, ge=0)
    cepacs_colocacao_privada: int = Field(0, ge=0)
    cepacs_totais: int = Field(0, ge=0)


class OperacaoUrbanaOut(BaseModel):
    """Representação de uma Operação Urbana Consorciada para o cliente."""
    id: int
    nome: str
    sigla: str
    lei_vigente: Optional[str]
    estoque_maximo_global_r: Optional[Decimal]
    estoque_maximo_global_nr: Optional[Decimal]
    possui_nuvem: bool
    valor_cepac_ref: Optional[Decimal]
    data_ultima_posicao: Optional[date]
    ativo: bool
    teto_r_nao_incentivado_m2: Optional[Decimal]
    reserva_tecnica_m2: Decimal
    cepacs_leiloados: int
    cepacs_colocacao_privada: int
    cepacs_totais: int

    model_config = {"from_attributes": True}


class OperacaoUrbanaResumo(BaseModel):
    """Versão compacta para comboboxes (filtro de Propostas etc.)."""
    id: int
    sigla: str
    nome: str
    ativo: bool

    model_config = {"from_attributes": True}


class ConfiguracaoIn(BaseModel):
    """Payload para atualizar a configuração global da operação."""
    reserva_tecnica_m2: Decimal = Field(..., ge=0, description="Reserva técnica em m²")
    cepacs_leiloados: int = Field(0, ge=0)
    cepacs_colocacao_privada: int = Field(0, ge=0)
    cepacs_totais: int = Field(0, ge=0)


class ConfiguracaoOut(BaseModel):
    """Configuração global da operação."""
    reserva_tecnica_m2: Decimal
    cepacs_leiloados: int
    cepacs_colocacao_privada: int
    cepacs_totais: int
    updated_at: datetime

    model_config = {"from_attributes": True}


class UsuarioOut(BaseModel):
    """Representação de um usuário para o cliente."""
    id: UUID
    upn: str
    nome: Optional[str]
    papel: PapelUsuarioEnum
    ativo: bool
    created_at: datetime
    last_login_at: Optional[datetime]

    model_config = {"from_attributes": True}


class PapelUpdate(BaseModel):
    """Payload para alterar o papel de um usuário."""
    papel: PapelUsuarioEnum


class AtivoUpdate(BaseModel):
    """Payload para ativar ou desativar um usuário."""
    ativo: bool


# ---------------------------------------------------------------------------
# Lei OUC — catálogo de leis por operação urbana
# ---------------------------------------------------------------------------

class LeiOucIn(BaseModel):
    """Payload para criar uma lei."""
    operacao_urbana_id: int = Field(..., gt=0)
    identificador: str = Field(..., min_length=1, max_length=30)
    nome: Optional[str] = None
    data_vigencia_inicio: Optional[date] = None
    data_vigencia_fim: Optional[date] = None
    ordem: int = Field(..., gt=0)
    vigente: bool = False
    consumo_historico_r_m2: Optional[Decimal] = Field(None, ge=0)
    consumo_historico_nr_m2: Optional[Decimal] = Field(None, ge=0)
    estoque_geral_m2: Optional[Decimal] = Field(None, ge=0)


class LeiOucOut(BaseModel):
    """Representação de uma lei."""
    id: int
    operacao_urbana_id: int
    identificador: str
    nome: Optional[str]
    data_vigencia_inicio: Optional[date]
    data_vigencia_fim: Optional[date]
    ordem: int
    vigente: bool
    consumo_historico_r_m2: Optional[Decimal]
    consumo_historico_nr_m2: Optional[Decimal]
    estoque_geral_m2: Optional[Decimal]

    model_config = {"from_attributes": True}


class LeiOucUpdate(BaseModel):
    """Payload para atualizar uma lei (campos opcionais)."""
    nome: Optional[str] = None
    data_vigencia_inicio: Optional[date] = None
    data_vigencia_fim: Optional[date] = None
    ordem: Optional[int] = None
    vigente: Optional[bool] = None
    consumo_historico_r_m2: Optional[Decimal] = None
    consumo_historico_nr_m2: Optional[Decimal] = None
    estoque_geral_m2: Optional[Decimal] = None


# ---------------------------------------------------------------------------
# SetorEstoqueLei — estoque por setor × lei
# ---------------------------------------------------------------------------

class SetorEstoqueLeiIn(BaseModel):
    """Payload para criar registro de estoque por lei."""
    setor_id: UUID = Field(...)
    lei_ouc_id: int = Field(..., gt=0)
    estoque_total_r_m2: Decimal = Field(..., ge=0)
    estoque_total_nr_m2: Decimal = Field(..., ge=0)
    teto_r_m2: Optional[Decimal] = Field(None, ge=0)
    teto_nr_m2: Optional[Decimal] = Field(None, ge=0)
    reserva_r_m2: Optional[Decimal] = Field(None, ge=0)


class SetorEstoqueLeiOut(BaseModel):
    """Representação do estoque por lei."""
    id: int
    setor_id: UUID
    lei_ouc_id: int
    estoque_total_r_m2: Decimal
    estoque_total_nr_m2: Decimal
    teto_r_m2: Optional[Decimal]
    teto_nr_m2: Optional[Decimal]
    reserva_r_m2: Optional[Decimal]

    model_config = {"from_attributes": True}
