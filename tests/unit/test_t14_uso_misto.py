"""
T14 — uso=MISTO: validação de parcelas R+NR no Rules Engine.

Cobre as propriedades area_nr_m2 / area_r_m2 do SolicitacaoDTO e o comportamento
de cada validator setorial quando a solicitação tem uso=MISTO.

Premissa: uso=MISTO divide area_m2 igualmente (50% NR + 50% R).
"""
from decimal import Decimal
from uuid import uuid4


from src.core.engine.dtos import SaldoSetorDTO, SolicitacaoDTO, TituloDTO
from tests.conftest import make_solicitacao


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def saldo_zerado(setor: str) -> SaldoSetorDTO:
    """SaldoSetorDTO totalmente zerado para um setor qualquer."""
    return SaldoSetorDTO(
        setor=setor,
        nr_consumido_aca=Decimal("0.00"),
        nr_consumido_nuvem=Decimal("0.00"),
        nr_em_analise=Decimal("0.00"),
        r_consumido_aca=Decimal("0.00"),
        r_consumido_nuvem=Decimal("0.00"),
        r_em_analise=Decimal("0.00"),
        consumo_total_global=Decimal("0.00"),
    )


# ---------------------------------------------------------------------------
# SolicitacaoDTO — propriedades area_nr_m2 / area_r_m2
# ---------------------------------------------------------------------------

class TestAreaProperties:
    """Garante que as propriedades de parcela calculam correctamente."""

    def _dto(self, uso: str, area_m2: Decimal) -> SolicitacaoDTO:
        titulo = TituloDTO(
            id=uuid4(), setor="Brooklin", uso=uso,
            origem="ACA", estado="DISPONIVEL", valor_m2=Decimal("100.00"),
        )
        return SolicitacaoDTO(
            setor="Brooklin", uso=uso, origem="ACA", area_m2=area_m2,
            numero_processo_sei="SEI-2026/001",
            titulo_ids=[titulo.id], titulos=[titulo],
            saldo_setor=saldo_zerado("Brooklin"),
        )

    def test_uso_nr_area_nr_igual_total(self):
        dto = self._dto("NR", Decimal("1000.00"))
        assert dto.area_nr_m2 == Decimal("1000.00")
        assert dto.area_r_m2 == Decimal("0.00")

    def test_uso_r_area_r_igual_total(self):
        dto = self._dto("R", Decimal("1000.00"))
        assert dto.area_r_m2 == Decimal("1000.00")
        assert dto.area_nr_m2 == Decimal("0.00")

    def test_uso_misto_divide_igualmente(self):
        dto = self._dto("MISTO", Decimal("1000.00"))
        assert dto.area_nr_m2 == Decimal("500.00")
        assert dto.area_r_m2 == Decimal("500.00")

    def test_uso_misto_valor_impar_arredonda_duas_casas(self):
        dto = self._dto("MISTO", Decimal("1001.00"))
        assert dto.area_nr_m2 == Decimal("500.50")
        assert dto.area_r_m2 == Decimal("500.50")

    def test_uso_misto_soma_igual_total(self):
        dto = self._dto("MISTO", Decimal("999.98"))
        assert dto.area_nr_m2 + dto.area_r_m2 == Decimal("999.98")


# ---------------------------------------------------------------------------
# Berrini — MISTO deve ser bloqueado (teto NR esgotado)
# ---------------------------------------------------------------------------

class TestBerriniMisto:
    def test_misto_bloqueado_incondicional(self, engine, saldo_berrini_seed):
        """MISTO tem parcela NR → bloqueio incondicional no Berrini."""
        sol = make_solicitacao(
            setor="Berrini", uso="MISTO",
            area_m2=Decimal("200.00"), saldo_setor=saldo_berrini_seed,
        )
        resultado = engine.validar(sol)
        assert not resultado.aprovado
        assert resultado.erro.codigo == "TETO_NR_EXCEDIDO"

    def test_misto_bloqueado_com_saldo_zerado(self, engine):
        """MISTO bloqueado mesmo com saldo NR zerado — bloqueio é incondicional."""
        sol = make_solicitacao(
            setor="Berrini", uso="MISTO",
            area_m2=Decimal("1.00"), saldo_setor=saldo_zerado("Berrini"),
        )
        resultado = engine.validar(sol)
        assert not resultado.aprovado
        assert resultado.erro.codigo == "TETO_NR_EXCEDIDO"

    def test_r_puro_aprovado(self, engine, saldo_berrini_seed):
        """R puro continua aprovado no Berrini (sem parcela NR)."""
        sol = make_solicitacao(
            setor="Berrini", uso="R",
            area_m2=Decimal("1000.00"), saldo_setor=saldo_berrini_seed,
        )
        resultado = engine.validar(sol)
        assert resultado.aprovado


