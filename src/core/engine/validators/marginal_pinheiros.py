"""
Validator do setor Marginal Pinheiros — piso R (30%) + teto NR de 420.000,00 m².

O NR em análise já compromete o saldo disponível, impedindo aprovações
paralelas que ultrapassariam o limite antes da confirmação final.

Para uso=MISTO: area_nr_m2 (50%) é contabilizada contra o teto NR e o piso R
é avaliado acrescentando também a parcela R (area_r_m2, outros 50%) ao saldo R
projetado — o que normalmente beneficia o cumprimento do piso mínimo residencial.
"""
from decimal import Decimal
from typing import Optional

from src.core.engine.dtos import RulesError, SolicitacaoDTO

TETO_NR = Decimal("420000.00")
PISO_R_RATIO = Decimal("0.30")


def validar(solicitacao: SolicitacaoDTO) -> Optional[RulesError]:
    """
    Para solicitações com parcela NR verifica dois limites em ordem:
    1. Piso R (30%): R deve representar ≥ 30% do total comprometido após este pedido.
    2. Teto NR (420.000 m²): NR comprometido não pode ultrapassar o teto setorial.

    Para uso=NR  : area_nr_m2 == area_m2, area_r_m2 == 0.
    Para uso=MISTO: cada parcela vale 50% de area_m2.
    Para uso=R   : area_nr_m2 == 0 → retorna None imediatamente.
    """
    area_nr = solicitacao.area_nr_m2
    if area_nr == Decimal("0.00"):
        return None

    saldo = solicitacao.saldo_setor

    # --- 1. Piso R (30% mínimo residencial) ---
    # Para MISTO, a parcela R desta solicitação já contribui ao saldo R projetado.
    r_comprometido_atual = (
        saldo.r_consumido_aca
        + saldo.r_consumido_nuvem
        + saldo.r_em_analise
    )
    r_projetado = r_comprometido_atual + solicitacao.area_r_m2
    nr_projetado = saldo.nr_total_comprometido + area_nr
    total_projetado = r_projetado + nr_projetado

    if total_projetado > 0 and r_projetado / total_projetado < PISO_R_RATIO:
        # R mínimo absoluto necessário para manter 30% após este pedido
        r_minimo = (nr_projetado * PISO_R_RATIO / (1 - PISO_R_RATIO)).quantize(
            Decimal("0.01")
        )
        r_faltante = (r_minimo - r_projetado).quantize(Decimal("0.01"))
        return RulesError(
            codigo="PISO_R_NAO_ATINGIDO",
            mensagem=(
                f"Setor Marginal Pinheiros: piso mínimo R (30%) não atingido. "
                f"Necessário vincular mais {r_faltante:,.2f} m² R antes de novas vinculações NR."
            ),
            setor=solicitacao.setor,
            saldo_atual=r_projetado,
            limite=r_minimo,
        )

    # --- 2. Teto NR (420.000 m²) ---
    nr_comprometido = saldo.nr_total_comprometido
    projetado_nr = nr_comprometido + area_nr

    if projetado_nr > TETO_NR:
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
