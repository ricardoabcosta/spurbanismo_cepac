"""
T03 — Fórmula de Saldo

Valida as propriedades SaldoSetorDTO.nr_total_comprometido e r_total_consumido.
Saldo Disponível = Teto - (Consumido_ACA + Consumido_NUVEM + Em_Análise)
"""
from decimal import Decimal

from src.core.engine.dtos import SaldoSetorDTO


def test_saldo_nr_total_comprometido():
    """nr_total_comprometido = nr_consumido_aca + nr_consumido_nuvem + nr_em_analise"""
    saldo = SaldoSetorDTO(
        setor="Brooklin",
        nr_consumido_aca=Decimal("400000.00"),
        nr_consumido_nuvem=Decimal("50000.00"),
        nr_em_analise=Decimal("100000.00"),
        r_consumido_aca=Decimal("0"),
        r_consumido_nuvem=Decimal("0"),
        r_em_analise=Decimal("0"),
        consumo_total_global=Decimal("550000.00"),
    )
    assert saldo.nr_total_comprometido == Decimal("550000.00")


def test_saldo_r_total_consumido():
    """r_total_consumido = r_consumido_aca + r_consumido_nuvem (sem em_analise)"""
    saldo = SaldoSetorDTO(
        setor="Chucri Zaidan",
        nr_consumido_aca=Decimal("0"),
        nr_consumido_nuvem=Decimal("0"),
        nr_em_analise=Decimal("0"),
        r_consumido_aca=Decimal("300000.00"),
        r_consumido_nuvem=Decimal("50000.00"),
        r_em_analise=Decimal("25000.00"),  # em_analise NÃO entra no r_total_consumido
        consumo_total_global=Decimal("375000.00"),
    )
    # r_total_consumido deve excluir r_em_analise
    assert saldo.r_total_consumido == Decimal("350000.00")
    # r_em_analise deve ser acessado separadamente
    assert saldo.r_em_analise == Decimal("25000.00")


def test_saldo_disponivel_brooklin_seed():
    """Com valores do seed (716.470,01 ACA), saldo NR deve ser 263.529,99."""
    saldo = SaldoSetorDTO(
        setor="Brooklin",
        nr_consumido_aca=Decimal("716470.01"),
        nr_consumido_nuvem=Decimal("0.00"),
        nr_em_analise=Decimal("0.00"),
        r_consumido_aca=Decimal("0"),
        r_consumido_nuvem=Decimal("0"),
        r_em_analise=Decimal("0"),
        consumo_total_global=Decimal("716470.01"),
    )
    saldo_disponivel = Decimal("980000.00") - saldo.nr_total_comprometido
    assert saldo_disponivel == Decimal("263529.99")


def test_saldo_marginal_pinheiros_seed():
    """Seed: ACA=258.908,19 + em_analise=11.173,06 → saldo 149.918,75."""
    saldo = SaldoSetorDTO(
        setor="Marginal Pinheiros",
        nr_consumido_aca=Decimal("258908.19"),
        nr_consumido_nuvem=Decimal("0.00"),
        nr_em_analise=Decimal("11173.06"),
        r_consumido_aca=Decimal("0"),
        r_consumido_nuvem=Decimal("1301.13"),
        r_em_analise=Decimal("0"),
        consumo_total_global=Decimal("271382.38"),
    )
    saldo_disponivel = Decimal("420000.00") - saldo.nr_total_comprometido
    assert saldo_disponivel == Decimal("149918.75")


def test_saldo_chucri_zaidan_seed():
    """
    Seed: R=752.113,79; NR=1.051.316,21; Em_Análise=14.006,35 →
    consumo_total=1.817.436,35 e saldo_nr=-33.878,82 (já negativo).
    """
    saldo = SaldoSetorDTO(
        setor="Chucri Zaidan",
        nr_consumido_aca=Decimal("1050881.42"),
        nr_consumido_nuvem=Decimal("434.79"),
        nr_em_analise=Decimal("0.00"),
        r_consumido_aca=Decimal("751909.09"),
        r_consumido_nuvem=Decimal("204.70"),
        r_em_analise=Decimal("14006.35"),
        consumo_total_global=Decimal("1817436.35"),
    )
    teto_nr = Decimal("1783557.53")
    consumo_total = saldo.r_total_consumido + saldo.r_em_analise + saldo.nr_total_comprometido
    assert consumo_total == Decimal("1817436.35")
    saldo_nr = teto_nr - consumo_total
    assert saldo_nr == Decimal("-33878.82")  # já negativo — qualquer NR bloqueado


def test_nr_total_comprometido_inclui_em_analise():
    """nr_em_analise deve ser incluído no comprometido (bloqueante para aprovações paralelas)."""
    saldo = SaldoSetorDTO(
        setor="Marginal Pinheiros",
        nr_consumido_aca=Decimal("200000.00"),
        nr_consumido_nuvem=Decimal("10000.00"),
        nr_em_analise=Decimal("30000.00"),   # deve entrar no comprometido
        r_consumido_aca=Decimal("0"),
        r_consumido_nuvem=Decimal("0"),
        r_em_analise=Decimal("0"),
        consumo_total_global=Decimal("240000.00"),
    )
    assert saldo.nr_total_comprometido == Decimal("240000.00")


def test_saldo_zerado():
    """SaldoSetorDTO com todos os campos zerados deve ter comprometido=0."""
    saldo = SaldoSetorDTO(
        setor="Jabaquara",
        nr_consumido_aca=Decimal("0"),
        nr_consumido_nuvem=Decimal("0"),
        nr_em_analise=Decimal("0"),
        r_consumido_aca=Decimal("0"),
        r_consumido_nuvem=Decimal("0"),
        r_em_analise=Decimal("0"),
        consumo_total_global=Decimal("0"),
    )
    assert saldo.nr_total_comprometido == Decimal("0")
    assert saldo.r_total_consumido == Decimal("0")
