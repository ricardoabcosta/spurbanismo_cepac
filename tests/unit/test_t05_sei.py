"""
T05 — SEI Obrigatório

O número do processo SEI deve ser validado ANTES de qualquer outro validator.
Falha rápida: sem SEI, nenhum cálculo de saldo é executado.
"""
from decimal import Decimal
from uuid import uuid4

import pytest

from src.core.engine.dtos import SaldoSetorDTO, SolicitacaoDTO, TituloDTO
from tests.conftest import make_solicitacao


@pytest.fixture
def saldo_brooklin():
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
def saldo_berrini_bloqueado():
    """Saldo Berrini com NR excedido — para testar precedência do SEI."""
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


def _solicitacao_sem_sei(setor: str, saldo: SaldoSetorDTO, sei: str) -> SolicitacaoDTO:
    """Cria solicitação com SEI específico (possivelmente inválido)."""
    titulo = TituloDTO(
        id=uuid4(),
        setor=setor,
        uso="NR",
        origem="ACA",
        estado="DISPONIVEL",
        valor_m2=Decimal("100.00"),
    )
    return SolicitacaoDTO(
        setor=setor,
        uso="NR",
        origem="ACA",
        area_m2=Decimal("1000.00"),
        numero_processo_sei=sei,
        titulo_ids=[titulo.id],
        titulos=[titulo],
        saldo_setor=saldo,
    )


def test_sei_vazio_bloqueado(engine, saldo_brooklin):
    """numero_processo_sei vazio → NUMERO_SEI_OBRIGATORIO antes de qualquer cálculo."""
    solicitacao = _solicitacao_sem_sei("Brooklin", saldo_brooklin, "")
    resultado = engine.validar(solicitacao)

    assert not resultado.aprovado
    assert resultado.erro.codigo == "NUMERO_SEI_OBRIGATORIO"


def test_sei_espacos_bloqueado(engine, saldo_brooklin):
    """numero_processo_sei só com espaços → NUMERO_SEI_OBRIGATORIO."""
    solicitacao = _solicitacao_sem_sei("Brooklin", saldo_brooklin, "   ")
    resultado = engine.validar(solicitacao)

    assert not resultado.aprovado
    assert resultado.erro.codigo == "NUMERO_SEI_OBRIGATORIO"


def test_sei_none_bloqueado(engine, saldo_brooklin):
    """numero_processo_sei=None → NUMERO_SEI_OBRIGATORIO."""
    titulo = TituloDTO(
        id=uuid4(),
        setor="Brooklin",
        uso="NR",
        origem="ACA",
        estado="DISPONIVEL",
        valor_m2=Decimal("100.00"),
    )
    solicitacao = SolicitacaoDTO(
        setor="Brooklin",
        uso="NR",
        origem="ACA",
        area_m2=Decimal("1000.00"),
        numero_processo_sei=None,
        titulo_ids=[titulo.id],
        titulos=[titulo],
        saldo_setor=saldo_brooklin,
    )
    resultado = engine.validar(solicitacao)

    assert not resultado.aprovado
    assert resultado.erro.codigo == "NUMERO_SEI_OBRIGATORIO"


def test_sei_valido_prossegue_para_proximos_validators(engine, saldo_brooklin):
    """SEI válido → passa para próximo validator (não retorna erro SEI)."""
    solicitacao = make_solicitacao(
        setor="Brooklin",
        uso="NR",
        area_m2=Decimal("1000.00"),
        saldo_setor=saldo_brooklin,
        numero_processo_sei="6016.2026/0001234-5",
    )
    resultado = engine.validar(solicitacao)

    # SEI válido — o erro retornado (se houver) não deve ser SEI
    if not resultado.aprovado:
        assert resultado.erro.codigo != "NUMERO_SEI_OBRIGATORIO"


def test_sei_roda_antes_de_outros_validators(engine, saldo_berrini_bloqueado):
    """
    Mesmo com saldo Berrini bloqueado (TETO_NR_EXCEDIDO) E SEI vazio,
    o erro retornado deve ser NUMERO_SEI_OBRIGATORIO (SEI vem primeiro na cadeia).
    """
    solicitacao = _solicitacao_sem_sei("Berrini", saldo_berrini_bloqueado, "")
    resultado = engine.validar(solicitacao)

    assert not resultado.aprovado
    # SEI é validado antes do setorial Berrini — deve ser o primeiro erro
    assert resultado.erro.codigo == "NUMERO_SEI_OBRIGATORIO", (
        f"Esperado NUMERO_SEI_OBRIGATORIO mas recebido: {resultado.erro.codigo}"
    )


def test_sei_tab_bloqueado(engine, saldo_brooklin):
    """numero_processo_sei com apenas tabulação → NUMERO_SEI_OBRIGATORIO."""
    solicitacao = _solicitacao_sem_sei("Brooklin", saldo_brooklin, "\t")
    resultado = engine.validar(solicitacao)

    assert not resultado.aprovado
    assert resultado.erro.codigo == "NUMERO_SEI_OBRIGATORIO"


def test_sei_um_caracter_valido(engine, saldo_brooklin):
    """SEI com um único caractere não-espaço deve passar a validação SEI."""
    solicitacao = make_solicitacao(
        setor="Brooklin",
        uso="NR",
        area_m2=Decimal("1000.00"),
        saldo_setor=saldo_brooklin,
        numero_processo_sei="X",
    )
    resultado = engine.validar(solicitacao)

    if not resultado.aprovado:
        assert resultado.erro.codigo != "NUMERO_SEI_OBRIGATORIO"
