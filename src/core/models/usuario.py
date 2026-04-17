"""
Modelo SQLAlchemy para a tabela `usuario`.
"""
from __future__ import annotations

from datetime import datetime
from uuid import UUID

from sqlalchemy import Boolean, Enum as SAEnum, String, text
from sqlalchemy.orm import Mapped, mapped_column

from .base import Base
from .enums import PapelUsuarioEnum


class Usuario(Base):
    """
    Usuário autenticado via Azure AD (MSAL).

    Roles (TECNICO/DIRETOR) gerenciados internamente no banco — não usa App Roles
    do Azure AD (D4). Criado automaticamente no primeiro login com papel=TECNICO.

    Promoção a DIRETOR: endpoint PATCH /admin/usuarios/{id}/papel (só DIRETOR).
    """
    __tablename__ = "usuario"

    # --- Chave primária ---
    id: Mapped[UUID] = mapped_column(
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )

    # User Principal Name do Azure AD (ex: joao.silva@spurbanismo.sp.gov.br)
    upn: Mapped[str] = mapped_column(String(200), nullable=False, unique=True)
    nome: Mapped[str | None] = mapped_column(String(200), nullable=True)

    papel: Mapped[PapelUsuarioEnum] = mapped_column(
        SAEnum(PapelUsuarioEnum, name="papel_usuario_enum", native_enum=True),
        nullable=False,
        server_default=text("'TECNICO'"),
    )
    ativo: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=text("true")
    )

    # --- Auditoria ---
    created_at: Mapped[datetime] = mapped_column(
        nullable=False,
        server_default=text("now()"),
    )
    last_login_at: Mapped[datetime | None] = mapped_column(nullable=True)

    def __repr__(self) -> str:
        return (
            f"<Usuario id={self.id!s} upn={self.upn!r} papel={self.papel.value!r}>"
        )
