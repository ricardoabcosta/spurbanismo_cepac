"""
Schemas Pydantic v2 para os endpoints de administração (/admin).
"""
from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field


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
