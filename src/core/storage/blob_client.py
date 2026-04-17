"""
src/core/storage/blob_client.py
SP Urbanismo / Prodam — CEPAC T13

Wrapper do SDK Azure Blob Storage para geração de SAS tokens.

O arquivo físico NUNCA transita pelo backend — upload direto pelo cliente
via SAS URL de escrita. O backend apenas:
  1. Gera o blob_path canônico
  2. Emite o SAS token via account key
  3. Persiste os metadados em documento_processo (tombstone)

Formato do blob_path: {ano}/{mes:02d}/{uuid4}-{nome_arquivo_sanitizado}
Container: cepac-documentos (private)

SAS de upload: PUT + CREATE, TTL 30 minutos
SAS de download: READ, TTL 1 hora

Tipos MIME permitidos (422 para qualquer outro):
  application/pdf
  application/vnd.openxmlformats-officedocument.wordprocessingml.document  (.docx)
  application/vnd.openxmlformats-officedocument.spreadsheetml.sheet         (.xlsx)
  image/jpeg
  image/png

Tamanho máximo: 50 MB (client-side; validado via content_length quando informado).
"""
from __future__ import annotations

import re
import uuid
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone

from fastapi import HTTPException, status

# ---------------------------------------------------------------------------
# Tipos MIME aceitos
# ---------------------------------------------------------------------------

CONTENT_TYPES_PERMITIDOS: dict[str, str] = {
    "application/pdf": ".pdf",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document": ".docx",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet": ".xlsx",
    "image/jpeg": ".jpg",
    "image/png": ".png",
}

TAMANHO_MAXIMO_BYTES = 50 * 1024 * 1024  # 50 MB

# ---------------------------------------------------------------------------
# SAS result
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class SasResult:
    sas_url: str
    expira_em: datetime


# ---------------------------------------------------------------------------
# Utilitários
# ---------------------------------------------------------------------------

def _sanitizar_nome(nome_arquivo: str) -> str:
    """
    Remove caracteres não-ASCII e perigosos do nome do arquivo.
    Substitui espaços e barras por underscores. Limita a 200 chars.
    """
    nome = re.sub(r"[^\w.\-]", "_", nome_arquivo, flags=re.ASCII)
    nome = nome[:200]
    return nome or "arquivo"


def gerar_blob_path(nome_arquivo: str) -> str:
    """
    Gera o caminho canônico do blob: {ano}/{mes:02d}/{uuid4}-{nome_sanitizado}

    Exemplo: 2026/04/3f2e1d0c-...-arquivo.pdf
    """
    agora = datetime.now(tz=timezone.utc)
    nome = _sanitizar_nome(nome_arquivo)
    uid = uuid.uuid4()
    return f"{agora.year}/{agora.month:02d}/{uid}-{nome}"


# ---------------------------------------------------------------------------
# Validações
# ---------------------------------------------------------------------------

def validar_content_type(content_type: str) -> None:
    """Levanta HTTPException(422) se o tipo MIME não for permitido."""
    ct = content_type.split(";")[0].strip().lower()
    if ct not in CONTENT_TYPES_PERMITIDOS:
        permitidos = ", ".join(sorted(CONTENT_TYPES_PERMITIDOS))
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=(
                f"Tipo de arquivo não permitido: '{ct}'. "
                f"Aceitos: {permitidos}."
            ),
        )


def validar_tamanho(tamanho_bytes: int | None) -> None:
    """Levanta HTTPException(422) se o tamanho exceder 50 MB."""
    if tamanho_bytes is not None and tamanho_bytes > TAMANHO_MAXIMO_BYTES:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=(
                f"Arquivo excede o tamanho máximo permitido de 50 MB "
                f"({tamanho_bytes:,} bytes informados)."
            ),
        )


# ---------------------------------------------------------------------------
# Geração de SAS tokens
# ---------------------------------------------------------------------------

def gerar_sas_upload(
    blob_path: str,
    content_type: str,
    account_name: str,
    container_name: str,
    account_key: str,
) -> SasResult:
    """
    Gera SAS URL de escrita (PUT + CREATE) com TTL de 30 minutos.

    O cliente usa esta URL para fazer PUT diretamente no Azure Blob.
    """
    from azure.storage.blob import (
        BlobSasPermissions,
        generate_blob_sas,
    )

    agora = datetime.now(tz=timezone.utc)
    expira = agora + timedelta(minutes=30)

    sas_token = generate_blob_sas(
        account_name=account_name,
        container_name=container_name,
        blob_name=blob_path,
        account_key=account_key,
        permission=BlobSasPermissions(write=True, create=True),
        expiry=expira,
        content_type=content_type,
    )

    sas_url = (
        f"https://{account_name}.blob.core.windows.net"
        f"/{container_name}/{blob_path}?{sas_token}"
    )
    return SasResult(sas_url=sas_url, expira_em=expira)


def gerar_sas_download(
    blob_path: str,
    account_name: str,
    container_name: str,
    account_key: str,
) -> SasResult:
    """
    Gera SAS URL de leitura (READ) com TTL de 1 hora.
    """
    from azure.storage.blob import (
        BlobSasPermissions,
        generate_blob_sas,
    )

    agora = datetime.now(tz=timezone.utc)
    expira = agora + timedelta(hours=1)

    sas_token = generate_blob_sas(
        account_name=account_name,
        container_name=container_name,
        blob_name=blob_path,
        account_key=account_key,
        permission=BlobSasPermissions(read=True),
        expiry=expira,
    )

    sas_url = (
        f"https://{account_name}.blob.core.windows.net"
        f"/{container_name}/{blob_path}?{sas_token}"
    )
    return SasResult(sas_url=sas_url, expira_em=expira)


# ---------------------------------------------------------------------------
# Guard de configuração
# ---------------------------------------------------------------------------

def _require_blob_config(account_name: str | None, account_key: str | None) -> None:
    """Levanta HTTPException(503) se as credenciais Blob não estiverem configuradas."""
    if not account_name or not account_key:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=(
                "Azure Blob Storage não configurado — defina "
                "AZURE_BLOB_ACCOUNT_NAME e AZURE_BLOB_ACCOUNT_KEY."
            ),
        )
