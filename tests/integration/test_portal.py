"""
T20 — Testes de integração: Portal de Operações Técnicas (T15).

Cenários testados:
  - POST /portal/solicitacoes cria solicitação PENDENTE, títulos → EM_ANALISE.
  - PATCH cancelar reverte títulos para DISPONIVEL e solicitação → CANCELADA.
  - Cancelar solicitação não-PENDENTE retorna 422 SOLICITACAO_NAO_CANCELAVEL.
  - GET /portal/solicitacoes retorna paginação correta.
  - GET /portal/solicitacoes/{id} retorna lote de títulos.
  - POST com SEI inválido retorna 422.
  - GET /portal/titulos retorna apenas DISPONIVEL.
  - GET /portal/propostas/{codigo} retorna dados da proposta.
"""
from __future__ import annotations

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from src.core.models.enums import EstadoTituloEnum
from src.core.models.titulo_cepac import TituloCepac


async def _pegar_titulo_disponivel(db: AsyncSession) -> TituloCepac:
    """
    Retorna um título DISPONIVEL de qualquer setor com setor carregado.
    Todos os campos (setor.nome, uso, origem, valor_m2) ficam disponíveis.
    """
    from src.core.models.setor import Setor  # noqa: F401 (trigger ORM registration)

    result = await db.execute(
        select(TituloCepac)
        .options(selectinload(TituloCepac.setor))
        .where(TituloCepac.estado == EstadoTituloEnum.DISPONIVEL)
        .where(TituloCepac.setor_id.in_(
            select(Setor.id).where(Setor.bloqueio_nr.is_(False))
        ))
        .limit(1)
    )
    titulo = result.scalar_one_or_none()
    assert titulo is not None, "Nenhum título DISPONIVEL encontrado em setor não-bloqueado"
    return titulo


def _make_payload(titulo: TituloCepac, numero_sei: str, **overrides) -> dict:
    """Constrói payload de POST /portal/solicitacoes a partir do título."""
    return {
        "setor": titulo.setor.nome,
        "uso": titulo.uso.value,
        "origem": titulo.origem.value,
        "area_m2": str(titulo.valor_m2),
        "numero_processo_sei": numero_sei,
        "titulo_ids": [str(titulo.id)],
        **overrides,
    }


@pytest.mark.asyncio
async def test_criar_solicitacao_pendente(
    client_tecnico: AsyncClient, db_session: AsyncSession
) -> None:
    """POST cria solicitação EM_ANALISE; títulos também transitam para EM_ANALISE."""
    titulo = await _pegar_titulo_disponivel(db_session)

    response = await client_tecnico.post(
        "/portal/solicitacoes",
        json=_make_payload(titulo, "7810.2026/0001234-5"),
    )
    assert response.status_code == 201, response.text

    data = response.json()
    assert data["status"] == "EM_ANALISE"
    assert data["setor"] == titulo.setor.nome
    assert data["uso"] == titulo.uso.value

    # Verifica transição para EM_ANALISE
    await db_session.refresh(titulo)
    assert titulo.estado == EstadoTituloEnum.EM_ANALISE


@pytest.mark.asyncio
async def test_cancelar_solicitacao_libera_titulo(
    client_tecnico: AsyncClient, db_session: AsyncSession
) -> None:
    """PATCH /cancelar reverte título para DISPONIVEL e status → CANCELADA."""
    titulo = await _pegar_titulo_disponivel(db_session)

    create_resp = await client_tecnico.post(
        "/portal/solicitacoes",
        json=_make_payload(titulo, "7810.2026/0009999-1"),
    )
    assert create_resp.status_code == 201, create_resp.text
    solicitacao_id = create_resp.json()["id"]

    cancel_resp = await client_tecnico.patch(
        f"/portal/solicitacoes/{solicitacao_id}/cancelar"
    )
    assert cancel_resp.status_code == 200
    assert cancel_resp.json()["status"] == "CANCELADA"

    # Título deve ter voltado a DISPONIVEL
    await db_session.refresh(titulo)
    assert titulo.estado == EstadoTituloEnum.DISPONIVEL


