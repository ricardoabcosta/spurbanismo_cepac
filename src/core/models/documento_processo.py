"""
Modelo SQLAlchemy para a tabela `documento_processo`.
"""
from __future__ import annotations

from datetime import datetime
from typing import TYPE_CHECKING
from uuid import UUID

from sqlalchemy import BigInteger, ForeignKey, String, Text, text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base

if TYPE_CHECKING:
    from .proposta import Proposta
    from .usuario import Usuario


class DocumentoProcesso(Base):
    """
    Metadados de documentos armazenados no Azure Blob Storage.

    O arquivo físico nunca é armazenado no banco — apenas o caminho no Blob.
    Upload direto via SAS URL (T13). Append-only: trigger bloqueia DELETE.

    blob_path formato: {ano}/{mes}/{uuid}-{nome_arquivo}
    Container: cepac-documentos (private — acesso via SAS token).
    """
    __tablename__ = "documento_processo"

    # --- Chave primária ---
    id: Mapped[UUID] = mapped_column(
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )

    # --- FK: proposta ---
    proposta_id: Mapped[UUID] = mapped_column(
        ForeignKey("proposta.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )

    # Aceita padrões SIMPROC e SEI — D2
    numero_processo_sei: Mapped[str] = mapped_column(Text, nullable=False)

    # --- Metadados do arquivo ---
    nome_arquivo: Mapped[str] = mapped_column(String(500), nullable=False)
    blob_path: Mapped[str] = mapped_column(String(1000), nullable=False)
    content_type: Mapped[str | None] = mapped_column(String(100), nullable=True)
    tamanho_bytes: Mapped[int | None] = mapped_column(BigInteger, nullable=True)

    # --- Operador que realizou o upload ---
    operador_id: Mapped[UUID] = mapped_column(
        ForeignKey("usuario.id", ondelete="RESTRICT"),
        nullable=False,
    )

    # --- Auditoria ---
    created_at: Mapped[datetime] = mapped_column(
        nullable=False,
        server_default=text("now()"),
    )

    # --- Relacionamentos ---
    proposta: Mapped[Proposta] = relationship(
        "Proposta",
        back_populates="documentos",
        lazy="select",
    )
    operador: Mapped[Usuario] = relationship(
        "Usuario",
        lazy="select",
    )

    def __repr__(self) -> str:
        return (
            f"<DocumentoProcesso id={self.id!s} nome={self.nome_arquivo!r} "
            f"proposta_id={self.proposta_id!s}>"
        )
