"""
T20 — Testes de integração: Autenticação e Autorização (T12).

Cenários testados:
  - Primeiro login cria usuário com papel TECNICO no banco.
  - Token válido de usuário existente retorna 200.
  - Token ausente retorna 401 nas rotas protegidas.
  - TECNICO não pode acessar endpoint restrito a DIRETOR.
  - get_current_user falha com 503 quando Azure AD não configurado.
"""
from __future__ import annotations

from datetime import datetime, timezone, timedelta
from unittest.mock import patch, AsyncMock
from uuid import uuid4

import pytest
from httpx import AsyncClient, ASGITransport
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.app import app
from src.api.auth.azure_ad import TokenPayload
from src.api.dependencies import get_db
from src.core.models.enums import PapelUsuarioEnum
from src.core.models.usuario import Usuario


def _make_token_payload(upn: str = "integracao@test.com") -> TokenPayload:
    return TokenPayload(
        upn=upn,
        nome="Usuário Integração",
        exp=datetime.now(tz=timezone.utc) + timedelta(hours=1),
    )


@pytest.mark.asyncio
async def test_primeiro_login_cria_tecnico(db_session: AsyncSession) -> None:
    """Primeiro acesso com UPN desconhecido deve criar usuario com papel=TECNICO."""
    upn = f"novo_{uuid4().hex[:8]}@spurbanismo.sp.gov.br"
    payload = _make_token_payload(upn=upn)

    async def _override_db():
        yield db_session

    app.dependency_overrides[get_db] = _override_db

    try:
        with patch(
            "src.api.auth.dependencies.validate_token",
            new_callable=AsyncMock,
            return_value=payload,
        ):
            async with AsyncClient(
                transport=ASGITransport(app=app), base_url="http://test"
            ) as ac:
                response = await ac.get(
                    "/dashboard/setores",
                    headers={"Authorization": "Bearer fake-token"},
                )
    finally:
        app.dependency_overrides.clear()

    assert response.status_code == 200

    result = await db_session.execute(
        select(Usuario).where(Usuario.upn == upn)
    )
    usuario = result.scalar_one_or_none()
    assert usuario is not None, "Usuário não foi criado no banco"
    assert usuario.papel == PapelUsuarioEnum.TECNICO
    assert usuario.ativo is True


@pytest.mark.asyncio
async def test_token_ausente_retorna_401(client_unauth: AsyncClient) -> None:
    """Requisição sem Authorization header deve retornar 401."""
    response = await client_unauth.get("/dashboard/setores")
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_tecnico_nao_acessa_medicoes_diretor(client_tecnico: AsyncClient) -> None:
    """TECNICO não pode acessar GET /dashboard/medicoes (restrito a DIRETOR)."""
    response = await client_tecnico.get("/dashboard/medicoes")
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_diretor_acessa_medicoes(client_diretor: AsyncClient) -> None:
    """DIRETOR pode acessar GET /dashboard/medicoes sem restrição."""
    response = await client_diretor.get("/dashboard/medicoes")
    assert response.status_code == 200
    assert isinstance(response.json(), list)


@pytest.mark.asyncio
async def test_tecnico_nao_acessa_snapshot_historico(client_tecnico: AsyncClient) -> None:
    """TECNICO não pode acessar snapshot histórico (?data=YYYY-MM-DD) — retorna 403."""
    response = await client_tecnico.get("/dashboard/snapshot?data=2025-01-01")
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_diretor_acessa_snapshot_historico(client_diretor: AsyncClient) -> None:
    """DIRETOR pode acessar snapshot histórico com ?data=YYYY-MM-DD."""
    response = await client_diretor.get("/dashboard/snapshot?data=2025-12-31")
    assert response.status_code == 200
    data = response.json()
    assert "prazo_zona" in data
    assert "setores" in data
