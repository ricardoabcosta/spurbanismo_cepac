"""
Rota GET /saldo/{setor} — consulta de saldo de um setor com suporte a snapshot histórico.

O parâmetro opcional `?data=YYYY-MM-DD` permite auditoria point-in-time (CVM/TCM).
Sem o parâmetro, retorna o saldo atual.

Nenhuma lógica de negócio reside neste módulo — apenas orquestração.
"""
from datetime import date, datetime, timezone
from decimal import Decimal
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.dependencies import get_db
from src.api.schemas.saldo import SaldoOut
from src.core.repositories import saldo_repository
from src.core.models import Setor
from sqlalchemy import select

router = APIRouter(prefix="/saldo", tags=["saldo"])


@router.get(
    "/{setor}",
    response_model=SaldoOut,
    summary="Consultar saldo de CEPACs de um setor",
)
async def get_saldo(
    setor: str,
    session: Annotated[AsyncSession, Depends(get_db)],
    data: Optional[date] = Query(
        None,
        description="Data de referência para snapshot histórico (YYYY-MM-DD). "
                    "Se omitido, retorna o saldo atual.",
    ),
) -> SaldoOut:
    """
    Retorna o saldo de CEPACs do setor.

    - Sem `?data`: saldo atual (todas as movimentações)
    - Com `?data=YYYY-MM-DD`: snapshot até o fim do dia informado (auditoria CVM/TCM)

    O saldo é sempre calculado a partir da tabela `movimentacao` —
    nunca lido de coluna pré-calculada.
    """
    # Verificar se o setor existe no banco
    stmt = select(Setor).where(Setor.nome == setor)
    result = await session.execute(stmt)
    setor_obj = result.scalar_one_or_none()

    if setor_obj is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Setor '{setor}' não encontrado.",
        )

    saldo_dto = await saldo_repository.calcular_saldo(
        session, setor, data_referencia=data
    )

    teto_nr = setor_obj.teto_nr_m2
    nr_total = saldo_dto.nr_total_comprometido
    saldo_nr_disponivel = teto_nr - nr_total

    data_referencia = data if data is not None else datetime.now(tz=timezone.utc).date()

    return SaldoOut(
        setor=setor,
        data_referencia=data_referencia,
        nr_consumido_aca=saldo_dto.nr_consumido_aca,
        nr_consumido_nuvem=saldo_dto.nr_consumido_nuvem,
        nr_em_analise=saldo_dto.nr_em_analise,
        nr_total_comprometido=nr_total,
        saldo_nr_disponivel=saldo_nr_disponivel,
        teto_nr=teto_nr,
        bloqueado=saldo_nr_disponivel <= Decimal("0"),
    )
