"""
Modelo SQLAlchemy para a tabela `proposta`.
"""
from __future__ import annotations

from datetime import date, datetime
from decimal import Decimal
from typing import TYPE_CHECKING
from uuid import UUID

from sqlalchemy import Enum as SAEnum, ForeignKey, Numeric, String, Text, text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base
from .enums import RequerimentoEnum, StatusPaEnum, TipoProcessoEnum

if TYPE_CHECKING:
    from .certidao import Certidao
    from .documento_processo import DocumentoProcesso
    from .setor import Setor


class Proposta(Base):
    """
    Projeto/empreendimento que solicitou vinculação de CEPACs na OUCAE.

    Código no formato AE-XXXX. Agrupa todas as certidões de emenda do mesmo
    projeto. Certidões de alteração: usar sempre a mais recente VALIDA (D7).
    """
    __tablename__ = "proposta"

    # --- Chave primária ---
    id: Mapped[UUID] = mapped_column(
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )

    # --- Identificação ---
    codigo: Mapped[str] = mapped_column(String(20), nullable=False, unique=True)

    # Processo administrativo — aceita SIMPROC (2004–2015) e SEI (2016+) — D2
    numero_pa: Mapped[str | None] = mapped_column(Text, nullable=True)
    tipo_processo: Mapped[TipoProcessoEnum | None] = mapped_column(
        SAEnum(TipoProcessoEnum, name="tipo_processo_enum", native_enum=True),
        nullable=True,
    )
    data_autuacao: Mapped[date | None] = mapped_column(nullable=True)

    status_pa: Mapped[StatusPaEnum] = mapped_column(
        SAEnum(StatusPaEnum, name="status_pa_enum", native_enum=True),
        nullable=False,
        server_default=text("'ANALISE'"),
    )

    # --- Interessado ---
    interessado: Mapped[str | None] = mapped_column(String(300), nullable=True)
    cnpj_cpf: Mapped[str | None] = mapped_column(String(20), nullable=True)
    endereco: Mapped[str | None] = mapped_column(Text, nullable=True)

    # --- FK: setor ---
    setor_id: Mapped[UUID] = mapped_column(
        ForeignKey("setor.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )

    # --- Requerimento e área ---
    requerimento: Mapped[RequerimentoEnum] = mapped_column(
        SAEnum(RequerimentoEnum, name="requerimento_enum", native_enum=True),
        nullable=False,
    )
    area_terreno_m2: Mapped[Decimal | None] = mapped_column(
        Numeric(15, 2), nullable=True
    )

    # Preenchido quando certidão de alteração tem área diferente — D7
    observacao_alteracao: Mapped[str | None] = mapped_column(Text, nullable=True)

    # --- Auditoria ---
    created_at: Mapped[datetime] = mapped_column(
        nullable=False,
        server_default=text("now()"),
    )
    updated_at: Mapped[datetime] = mapped_column(
        nullable=False,
        server_default=text("now()"),
        # Mantido pelo trigger trg_proposta_updated_at (reutiliza fn_set_updated_at).
    )

    # --- Relacionamentos ---
    setor: Mapped[Setor] = relationship(
        "Setor",
        lazy="select",
    )
    certidoes: Mapped[list[Certidao]] = relationship(
        "Certidao",
        back_populates="proposta",
        lazy="select",
    )
    documentos: Mapped[list[DocumentoProcesso]] = relationship(
        "DocumentoProcesso",
        back_populates="proposta",
        lazy="select",
    )

    def __repr__(self) -> str:
        return (
            f"<Proposta id={self.id!s} codigo={self.codigo!r} "
            f"status_pa={self.status_pa.value!r}>"
        )
