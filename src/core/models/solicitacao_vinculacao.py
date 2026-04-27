"""
Modelo SQLAlchemy para a tabela `solicitacao_vinculacao`.
"""
from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from typing import TYPE_CHECKING
from uuid import UUID

from sqlalchemy import Enum as SAEnum, ForeignKey, Integer, Numeric, String, Text, text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base
from .enums import OrigemEnum, StatusSolicitacaoEnum, UsoEnum

if TYPE_CHECKING:
    from .proposta import Proposta
    from .setor import Setor
    from .solicitacao_titulos import SolicitacaoTitulos


class SolicitacaoVinculacao(Base):
    """
    Solicitação de vinculação de CEPACs a um processo SEI.

    Ao ser aprovada, os títulos associados via `solicitacao_titulos` transitam
    para o estado CONSUMIDO, gerando registros em `movimentacao`.
    """
    __tablename__ = "solicitacao_vinculacao"

    # --- Chave primária ---
    id: Mapped[UUID] = mapped_column(
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )

    # --- FK: setor ---
    setor_id: Mapped[UUID] = mapped_column(
        ForeignKey("setor.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )

    # --- Atributos da solicitação ---
    uso: Mapped[UsoEnum] = mapped_column(
        SAEnum(UsoEnum, name="uso_enum", native_enum=True),
        nullable=False,
    )
    origem: Mapped[OrigemEnum] = mapped_column(
        SAEnum(OrigemEnum, name="origem_enum", native_enum=True),
        nullable=False,
    )

    # m² total solicitados — deve ser > 0 (garantido por CHECK no banco)
    area_m2: Mapped[Decimal] = mapped_column(Numeric(15, 2), nullable=False)

    # quantidade de CEPACs necessários — deve ser > 0 (garantido por CHECK no banco)
    quantidade_cepacs: Mapped[int] = mapped_column(Integer, nullable=False)

    # Número do processo SEI — obrigatório e não vazio (CHECK no banco)
    numero_processo_sei: Mapped[str] = mapped_column(String(50), nullable=False)

    status: Mapped[StatusSolicitacaoEnum] = mapped_column(
        SAEnum(StatusSolicitacaoEnum, name="status_solicitacao_enum", native_enum=True),
        nullable=False,
        server_default=text("'EM_ANALISE'"),
    )

    # Obrigatório quando status = REJEITADA (CHECK de consistência no banco)
    motivo_rejeicao: Mapped[str | None] = mapped_column(Text, nullable=True)

    # --- Campos adicionados em T15 (migration 005) ---
    # Vínculo opcional à proposta conhecida (AE-XXXX)
    proposta_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("proposta.id", ondelete="RESTRICT"),
        nullable=True,
        index=False,  # índice criado manualmente na migration (WHERE proposta_id IS NOT NULL)
    )
    # Observação livre do técnico ao registrar a solicitação
    observacao: Mapped[str | None] = mapped_column(Text, nullable=True)

    # --- Auditoria ---
    created_at: Mapped[datetime] = mapped_column(
        nullable=False,
        server_default=text("now()"),
    )

    # --- Relacionamentos ---
    setor: Mapped[Setor] = relationship(
        "Setor",
        back_populates="solicitacoes",
        lazy="select",
    )
    proposta: Mapped[Proposta | None] = relationship(
        "Proposta",
        lazy="select",
    )
    solicitacao_titulos: Mapped[list[SolicitacaoTitulos]] = relationship(
        "SolicitacaoTitulos",
        back_populates="solicitacao",
        lazy="select",
        cascade="all, delete-orphan",
    )

    def __repr__(self) -> str:
        return (
            f"<SolicitacaoVinculacao id={self.id!s} "
            f"processo={self.numero_processo_sei!r} status={self.status.value!r}>"
        )
