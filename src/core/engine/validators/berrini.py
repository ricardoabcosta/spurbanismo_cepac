"""
Validator do setor Berrini — bloqueio INCONDICIONAL de novas solicitações NR.

O setor Berrini atingiu seu teto NR de 175.000,00 m² e qualquer nova
solicitação NR deve ser rejeitada imediatamente, sem consultar saldo.
Este validator não realiza nenhum cálculo — o limite já foi superado.
"""
from decimal import Decimal
from typing import Optional

from src.core.engine.dtos import RulesError, SolicitacaoDTO

# Limite histórico registrado — já esgotado, mantido apenas como referência documentada
_TETO_NR_HISTORICO = Decimal("175000.00")


def validar(solicitacao: SolicitacaoDTO) -> Optional[RulesError]:
    """
    Retorna RulesError para qualquer solicitação NR no setor Berrini.

    O bloqueio é incondicional: independentemente do saldo recebido no DTO,
    nenhum novo pedido NR é aceito neste setor.
    """
    if solicitacao.uso != "NR":
        return None

    return RulesError(
        codigo="TETO_NR_EXCEDIDO",
        mensagem="Setor Berrini: teto NR excedido. Novos pedidos NR bloqueados.",
        setor=solicitacao.setor,
        saldo_atual=Decimal("0"),
        limite=_TETO_NR_HISTORICO,
    )
