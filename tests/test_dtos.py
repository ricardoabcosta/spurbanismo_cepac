"""
Testes unitários para src/core/engine/dtos.py.

Foco: propriedades area_nr_m2 e area_r_m2 de SolicitacaoDTO para todos os
valores de uso (R, NR, MISTO).

Sem dependência de banco, ORM ou FastAPI.
"""
from decimal import Decimal
from uuid import uuid4


from src.core.engine.dtos import SaldoSetorDTO, SolicitacaoDTO, TituloDTO


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _saldo_zerado(setor: str = "Brooklin") -> SaldoSetorDTO:
    z = Decimal("0.00")
    return SaldoSetorDTO(
        setor=setor,
        nr_consumido_aca=z,
        nr_consumido_nuvem=z,
        nr_em_analise=z,
        r_consumido_aca=z,
        r_consumido_nuvem=z,
        r_em_analise=z,
        consumo_total_global=z,
    )


def _dto(uso: str, area_m2: Decimal) -> SolicitacaoDTO:
    titulo = TituloDTO(
        id=uuid4(),
        setor="Brooklin",
        uso=uso,
        origem="ACA",
        estado="DISPONIVEL",
        valor_m2=Decimal("100.00"),
    )
    return SolicitacaoDTO(
        setor="Brooklin",
        uso=uso,
        origem="ACA",
        area_m2=area_m2,
        numero_processo_sei="6016.2026/0001234-5",
        titulo_ids=[titulo.id],
        titulos=[titulo],
        saldo_setor=_saldo_zerado(),
    )


# ---------------------------------------------------------------------------
# Uso R
# ---------------------------------------------------------------------------

class TestAreaPropertiesUsoR:
    def test_area_r_igual_area_total(self):
        dto = _dto("R", Decimal("1000.00"))
        assert dto.area_r_m2 == Decimal("1000.00")

    def test_area_nr_zero_para_uso_r(self):
        dto = _dto("R", Decimal("1000.00"))
        assert dto.area_nr_m2 == Decimal("0.00")

    def test_area_nr_zero_independente_do_tamanho(self):
        dto = _dto("R", Decimal("999999.99"))
        assert dto.area_nr_m2 == Decimal("0.00")

    def test_soma_igual_area_total(self):
        area = Decimal("750.50")
        dto = _dto("R", area)
        assert dto.area_nr_m2 + dto.area_r_m2 == area


# ---------------------------------------------------------------------------
# Uso NR
# ---------------------------------------------------------------------------

class TestAreaPropertiesUsoNR:
    def test_area_nr_igual_area_total(self):
        dto = _dto("NR", Decimal("1000.00"))
        assert dto.area_nr_m2 == Decimal("1000.00")

    def test_area_r_zero_para_uso_nr(self):
        dto = _dto("NR", Decimal("1000.00"))
        assert dto.area_r_m2 == Decimal("0.00")

    def test_area_r_zero_independente_do_tamanho(self):
        dto = _dto("NR", Decimal("999999.99"))
        assert dto.area_r_m2 == Decimal("0.00")

    def test_soma_igual_area_total(self):
        area = Decimal("500.00")
        dto = _dto("NR", area)
        assert dto.area_nr_m2 + dto.area_r_m2 == area


# ---------------------------------------------------------------------------
# Uso MISTO
# ---------------------------------------------------------------------------

class TestAreaPropertiesUsoMisto:
    def test_area_nr_metade_do_total(self):
        dto = _dto("MISTO", Decimal("1000.00"))
        assert dto.area_nr_m2 == Decimal("500.00")

    def test_area_r_metade_do_total(self):
        dto = _dto("MISTO", Decimal("1000.00"))
        assert dto.area_r_m2 == Decimal("500.00")

    def test_soma_igual_area_total_valor_par(self):
        area = Decimal("1000.00")
        dto = _dto("MISTO", area)
        assert dto.area_nr_m2 + dto.area_r_m2 == area

    def test_soma_igual_area_total_valor_impar(self):
        area = Decimal("1001.00")
        dto = _dto("MISTO", area)
        assert dto.area_nr_m2 + dto.area_r_m2 == area

    def test_arredondamento_duas_casas_decimais(self):
        """Divisão de valor com muitas casas decimais deve arredondar para 2."""
        dto = _dto("MISTO", Decimal("999.99"))
        assert dto.area_nr_m2 == Decimal("500.00")
        assert dto.area_r_m2 == Decimal("500.00")

    def test_area_nr_igual_area_r_para_misto(self):
        """As duas parcelas devem ser sempre iguais (divisão 50/50)."""
        dto = _dto("MISTO", Decimal("2468.00"))
        assert dto.area_nr_m2 == dto.area_r_m2

    def test_area_pequena_misto(self):
        dto = _dto("MISTO", Decimal("2.00"))
        assert dto.area_nr_m2 == Decimal("1.00")
        assert dto.area_r_m2 == Decimal("1.00")
