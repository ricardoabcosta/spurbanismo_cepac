"""
Validator de capacidade global da Operação Urbana Consorciada Água Espraiada.

Aplica o teto máximo de emissão de CEPACs, descontada a reserva técnica,
sobre o consumo total acumulado de todos os setores combinados.

Aplica-se apenas a solicitações NR; solicitações R não são limitadas por
este teto global (são controladas por reserva setorial em Chucri Zaidan).
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
    Retorna RulesError se a solicitação NR ultrapassar o limite global da operação.

    O campo consumo_total_global do SaldoSetorDTO representa a soma de
    todos os setores e deve ser pré-calculado pelo repositório antes de
    instanciar o DTO.
    """
    if solicitacao.uso != "NR":
        return None

    saldo = solicitacao.saldo_setor
    projetado = saldo.consumo_total_global + solicitacao.area_m2

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
