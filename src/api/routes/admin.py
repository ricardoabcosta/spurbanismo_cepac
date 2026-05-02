"""
Rotas administrativas — setores, configuração global e gestão de usuários.

GET   /admin/setores                       → require_tecnico  (leitura para combobox)
POST  /admin/setores                       → require_diretor  (criação)
PUT   /admin/setores/{id}                  → require_diretor  (edição completa)
GET   /admin/configuracao                  → require_tecnico  (leitura)
PUT   /admin/configuracao                  → require_diretor  (edição)
GET   /admin/me                            → require_tecnico  (perfil do autenticado)
GET   /admin/usuarios                      → require_diretor  (lista todos os usuários)
PATCH /admin/usuarios/{id}/papel           → require_diretor  (altera papel)
PATCH /admin/usuarios/{id}/ativo           → require_diretor  (ativa/desativa)
"""
from datetime import datetime
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.auth.dependencies import UsuarioAutenticado, require_diretor, require_tecnico
from src.api.dependencies import get_db
from src.api.schemas.admin import (
    AtivoUpdate,
    ConfiguracaoIn,
    ConfiguracaoOut,
    PapelUpdate,
    SetorIn,
    SetorOut,
    UsuarioOut,
)
from src.core.models.configuracao_operacao import ConfiguracaoOperacao
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
) -> list[SetorOut]:
    result = await session.execute(select(Setor).order_by(Setor.nome))
    setores = result.scalars().all()
    return [SetorOut.model_validate(s) for s in setores]


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

    for field, value in payload.model_dump().items():
        setattr(setor, field, value)

    await session.commit()
    await session.refresh(setor)
    return SetorOut.model_validate(setor)


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
