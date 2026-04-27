"""
Validator de capacidade global da Operação Urbana Consorciada Água Espraiada.

Aplica o teto máximo de emissão de CEPACs, descontada a reserva técnica,
sobre o consumo total acumulado de todos os setores combinados.

Aplica-se apenas à parcela NR da solicitação; a parcela R não é limitada
por este teto global (é controlada por reserva setorial em Chucri Zaidan).
Para uso=MISTO, apenas metade da área (a parcela NR) é contabilizada.
"""
from decimal import Decimal
from typing import Optional

from src.core.engine.dtos import RulesError, SolicitacaoDTO

# Parâmetros da operação (Lei 15.893/2013 e atualizações)
CAPACIDADE_TOTAL = Decimal("4850000.00")
RESERVA_TECNICA  = Decimal("250000.00")
LIMITE_OPERACAO  = CAPACIDADE_TOTAL - RESERVA_TECNICA   # 4.600.000,00 m²


def validar(solicitacao: SolicitacaoDTO) -> Optional[RulesError]:
    """
    Retorna RulesError se a parcela NR da solicitação ultrapassar o limite global.

    Para uso=NR  : toda a area_m2 é contabilizada como NR.
    Para uso=MISTO: apenas area_nr_m2 (50%) é contabilizada contra o teto global.
    Para uso=R   : parcela NR é zero — validator retorna None imediatamente.

    O campo consumo_total_global do SaldoSetorDTO representa a soma de
    todos os setores e deve ser pré-calculado pelo repositório antes de
    instanciar o DTO.
    """
    area_nr = solicitacao.area_nr_m2
    if area_nr == Decimal("0.00"):
        return None

    saldo = solicitacao.saldo_setor
    projetado = saldo.consumo_total_global + area_nr

    if projetado > LIMITE_OPERACAO:
        saldo_disponivel = LIMITE_OPERACAO - saldo.consumo_total_global
        return RulesError(
            codigo="TETO_GLOBAL_EXCEDIDO",
            mensagem=(
                f"Operação Urbana: teto global NR de {LIMITE_OPERACAO:,.2f} m² excedido. "
                f"Saldo disponível: {saldo_disponivel:,.2f} m²."
            ),
            setor=solicitacao.setor,
            saldo_atual=saldo_disponivel,
            limite=LIMITE_OPERACAO,
        )

    return None
