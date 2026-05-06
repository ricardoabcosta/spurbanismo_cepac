"""
Modelo SQLAlchemy para a tabela `setor_estoque_lei`.

Estoque máximo de cada setor segregado por lei (R e NR).
Cada setor tem 1 registro por lei aplicável.

Compatibilidade retroativa: os campos denormalizados em `setor.*`
(setor.estoque_total_m2, setor.teto_r_m2, etc.) espelham a lei vigente.
O roadmap (R3) prevê removê-los no futuro.
"""
from __future__ import annotations

from decimal import Decimal
from typing import TYPE_CHECKING, Optional
from uuid import UUID

from sqlalchemy import ForeignKey, Integer, Numeric
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base

if TYPE_CHECKING:
    from .lei_ouc import LeiOuc
    from .setor import Setor


class SetorEstoqueLei(Base):
    """
    Estoque de um setor sob uma lei específica.

    - estoque_total_r_m2: limite total de área R neste setor para esta lei
    - estoque_total_nr_m2: limite total de área NR neste setor para esta lei
    - teto_r_m2: teto máximo de R (pode ser igual a estoque_total_r_m2)
    - teto_nr_m2: teto máximo de NR (pode ser igual a estoque_total_nr_m2)
    - reserva_r_m2: reserva de R protegida (NR não pode invadir)
    """
    __tablename__ = "setor_estoque_lei"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    setor_id: Mapped[UUID] = mapped_column(
        ForeignKey("setor.id", ondelete="CASCADE"), nullable=False
    )
    lei_ouc_id: Mapped[int] = mapped_column(
        ForeignKey("lei_ouc.id", ondelete="CASCADE"), nullable=False
    )
    estoque_total_r_m2: Mapped[Decimal] = mapped_column(
        Numeric(15, 2), nullable=False
    )
    estoque_total_nr_m2: Mapped[Decimal] = mapped_column(
        Numeric(15, 2), nullable=False
    )
    teto_r_m2: Mapped[Optional[Decimal]] = mapped_column(Numeric(15, 2), nullable=True)
    teto_nr_m2: Mapped[Optional[Decimal]] = mapped_column(Numeric(15, 2), nullable=True)
    reserva_r_m2: Mapped[Optional[Decimal]] = mapped_column(
        Numeric(15, 2), nullable=True
    )

    # --- Relacionamentos ---
    setor: Mapped["Setor"] = relationship(
        "Setor", back_populates="estoques_por_lei", lazy="select"
    )
    lei_ouc: Mapped["LeiOuc"] = relationship(
        "LeiOuc", back_populates="estoques_setor", lazy="select"
    )

    def __repr__(self) -> str:
        return (
            f"<SetorEstoqueLei id={self.id} setor_id={self.setor_id!s} "
            f"lei_ouc_id={self.lei_ouc_id}>"
        )
