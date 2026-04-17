"""
Validator do setor Chucri Zaidan — fórmula especial com reserva residencial obrigatória.

A Lei 16.975/2018 reserva 216.442,47 m² exclusivamente para uso Residencial (R).
O teto NR é calculado como ESTOQUE_TOTAL - RESERVA_R, mas a fórmula de verificação
usa o consumo TOTAL do setor (R + NR + em análise de ambos) para garantir que a
reserva residencial não seja indiretamente consumida por aprovações NR.

Fórmula de verificação:
    consumo_total = r_total_consumido + r_em_analise + nr_total_comprometido
    SE consumo_total + area_m2 > TETO_NR → RESERVA_R_VIOLADA
"""
from decimal import Decimal
from typing import Optional

from src.core.engine.dtos import RulesError, SolicitacaoDTO

ESTOQUE_TOTAL = Decimal("2000000.00")
RESERVA_R     = Decimal("216442.47")          # Lei 16.975/2018
TETO_NR       = ESTOQUE_TOTAL - RESERVA_R     # 1.783.557,53 m²


def validar(solicitacao: SolicitacaoDTO) -> Optional[RulesError]:
    """
    Retorna RulesError se o novo pedido NR violar a reserva residencial obrigatória.

    A fórmula agrega todo o consumo do setor (R consumido, R em análise e NR
    comprometido) contra o TETO_NR — não apenas o NR — pois qualquer m² já
    utilizado reduz o espaço disponível para o uso NR dentro do limite total.
    """
    if solicitacao.uso != "NR":
        return None

    saldo = solicitacao.saldo_setor

    # Consumo total do setor: R consumido + R em análise + NR comprometido
    consumo_total = (
        saldo.r_total_consumido       # r_consumido_aca + r_consumido_nuvem
        + saldo.r_em_analise          # R em estado EM_ANALISE
        + saldo.nr_total_comprometido # nr_consumido_aca + nr_consumido_nuvem + nr_em_analise
    )

    projetado = consumo_total + solicitacao.area_m2

    if projetado > TETO_NR:
        saldo_nr = TETO_NR - consumo_total
        return RulesError(
            codigo="RESERVA_R_VIOLADA",
            mensagem=(
                "Setor Chucri Zaidan: novo pedido NR violaria reserva residencial obrigatória."
            ),
            setor=solicitacao.setor,
            saldo_atual=saldo_nr,
            limite=TETO_NR,
        )

    return None
