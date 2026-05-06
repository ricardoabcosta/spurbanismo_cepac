"""
Modelo SQLAlchemy para a tabela `lei_ouc`.

Catálogo cronológico de leis aplicáveis a cada Operação Urbana Consorciada.
Cada OUC pode ter múltiplas leis ao longo do tempo (ex: OUCFL tem 3 leis).
A lei vigente (vigente=TRUE) é a que está em vigor atualmente.

Consumo histórico: armazenado apenas em leis encerradas (vigente=FALSE),
como snapshot do consumo acumulado sob aquela lei.
"""
from __future__ import annotations

from datetime import date
from decimal import Decimal
from typing import TYPE_CHECKING, Optional

from sqlalchemy import Boolean, Date, ForeignKey, Integer, Numeric, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base

if TYPE_CHECKING:
    from .operacao_urbana import OperacaoUrbana
    from .setor_estoque_lei import SetorEstoqueLei


class LeiOuc(Base):
    """
    Representa uma lei aplicável a uma OUC em uma janela de tempo.

    Exemplo para OUCFL:
      - 11.732/1995 (pré-OUC, ordem 1)
      - 13.769/2004 (criação da OUC, ordem 2, tem consumo_historico)
      - 18.175/2024 (vigente, ordem 3)
    """
    __tablename__ = "lei_ouc"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    operacao_urbana_id: Mapped[int] = mapped_column(
        ForeignKey("operacao_urbana.id", ondelete="CASCADE"), nullable=False
    )
    identificador: Mapped[str] = mapped_column(String(30), nullable=False)
    nome: Mapped[Optional[str]] = mapped_column(String(150), nullable=True)
    data_vigencia_inicio: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    data_vigencia_fim: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    ordem: Mapped[int] = mapped_column(Integer, nullable=False)
    vigente: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    consumo_historico_r_m2: Mapped[Optional[Decimal]] = mapped_column(
        Numeric(15, 2), nullable=True
    )
    consumo_historico_nr_m2: Mapped[Optional[Decimal]] = mapped_column(
        Numeric(15, 2), nullable=True
    )
    estoque_geral_m2: Mapped[Optional[Decimal]] = mapped_column(
        Numeric(15, 2), nullable=True
    )

    # --- Relacionamentos ---
    operacao_urbana: Mapped["OperacaoUrbana"] = relationship(
        "OperacaoUrbana", back_populates="leis", lazy="select"
    )
    estoques_setor: Mapped[list["SetorEstoqueLei"]] = relationship(
        "SetorEstoqueLei", back_populates="lei_ouc", lazy="select"
    )

    def __repr__(self) -> str:
        return (
            f"<LeiOuc id={self.id} identificador={self.identificador!r} "
            f"vigente={self.vigente}>"
        )
