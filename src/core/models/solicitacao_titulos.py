"""
Modelo SQLAlchemy para a tabela `solicitacao_titulos`.

Tabela de junção N:N entre `solicitacao_vinculacao` e `titulo_cepac`.
Inclui o campo `area_m2` com a contribuição de cada título para a solicitação.
"""
from __future__ import annotations

from decimal import Decimal
from typing import TYPE_CHECKING
from uuid import UUID

from sqlalchemy import ForeignKey, Numeric
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base

if TYPE_CHECKING:
    from .solicitacao_vinculacao import SolicitacaoVinculacao
    from .titulo_cepac import TituloCepac


class SolicitacaoTitulos(Base):
    """
    Associação N:N entre solicitações de vinculação e títulos CEPAC.

    `area_m2` indica quantos m² este título contribui para a solicitação.
    A soma de `area_m2` de todos os títulos de uma solicitação deve
    corresponder à `area_m2` da `solicitacao_vinculacao`.
    """
    __tablename__ = "solicitacao_titulos"

    # --- Chave primária composta ---
    solicitacao_id: Mapped[UUID] = mapped_column(
        ForeignKey("solicitacao_vinculacao.id", ondelete="RESTRICT"),
        primary_key=True,
    )
    titulo_id: Mapped[UUID] = mapped_column(
        ForeignKey("titulo_cepac.id", ondelete="RESTRICT"),
        primary_key=True,
        index=True,
    )

    # m² que este título contribui para a solicitação — deve ser > 0
    area_m2: Mapped[Decimal] = mapped_column(Numeric(15, 2), nullable=False)

    # --- Relacionamentos ---
    solicitacao: Mapped[SolicitacaoVinculacao] = relationship(
        "SolicitacaoVinculacao",
        back_populates="solicitacao_titulos",
        lazy="select",
    )
    titulo: Mapped[TituloCepac] = relationship(
        "TituloCepac",
        back_populates="solicitacao_titulos",
        lazy="select",
    )

    def __repr__(self) -> str:
        return (
            f"<SolicitacaoTitulos "
            f"solicitacao_id={self.solicitacao_id!s} "
            f"titulo_id={self.titulo_id!s} "
            f"area_m2={self.area_m2}>"
        )
