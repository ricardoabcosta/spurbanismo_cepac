"""
Testes de integração — Bloco C: Filtro por OUC em GET /portal/propostas.

Cenários:
  - GET sem filtro retorna propostas de todas as OUCs.
  - GET ?operacao_urbana_id=1 retorna apenas propostas cujo setor pertence à OUCAE.
  - GET ?operacao_urbana_id=2 com base vazia retorna 0 itens (OUCFL sem propostas seed).
  - GET ?operacao_urbana_id=9999 retorna 0 itens (OUC inexistente — sem erro, apenas vazio).
"""
from __future__ import annotations

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.core.models.proposta import Proposta
from src.core.models.setor import Setor


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

async def _total_propostas_oucae(db: AsyncSession) -> int:
    """Conta propostas cujo setor pertence à OUCAE (operacao_urbana_id=1)."""
    result = await db.execute(
        select(Proposta)
        .join(Setor, Setor.id == Proposta.setor_id)
        .where(Setor.operacao_urbana_id == 1)
    )
    return len(result.scalars().all())


# ---------------------------------------------------------------------------
# Testes
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_filtro_ouc_oucae_retorna_somente_oucae(
    client_tecnico: AsyncClient, db_session: AsyncSession
) -> None:
    """
    GET /portal/propostas?operacao_urbana_id=1 deve retornar apenas propostas
    cujo setor pertence à OUCAE.

    Se não houver propostas, o teste verifica apenas que o total é 0
    (o filtro funcionou sem erro).
    """
    r = await client_tecnico.get("/portal/propostas?operacao_urbana_id=1&page_size=100")
    assert r.status_code == 200, r.text
    data = r.json()
    assert "items" in data
    assert "total" in data

    total_esperado = await _total_propostas_oucae(db_session)
    assert data["total"] == total_esperado


@pytest.mark.asyncio
async def test_filtro_ouc_oucfl_retorna_vazio(client_tecnico: AsyncClient) -> None:
    """
    GET /portal/propostas?operacao_urbana_id=2 deve retornar 0 propostas
    (OUCFL sem dados seed de propostas).
    """
    r = await client_tecnico.get("/portal/propostas?operacao_urbana_id=2")
    assert r.status_code == 200
    data = r.json()
    assert data["total"] == 0
    assert data["items"] == []


@pytest.mark.asyncio
async def test_filtro_ouc_inexistente_retorna_vazio(client_tecnico: AsyncClient) -> None:
    """
    GET /portal/propostas?operacao_urbana_id=9999 deve retornar 0 itens sem erros.
    OUC inexistente não é um erro — apenas não há propostas para ela.
    """
    r = await client_tecnico.get("/portal/propostas?operacao_urbana_id=9999")
    assert r.status_code == 200
    data = r.json()
    assert data["total"] == 0


@pytest.mark.asyncio
async def test_filtro_sem_ouc_retorna_todas(
    client_tecnico: AsyncClient, db_session: AsyncSession
) -> None:
    """
    GET /portal/propostas sem filtro de OUC deve retornar total geral
    (backward compat — nenhuma regressão).
    """
    result = await db_session.execute(select(Proposta))
    total_db = len(result.scalars().all())

    r = await client_tecnico.get("/portal/propostas?page_size=1")
    assert r.status_code == 200
    assert r.json()["total"] == total_db
