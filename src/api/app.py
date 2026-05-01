"""
FastAPI app factory para o sistema CEPAC.

Exporta `app` para uso em `main.py` e nos testes de integração.

Registra todos os routers e configura handlers de exceção globais
para garantir respostas padronizadas em erros de validação Pydantic.

O lifespan gerencia o job de expiração TTL de reservas EM_ANALISE,
executado em background a cada 30 minutos via asyncio nativo.
"""
import asyncio
import logging
from contextlib import asynccontextmanager
from typing import TYPE_CHECKING, AsyncGenerator, Optional

if TYPE_CHECKING:
    from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

import sqlalchemy
from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from src.api.routes import admin, certidoes, dashboard, documentos, medicoes, movimentacoes, portal, saldo, solicitacoes, titulos
from src.config import settings

logger = logging.getLogger(__name__)

# --------------------------------------------------------------------------- #
# Configuração de logging baseada em settings.log_level                        #
# --------------------------------------------------------------------------- #

logging.basicConfig(
    level=getattr(logging, settings.log_level.upper(), logging.INFO),
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
)

# --------------------------------------------------------------------------- #
# Sessão de banco para uso no job (fora do ciclo de request/response)          #
# --------------------------------------------------------------------------- #


async def _get_async_session() -> AsyncGenerator:
    """
    Cria e retorna um context manager de AsyncSession reutilizando o engine
    já configurado em dependencies.py, evitando duplicação de configuração.
    """
    from src.api.dependencies import _AsyncSessionLocal as _SLF

    async with _SLF() as session:
        yield session


# --------------------------------------------------------------------------- #
# Loop do job de expiração TTL                                                  #
# --------------------------------------------------------------------------- #


async def _run_expiry_job_loop() -> None:
    """
    Executa o job de expiração a cada 30 minutos.

    Nunca propaga exceções — erros são logados e o loop continua,
    garantindo que o job jamais derrube a aplicação.
    """
    from src.core.jobs.expiry_job import expirar_reservas

    while True:
        try:
            assert _AsyncSessionLocal is not None
            async with _AsyncSessionLocal() as session:
                count = await expirar_reservas(session)
                if count > 0:
                    logger.info(
                        "Job TTL: %d título(s) EM_ANALISE expirado(s) e revertido(s) para DISPONIVEL.",
                        count,
                    )
        except Exception:
            logger.exception("Erro no job de expiração TTL — continuando o loop.")
        await asyncio.sleep(30 * 60)  # 30 minutos


def _get_session_local():
    """Importação lazy para evitar ciclo de importação no topo do módulo."""
    from src.api.dependencies import _AsyncSessionLocal

    return _AsyncSessionLocal


# Referência ao session maker — resolvida uma única vez no lifespan
_AsyncSessionLocal: Optional["async_sessionmaker[AsyncSession]"] = None