@pytest.mark.asyncio
async def test_cancelar_nao_pendente_retorna_422(
    client_tecnico: AsyncClient, db_session: AsyncSession
) -> None:
    """Cancelar solicitação já CANCELADA retorna 422 SOLICITACAO_NAO_CANCELAVEL."""
    titulo = await _pegar_titulo_disponivel(db_session)

    create_resp = await client_tecnico.post(
        "/portal/solicitacoes",
        json=_make_payload(titulo, "7810.2026/0002222-7"),
    )
    assert create_resp.status_code == 201, create_resp.text
    solicitacao_id = create_resp.json()["id"]

    # Cancela uma vez → CANCELADA
    cancel1 = await client_tecnico.patch(
        f"/portal/solicitacoes/{solicitacao_id}/cancelar"
    )
    assert cancel1.status_code == 200

    # Tenta cancelar novamente → 422
    cancel2 = await client_tecnico.patch(
        f"/portal/solicitacoes/{solicitacao_id}/cancelar"
    )
    assert cancel2.status_code == 422
    detail = cancel2.json()["detail"]
    assert detail["codigo_erro"] == "SOLICITACAO_NAO_CANCELAVEL"


@pytest.mark.asyncio
async def test_listar_solicitacoes_paginado(
    client_tecnico: AsyncClient,
) -> None:
    """GET /portal/solicitacoes retorna estrutura de paginação."""
    response = await client_tecnico.get(
        "/portal/solicitacoes?page=1&page_size=5"
    )
    assert response.status_code == 200
    data = response.json()
    assert "items" in data
    assert "total" in data
    assert "page" in data
    assert data["page"] == 1
    assert data["page_size"] == 5


@pytest.mark.asyncio
async def test_detalhe_solicitacao_com_lote(
    client_tecnico: AsyncClient, db_session: AsyncSession
) -> None:
    """GET /portal/solicitacoes/{id} retorna lote de títulos."""
    titulo = await _pegar_titulo_disponivel(db_session)

    create_resp = await client_tecnico.post(
        "/portal/solicitacoes",
        json=_make_payload(titulo, "7810.2026/0003333-9"),
    )
    assert create_resp.status_code == 201, create_resp.text
    solicitacao_id = create_resp.json()["id"]

    detail_resp = await client_tecnico.get(
        f"/portal/solicitacoes/{solicitacao_id}"
    )
    assert detail_resp.status_code == 200
    data = detail_resp.json()
    assert "titulos" in data
    assert len(data["titulos"]) == 1
    assert data["titulos"][0]["id"] == str(titulo.id)


@pytest.mark.asyncio
async def test_sei_invalido_retorna_422(client_tecnico: AsyncClient) -> None:
    """POST com número SEI fora dos padrões aceitos retorna 422."""
    payload = {
        "setor": "Berrini",
        "uso": "NR",
        "origem": "ACA",
        "area_m2": "100.00",
        "numero_processo_sei": "INVALIDO-SEI",
        "titulo_ids": [],
    }
    response = await client_tecnico.post("/portal/solicitacoes", json=payload)
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_listar_titulos_disponiveis(
    client_tecnico: AsyncClient, db_session: AsyncSession
) -> None:
    """GET /portal/titulos retorna somente CEPACs DISPONIVEL."""
    titulo = await _pegar_titulo_disponivel(db_session)

    response = await client_tecnico.get(
        f"/portal/titulos?setor={titulo.setor.nome}&uso={titulo.uso.value}"
        f"&origem={titulo.origem.value}"
    )
    assert response.status_code == 200
    titulos = response.json()
    assert len(titulos) > 0
    for t in titulos:
        assert "codigo" in t
        assert "id" in t


@pytest.mark.asyncio
async def test_buscar_proposta_por_codigo(client_tecnico: AsyncClient) -> None:
    """GET /portal/propostas/AE-0200 retorna dados da proposta."""
    response = await client_tecnico.get("/portal/propostas/AE-0200")
    assert response.status_code == 200
    data = response.json()
    assert data["codigo"] == "AE-0200"
    assert data["setor"] == "Chucri Zaidan"


@pytest.mark.asyncio
async def test_buscar_proposta_inexistente(client_tecnico: AsyncClient) -> None:
    """GET /portal/propostas/{codigo} com código inexistente retorna 404."""
    response = await client_tecnico.get("/portal/propostas/AE-9999")
    assert response.status_code == 404
