"""
Modelo SQLAlchemy para a tabela `configuracao_operacao`.

Singleton (id = 1) — parâmetros globais da OUCAE.
Nunca inserir mais de uma linha; usar UPDATE para alterar.
"""
from __future__ import annotations

from datetime import datetime
from decimal import Decimal

from sqlalchemy import Integer, Numeric, SmallInteger, text
from sqlalchemy.orm import Mapped, mapped_column

from .base import Base


class ConfiguracaoOperacao(Base):
    __tablename__ = "configuracao_operacao"

    id: Mapped[int] = mapped_column(SmallInteger, primary_key=True, default=1)
    reserva_tecnica_m2: Mapped[Decimal] = mapped_column(
        Numeric(15, 2), nullable=False, default=Decimal("0")
    )
    cepacs_leiloados: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    cepacs_colocacao_privada: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    cepacs_totais: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    updated_at: Mapped[datetime] = mapped_column(
        nullable=False,
        server_default=text("now()"),
        onupdate=datetime.utcnow,
    )

    def __repr__(self) -> str:
        return f"<ConfiguracaoOperacao reserva_tecnica_m2={self.reserva_tecnica_m2}>"
