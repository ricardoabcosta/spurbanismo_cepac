"""
Schemas Pydantic v2 para os endpoints do Portal de Operações Técnicas (T15).
"""
from __future__ import annotations

import re
from datetime import date, datetime
from decimal import Decimal
from typing import Literal, Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator


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
    # Apenas R ou NR são aceitos no fluxo de vinculação de títulos.
    # MISTO é intencional somente em PropostaPortalIn (registro AE-XXXX),
    # onde uma proposta pode ter áreas residenciais e não-residenciais combinadas.
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
# Proposta — listagem paginada
# ---------------------------------------------------------------------------

class PropostaListItem(BaseModel):
    """Resposta leve para listagem de propostas — não expõe CPF/CNPJ."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    codigo: str
    setor: str
    interessado: Optional[str] = None
    uso_aca: Optional[str] = None
    cepac_total: Optional[int] = None
    status_pa: str
    data_proposta: Optional[date] = None
    requerimento: str
    situacao_certidao: Optional[str] = None


class PaginacaoProposta(BaseModel):
    """Resposta paginada de listagem de propostas."""

    items: list[PropostaListItem]
    total: int
    page: int
    page_size: int
    total_pages: int


class FiltrosPropostaList(BaseModel):
    """Filtros disponíveis para GET /portal/propostas."""

    setor_id: Optional[UUID] = None
    status_pa: Optional[str] = None   # ANALISE | DEFERIDO | INDEFERIDO
    data_inicio: Optional[date] = None
    data_fim: Optional[date] = None


# ---------------------------------------------------------------------------
# Certidão (item de lista dentro de uma proposta)
# ---------------------------------------------------------------------------

class CertidaoItem(BaseModel):
    """Certidão vinculada a uma proposta — retornada no detalhe GET /portal/propostas/{codigo}."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    numero_certidao: str
    tipo: str
    data_emissao: Optional[date] = None
    situacao: str
    numero_processo_sei: Optional[str] = None

    # Campos migration 013
    uso_aca: Optional[str] = None
    aca_r_m2: Optional[Decimal] = None
    aca_nr_m2: Optional[Decimal] = None
    aca_total_m2: Optional[Decimal] = None
    tipo_contrapartida: Optional[str] = None
    valor_oodc_rs: Optional[Decimal] = None
    cepac_aca: Optional[int] = None
    cepac_parametros: Optional[int] = None
    cepac_total: Optional[int] = None
    nuvem_r_m2: Optional[Decimal] = None
    nuvem_nr_m2: Optional[Decimal] = None
    nuvem_total_m2: Optional[Decimal] = None
    nuvem_cepac: Optional[int] = None
    contribuinte_sq: Optional[str] = None
    contribuinte_lote: Optional[str] = None
    obs: Optional[str] = None

    created_at: datetime


# ---------------------------------------------------------------------------
# Proposta (busca por código)
# ---------------------------------------------------------------------------

class PropostaPortalOut(BaseModel):
    """Dados completos de uma proposta para o portal técnico (inclui campos migration 012)."""

    # --- Campos históricos ---
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

    # --- Campos migration 012 ---
    data_proposta: Optional[date] = None
    tipo_interessado: Optional[str] = Field(
        default=None, description="Tipo do interessado: 'PF' ou 'PJ'"
    )
    cnpj: Optional[str] = None
    cpf: Optional[str] = None
    contribuinte_sq: Optional[str] = None
    contribuinte_lote: Optional[str] = None
    uso_aca: Optional[str] = Field(
        default=None, description="Uso ACA: R, NR ou MISTO"
    )
    aca_r_m2: Optional[Decimal] = None
    aca_nr_m2: Optional[Decimal] = None
    aca_total_m2: Optional[Decimal] = None
    tipo_contrapartida: Optional[str] = Field(
        default=None, description="Ex: 'CEPAC (título)'"
    )
    valor_oodc_rs: Optional[Decimal] = None
    cepac_aca: Optional[int] = None
    cepac_parametros: Optional[int] = None
    cepac_total: Optional[int] = None
    certidao: Optional[str] = None
    situacao_certidao: Optional[str] = None
    data_certidao: Optional[date] = None
    nuvem_r_m2: Optional[Decimal] = None
    nuvem_nr_m2: Optional[Decimal] = None
    nuvem_total_m2: Optional[Decimal] = None
    nuvem_cepac: Optional[int] = None
    obs: Optional[str] = None
    resp_data: Optional[str] = None
    cross_check: Optional[str] = None

    # --- Certidões vinculadas (carregadas via selectinload) ---
    certidoes: list[CertidaoItem] = Field(default_factory=list)

    model_config = {"from_attributes": True}


# ---------------------------------------------------------------------------
# Proposta — entrada (criar / editar)
# ---------------------------------------------------------------------------

