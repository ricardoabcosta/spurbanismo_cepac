"""
Rotas administrativas — setores, operações urbanas, configuração global e gestão de usuários.

GET   /admin/setores                            → require_tecnico  (leitura para combobox)
POST  /admin/setores                            → require_diretor  (criação)
PUT   /admin/setores/{id}                       → require_diretor  (edição completa)
GET   /admin/operacoes-urbanas                  → require_tecnico  (lista todas as OUCs)
POST  /admin/operacoes-urbanas                  → require_diretor  (criação)
GET   /admin/operacoes-urbanas/{id}             → require_tecnico  (detalhe)
PUT   /admin/operacoes-urbanas/{id}             → require_diretor  (edição)
GET   /admin/operacoes-urbanas/{id}/setores     → require_tecnico  (setores de uma OUC)
GET   /admin/configuracao                       → require_tecnico  (leitura)
PUT   /admin/configuracao                       → require_diretor  (edição)
GET   /admin/me                                 → require_tecnico  (perfil do autenticado)
GET   /admin/usuarios                           → require_diretor  (lista todos os usuários)
PATCH /admin/usuarios/{id}/papel                → require_diretor  (altera papel)
PATCH /admin/usuarios/{id}/ativo                → require_diretor  (ativa/desativa)
"""
from datetime import datetime
from typing import Annotated, Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.auth.dependencies import UsuarioAutenticado, require_diretor, require_tecnico
from src.api.dependencies import get_db
from src.api.schemas.admin import (
    AtivoUpdate,
    ConfiguracaoIn,
    ConfiguracaoOut,
    OperacaoUrbanaIn,
    OperacaoUrbanaOut,
    OperacaoUrbanaResumo,
    PapelUpdate,
    SetorIn,
    SetorOut,
    UsuarioOut,
)
from src.core.models.configuracao_operacao import ConfiguracaoOperacao
from src.core.models.operacao_urbana import OperacaoUrbana
from src.core.models.setor import Setor
from src.core.models.usuario import Usuario

router = APIRouter(prefix="/admin", tags=["admin"])


# ---------------------------------------------------------------------------
# Setores
# ---------------------------------------------------------------------------

@router.get(
    "/setores",
    response_model=list[SetorOut],
    summary="Listar todos os setores",
)
async def listar_setores(
    session: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[UsuarioAutenticado, Depends(require_tecnico)],
    operacao_urbana_id: Annotated[
        Optional[int], Query(description="Filtrar por ID da Operação Urbana")
    ] = None,
) -> list[SetorOut]:
    stmt = select(Setor)
    if operacao_urbana_id is not None:
        stmt = stmt.where(Setor.operacao_urbana_id == operacao_urbana_id)
    stmt = stmt.order_by(Setor.nome)
    result = await session.execute(stmt)
    setores = result.scalars().all()
    return [SetorOut.model_validate(s) for s in setores]


async def _validar_referencias_setor(
    session: AsyncSession,
    payload: SetorIn,
    setor_id: Optional[UUID] = None,
) -> None:
    """
    Valida operacao_urbana_id e setor_pai_id do payload.
    Lança HTTPException 422 se alguma restrição for violada.
    """
    # Verificar existência da OUC
    ouc = await session.execute(
        select(OperacaoUrbana).where(OperacaoUrbana.id == payload.operacao_urbana_id)
    )
    if ouc.scalar_one_or_none() is None:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Operação Urbana não encontrada.",
        )

    # Verificar setor pai
    if payload.setor_pai_id is not None:
        # Impedir auto-referência (relevante no PUT)
        if setor_id is not None and payload.setor_pai_id == setor_id:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Um setor não pode ser pai de si mesmo.",
            )
        pai_result = await session.execute(
            select(Setor).where(Setor.id == payload.setor_pai_id)
        )
        pai = pai_result.scalar_one_or_none()
        if (
            pai is None
            or not pai.ativo
            or pai.operacao_urbana_id != payload.operacao_urbana_id
        ):
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Setor pai não pertence à mesma Operação Urbana.",
            )


@router.post(
    "/setores",
    response_model=SetorOut,
    status_code=status.HTTP_201_CREATED,
    summary="Criar setor",
)
async def criar_setor(
    payload: SetorIn,
    session: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[UsuarioAutenticado, Depends(require_diretor)],
) -> SetorOut:
    existente = await session.execute(select(Setor).where(Setor.nome == payload.nome))
    if existente.scalar_one_or_none() is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Setor '{payload.nome}' já existe.",
        )
    await _validar_referencias_setor(session, payload)
    setor = Setor(**payload.model_dump())
    session.add(setor)
    await session.flush()
    await session.commit()
    await session.refresh(setor)
    return SetorOut.model_validate(setor)


