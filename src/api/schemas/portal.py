"""
Schemas Pydantic v2 para os endpoints do Portal de Operações Técnicas (T15).
"""
from __future__ import annotations

import re
from datetime import datetime
from decimal import Decimal
from typing import Literal, Optional
from uuid import UUID

from pydantic import BaseModel, Field, field_validator


# ---------------------------------------------------------------------------
# Validador SEI reutilizável (D2 — corrige achado T8-2)
# ---------------------------------------------------------------------------

# Padrão novo SEI:    7810.2024/0001234-5
_PATTERN_SEI = re.compile(r"^\d{4}\.\d{4}/\d{7}-\d$")
# Padrão antigo SIMPROC: 2005-0.060.565-0
_PATTERN_SIMPROC = re.compile(r"^\d{4}-\d\.\d{3}\.\d{3}-\d$")


def _validar_numero_sei(v: str) -> str:
    v = v.strip()
    if not (_PATTERN_SEI.match(v) or _PATTERN_SIMPROC.match(v)):
        raise ValueError(
            "Formato de processo SEI inválido. "
            "Use SEI (ex: 7810.2024/0001234-5) ou SIMPROC (ex: 2005-0.060.565-0)."
        )
    return v


# ---------------------------------------------------------------------------
# Entrada
# ---------------------------------------------------------------------------

class SolicitacaoPortalIn(BaseModel):
    """Payload para POST /portal/solicitacoes."""

    setor: str = Field(..., min_length=1, description="Nome do setor (ex: Brooklin)")
    uso: Literal["R", "NR"] = Field(..., description="Uso: Residencial ou Não-Residencial")
    origem: Literal["ACA", "NUVEM"] = Field(..., description="Origem do estoque")
    area_m2: Decimal = Field(..., gt=0, description="Área total solicitada em m²")
    numero_processo_sei: str = Field(
        ...,
        min_length=1,
        description="Número do processo SEI (padrão novo) ou SIMPROC (padrão antigo)",
    )
    titulo_ids: list[UUID] = Field(..., min_length=1, description="IDs dos títulos a vincular")
    proposta_codigo: Optional[str] = Field(
        default=None,
        description="Código da proposta AE-XXXX (vínculo opcional)",
    )
    observacao: Optional[str] = Field(
        default=None,
        max_length=1000,
        description="Observação livre do técnico",
    )

    @field_validator("numero_processo_sei")
    @classmethod
    def validar_sei(cls, v: str) -> str:
        return _validar_numero_sei(v)

    model_config = {
        "json_schema_extra": {
            "example": {
                "setor": "Brooklin",
                "uso": "NR",
                "origem": "ACA",
                "area_m2": "1000.00",
                "numero_processo_sei": "7810.2024/0001234-5",
                "titulo_ids": ["00000000-0000-0000-0000-000000000001"],
                "proposta_codigo": "AE-0183",
                "observacao": None,
            }
        }
    }


# ---------------------------------------------------------------------------
# Saída — item de lista / resposta de criação
# ---------------------------------------------------------------------------

class SolicitacaoPortalOut(BaseModel):
    """Resposta resumida de uma solicitação (criação e listagem)."""

    id: UUID
    status: str
    setor: str
    uso: str
    origem: str
    area_m2: Decimal
    quantidade_cepacs: int
    numero_processo_sei: str
    proposta_codigo: Optional[str] = None
    observacao: Optional[str] = None
    motivo_rejeicao: Optional[str] = None
    created_at: datetime

    model_config = {"from_attributes": True}


# ---------------------------------------------------------------------------
# Saída — detalhe completo
# ---------------------------------------------------------------------------

class TituloNoLoteOut(BaseModel):
    """Título CEPAC vinculado ao lote da solicitação."""

    id: UUID
    codigo: str
    setor: str
    uso: str
    origem: str
    estado: str
    valor_m2: Decimal
    area_m2_contribuicao: Decimal = Field(..., description="Área que este título contribui ao lote")

    model_config = {"from_attributes": True}


class SolicitacaoPortalDetalheOut(BaseModel):
    """Resposta detalhada: solicitação + lote de títulos."""

    id: UUID
    status: str
    setor: str
    uso: str
    origem: str
    area_m2: Decimal
    quantidade_cepacs: int
    numero_processo_sei: str
    proposta_codigo: Optional[str] = None
    observacao: Optional[str] = None
    motivo_rejeicao: Optional[str] = None
    created_at: datetime
    titulos: list[TituloNoLoteOut]

    model_config = {"from_attributes": True}


# ---------------------------------------------------------------------------
# Paginação
# ---------------------------------------------------------------------------

class PaginacaoSolicitacaoOut(BaseModel):
    """Resposta paginada de listagem de solicitações."""

    items: list[SolicitacaoPortalOut]
    total: int
    page: int
    page_size: int
    total_pages: int


# ---------------------------------------------------------------------------
# Títulos disponíveis
# ---------------------------------------------------------------------------

class TituloDisponivelOut(BaseModel):
    """Título CEPAC em estado DISPONIVEL (para seleção no portal)."""

    id: UUID
    codigo: str
    setor: str
    uso: str
    origem: str
    valor_m2: Decimal

    model_config = {"from_attributes": True}


# ---------------------------------------------------------------------------
# Proposta (busca por código)
# ---------------------------------------------------------------------------

class PropostaPortalOut(BaseModel):
    """Dados completos de uma proposta para o portal técnico."""

    id: UUID
    codigo: str
    numero_pa: Optional[str] = None
    tipo_processo: Optional[str] = None
    data_autuacao: Optional[str] = None
    status_pa: str
    interessado: Optional[str] = None
    cnpj_cpf: Optional[str] = None
    endereco: Optional[str] = None
    setor: str
    requerimento: str
    area_terreno_m2: Optional[Decimal] = None
    observacao_alteracao: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}
