"""
Motor de regras CEPAC — módulo Python puro.

Exporta as interfaces públicas necessárias para o uso do RulesEngine:
  - RulesEngine     : orquestrador principal
  - SolicitacaoDTO  : dados de entrada da solicitação
  - SaldoSetorDTO   : saldo pré-calculado do setor
  - TituloDTO       : snapshot de um título CEPAC
  - ValidationResult: resultado da validação
  - RulesError      : erro de negócio estruturado

Nenhum símbolo deste módulo depende de SQLAlchemy, FastAPI ou I/O.
"""
from src.core.engine.dtos import (
    RulesError,
    SaldoSetorDTO,
    SolicitacaoDTO,
    TituloDTO,
    ValidationResult,
)
from src.core.engine.rules_engine import RulesEngine

__all__ = [
    "RulesEngine",
    "SolicitacaoDTO",
    "SaldoSetorDTO",
    "TituloDTO",
    "ValidationResult",
    "RulesError",
]
