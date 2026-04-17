"""
Schemas Pydantic v2 para o endpoint POST /movimentacoes.
"""
from typing import Literal, Optional
from uuid import UUID

from pydantic import BaseModel, Field, field_validator


_ESTADOS_VALIDOS = {"DISPONIVEL", "EM_ANALISE", "CONSUMIDO", "QUARENTENA"}


class MovimentacaoIn(BaseModel):
    """Payload de entrada para POST /movimentacoes (transição manual de estado)."""

    titulo_id: UUID = Field(..., description="ID do título a transicionar")
    estado_novo: Literal["DISPONIVEL", "EM_ANALISE", "CONSUMIDO", "QUARENTENA"] = Field(
        ..., description="Novo estado do título"
    )
    numero_processo_sei: str = Field(
        ...,
        min_length=1,
        description="Número do processo SEI — obrigatório",
    )
    motivo: Optional[str] = Field(
        None,
        description="Motivo da transição (texto livre)",
    )

    @field_validator("numero_processo_sei")
    @classmethod
    def numero_sei_nao_pode_ser_vazio(cls, v: str) -> str:
        if not v or not v.strip():
            raise ValueError("numero_processo_sei não pode ser vazio")
        return v.strip()

    model_config = {"json_schema_extra": {
        "example": {
            "titulo_id": "00000000-0000-0000-0000-000000000001",
            "estado_novo": "CONSUMIDO",
            "numero_processo_sei": "6016.2024/0000001-0",
            "motivo": "Vinculação ao projeto X",
        }
    }}


class MovimentacaoOut(BaseModel):
    """Resposta de sucesso do POST /movimentacoes."""

    titulo_id: UUID
    estado_novo: str
    mensagem: str = "Transição registrada com sucesso."