# ---------------------------------------------------------------------------
# Brooklin — MISTO deve debitar apenas 50% no teto NR de 980.000 m²
# ---------------------------------------------------------------------------

class TestBrooklinMisto:
    def test_misto_aprovado_quando_parcela_nr_cabe(self, engine, saldo_brooklin_seed):
        """
        saldo_brooklin_seed: 716.470,01 m² NR consumidos → disponível: 263.529,99 m².
        Solicitação MISTO de 400.000 m² → parcela NR = 200.000 m² < 263.529,99 → aprovado.
        """
        sol = make_solicitacao(
            setor="Brooklin", uso="MISTO",
            area_m2=Decimal("400000.00"), saldo_setor=saldo_brooklin_seed,
        )
        resultado = engine.validar(sol)
        assert resultado.aprovado, resultado.erro

    def test_misto_bloqueado_quando_parcela_nr_excede(self, engine, saldo_brooklin_seed):
        """
        Parcela NR = 50% de 600.000 = 300.000 m² > 263.529,99 disponível → TETO_NR_EXCEDIDO.
        """
        sol = make_solicitacao(
            setor="Brooklin", uso="MISTO",
            area_m2=Decimal("600000.00"), saldo_setor=saldo_brooklin_seed,
        )
        resultado = engine.validar(sol)
        assert not resultado.aprovado
        assert resultado.erro.codigo == "TETO_NR_EXCEDIDO"

    def test_nr_puro_ainda_bloqueado_quando_excede(self, engine, saldo_brooklin_seed):
        """Regressão: NR puro de 264.000 m² > disponível → deve continuar sendo bloqueado."""
        sol = make_solicitacao(
            setor="Brooklin", uso="NR",
            area_m2=Decimal("264000.00"), saldo_setor=saldo_brooklin_seed,
        )
        resultado = engine.validar(sol)
        assert not resultado.aprovado
        assert resultado.erro.codigo == "TETO_NR_EXCEDIDO"


# ---------------------------------------------------------------------------
# Capacity (global) — MISTO conta apenas parcela NR no teto de 4.600.000 m²
# ---------------------------------------------------------------------------

class TestCapacityMisto:
    def _saldo_jabaquara_com_global_alto(self, consumo_total_global: Decimal) -> SaldoSetorDTO:
        """
        Saldo para Jabaquara com NR setorial baixo (bem dentro do teto de 175.000),
        mas consumo_total_global elevado (reflectindo outros sectores).
        Assim o teto setorial do Jabaquara não é acionado e só o capacity validator actua.
        """
        return SaldoSetorDTO(
            setor="Jabaquara",
            nr_consumido_aca=Decimal("100.00"),     # dentro do teto setorial de 175.000
            nr_consumido_nuvem=Decimal("0.00"),
            nr_em_analise=Decimal("0.00"),
            r_consumido_aca=Decimal("0.00"),
            r_consumido_nuvem=Decimal("0.00"),
            r_em_analise=Decimal("0.00"),
            consumo_total_global=consumo_total_global,
        )

    def test_misto_aprovado_quando_parcela_nr_cabe_no_global(self, engine):
        """
        consumo_total_global = 4.599.000 → disponível global: 1.000 m².
        MISTO 1.000 m² → parcela NR = 500 m² < 1.000 disponível → aprovado.
        NR setorial Jabaquara = 100 m² → não activa o teto setorial (175.000).
        """
        saldo = self._saldo_jabaquara_com_global_alto(Decimal("4599000.00"))
        sol = make_solicitacao(
            setor="Jabaquara", uso="MISTO",
            area_m2=Decimal("1000.00"), saldo_setor=saldo,
        )
        resultado = engine.validar(sol)
        assert resultado.aprovado, resultado.erro

    def test_misto_bloqueado_quando_parcela_nr_excede_global(self, engine):
        """
        consumo_total_global = 4.599.800 → disponível global: 200 m².
        MISTO 1.000 m² → parcela NR = 500 m² > 200 disponível → TETO_GLOBAL_EXCEDIDO.
        """
        saldo = self._saldo_jabaquara_com_global_alto(Decimal("4599800.00"))
        sol = make_solicitacao(
            setor="Jabaquara", uso="MISTO",
            area_m2=Decimal("1000.00"), saldo_setor=saldo,
        )
        resultado = engine.validar(sol)
        assert not resultado.aprovado
        assert resultado.erro.codigo == "TETO_GLOBAL_EXCEDIDO"

    def test_r_puro_nao_limitado_pelo_global(self, engine):
        """R puro não é limitado pelo teto global — mesmo com consumo_total_global no limite."""
        saldo = self._saldo_jabaquara_com_global_alto(Decimal("4599999.00"))
        sol = make_solicitacao(
            setor="Jabaquara", uso="R",
            area_m2=Decimal("100000.00"), saldo_setor=saldo,
        )
        resultado = engine.validar(sol)
        assert resultado.aprovado, resultado.erro


