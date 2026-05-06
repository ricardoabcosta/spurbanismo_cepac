"""
Modelo SQLAlchemy para a tabela `operacao_urbana`.

Catálogo de Operações Urbanas Consorciadas (OUC) de São Paulo.
Atualmente cadastradas: Água Espraiada (AE), Faria Lima (FL), Água Branca (AB).

Cada `setor` referencia sua operação urbana via FK `operacao_urbana_id`
(migration 016). Atualmente todos os setores pertencem à OUCAE (AE).
"""
from __future__ import annotations

from datetime import date
from decimal import Decimal
from typing import TYPE_CHECKING, Optional

from sqlalchemy import Boolean, Date, Integer, Numeric, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base

if TYPE_CHECKING:
    from .lei_ouc import LeiOuc
    from .setor import Setor


class OperacaoUrbana(Base):
    __tablename__ = "operacao_urbana"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    nome: Mapped[str] = mapped_column(String(100), nullable=False)
    sigla: Mapped[str] = mapped_column(String(5), nullable=False, unique=True)
    lei_vigente: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    estoque_maximo_global_r: Mapped[Optional[Decimal]] = mapped_column(
        Numeric(15, 2), nullable=True
    )
    estoque_maximo_global_nr: Mapped[Optional[Decimal]] = mapped_column(
        Numeric(15, 2), nullable=True
    )
    possui_nuvem: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    valor_cepac_ref: Mapped[Optional[Decimal]] = mapped_column(
        Numeric(15, 2), nullable=True
    )
    data_ultima_posicao: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    ativo: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)

    # Limite de R Não Incentivado — NULL para OUCs sem distinção (OUCAE, OUCFL)
    teto_r_nao_incentivado_m2: Mapped[Optional[Decimal]] = mapped_column(
        Numeric(15, 2), nullable=True
    )

    # Campos migrados de configuracao_operacao (Fase 3, Opção B)
    reserva_tecnica_m2: Mapped[Decimal] = mapped_column(
        Numeric(15, 2), nullable=False, default=Decimal("0")
    )
    cepacs_leiloados: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    cepacs_colocacao_privada: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    cepacs_totais: Mapped[int] = mapped_column(Integer, nullable=False, default=0)

    setores: Mapped[list["Setor"]] = relationship(
        "Setor", back_populates="operacao_urbana", lazy="select"
    )
    leis: Mapped[list["LeiOuc"]] = relationship(
        "LeiOuc", back_populates="operacao_urbana", lazy="select"
    )
    def __repr__(self) -> str:
        return (
            f"<OperacaoUrbana id={self.id} sigla={self.sigla!r} "
            f"nome={self.nome!r}>"
        )
