"""
Rotas de certidões (T14) — Consulta Pública de Autenticidade.

Endpoints públicos (sem autenticação): acessíveis pelo munícipe.
Endpoint restrito: dados completos da proposta (TECNICO/DIRETOR).

O número da certidão usa barra como separador (ex: AE-001/2024),
que na URL deve ser codificado como %2F — FastAPI decodifica automaticamente.
"""
from typing import Annotated, Literal, Optional

from fastapi import APIRouter, Depends, HTTPException, Path, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.auth.dependencies import UsuarioAutenticado, require_tecnico
from src.api.dependencies import get_db
from src.api.schemas.certidao import (
    CertidaoComPropostaOut,
    CertidaoListaOut,
    CertidaoPublicaOut,
    PropostaResumidaOut,
)
from src.core.models.enums import SituacaoCertidaoEnum, TipoCertidaoEnum
from src.core.repositories import certidao_repository

router = APIRouter(prefix="/certidoes", tags=["certidoes"])


def _autenticidade(situacao: SituacaoCertidaoEnum) -> Literal["CERTIDÃO AUTÊNTICA", "CERTIDÃO CANCELADA"]:
    """Mapeia situação da certidão para o texto de autenticidade."""
    if situacao == SituacaoCertidaoEnum.VALIDA:
        return "CERTIDÃO AUTÊNTICA"
    return "CERTIDÃO CANCELADA"


# ---------------------------------------------------------------------------
# ATENÇÃO: ordem das rotas é crítica.
# A rota /{:path}/proposta DEVE ser registrada ANTES de /{:path}, pois
# Starlette faz matching em ordem de definição e {numero_certidao:path}
# consome tudo, incluindo "/proposta" no final.
# ---------------------------------------------------------------------------

@router.get(
    "/{numero_certidao:path}/proposta",
    response_model=CertidaoComPropostaOut,
    status_code=status.HTTP_200_OK,
    summary="Dados completos da proposta vinculada à certidão (TECNICO)",
    description="Retorna dados completos da proposta, incluindo interessado e CNPJ. Requer autenticação.",
)
async def obter_proposta_da_certidao(
    numero_certidao: Annotated[
        str,
        Path(description="Número da certidão (ex: AE-001%2F2024)"),
    ],
    session: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[UsuarioAutenticado, Depends(require_tecnico)],
) -> CertidaoComPropostaOut:
    """
    Retorna certidão com dados completos da proposta vinculada.

    Requer papel TECNICO ou DIRETOR. Expõe interessado, CNPJ/CPF e endereço.
    """
    certidao = await certidao_repository.buscar_por_numero(session, numero_certidao)
    if certidao is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Certidão '{numero_certidao}' não encontrada.",
        )

    proposta = certidao.proposta
    setor = proposta.setor

    proposta_out = PropostaResumidaOut(
        id=proposta.id,
        codigo=proposta.codigo,
        numero_pa=proposta.numero_pa,
        tipo_processo=proposta.tipo_processo.value if proposta.tipo_processo else None,
        data_autuacao=proposta.data_autuacao,
        status_pa=proposta.status_pa.value,
        interessado=proposta.interessado,
        cnpj_cpf=proposta.cnpj_cpf,
        endereco=proposta.endereco,
        setor=setor.nome,
        requerimento=proposta.requerimento.value,
        area_terreno_m2=float(proposta.area_terreno_m2) if proposta.area_terreno_m2 else None,
        observacao_alteracao=proposta.observacao_alteracao,
        created_at=proposta.created_at,
        updated_at=proposta.updated_at,
    )

    return CertidaoComPropostaOut(
        numero_certidao=certidao.numero_certidao,
        tipo=certidao.tipo.value,
        data_emissao=certidao.data_emissao,
        situacao=certidao.situacao.value,
        numero_processo_sei=certidao.numero_processo_sei,
        created_at=certidao.created_at,
        proposta=proposta_out,
    )


@router.get(
    "",
    response_model=list[CertidaoListaOut],
    status_code=status.HTTP_200_OK,
    summary="Listar certidões com filtros (público)",
    description="Lista certidões emitidas. Não requer autenticação. Suporta filtros por tipo, ano e situação.",
)
async def listar_certidoes(
    session: Annotated[AsyncSession, Depends(get_db)],
    tipo: Annotated[
        Optional[TipoCertidaoEnum],
        Query(description="Filtrar por tipo: VINCULAÇÃO, ALTERAÇÃO ou DESVINCULAÇÃO"),
    ] = None,
    ano: Annotated[
        Optional[int],
        Query(ge=2004, le=2100, description="Filtrar por ano de emissão"),
    ] = None,
    situacao: Annotated[
        Optional[SituacaoCertidaoEnum],
        Query(description="Filtrar por situação: VALIDA ou CANCELADA"),
    ] = None,
    limit: Annotated[int, Query(ge=1, le=500, description="Máximo de registros")] = 100,
    offset: Annotated[int, Query(ge=0, description="Offset para paginação")] = 0,
) -> list[CertidaoListaOut]:
    certidoes = await certidao_repository.listar_com_filtros(
        session=session,
        tipo=tipo,
        ano=ano,
        situacao=situacao,
        limit=limit,
        offset=offset,
    )
    return [
        CertidaoListaOut(
            numero_certidao=c.numero_certidao,
            tipo=c.tipo.value,
            data_emissao=c.data_emissao,
            situacao=c.situacao.value,
            proposta_codigo=c.proposta.codigo,
            setor=c.proposta.setor.nome,
        )
        for c in certidoes
    ]


@router.get(
    "/{numero_certidao:path}",
    response_model=CertidaoPublicaOut,
    status_code=status.HTTP_200_OK,
    summary="Consultar autenticidade de uma certidão (público)",
    description=(
        "Verifica a autenticidade de uma certidão emitida pela SP Urbanismo. "
        "Não requer autenticação. Não expõe dados pessoais do interessado."
    ),
)
async def consultar_autenticidade(
    numero_certidao: Annotated[
        str,
        Path(
            description="Número da certidão (ex: AE-001/2024 → encode como AE-001%2F2024)"
        ),
    ],
    session: Annotated[AsyncSession, Depends(get_db)],
) -> CertidaoPublicaOut:
    """
    Busca a certidão pelo número exato e retorna o resultado de autenticidade.

    Retorna 404 com `autenticidade: "CERTIDÃO NÃO ENCONTRADA"` se não existir.
    """
    certidao = await certidao_repository.buscar_por_numero(session, numero_certidao)
    if certidao is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={
                "numero_certidao": numero_certidao,
                "autenticidade": "CERTIDÃO NÃO ENCONTRADA",
            },
        )

    return CertidaoPublicaOut(
        numero_certidao=certidao.numero_certidao,
        tipo=certidao.tipo.value,
        data_emissao=certidao.data_emissao,
        situacao=certidao.situacao.value,
        proposta_codigo=certidao.proposta.codigo,
        setor=certidao.proposta.setor.nome,
        autenticidade=_autenticidade(certidao.situacao),
    )
