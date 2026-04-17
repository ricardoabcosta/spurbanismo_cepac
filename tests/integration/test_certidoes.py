"""
T20 — Testes de integração: Consulta Pública de Autenticidade (T14).

Cenários testados:
  - Certidão existente e VALIDA → autenticidade=AUTENTICA.
  - Número inexistente → 404 com autenticidade=INVALIDA.
  - GET /{numero}/proposta requer autenticação (TECNICO).
  - TECNICO pode consultar proposta de certidão existente.
"""
from __future__ import annotations

import pytest
from httpx import AsyncClient


# DV-001/2026 é inserida pela migration 004 (proposta AE-0200, Chucri Zaidan).
# O slash na URL deve ser codificado como %2F para não ser interpretado como
# separador de path. Starlette decodifica automaticamente na rota /{:path}.
_CERTIDAO_VALIDA = "DV-001%2F2026"       # URL-encoded: DV-001/2026
_CERTIDAO_INEXISTENTE = "XX-999%2F9999"  # URL-encoded: XX-999/9999


@pytest.mark.asyncio
async def test_autenticidade_certidao_valida(client_unauth: AsyncClient) -> None:
    """Certidão existente e VALIDA retorna autenticidade='CERTIDÃO AUTÊNTICA'."""
    response = await client_unauth.get(f"/certidoes/{_CERTIDAO_VALIDA}")
    assert response.status_code == 200
    data = response.json()
    assert data["autenticidade"] == "CERTIDÃO AUTÊNTICA"
    assert data["numero_certidao"] == "DV-001/2026"


@pytest.mark.asyncio
async def test_autenticidade_certidao_inexistente(client_unauth: AsyncClient) -> None:
    """Certidão inexistente retorna 404 com campo autenticidade no detalhe."""
    response = await client_unauth.get(f"/certidoes/{_CERTIDAO_INEXISTENTE}")
    assert response.status_code == 404
    detail = response.json()["detail"]
    assert "autenticidade" in detail
    assert "NÃO ENCONTRADA" in detail["autenticidade"]


@pytest.mark.asyncio
async def test_proposta_certidao_requer_autenticacao(client_unauth: AsyncClient) -> None:
    """GET /certidoes/{numero}/proposta sem token retorna 401."""
    response = await client_unauth.get(
        f"/certidoes/{_CERTIDAO_VALIDA}/proposta"
    )
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_tecnico_consulta_proposta_certidao(client_tecnico: AsyncClient) -> None:
    """TECNICO autenticado pode consultar a proposta vinculada a uma certidão."""
    response = await client_tecnico.get(
        f"/certidoes/{_CERTIDAO_VALIDA}/proposta"
    )
    assert response.status_code == 200
    data = response.json()
    # CertidaoComPropostaOut tem campo "proposta" aninhado
    assert "proposta" in data
    assert data["proposta"]["codigo"] == "AE-0200"
    assert data["proposta"]["setor"] == "Chucri Zaidan"


@pytest.mark.asyncio
async def test_listar_certidoes_publico(client_unauth: AsyncClient) -> None:
    """GET /certidoes (listagem) é público — não requer autenticação."""
    response = await client_unauth.get("/certidoes")
    assert response.status_code == 200
    data = response.json()
    # Deve retornar lista de certidões da migration 004
    assert isinstance(data, list)
    assert len(data) > 0


@pytest.mark.asyncio
async def test_listar_certidoes_com_filtro_ano(client_unauth: AsyncClient) -> None:
    """GET /certidoes?ano=2026 filtra por ano de emissão."""
    response = await client_unauth.get("/certidoes?ano=2026")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    for c in data:
        assert "2026" in c["data_emissao"]
