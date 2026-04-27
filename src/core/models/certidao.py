"""
Modelo SQLAlchemy para a tabela `certidao`.
"""
from __future__ import annotations

from datetime import date, datetime
from decimal import Decimal
from typing import TYPE_CHECKING, Optional
from uuid import UUID

from sqlalchemy import Enum as SAEnum, ForeignKey, Integer, Numeric, String, Text, text
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
        # values_callable garante que SQLAlchemy use os .value (acentuados: VINCULAÇÃO…)
        # e não os .name (VINCULACAO…) como chave de lookup — necessário no Python 3.12.
        SAEnum(
            TipoCertidaoEnum,
            name="tipo_certidao_enum",
            native_enum=True,
            values_callable=lambda x: [i.value for i in x],
        ),
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

    # --- Campos migration 013: dados da planilha por linha ---

    # Uso ACA
    uso_aca: Mapped[Optional[str]] = mapped_column(String(10), nullable=True)

    # Áreas ACA em m²
    aca_r_m2: Mapped[Optional[Decimal]] = mapped_column(Numeric(15, 2), nullable=True)
    aca_nr_m2: Mapped[Optional[Decimal]] = mapped_column(Numeric(15, 2), nullable=True)
    aca_total_m2: Mapped[Optional[Decimal]] = mapped_column(Numeric(15, 2), nullable=True)

    # Contrapartida e OODC
    tipo_contrapartida: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    valor_oodc_rs: Mapped[Optional[Decimal]] = mapped_column(Numeric(18, 2), nullable=True)

    # CEPACs calculados
    cepac_aca: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    cepac_parametros: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    cepac_total: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)

    # Áreas NUVEM em m²
    nuvem_r_m2: Mapped[Optional[Decimal]] = mapped_column(Numeric(15, 2), nullable=True)
    nuvem_nr_m2: Mapped[Optional[Decimal]] = mapped_column(Numeric(15, 2), nullable=True)
    nuvem_total_m2: Mapped[Optional[Decimal]] = mapped_column(Numeric(15, 2), nullable=True)
    nuvem_cepac: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)

    # Contribuinte / lote
    contribuinte_sq: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    contribuinte_lote: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    # Observações livres
    obs: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

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
