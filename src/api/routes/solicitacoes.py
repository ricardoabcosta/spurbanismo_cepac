"""
Rota POST /solicitacoes — submissão de solicitação de vinculação de CEPACs.

Fluxo:
  1. Validação Pydantic do payload (numero_processo_sei obrigatório)
  2. Busca dos títulos no banco
  3. Cálculo do saldo do setor
  4. Montagem do SolicitacaoDTO e validação pelo RulesEngine
  5a. Aprovado  → transicionar títulos para EM_ANALISE + registrar movimentação
  5b. Reprovado → retornar 422 com corpo de erro estruturado

Nenhuma lógica de negócio reside neste módulo — apenas orquestração.
"""
import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.auth.dependencies import UsuarioAutenticado, require_tecnico
from src.api.dependencies import get_db, get_rules_engine
from src.api.schemas.solicitacao import ErroNegocioOut, SolicitacaoIn, SolicitacaoOut
from src.core.engine.dtos import SolicitacaoDTO
from src.core.engine.rules_engine import RulesEngine
from src.core.repositories import saldo_repository, titulo_repository

router = APIRouter(prefix="/solicitacoes", tags=["solicitacoes"])


@router.post(
    "",
    response_model=SolicitacaoOut,
    status_code=status.HTTP_200_OK,
    responses={
        422: {
            "description": "Erro de negócio (regra do RulesEngine)",
            "model": ErroNegocioOut,
        }
    },
    summary="Submeter solicitação de vinculação de CEPACs",
)
async def criar_solicitacao(
    payload: SolicitacaoIn,
    session: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[UsuarioAutenticado, Depends(require_tecnico)],
    engine: Annotated[RulesEngine, Depends(get_rules_engine)],
) -> Response:
    """
    Processa uma solicitação de vinculação de títulos CEPAC.

    - Valida regras de negócio via RulesEngine
    - Em caso de aprovação, transiciona os títulos para EM_ANALISE
    - Em caso de reprovação, retorna 422 com detalhes do erro
    """
    # 1. Buscar títulos
    try:
        titulos = await titulo_repository.get_titulos_by_ids(
            session, payload.titulo_ids
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(exc),
        )

    # 2. Calcular saldo do setor
    saldo_setor = await saldo_repository.calcular_saldo(session, payload.setor)

    # 3. Montar SolicitacaoDTO
    solicitacao_dto = SolicitacaoDTO(
        setor=payload.setor,
        uso=payload.uso,
        origem=payload.origem,
        area_m2=payload.area_m2,
        numero_processo_sei=payload.numero_processo_sei,
        titulo_ids=payload.titulo_ids,
        titulos=titulos,
        saldo_setor=saldo_setor,
    )

    # 4. Validar pelo RulesEngine
    resultado = engine.validar(solicitacao_dto)

    # 5b. Reprovado
    if not resultado.aprovado:
        erro = resultado.erro
        corpo_erro = ErroNegocioOut(
            codigo_erro=erro.codigo,
            mensagem=erro.mensagem,
            setor=erro.setor,
            saldo_atual=erro.saldo_atual,
            limite=erro.limite,
            dias_restantes=erro.dias_restantes,
        )
        return Response(
            content=corpo_erro.model_dump_json(),
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            media_type="application/json",
        )

    # 5a. Aprovado — transicionar títulos e gerar ID da solicitação
    solicitacao_id = uuid.uuid4()

    for titulo_id in payload.titulo_ids:
        await titulo_repository.transicionar_estado(
            session=session,
            titulo_id=titulo_id,
            estado_novo="EM_ANALISE",
            numero_processo_sei=payload.numero_processo_sei,
            operador=current_user.upn,
            motivo=f"Solicitacao {solicitacao_id}",
        )

    await session.commit()

    resposta = SolicitacaoOut(
        solicitacao_id=solicitacao_id,
        status="APROVADA",
        area_m2=payload.area_m2,
    )
    return Response(
        content=resposta.model_dump_json(),
        status_code=status.HTTP_200_OK,
        media_type="application/json",
    )
