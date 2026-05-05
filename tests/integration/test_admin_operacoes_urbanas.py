"""
Testes de integração — Bloco C: CRUD de Operações Urbanas (/admin/operacoes-urbanas).

Cenários:
  - GET lista retorna as 3 OUCs seed (AE, FL, AB).
  - GET lista com ?ativo=true filtra corretamente.
  - POST cria nova OUC (require_diretor).
  - POST com sigla duplicada retorna 409.
  - GET /{id} retorna OUC existente.
  - GET /{id} com ID inexistente retorna 404.
  - PUT /{id} atualiza campos.
  - PUT /{id} com sigla de outra OUC retorna 409.
  - TECNICO não pode criar OUC (403).
"""
from __future__ import annotations

import pytest
from httpx import AsyncClient


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _payload_ouc(**overrides) -> dict:
    base = {
        "nome": "OUC Teste",
        "sigla": "TST",
        "lei_vigente": "Lei 99.999/26",
        "estoque_maximo_global_r": None,
        "estoque_maximo_global_nr": None,
        "possui_nuvem": False,
        "valor_cepac_ref": None,
        "data_ultima_posicao": None,
        "ativo": True,
        "teto_r_nao_incentivado_m2": None,
        "reserva_tecnica_m2": 0,
        "cepacs_leiloados": 0,
        "cepacs_colocacao_privada": 0,
        "cepacs_totais": 0,
    }
    base.update(overrides)
    return base


# ---------------------------------------------------------------------------
# Testes de leitura
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_listar_oucs_retorna_seed(client_tecnico: AsyncClient) -> None:
    """GET /admin/operacoes-urbanas deve retornar pelo menos AE, FL e AB."""
    r = await client_tecnico.get("/admin/operacoes-urbanas")
    assert r.status_code == 200
    siglas = {ouc["sigla"] for ouc in r.json()}
    assert {"AE", "FL", "AB"}.issubset(siglas)


@pytest.mark.asyncio
async def test_listar_oucs_filtro_ativo(client_tecnico: AsyncClient) -> None:
    """GET /admin/operacoes-urbanas?ativo=true retorna apenas OUCs ativas."""
    r = await client_tecnico.get("/admin/operacoes-urbanas?ativo=true")
    assert r.status_code == 200
    for ouc in r.json():
        assert ouc["ativo"] is True


@pytest.mark.asyncio
async def test_buscar_ouc_existente(client_tecnico: AsyncClient) -> None:
    """GET /admin/operacoes-urbanas/1 retorna OUCAE."""
    r = await client_tecnico.get("/admin/operacoes-urbanas/1")
    assert r.status_code == 200
    assert r.json()["sigla"] == "AE"


@pytest.mark.asyncio
async def test_buscar_ouc_inexistente_retorna_404(client_tecnico: AsyncClient) -> None:
    """GET com ID inexistente deve retornar 404."""
    r = await client_tecnico.get("/admin/operacoes-urbanas/9999")
    assert r.status_code == 404


# ---------------------------------------------------------------------------
# Testes de criação (require_diretor)
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_criar_ouc_diretor(client_diretor: AsyncClient) -> None:
    """POST cria nova OUC e retorna 201 com os dados."""
    r = await client_diretor.post("/admin/operacoes-urbanas", json=_payload_ouc())
    assert r.status_code == 201, r.text
    data = r.json()
    assert data["sigla"] == "TST"
    assert data["nome"] == "OUC Teste"
    assert "id" in data


@pytest.mark.asyncio
async def test_criar_ouc_sigla_duplicada_retorna_409(client_diretor: AsyncClient) -> None:
    """POST com sigla já existente deve retornar 409."""
    await client_diretor.post("/admin/operacoes-urbanas", json=_payload_ouc())
    r2 = await client_diretor.post("/admin/operacoes-urbanas", json=_payload_ouc())
    assert r2.status_code == 409


@pytest.mark.asyncio
async def test_criar_ouc_tecnico_retorna_403(client_tecnico: AsyncClient) -> None:
    """TECNICO não tem permissão para criar OUC — deve retornar 403."""
    r = await client_tecnico.post("/admin/operacoes-urbanas", json=_payload_ouc(sigla="X01"))
    assert r.status_code == 403


# ---------------------------------------------------------------------------
# Testes de atualização (require_diretor)
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_atualizar_ouc(client_diretor: AsyncClient) -> None:
    """PUT atualiza nome e retorna OUC atualizada."""
    r_create = await client_diretor.post("/admin/operacoes-urbanas", json=_payload_ouc())
    assert r_create.status_code == 201
    ouc_id = r_create.json()["id"]

    r_update = await client_diretor.put(
        f"/admin/operacoes-urbanas/{ouc_id}",
        json=_payload_ouc(nome="OUC Teste Atualizada"),
    )
    assert r_update.status_code == 200
    assert r_update.json()["nome"] == "OUC Teste Atualizada"


@pytest.mark.asyncio
async def test_atualizar_ouc_sigla_conflito_retorna_409(client_diretor: AsyncClient) -> None:
    """PUT com sigla que pertence a outra OUC deve retornar 409."""
    r = await client_diretor.put(
        "/admin/operacoes-urbanas/1",
        json=_payload_ouc(sigla="FL"),  # sigla da OUCFL
    )
    assert r.status_code == 409


@pytest.mark.asyncio
async def test_atualizar_ouc_inexistente_retorna_404(client_diretor: AsyncClient) -> None:
    """PUT em ID inexistente deve retornar 404."""
    r = await client_diretor.put(
        "/admin/operacoes-urbanas/9999",
        json=_payload_ouc(sigla="ZZZ"),
    )
    assert r.status_code == 404