# --------------------------------------------------------------------------- #
# Lifespan — startup / shutdown                                                 #
# --------------------------------------------------------------------------- #


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Gerencia o ciclo de vida da aplicação FastAPI.

    Startup:
        - Importa _AsyncSessionLocal do módulo de dependências.
        - Inicia o job de expiração TTL como task asyncio em background.

    Shutdown:
        - Cancela a task do job graciosamente.
    """
    global _AsyncSessionLocal

    # Importação no startup para garantir que settings já foram carregados
    from src.api.dependencies import _AsyncSessionLocal as _session_local

    _AsyncSessionLocal = _session_local

    # Pré-aquece o pool: exercita UUID/Numeric/Enum para forçar OID cache do asyncpg
    from src.api.dependencies import _AsyncSessionLocal as _SL
    import sys

    _WARMUP_SQL = sqlalchemy.text(
        "SELECT p.id, p.codigo, p.status_pa, p.cepac_total, p.setor_id, "
        "c.id, c.tipo, c.situacao, c.cepac_total, c.aca_r_m2 "
        "FROM proposta p "
        "LEFT JOIN certidao c ON c.proposta_id = p.id "
        "LIMIT 3"
    )

    async def _warm_worker():
        async with _SL() as s:
            await s.execute(_WARMUP_SQL)

    try:
        results = await asyncio.gather(*[_warm_worker() for _ in range(3)], return_exceptions=True)
        erros = [r for r in results if isinstance(r, Exception)]
        if erros:
            print(f"[CEPAC] pre-warming erros: {erros}", file=sys.stderr, flush=True)
        else:
            print("[CEPAC] pool pre-aquecido (UUID+Numeric+Enum).", file=sys.stderr, flush=True)
    except Exception as exc:
        print(f"[CEPAC] falha no pre-warming: {exc}", file=sys.stderr, flush=True)

    logger.info("CEPAC: iniciando job de expiração TTL em background.")
    task = asyncio.create_task(_run_expiry_job_loop())

    yield  # aplicação rodando

    # Shutdown
    logger.info("CEPAC: encerrando job de expiração TTL.")
    task.cancel()
    try:
        await task
    except asyncio.CancelledError:
        pass


# --------------------------------------------------------------------------- #
# Instância principal da aplicação                                              #
# --------------------------------------------------------------------------- #

app = FastAPI(
    title="CEPAC — Sistema de Controle de Estoque",
    description=(
        "API REST para gestão do ciclo de vida dos títulos CEPAC da "
        "Operação Urbana Consorciada Água Espraiada (OUCAE). "
        "SP Urbanismo / Prodam."
    ),
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

# --------------------------------------------------------------------------- #
# CORS                                                                          #
# --------------------------------------------------------------------------- #

_cors_origins = [o.strip() for o in settings.cors_origins.split(",")]

app.add_middleware(
    CORSMiddleware,
    allow_origins=_cors_origins,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type"],
)

# --------------------------------------------------------------------------- #
# Registro dos routers                                                          #
# --------------------------------------------------------------------------- #

app.include_router(admin.router)
app.include_router(solicitacoes.router)
app.include_router(saldo.router)
app.include_router(movimentacoes.router)
app.include_router(titulos.router)
app.include_router(documentos.router)
app.include_router(certidoes.router)
app.include_router(portal.router)
app.include_router(dashboard.router)
app.include_router(medicoes.router)


# --------------------------------------------------------------------------- #
# Handler de exceção para erros de validação Pydantic (422 nativo do FastAPI)  #
# --------------------------------------------------------------------------- #

@app.exception_handler(422)
async def validation_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    """
    Intercepta erros de validação do schema Pydantic e verifica se o campo
    `numero_processo_sei` está ausente ou vazio, retornando o código de erro
    padronizado NUMERO_SEI_OBRIGATORIO.
    """
    from fastapi.exceptions import RequestValidationError

    if isinstance(exc, RequestValidationError):
        for error in exc.errors():
            loc = error.get("loc", ())
            field = loc[-1] if loc else ""
            if field == "numero_processo_sei":
                return JSONResponse(
                    status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                    content={
                        "codigo_erro": "NUMERO_SEI_OBRIGATORIO",
                        "mensagem": "O campo numero_processo_sei é obrigatório e não pode ser vazio.",
                        "setor": None,
                        "saldo_atual": None,
                        "limite": None,
                    },
                )
        # Outros erros de validação: retornar no formato padrão
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            content={"detail": exc.errors()},
        )

    # Respostas 422 já formatadas pelas rotas (ErroNegocioOut) — preserva dict
    from fastapi import HTTPException as _HTTPException
    if isinstance(exc, _HTTPException) and isinstance(exc.detail, dict):
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            content={"detail": exc.detail},
        )
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={"detail": str(exc)},
    )


# --------------------------------------------------------------------------- #
# Health check                                                                  #
# --------------------------------------------------------------------------- #

@app.get("/health", tags=["infra"], summary="Health check")
async def health() -> dict:
    """Retorna status da aplicação (usado por load balancer / k8s probes)."""
    return {"status": "ok"}