class PropostaPortalIn(BaseModel):
    """
    Payload para criar ou editar uma proposta (campos migration 012).

    Regras de validação cruzada:
    - uso_aca == 'MISTO'  → aca_r_m2 e aca_nr_m2 obrigatórios
    - tipo_interessado == 'PJ' → cnpj obrigatório
    - tipo_interessado == 'PF' → cpf obrigatório
    """

    # --- Identificação ---
    codigo: Optional[str] = Field(
        default=None, description="Código AE-XXXX (obrigatório na criação)"
    )
    numero_pa: Optional[str] = None
    tipo_processo: Optional[str] = None
    data_autuacao: Optional[date] = None
    data_proposta: Optional[date] = None
    status_pa: Optional[str] = None

    # --- Interessado ---
    interessado: Optional[str] = Field(default=None, max_length=300)
    tipo_interessado: Optional[str] = Field(
        default=None, description="'PF' ou 'PJ'"
    )
    cnpj: Optional[str] = None
    cpf: Optional[str] = None
    cnpj_cpf: Optional[str] = Field(
        default=None, description="Campo legado — prefira cnpj / cpf"
    )
    endereco: Optional[str] = None

    # --- Setor e requerimento ---
    setor: Optional[str] = None
    requerimento: Optional[str] = None
    area_terreno_m2: Optional[Decimal] = Field(default=None, gt=0)
    observacao_alteracao: Optional[str] = None

    # --- Contribuinte / lote ---
    contribuinte_sq: Optional[str] = None
    contribuinte_lote: Optional[str] = None

    # --- Uso ACA ---
    uso_aca: Optional[str] = Field(
        default=None, description="R, NR ou MISTO"
    )
    aca_r_m2: Optional[Decimal] = Field(default=None, gt=0)
    aca_nr_m2: Optional[Decimal] = Field(default=None, gt=0)
    aca_total_m2: Optional[Decimal] = Field(default=None, gt=0)

    # --- Contrapartida e OODC ---
    tipo_contrapartida: Optional[str] = Field(
        default="CEPAC (título)", max_length=20
    )
    valor_oodc_rs: Optional[Decimal] = Field(default=None, ge=0)

    # --- CEPACs calculados ---
    cepac_aca: Optional[int] = Field(default=None, ge=0)
    cepac_parametros: Optional[int] = Field(default=None, ge=0)
    cepac_total: Optional[int] = Field(default=None, ge=0)

    # --- Certidão ---
    certidao: Optional[str] = Field(default=None, max_length=30)
    situacao_certidao: Optional[str] = Field(default=None, max_length=20)
    data_certidao: Optional[date] = None

    # --- NUVEM ---
    nuvem_r_m2: Optional[Decimal] = Field(default=None, gt=0)
    nuvem_nr_m2: Optional[Decimal] = Field(default=None, gt=0)
    nuvem_total_m2: Optional[Decimal] = Field(default=None, gt=0)
    nuvem_cepac: Optional[int] = Field(default=None, ge=0)

    # --- Controle interno ---
    obs: Optional[str] = None
    resp_data: Optional[str] = Field(default=None, max_length=100)
    cross_check: Optional[str] = Field(default=None, max_length=100)

    @field_validator("tipo_interessado")
    @classmethod
    def validar_tipo_interessado(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and v not in ("PF", "PJ"):
            raise ValueError("tipo_interessado deve ser 'PF' ou 'PJ'.")
        return v

    @field_validator("uso_aca")
    @classmethod
    def validar_uso_aca(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and v not in ("R", "NR", "MISTO"):
            raise ValueError("uso_aca deve ser 'R', 'NR' ou 'MISTO'.")
        return v

    @model_validator(mode="after")
    def validar_regras_cruzadas(self) -> "PropostaPortalIn":
        # Regra 1: uso_aca MISTO exige aca_r_m2 e aca_nr_m2
        if self.uso_aca == "MISTO":
            if self.aca_r_m2 is None:
                raise ValueError(
                    "aca_r_m2 é obrigatório quando uso_aca é 'MISTO'."
                )
            if self.aca_nr_m2 is None:
                raise ValueError(
                    "aca_nr_m2 é obrigatório quando uso_aca é 'MISTO'."
                )

        # Regra 2: PJ exige CNPJ
        if self.tipo_interessado == "PJ" and not self.cnpj:
            raise ValueError(
                "cnpj é obrigatório quando tipo_interessado é 'PJ'."
            )

        # Regra 3: PF exige CPF
        if self.tipo_interessado == "PF" and not self.cpf:
            raise ValueError(
                "cpf é obrigatório quando tipo_interessado é 'PF'."
            )

        return self

    model_config = {
        "json_schema_extra": {
            "example": {
                "codigo": "AE-0183",
                "tipo_interessado": "PJ",
                "cnpj": "12.345.678/0001-99",
                "uso_aca": "MISTO",
                "aca_r_m2": "500.00",
                "aca_nr_m2": "300.00",
                "aca_total_m2": "800.00",
                "tipo_contrapartida": "CEPAC (título)",
                "cepac_total": 12,
            }
        }
    }
