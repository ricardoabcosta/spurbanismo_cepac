"""
Repositórios de acesso ao banco de dados.

Encapsulam todas as queries SQLAlchemy. Nunca contêm lógica de negócio —
apenas acesso a dados e mapeamento para DTOs.
"""
from .saldo_repository import calcular_saldo
from .titulo_repository import (
    get_titulos_by_ids,
    transicionar_estado,
    get_historico,
    list_titulos,
)

__all__ = [
    "calcular_saldo",
    "get_titulos_by_ids",
    "transicionar_estado",
    "get_historico",
    "list_titulos",
]
