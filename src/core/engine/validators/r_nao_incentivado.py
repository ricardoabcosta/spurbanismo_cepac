"""
Validator de teto de R Não Incentivado — específico para OUCAB.

Regra: O total de R Não Incentivado consumido/em análise em todos os setores
da OUC, somado à área desta solicitação, não pode exceder
`limites_ouc.teto_r_nao_incentivado_m2`.

Casos em que o validator é no-op (retorna None sem verificação):
  - limites_ouc is None ou teto_r_nao_incentivado_m2 is None → OUC sem teto NI
  - incentivado is True → R Incentivado (HIS/HMP) não consome teto NI
  - uso != "R" → apenas solicitações residenciais puras consomem teto NI
"""
from decimal import Decimal
from typing import Optional

from src.core.engine.dtos import RulesError, SolicitacaoDTO


def validar(solicitacao: SolicitacaoDTO) -> Optional[RulesError]:
    limites = solicitacao.limites_ouc

    # No-op: OUC sem teto de R Não Incentivado
    if limites is None or limites.teto_r_nao_incentivado_m2 is None:
        return None

    # No-op: R Incentivado (HIS/HMP) não é limitado por este teto
    if solicitacao.incentivado is True:
        return None

    # No-op: uso NR ou MISTO não consome teto de R Não Incentivado
    if solicitacao.uso != "R":
        return None

    teto = limites.teto_r_nao_incentivado_m2
    consumido = limites.r_nao_inc_consumido_global
    projetado = consumido + solicitacao.area_r_m2

    if projetado > teto:
        disponivel = max(teto - consumido, Decimal("0.00"))
        return RulesError(
            codigo="TETO_R_NAO_INCENTIVADO_EXCEDIDO",
            mensagem=(
                f"Teto de R Não Incentivado da OUC seria excedido. "
                f"Disponível: {disponivel:.2f} m² | Solicitado: {solicitacao.area_r_m2:.2f} m²."
            ),
            setor=solicitacao.setor,
            saldo_atual=consumido,
            limite=teto,
        )

    return None
