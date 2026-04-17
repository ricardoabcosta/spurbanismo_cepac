"""
Validator do setor Brooklin — teto NR de 980.000,00 m².

Considera como "comprometido" o total de NR já consumido (ACA + NUVEM)
mais o NR em análise, evitando que aprovações paralelas ultrapassem o limite.
"""
from decimal import Decimal
from typing import Optional

from src.core.engine.dtos import RulesError, SolicitacaoDTO

TETO_NR = Decimal("980000.00")


def validar(solicitacao: SolicitacaoDTO) -> Optional[RulesError]:
    """
    Retorna RulesError se a solicitação NR ultrapassar o teto setorial do Brooklin.

    O total comprometido inclui NR em análise para evitar corrida entre
    solicitações simultâneas que ainda não foram definitivamente consumidas.
    """
    if solicitacao.uso != "NR":
        return None

    saldo = solicitacao.saldo_setor
    comprometido = saldo.nr_total_comprometido   # ACA + NUVEM + em_analise
    projetado = comprometido + solicitacao.area_m2

    if projetado > TETO_NR:
        saldo_disponivel = TETO_NR - comprometido
        return RulesError(
            codigo="TETO_NR_EXCEDIDO",
            mensagem=(
                f"Setor Brooklin: teto NR de {TETO_NR:,.2f} m² excedido. "
                f"Saldo disponível: {saldo_disponivel:,.2f} m²."
            ),
            setor=solicitacao.setor,
            saldo_atual=saldo_disponivel,
            limite=TETO_NR,
        )

    return None
