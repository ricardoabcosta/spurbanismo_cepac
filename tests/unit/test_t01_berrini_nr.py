"""
T01 — Berrini NR: Bloqueio Incondicional

Setor Berrini: teto NR de 175.000,00 m² já excedido (203.797,23 m² consumidos).
O motor deve bloquear QUALQUER pedido NR, independente do saldo informado.
"""
from decimal import Decimal
from uuid import uuid4

import pytest

from src.core.engine.dtos import SaldoSetorDTO, TituloDTO
from tests.conftest import make_solicitacao


@pytest.fixture
def saldo_berrini_zerado():
    """SaldoSetorDTO zerado para Berrini — NR ainda deve ser bloqueado."""
    return SaldoSetorDTO(
        setor="Berrini",
        nr_consumido_aca=Decimal("0.00"),
        nr_consumido_nuvem=Decimal("0.00"),
        nr_em_analise=Decimal("0.00"),
        r_consumido_aca=Decimal("0.00"),
        r_consumido_nuvem=Decimal("0.00"),
        r_em_analise=Decimal("0.00"),
        consumo_total_global=Decimal("0.00"),
    )


def test_berrini_nr_bloqueio_incondicional(engine, saldo_berrini_seed):
    """Pedido NR de 1 m² deve ser bloqueado — qualquer NR é vetado no Berrini."""
    solicitacao = make_solicitacao(
        setor="Berrini",
        uso="NR",
        area_m2=Decimal("1.00"),
        saldo_setor=saldo_berrini_seed,
    )
    resultado = engine.validar(solicitacao)

    assert not resultado.aprovado
    assert resultado.erro is not None
    assert resultado.erro.codigo == "TETO_NR_EXCEDIDO"


def test_berrini_nr_bloqueio_com_saldo_zerado(engine, saldo_berrini_zerado):
    """Mesmo com SaldoSetorDTO zerado, NR é bloqueado (bloqueio incondicional)."""
    solicitacao = make_solicitacao(
        setor="Berrini",
        uso="NR",
        area_m2=Decimal("1.00"),
        saldo_setor=saldo_berrini_zerado,
    )
    resultado = engine.validar(solicitacao)

    assert not resultado.aprovado
    assert resultado.erro is not None
    assert resultado.erro.codigo == "TETO_NR_EXCEDIDO"


def test_berrini_r_aprovado(engine, saldo_berrini_seed):
    """Pedido Residencial deve ser aprovado normalmente no Berrini."""
    titulo_r = TituloDTO(
        id=uuid4(),
        setor="Berrini",
        uso="R",
        origem="ACA",
        estado="DISPONIVEL",
        valor_m2=Decimal("100.00"),
    )
    solicitacao = make_solicitacao(
        setor="Berrini",
        uso="R",
        area_m2=Decimal("1000.00"),
        saldo_setor=saldo_berrini_seed,
        titulos=[titulo_r],
    )
    resultado = engine.validar(solicitacao)

    assert resultado.aprovado
    assert resultado.erro is None


def test_berrini_nr_retorna_codigo_correto(engine, saldo_berrini_seed):
    """Código de erro deve ser TETO_NR_EXCEDIDO com saldo_atual=0."""
    solicitacao = make_solicitacao(
        setor="Berrini",
        uso="NR",
        area_m2=Decimal("500.00"),
        saldo_setor=saldo_berrini_seed,
    )
    resultado = engine.validar(solicitacao)

    assert not resultado.aprovado
    assert resultado.erro.codigo == "TETO_NR_EXCEDIDO"
    assert resultado.erro.saldo_atual == Decimal("0")
    assert resultado.erro.setor == "Berrini"
