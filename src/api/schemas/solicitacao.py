"""
Schemas Pydantic v2 para o endpoint POST /solicitacoes.
"""
from decimal import Decimal
from typing import Literal, Optional
from uuid import UUID

from pydantic import BaseModel, Field, field_validator


class SolicitacaoIn(BaseModel):
    """Payload de entrada para POST /solicitacoes."""

    setor: str = Field(..., min_length=1, description="Nome do setor da OUC")
    uso: Literal["R", "NR"] = Field(..., description="Uso: Residencial ou Não-Residencial")
    origem: Literal["ACA", "NUVEM"] = Field(..., description="Origem: ACA ou NUVEM")
    area_m2: Decimal = Field(..., gt=0, description="Área em m² solicitada")
    numero_processo_sei: str = Field(
        ...,
        min_length=1,
        description="Número do processo SEI — obrigatório e não vazio",
    )
    titulo_ids: list[UUID] = Field(..., min_length=1, description="IDs dos títulos a vincular")

    @field_validator("numero_processo_sei")
    @classmethod
    def numero_sei_nao_pode_ser_vazio(cls, v: str) -> str:
        if not v or not v.strip():
            raise ValueError("numero_processo_sei não pode ser vazio")
        return v.strip()

    model_config = {"json_schema_extra": {
        "example": {
            "setor": "Brooklin",
            "uso": "NR",
            "origem": "ACA",
            "area_m2": "1000.00",
            "numero_processo_sei": "6016.2024/0000001-0",
            "titulo_ids": ["00000000-0000-0000-0000-000000000001"],
        }
    }}


class SolicitacaoOut(BaseModel):
    """Resposta de sucesso do POST /solicitacoes."""

    solicitacao_id: UUID
    status: Literal["APROVADA"]
    area_m2: Decimal

    model_config = {"json_encoders": {Decimal: str}}


class ErroNegocioOut(BaseModel):
    """
    Resposta de erro de negócio (HTTP 422) do POST /solicitacoes.

    Estrutura padronizada para todos os erros de regra de negócio,
    compatível com os campos de RulesError.
    """

    codigo_erro: str
    mensagem: str
    setor: Optional[str] = None
    saldo_atual: Optional[Decimal] = None
    limite: Optional[Decimal] = None
    dias_restantes: Optional[int] = None

    model_config = {"json_encoders": {Decimal: str}}
