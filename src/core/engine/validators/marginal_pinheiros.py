"""
Validator do setor Marginal Pinheiros — piso R (30%) + teto NR de 420.000,00 m².

O NR em análise já compromete o saldo disponível, impedindo aprovações
paralelas que ultrapassariam o limite antes da confirmação final.
"""
from decimal import Decimal
from typing import Optional

from src.core.engine.dtos import RulesError, SolicitacaoDTO

TETO_NR = Decimal("420000.00")
PISO_R_RATIO = Decimal("0.30")


def validar(solicitacao: SolicitacaoDTO) -> Optional[RulesError]:
    """
    Para solicitações NR verifica dois limites em ordem:
    1. Piso R (30%): R deve representar ≥ 30% do total comprometido após este NR.
    2. Teto NR (420.000 m²): NR comprometido não pode ultrapassar o teto setorial.
    """
    if solicitacao.uso != "NR":
        return None

    saldo = solicitacao.saldo_setor

    # --- 1. Piso R (30% mínimo residencial) ---
    r_comprometido = (
        saldo.r_consumido_aca
        + saldo.r_consumido_nuvem
        + saldo.r_em_analise
    )
    nr_projetado = saldo.nr_total_comprometido + solicitacao.area_m2
    total_projetado = r_comprometido + nr_projetado

    if total_projetado > 0 and r_comprometido / total_projetado < PISO_R_RATIO:
        # R mínimo absoluto necessário para manter 30% após este NR
        r_minimo = (nr_projetado * PISO_R_RATIO / (1 - PISO_R_RATIO)).quantize(
            Decimal("0.01")
        )
        r_faltante = (r_minimo - r_comprometido).quantize(Decimal("0.01"))
        return RulesError(
            codigo="PISO_R_NAO_ATINGIDO",
            mensagem=(
                f"Setor Marginal Pinheiros: piso mínimo R (30%) não atingido. "
                f"Necessário vincular mais {r_faltante:,.2f} m² R antes de novas vinculações NR."
            ),
            setor=solicitacao.setor,
            saldo_atual=r_comprometido,
            limite=r_minimo,
        )

    # --- 2. Teto NR (420.000 m²) ---
    nr_comprometido = saldo.nr_total_comprometido
    projetado = nr_comprometido + solicitacao.area_m2

    if projetado > TETO_NR:
        saldo_disponivel = TETO_NR - nr_comprometido
        return RulesError(
            codigo="TETO_NR_EXCEDIDO",
            mensagem=(
                f"Setor Marginal Pinheiros: teto NR de {TETO_NR:,.2f} m² excedido. "
                f"Saldo disponível: {saldo_disponivel:,.2f} m²."
            ),
            setor=solicitacao.setor,
            saldo_atual=saldo_disponivel,
            limite=TETO_NR,
        )

    return None
