"""
Schemas Pydantic v2 para os endpoints GET /titulos e GET /titulos/{id}/historico.
"""
from datetime import datetime
from decimal import Decimal
from typing import Literal, Optional
from uuid import UUID

from pydantic import BaseModel, Field


class TituloOut(BaseModel):
    """Representação de um título CEPAC na resposta da API."""

    id: UUID
    setor: str
    uso: Literal["R", "NR"]
    origem: Literal["ACA", "NUVEM"]
    estado: Literal["DISPONIVEL", "EM_ANALISE", "CONSUMIDO", "QUARENTENA"]
    valor_m2: Decimal
    data_desvinculacao: Optional[datetime] = None

    model_config = {"json_encoders": {Decimal: str}}


class MovimentacaoHistoricoOut(BaseModel):
    """
    Representação de uma entrada no histórico de movimentações de um título.

    Retornada pelo GET /titulos/{id}/historico em ordem cronológica.
    """

    id: UUID
    titulo_id: UUID
    estado_anterior: Optional[Literal["DISPONIVEL", "EM_ANALISE", "CONSUMIDO", "QUARENTENA"]] = None
    estado_novo: Literal["DISPONIVEL", "EM_ANALISE", "CONSUMIDO", "QUARENTENA"]
    numero_processo_sei: str
    motivo: Optional[str] = None
    operador: str
    created_at: datetime
