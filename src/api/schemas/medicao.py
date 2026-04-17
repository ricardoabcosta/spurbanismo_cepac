"""
Schemas Pydantic v2 para os endpoints de medições de obra (T17).
"""
from __future__ import annotations

import re
from datetime import date, datetime
from decimal import Decimal
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field, field_validator

# Reutiliza os mesmos padrões SEI/SIMPROC definidos em portal.py (D2)
_PATTERN_SEI = re.compile(r"^\d{4}\.\d{4}/\d{7}-\d$")
_PATTERN_SIMPROC = re.compile(r"^\d{4}-\d\.\d{3}\.\d{3}-\d$")


# ---------------------------------------------------------------------------
# Entrada
# ---------------------------------------------------------------------------

class MedicaoIn(BaseModel):
    """Payload para POST /medicoes (DIRETOR)."""

    data_referencia: date = Field(
        ...,
        description="Primeiro dia do mês de competência (ex: 2026-05-01)",
    )
    valor_medicao: Decimal = Field(
        ..., gt=0, description="Valor da medição mensal em R$ (deve ser > 0)"
    )
    numero_processo_sei: str = Field(
        ...,
        min_length=1,
        description="Número do processo SEI ou SIMPROC vinculado à medição",
    )
    descricao: Optional[str] = Field(
        default=None,
        max_length=500,
        description="Descrição livre da medição",
    )

    @field_validator("data_referencia")
    @classmethod
    def data_deve_ser_primeiro_dia(cls, v: date) -> date:
        if v.day != 1:
            raise ValueError(
                f"data_referencia deve ser o primeiro dia do mês (recebido: {v})."
            )
        return v

    @field_validator("numero_processo_sei")
    @classmethod
    def validar_sei(cls, v: str) -> str:
        v = v.strip()
        if not (_PATTERN_SEI.match(v) or _PATTERN_SIMPROC.match(v)):
            raise ValueError(
                "Formato de processo SEI inválido. "
                "Use SEI (ex: 7810.2024/0001234-5) ou SIMPROC (ex: 2005-0.060.565-0)."
            )
        return v

    model_config = {
        "json_schema_extra": {
            "example": {
                "data_referencia": "2026-05-01",
                "valor_medicao": "125000000.00",
                "numero_processo_sei": "7810.2026/0000500-1",
                "descricao": "Medição maio/2026 — Lote 3 Marginal Pinheiros",
            }
        }
    }


# ---------------------------------------------------------------------------
# Saída
# ---------------------------------------------------------------------------

class MedicaoOut(BaseModel):
    """Resposta de uma medição registrada ou listada."""

    id: UUID
    data_referencia: date
    valor_medicao: Decimal
    valor_acumulado: Decimal = Field(
        ..., description="Custo total acumulado após esta medição (calculado pela aplicação)"
    )
    descricao: Optional[str] = None
    numero_processo_sei: str
    created_at: datetime

    model_config = {"from_attributes": True}


class MedicaoAtualOut(BaseModel):
    """Custo Total Incorrido atual — resposta de GET /medicoes/atual."""

    valor_acumulado: Decimal = Field(
        ..., description="Custo Total Incorrido atual em R$"
    )
    data_referencia: Optional[date] = Field(
        default=None, description="Competência da última medição registrada"
    )
    gerado_em: datetime = Field(..., description="Momento da consulta (UTC)")
