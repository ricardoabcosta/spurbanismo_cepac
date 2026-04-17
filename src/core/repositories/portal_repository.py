"""
PortalRepository — acesso a dados para o Portal de Operações Técnicas (T15).

Todas as funções recebem AsyncSession e retornam modelos ORM ou None.
Sem lógica de negócio — apenas acesso a dados.
"""
from __future__ import annotations

import math
from typing import Optional
from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from src.core.models.enums import (
    EstadoTituloEnum,
    OrigemEnum,
    StatusSolicitacaoEnum,
    UsoEnum,
)
from src.core.models.proposta import Proposta
from src.core.models.setor import Setor
from src.core.models.solicitacao_titulos import SolicitacaoTitulos
from src.core.models.solicitacao_vinculacao import SolicitacaoVinculacao
from src.core.models.titulo_cepac import TituloCepac


# ---------------------------------------------------------------------------
# Criação
# ---------------------------------------------------------------------------

async def criar_solicitacao(
    session: AsyncSession,
    setor_id: UUID,
    uso: UsoEnum,
    origem: OrigemEnum,
    area_m2,
    numero_processo_sei: str,
    titulo_dtos: list,
    proposta_id: Optional[UUID] = None,
    observacao: Optional[str] = None,
) -> SolicitacaoVinculacao:
    """
    Cria um registro em solicitacao_vinculacao (status=PENDENTE) e os
    registros de junção em solicitacao_titulos.

    Não faz commit — responsabilidade da camada de rota.
    """
    solicitacao = SolicitacaoVinculacao(
        setor_id=setor_id,
        uso=uso,
        origem=origem,
        area_m2=area_m2,
        quantidade_cepacs=len(titulo_dtos),
        numero_processo_sei=numero_processo_sei,
        status=StatusSolicitacaoEnum.PENDENTE,
        proposta_id=proposta_id,
        observacao=observacao,
    )
    session.add(solicitacao)
    await session.flush()  # obtém o ID sem commit

    for dto in titulo_dtos:
        st = SolicitacaoTitulos(
            solicitacao_id=solicitacao.id,
            titulo_id=dto.id,
            area_m2=dto.valor_m2,
        )
        session.add(st)

    return solicitacao


# ---------------------------------------------------------------------------
# Leitura
# ---------------------------------------------------------------------------

async def buscar_por_id(
    session: AsyncSession,
    solicitacao_id: UUID,
) -> Optional[SolicitacaoVinculacao]:
    """
    Busca solicitação pelo ID.

    Carrega setor, proposta e solicitacao_titulos → titulo → setor eagerly.
    """
    result = await session.execute(
        select(SolicitacaoVinculacao)
        .where(SolicitacaoVinculacao.id == solicitacao_id)
        .options(
            selectinload(SolicitacaoVinculacao.setor),
            selectinload(SolicitacaoVinculacao.proposta),
            selectinload(SolicitacaoVinculacao.solicitacao_titulos).selectinload(
                SolicitacaoTitulos.titulo
            ).selectinload(TituloCepac.setor),
        )
    )
    return result.scalar_one_or_none()


