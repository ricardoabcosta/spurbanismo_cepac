"""
Fixtures compartilhadas para os testes unitários do RulesEngine CEPAC.

Não importa SQLAlchemy, FastAPI ou qualquer I/O.
Todos os valores de área em Decimal — nunca float.
"""
import pytest
from decimal import Decimal
from uuid import uuid4

from src.core.engine.dtos import SaldoSetorDTO, TituloDTO, SolicitacaoDTO
from src.core.engine.rules_engine import RulesEngine


@pytest.fixture
def engine():
    """Instância limpa do RulesEngine para cada teste."""
    return RulesEngine()


@pytest.fixture
def titulo_disponivel():
    """Título CEPAC disponível para vinculação no setor Brooklin."""
    return TituloDTO(
        id=uuid4(),
        setor="Brooklin",
        uso="NR",
        origem="ACA",
        estado="DISPONIVEL",
        valor_m2=Decimal("100.00"),
    )


@pytest.fixture
def saldo_brooklin_seed():
    """Saldo Brooklin conforme seed 13/04/2026. Saldo NR disponível: 263.529,99 m²."""
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


@pytest.fixture
def saldo_berrini_seed():
    """Saldo Berrini — NR excedido (203.797,23 m² consumidos, teto 175.000,00)."""
    return SaldoSetorDTO(
        setor="Berrini",
        nr_consumido_aca=Decimal("203202.23"),
        nr_consumido_nuvem=Decimal("595.00"),
        nr_em_analise=Decimal("0.00"),
        r_consumido_aca=Decimal("0.00"),
        r_consumido_nuvem=Decimal("100.62"),
        r_em_analise=Decimal("0.00"),
        consumo_total_global=Decimal("203897.85"),
    )


@pytest.fixture
def saldo_chucri_zaidan_seed():
    """
    Saldo Chucri Zaidan conforme seed 13/04/2026.
    Saldo NR disponível: 182.563,65 m²
    (teto_nr=1.783.557,53 - consumo_total=1.817.436,35 = -33.878,82 já negativo,
     mas o saldo_nr disponível para novos pedidos = teto_nr - (r_total + r_em_analise + nr_comprometido))
    """
    return SaldoSetorDTO(
        setor="Chucri Zaidan",
        nr_consumido_aca=Decimal("1050881.42"),
        nr_consumido_nuvem=Decimal("434.79"),
        nr_em_analise=Decimal("0.00"),
        r_consumido_aca=Decimal("751909.09"),
        r_consumido_nuvem=Decimal("204.70"),
        r_em_analise=Decimal("14006.35"),
        consumo_total_global=Decimal("1817436.35"),
    )


def make_solicitacao(
    setor: str,
    uso: str,
    area_m2: Decimal,
    saldo_setor: SaldoSetorDTO,
    titulos: list = None,
    numero_processo_sei: str = "6016.2026/0001234-5",
    origem: str = "ACA",
) -> SolicitacaoDTO:
    """Helper para construir SolicitacaoDTO nos testes."""
    if titulos is None:
        titulos = [
            TituloDTO(
                id=uuid4(),
                setor=setor,
                uso=uso,
                origem=origem,
                estado="DISPONIVEL",
                valor_m2=Decimal("100.00"),
            )
        ]
    return SolicitacaoDTO(
        setor=setor,
        uso=uso,
        origem=origem,
        area_m2=area_m2,
        numero_processo_sei=numero_processo_sei,
        titulo_ids=[t.id for t in titulos],
        titulos=titulos,
        saldo_setor=saldo_setor,
    )
