"""
RulesEngine — orquestrador principal do motor de regras CEPAC.

Executa os validators na ordem correta para cada setor. A ordem é:
  1. sei          — sempre primeiro (falha rápida, sem cálculos)
  2. capacity     — teto global da operação
  3. <setorial>   — regra de negócio específica do setor
  4. quarantine   — disponibilidade individual de cada título do lote

Setores reconhecidos: Brooklin, Berrini, Marginal Pinheiros,
                       Chucri Zaidan, Jabaquara.

O RulesEngine não acessa banco de dados, não instancia modelos ORM e
não tem dependência de FastAPI. Todos os dados necessários chegam via
SolicitacaoDTO, que carrega SaldoSetorDTO e TituloDTO pré-calculados
pelo repositório.
"""
from src.core.engine.dtos import RulesError, SolicitacaoDTO, ValidationResult
from src.core.engine.validators import (
    berrini,
    brooklin,
    capacity,
    chucri_zaidan,
    jabaquara,
    marginal_pinheiros,
    quarantine,
    sei,
)

# Mapeamento setor → sequência de validators a executar (em ordem)
VALIDATORS_POR_SETOR: dict[str, list] = {
    "Brooklin":          [sei, capacity, brooklin,          quarantine],
    "Berrini":           [sei, capacity, berrini,           quarantine],
    "Marginal Pinheiros":[sei, capacity, marginal_pinheiros, quarantine],
    "Chucri Zaidan":     [sei, capacity, chucri_zaidan,     quarantine],
    "Jabaquara":         [sei, capacity, jabaquara,         quarantine],
}


class RulesEngine:
    """
    Orquestrador de validação de solicitações de vinculação de CEPACs.

    Uso:
        engine = RulesEngine()
        resultado = engine.validar(solicitacao_dto)
        if not resultado.aprovado:
            raise resultado.erro
    """

    def validar(self, solicitacao: SolicitacaoDTO) -> ValidationResult:
        """
        Executa a cadeia de validators do setor e retorna o resultado.

        Retorna ValidationResult(aprovado=True) se todas as regras passarem.
        Retorna ValidationResult(aprovado=False, erro=...) no primeiro erro encontrado.
        Setor não reconhecido retorna SETOR_INVALIDO sem levantar exceção.
        """
        validators = VALIDATORS_POR_SETOR.get(solicitacao.setor)

        if not validators:
            return ValidationResult(
                aprovado=False,
                erro=RulesError(
                    codigo="SETOR_INVALIDO",
                    mensagem=f"Setor '{solicitacao.setor}' não reconhecido.",
                    setor=solicitacao.setor,
                ),
            )

        for validator_module in validators:
            erro = validator_module.validar(solicitacao)
            if erro:
                return ValidationResult(aprovado=False, erro=erro)

        return ValidationResult(aprovado=True)
