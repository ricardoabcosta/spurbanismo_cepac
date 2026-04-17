"""
T02 — Chucri Zaidan: Reserva Residencial

Setor Chucri Zaidan:
- Estoque total: 2.000.000,00 m²
- Reserva R obrigatória (Lei 16.975/2018): 216.442,47 m²
- Teto NR: 1.783.557,53 m²
- Fórmula: BLOQUEIA se (R_total + R_em_analise + NR_comprometido) + area_m2 > 1.783.557,53
- Seed atual: R_total=752.113,79; NR_comprometido=1.051.316,21; Em_Analise=14.006,35 R
- Saldo NR disponível: 1.783.557,53 - 1.817.436,35 = -33.878,82 (negativo — qualquer NR bloqueado)

Nota: o saldo disponível no seed já é negativo. Para testar aprovação e bloqueio na borda,
os testes abaixo usam um SaldoSetorDTO com consumo total em 1.601.994,35,
resultando em exatamente 181.563,18 de saldo NR, permitindo testar o comportamento
na fronteira com pedidos de 181.563,18 (aprovado) e 181.563,19 (bloqueado).

Para manter consistência com o enunciado (saldo = 182.563,65), foi construído
um saldo setorial ligeiramente diferente conforme descrito nos comentários de cada teste.
"""
from decimal import Decimal
from uuid import uuid4

import pytest

from src.core.engine.dtos import SaldoSetorDTO, TituloDTO
from tests.conftest import make_solicitacao

# Teto NR de Chucri Zaidan = 2.000.000 - 216.442,47
TETO_NR_CHUCRI = Decimal("1783557.53")


@pytest.fixture
def saldo_chucri_borda():
    """
    Saldo construído para ter exatamente 182.563,65 m² de saldo NR disponível.

    consumo_total = r_total + r_em_analise + nr_comprometido
    Para saldo = 182.563,65:
        consumo_total = 1.783.557,53 - 182.563,65 = 1.600.993,88

    Distribuição escolhida:
        r_consumido_aca = 500.000,00
        r_consumido_nuvem = 0,00
        r_em_analise = 50.000,00
        nr_consumido_aca = 1.050.993,88
        nr_consumido_nuvem = 0,00
        nr_em_analise = 0,00
        consumo_total_global = 1.600.993,88
    """
    return SaldoSetorDTO(
        setor="Chucri Zaidan",
        nr_consumido_aca=Decimal("1050993.88"),
        nr_consumido_nuvem=Decimal("0.00"),
        nr_em_analise=Decimal("0.00"),
        r_consumido_aca=Decimal("500000.00"),
        r_consumido_nuvem=Decimal("0.00"),
        r_em_analise=Decimal("50000.00"),
        consumo_total_global=Decimal("1600993.88"),
    )


def test_chucri_zaidan_nr_dentro_limite_aprovado(engine, saldo_chucri_borda):
    """
    Pedido NR de 182.563,65 m² (exatamente no limite) deve ser aprovado.

    consumo_total + area = 1.600.993,88 + 182.563,65 = 1.783.557,53 = TETO_NR → aprovado (<=)
    """
    titulo_nr = TituloDTO(
        id=uuid4(),
        setor="Chucri Zaidan",
        uso="NR",
        origem="ACA",
        estado="DISPONIVEL",
        valor_m2=Decimal("100.00"),
    )
    solicitacao = make_solicitacao(
        setor="Chucri Zaidan",
        uso="NR",
        area_m2=Decimal("182563.65"),
        saldo_setor=saldo_chucri_borda,
        titulos=[titulo_nr],
    )
    resultado = engine.validar(solicitacao)

    assert resultado.aprovado, (
        f"Esperado aprovado, mas bloqueado com: {resultado.erro}"
    )


