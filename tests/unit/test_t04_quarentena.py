"""
T04 — Quarentena 90 dias e disponibilidade de títulos

Regras:
- Títulos em QUARENTENA com < 180 dias de desvinculação → QUARENTENA_ATIVA
- Títulos em QUARENTENA com >= 180 dias → quarentena cumprida, aprovado
- Títulos em EM_ANALISE ou CONSUMIDO → TITULO_INDISPONIVEL
- Título em QUARENTENA sem data_desvinculacao → QUARENTENA_ATIVA (inconsistência)
"""
from datetime import datetime, timedelta, timezone
from decimal import Decimal
from uuid import uuid4

import pytest

from src.core.engine.dtos import SaldoSetorDTO, SolicitacaoDTO, TituloDTO


@pytest.fixture
def saldo_brooklin_seed():
    return SaldoSetorDTO(
        setor="Brooklin",
        nr_consumido_aca=Decimal("716470.01"),
        nr_consumido_nuvem=Decimal("0.00"),
        nr_em_analise=Decimal("0.00"),
        r_consumido_aca=Decimal("0.00"),
        r_consumido_nuvem=Decimal("0.00"),
        r_em_analise=Decimal("0.00"),
        consumo_total_global=Decimal("716470.01"),
    )


def _solicitacao_com_titulo(titulo: TituloDTO, saldo: SaldoSetorDTO, uso: str = "NR") -> SolicitacaoDTO:
    """Cria SolicitacaoDTO com um único título fornecido."""
    return SolicitacaoDTO(
        setor=titulo.setor,
        uso=uso,
        origem=titulo.origem,
        area_m2=Decimal("1000.00"),
        numero_processo_sei="6016.2026/0001234-5",
        titulo_ids=[titulo.id],
        titulos=[titulo],
        saldo_setor=saldo,
    )


def test_quarentena_90_dias_bloqueado(engine, saldo_brooklin_seed):
    """
    Título desvinculado há 90 dias → QUARENTENA_ATIVA com dias_restantes=90.

    DIAS_QUARENTENA = 180; dias_em_quarentena = 90 → dias_restantes = 180 - 90 = 90.
    """
    data_desvinc = datetime.now(timezone.utc) - timedelta(days=90)
    titulo = TituloDTO(
        id=uuid4(),
        setor="Brooklin",
        uso="NR",
        origem="ACA",
        estado="QUARENTENA",
        valor_m2=Decimal("100.00"),
        data_desvinculacao=data_desvinc,
    )
    solicitacao = _solicitacao_com_titulo(titulo, saldo_brooklin_seed)
    resultado = engine.validar(solicitacao)

    assert not resultado.aprovado
    assert resultado.erro.codigo == "QUARENTENA_ATIVA"
    assert resultado.erro.dias_restantes == 90


def test_quarentena_181_dias_aprovado(engine, saldo_brooklin_seed):
    """Título desvinculado há 181 dias → quarentena cumprida, deve ser aprovado."""
    data_desvinc = datetime.now(timezone.utc) - timedelta(days=181)
    titulo = TituloDTO(
        id=uuid4(),
        setor="Brooklin",
        uso="NR",
        origem="ACA",
        estado="QUARENTENA",
        valor_m2=Decimal("100.00"),
        data_desvinculacao=data_desvinc,
    )
    solicitacao = _solicitacao_com_titulo(titulo, saldo_brooklin_seed)
    resultado = engine.validar(solicitacao)

    assert resultado.aprovado, (
        f"Quarentena de 181 dias deveria ser aprovada, mas bloqueada: {resultado.erro}"
    )


def test_quarentena_179_dias_bloqueado(engine, saldo_brooklin_seed):
    """Título desvinculado há 179 dias → ainda em quarentena (falta 1 dia)."""
    data_desvinc = datetime.now(timezone.utc) - timedelta(days=179)
    titulo = TituloDTO(
        id=uuid4(),
        setor="Brooklin",
        uso="NR",
        origem="ACA",
        estado="QUARENTENA",
        valor_m2=Decimal("100.00"),
        data_desvinculacao=data_desvinc,
    )
    solicitacao = _solicitacao_com_titulo(titulo, saldo_brooklin_seed)
    resultado = engine.validar(solicitacao)

    assert not resultado.aprovado
    assert resultado.erro.codigo == "QUARENTENA_ATIVA"
    assert resultado.erro.dias_restantes == 1


