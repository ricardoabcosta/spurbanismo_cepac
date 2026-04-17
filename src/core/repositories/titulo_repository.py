"""
TituloRepository — CRUD de títulos CEPAC e registro de movimentações.

Todas as funções recebem uma AsyncSession e retornam DTOs ou modelos ORM.
Sem lógica de negócio — apenas acesso a dados.
"""
from typing import Optional
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from src.core.engine.dtos import TituloDTO
from src.core.models import Movimentacao, Setor, TituloCepac
from src.core.models.enums import EstadoTituloEnum


async def get_titulos_by_ids(
    session: AsyncSession,
    ids: list[UUID],
) -> list[TituloDTO]:
    """
    Retorna DTOs para os títulos com os IDs fornecidos.

    Carrega o relacionamento `setor` eagerly para popular o campo `setor`
    do DTO sem queries N+1.

    Levanta ValueError se algum ID não for encontrado.
    """
    if not ids:
        return []

    stmt = (
        select(TituloCepac)
        .options(selectinload(TituloCepac.setor))
        .where(TituloCepac.id.in_(ids))
    )
    result = await session.execute(stmt)
    titulos = result.scalars().all()

    encontrados = {t.id for t in titulos}
    ausentes = [str(i) for i in ids if i not in encontrados]
    if ausentes:
        raise ValueError(f"Títulos não encontrados: {', '.join(ausentes)}")

    return [_to_dto(t) for t in titulos]


async def transicionar_estado(
    session: AsyncSession,
    titulo_id: UUID,
    estado_novo: str,
    numero_processo_sei: str,
    operador: str,
    motivo: Optional[str] = None,
) -> None:
    """
    Transiciona o estado de um título e registra a movimentação correspondente.

    - Atualiza `titulo_cepac.estado`
    - Insere novo registro em `movimentacao` (append-only)

    Levanta ValueError se o título não for encontrado.
    """
    stmt = (
        select(TituloCepac)
        .options(selectinload(TituloCepac.setor))
        .where(TituloCepac.id == titulo_id)
    )
    result = await session.execute(stmt)
    titulo = result.scalar_one_or_none()

    if titulo is None:
        raise ValueError(f"Título não encontrado: {titulo_id}")

    estado_anterior = titulo.estado
    novo_estado_enum = EstadoTituloEnum(estado_novo)

    titulo.estado = novo_estado_enum

    movimentacao = Movimentacao(
        titulo_id=titulo.id,
        setor_id=titulo.setor_id,
        uso=titulo.uso,
        origem=titulo.origem,
        estado_anterior=estado_anterior,
        estado_novo=novo_estado_enum,
        numero_processo_sei=numero_processo_sei,
        operador=operador,
        motivo=motivo,
    )
    session.add(movimentacao)


async def get_historico(
    session: AsyncSession,
    titulo_id: UUID,
) -> list[Movimentacao]:
    """
    Retorna todas as movimentações de um título em ordem cronológica ascendente.
    """
    stmt = (
        select(Movimentacao)
        .where(Movimentacao.titulo_id == titulo_id)
        .order_by(Movimentacao.created_at.asc())
    )
    result = await session.execute(stmt)
    return list(result.scalars().all())


async def list_titulos(
    session: AsyncSession,
    setor: Optional[str] = None,
    uso: Optional[str] = None,
    origem: Optional[str] = None,
    estado: Optional[str] = None,
) -> list[TituloDTO]:
    """
    Lista títulos CEPAC com filtros opcionais.

    Todos os filtros são aplicados com AND lógico.
    """
    stmt = (
        select(TituloCepac)
        .options(selectinload(TituloCepac.setor))
    )

    if setor is not None:
        stmt = stmt.join(Setor, Setor.id == TituloCepac.setor_id).where(
            Setor.nome == setor
        )

    if uso is not None:
        stmt = stmt.where(TituloCepac.uso == uso)

    if origem is not None:
        stmt = stmt.where(TituloCepac.origem == origem)

    if estado is not None:
        stmt = stmt.where(TituloCepac.estado == estado)

    result = await session.execute(stmt)
    titulos = result.scalars().all()
    return [_to_dto(t) for t in titulos]


# --------------------------------------------------------------------------- #
# Helpers internos                                                              #
# --------------------------------------------------------------------------- #

def _to_dto(titulo: TituloCepac) -> TituloDTO:
    """Converte um modelo ORM TituloCepac para TituloDTO."""
    return TituloDTO(
        id=titulo.id,
        setor=titulo.setor.nome,
        uso=titulo.uso.value,
        origem=titulo.origem.value,
        estado=titulo.estado.value,
        valor_m2=titulo.valor_m2,
        data_desvinculacao=titulo.data_desvinculacao,
    )