async def listar_paginado(
    session: AsyncSession,
    setor_nome: Optional[str] = None,
    status: Optional[StatusSolicitacaoEnum] = None,
    uso: Optional[UsoEnum] = None,
    origem: Optional[OrigemEnum] = None,
    data_inicio: Optional[str] = None,
    data_fim: Optional[str] = None,
    page: int = 1,
    page_size: int = 20,
) -> tuple[list[SolicitacaoVinculacao], int, int]:
    """
    Lista solicitações com filtros opcionais, paginadas.

    Retorna (items, total, total_pages).
    """
    stmt_base = select(SolicitacaoVinculacao).options(
        selectinload(SolicitacaoVinculacao.setor),
        selectinload(SolicitacaoVinculacao.proposta),
    )
    count_base = select(func.count()).select_from(SolicitacaoVinculacao)

    if setor_nome is not None:
        stmt_base = stmt_base.join(Setor, Setor.id == SolicitacaoVinculacao.setor_id).where(
            Setor.nome == setor_nome
        )
        count_base = count_base.join(Setor, Setor.id == SolicitacaoVinculacao.setor_id).where(
            Setor.nome == setor_nome
        )

    if status is not None:
        stmt_base = stmt_base.where(SolicitacaoVinculacao.status == status)
        count_base = count_base.where(SolicitacaoVinculacao.status == status)

    if uso is not None:
        stmt_base = stmt_base.where(SolicitacaoVinculacao.uso == uso)
        count_base = count_base.where(SolicitacaoVinculacao.uso == uso)

    if origem is not None:
        stmt_base = stmt_base.where(SolicitacaoVinculacao.origem == origem)
        count_base = count_base.where(SolicitacaoVinculacao.origem == origem)

    if data_inicio is not None:
        stmt_base = stmt_base.where(SolicitacaoVinculacao.created_at >= data_inicio)
        count_base = count_base.where(SolicitacaoVinculacao.created_at >= data_inicio)

    if data_fim is not None:
        stmt_base = stmt_base.where(SolicitacaoVinculacao.created_at <= data_fim)
        count_base = count_base.where(SolicitacaoVinculacao.created_at <= data_fim)

    total_result = await session.execute(count_base)
    total = total_result.scalar_one()

    offset = (page - 1) * page_size
    stmt_base = stmt_base.order_by(SolicitacaoVinculacao.created_at.desc()).limit(page_size).offset(offset)

    result = await session.execute(stmt_base)
    items = list(result.scalars().all())

    total_pages = max(1, math.ceil(total / page_size))
    return items, total, total_pages


# ---------------------------------------------------------------------------
# Cancelamento
# ---------------------------------------------------------------------------

async def cancelar(
    session: AsyncSession,
    solicitacao: SolicitacaoVinculacao,
) -> None:
    """
    Marca a solicitação como CANCELADA.

    Não faz commit nem libera os títulos — responsabilidade da rota.
    """
    solicitacao.status = StatusSolicitacaoEnum.CANCELADA


# ---------------------------------------------------------------------------
# Proposta por código
# ---------------------------------------------------------------------------

async def buscar_proposta_por_codigo(
    session: AsyncSession,
    codigo: str,
) -> Optional[Proposta]:
    """
    Busca proposta pelo código (ex: AE-0183).

    Carrega setor eagerly. Retorna None se não encontrada.
    """
    result = await session.execute(
        select(Proposta)
        .where(Proposta.codigo == codigo)
        .options(selectinload(Proposta.setor))
    )
    return result.scalar_one_or_none()


# ---------------------------------------------------------------------------
# Títulos DISPONIVEL (query ORM direta para expor o campo codigo)
# ---------------------------------------------------------------------------

async def listar_titulos_disponiveis(
    session: AsyncSession,
    setor_nome: Optional[str] = None,
    uso: Optional[str] = None,
    origem: Optional[str] = None,
) -> list[TituloCepac]:
    """
    Retorna títulos em estado DISPONIVEL com filtros opcionais.

    Retorna modelos ORM (não DTO) para expor o campo `codigo`.
    """
    stmt = (
        select(TituloCepac)
        .where(TituloCepac.estado == EstadoTituloEnum.DISPONIVEL)
        .options(selectinload(TituloCepac.setor))
        .order_by(TituloCepac.created_at.asc())
    )

    if setor_nome is not None:
        stmt = stmt.join(Setor, Setor.id == TituloCepac.setor_id).where(
            Setor.nome == setor_nome
        )

    if uso is not None:
        stmt = stmt.where(TituloCepac.uso == uso)

    if origem is not None:
        stmt = stmt.where(TituloCepac.origem == origem)

    result = await session.execute(stmt)
    return list(result.scalars().all())


# ---------------------------------------------------------------------------
# Busca de setor por nome (auxiliar)
# ---------------------------------------------------------------------------

async def buscar_setor_por_nome(
    session: AsyncSession,
    nome: str,
) -> Optional[Setor]:
    """Busca setor pelo nome exato. Retorna None se não encontrado."""
    result = await session.execute(
        select(Setor).where(Setor.nome == nome)
    )
    return result.scalar_one_or_none()
