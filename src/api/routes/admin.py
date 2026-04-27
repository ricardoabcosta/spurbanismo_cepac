"""
Rotas administrativas — setores e configuração global da operação.

GET  /admin/setores          → require_tecnico  (leitura para combobox)
POST /admin/setores          → require_diretor  (criação)
PUT  /admin/setores/{id}     → require_diretor  (edição completa)
GET  /admin/configuracao     → require_tecnico  (leitura)
PUT  /admin/configuracao     → require_diretor  (edição)
"""
from datetime import datetime
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.auth.dependencies import UsuarioAutenticado, require_diretor, require_tecnico
from src.api.dependencies import get_db
from src.api.schemas.admin import ConfiguracaoIn, ConfiguracaoOut, SetorIn, SetorOut
from src.core.models.configuracao_operacao import ConfiguracaoOperacao
from src.core.models.setor import Setor

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
