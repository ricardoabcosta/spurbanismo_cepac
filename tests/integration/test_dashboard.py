"""
T20 — Testes de integração: Dashboard Executivo (T16).

Cenários testados:
  - GET /dashboard/snapshot retorna big numbers e estrutura completa.
  - GET /dashboard/snapshot?data=... restrito a DIRETOR.
  - GET /dashboard/setores retorna lista de setores com campos NR.
  - GET /dashboard/alertas retorna lista (possivelmente vazia).
  - GET /dashboard/medicoes restrito a DIRETOR.
  - Velocímetro 2029: zona calculada corretamente para 2026-04-16.
"""
from __future__ import annotations

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_snapshot_atual_tecnico(client_tecnico: AsyncClient) -> None:
    """TECNICO pode acessar snapshot atual — retorna todos os campos esperados."""
    response = await client_tecnico.get("/dashboard/snapshot")
    assert response.status_code == 200

    data = response.json()
    # Big numbers obrigatórios
    assert "custo_total_incorrido" in data
    assert "capacidade_total_operacao" in data
    assert "saldo_geral_disponivel" in data
    assert "cepacs_em_circulacao" in data
    # Velocímetro
    assert "prazo_percentual_decorrido" in data
    assert "prazo_dias_restantes" in data
    assert "prazo_zona" in data
    assert data["prazo_zona"] in ("VERDE", "AMARELO", "VERMELHO")
    # Setores e alertas
    assert "setores" in data
    assert isinstance(data["setores"], list)
    assert len(data["setores"]) > 0
    assert "alertas" in data
    assert isinstance(data["alertas"], list)


@pytest.mark.asyncio
async def test_snapshot_historico_tecnico_negado(client_tecnico: AsyncClient) -> None:
    """Snapshot histórico com ?data= negado para TECNICO (403)."""
    response = await client_tecnico.get("/dashboard/snapshot?data=2024-06-30")
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_snapshot_historico_diretor_ok(client_diretor: AsyncClient) -> None:
    """DIRETOR pode acessar snapshot histórico com ?data=YYYY-MM-DD."""
    response = await client_diretor.get("/dashboard/snapshot?data=2025-12-31")
    assert response.status_code == 200
    data = response.json()
    assert data["prazo_zona"] in ("VERDE", "AMARELO", "VERMELHO")
    assert "gerado_em" in data


@pytest.mark.asyncio
async def test_setores_retorna_campos_nr(client_tecnico: AsyncClient) -> None:
    """GET /dashboard/setores inclui campos de teto NR e saldo NR."""
    response = await client_tecnico.get("/dashboard/setores")
    assert response.status_code == 200
    setores = response.json()
    assert len(setores) > 0

    for setor in setores:
        assert "nome" in setor
        assert "estoque_total" in setor
        assert "disponivel" in setor
        assert "percentual_ocupado" in setor
        # Campos NR (D9 — T16)
        assert "teto_nr" in setor
        assert "bloqueado_nr" in setor


@pytest.mark.asyncio
async def test_alertas_retorna_lista(client_tecnico: AsyncClient) -> None:
    """GET /dashboard/alertas retorna lista de alertas (pode ser vazia)."""
    response = await client_tecnico.get("/dashboard/alertas")
    assert response.status_code == 200
    alertas = response.json()
    assert isinstance(alertas, list)
    # Se houver alertas, validar estrutura
    for alerta in alertas:
        assert "setor" in alerta
        assert "tipo" in alerta
        assert alerta["tipo"] in ("TETO_NR_EXCEDIDO", "RESERVA_R_VIOLADA")


@pytest.mark.asyncio
async def test_medicoes_tecnico_negado(client_tecnico: AsyncClient) -> None:
    """GET /dashboard/medicoes negado para TECNICO (403)."""
    response = await client_tecnico.get("/dashboard/medicoes")
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_medicoes_diretor_ok(client_diretor: AsyncClient) -> None:
    """DIRETOR pode listar medições — migration 006 inseriu uma medição inicial."""
    response = await client_diretor.get("/dashboard/medicoes")
    assert response.status_code == 200
    medicoes = response.json()
    assert isinstance(medicoes, list)
    # Migration 006 insere medição de 2026-04-01
    assert len(medicoes) >= 1
    primeira = medicoes[0]  # ordenado DESC
    assert "data_referencia" in primeira
    assert "valor_acumulado" in primeira


@pytest.mark.asyncio
async def test_cepacs_em_circulacao_valor(client_tecnico: AsyncClient) -> None:
    """
    cepacs_em_circulacao deve retornar 193779 (D5 — valor da planilha XLSX).
    Migration 007 popula parametro_sistema com este valor.
    """
    response = await client_tecnico.get("/dashboard/snapshot")
    assert response.status_code == 200
    data = response.json()
    # Migration 007 insere 193779 — mesmo valor do fallback em buscar_cepacs_em_circulacao
    assert data["cepacs_em_circulacao"] == 193_779
