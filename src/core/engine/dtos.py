"""
DTOs (Data Transfer Objects) do motor de regras CEPAC.

Todos os tipos são dataclasses imutáveis (frozen=True) sem dependência de ORM,
FastAPI ou qualquer I/O. O RulesEngine recebe estes objetos como parâmetros e
nunca acessa o banco diretamente.
"""
from dataclasses import dataclass, field
from decimal import Decimal
from datetime import datetime
from uuid import UUID
from typing import Literal, Optional


@dataclass(frozen=True)
class TituloDTO:
    """Snapshot de um título CEPAC para validação. Sem dependência de ORM."""
    id: UUID
    setor: str
    uso: Literal["R", "NR", "MISTO"]
    origem: Literal["ACA", "NUVEM"]
    estado: Literal["DISPONIVEL", "EM_ANALISE", "CONSUMIDO", "QUARENTENA"]
    valor_m2: Decimal
    data_desvinculacao: Optional[datetime] = None


@dataclass(frozen=True)
class SaldoSetorDTO:
    """
    Saldo acumulado de um setor, pré-calculado pelo repositório a partir de movimentacao.
    O RulesEngine nunca acessa o banco — recebe este DTO como parâmetro.
    """
    setor: str
    nr_consumido_aca: Decimal       # NR em estado CONSUMIDO, origem ACA
    nr_consumido_nuvem: Decimal     # NR em estado CONSUMIDO, origem NUVEM
    nr_em_analise: Decimal          # NR em estado EM_ANALISE (qualquer origem)
    r_consumido_aca: Decimal        # R em estado CONSUMIDO, origem ACA
    r_consumido_nuvem: Decimal      # R em estado CONSUMIDO, origem NUVEM
    r_em_analise: Decimal           # R em estado EM_ANALISE (qualquer origem)
    consumo_total_global: Decimal   # Soma total de todos os setores (para validação de capacidade global)

    @property
    def nr_total_comprometido(self) -> Decimal:
        """NR comprometido: consumido (ACA + NUVEM) + em análise."""
        return self.nr_consumido_aca + self.nr_consumido_nuvem + self.nr_em_analise

    @property
    def r_total_consumido(self) -> Decimal:
        """R consumido: ACA + NUVEM (excluindo em análise)."""
        return self.r_consumido_aca + self.r_consumido_nuvem


@dataclass(frozen=True)
class SolicitacaoDTO:
    """Dados de uma solicitação de vinculação submetida ao motor de regras."""
    setor: str
    uso: Literal["R", "NR", "MISTO"]
    origem: Literal["ACA", "NUVEM"]
    area_m2: Decimal
    numero_processo_sei: str
    titulo_ids: list[UUID]
    titulos: list[TituloDTO]        # snapshots dos títulos do lote
    saldo_setor: SaldoSetorDTO      # pré-calculado pelo repositório

    @property
    def area_nr_m2(self) -> Decimal:
        """
        Parcela NR efectiva desta solicitação.

        - uso == "NR"   → 100% da área
        - uso == "MISTO" → 50% da área (divisão igualitária R+NR)
        - uso == "R"    → 0
        """
        if self.uso == "NR":
            return self.area_m2
        if self.uso == "MISTO":
            return (self.area_m2 / 2).quantize(Decimal("0.01"))
        return Decimal("0.00")

    @property
    def area_r_m2(self) -> Decimal:
        """
        Parcela R efectiva desta solicitação.

        - uso == "R"    → 100% da área
        - uso == "MISTO" → 50% da área (divisão igualitária R+NR)
        - uso == "NR"   → 0
        """
        if self.uso == "R":
            return self.area_m2
        if self.uso == "MISTO":
            return (self.area_m2 / 2).quantize(Decimal("0.01"))
        return Decimal("0.00")


@dataclass
class RulesError(Exception):
    """Erro de negócio retornado pelo motor de regras."""
    codigo: str           # Ex: "TETO_NR_EXCEDIDO"
    mensagem: str
    setor: Optional[str] = None
    saldo_atual: Optional[Decimal] = None
    limite: Optional[Decimal] = None
    dias_restantes: Optional[int] = None   # para QUARENTENA_ATIVA

    def __str__(self) -> str:
        return f"[{self.codigo}] {self.mensagem}"


@dataclass
class ValidationResult:
    """Resultado da validação pelo motor de regras."""
    aprovado: bool
    erro: Optional[RulesError] = None
