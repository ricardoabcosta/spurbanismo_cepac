"""
Validator do setor Brooklin — teto NR de 980.000,00 m².

Considera como "comprometido" o total de NR já consumido (ACA + NUVEM)
mais o NR em análise, evitando que aprovações paralelas ultrapassem o limite.

Para uso=MISTO, apenas a parcela NR (50% de area_m2) é contabilizada.
"""
from decimal import Decimal
from typing import Optional

from src.core.engine.dtos import RulesError, SolicitacaoDTO

TETO_NR = Decimal("980000.00")


def validar(solicitacao: SolicitacaoDTO) -> Optional[RulesError]:
    """
    Retorna RulesError se a parcela NR da solicitação ultrapassar o teto do Brooklin.

    Para uso=NR  : toda a area_m2 é contabilizada.
    Para uso=MISTO: apenas area_nr_m2 (50%) é contabilizada.
    Para uso=R   : parcela NR é zero — retorna None imediatamente.

    O total comprometido inclui NR em análise para evitar corrida entre
    solicitações simultâneas que ainda não foram definitivamente consumidas.
    """
    area_nr = solicitacao.area_nr_m2
    if area_nr == Decimal("0.00"):
        return None

    saldo = solicitacao.saldo_setor
    comprometido = saldo.nr_total_comprometido   # ACA + NUVEM + em_analise
    projetado = comprometido + area_nr

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
