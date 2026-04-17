"""
Base declarativa para todos os modelos SQLAlchemy do projeto CEPAC.
"""
from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    """
    Classe base de todos os modelos.

    Usa DeclarativeBase do SQLAlchemy 2.x com suporte a type annotations
    (Mapped / mapped_column).
    """
    pass
