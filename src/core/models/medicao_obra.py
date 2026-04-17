"""
Modelo SQLAlchemy para a tabela `medicao_obra`.
"""
from __future__ import annotations

from datetime import date, datetime
from decimal import Decimal
from typing import TYPE_CHECKING
from uuid import UUID

from sqlalchemy import CheckConstraint, ForeignKey, Numeric, Text, text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base

if TYPE_CHECKING:
    from .usuario import Usuario


class MedicaoObra(Base):
    """
    Medição mensal de obras da OUCAE — série histórica do Custo Total Incorrido.

    Append-only: triggers bloqueiam UPDATE e DELETE (mesmo padrão de movimentacao).
    data_referencia é sempre o primeiro dia do mês (constraint CHECK no banco).
    valor_acumulado é calculado pela aplicação no momento da inserção — nunca
    enviado pelo cliente.
    """
    __tablename__ = "medicao_obra"

    __table_args__ = (
        CheckConstraint(
            "EXTRACT(DAY FROM data_referencia) = 1",
            name="ck_medicao_data_primeiro_dia",
        ),
        CheckConstraint("valor_medicao > 0", name="ck_medicao_valor_positivo"),
        CheckConstraint("valor_acumulado > 0", name="ck_medicao_acumulado_positivo"),
    )

    # --- Chave primária ---
    id: Mapped[UUID] = mapped_column(
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )

    # Primeiro dia do mês de competência (ex: 2026-04-01)
    data_referencia: Mapped[date] = mapped_column(nullable=False, unique=True)

    # Valor da medição mensal em R$
    valor_medicao: Mapped[Decimal] = mapped_column(Numeric(18, 2), nullable=False)

    # Custo total acumulado após esta medição — calculado pela aplicação
    valor_acumulado: Mapped[Decimal] = mapped_column(Numeric(18, 2), nullable=False)

    descricao: Mapped[str | None] = mapped_column(Text, nullable=True)

    # Aceita padrões SIMPROC e SEI — D2
    numero_processo_sei: Mapped[str] = mapped_column(Text, nullable=False)

    # --- FK: operador ---
    operador_id: Mapped[UUID] = mapped_column(
        ForeignKey("usuario.id", ondelete="RESTRICT"),
        nullable=False,
    )

    # --- Auditoria ---
    created_at: Mapped[datetime] = mapped_column(
        nullable=False,
        server_default=text("now()"),
    )

    # --- Relacionamentos ---
    operador: Mapped[Usuario] = relationship(
        "Usuario",
        lazy="select",
    )

    def __repr__(self) -> str:
        return (
            f"<MedicaoObra id={self.id!s} data={self.data_referencia!s} "
            f"valor_medicao={self.valor_medicao}>"
        )
