"""
T06 — Estresse Brooklin NR

Cenário: 5 solicitações NR sequenciais no Brooklin.
- Saldo inicial NR: 263.529,99 m² (conforme seed de 13/04/2026)
  (Teto=980.000,00 - consumido_aca=716.470,01 = 263.529,99 disponíveis)
- Cada solicitação: 53.000,00 m²  (5 × 53.000 = 265.000 > 263.529,99)
- Solicitações 1 a 4 devem ser aprovadas (acumulado: 212.000)
- Solicitação 5 (acumulado projetado: 265.000) deve ser BLOQUEADA
- Após bloqueio NR, pedido R deve ser aprovado normalmente
"""
from decimal import Decimal
from uuid import uuid4


from src.core.engine.dtos import SaldoSetorDTO, TituloDTO
from tests.conftest import make_solicitacao

# Constantes do cenário
TETO_NR_BROOKLIN = Decimal("980000.00")
NR_CONSUMIDO_SEED = Decimal("716470.01")
PEDIDO_SERIE = Decimal("53000.00")
SALDO_INICIAL = TETO_NR_BROOKLIN - NR_CONSUMIDO_SEED  # 263.529,99


def _saldo_brooklin(nr_consumido_aca: Decimal) -> SaldoSetorDTO:
    """Cria SaldoSetorDTO para Brooklin com consumo NR informado."""
    return SaldoSetorDTO(
        setor="Brooklin",
        nr_consumido_aca=nr_consumido_aca,
        nr_consumido_nuvem=Decimal("0.00"),
        nr_em_analise=Decimal("0.00"),
        r_consumido_aca=Decimal("0.00"),
        r_consumido_nuvem=Decimal("0.00"),
        r_em_analise=Decimal("0.00"),
        consumo_total_global=nr_consumido_aca,
    )


def _titulo_nr() -> TituloDTO:
    return TituloDTO(
        id=uuid4(),
        setor="Brooklin",
        uso="NR",
        origem="ACA",
        estado="DISPONIVEL",
        valor_m2=Decimal("100.00"),
    )


def _titulo_r() -> TituloDTO:
    return TituloDTO(
        id=uuid4(),
        setor="Brooklin",
        uso="R",
        origem="ACA",
        estado="DISPONIVEL",
        valor_m2=Decimal("100.00"),
    )


def test_brooklin_serie_nr_primeira_aprovada(engine):
    """Primeira solicitação (53.000 acumulado) deve ser aprovada."""
    saldo = _saldo_brooklin(NR_CONSUMIDO_SEED)  # 716.470,01 → projetado 769.470,01 < 980.000
    titulo = _titulo_nr()
    solicitacao = make_solicitacao(
        setor="Brooklin",
        uso="NR",
        area_m2=PEDIDO_SERIE,
        saldo_setor=saldo,
        titulos=[titulo],
    )
    resultado = engine.validar(solicitacao)
    assert resultado.aprovado, f"1ª solicitação deveria ser aprovada: {resultado.erro}"


def test_brooklin_serie_nr_quarta_aprovada(engine):
    """
    Quarta solicitação (212.000 acumulado desde o início) deve ser aprovada.

    Após 3 aprovações de 53.000 cada, consumido sobe para 716.470,01 + 159.000 = 875.470,01.
    Projetado: 875.470,01 + 53.000 = 928.470,01 < 980.000 → aprovado.
    """
    consumido_apos_3 = NR_CONSUMIDO_SEED + (PEDIDO_SERIE * 3)  # 875.470,01
    saldo = _saldo_brooklin(consumido_apos_3)
    titulo = _titulo_nr()
    solicitacao = make_solicitacao(
        setor="Brooklin",
        uso="NR",
        area_m2=PEDIDO_SERIE,
        saldo_setor=saldo,
        titulos=[titulo],
    )
    resultado = engine.validar(solicitacao)
    assert resultado.aprovado, (
        f"4ª solicitação (acumulado 212.000 acima do seed) deve ser aprovada: {resultado.erro}"
    )


def test_brooklin_serie_nr_quinta_bloqueada(engine):
    """
    Quinta solicitação estoura 980.000,00 → TETO_NR_EXCEDIDO.

    Após 4 aprovações de 53.000, consumido = 716.470,01 + 212.000 = 928.470,01.
    Projetado: 928.470,01 + 53.000 = 981.470,01 > 980.000 → bloqueado.
    """
    consumido_apos_4 = NR_CONSUMIDO_SEED + (PEDIDO_SERIE * 4)  # 928.470,01
    saldo = _saldo_brooklin(consumido_apos_4)
    titulo = _titulo_nr()
    solicitacao = make_solicitacao(
        setor="Brooklin",
        uso="NR",
        area_m2=PEDIDO_SERIE,
        saldo_setor=saldo,
        titulos=[titulo],
    )
    resultado = engine.validar(solicitacao)

    assert not resultado.aprovado
    assert resultado.erro.codigo == "TETO_NR_EXCEDIDO"


