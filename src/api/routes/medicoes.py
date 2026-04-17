"""
Rotas de medições de obra (T17) — Rastreabilidade Financeira.

Endpoints para DIRETOR registrar medições mensais e qualquer técnico
consultar o histórico e o Custo Total Incorrido atual.

O arquivo físico de medição nunca transita pelo backend — apenas metadados.
O valor_acumulado é sempre calculado pela aplicação (nunca enviado pelo cliente).
"""
from datetime import datetime, timezone
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.auth.dependencies import UsuarioAutenticado, require_diretor, require_tecnico
from src.api.dependencies import get_db
from src.api.schemas.medicao import MedicaoAtualOut, MedicaoIn, MedicaoOut
from src.core.repositories import medicao_repository

router = APIRouter(prefix="/medicoes", tags=["medicoes"])


# ---------------------------------------------------------------------------
# GET /medicoes/atual   — deve vir ANTES de GET /medicoes/{id} (se existisse)
# ---------------------------------------------------------------------------

@router.get(
    "/atual",
    response_model=MedicaoAtualOut,
    status_code=status.HTTP_200_OK,
    summary="Custo Total Incorrido atual",
)
async def custo_total_atual(
    session: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[UsuarioAutenticado, Depends(require_tecnico)],
) -> MedicaoAtualOut:
    """
    Retorna o valor_acumulado da medição mais recente.

    Retorna `valor_acumulado = 0` quando ainda não há medições registradas.
    """
    from decimal import Decimal

    ultima = await medicao_repository.buscar_mais_recente(session)
    return MedicaoAtualOut(
        valor_acumulado=ultima.valor_acumulado if ultima else Decimal("0"),
        data_referencia=ultima.data_referencia if ultima else None,
        gerado_em=datetime.now(tz=timezone.utc),
    )


# ---------------------------------------------------------------------------
# GET /medicoes
# ---------------------------------------------------------------------------

@router.get(
    "",
    response_model=list[MedicaoOut],
    status_code=status.HTTP_200_OK,
    summary="Histórico de medições ordenado por data_referencia DESC",
)
async def listar_medicoes(
    session: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[UsuarioAutenticado, Depends(require_tecnico)],
) -> list[MedicaoOut]:
    registros = await medicao_repository.listar(session)
    return [MedicaoOut.model_validate(m) for m in registros]


# ---------------------------------------------------------------------------
# POST /medicoes
# ---------------------------------------------------------------------------

@router.post(
    "",
    response_model=MedicaoOut,
    status_code=status.HTTP_201_CREATED,
    summary="Registrar nova medição de obra (DIRETOR)",
)
async def registrar_medicao(
    payload: MedicaoIn,
    session: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[UsuarioAutenticado, Depends(require_diretor)],
) -> MedicaoOut:
    """
    Registra nova medição mensal.

    - `valor_acumulado` é calculado automaticamente — não enviar no payload.
    - `data_referencia` deve ser o primeiro dia do mês (validado pelo schema).
    - Duplicata de `data_referencia` → 422 com `MEDICAO_JA_EXISTE`.
    """
    try:
        medicao = await medicao_repository.registrar(
            session=session,
            data_referencia=payload.data_referencia,
            valor_medicao=payload.valor_medicao,
            numero_processo_sei=payload.numero_processo_sei,
            operador_id=current_user.id,
            descricao=payload.descricao,
        )
        await session.commit()
        await session.refresh(medicao)
    except IntegrityError:
        await session.rollback()
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={
                "codigo_erro": "MEDICAO_JA_EXISTE",
                "mensagem": (
                    f"Já existe uma medição para {payload.data_referencia}. "
                    "Cada mês admite apenas um registro."
                ),
            },
        )

    return MedicaoOut.model_validate(medicao)
