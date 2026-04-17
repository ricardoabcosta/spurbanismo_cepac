"""
Rotas do Dashboard Executivo (T16).

Endpoints de leitura para indicadores consolidados: snapshot geral,
ocupação setorial, alertas e série histórica de medições.

Autenticação:
  - TECNICO, DIRETOR: /snapshot (sem data), /setores, /alertas
  - DIRETOR apenas: /snapshot?data=YYYY-MM-DD (histórico), /medicoes
"""
from datetime import date
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.auth.dependencies import UsuarioAutenticado, require_diretor, require_tecnico
from src.core.models.enums import PapelUsuarioEnum
from src.api.dependencies import get_db
from src.api.schemas.dashboard import (
    AlertaSetorialOut,
    DashboardSnapshotOut,
    MedicaoOut,
    OcupacaoSetorOut,
)
from src.core.repositories import dashboard_repository

router = APIRouter(prefix="/dashboard", tags=["dashboard"])


# ---------------------------------------------------------------------------
# GET /dashboard/snapshot
# ---------------------------------------------------------------------------

@router.get(
    "/snapshot",
    response_model=DashboardSnapshotOut,
    status_code=status.HTTP_200_OK,
    summary="Snapshot de todos os indicadores do Dashboard",
    description=(
        "Retorna big numbers, velocímetro 2029, alertas e ocupação setorial. "
        "Com `?data=YYYY-MM-DD` reconstrói o estado histórico — restrito a DIRETOR."
    ),
)
async def snapshot(
    session: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[UsuarioAutenticado, Depends(require_tecnico)],
    data: Annotated[
        Optional[date],
        Query(description="Data de referência para snapshot histórico (DIRETOR apenas)"),
    ] = None,
) -> DashboardSnapshotOut:
    """
    Snapshot point-in-time quando `data` é informado.

    - Sem `data`: estado atual — TECNICO e DIRETOR.
    - Com `data`: reconstrução histórica — somente DIRETOR.
    """
    if data is not None and current_user.papel != PapelUsuarioEnum.DIRETOR:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Snapshot histórico restrito a DIRETOR.",
        )

    dados = await dashboard_repository.montar_snapshot(session, data)
    return DashboardSnapshotOut(
        gerado_em=dados["gerado_em"],
        custo_total_incorrido=dados["custo_total_incorrido"],
        capacidade_total_operacao=dados["capacidade_total_operacao"],
        saldo_geral_disponivel=dados["saldo_geral_disponivel"],
        cepacs_em_circulacao=dados["cepacs_em_circulacao"],
        prazo_percentual_decorrido=dados["prazo_percentual_decorrido"],
        prazo_dias_restantes=dados["prazo_dias_restantes"],
        prazo_zona=dados["prazo_zona"],
        alertas=[
            AlertaSetorialOut(setor=a.setor, tipo=a.tipo, mensagem=a.mensagem)
            for a in dados["alertas"]
        ],
        setores=[
            OcupacaoSetorOut(
                nome=s.nome,
                estoque_total=s.estoque_total,
                consumido_r=s.consumido_r,
                consumido_nr=s.consumido_nr,
                em_analise_r=s.em_analise_r,
                em_analise_nr=s.em_analise_nr,
                disponivel=s.disponivel,
                percentual_ocupado=s.percentual_ocupado,
                teto_nr=s.teto_nr,
                saldo_nr_liquido=s.saldo_nr_liquido,
                bloqueado_nr=s.bloqueado_nr,
            )
            for s in dados["setores"]
        ],
    )


# ---------------------------------------------------------------------------
# GET /dashboard/setores
# ---------------------------------------------------------------------------

@router.get(
    "/setores",
    response_model=list[OcupacaoSetorOut],
    status_code=status.HTTP_200_OK,
    summary="Ocupação por setor (dados para gráfico de barras)",
)
async def setores(
    session: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[UsuarioAutenticado, Depends(require_tecnico)],
) -> list[OcupacaoSetorOut]:
    """Retorna a ocupação atual de cada setor."""
    setores_orm = await dashboard_repository.buscar_setores(session)
    dtos = await dashboard_repository.calcular_ocupacao_setores(session, setores=setores_orm)
    return [
        OcupacaoSetorOut(
            nome=s.nome,
            estoque_total=s.estoque_total,
            consumido_r=s.consumido_r,
            consumido_nr=s.consumido_nr,
            em_analise_r=s.em_analise_r,
            em_analise_nr=s.em_analise_nr,
            disponivel=s.disponivel,
            percentual_ocupado=s.percentual_ocupado,
            teto_nr=s.teto_nr,
            saldo_nr_liquido=s.saldo_nr_liquido,
            bloqueado_nr=s.bloqueado_nr,
        )
        for s in dtos
    ]


# ---------------------------------------------------------------------------
# GET /dashboard/alertas
# ---------------------------------------------------------------------------

@router.get(
    "/alertas",
    response_model=list[AlertaSetorialOut],
    status_code=status.HTTP_200_OK,
    summary="Travas ativas por setor",
)
async def alertas(
    session: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[UsuarioAutenticado, Depends(require_tecnico)],
) -> list[AlertaSetorialOut]:
    """
    Retorna os alertas de travas ativos (TETO_NR_EXCEDIDO, RESERVA_R_VIOLADA).
    Lista vazia quando não há travas ativas.
    """
    setores_orm = await dashboard_repository.buscar_setores(session)
    ocupacao = await dashboard_repository.calcular_ocupacao_setores(session, setores=setores_orm)
    dtos = dashboard_repository.calcular_alertas(ocupacao, setores_orm)
    return [
        AlertaSetorialOut(setor=a.setor, tipo=a.tipo, mensagem=a.mensagem)
        for a in dtos
    ]


# ---------------------------------------------------------------------------
# GET /dashboard/medicoes
# ---------------------------------------------------------------------------

@router.get(
    "/medicoes",
    response_model=list[MedicaoOut],
    status_code=status.HTTP_200_OK,
    summary="Série histórica de medições de obra (DIRETOR)",
)
async def medicoes(
    session: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[UsuarioAutenticado, Depends(require_diretor)],
) -> list[MedicaoOut]:
    """
    Retorna o histórico completo de medições de obra, ordenado por
    data_referencia descendente. Restrito a DIRETOR.
    """
    registros = await dashboard_repository.listar_medicoes(session)
    return [MedicaoOut.model_validate(m) for m in registros]
