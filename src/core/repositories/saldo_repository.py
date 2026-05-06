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

from src.core.engine.dtos import LimitesOucDTO, LimitesSetorDTO, SaldoSetorDTO
from src.core.models import LeiOuc, Movimentacao, OperacaoUrbana, Setor, SetorEstoqueLei, TituloCepac
from src.core.models.enums import EstadoTituloEnum, UsoEnum


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


async def get_limites_setor(
    session: AsyncSession,
    setor_nome: str,
    lei_vigente: Optional[str] = None,
) -> LimitesSetorDTO:
    """
    Retorna os limites estruturais de um setor.

    Se `lei_vigente` for informado, busca em `setor_estoque_lei` via join
    com `lei_ouc`. Caso contrário, usa os campos denormalizados de `setor.*`
    (backward compatibility).

    O parâmetro `lei_vigente` é o identificador da lei (ex: "18.175/2024").
    Quando informado, localiza a lei vigente correspondente à OUC do setor
    e lê os estoques da tabela `setor_estoque_lei`.
    """
    if lei_vigente is not None:
        # Buscar via setor_estoque_lei — multi-lei
        stmt = (
            select(
                SetorEstoqueLei.estoque_total_r_m2,
                SetorEstoqueLei.estoque_total_nr_m2,
                SetorEstoqueLei.teto_r_m2,
                SetorEstoqueLei.teto_nr_m2,
                SetorEstoqueLei.reserva_r_m2,
                Setor.estoque_total_m2,
                Setor.bloqueio_nr,
                Setor.piso_r_percentual,
            )
            .join(Setor, Setor.id == SetorEstoqueLei.setor_id)
            .join(LeiOuc, LeiOuc.id == SetorEstoqueLei.lei_ouc_id)
            .where(
                Setor.nome == setor_nome,
                LeiOuc.identificador == lei_vigente,
            )
            .limit(1)
        )
        result = await session.execute(stmt)
        row = result.one_or_none()
        if row is not None:
            estoque_total = row.estoque_total_m2
            teto_nr = row.teto_nr_m2 or Decimal("0")
            teto_r = row.teto_r_m2
            reserva_r = row.reserva_r_m2
            piso_r = row.piso_r_percentual
            return LimitesSetorDTO(
                estoque_total_m2=Decimal(str(estoque_total)),
                teto_nr_m2=Decimal(str(teto_nr)),
                teto_r_m2=Decimal(str(teto_r)) if teto_r is not None else None,
                reserva_r_m2=Decimal(str(reserva_r)) if reserva_r is not None else None,
                piso_r_percentual=Decimal(str(piso_r)) if piso_r is not None else None,
                bloqueio_nr=row.bloqueio_nr,
            )

    # Fallback: usar campos denormalizados de setor.*
    stmt = (
        select(
            Setor.estoque_total_m2,
            Setor.teto_nr_m2,
            Setor.teto_r_m2,
            Setor.reserva_r_m2,
            Setor.piso_r_percentual,
            Setor.bloqueio_nr,
        )
        .where(Setor.nome == setor_nome)
        .limit(1)
    )
    result = await session.execute(stmt)
    row = result.one_or_none()
    if row is None:
        return LimitesSetorDTO(
            estoque_total_m2=Decimal("0"),
            teto_nr_m2=Decimal("0"),
            bloqueio_nr=False,
        )

    return LimitesSetorDTO(
        estoque_total_m2=Decimal(str(row.estoque_total_m2)),
        teto_nr_m2=Decimal(str(row.teto_nr_m2)),
        teto_r_m2=Decimal(str(row.teto_r_m2)) if row.teto_r_m2 is not None else None,
        reserva_r_m2=Decimal(str(row.reserva_r_m2)) if row.reserva_r_m2 is not None else None,
        piso_r_percentual=Decimal(str(row.piso_r_percentual)) if row.piso_r_percentual is not None else None,
        bloqueio_nr=row.bloqueio_nr,
    )


async def get_limites_ouc(
    session: AsyncSession,
    setor_nome: str,
) -> LimitesOucDTO:
    """
    Retorna os limites da OUC à qual o setor pertence.

    Calcula também o total de R Não Incentivado (incentivado=FALSE) já
    consumido/em análise em todos os setores da mesma OUC.
    Também retorna a capacidade global da operação (CAPACIDADE_TOTAL - RESERVA_TECNICA).

    Para OUCs sem distinção R Inc/NI, teto_r_nao_incentivado_m2 é None
    e r_nao_inc_consumido_global é 0 — o validator faz no-op automaticamente.
    """
    # Busca parâmetros da OUC via setor
    stmt_ouc = (
        select(
            OperacaoUrbana.teto_r_nao_incentivado_m2,
            OperacaoUrbana.id,
            OperacaoUrbana.reserva_tecnica_m2,
        )
        .join(Setor, Setor.operacao_urbana_id == OperacaoUrbana.id)
        .where(Setor.nome == setor_nome)
        .limit(1)
    )
    result_ouc = await session.execute(stmt_ouc)
    row_ouc = result_ouc.one_or_none()

    if row_ouc is None:
        return LimitesOucDTO(
            teto_r_nao_incentivado_m2=None,
            r_nao_inc_consumido_global=Decimal("0"),
        )

    ouc_id: int = row_ouc.id
    teto_ni = None
    capacidade_global = Decimal("4850000.00") - Decimal("250000.00")  # default OUCAE

    # Tentar ler capacidade_global de lei_ouc.estoque_geral_m2 se disponível
    get_cap = await session.execute(
        select(LeiOuc.estoque_geral_m2).where(
            LeiOuc.operacao_urbana_id == ouc_id,
            LeiOuc.vigente.is_(True),
        ).limit(1)
    )
    cap_row = get_cap.scalar_one_or_none()
    if cap_row is not None:
        capacidade_global = Decimal(str(cap_row))

    # teto R Não Incentivado
    if row_ouc.teto_r_nao_incentivado_m2 is not None:
        teto_ni = Decimal(str(row_ouc.teto_r_nao_incentivado_m2))

    # Soma R Não Incentivado (incentivado=FALSE) consumido/em análise na OUC inteira
    r_nao_inc_consumido = Decimal("0")
    if teto_ni is not None:
        stmt_consumido = (
            select(func.sum(TituloCepac.valor_m2).label("total_ni"))
            .select_from(Movimentacao)
            .join(TituloCepac, TituloCepac.id == Movimentacao.titulo_id)
            .join(Setor, Setor.id == Movimentacao.setor_id)
            .where(
                Setor.operacao_urbana_id == ouc_id,
                Movimentacao.uso == UsoEnum.R,
                Movimentacao.incentivado.is_(False),
                Movimentacao.estado_novo.in_(
                    [EstadoTituloEnum.CONSUMIDO, EstadoTituloEnum.EM_ANALISE]
                ),
            )
        )
        result_consumido = await session.execute(stmt_consumido)
        r_nao_inc_consumido = Decimal(str(result_consumido.scalar() or "0"))

    return LimitesOucDTO(
        teto_r_nao_incentivado_m2=teto_ni,
        r_nao_inc_consumido_global=r_nao_inc_consumido,
        capacidade_global_m2=capacidade_global,
    )
