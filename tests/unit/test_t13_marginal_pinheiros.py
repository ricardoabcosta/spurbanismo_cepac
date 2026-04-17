"""
T13 — Marginal Pinheiros: piso R (30%) + teto NR (420.000 m²)

Dados reais da planilha (posição 13/04/2026):
  ACA_R=198.945,31  ACA_NR=258.908,19  NUVEM_R=1.301,13  NUVEM_NR=0
  EM_ANALISE_R=59.398,03  EM_ANALISE_NR=11.173,06
  R comprometido total ≈ 259.644,47 m² (43,7% do total) → piso R já atingido
"""
from decimal import Decimal

import pytest

from src.core.engine.dtos import SaldoSetorDTO
from tests.conftest import make_solicitacao


@pytest.fixture
def saldo_marginal_pinheiros_seed():
    """Saldo Marginal Pinheiros conforme planilha 13/04/2026."""
    return SaldoSetorDTO(
        setor="Marginal Pinheiros",
        nr_consumido_aca=Decimal("258908.19"),
        nr_consumido_nuvem=Decimal("0.00"),
        nr_em_analise=Decimal("11173.06"),
        r_consumido_aca=Decimal("198945.31"),
        r_consumido_nuvem=Decimal("1301.13"),
        r_em_analise=Decimal("59398.03"),
        consumo_total_global=Decimal("529725.72"),
    )


@pytest.fixture
def saldo_marginal_piso_r_nao_atingido():
    """Saldo hipotético onde R ainda não atingiu 30% do total."""
    return SaldoSetorDTO(
        setor="Marginal Pinheiros",
        nr_consumido_aca=Decimal("200000.00"),
        nr_consumido_nuvem=Decimal("0.00"),
        nr_em_analise=Decimal("0.00"),
        r_consumido_aca=Decimal("50000.00"),  # 50k R / 250k total = 20% < 30%
        r_consumido_nuvem=Decimal("0.00"),
        r_em_analise=Decimal("0.00"),
        consumo_total_global=Decimal("250000.00"),
    )


# ---------------------------------------------------------------------------
# Casos com saldo real (piso R já atingido)
# ---------------------------------------------------------------------------

def test_nr_aprovado_abaixo_do_teto(engine, saldo_marginal_pinheiros_seed):
    """NR aprovado quando total projetado fica abaixo de 420.000 m²."""
    solicitacao = make_solicitacao(
        setor="Marginal Pinheiros",
        uso="NR",
        area_m2=Decimal("100000.00"),  # 258.908 + 11.173 + 100.000 = 370.081 < 420.000
        saldo_setor=saldo_marginal_pinheiros_seed,
    )
    resultado = engine.validar(solicitacao)
    assert resultado.aprovado
    assert resultado.erro is None


def test_nr_bloqueado_acima_do_teto(engine, saldo_marginal_pinheiros_seed):
    """NR bloqueado quando ultrapassa teto NR de 420.000 m²."""
    solicitacao = make_solicitacao(
        setor="Marginal Pinheiros",
        uso="NR",
        area_m2=Decimal("200000.00"),  # 258.908 + 11.173 + 200.000 = 470.081 > 420.000
        saldo_setor=saldo_marginal_pinheiros_seed,
    )
    resultado = engine.validar(solicitacao)
    assert not resultado.aprovado
    assert resultado.erro.codigo == "TETO_NR_EXCEDIDO"
    assert resultado.erro.setor == "Marginal Pinheiros"


def test_r_sempre_aprovado(engine, saldo_marginal_pinheiros_seed):
    """Solicitações R passam direto sem nenhuma restrição do setor."""
    solicitacao = make_solicitacao(
        setor="Marginal Pinheiros",
        uso="R",
        area_m2=Decimal("50000.00"),
        saldo_setor=saldo_marginal_pinheiros_seed,
    )
    resultado = engine.validar(solicitacao)
    assert resultado.aprovado
    assert resultado.erro is None


def test_nr_exatamente_no_teto_aprovado(engine, saldo_marginal_pinheiros_seed):
    """NR exatamente igual ao teto deve ser aprovado (limite inclusivo)."""
    nr_comprometido = Decimal("258908.19") + Decimal("11173.06")  # 270.081,25
    area_exata = Decimal("420000.00") - nr_comprometido            # 149.918,75
    solicitacao = make_solicitacao(
        setor="Marginal Pinheiros",
        uso="NR",
        area_m2=area_exata,
        saldo_setor=saldo_marginal_pinheiros_seed,
    )
    resultado = engine.validar(solicitacao)
    assert resultado.aprovado


# ---------------------------------------------------------------------------
# Casos com piso R não atingido
# ---------------------------------------------------------------------------

def test_nr_bloqueado_por_piso_r(engine, saldo_marginal_piso_r_nao_atingido):
    """NR bloqueado quando piso R (30%) ainda não foi atingido."""
    solicitacao = make_solicitacao(
        setor="Marginal Pinheiros",
        uso="NR",
        area_m2=Decimal("10000.00"),
        saldo_setor=saldo_marginal_piso_r_nao_atingido,
    )
    resultado = engine.validar(solicitacao)
    assert not resultado.aprovado
    assert resultado.erro.codigo == "PISO_R_NAO_ATINGIDO"
    assert resultado.erro.setor == "Marginal Pinheiros"
    assert resultado.erro.saldo_atual == Decimal("50000.00")


def test_r_aprovado_com_piso_nao_atingido(engine, saldo_marginal_piso_r_nao_atingido):
    """Solicitações R são aprovadas mesmo quando o piso ainda não foi atingido."""
    solicitacao = make_solicitacao(
        setor="Marginal Pinheiros",
        uso="R",
        area_m2=Decimal("10000.00"),
        saldo_setor=saldo_marginal_piso_r_nao_atingido,
    )
    resultado = engine.validar(solicitacao)
    assert resultado.aprovado
