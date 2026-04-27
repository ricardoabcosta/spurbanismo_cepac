"""
Dependências FastAPI injetáveis: sessão de banco e motor de regras.

Autenticação e autorização em src/api/auth/dependencies.py:
  - get_current_user  — valida JWT Azure AD, upsert em usuario, retorna UsuarioAutenticado
  - require_tecnico   — TECNICO ou DIRETOR
  - require_diretor   — somente DIRETOR

A função get_operador() foi removida na Fase 2 (T12).
Achado T8-1 corrigido: qualquer falha de autenticação resulta em 401,
nunca em degradação silenciosa para "desconhecido".
"""
from typing import AsyncGenerator

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from src.config import settings
from src.core.engine.rules_engine import RulesEngine

# --------------------------------------------------------------------------- #
# Engine SQLAlchemy (singleton de módulo)                                      #
# --------------------------------------------------------------------------- #

# pool_size=5 conexões persistentes + max_overflow=10 conexões extras sob carga.
_engine = create_async_engine(
    settings.database_url,
    echo=False,
    pool_pre_ping=False,
    pool_size=5,
    max_overflow=10,
    pool_recycle=1800,
)

_AsyncSessionLocal = async_sessionmaker(
    bind=_engine,
    expire_on_commit=False,
    autoflush=False,
    autocommit=False,
)

# --------------------------------------------------------------------------- #
# Dependências FastAPI                                                          #
# --------------------------------------------------------------------------- #


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """Provê uma AsyncSession por requisição."""
    async with _AsyncSessionLocal() as session:
        try:
            yield session
        except Exception:
            await session.rollback()
            raise


def get_rules_engine() -> RulesEngine:
    """
    Provê uma instância do RulesEngine.

    O RulesEngine é stateless — uma nova instância por requisição é leve e segura.
    """
    return RulesEngine()