# ---------------------------------------------------------------------------
# Jabaquara — MISTO deve debitar apenas 50% no teto NR de 175.000 m²
# ---------------------------------------------------------------------------

class TestJabaquaraMisto:
    def _saldo_jabaquara(self, nr_consumido: Decimal) -> SaldoSetorDTO:
        return SaldoSetorDTO(
            setor="Jabaquara",
            nr_consumido_aca=nr_consumido,
            nr_consumido_nuvem=Decimal("0.00"),
            nr_em_analise=Decimal("0.00"),
            r_consumido_aca=Decimal("0.00"),
            r_consumido_nuvem=Decimal("0.00"),
            r_em_analise=Decimal("0.00"),
            consumo_total_global=nr_consumido,
        )

    def test_misto_aprovado_parcela_nr_cabe(self, engine):
        """170.000 consumido → disponível 5.000. MISTO 8.000 → parcela NR = 4.000 → aprovado."""
        saldo = self._saldo_jabaquara(Decimal("170000.00"))
        sol = make_solicitacao(
            setor="Jabaquara", uso="MISTO",
            area_m2=Decimal("8000.00"), saldo_setor=saldo,
        )
        resultado = engine.validar(sol)
        assert resultado.aprovado, resultado.erro

    def test_misto_bloqueado_parcela_nr_excede(self, engine):
        """170.000 consumido → disponível 5.000. MISTO 12.000 → parcela NR = 6.000 > 5.000."""
        saldo = self._saldo_jabaquara(Decimal("170000.00"))
        sol = make_solicitacao(
            setor="Jabaquara", uso="MISTO",
            area_m2=Decimal("12000.00"), saldo_setor=saldo,
        )
        resultado = engine.validar(sol)
        assert not resultado.aprovado
        assert resultado.erro.codigo == "TETO_NR_EXCEDIDO"


# ---------------------------------------------------------------------------
# Marginal Pinheiros — MISTO: parcela NR vs. teto + parcela R conta no piso
# ---------------------------------------------------------------------------

class TestMarginalPinheirosMisto:
    def _saldo(
        self,
        nr_consumido: Decimal = Decimal("0.00"),
        r_consumido: Decimal = Decimal("0.00"),
    ) -> SaldoSetorDTO:
        return SaldoSetorDTO(
            setor="Marginal Pinheiros",
            nr_consumido_aca=nr_consumido,
            nr_consumido_nuvem=Decimal("0.00"),
            nr_em_analise=Decimal("0.00"),
            r_consumido_aca=r_consumido,
            r_consumido_nuvem=Decimal("0.00"),
            r_em_analise=Decimal("0.00"),
            consumo_total_global=nr_consumido + r_consumido,
        )

    def test_misto_aprovado_com_saldo_zerado(self, engine):
        """
        Saldo zerado, MISTO 200.000 m²:
          area_nr = 100.000, area_r = 100.000
          r_projetado = 100.000, nr_projetado = 100.000, total = 200.000
          r% = 50% ≥ 30% → piso OK; 100.000 < 420.000 → teto OK → aprovado.
        """
        saldo = self._saldo()
        sol = make_solicitacao(
            setor="Marginal Pinheiros", uso="MISTO",
            area_m2=Decimal("200000.00"), saldo_setor=saldo,
        )
        resultado = engine.validar(sol)
        assert resultado.aprovado, resultado.erro

    def test_misto_bloqueado_por_teto_nr(self, engine):
        """
        NR já consumido = 380.000. MISTO 100.000 → parcela NR = 50.000.
        380.000 + 50.000 = 430.000 > 420.000 → TETO_NR_EXCEDIDO.
        """
        saldo = self._saldo(nr_consumido=Decimal("380000.00"), r_consumido=Decimal("200000.00"))
        sol = make_solicitacao(
            setor="Marginal Pinheiros", uso="MISTO",
            area_m2=Decimal("100000.00"), saldo_setor=saldo,
        )
        resultado = engine.validar(sol)
        assert not resultado.aprovado
        assert resultado.erro.codigo == "TETO_NR_EXCEDIDO"

    def test_misto_parcela_r_contribui_para_piso(self, engine):
        """
        Sem saldo anterior, MISTO 100.000 m²:
        r_projetado = 50.000, nr_projetado = 50.000, total = 100.000.
        r% = 50% ≥ 30% → piso satisfeito pela própria parcela R do MISTO.
        NR puro de 100.000 com saldo zerado falharia no piso (r=0/(0+100k)=0% < 30%).
        """
        saldo = self._saldo()
        sol_misto = make_solicitacao(
            setor="Marginal Pinheiros", uso="MISTO",
            area_m2=Decimal("100000.00"), saldo_setor=saldo,
        )
        sol_nr = make_solicitacao(
            setor="Marginal Pinheiros", uso="NR",
            area_m2=Decimal("100000.00"), saldo_setor=saldo,
        )
        resultado_misto = engine.validar(sol_misto)
        resultado_nr = engine.validar(sol_nr)

        assert resultado_misto.aprovado, resultado_misto.erro
        assert not resultado_nr.aprovado
        assert resultado_nr.erro.codigo == "PISO_R_NAO_ATINGIDO"


