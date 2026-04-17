"""
Modelo SQLAlchemy para a tabela `setor`.

Armazena APENAS parâmetros estruturais imutáveis do setor.
Saldo de CEPACs é SEMPRE calculado a partir de `movimentacao` — nunca armazenado aqui.
"""
from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from typing import TYPE_CHECKING
from uuid import UUID

from sqlalchemy import Numeric, String, text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base

if TYPE_CHECKING:
    from .titulo_cepac import TituloCepac
    from .movimentacao import Movimentacao
    from .solicitacao_vinculacao import SolicitacaoVinculacao


class Setor(Base):
    """
    Setor da Operação Urbana Consorciada.

    Contém apenas parâmetros estruturais (estoque total, teto NR, reserva R).
    Nunca armazene saldos calculados aqui — use queries sobre `movimentacao`.
    """
    __tablename__ = "setor"

    # --- Chave primária ---
    id: Mapped[UUID] = mapped_column(
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )

    # --- Identificação ---
    nome: Mapped[str] = mapped_column(String(100), nullable=False, unique=True)

    # --- Parâmetros estruturais ---
    estoque_total_m2: Mapped[Decimal] = mapped_column(
        Numeric(15, 2), nullable=False
    )
    teto_nr_m2: Mapped[Decimal] = mapped_column(
        Numeric(15, 2), nullable=False
    )
    # NULL em todos os setores exceto Chucri Zaidan (216.442,47 m²)
    reserva_r_m2: Mapped[Decimal | None] = mapped_column(
        Numeric(15, 2), nullable=True
    )

    # --- Auditoria ---
    created_at: Mapped[datetime] = mapped_column(
        nullable=False,
        server_default=text("now()"),
    )

    # --- Relacionamentos ---
    titulos: Mapped[list[TituloCepac]] = relationship(
        "TituloCepac",
        back_populates="setor",
        lazy="select",
    )
    movimentacoes: Mapped[list[Movimentacao]] = relationship(
        "Movimentacao",
        back_populates="setor",
        lazy="select",
    )
    solicitacoes: Mapped[list[SolicitacaoVinculacao]] = relationship(
        "SolicitacaoVinculacao",
        back_populates="setor",
        lazy="select",
    )

    def __repr__(self) -> str:
        return f"<Setor id={self.id!s} nome={self.nome!r}>"
