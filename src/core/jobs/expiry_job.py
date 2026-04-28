"""
Job de expiração automática de reservas temporárias (TTL 48h).

Executa periodicamente e reverte títulos em estado EM_ANALISE
cujo updated_at seja anterior a now() - 48h para estado DISPONIVEL.

Cada reversão gera uma entrada em movimentacao com:
  - motivo = "EXPIRAÇÃO_TTL"
  - operador = "SISTEMA"
  - numero_processo_sei = "SISTEMA-TTL-EXPIRADO"

Idempotente: a query filtra por estado=EM_ANALISE, portanto
executar o job mais de uma vez não produz duplicatas.
"""
import logging
from datetime import datetime, timedelta

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.core.models.enums import EstadoTituloEnum
from src.core.models.titulo_cepac import TituloCepac
from src.core.repositories.titulo_repository import transicionar_estado

logger = logging.getLogger(__name__)

TTL_HORAS = 48


async def expirar_reservas(session: AsyncSession) -> int:
    """
    Busca todos os títulos EM_ANALISE com updated_at < now() - 48h.
    Para cada um:
      1. Atualiza estado para DISPONIVEL
      2. Insere movimentacao com motivo=EXPIRAÇÃO_TTL, operador=SISTEMA

    Retorna a quantidade de títulos expirados.

    Idempotente: o filtro por estado=EM_ANALISE garante que títulos já
    revertidos para DISPONIVEL não serão processados novamente.
    """
    limite = datetime.utcnow() - timedelta(hours=TTL_HORAS)

    stmt = select(TituloCepac).where(
        TituloCepac.estado == EstadoTituloEnum.EM_ANALISE,
        TituloCepac.updated_at < limite,
    )
    result = await session.execute(stmt)
    titulos = result.scalars().all()

    for titulo in titulos:
        await transicionar_estado(
            session=session,
            titulo_id=titulo.id,
            estado_novo="DISPONIVEL",
            numero_processo_sei="SISTEMA-TTL-EXPIRADO",
            operador="SISTEMA",
            motivo="EXPIRAÇÃO_TTL",
        )
        logger.info(
            "Título expirado por TTL: id=%s codigo=%s",
            titulo.id,
            titulo.codigo,
        )

    await session.commit()
    return len(titulos)
