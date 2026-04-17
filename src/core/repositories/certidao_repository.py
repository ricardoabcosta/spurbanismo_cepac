"""
CertidaoRepository — consultas de autenticidade de certidões (T14).

Todas as funções recebem AsyncSession e retornam modelos ORM ou None.
Sem lógica de negócio — apenas acesso a dados.
"""
from __future__ import annotations

from typing import Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from src.core.models.certidao import Certidao
from src.core.models.enums import SituacaoCertidaoEnum, TipoCertidaoEnum
from src.core.models.proposta import Proposta
from src.core.models.setor import Setor


async def buscar_por_numero(
    session: AsyncSession,
    numero_certidao: str,
) -> Optional[Certidao]:
    """
    Busca certidão pelo número exato (case-sensitive).

    Carrega proposta → setor eagerly para evitar N+1 no endpoint público.
    Retorna None se não encontrada.
    """
    result = await session.execute(
        select(Certidao)
        .where(Certidao.numero_certidao == numero_certidao)
        .options(
            selectinload(Certidao.proposta).selectinload(Proposta.setor)
        )
    )
    return result.scalar_one_or_none()


async def listar_com_filtros(
    session: AsyncSession,
    tipo: Optional[TipoCertidaoEnum] = None,
    ano: Optional[int] = None,
    situacao: Optional[SituacaoCertidaoEnum] = None,
    limit: int = 100,
    offset: int = 0,
) -> list[Certidao]:
    """
    Lista certidões com filtros opcionais.

    Carrega proposta → setor eagerly para evitar N+1 na listagem.
    Ordenadas por data_emissao DESC, numero_certidao ASC como desempate.
    """
    stmt = (
        select(Certidao)
        .options(
            selectinload(Certidao.proposta).selectinload(Proposta.setor)
        )
        .order_by(Certidao.data_emissao.desc().nulls_last(), Certidao.numero_certidao.asc())
        .limit(limit)
        .offset(offset)
    )

    if tipo is not None:
        stmt = stmt.where(Certidao.tipo == tipo)

    if situacao is not None:
        stmt = stmt.where(Certidao.situacao == situacao)

    if ano is not None:
        # Filtra pelo ano de emissão; registros sem data_emissao são excluídos
        stmt = stmt.where(
            Certidao.data_emissao.isnot(None),
        ).where(
            Certidao.data_emissao >= f"{ano}-01-01",
            Certidao.data_emissao <= f"{ano}-12-31",
        )

    result = await session.execute(stmt)
    return list(result.scalars().all())
