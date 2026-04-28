"""
Rotas de documentos (T13) — gerenciamento de arquivos via Azure Blob Storage.

Endpoints:
  POST /documentos/upload-url   — gera SAS URL de upload, cria tombstone
  GET  /documentos/{id}/download-url — gera SAS URL de download
  GET  /documentos              — lista documentos de uma proposta

O arquivo físico NUNCA transita pelo backend — upload direto via SAS URL.

Requer autenticação Azure AD com papel TECNICO ou DIRETOR (T12).
"""
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.auth.dependencies import UsuarioAutenticado, require_tecnico
from src.api.dependencies import get_db
from src.api.schemas.documento import (
    DocumentoDownloadUrlOut,
    DocumentoOut,
    DocumentoUploadUrlIn,
    DocumentoUploadUrlOut,
)
from src.config import settings
from src.core.models.documento_processo import DocumentoProcesso
from src.core.storage.blob_client import (
    _require_blob_config,
    gerar_blob_path,
    gerar_sas_download,
    gerar_sas_upload,
    validar_content_type,
    validar_tamanho,
)

router = APIRouter(prefix="/documentos", tags=["documentos"])


@router.post(
    "/upload-url",
    response_model=DocumentoUploadUrlOut,
    status_code=status.HTTP_201_CREATED,
    summary="Solicitar SAS URL de upload para um documento",
)
async def solicitar_upload_url(
    payload: DocumentoUploadUrlIn,
    session: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[UsuarioAutenticado, Depends(require_tecnico)],
) -> DocumentoUploadUrlOut:
    """
    Valida o tipo de arquivo e o tamanho, gera o blob_path canônico,
    cria o registro tombstone em `documento_processo` e retorna a SAS URL
    de upload (PUT direto no Azure Blob, TTL 30 minutos).

    O cliente deve fazer PUT para `sas_url_upload` com o conteúdo do arquivo
    e o header `Content-Type` correspondente.
    """
    _require_blob_config(settings.azure_blob_account_name, settings.azure_blob_account_key)

    validar_content_type(payload.content_type)
    validar_tamanho(payload.tamanho_bytes)

    blob_path = gerar_blob_path(payload.nome_arquivo)

    assert settings.azure_blob_account_name is not None
    assert settings.azure_blob_account_key is not None
    sas = gerar_sas_upload(
        blob_path=blob_path,
        content_type=payload.content_type,
        account_name=settings.azure_blob_account_name,
        container_name=settings.azure_blob_container_name,
        account_key=settings.azure_blob_account_key,
    )

    doc = DocumentoProcesso(
        proposta_id=payload.proposta_id,
        numero_processo_sei=payload.numero_processo_sei,
        nome_arquivo=payload.nome_arquivo,
        blob_path=blob_path,
        content_type=payload.content_type,
        tamanho_bytes=payload.tamanho_bytes,
        operador_id=current_user.id,
    )
    session.add(doc)
    await session.commit()
    await session.refresh(doc)

    return DocumentoUploadUrlOut(
        documento_id=doc.id,
        sas_url_upload=sas.sas_url,
        blob_path=blob_path,
        expira_em=sas.expira_em,
    )


@router.get(
    "/{documento_id}/download-url",
    response_model=DocumentoDownloadUrlOut,
    status_code=status.HTTP_200_OK,
    summary="Obter SAS URL de download para um documento",
)
async def obter_download_url(
    documento_id: UUID,
    session: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[UsuarioAutenticado, Depends(require_tecnico)],
) -> DocumentoDownloadUrlOut:
    """
    Busca os metadados do documento e emite SAS URL de leitura (TTL 1 hora).

    Retorna 404 se o documento não existir.
    """
    _require_blob_config(settings.azure_blob_account_name, settings.azure_blob_account_key)

    result = await session.execute(
        select(DocumentoProcesso).where(DocumentoProcesso.id == documento_id)
    )
    doc = result.scalar_one_or_none()
    if doc is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Documento {documento_id} não encontrado.",
        )

    assert settings.azure_blob_account_name is not None
    assert settings.azure_blob_account_key is not None
    sas = gerar_sas_download(
        blob_path=doc.blob_path,
        account_name=settings.azure_blob_account_name,
        container_name=settings.azure_blob_container_name,
        account_key=settings.azure_blob_account_key,
    )

    return DocumentoDownloadUrlOut(
        documento_id=doc.id,
        sas_url_download=sas.sas_url,
        nome_arquivo=doc.nome_arquivo,
        expira_em=sas.expira_em,
    )


@router.get(
    "",
    response_model=list[DocumentoOut],
    status_code=status.HTTP_200_OK,
    summary="Listar documentos de uma proposta",
)
async def listar_documentos(
    proposta_id: Annotated[UUID, Query(..., description="ID da proposta")],
    session: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[UsuarioAutenticado, Depends(require_tecnico)],
) -> list[DocumentoOut]:
    """
    Retorna todos os documentos vinculados à proposta informada,
    ordenados por data de criação descendente.
    """
    result = await session.execute(
        select(DocumentoProcesso)
        .where(DocumentoProcesso.proposta_id == proposta_id)
        .order_by(DocumentoProcesso.created_at.desc())
    )
    docs = result.scalars().all()
    return [DocumentoOut.model_validate(d) for d in docs]
