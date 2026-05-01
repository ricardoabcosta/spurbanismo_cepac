"""
Fixtures compartilhadas para testes de integração CEPAC Fase 2.

Estratégia:
  - PostgreSQL 15 real via testcontainers (session scope).
  - Migrations 001–014 aplicadas uma única vez com asyncpg.
  - Cada teste roda dentro de uma transação revertida no teardown
    (join_transaction_mode="create_savepoint" → commit() vira SAVEPOINT release).
  - get_db e get_current_user são sobrescritos no app via dependency_overrides.
  - Lifespan (job TTL) não é disparado: ASGITransport não chama lifespan.
  - event_loop session-scoped garante que o pool asyncpg do async_engine
    não seja invalidado entre testes (asyncpg amarra o pool ao 1º event loop).

Ordem das migrations (004a DEVE preceder 004):
  001 → 002 → 003 → 004a → 004 → 005 → ... → 014
"""
from __future__ import annotations

# ---------------------------------------------------------------------------
# Variáveis de ambiente para testes — definidas ANTES dos imports que
# carregam src.config.settings (pydantic-settings lê os.environ na
# inicialização; o .env local pode ter DEV_BYPASS_AUTH=true e Ryuk pode
# falhar em ambientes Docker rootless).
# ---------------------------------------------------------------------------
import os
os.environ["DEV_BYPASS_AUTH"] = "false"
os.environ["TESTCONTAINERS_RYUK_DISABLED"] = "true"

import asyncio
from asyncio import AbstractEventLoop
from datetime import datetime, timezone, timedelta
from pathlib import Path
from typing import AsyncGenerator
from uuid import uuid4

import asyncpg
import pytest
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from testcontainers.postgres import PostgresContainer

from src.api.app import app
from src.api.auth.dependencies import UsuarioAutenticado, get_current_user
from src.api.dependencies import get_db
from src.core.models.enums import PapelUsuarioEnum
from src.core.models.usuario import Usuario as UsuarioModel

# ---------------------------------------------------------------------------
# Ordem explícita de migrations (004a precede 004 — ver comentário no arquivo)
# ---------------------------------------------------------------------------

_MIGRATIONS_DIR = Path(__file__).parent.parent.parent / "migrations"

MIGRATION_ORDER = [
    "001_initial_schema.sql",
    "002_seed_abril_2026.sql",
    "003_fase2_schema.sql",
    "004a_revogar_seed_sintetico.sql",
    "004_carga_inicial_real.sql",
    "005_portal_campos.sql",
    "006_seed_medicao_inicial.sql",
    "007_seed_parametros_sistema.sql",
    "008_setor_admin_fields.sql",
    "009_setor_teto_r.sql",
    "010_configuracao_operacao.sql",
    "011_cepac_parametros.sql",
    "012_proposta_campos_planilha.sql",
    "013_certidao_expand.sql",
    "014_limpa_certidoes_formato_invalido.sql",
]


# ---------------------------------------------------------------------------
# Usuários sintéticos para injeção de dependência
# ---------------------------------------------------------------------------

def _make_user(papel: PapelUsuarioEnum, upn: str | None = None) -> UsuarioAutenticado:
    return UsuarioAutenticado(
        id=uuid4(),
        upn=upn or f"test_{papel.value.lower()}@test.spurbanismo.sp.gov.br",
        nome=f"Test {papel.value.title()}",
        papel=papel,
        token_exp=datetime.now(tz=timezone.utc) + timedelta(hours=1),
    )


TECNICO_USER = _make_user(PapelUsuarioEnum.TECNICO)
DIRETOR_USER = _make_user(PapelUsuarioEnum.DIRETOR)


# ---------------------------------------------------------------------------
# Event loop único para toda a sessão de testes
#
# asyncpg amarra o pool de conexões ao event loop do momento da criação.
# pytest-asyncio 0.23 fecha o loop após cada teste por padrão; sem este
# fixture o pool do async_engine (session-scoped) fica preso a um loop
# já fechado a partir do segundo teste.
#
# asyncio.set_event_loop(loop) é necessário no Python 3.12+ porque
# asyncio.get_event_loop() lança RuntimeError quando não há loop corrente.
# pytest-asyncio 0.23 chama get_event_loop() internamente.
# ---------------------------------------------------------------------------

@pytest.fixture(scope="session")
def event_loop() -> AbstractEventLoop:
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    yield loop
    loop.close()
    asyncio.set_event_loop(None)


# ---------------------------------------------------------------------------
# Container PostgreSQL 15 (session scope — criado uma vez por sessão de testes)
# ---------------------------------------------------------------------------

