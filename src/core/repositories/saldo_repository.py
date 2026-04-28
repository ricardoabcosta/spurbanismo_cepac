"""
SaldoRepository — calcula o saldo de um setor a partir da tabela `movimentacao`.

REGRA FUNDAMENTAL: O saldo nunca é lido de uma coluna calculada.
Sempre derivado do histórico de movimentações (append-only).

Suporta consulta point-in-time via `data_referencia` para auditoria CVM/TCM.
"""
from datetime import date, datetime, time
from decimal import Decimal
from typing import Optional

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from src.core.engine.dtos import SaldoSetorDTO
from src.core.models import Movimentacao, Setor, TituloCepac
from src.core.models.enums import EstadoTituloEnum


async def calcular_saldo(
    session: AsyncSession,
    setor: str,
    data_referencia: Optional[date] = None,
) -> SaldoSetorDTO:
    """
    Calcula o saldo de um setor a partir da tabela `movimentacao`.

    Nunca usa coluna calculada — sempre deriva do histórico.

    Se `data_referencia` fornecida, filtra movimentacao WHERE created_at <=
    fim do dia da data_referencia (23:59:59.999999 UTC) — snapshot point-in-time.

    O campo `consumo_total_global` soma TODOS os setores (sem filtro de setor)
    para permitir validação de capacidade global no RulesEngine.
    """
    # Montar filtro de data: até o fim do dia solicitado (23:59:59 UTC)
    data_limite: Optional[datetime] = None
    if data_referencia is not None:
        data_limite = datetime.combine(data_referencia, time.max)  # naive — TIMESTAMP WITHOUT TIME ZONE

    # ------------------------------------------------------------------ #
    # Query de saldo do setor                                              #
    # ------------------------------------------------------------------ #
    # Agrega por uso, origem e estado_novo apenas estados que comprometem  #
    # o saldo: CONSUMIDO e EM_ANALISE.                                     #
    # ------------------------------------------------------------------ #
    stmt_setor = (
        select(
            Movimentacao.uso,
            Movimentacao.origem,
            Movimentacao.estado_novo,
            func.sum(TituloCepac.valor_m2).label("total"),
        )
        .join(TituloCepac, TituloCepac.id == Movimentacao.titulo_id)
        .join(Setor, Setor.id == Movimentacao.setor_id)
        .where(
            Setor.nome == setor,
            Movimentacao.estado_novo.in_(
                [EstadoTituloEnum.CONSUMIDO, EstadoTituloEnum.EM_ANALISE]
            ),
        )
        .group_by(Movimentacao.uso, Movimentacao.origem, Movimentacao.estado_novo)
    )

    if data_limite is not None:
        stmt_setor = stmt_setor.where(Movimentacao.created_at <= data_limite)

    result_setor = await session.execute(stmt_setor)
    rows = result_setor.all()

    # Acumular valores nas categorias corretas
    nr_consumido_aca = Decimal("0")
    nr_consumido_nuvem = Decimal("0")
    nr_em_analise = Decimal("0")
    r_consumido_aca = Decimal("0")
    r_consumido_nuvem = Decimal("0")
    r_em_analise = Decimal("0")

    for uso, origem, estado_novo, total in rows:
        total = total or Decimal("0")
        uso_val = uso.value if hasattr(uso, "value") else uso
        origem_val = origem.value if hasattr(origem, "value") else origem
        estado_val = estado_novo.value if hasattr(estado_novo, "value") else estado_novo

        if uso_val == "NR":
            if estado_val == "CONSUMIDO":
                if origem_val == "ACA":
                    nr_consumido_aca += total
                else:
                    nr_consumido_nuvem += total
            elif estado_val == "EM_ANALISE":
                nr_em_analise += total
        elif uso_val == "R":
            if estado_val == "CONSUMIDO":
                if origem_val == "ACA":
                    r_consumido_aca += total
                else:
                    r_consumido_nuvem += total
            elif estado_val == "EM_ANALISE":
                r_em_analise += total

    # ------------------------------------------------------------------ #
    # Query de consumo global (todos os setores)                          #
    # ------------------------------------------------------------------ #
    stmt_global = (
        select(func.sum(TituloCepac.valor_m2).label("total_global"))
        .select_from(Movimentacao)
        .join(TituloCepac, TituloCepac.id == Movimentacao.titulo_id)
        .where(
            Movimentacao.estado_novo.in_(
                [EstadoTituloEnum.CONSUMIDO, EstadoTituloEnum.EM_ANALISE]
            )
        )
    )

    if data_limite is not None:
        stmt_global = stmt_global.where(Movimentacao.created_at <= data_limite)

    result_global = await session.execute(stmt_global)
    consumo_total_global = result_global.scalar() or Decimal("0")

    return SaldoSetorDTO(
        setor=setor,
        nr_consumido_aca=nr_consumido_aca,
        nr_consumido_nuvem=nr_consumido_nuvem,
        nr_em_analise=nr_em_analise,
        r_consumido_aca=r_consumido_aca,
        r_consumido_nuvem=r_consumido_nuvem,
        r_em_analise=r_em_analise,
        consumo_total_global=Decimal(str(consumo_total_global)),
    )
