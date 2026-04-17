"""
Rotas GET /titulos e GET /titulos/{id}/historico.

- GET /titulos            → listagem com filtros opcionais
- GET /titulos/{id}/historico → histórico cronológico de movimentações

Nenhuma lógica de negócio reside neste módulo — apenas orquestração.
"""
from typing import Annotated, Literal, Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.dependencies import get_db
from src.api.schemas.titulo import MovimentacaoHistoricoOut, TituloOut
from src.core.repositories import titulo_repository

router = APIRouter(prefix="/titulos", tags=["titulos"])


@router.get(
    "",
    response_model=list[TituloOut],
    summary="Listar títulos CEPAC com filtros opcionais",
)
async def listar_titulos(
    session: Annotated[AsyncSession, Depends(get_db)],
    setor: Optional[str] = Query(None, description="Filtrar por nome do setor"),
    uso: Optional[Literal["R", "NR"]] = Query(None, description="Filtrar por uso"),
    origem: Optional[Literal["ACA", "NUVEM"]] = Query(None, description="Filtrar por origem"),
    estado: Optional[Literal["DISPONIVEL", "EM_ANALISE", "CONSUMIDO", "QUARENTENA"]] = Query(
        None, description="Filtrar por estado"
    ),
) -> list[TituloOut]:
    """
    Retorna a lista de títulos CEPAC.

    Todos os filtros são opcionais e combinados com AND lógico.
    Sem filtros, retorna todos os títulos.
    """
    titulos = await titulo_repository.list_titulos(
        session,
        setor=setor,
        uso=uso,
        origem=origem,
        estado=estado,
    )

    return [
        TituloOut(
            id=t.id,
            setor=t.setor,
            uso=t.uso,
            origem=t.origem,
            estado=t.estado,
            valor_m2=t.valor_m2,
            data_desvinculacao=t.data_desvinculacao,
        )
        for t in titulos
    ]


@router.get(
    "/{titulo_id}/historico",
    response_model=list[MovimentacaoHistoricoOut],
    summary="Retornar histórico cronológico de movimentações de um título",
)
async def get_historico_titulo(
    titulo_id: UUID,
    session: Annotated[AsyncSession, Depends(get_db)],
) -> list[MovimentacaoHistoricoOut]:
    """
    Retorna todas as movimentações de um título em ordem cronológica ascendente.

    Retorna 404 se o título não existir.
    """
    # Verificar existência do título via get_titulos_by_ids
    try:
        await titulo_repository.get_titulos_by_ids(session, [titulo_id])
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(exc),
        )

    movimentacoes = await titulo_repository.get_historico(session, titulo_id)

    return [
        MovimentacaoHistoricoOut(
            id=m.id,
            titulo_id=m.titulo_id,
            estado_anterior=(
                m.estado_anterior.value if m.estado_anterior is not None else None
            ),
            estado_novo=m.estado_novo.value,
            numero_processo_sei=m.numero_processo_sei,
            motivo=m.motivo,
            operador=m.operador,
            created_at=m.created_at,
        )
        for m in movimentacoes
    ]
