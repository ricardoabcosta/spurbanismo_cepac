"""
src/api/auth/azure_ad.py
SP Urbanismo / Prodam — CEPAC T12

Validação de tokens JWT do Azure AD via JWKS.

Responsabilidades:
  - Buscar e cachear as chaves públicas do Azure AD (cache TTL: 1 hora)
  - Validar assinatura RS256, audience, issuer e expiração
  - Extrair claims relevantes (upn, name, exp)

NÃO responsável por:
  - Lógica de papéis (TECNICO/DIRETOR) — gerenciada no banco (D4)
  - Acesso ao banco de dados — isso fica em auth/dependencies.py

Uso:
    payload = await validate_token(token, settings)
    upn = payload.upn   # "joao.silva@spurbanismo.sp.gov.br"
"""
from __future__ import annotations

import asyncio
import logging
import time
from dataclasses import dataclass
from datetime import datetime, timezone

import jwt
from fastapi import HTTPException, status
from jwt import ExpiredSignatureError, InvalidTokenError, PyJWKClient

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Cache module-level do PyJWKClient (reuse por 1 hora)
# ---------------------------------------------------------------------------

_jwks_client: PyJWKClient | None = None
_jwks_client_created_at: float = 0.0
_JWKS_CACHE_TTL_SECONDS: int = 3600  # 1 hora


def _get_jwks_client(tenant_id: str) -> PyJWKClient:
    """
    Retorna um PyJWKClient, criando um novo quando o TTL de 1h expira.

    PyJWKClient busca as chaves na primeira chamada e as armazena internamente.
    Criamos um novo cliente a cada hora para forçar a renegociação das chaves,
    garantindo que rotações de chave no Azure AD sejam captadas em até 1h.
    """
    global _jwks_client, _jwks_client_created_at

    now = time.monotonic()
    if _jwks_client is None or (now - _jwks_client_created_at) > _JWKS_CACHE_TTL_SECONDS:
        jwks_uri = (
            f"https://login.microsoftonline.com/{tenant_id}"
            f"/discovery/v2.0/keys"
        )
        logger.debug("Criando novo PyJWKClient para tenant %s", tenant_id)
        _jwks_client = PyJWKClient(jwks_uri)
        _jwks_client_created_at = now

    return _jwks_client


# ---------------------------------------------------------------------------
# Token payload extraído
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class TokenPayload:
    """Claims extraídos de um token Azure AD validado."""
    upn: str
    nome: str | None
    exp: datetime


# ---------------------------------------------------------------------------
# Validação assíncrona
# ---------------------------------------------------------------------------

async def validate_token(token: str, tenant_id: str, client_id: str) -> TokenPayload:
    """
    Valida assinatura JWT do Azure AD e extrai o payload.

    A busca de JWKS (IO) é executada em thread pool para não bloquear o
    event loop. jwt.decode (CPU) roda diretamente.

    Raises:
        HTTPException(401) se o token for inválido, expirado ou malformado.
        HTTPException(503) se tenant_id ou client_id não estiverem configurados.
    """
    if not tenant_id or not client_id:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Azure AD não configurado — defina AZURE_AD_TENANT_ID e AZURE_AD_CLIENT_ID.",
        )

    client = _get_jwks_client(tenant_id)

    # Resolve a signing key (pode fazer HTTP ao JWKS endpoint — executar em thread)
    try:
        signing_key = await asyncio.to_thread(client.get_signing_key_from_jwt, token)
    except Exception as exc:
        logger.warning("Falha ao obter chave JWKS: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido — não foi possível obter a chave de assinatura.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    issuer = f"https://login.microsoftonline.com/{tenant_id}/v2.0"

    try:
        payload = jwt.decode(
            token,
            signing_key.key,
            algorithms=["RS256"],
            audience=client_id,
            issuer=issuer,
            options={"verify_exp": True},
        )
    except ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token expirado.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except InvalidTokenError as exc:
        logger.debug("Token inválido: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    upn = payload.get("upn") or payload.get("preferred_username") or payload.get("sub")
    if not upn:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token sem identificador de usuário (upn/preferred_username).",
            headers={"WWW-Authenticate": "Bearer"},
        )

    exp_ts = payload.get("exp")
    exp_dt = (
        datetime.fromtimestamp(exp_ts, tz=timezone.utc)
        if exp_ts
        else datetime.now(tz=timezone.utc)
    )

    return TokenPayload(
        upn=str(upn),
        nome=payload.get("name"),
        exp=exp_dt,
    )
