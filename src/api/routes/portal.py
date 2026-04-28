"""
Rotas do Portal de Operações Técnicas (T15).

Endpoints para técnicos cadastrarem solicitações, selecionarem títulos e
consultarem propostas. Requer autenticação Azure AD (T12).

Fluxo de solicitação:
  POST /portal/solicitacoes → rules engine → EM_ANALISE (títulos EM_ANALISE)
  PATCH /portal/solicitacoes/{id}/cancelar → CANCELADA (títulos de volta a DISPONIVEL)

Nenhuma lógica de negócio reside neste módulo — apenas orquestração.
"""
import math
from datetime import date
from typing import Annotated, Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.auth.dependencies import UsuarioAutenticado, require_tecnico
from src.api.dependencies import get_db, get_rules_engine
from src.api.schemas.portal import (
    CertidaoItem,
    PaginacaoProposta,
    PaginacaoSolicitacaoOut,
    PropostaListItem,
    PropostaPortalOut,
    SolicitacaoPortalDetalheOut,
    SolicitacaoPortalIn,
    SolicitacaoPortalOut,
    TituloDisponivelOut,
    TituloNoLoteOut,
)
from src.core.engine.dtos import SolicitacaoDTO
from src.core.engine.rules_engine import RulesEngine
from src.core.models.enums import (
    EstadoTituloEnum,
    OrigemEnum,
    StatusSolicitacaoEnum,
    UsoEnum,
)
from src.core.repositories import saldo_repository, titulo_repository
from src.core.repositories import portal_repository

router = APIRouter(prefix="/portal", tags=["portal"])


# ---------------------------------------------------------------------------
# POST /portal/solicitacoes
# ---------------------------------------------------------------------------

@router.post(
    "/solicitacoes",
    response_model=SolicitacaoPortalOut,
    status_code=status.HTTP_201_CREATED,
    summary="Cadastrar nova solicitação de vinculação",
)
async def criar_solicitacao(
    payload: SolicitacaoPortalIn,
    session: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[UsuarioAutenticado, Depends(require_tecnico)],
    engine: Annotated[RulesEngine, Depends(get_rules_engine)],
) -> SolicitacaoPortalOut:
    """
    Registra nova solicitação de vinculação.

    1. Valida formato SEI/SIMPROC (Pydantic)
    2. Busca setor e valida existência
    3. Busca e valida títulos (devem ser DISPONIVEL)
    4. Valida proposta_codigo (se informado)
    5. Executa RulesEngine
    6. Cria SolicitacaoVinculacao (EM_ANALISE) + SolicitacaoTitulos
    7. Transiciona títulos para EM_ANALISE
    """
    # Buscar setor
    setor = await portal_repository.buscar_setor_por_nome(session, payload.setor)
    if setor is None:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Setor não encontrado: '{payload.setor}'.",
        )

    # Buscar títulos
    try:
        titulos = await titulo_repository.get_titulos_by_ids(session, payload.titulo_ids)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))

    # Calcular saldo
    saldo_setor = await saldo_repository.calcular_saldo(session, payload.setor)

    # Montar DTO e validar pelo RulesEngine
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
    resultado = engine.validar(solicitacao_dto)

    if not resultado.aprovado:
        erro = resultado.erro
        assert erro is not None
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={
                "codigo_erro": erro.codigo,
                "mensagem": erro.mensagem,
                "setor": erro.setor,
                "saldo_atual": str(erro.saldo_atual) if erro.saldo_atual is not None else None,
                "limite": str(erro.limite) if erro.limite is not None else None,
                "dias_restantes": erro.dias_restantes,
            },
        )

    # Resolver proposta_id (opcional)
    proposta_id = None
    proposta_codigo_out = None
    if payload.proposta_codigo:
        proposta = await portal_repository.buscar_proposta_por_codigo(
            session, payload.proposta_codigo
        )
        if proposta is None:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=f"Proposta não encontrada: '{payload.proposta_codigo}'.",
            )
        proposta_id = proposta.id
        proposta_codigo_out = proposta.codigo

    # Criar registro persistido
    solicitacao = await portal_repository.criar_solicitacao(
        session=session,
        setor_id=setor.id,
        uso=UsoEnum(payload.uso),
        origem=OrigemEnum(payload.origem),
        area_m2=payload.area_m2,
        numero_processo_sei=payload.numero_processo_sei,
        titulo_dtos=titulos,
        proposta_id=proposta_id,
        observacao=payload.observacao,
    )

    # Transicionar títulos para EM_ANALISE
    for titulo_id in payload.titulo_ids:
        await titulo_repository.transicionar_estado(
            session=session,
            titulo_id=titulo_id,
            estado_novo="EM_ANALISE",
            numero_processo_sei=payload.numero_processo_sei,
            operador=current_user.upn,
            motivo=f"Solicitacao {solicitacao.id}",
        )

    await session.commit()
    await session.refresh(solicitacao)

    return SolicitacaoPortalOut(
        id=solicitacao.id,
        status=solicitacao.status.value,
        setor=setor.nome,
        uso=solicitacao.uso.value,
        origem=solicitacao.origem.value,
        area_m2=solicitacao.area_m2,
        quantidade_cepacs=solicitacao.quantidade_cepacs,
        numero_processo_sei=solicitacao.numero_processo_sei,
        proposta_codigo=proposta_codigo_out,
        observacao=solicitacao.observacao,
        motivo_rejeicao=None,
        created_at=solicitacao.created_at,
    )


