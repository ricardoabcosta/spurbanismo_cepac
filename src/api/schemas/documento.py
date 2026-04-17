"""
Schemas Pydantic v2 para os endpoints de documentos (T13).
"""
from __future__ import annotations

from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field


# ---------------------------------------------------------------------------
# Entrada
# ---------------------------------------------------------------------------

class DocumentoUploadUrlIn(BaseModel):
    """Payload para solicitar uma SAS URL de upload."""

    proposta_id: UUID = Field(..., description="ID da proposta à qual o documento pertence")
    numero_processo_sei: str = Field(
        ..., min_length=1, description="Número do processo SEI (SIMPROC ou SEI)"
    )
    nome_arquivo: str = Field(
        ..., min_length=1, max_length=500, description="Nome original do arquivo"
    )
    content_type: str = Field(
        ..., description="MIME type (application/pdf, image/png, etc.)"
    )
    tamanho_bytes: Optional[int] = Field(
        default=None,
        ge=1,
        description="Tamanho do arquivo em bytes (usado para validar limite de 50 MB)",
    )

    model_config = {
        "json_schema_extra": {
            "example": {
                "proposta_id": "00000000-0000-0000-0000-000000000001",
                "numero_processo_sei": "7810.2024/0001234-5",
                "nome_arquivo": "memorial_descritivo.pdf",
                "content_type": "application/pdf",
                "tamanho_bytes": 2097152,
            }
        }
    }


# ---------------------------------------------------------------------------
# Saída
# ---------------------------------------------------------------------------

class DocumentoUploadUrlOut(BaseModel):
    """Resposta com a SAS URL de upload e o ID do registro criado."""

    documento_id: UUID
    sas_url_upload: str = Field(
        ..., description="URL SAS para PUT direto no Azure Blob (TTL 30 min)"
    )
    blob_path: str = Field(..., description="Caminho do blob no container")
    expira_em: datetime = Field(..., description="Expiração da SAS URL de upload")


class DocumentoDownloadUrlOut(BaseModel):
    """Resposta com a SAS URL de download."""

    documento_id: UUID
    sas_url_download: str = Field(
        ..., description="URL SAS para GET do blob (TTL 1 hora)"
    )
    nome_arquivo: str
    expira_em: datetime


class DocumentoOut(BaseModel):
    """Metadados de um documento (sem SAS URL)."""

    id: UUID
    proposta_id: UUID
    numero_processo_sei: str
    nome_arquivo: str
    blob_path: str
    content_type: Optional[str]
    tamanho_bytes: Optional[int]
    operador_id: UUID
    created_at: datetime

    model_config = {"from_attributes": True}
