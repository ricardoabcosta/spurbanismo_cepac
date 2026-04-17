"""
Validator SEI — deve ser executado PRIMEIRO, antes de qualquer outro validator.

Garante que o número do processo SEI foi informado antes de realizar
qualquer cálculo de saldo ou verificação de capacidade.
"""
from typing import Optional

from src.core.engine.dtos import RulesError, SolicitacaoDTO


def validar(solicitacao: SolicitacaoDTO) -> Optional[RulesError]:
    """
    Retorna RulesError se o número SEI estiver ausente, None se aprovado.

    Falha rápida: este validator interrompe o pipeline antes de qualquer
    cálculo de saldo ou acesso a dados de capacidade.
    """
    sei = solicitacao.numero_processo_sei
    if not sei or not sei.strip():
        return RulesError(
            codigo="NUMERO_SEI_OBRIGATORIO",
            mensagem="O número do processo SEI é obrigatório para vincular CEPACs.",
            setor=solicitacao.setor,
        )
    return None
