"""
MedicaoRepository — acesso a dados para medições de obra (T17).

Toda a lógica de cálculo de valor_acumulado reside aqui:
  valor_acumulado = valor_acumulado_anterior + valor_medicao

Append-only: sem funções de UPDATE ou DELETE (trigger no banco garante também).
"""
from __future__ import annotations

from datetime import date
from decimal import Decimal
from typing import Optional
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.core.models.medicao_obra import MedicaoObra


async def buscar_mais_recente(session: AsyncSession) -> Optional[MedicaoObra]:
    """Retorna a medição mais recente (maior data_referencia) ou None."""
    result = await session.execute(
        select(MedicaoObra).order_by(MedicaoObra.data_referencia.desc()).limit(1)
    )
    return result.scalar_one_or_none()


async def listar(session: AsyncSession) -> list[MedicaoObra]:
    """Retorna todo o histórico ordenado por data_referencia DESC."""
    result = await session.execute(
        select(MedicaoObra).order_by(MedicaoObra.data_referencia.desc())
    )
    return list(result.scalars().all())


async def registrar(
    session: AsyncSession,
    data_referencia: date,
    valor_medicao: Decimal,
    numero_processo_sei: str,
    operador_id: UUID,
    descricao: Optional[str] = None,
) -> MedicaoObra:
    """
    Registra uma nova medição e calcula valor_acumulado automaticamente.

    valor_acumulado = (última medição).valor_acumulado + valor_medicao
    Se não houver medições anteriores, valor_acumulado = valor_medicao.

    Não faz commit — responsabilidade da rota.
    Lança IntegrityError se data_referencia já existir (UNIQUE constraint).
    """
    ultima = await buscar_mais_recente(session)
    acumulado_anterior = ultima.valor_acumulado if ultima else Decimal("0")
    valor_acumulado = acumulado_anterior + valor_medicao

    medicao = MedicaoObra(
        data_referencia=data_referencia,
        valor_medicao=valor_medicao,
        valor_acumulado=valor_acumulado,
        descricao=descricao,
        numero_processo_sei=numero_processo_sei,
        operador_id=operador_id,
    )
    session.add(medicao)
    return medicao
