"""
T20 — Testes de integração: Medições de Obra (T17).

Cenários testados:
  - POST /medicoes cria nova medição com valor_acumulado correto.
  - GET /medicoes/atual retorna a medição mais recente.
  - POST /medicoes com mesma data retorna 422 MEDICAO_JA_EXISTE.
  - POST /medicoes sem autenticação retorna 401.
  - Regra: dia_referencia deve ser dia 1 do mês.
"""
from __future__ import annotations

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_get_medicao_atual_tecnico(client_tecnico: AsyncClient) -> None:
    """GET /medicoes/atual acessível por TECNICO — retorna medição mais recente."""
    response = await client_tecnico.get("/medicoes/atual")
    assert response.status_code == 200
    data = response.json()
    assert "data_referencia" in data
    assert "valor_acumulado" in data
    assert "gerado_em" in data
    # Migration 006 inseriu 2026-04-01
    assert data["data_referencia"] == "2026-04-01"


@pytest.mark.asyncio
async def test_post_medicao_nova(client_diretor: AsyncClient) -> None:
    """POST /medicoes cria nova medição; valor_acumulado = anterior + novo."""
    payload = {
        "data_referencia": "2026-10-01",
        "valor_medicao": "500000.00",
        "numero_processo_sei": "7810.2026/0001000-0",
        "descricao": "Medição de teste",
    }
    response = await client_diretor.post("/medicoes", json=payload)
    assert response.status_code == 201, response.text

    data = response.json()
    assert data["data_referencia"] == "2026-10-01"

    # Valor acumulado = seed (3987822642.21) + novo (500000.00)
    acumulado = float(data["valor_acumulado"])
    assert acumulado == pytest.approx(3987822642.21 + 500000.00, rel=1e-4)


@pytest.mark.asyncio
async def test_post_medicao_data_duplicada_retorna_422(
    client_diretor: AsyncClient,
) -> None:
    """POST com data_referencia já existente retorna 422 MEDICAO_JA_EXISTE."""
    payload = {
        "data_referencia": "2026-11-01",
        "valor_medicao": "100000.00",
        "numero_processo_sei": "7810.2026/0001001-7",
    }

    # Primeira inserção deve ser bem-sucedida
    first = await client_diretor.post("/medicoes", json=payload)
    assert first.status_code == 201

    # Segunda inserção com mesma data deve falhar
    second = await client_diretor.post("/medicoes", json=payload)
    assert second.status_code == 422
    detail = second.json()
    assert "MEDICAO_JA_EXISTE" in str(detail)


@pytest.mark.asyncio
async def test_post_medicao_dia_diferente_de_1_retorna_422(
    client_diretor: AsyncClient,
) -> None:
    """data_referencia com dia != 1 retorna 422 (validação Pydantic)."""
    payload = {
        "data_referencia": "2026-07-15",  # dia 15 — inválido
        "valor_medicao": "100000.00",
        "numero_processo_sei": "7810.2026/0001002-4",
    }
    response = await client_diretor.post("/medicoes", json=payload)
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_post_medicao_tecnico_negado(client_tecnico: AsyncClient) -> None:
    """TECNICO não pode registrar medição (403)."""
    payload = {
        "data_referencia": "2026-08-01",
        "valor_medicao": "100000.00",
        "numero_processo_sei": "7810.2026/0001003-1",
    }
    response = await client_tecnico.post("/medicoes", json=payload)
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_post_medicao_sem_auth_retorna_401(
    client_unauth: AsyncClient,
) -> None:
    """Requisição sem autenticação retorna 401."""
    payload = {
        "data_referencia": "2026-09-01",
        "valor_medicao": "100000.00",
        "numero_processo_sei": "7810.2026/0001004-8",
    }
    response = await client_unauth.post("/medicoes", json=payload)
    assert response.status_code == 401
