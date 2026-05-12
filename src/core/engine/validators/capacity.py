"""
Validator de capacidade global da Operação Urbana.

Aplica o teto máximo de m² NR da operação, lido dinamicamente de
limites_ouc.capacidade_global_m2 (proveniente de lei_ouc.estoque_geral_m2).

No-op quando capacidade_global_m2 não está configurada (OUC sem teto global de NR).

Aplica-se à parcela NR da solicitação:
  uso=NR  : toda a area_m2 é contabilizada como NR.
  uso=MISTO: apenas area_nr_m2 (50%) é contabilizada.
  uso=R   : validator retorna None imediatamente.
"""
from decimal import Decimal
from typing import Optional

from src.core.engine.dtos import RulesError, SolicitacaoDTO


def validar(solicitacao: SolicitacaoDTO) -> Optional[RulesError]:
    """
    Retorna RulesError se a parcela NR da solicitação ultrapassar o teto global da OUC.
    """
    area_nr = solicitacao.area_nr_m2
    if area_nr == Decimal("0.00"):
        return None

    limites_ouc = solicitacao.limites_ouc
    if limites_ouc is None or limites_ouc.capacidade_global_m2 is None:
        return None  # OUC sem teto global configurado — no-op

    limite_operacao = limites_ouc.capacidade_global_m2
    saldo = solicitacao.saldo_setor
    projetado = saldo.consumo_total_global + area_nr

    if projetado > limite_operacao:
        saldo_disponivel = limite_operacao - saldo.consumo_total_global
        return RulesError(
            codigo="TETO_GLOBAL_EXCEDIDO",
            mensagem=(
                f"Operação Urbana: teto global NR de {limite_operacao:,.2f} m² excedido. "
                f"Saldo disponível: {saldo_disponivel:,.2f} m²."
            ),
            setor=solicitacao.setor,
            saldo_atual=saldo_disponivel,
            limite=limite_operacao,
        )

    return None