@router.put(
    "/setores/{setor_id}",
    response_model=SetorOut,
    summary="Atualizar setor",
)
async def atualizar_setor(
    setor_id: UUID,
    payload: SetorIn,
    session: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[UsuarioAutenticado, Depends(require_diretor)],
) -> SetorOut:
    result = await session.execute(select(Setor).where(Setor.id == setor_id))
    setor = result.scalar_one_or_none()
    if setor is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Setor não encontrado.")

    conflito = await session.execute(
        select(Setor).where(Setor.nome == payload.nome, Setor.id != setor_id)
    )
    if conflito.scalar_one_or_none() is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Outro setor com nome '{payload.nome}' já existe.",
        )

    await _validar_referencias_setor(session, payload, setor_id=setor_id)

    for field, value in payload.model_dump().items():
        setattr(setor, field, value)

    await session.commit()
    await session.refresh(setor)
    return SetorOut.model_validate(setor)


# ---------------------------------------------------------------------------
# Operações Urbanas Consorciadas (OUC)
# ---------------------------------------------------------------------------

@router.get(
    "/operacoes-urbanas",
    response_model=list[OperacaoUrbanaOut],
    summary="Listar Operações Urbanas",
)
async def listar_operacoes_urbanas(
    session: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[UsuarioAutenticado, Depends(require_tecnico)],
    ativo: Annotated[
        Optional[bool], Query(description="Filtrar por status ativo/inativo")
    ] = None,
) -> list[OperacaoUrbanaOut]:
    stmt = select(OperacaoUrbana)
    if ativo is not None:
        stmt = stmt.where(OperacaoUrbana.ativo == ativo)
    stmt = stmt.order_by(OperacaoUrbana.sigla)
    result = await session.execute(stmt)
    oucs = result.scalars().all()
    return [OperacaoUrbanaOut.model_validate(o) for o in oucs]


@router.post(
    "/operacoes-urbanas",
    response_model=OperacaoUrbanaOut,
    status_code=status.HTTP_201_CREATED,
    summary="Criar Operação Urbana",
)
async def criar_operacao_urbana(
    payload: OperacaoUrbanaIn,
    session: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[UsuarioAutenticado, Depends(require_diretor)],
) -> OperacaoUrbanaOut:
    existente = await session.execute(
        select(OperacaoUrbana).where(OperacaoUrbana.sigla == payload.sigla)
    )
    if existente.scalar_one_or_none() is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Operação Urbana com sigla '{payload.sigla}' já existe.",
        )
    ouc = OperacaoUrbana(**payload.model_dump())
    session.add(ouc)
    await session.flush()
    await session.commit()
    await session.refresh(ouc)
    return OperacaoUrbanaOut.model_validate(ouc)


@router.get(
    "/operacoes-urbanas/{ouc_id}",
    response_model=OperacaoUrbanaOut,
    summary="Detalhe de Operação Urbana",
)
async def detalhar_operacao_urbana(
    ouc_id: int,
    session: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[UsuarioAutenticado, Depends(require_tecnico)],
) -> OperacaoUrbanaOut:
    result = await session.execute(
        select(OperacaoUrbana).where(OperacaoUrbana.id == ouc_id)
    )
    ouc = result.scalar_one_or_none()
    if ouc is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Operação Urbana não encontrada.",
        )
    return OperacaoUrbanaOut.model_validate(ouc)


@router.put(
    "/operacoes-urbanas/{ouc_id}",
    response_model=OperacaoUrbanaOut,
    summary="Atualizar Operação Urbana",
)
async def atualizar_operacao_urbana(
    ouc_id: int,
    payload: OperacaoUrbanaIn,
    session: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[UsuarioAutenticado, Depends(require_diretor)],
) -> OperacaoUrbanaOut:
    result = await session.execute(
        select(OperacaoUrbana).where(OperacaoUrbana.id == ouc_id)
    )
    ouc = result.scalar_one_or_none()
    if ouc is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Operação Urbana não encontrada.",
        )

    conflito = await session.execute(
        select(OperacaoUrbana).where(
            OperacaoUrbana.sigla == payload.sigla,
            OperacaoUrbana.id != ouc_id,
        )
    )
    if conflito.scalar_one_or_none() is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Outra Operação Urbana com sigla '{payload.sigla}' já existe.",
        )

    for field, value in payload.model_dump().items():
        setattr(ouc, field, value)

    await session.commit()
    await session.refresh(ouc)
    return OperacaoUrbanaOut.model_validate(ouc)