def test_chucri_zaidan_nr_acima_limite_bloqueado(engine, saldo_chucri_borda):
    """
    Pedido NR de 182.563,66 m² (1 centésimo acima) deve ser bloqueado com RESERVA_R_VIOLADA.

    consumo_total + area = 1.600.993,88 + 182.563,66 = 1.783.557,54 > 1.783.557,53 → bloqueado
    """
    titulo_nr = TituloDTO(
        id=uuid4(),
        setor="Chucri Zaidan",
        uso="NR",
        origem="ACA",
        estado="DISPONIVEL",
        valor_m2=Decimal("100.00"),
    )
    solicitacao = make_solicitacao(
        setor="Chucri Zaidan",
        uso="NR",
        area_m2=Decimal("182563.66"),
        saldo_setor=saldo_chucri_borda,
        titulos=[titulo_nr],
    )
    resultado = engine.validar(solicitacao)

    assert not resultado.aprovado
    assert resultado.erro.codigo == "RESERVA_R_VIOLADA"


def test_chucri_zaidan_r_aprovado_sem_restricao(engine, saldo_chucri_zaidan_seed):
    """Pedido R deve ser aprovado (não sofre restrição de teto NR)."""
    titulo_r = TituloDTO(
        id=uuid4(),
        setor="Chucri Zaidan",
        uso="R",
        origem="ACA",
        estado="DISPONIVEL",
        valor_m2=Decimal("100.00"),
    )
    solicitacao = make_solicitacao(
        setor="Chucri Zaidan",
        uso="R",
        area_m2=Decimal("10000.00"),
        saldo_setor=saldo_chucri_zaidan_seed,
        titulos=[titulo_r],
    )
    resultado = engine.validar(solicitacao)

    assert resultado.aprovado, (
        f"Pedido R deveria ser aprovado, mas bloqueado com: {resultado.erro}"
    )


def test_chucri_zaidan_formula_usa_consumo_total(engine):
    """
    Validator usa R_total + R_em_analise + NR_comprometido, não só NR.

    Monte SaldoSetorDTO com R elevado e NR baixo — mesmo com pouco NR,
    o R consumido já consome quase todo o orçamento disponível.

    Configuração:
        r_consumido_aca = 1.300.000,00   (R elevado)
        r_em_analise    =   100.000,00
        nr_comprometido =   300.000,00   (NR baixo)
        consumo_total   = 1.700.000,00
        saldo_nr        = 1.783.557,53 - 1.700.000,00 = 83.557,53

    Pedido NR de 83.557,54 deve ser bloqueado (total: 1.783.557,54 > teto).
    Pedido NR de 83.557,53 deve ser aprovado (total: 1.783.557,53 = teto).
    """
    saldo_r_elevado = SaldoSetorDTO(
        setor="Chucri Zaidan",
        nr_consumido_aca=Decimal("300000.00"),
        nr_consumido_nuvem=Decimal("0.00"),
        nr_em_analise=Decimal("0.00"),
        r_consumido_aca=Decimal("1300000.00"),
        r_consumido_nuvem=Decimal("0.00"),
        r_em_analise=Decimal("100000.00"),
        consumo_total_global=Decimal("1700000.00"),
    )
    titulo_nr = TituloDTO(
        id=uuid4(),
        setor="Chucri Zaidan",
        uso="NR",
        origem="ACA",
        estado="DISPONIVEL",
        valor_m2=Decimal("100.00"),
    )

    # Pedido que ultrapassa o teto quando somado ao R consumido
    solicitacao_bloqueada = make_solicitacao(
        setor="Chucri Zaidan",
        uso="NR",
        area_m2=Decimal("83557.54"),
        saldo_setor=saldo_r_elevado,
        titulos=[titulo_nr],
    )
    resultado_bloqueado = engine.validar(solicitacao_bloqueada)
    assert not resultado_bloqueado.aprovado
    assert resultado_bloqueado.erro.codigo == "RESERVA_R_VIOLADA"

    # Pedido exatamente no limite deve ser aprovado
    titulo_nr2 = TituloDTO(
        id=uuid4(),
        setor="Chucri Zaidan",
        uso="NR",
        origem="ACA",
        estado="DISPONIVEL",
        valor_m2=Decimal("100.00"),
    )
    solicitacao_aprovada = make_solicitacao(
        setor="Chucri Zaidan",
        uso="NR",
        area_m2=Decimal("83557.53"),
        saldo_setor=saldo_r_elevado,
        titulos=[titulo_nr2],
    )
    resultado_aprovado = engine.validar(solicitacao_aprovada)
    assert resultado_aprovado.aprovado, (
        f"Pedido exato no limite deveria ser aprovado, mas bloqueado com: {resultado_aprovado.erro}"
    )
