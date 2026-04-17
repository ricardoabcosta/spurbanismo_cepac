"""
Rota POST /movimentacoes — transição de estado manual de um título CEPAC.

Utilizada para operações administrativas (ex: devolver título para DISPONIVEL,
marcar como CONSUMIDO, colocar em QUARENTENA) com rastreabilidade via SEI.

Nenhuma lógica de negócio reside neste módulo — apenas orquestração.
Requer autenticação Azure AD com papel TECNICO ou DIRETOR (T12).
"""
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.auth.dependencies import UsuarioAutenticado, require_tecnico
from src.api.dependencies import get_db
from src.api.schemas.movimentacao import MovimentacaoIn, MovimentacaoOut
from src.core.repositories import titulo_repository

router = APIRouter(prefix="/movimentacoes", tags=["movimentacoes"])


@router.post(
    "",
    response_model=MovimentacaoOut,
    status_code=status.HTTP_200_OK,
    summary="Registrar transição de estado manual de um título CEPAC",
)
async def registrar_movimentacao(
    payload: MovimentacaoIn,
    session: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[UsuarioAutenticado, Depends(require_tecnico)],
) -> MovimentacaoOut:
    """
    Transiciona o estado de um título CEPAC e registra a movimentação.

    - `numero_processo_sei` é obrigatório e não pode ser vazio
    - `motivo` é opcional (texto livre)
    - O operador é o UPN do usuário autenticado via Azure AD
    """
    try:
        await titulo_repository.transicionar_estado(
            session=session,
            titulo_id=payload.titulo_id,
            estado_novo=payload.estado_novo,
            numero_processo_sei=payload.numero_processo_sei,
            operador=current_user.upn,
            motivo=payload.motivo,
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(exc),
        )

    await session.commit()

    return MovimentacaoOut(
        titulo_id=payload.titulo_id,
        estado_novo=payload.estado_novo,
    )
