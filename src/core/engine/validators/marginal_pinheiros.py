"""
Validator do setor Marginal Pinheiros — teto NR de 420.000,00 m².

O NR em análise já compromete o saldo disponível, impedindo aprovações
paralelas que ultrapassariam o limite antes da confirmação final.
"""
from decimal import Decimal
from typing import Optional

from src.core.engine.dtos import RulesError, SolicitacaoDTO

TETO_NR = Decimal("420000.00")


def validar(solicitacao: SolicitacaoDTO) -> Optional[RulesError]:
    """
    Retorna RulesError se a solicitação NR ultrapassar o teto do setor Marginal Pinheiros.

    Comprometido = NR consumido ACA + NR consumido NUVEM + NR em análise.
    O NR em análise é bloqueante — já reserva saldo contra aprovações concorrentes.
    """
    if solicitacao.uso != "NR":
        return None

    saldo = solicitacao.saldo_setor
    comprometido = (
        saldo.nr_consumido_aca
        + saldo.nr_consumido_nuvem
        + saldo.nr_em_analise
    )
    projetado = comprometido + solicitacao.area_m2

    if projetado > TETO_NR:
        saldo_disponivel = TETO_NR - comprometido
        return RulesError(
            codigo="TETO_NR_EXCEDIDO",
            mensagem=(
                f"Setor Marginal Pinheiros: teto NR de {TETO_NR:,.2f} m² excedido. "
                f"Saldo disponível: {saldo_disponivel:,.2f} m²."
            ),
            setor=solicitacao.setor,
            saldo_atual=saldo_disponivel,
            limite=TETO_NR,
        )

    return None
