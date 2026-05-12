"""
Testes de integração — Bloco C: Setores com suporte a OUC e hierarquia.

Cenários:
  - GET /admin/setores retorna todos (22 setores seed).
  - GET /admin/setores?operacao_urbana_id=1 retorna apenas setores OUCAE.
  - GET /admin/operacoes-urbanas/{id}/setores retorna setores da OUC.
  - GET /admin/operacoes-urbanas/9999/setores retorna 404.
  - POST cria setor com operacao_urbana_id.
  - POST cria setor filho referenciando pai da mesma OUC.
  - POST rejeita pai de outra OUC (422).
  - POST rejeita operacao_urbana_id inexistente (422).
"""
from __future__ import annotations

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.core.models.setor import Setor


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _payload_setor(**overrides) -> dict:
    base = {
        "nome": f"Setor Teste {id(overrides)}",
        "estoque_total_m2": 10000,
        "teto_nr_m2": 5000,
        "teto_r_m2": 5000,
        "reserva_r_m2": None,
        "piso_r_percentual": None,
        "bloqueio_nr": False,
        "ativo": True,
        "cepacs_convertidos_aca": 0,
        "cepacs_convertidos_parametros": 0,
        "cepacs_desvinculados_aca": 0,
        "cepacs_desvinculados_parametros": 0,
        "operacao_urbana_id": 1,
        "setor_pai_id": None,
        "fator_equivalencia_f1": None,
        "fator_equivalencia_f2": None,
    }
    base.update(overrides)
    return base


async def _id_setor_raiz_oucab(db: AsyncSession) -> str:
    """Retorna o UUID de um setor raiz (sem pai) da OUCAB (id=3)."""
    result = await db.execute(
        select(Setor)
        .where(Setor.operacao_urbana_id == 3, Setor.setor_pai_id.is_(None))
        .limit(1)
    )
    setor = result.scalar_one_or_none()
    assert setor is not None, "Nenhum setor raiz OUCAB encontrado"
    return str(setor.id)


async def _id_setor_oucae(db: AsyncSession) -> str:
    """Retorna o UUID de qualquer setor da OUCAE (id=1)."""
    result = await db.execute(
        select(Setor).where(Setor.operacao_urbana_id == 1).limit(1)
    )
    setor = result.scalar_one_or_none()
    assert setor is not None, "Nenhum setor OUCAE encontrado"
    return str(setor.id)


# ---------------------------------------------------------------------------
# Listagem
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_listar_setores_retorna_todos(client_tecnico: AsyncClient) -> None:
    """GET /admin/setores sem filtro retorna todos os 22 setores seed."""
    r = await client_tecnico.get("/admin/setores")
    assert r.status_code == 200
    assert len(r.json()) >= 22


@pytest.mark.asyncio
async def test_listar_setores_filtro_ouc_oucae(client_tecnico: AsyncClient) -> None:
    """GET /admin/setores?operacao_urbana_id=1 retorna apenas setores OUCAE (5)."""
    r = await client_tecnico.get("/admin/setores?operacao_urbana_id=1")
    assert r.status_code == 200
    items = r.json()
    assert len(items) == 5
    for s in items:
        assert s["operacao_urbana_id"] == 1


@pytest.mark.asyncio
async def test_listar_setores_por_ouc_endpoint(client_tecnico: AsyncClient) -> None:
    """GET /admin/operacoes-urbanas/3/setores retorna 18 setores OUCAB (migration 030)."""
    r = await client_tecnico.get("/admin/operacoes-urbanas/3/setores")
    assert r.status_code == 200
    assert len(r.json()) == 18


@pytest.mark.asyncio
async def test_listar_setores_ouc_inexistente_retorna_404(client_tecnico: AsyncClient) -> None:
    """GET /admin/operacoes-urbanas/9999/setores retorna 404."""
    r = await client_tecnico.get("/admin/operacoes-urbanas/9999/setores")
    assert r.status_code == 404


# ---------------------------------------------------------------------------
# Criação
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_criar_setor_com_ouc(client_diretor: AsyncClient) -> None:
    """POST cria setor vinculado à OUCAE e retorna operacao_urbana_id correto."""
    r = await client_diretor.post(
        "/admin/setores",
        json=_payload_setor(nome="Setor Novo AE", operacao_urbana_id=1),
    )
    assert r.status_code == 201, r.text
    data = r.json()
    assert data["operacao_urbana_id"] == 1
    assert data["nome"] == "Setor Novo AE"


@pytest.mark.asyncio
async def test_criar_setor_filho_mesma_ouc(
    client_diretor: AsyncClient, db_session: AsyncSession
) -> None:
    """POST cria setor filho referenciando pai na mesma OUC — deve retornar 201."""
    pai_id = await _id_setor_raiz_oucab(db_session)
    r = await client_diretor.post(
        "/admin/setores",
        json=_payload_setor(
            nome="Setor Filho Novo",
            operacao_urbana_id=3,
            setor_pai_id=pai_id,
        ),
    )
    assert r.status_code == 201, r.text
    assert r.json()["setor_pai_id"] == pai_id


@pytest.mark.asyncio
async def test_criar_setor_pai_outra_ouc_retorna_422(
    client_diretor: AsyncClient, db_session: AsyncSession
) -> None:
    """POST com setor_pai_id de OUC diferente deve retornar 422."""
    pai_id_oucae = await _id_setor_oucae(db_session)
    r = await client_diretor.post(
        "/admin/setores",
        json=_payload_setor(
            nome="Setor Filho Inválido",
            operacao_urbana_id=3,   # OUCAB
            setor_pai_id=pai_id_oucae,  # pai é da OUCAE
        ),
    )
    assert r.status_code == 422


@pytest.mark.asyncio
async def test_criar_setor_ouc_inexistente_retorna_422(client_diretor: AsyncClient) -> None:
    """POST com operacao_urbana_id inexistente deve retornar 422."""
    r = await client_diretor.post(
        "/admin/setores",
        json=_payload_setor(nome="Setor OUC Inexistente", operacao_urbana_id=9999),
    )
    assert r.status_code == 422
