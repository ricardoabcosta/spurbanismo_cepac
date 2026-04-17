"""
Modelo SQLAlchemy para a tabela `movimentacao`.

APPEND-ONLY: Registro imutável de todas as transições de estado dos títulos CEPAC.
UPDATE e DELETE são bloqueados por trigger no banco (trg_movimentacao_no_update /
trg_movimentacao_no_delete). Nunca tente modificar ou excluir registros desta tabela.

Convenções para o campo `motivo`:
  - 'SEED_INICIAL'   — carga inicial de títulos
  - 'EXPIRAÇÃO_TTL'  — expiração automática do prazo de análise
  - Outros valores   — descrição livre da operação
"""
from __future__ import annotations

from datetime import datetime
from typing import TYPE_CHECKING
from uuid import UUID

from sqlalchemy import Enum as SAEnum, ForeignKey, String, Text, text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base
from .enums import EstadoTituloEnum, OrigemEnum, UsoEnum

if TYPE_CHECKING:
    from .titulo_cepac import TituloCepac
    from .setor import Setor


class Movimentacao(Base):
    """
    Log de auditoria append-only das transições de estado dos títulos CEPAC.

    Cada linha representa uma transição de `estado_anterior` para `estado_novo`.
    `estado_anterior` é NULL apenas no registro inicial (motivo='SEED_INICIAL').

    Campos desnormalizados (`setor_id`, `uso`, `origem`) existem para permitir
    queries de saldo histórico eficientes sem JOINs com `titulo_cepac`.

    IMPORTANTE: Esta tabela é imutável. O banco rejeita UPDATE e DELETE via trigger.
    """
    __tablename__ = "movimentacao"

    # --- Chave primária ---
    id: Mapped[UUID] = mapped_column(
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )

    # --- FK: título ---
    titulo_id: Mapped[UUID] = mapped_column(
        ForeignKey("titulo_cepac.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )

    # --- FK: setor (desnormalizado para queries históricas eficientes) ---
    setor_id: Mapped[UUID] = mapped_column(
        ForeignKey("setor.id", ondelete="RESTRICT"),
        nullable=False,
    )

    # --- Campos desnormalizados do título ---
    uso: Mapped[UsoEnum] = mapped_column(
        SAEnum(UsoEnum, name="uso_enum", native_enum=True),
        nullable=False,
    )
    origem: Mapped[OrigemEnum] = mapped_column(
        SAEnum(OrigemEnum, name="origem_enum", native_enum=True),
        nullable=False,
    )

    # --- Transição de estado ---
    # NULL apenas no registro inicial (SEED_INICIAL)
    estado_anterior: Mapped[EstadoTituloEnum | None] = mapped_column(
        SAEnum(EstadoTituloEnum, name="estado_titulo_enum", native_enum=True),
        nullable=True,
    )
    estado_novo: Mapped[EstadoTituloEnum] = mapped_column(
        SAEnum(EstadoTituloEnum, name="estado_titulo_enum", native_enum=True),
        nullable=False,
    )

    # --- Rastreabilidade ---
    # Número do processo SEI — obrigatório e não vazio (CHECK no banco)
    numero_processo_sei: Mapped[str] = mapped_column(String(50), nullable=False)

    # Motivo da movimentação (livre ou valores convencionados acima)
    motivo: Mapped[str | None] = mapped_column(Text, nullable=True)

    # UPN ou sub extraído do JWT do operador responsável
    operador: Mapped[str] = mapped_column(String(200), nullable=False)

    # --- Auditoria (IMUTÁVEL) ---
    # created_at é a base do audit trail. Nunca deve ser alterado.
    # O trigger no banco impede qualquer UPDATE nesta tabela.
    created_at: Mapped[datetime] = mapped_column(
        nullable=False,
        server_default=text("now()"),
    )

    # --- Relacionamentos ---
    titulo: Mapped[TituloCepac] = relationship(
        "TituloCepac",
        back_populates="movimentacoes",
        lazy="select",
    )
    setor: Mapped[Setor] = relationship(
        "Setor",
        back_populates="movimentacoes",
        lazy="select",
    )

    def __repr__(self) -> str:
        return (
            f"<Movimentacao id={self.id!s} "
            f"titulo_id={self.titulo_id!s} "
            f"{self.estado_anterior!r} -> {self.estado_novo!r}>"
        )