def test_brooklin_serie_nr_bloqueio_exato_na_borda(engine):
    """
    Solicitação que atinge EXATAMENTE 980.000 deve ser aprovada (limite inclusive).

    saldo atual = 263.529,99; pedido = 263.529,99 → acumulado = 980.000,00 → APROVADO
    """
    saldo = _saldo_brooklin(NR_CONSUMIDO_SEED)  # 716.470,01
    titulo = _titulo_nr()
    solicitacao = make_solicitacao(
        setor="Brooklin",
        uso="NR",
        area_m2=SALDO_INICIAL,  # 263.529,99 — exatamente o saldo disponível
        saldo_setor=saldo,
        titulos=[titulo],
    )
    resultado = engine.validar(solicitacao)

    assert resultado.aprovado, (
        f"Pedido exato no limite (980.000) deve ser aprovado: {resultado.erro}"
    )


def test_brooklin_serie_nr_um_centesimo_acima_bloqueado(engine):
    """
    Pedido que ultrapassa 1 centésimo → BLOQUEADO.

    pedido = 263.530,00 → acumulado = 716.470,01 + 263.530,00 = 980.000,01 → REPROVADO
    """
    saldo = _saldo_brooklin(NR_CONSUMIDO_SEED)  # 716.470,01
    titulo = _titulo_nr()
    solicitacao = make_solicitacao(
        setor="Brooklin",
        uso="NR",
        area_m2=SALDO_INICIAL + Decimal("0.01"),  # 263.530,00
        saldo_setor=saldo,
        titulos=[titulo],
    )
    resultado = engine.validar(solicitacao)

    assert not resultado.aprovado
    assert resultado.erro.codigo == "TETO_NR_EXCEDIDO"


def test_brooklin_r_aprovado_apos_teto_nr(engine):
    """
    Mesmo após NR bloqueado (saldo esgotado), pedido R deve ser aprovado.

    Brooklin com saldo NR esgotado (nr_consumido = teto = 980.000,00).
    Pedido R não sofre restrição de teto NR.
    """
    saldo_esgotado = _saldo_brooklin(TETO_NR_BROOKLIN)  # 980.000,00 — NR esgotado
    titulo_r = _titulo_r()
    solicitacao = make_solicitacao(
        setor="Brooklin",
        uso="R",
        area_m2=Decimal("10000.00"),
        saldo_setor=saldo_esgotado,
        titulos=[titulo_r],
    )
    resultado = engine.validar(solicitacao)

    assert resultado.aprovado, (
        f"Pedido R deve ser aprovado mesmo com NR esgotado: {resultado.erro}"
    )


def test_brooklin_serie_nr_segunda_aprovada(engine):
    """Segunda solicitação (106.000 acumulado) deve ser aprovada."""
    consumido_apos_1 = NR_CONSUMIDO_SEED + PEDIDO_SERIE  # 769.470,01
    saldo = _saldo_brooklin(consumido_apos_1)
    titulo = _titulo_nr()
    solicitacao = make_solicitacao(
        setor="Brooklin",
        uso="NR",
        area_m2=PEDIDO_SERIE,
        saldo_setor=saldo,
        titulos=[titulo],
    )
    resultado = engine.validar(solicitacao)
    assert resultado.aprovado, f"2ª solicitação deve ser aprovada: {resultado.erro}"


def test_brooklin_serie_nr_terceira_aprovada(engine):
    """Terceira solicitação (159.000 acumulado) deve ser aprovada."""
    consumido_apos_2 = NR_CONSUMIDO_SEED + (PEDIDO_SERIE * 2)  # 822.470,01
    saldo = _saldo_brooklin(consumido_apos_2)
    titulo = _titulo_nr()
    solicitacao = make_solicitacao(
        setor="Brooklin",
        uso="NR",
        area_m2=PEDIDO_SERIE,
        saldo_setor=saldo,
        titulos=[titulo],
    )
    resultado = engine.validar(solicitacao)
    assert resultado.aprovado, f"3ª solicitação deve ser aprovada: {resultado.erro}"