@router.get(
    "/operacoes-urbanas/{ouc_id}/setores",
    response_model=list[SetorOut],
    summary="Listar setores de uma Operação Urbana",
)
async def listar_setores_por_ouc(
    ouc_id: int,
    session: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[UsuarioAutenticado, Depends(require_tecnico)],
) -> list[SetorOut]:
    ouc_result = await session.execute(
        select(OperacaoUrbana).where(OperacaoUrbana.id == ouc_id)
    )
    if ouc_result.scalar_one_or_none() is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Operação Urbana não encontrada.",
        )
    result = await session.execute(
        select(Setor)
        .where(Setor.operacao_urbana_id == ouc_id)
        .order_by(Setor.nome)
    )
    setores = result.scalars().all()
    return [SetorOut.model_validate(s) for s in setores]


# ---------------------------------------------------------------------------
# Configuração global da operação (singleton id=1)
# ---------------------------------------------------------------------------

async def _get_or_create_config(session: AsyncSession) -> ConfiguracaoOperacao:
    result = await session.execute(select(ConfiguracaoOperacao).where(ConfiguracaoOperacao.id == 1))
    cfg = result.scalar_one_or_none()
    if cfg is None:
        cfg = ConfiguracaoOperacao(id=1)
        session.add(cfg)
        await session.flush()
    return cfg


@router.get(
    "/configuracao",
    response_model=ConfiguracaoOut,
    summary="Ler configuração global da operação",
)
async def ler_configuracao(
    session: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[UsuarioAutenticado, Depends(require_tecnico)],
) -> ConfiguracaoOut:
    cfg = await _get_or_create_config(session)
    return ConfiguracaoOut.model_validate(cfg)


@router.put(
    "/configuracao",
    response_model=ConfiguracaoOut,
    summary="Atualizar configuração global da operação",
)
async def atualizar_configuracao(
    payload: ConfiguracaoIn,
    session: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[UsuarioAutenticado, Depends(require_diretor)],
) -> ConfiguracaoOut:
    cfg = await _get_or_create_config(session)
    cfg.reserva_tecnica_m2 = payload.reserva_tecnica_m2
    cfg.cepacs_leiloados = payload.cepacs_leiloados
    cfg.cepacs_colocacao_privada = payload.cepacs_colocacao_privada
    cfg.cepacs_totais = payload.cepacs_totais
    cfg.updated_at = datetime.utcnow()
    await session.commit()
    await session.refresh(cfg)
    return ConfiguracaoOut.model_validate(cfg)


# ---------------------------------------------------------------------------
# Gestão de usuários
# ---------------------------------------------------------------------------

@router.get(
    "/me",
    response_model=UsuarioOut,
    summary="Perfil do usuário autenticado",
)
async def meu_perfil(
    session: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[UsuarioAutenticado, Depends(require_tecnico)],
) -> UsuarioOut:
    result = await session.execute(select(Usuario).where(Usuario.id == current_user.id))
    usuario = result.scalar_one_or_none()
    if usuario is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuário não encontrado.")
    return UsuarioOut.model_validate(usuario)


@router.get(
    "/usuarios",
    response_model=list[UsuarioOut],
    summary="Listar todos os usuários",
)
async def listar_usuarios(
    session: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[UsuarioAutenticado, Depends(require_diretor)],
) -> list[UsuarioOut]:
    # NULLS LAST: usuários sem nome aparecem ao final
    result = await session.execute(
        select(Usuario).order_by(Usuario.nome.asc().nulls_last())
    )
    usuarios = result.scalars().all()
    return [UsuarioOut.model_validate(u) for u in usuarios]


@router.patch(
    "/usuarios/{usuario_id}/papel",
    response_model=UsuarioOut,
    summary="Alterar papel de um usuário",
)
async def alterar_papel(
    usuario_id: UUID,
    payload: PapelUpdate,
    session: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[UsuarioAutenticado, Depends(require_diretor)],
) -> UsuarioOut:
    if usuario_id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Você não pode alterar seu próprio perfil.",
        )
    result = await session.execute(select(Usuario).where(Usuario.id == usuario_id))
    usuario = result.scalar_one_or_none()
    if usuario is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuário não encontrado.")
    usuario.papel = payload.papel
    await session.commit()
    await session.refresh(usuario)
    return UsuarioOut.model_validate(usuario)


@router.patch(
    "/usuarios/{usuario_id}/ativo",
    response_model=UsuarioOut,
    summary="Ativar ou desativar um usuário",
)
async def alterar_ativo(
    usuario_id: UUID,
    payload: AtivoUpdate,
    session: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[UsuarioAutenticado, Depends(require_diretor)],
) -> UsuarioOut:
    if usuario_id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Você não pode desativar sua própria conta.",
        )
    result = await session.execute(select(Usuario).where(Usuario.id == usuario_id))
    usuario = result.scalar_one_or_none()
    if usuario is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuário não encontrado.")
    usuario.ativo = payload.ativo
    await session.commit()
    await session.refresh(usuario)
    return UsuarioOut.model_validate(usuario)