# ---------------------------------------------------------------------------
# GET /portal/solicitacoes
# ---------------------------------------------------------------------------

@router.get(
    "/solicitacoes",
    response_model=PaginacaoSolicitacaoOut,
    status_code=status.HTTP_200_OK,
    summary="Listar solicitações com filtros (paginado)",
)
async def listar_solicitacoes(
    session: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[UsuarioAutenticado, Depends(require_tecnico)],
    setor: Annotated[Optional[str], Query(description="Filtrar por nome do setor")] = None,
    status_filtro: Annotated[
        Optional[StatusSolicitacaoEnum],
        Query(alias="status", description="Filtrar por status"),
    ] = None,
    uso: Annotated[Optional[UsoEnum], Query(description="Filtrar por uso R ou NR")] = None,
    origem: Annotated[
        Optional[OrigemEnum], Query(description="Filtrar por origem ACA ou NUVEM")
    ] = None,
    data_inicio: Annotated[
        Optional[date], Query(description="Data início (YYYY-MM-DD)")
    ] = None,
    data_fim: Annotated[
        Optional[date], Query(description="Data fim (YYYY-MM-DD)")
    ] = None,
    page: Annotated[int, Query(ge=1, description="Número da página")] = 1,
    page_size: Annotated[
        int, Query(ge=1, le=100, description="Itens por página")
    ] = 20,
) -> PaginacaoSolicitacaoOut:
    items, total, total_pages = await portal_repository.listar_paginado(
        session=session,
        setor_nome=setor,
        status=status_filtro,
        uso=uso,
        origem=origem,
        data_inicio=data_inicio,
        data_fim=data_fim,
        page=page,
        page_size=page_size,
    )

    items_out = [
        SolicitacaoPortalOut(
            id=s.id,
            status=s.status.value,
            setor=s.setor.nome,
            uso=s.uso.value,
            origem=s.origem.value,
            area_m2=s.area_m2,
            quantidade_cepacs=s.quantidade_cepacs,
            numero_processo_sei=s.numero_processo_sei,
            proposta_codigo=s.proposta.codigo if s.proposta else None,
            observacao=s.observacao,
            motivo_rejeicao=s.motivo_rejeicao,
            created_at=s.created_at,
        )
        for s in items
    ]

    return PaginacaoSolicitacaoOut(
        items=items_out,
        total=total,
        page=page,
        page_size=page_size,
        total_pages=total_pages,
    )


# ---------------------------------------------------------------------------
# GET /portal/solicitacoes/{id}
# ---------------------------------------------------------------------------

@router.get(
    "/solicitacoes/{solicitacao_id}",
    response_model=SolicitacaoPortalDetalheOut,
    status_code=status.HTTP_200_OK,
    summary="Detalhe de uma solicitação com lote de títulos",
)
async def detalhe_solicitacao(
    solicitacao_id: UUID,
    session: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[UsuarioAutenticado, Depends(require_tecnico)],
) -> SolicitacaoPortalDetalheOut:
    solicitacao = await portal_repository.buscar_por_id(session, solicitacao_id)
    if solicitacao is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Solicitação {solicitacao_id} não encontrada.",
        )

    titulos_out = [
        TituloNoLoteOut(
            id=st.titulo.id,
            codigo=st.titulo.codigo,
            setor=st.titulo.setor.nome,
            uso=st.titulo.uso.value,
            origem=st.titulo.origem.value,
            estado=st.titulo.estado.value,
            valor_m2=st.titulo.valor_m2,
            area_m2_contribuicao=st.area_m2,
        )
        for st in solicitacao.solicitacao_titulos
    ]

    return SolicitacaoPortalDetalheOut(
        id=solicitacao.id,
        status=solicitacao.status.value,
        setor=solicitacao.setor.nome,
        uso=solicitacao.uso.value,
        origem=solicitacao.origem.value,
        area_m2=solicitacao.area_m2,
        quantidade_cepacs=solicitacao.quantidade_cepacs,
        numero_processo_sei=solicitacao.numero_processo_sei,
        proposta_codigo=solicitacao.proposta.codigo if solicitacao.proposta else None,
        observacao=solicitacao.observacao,
        motivo_rejeicao=solicitacao.motivo_rejeicao,
        created_at=solicitacao.created_at,
        titulos=titulos_out,
    )


