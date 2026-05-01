"""
src/api/auth/dependencies.py
SP Urbanismo / Prodam — CEPAC T12

Dependências FastAPI de autenticação e autorização.

Fluxo de get_current_user():
  1. Extrai Bearer token do header Authorization
  2. Valida assinatura JWT via JWKS do Azure AD (azure_ad.validate_token)
  3. Lookup em `usuario` WHERE upn = ? — cria com papel=TECNICO se novo (D4)
  4. Atualiza last_login_at
  5. Retorna UsuarioAutenticado

Dependências exportadas:
  get_current_user  — qualquer usuário autenticado (TECNICO ou DIRETOR)
  require_tecnico   — TECNICO ou DIRETOR (DIRETOR é superconjunto)
  require_diretor   — somente DIRETOR

Decisão D4: papéis gerenciados no banco, NÃO no Azure AD.
  - JWT validado → extrai upn
  - `papel` vem de `usuario.papel` — nunca de claims JWT

Sem ciclo de importação:
  auth/dependencies → api/dependencies (somente get_db)
  routes            → api/dependencies + auth/dependencies
  api/dependencies  → NÃO importa auth/dependencies
"""
from __future__ import annotations

import logging
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from uuid import UUID

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.auth.azure_ad import TokenPayload, validate_token
from src.api.dependencies import get_db  # sentido único — sem ciclo
from src.config import settings
from src.core.models.enums import PapelUsuarioEnum
from src.core.models.usuario import Usuario

logger = logging.getLogger(__name__)

_bearer_scheme = HTTPBearer(auto_error=False)


# ---------------------------------------------------------------------------
# DTO de usuário autenticado
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class UsuarioAutenticado:
    """
    Usuário autenticado com papel definido no banco de dados.

    `papel` é sempre lido de `usuario.papel` — nunca de claims JWT (D4).
    """
    id: UUID
    upn: str
    nome: str | None
    papel: PapelUsuarioEnum
    token_exp: datetime


# ---------------------------------------------------------------------------
# Upsert de usuário
# ---------------------------------------------------------------------------

async def _upsert_usuario(session: AsyncSession, payload: TokenPayload) -> Usuario:
    """
    Retorna o registro existente ou cria novo com papel=TECNICO.
    Atualiza last_login_at e nome a cada autenticação bem-sucedida.
    """
    stmt = select(Usuario).where(Usuario.upn == payload.upn)
    result = await session.execute(stmt)
    usuario = result.scalar_one_or_none()

    agora = datetime.utcnow()

    if usuario is None:
        logger.info("Primeiro login: criando usuario upn=%s", payload.upn)
        usuario = Usuario(
            upn=payload.upn,
            nome=payload.nome,
            papel=PapelUsuarioEnum.TECNICO,
            ativo=True,
            last_login_at=agora,
        )
        session.add(usuario)
        await session.flush()  # gera o UUID antes do return
    else:
        usuario.last_login_at = agora
        if payload.nome and usuario.nome != payload.nome:
            usuario.nome = payload.nome

    return usuario


# ---------------------------------------------------------------------------
# Dependência principal
# ---------------------------------------------------------------------------

_DEV_BYPASS_UPN = "dev@bypass.local"
_DEV_BYPASS_NOME = "Dev Bypass (local)"


async def _get_dev_bypass_user(session: AsyncSession) -> UsuarioAutenticado:
    """Upsert do usuário de bypass e retorno como TECNICO. Apenas em DEV_BYPASS_AUTH=true."""
    stmt = select(Usuario).where(Usuario.upn == _DEV_BYPASS_UPN)
    result = await session.execute(stmt)
    usuario = result.scalar_one_or_none()

    if usuario is None:
        usuario = Usuario(
            upn=_DEV_BYPASS_UPN,
            nome=_DEV_BYPASS_NOME,
            papel=PapelUsuarioEnum.TECNICO,
            ativo=True,
            last_login_at=datetime.utcnow(),
        )
        session.add(usuario)
        await session.flush()
    await session.commit()

    return UsuarioAutenticado(
        id=usuario.id,
        upn=usuario.upn,
        nome=usuario.nome,
        papel=usuario.papel,
        token_exp=datetime.now(tz=timezone.utc) + timedelta(hours=8),
    )


async def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer_scheme),
    session: AsyncSession = Depends(get_db),
) -> UsuarioAutenticado:
    """
    Valida JWT Azure AD e retorna o usuário autenticado.

    Nunca retorna "desconhecido" — qualquer falha resulta em 401.
    Corrige o achado T8-1 da Fase 1.
    """
    if settings.dev_bypass_auth:
        return await _get_dev_bypass_user(session)

    if credentials is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token de autenticação ausente.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token_payload = await validate_token(
        token=credentials.credentials,
        tenant_id=settings.azure_ad_tenant_id or "",
        client_id=settings.azure_ad_client_id or "",
    )

    usuario = await _upsert_usuario(session, token_payload)
    await session.commit()

    if not usuario.ativo:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Usuário desativado.",
        )

    return UsuarioAutenticado(
        id=usuario.id,
        upn=usuario.upn,
        nome=usuario.nome,
        papel=usuario.papel,
        token_exp=token_payload.exp,
    )


# ---------------------------------------------------------------------------
# Atalhos de autorização
# ---------------------------------------------------------------------------

async def require_tecnico(
    current_user: UsuarioAutenticado = Depends(get_current_user),
) -> UsuarioAutenticado:
    """Exige TECNICO ou DIRETOR (DIRETOR é superconjunto de TECNICO)."""
    if current_user.papel not in (PapelUsuarioEnum.TECNICO, PapelUsuarioEnum.DIRETOR):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Permissão insuficiente. Requerido: TECNICO ou DIRETOR.",
        )
    return current_user


async def require_diretor(
    current_user: UsuarioAutenticado = Depends(get_current_user),
) -> UsuarioAutenticado:
    """Exige DIRETOR."""
    if current_user.papel != PapelUsuarioEnum.DIRETOR:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Permissão insuficiente. Requerido: DIRETOR.",
        )
    return current_user
