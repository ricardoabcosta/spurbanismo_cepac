"""
Validators do motor de regras CEPAC.

Cada módulo expõe uma única função pura:
    validar(solicitacao: SolicitacaoDTO) -> Optional[RulesError]

Ordem de execução garantida pelo RulesEngine:
  1. sei                — SEI obrigatório (falha rápida)
  2. capacity           — teto global da operação (OUCAE)
  3. <setorial>         — regra específica do setor
  4. r_nao_incentivado  — teto R Não Incentivado (OUCAB; no-op para demais OUCs)
  5. quarantine         — disponibilidade de cada título do lote
"""
from src.core.engine.validators import (
    berrini,
    brooklin,
    capacity,
    chucri_zaidan,
    jabaquara,
    marginal_pinheiros,
    quarantine,
    r_nao_incentivado,
    sei,
)

__all__ = [
    "sei",
    "capacity",
    "brooklin",
    "berrini",
    "marginal_pinheiros",
    "chucri_zaidan",
    "jabaquara",
    "r_nao_incentivado",
    "quarantine",
]
