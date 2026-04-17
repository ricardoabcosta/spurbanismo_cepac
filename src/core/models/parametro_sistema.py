"""
Modelo SQLAlchemy para a tabela `parametro_sistema`.
"""
from __future__ import annotations

from datetime import datetime
from typing import TYPE_CHECKING
from uuid import UUID

from sqlalchemy import ForeignKey, String, Text, text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base

if TYPE_CHECKING:
    from .usuario import Usuario


class ParametroSistema(Base):
    """
    Parâmetros configuráveis do sistema CEPAC.

    Atualizável por DIRETOR via endpoint administrativo. Chaves predefinidas:
    - cepacs_em_circulacao: 193779 (D5 — fonte: planilha XLSX)
    - data_inicio_oucae: 2004-01-01 (D3)
    """
    __tablename__ = "parametro_sistema"

    # --- Chave primária (chave do parâmetro) ---
    chave: Mapped[str] = mapped_column(String(100), primary_key=True)

    valor: Mapped[str] = mapped_column(Text, nullable=False)
    descricao: Mapped[str | None] = mapped_column(Text, nullable=True)

    updated_at: Mapped[datetime] = mapped_column(
        nullable=False,
        server_default=text("now()"),
    )

    # Último operador que alterou (NULL = seed inicial)
    operador_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("usuario.id", ondelete="SET NULL"),
        nullable=True,
    )

    # --- Relacionamentos ---
    operador: Mapped[Usuario | None] = relationship(
        "Usuario",
        lazy="select",
    )

    def __repr__(self) -> str:
        return f"<ParametroSistema chave={self.chave!r} valor={self.valor!r}>"