# ---------------------------------------------------------------------------
# PATCH /portal/solicitacoes/{id}/cancelar
# ---------------------------------------------------------------------------

@router.patch(
    "/solicitacoes/{solicitacao_id}/cancelar",
    response_model=SolicitacaoPortalOut,
    status_code=status.HTTP_200_OK,
    summary="Cancelar solicitação EM_ANALISE (ou PENDENTE) e liberar títulos",
)
async def cancelar_solicitacao(
    solicitacao_id: UUID,
    session: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[UsuarioAutenticado, Depends(require_tecnico)],
) -> SolicitacaoPortalOut:
    """
    Cancela uma solicitação EM_ANALISE e reverte os títulos para DISPONIVEL.

    - APROVADA → 422 SOLICITACAO_NAO_CANCELAVEL
    - CANCELADA/REJEITADA → 422 SOLICITACAO_NAO_CANCELAVEL
    - EM_ANALISE → CANCELADA + títulos voltam a DISPONIVEL
    """
    solicitacao = await portal_repository.buscar_por_id(session, solicitacao_id)
    if solicitacao is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Solicitação {solicitacao_id} não encontrada.",
        )

    _cancelaveis = {StatusSolicitacaoEnum.PENDENTE, StatusSolicitacaoEnum.EM_ANALISE}
    if solicitacao.status not in _cancelaveis:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={
                "codigo_erro": "SOLICITACAO_NAO_CANCELAVEL",
                "mensagem": (
                    f"Solicitação não pode ser cancelada. "
                    f"Status atual: {solicitacao.status.value}."
                ),
            },
        )

    # Liberar todos os títulos EM_ANALISE do lote
    for st in solicitacao.solicitacao_titulos:
        if st.titulo.estado == EstadoTituloEnum.EM_ANALISE:
            await titulo_repository.transicionar_estado(
                session=session,
                titulo_id=st.titulo_id,
                estado_novo="DISPONIVEL",
                numero_processo_sei=solicitacao.numero_processo_sei,
                operador=current_user.upn,
                motivo=f"Cancelamento solicitacao {solicitacao_id}",
            )

    await portal_repository.cancelar(session, solicitacao)
    await session.commit()

    return SolicitacaoPortalOut(
        id=solicitacao.id,
        status=solicitacao.status.value,
        setor=solicitacao.setor.nome,
        uso=solicitacao.uso.value,
        origem=solicitacao.origem.value,
        area_m2=solicitacao.area_m2,
        quantidade_cepacs=solicitacao.quantidade_cepacs,
        numero_processo_sei=solicitacao.numero_processo_sei,
        proposta_codigo=solicitacao.proposta.codigo if solicitacao.proposta else None,
        observacao=solicitacao.observacao,
        motivo_rejeicao=solicitacao.motivo_rejeicao,
        created_at=solicitacao.created_at,
    )


# ---------------------------------------------------------------------------
# GET /portal/titulos
# ---------------------------------------------------------------------------

@router.get(
    "/titulos",
    response_model=list[TituloDisponivelOut],
    status_code=status.HTTP_200_OK,
    summary="Listar títulos DISPONIVEL para seleção",
)
async def listar_titulos_disponiveis(
    session: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[UsuarioAutenticado, Depends(require_tecnico)],
    setor: Annotated[Optional[str], Query(description="Filtrar por setor")] = None,
    uso: Annotated[Optional[str], Query(description="Filtrar por uso: R ou NR")] = None,
    origem: Annotated[Optional[str], Query(description="Filtrar por origem: ACA ou NUVEM")] = None,
) -> list[TituloDisponivelOut]:
    """Retorna apenas títulos em estado DISPONIVEL."""
    titulos = await portal_repository.listar_titulos_disponiveis(
        session=session,
        setor_nome=setor,
        uso=uso,
        origem=origem,
    )
    return [
        TituloDisponivelOut(
            id=t.id,
            codigo=t.codigo,
            setor=t.setor.nome,
            uso=t.uso.value,
            origem=t.origem.value,
            valor_m2=t.valor_m2,
        )
        for t in titulos
    ]


# ---------------------------------------------------------------------------
# GET /portal/propostas
# ---------------------------------------------------------------------------

