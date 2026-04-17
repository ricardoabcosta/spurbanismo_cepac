"""
Modelo SQLAlchemy para a tabela `titulo_cepac`.
"""
from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from typing import TYPE_CHECKING
from uuid import UUID

from sqlalchemy import Enum as SAEnum, ForeignKey, Numeric, String, text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base
from .enums import EstadoTituloEnum, OrigemEnum, UsoEnum

if TYPE_CHECKING:
    from .setor import Setor
    from .movimentacao import Movimentacao
    from .solicitacao_titulos import SolicitacaoTitulos


class TituloCepac(Base):
    """
    Título CEPAC individual.

    O campo `estado` representa o estado atual e é atualizado a cada
    transição. O histórico completo de transições é preservado em `movimentacao`.
    """
    __tablename__ = "titulo_cepac"

    # --- Chave primária ---
    id: Mapped[UUID] = mapped_column(
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )

    # --- Identificação ---
    codigo: Mapped[str] = mapped_column(String(50), nullable=False, unique=True)

    # --- FK: setor ---
    setor_id: Mapped[UUID] = mapped_column(
        ForeignKey("setor.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )

    # --- Atributos do título ---
    valor_m2: Mapped[Decimal] = mapped_column(Numeric(15, 2), nullable=False)

    uso: Mapped[UsoEnum] = mapped_column(
        SAEnum(UsoEnum, name="uso_enum", native_enum=True),
        nullable=False,
    )
    origem: Mapped[OrigemEnum] = mapped_column(
        SAEnum(OrigemEnum, name="origem_enum", native_enum=True),
        nullable=False,
    )
    estado: Mapped[EstadoTituloEnum] = mapped_column(
        SAEnum(EstadoTituloEnum, name="estado_titulo_enum", native_enum=True),
        nullable=False,
        server_default=text("'DISPONIVEL'"),
    )

    # Preenchido quando o título entra em QUARENTENA
    data_desvinculacao: Mapped[datetime | None] = mapped_column(nullable=True)

    # --- Auditoria ---
    created_at: Mapped[datetime] = mapped_column(
        nullable=False,
        server_default=text("now()"),
    )
    updated_at: Mapped[datetime] = mapped_column(
        nullable=False,
        server_default=text("now()"),
        # O trigger trg_titulo_cepac_updated_at mantém este campo atualizado no banco.
        # Na aplicação, atualize-o explicitamente ou confie no trigger.
    )

    # --- Relacionamentos ---
    setor: Mapped[Setor] = relationship(
        "Setor",
        back_populates="titulos",
        lazy="select",
    )
    movimentacoes: Mapped[list[Movimentacao]] = relationship(
        "Movimentacao",
        back_populates="titulo",
        lazy="select",
    )
    solicitacao_titulos: Mapped[list[SolicitacaoTitulos]] = relationship(
        "SolicitacaoTitulos",
        back_populates="titulo",
        lazy="select",
    )

    def __repr__(self) -> str:
        return (
            f"<TituloCepac id={self.id!s} codigo={self.codigo!r} "
            f"estado={self.estado.value!r}>"
        )
