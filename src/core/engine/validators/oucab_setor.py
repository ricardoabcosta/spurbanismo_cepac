"""
Validator setorial OUCAB — Água Branca.

Verifica os tetos de R e NR por setor conforme setor_estoque_lei e a lei vigente
(15.893/2013 c/c 17.561/2021).

Setores com teto_r_m2 = 0 bloqueiam qualquer solicitação R.
Setores com teto_nr_m2 = 0 bloqueiam qualquer solicitação NR.
No-op quando limites_setor não está disponível (OUC sem teto setorial configurado).
"""
from decimal import Decimal
from typing import Optional

from src.core.engine.dtos import RulesError, SolicitacaoDTO


def validar(solicitacao: SolicitacaoDTO) -> Optional[RulesError]:
    """
    Retorna RulesError se a parcela R ou NR ultrapassar o teto setorial OUCAB.
    """
    limites = solicitacao.limites_setor
    if limites is None:
        return None

    saldo = solicitacao.saldo_setor
    area_r = solicitacao.area_r_m2
    area_nr = solicitacao.area_nr_m2

    # --- Teto R setorial ---
    if area_r > Decimal("0"):
        teto_r = limites.teto_r_m2 if limites.teto_r_m2 is not None else Decimal("0")
        r_comprometido = (
            saldo.r_consumido_aca + saldo.r_consumido_nuvem + saldo.r_em_analise
        )
        r_disponivel = teto_r - r_comprometido
        if area_r > r_disponivel:
            return RulesError(
                codigo="TETO_R_SETOR_EXCEDIDO",
                mensagem=(
                    f"{solicitacao.setor}: teto R de {teto_r:,.2f} m² excedido. "
                    f"Saldo disponível: {max(r_disponivel, Decimal('0')):,.2f} m²."
                ),
                setor=solicitacao.setor,
                saldo_atual=max(r_disponivel, Decimal("0")),
                limite=teto_r,
            )

    # --- Teto NR setorial ---
    if area_nr > Decimal("0"):
        teto_nr = limites.teto_nr_m2 if limites.teto_nr_m2 is not None else Decimal("0")
        nr_comprometido = (
            saldo.nr_consumido_aca + saldo.nr_consumido_nuvem + saldo.nr_em_analise
        )
        nr_disponivel = teto_nr - nr_comprometido
        if area_nr > nr_disponivel:
            return RulesError(
                codigo="TETO_NR_SETOR_EXCEDIDO",
                mensagem=(
                    f"{solicitacao.setor}: teto NR de {teto_nr:,.2f} m² excedido. "
                    f"Saldo disponível: {max(nr_disponivel, Decimal('0')):,.2f} m²."
                ),
                setor=solicitacao.setor,
                saldo_atual=max(nr_disponivel, Decimal("0")),
                limite=teto_nr,
            )

    return None
