"""
Validator do setor Berrini — bloqueio INCONDICIONAL de novas solicitações NR.

O setor Berrini atingiu seu teto NR e qualquer nova solicitação com
parcela NR deve ser rejeitada imediatamente, sem consultar saldo.
Este validator não realiza nenhum cálculo — o limite já foi superado.

O teto NR vem de `solicitacao.limites_setor.teto_nr_m2` (setor_estoque_lei ou setor.*).
Isso inclui uso=MISTO, pois a parcela NR seria automaticamente inviável.

Se `limites_setor` for None, usa o valor do campo `setor.bloqueio_nr` como fallback.
"""
from decimal import Decimal
from typing import Optional

from src.core.engine.dtos import RulesError, SolicitacaoDTO


def validar(solicitacao: SolicitacaoDTO) -> Optional[RulesError]:
    """
    Retorna RulesError para qualquer solicitação com parcela NR no setor Berrini.

    O bloqueio é incondicional: independentemente do saldo recebido no DTO,
    nenhum novo pedido NR ou MISTO é aceito neste setor.
    Solicitações R puras passam sem restrição setorial de teto NR.
    """
    if solicitacao.area_nr_m2 == Decimal("0.00"):
        return None

    # Verificar bloqueio via limites_setor
    if solicitacao.limites_setor is not None and not solicitacao.limites_setor.bloqueio_nr:
        return None  # Não bloqueado — passa para o próximo validator

    teto_nr = solicitacao.limites_setor.teto_nr_m2 if solicitacao.limites_setor else Decimal("175000.00")
    return RulesError(
        codigo="TETO_NR_EXCEDIDO",
        mensagem="Setor Berrini: teto NR excedido. Novos pedidos NR ou MISTO bloqueados.",
        setor=solicitacao.setor,
        saldo_atual=Decimal("0"),
        limite=teto_nr,
    )