@router.get(
    "/propostas",
    response_model=PaginacaoProposta,
    status_code=200,
    summary="Listar propostas (AE-XXXX) com paginação",
)
async def listar_propostas(
    session: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[UsuarioAutenticado, Depends(require_tecnico)],
    page: Annotated[int, Query(ge=1, description="Número da página")] = 1,
    page_size: Annotated[int, Query(ge=1, le=100, description="Itens por página")] = 20,
    setor_id: Annotated[Optional[UUID], Query(description="Filtrar por UUID do setor")] = None,
    status_pa: Annotated[
        Optional[str], Query(description="Filtrar por status: ANALISE | DEFERIDO | INDEFERIDO")
    ] = None,
    data_inicio: Annotated[
        Optional[date], Query(description="Data proposta início (YYYY-MM-DD)")
    ] = None,
    data_fim: Annotated[
        Optional[date], Query(description="Data proposta fim (YYYY-MM-DD)")
    ] = None,
    situacao_certidao: Optional[str] = Query(
        None, description="ANALISE | VALIDA | CANCELADA"
    ),
) -> PaginacaoProposta:
    """
    Lista propostas com paginação e filtros opcionais.

    Não expõe CPF/CNPJ — use GET /portal/propostas/{codigo} para o detalhe completo.
    """
    items, total = await portal_repository.listar_propostas(
        session=session,
        page=page,
        page_size=page_size,
        setor_id=setor_id,
        status_pa=status_pa,
        data_inicio=data_inicio,
        data_fim=data_fim,
        situacao_certidao=situacao_certidao,
    )

    total_pages = max(1, math.ceil(total / page_size))

    items_out = [
        PropostaListItem(
            id=p.id,
            codigo=p.codigo,
            setor=p.setor.nome,
            interessado=p.interessado,
            uso_aca=p.uso_aca,
            cepac_total=p.cepac_total,
            status_pa=p.status_pa.value,
            data_proposta=p.data_proposta,
            requerimento=p.requerimento.value,
            situacao_certidao=p.situacao_certidao,
        )
        for p in items
    ]

    return PaginacaoProposta(
        items=items_out,
        total=total,
        page=page,
        page_size=page_size,
        total_pages=total_pages,
    )


# ---------------------------------------------------------------------------
# GET /portal/propostas/{codigo}
# ---------------------------------------------------------------------------

@router.get(
    "/propostas/{codigo}",
    response_model=PropostaPortalOut,
    status_code=status.HTTP_200_OK,
    summary="Buscar proposta por código",
)
async def buscar_proposta(
    codigo: str,
    session: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[UsuarioAutenticado, Depends(require_tecnico)],
) -> PropostaPortalOut:
    """
    Retorna dados completos de uma proposta pelo código (ex: AE-0183).

    Inclui interessado, CNPJ/CPF e endereço — requer TECNICO ou DIRETOR.
    """
    proposta = await portal_repository.buscar_proposta_por_codigo(session, codigo)
    if proposta is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Proposta '{codigo}' não encontrada.",
        )

    # Montar dicionário com campos que requerem conversão explícita (enums → str)
    # e depois deixar from_attributes resolver o restante dos campos da migration 012.
    data = {k: v for k, v in proposta.__dict__.items() if not k.startswith("_")}
    data["tipo_processo"] = proposta.tipo_processo.value if proposta.tipo_processo else None
    data["data_autuacao"] = str(proposta.data_autuacao) if proposta.data_autuacao else None
    data["status_pa"] = proposta.status_pa.value
    data["requerimento"] = proposta.requerimento.value
    data["setor"] = proposta.setor.nome

    # Montar certidões vinculadas (carregadas via selectinload em buscar_proposta_por_codigo)
    certidoes_out = [
        CertidaoItem(
            id=c.id,
            numero_certidao=c.numero_certidao,
            tipo=c.tipo.value,
            data_emissao=c.data_emissao,
            situacao=c.situacao.value,
            numero_processo_sei=c.numero_processo_sei,
            uso_aca=c.uso_aca,
            aca_r_m2=c.aca_r_m2,
            aca_nr_m2=c.aca_nr_m2,
            aca_total_m2=c.aca_total_m2,
            tipo_contrapartida=c.tipo_contrapartida,
            valor_oodc_rs=c.valor_oodc_rs,
            cepac_aca=c.cepac_aca,
            cepac_parametros=c.cepac_parametros,
            cepac_total=c.cepac_total,
            nuvem_r_m2=c.nuvem_r_m2,
            nuvem_nr_m2=c.nuvem_nr_m2,
            nuvem_total_m2=c.nuvem_total_m2,
            nuvem_cepac=c.nuvem_cepac,
            contribuinte_sq=c.contribuinte_sq,
            contribuinte_lote=c.contribuinte_lote,
            obs=c.obs,
            created_at=c.created_at,
        )
        for c in proposta.certidoes
    ]
    data["certidoes"] = certidoes_out

    return PropostaPortalOut.model_validate(data)
