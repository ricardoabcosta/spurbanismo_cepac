"""
Modelo SQLAlchemy para a tabela `certidao`.
"""
from __future__ import annotations

from datetime import date, datetime
from typing import TYPE_CHECKING
from uuid import UUID

from sqlalchemy import Enum as SAEnum, ForeignKey, String, Text, text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base
from .enums import SituacaoCertidaoEnum, TipoCertidaoEnum

if TYPE_CHECKING:
    from .proposta import Proposta


class Certidao(Base):
    """
    Certidão de vinculação, desvinculação ou alteração emitida pela SP Urbanismo.

    Base do módulo de Consulta Pública de Autenticidade (T14) — acessível ao
    munícipe sem autenticação. Append-only: certidões não são deletadas.

    Formato número_certidao: AE-001/2024 (vinculação/alteração) ou DV-001/2026
    (desvinculação).
    """
    __tablename__ = "certidao"

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

    # --- Identificação da certidão ---
    numero_certidao: Mapped[str] = mapped_column(
        String(20), nullable=False, unique=True
    )
    tipo: Mapped[TipoCertidaoEnum] = mapped_column(
        SAEnum(TipoCertidaoEnum, name="tipo_certidao_enum", native_enum=True),
        nullable=False,
    )
    data_emissao: Mapped[date | None] = mapped_column(nullable=True)

    # Aceita padrões SIMPROC e SEI — D2
    numero_processo_sei: Mapped[str | None] = mapped_column(Text, nullable=True)

    situacao: Mapped[SituacaoCertidaoEnum] = mapped_column(
        SAEnum(SituacaoCertidaoEnum, name="situacao_certidao_enum", native_enum=True),
        nullable=False,
        server_default=text("'VALIDA'"),
    )

    # --- Auditoria ---
    created_at: Mapped[datetime] = mapped_column(
        nullable=False,
        server_default=text("now()"),
    )

    # --- Relacionamentos ---
    proposta: Mapped[Proposta] = relationship(
        "Proposta",
        back_populates="certidoes",
        lazy="select",
    )

    def __repr__(self) -> str:
        return (
            f"<Certidao id={self.id!s} numero={self.numero_certidao!r} "
            f"tipo={self.tipo.value!r} situacao={self.situacao.value!r}>"
        )