async def _apply_migrations(pg: PostgresContainer) -> None:
    """Aplica todas as migrations no container de teste via asyncpg."""
    conn = await asyncpg.connect(
        host=pg.get_container_host_ip(),
        port=pg.get_exposed_port(5432),
        user=pg.username,
        password=pg.password,
        database=pg.dbname,
    )
    try:
        for name in MIGRATION_ORDER:
            sql = (_MIGRATIONS_DIR / name).read_text(encoding="utf-8")
            await conn.execute(sql)
    finally:
        await conn.close()


@pytest.fixture(scope="session")
def pg_container(event_loop: AbstractEventLoop):
    """
    Inicia o container PostgreSQL 15 e aplica todas as migrations.
    Compartilhado por toda a sessão de testes — teardown automático ao final.

    Depende explicitamente de event_loop para garantir que o loop de sessão
    esteja definido antes de qualquer chamada asyncio (Python 3.12+).
    """
    with PostgresContainer("postgres:15-alpine") as pg:
        event_loop.run_until_complete(_apply_migrations(pg))
        yield pg


@pytest.fixture(scope="session")
def async_engine(pg_container):
    """Engine SQLAlchemy apontando para o container de teste."""
    url = (
        f"postgresql+asyncpg://{pg_container.username}:{pg_container.password}"
        f"@{pg_container.get_container_host_ip()}"
        f":{pg_container.get_exposed_port(5432)}/{pg_container.dbname}"
    )
    return create_async_engine(url, echo=False, pool_pre_ping=True)


# ---------------------------------------------------------------------------
# Sessão por teste — transação revertida no teardown
# ---------------------------------------------------------------------------

@pytest.fixture
async def db_session(async_engine) -> AsyncGenerator[AsyncSession, None]:
    """
    Fornece uma AsyncSession envolta em transação que é revertida após cada teste.

    join_transaction_mode="create_savepoint" faz com que session.commit() emita
    SAVEPOINT/RELEASE SAVEPOINT em vez de COMMIT real, garantindo isolamento.
    """
    async with async_engine.connect() as conn:
        await conn.begin()
        session = AsyncSession(
            bind=conn,
            expire_on_commit=False,
            autoflush=False,
            join_transaction_mode="create_savepoint",
        )
        try:
            yield session
        finally:
            await session.close()
            await conn.rollback()


# ---------------------------------------------------------------------------
# Helpers de clientes HTTP
# ---------------------------------------------------------------------------

async def _seed_usuario(session: AsyncSession, user: UsuarioAutenticado) -> None:
    """
    Insere o usuário sintético na tabela `usuario` dentro da transação do teste.

    Necessário para que colunas FK como `medicao_obra.operador_id` e
    `solicitacao_vinculacao.tecnico_id` passem na verificação de integridade
    referencial do PostgreSQL (a linha existe na mesma transação, mas não é
    committed — o rollback no teardown do db_session desfaz tudo).
    """
    from sqlalchemy import select as sa_select
    exists = await session.execute(
        sa_select(UsuarioModel).where(UsuarioModel.id == user.id)
    )
    if exists.scalar_one_or_none() is None:
        session.add(UsuarioModel(
            id=user.id,
            upn=user.upn,
            nome=user.nome,
            papel=user.papel,
            ativo=True,
        ))
        await session.flush()


@pytest.fixture
async def client_tecnico(db_session: AsyncSession) -> AsyncGenerator[AsyncClient, None]:
    """Cliente HTTP autenticado como TECNICO."""
    await _seed_usuario(db_session, TECNICO_USER)

    async def _override_db():
        yield db_session

    app.dependency_overrides[get_db] = _override_db
    app.dependency_overrides[get_current_user] = lambda: TECNICO_USER

    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as ac:
        yield ac

    app.dependency_overrides.clear()


@pytest.fixture
async def client_diretor(db_session: AsyncSession) -> AsyncGenerator[AsyncClient, None]:
    """Cliente HTTP autenticado como DIRETOR."""
    await _seed_usuario(db_session, DIRETOR_USER)

    async def _override_db():
        yield db_session

    app.dependency_overrides[get_db] = _override_db
    app.dependency_overrides[get_current_user] = lambda: DIRETOR_USER

    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as ac:
        yield ac

    app.dependency_overrides.clear()


@pytest.fixture
async def client_unauth(db_session: AsyncSession) -> AsyncGenerator[AsyncClient, None]:
    """
    Cliente HTTP sem autenticação.

    Sobrescreve get_db (rotas públicas com DB) mas NÃO sobrescreve
    get_current_user — testa que endpoints protegidos devolvem 401.
    """
    async def _override_db():
        yield db_session

    app.dependency_overrides[get_db] = _override_db
    # get_current_user NÃO é sobrescrito → requests sem token devolvem 401

    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as ac:
        yield ac

    app.dependency_overrides.clear()