# ---------------------------------------------------------------------------
# Chucri Zaidan — MISTO: apenas parcela NR testada contra TETO_NR
# ---------------------------------------------------------------------------

class TestChucriZaidanMisto:
    def _saldo_chucri(
        self,
        nr_comprometido: Decimal = Decimal("0.00"),
        r_consumido: Decimal = Decimal("0.00"),
        r_em_analise: Decimal = Decimal("0.00"),
    ) -> SaldoSetorDTO:
        return SaldoSetorDTO(
            setor="Chucri Zaidan",
            nr_consumido_aca=nr_comprometido,
            nr_consumido_nuvem=Decimal("0.00"),
            nr_em_analise=Decimal("0.00"),
            r_consumido_aca=r_consumido,
            r_consumido_nuvem=Decimal("0.00"),
            r_em_analise=r_em_analise,
            consumo_total_global=nr_comprometido + r_consumido + r_em_analise,
        )

    def test_misto_aprovado_quando_parcela_nr_cabe(self, engine):
        """
        TETO_NR Chucri = 1.783.557,53.
        consumo_total = 1.700.000 → disponível NR: 83.557,53.
        MISTO 100.000 → parcela NR = 50.000 < 83.557,53 → aprovado.
        """
        saldo = self._saldo_chucri(
            nr_comprometido=Decimal("1000000.00"),
            r_consumido=Decimal("700000.00"),
        )
        sol = make_solicitacao(
            setor="Chucri Zaidan", uso="MISTO",
            area_m2=Decimal("100000.00"), saldo_setor=saldo,
        )
        resultado = engine.validar(sol)
        assert resultado.aprovado, resultado.erro

    def test_misto_bloqueado_quando_parcela_nr_viola_reserva(self, engine):
        """
        consumo_total = 1.780.000 → disponível NR: 3.557,53.
        MISTO 10.000 → parcela NR = 5.000 > 3.557,53 → RESERVA_R_VIOLADA.
        """
        saldo = self._saldo_chucri(
            nr_comprometido=Decimal("1080000.00"),
            r_consumido=Decimal("700000.00"),
        )
        sol = make_solicitacao(
            setor="Chucri Zaidan", uso="MISTO",
            area_m2=Decimal("10000.00"), saldo_setor=saldo,
        )
        resultado = engine.validar(sol)
        assert not resultado.aprovado
        assert resultado.erro.codigo == "RESERVA_R_VIOLADA"

    def test_r_puro_aprovado_chucri(self, engine, saldo_chucri_zaidan_seed):
        """R puro continua aprovado no Chucri Zaidan (sem parcela NR)."""
        sol = make_solicitacao(
            setor="Chucri Zaidan", uso="R",
            area_m2=Decimal("1000.00"), saldo_setor=saldo_chucri_zaidan_seed,
        )
        resultado = engine.validar(sol)
        assert resultado.aprovado, resultado.erro