def test_quarentena_exatamente_180_dias_aprovado(engine, saldo_brooklin_seed):
    """
    Título desvinculado há exatamente 180 dias → quarentena cumprida.

    (agora - data).days == 180 >= DIAS_QUARENTENA=180 → aprovado.
    """
    data_desvinc = datetime.now(timezone.utc) - timedelta(days=180)
    titulo = TituloDTO(
        id=uuid4(),
        setor="Brooklin",
        uso="NR",
        origem="ACA",
        estado="QUARENTENA",
        valor_m2=Decimal("100.00"),
        data_desvinculacao=data_desvinc,
    )
    solicitacao = _solicitacao_com_titulo(titulo, saldo_brooklin_seed)
    resultado = engine.validar(solicitacao)

    assert resultado.aprovado, (
        f"Quarentena exata de 180 dias deve ser aprovada, mas bloqueada: {resultado.erro}"
    )


def test_quarentena_sem_data_desvinculacao(engine, saldo_brooklin_seed):
    """Título em QUARENTENA sem data_desvinculacao → erro de inconsistência QUARENTENA_ATIVA."""
    titulo = TituloDTO(
        id=uuid4(),
        setor="Brooklin",
        uso="NR",
        origem="ACA",
        estado="QUARENTENA",
        valor_m2=Decimal("100.00"),
        data_desvinculacao=None,
    )
    solicitacao = _solicitacao_com_titulo(titulo, saldo_brooklin_seed)
    resultado = engine.validar(solicitacao)

    assert not resultado.aprovado
    assert resultado.erro.codigo == "QUARENTENA_ATIVA"
    # Sem data, dias_restantes não deve ser definido (inconsistência de dados)
    assert resultado.erro.dias_restantes is None


def test_titulo_em_analise_bloqueado(engine, saldo_brooklin_seed):
    """Título em EM_ANALISE → TITULO_INDISPONIVEL."""
    titulo = TituloDTO(
        id=uuid4(),
        setor="Brooklin",
        uso="NR",
        origem="ACA",
        estado="EM_ANALISE",
        valor_m2=Decimal("100.00"),
    )
    solicitacao = _solicitacao_com_titulo(titulo, saldo_brooklin_seed)
    resultado = engine.validar(solicitacao)

    assert not resultado.aprovado
    assert resultado.erro.codigo == "TITULO_INDISPONIVEL"


def test_titulo_consumido_bloqueado(engine, saldo_brooklin_seed):
    """Título em CONSUMIDO → TITULO_INDISPONIVEL."""
    titulo = TituloDTO(
        id=uuid4(),
        setor="Brooklin",
        uso="NR",
        origem="ACA",
        estado="CONSUMIDO",
        valor_m2=Decimal("100.00"),
    )
    solicitacao = _solicitacao_com_titulo(titulo, saldo_brooklin_seed)
    resultado = engine.validar(solicitacao)

    assert not resultado.aprovado
    assert resultado.erro.codigo == "TITULO_INDISPONIVEL"


def test_quarentena_primeiro_titulo_bloqueado_para_lote(engine, saldo_brooklin_seed):
    """
    Lote misto: primeiro título disponível, segundo em quarentena recente.
    O validator deve retornar no primeiro título inválido (segundo neste caso).
    """
    titulo_ok = TituloDTO(
        id=uuid4(),
        setor="Brooklin",
        uso="NR",
        origem="ACA",
        estado="DISPONIVEL",
        valor_m2=Decimal("100.00"),
    )
    data_desvinc = datetime.now(timezone.utc) - timedelta(days=30)
    titulo_quarentena = TituloDTO(
        id=uuid4(),
        setor="Brooklin",
        uso="NR",
        origem="ACA",
        estado="QUARENTENA",
        valor_m2=Decimal("100.00"),
        data_desvinculacao=data_desvinc,
    )
    solicitacao = SolicitacaoDTO(
        setor="Brooklin",
        uso="NR",
        origem="ACA",
        area_m2=Decimal("2000.00"),
        numero_processo_sei="6016.2026/0001234-5",
        titulo_ids=[titulo_ok.id, titulo_quarentena.id],
        titulos=[titulo_ok, titulo_quarentena],
        saldo_setor=saldo_brooklin_seed,
    )
    resultado = engine.validar(solicitacao)

    assert not resultado.aprovado
    assert resultado.erro.codigo == "QUARENTENA_ATIVA"
    assert resultado.erro.dias_restantes == 150  # 180 - 30
