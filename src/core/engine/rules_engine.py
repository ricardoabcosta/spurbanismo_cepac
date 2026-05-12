"""
RulesEngine — orquestrador principal do motor de regras CEPAC.

Executa os validators na ordem correta para cada setor. A ordem é:
  1. sei               — sempre primeiro (falha rápida, sem cálculos)
  2. capacity          — teto global NR da operação (lido de lei_ouc.estoque_geral_m2)
  3. <setorial>        — regra de negócio específica do setor
  4. r_nao_incentivado — teto R Não Incentivado cross-setor (OUCAB — no-op para demais OUCs)
  5. quarantine        — disponibilidade individual de cada título do lote

Setores reconhecidos:
  OUCAE: Brooklin, Berrini, Marginal Pinheiros, Chucri Zaidan, Jabaquara
  OUCFL: Hélio Pelegrino, Faria Lima, Pinheiros, Olimpíadas
  OUCAB: Setor A, Setor A1, Setor A2, Setor A3,
          Setor B, Setor C, Setor D,
          Setor E, Setor E1, Setor E2,
          Setor F, Setor F1, Setor F2,
          Setor G, Setor H,
          Setor I, Setor I1, Setor I2

O RulesEngine não acessa banco de dados, não instancia modelos ORM e
não tem dependência de FastAPI. Todos os dados necessários chegam via
SolicitacaoDTO, que carrega SaldoSetorDTO, LimitesOucDTO e TituloDTO
pré-calculados pelo repositório.
"""
from src.core.engine.dtos import RulesError, SolicitacaoDTO, ValidationResult
from src.core.engine.validators import (
    berrini,
    brooklin,
    capacity,
    chucri_zaidan,
    jabaquara,
    marginal_pinheiros,
    oucab_setor,
    quarantine,
    r_nao_incentivado,
    sei,
)

# Mapeamento setor → sequência de validators a executar (em ordem)
VALIDATORS_POR_SETOR: dict[str, list] = {
    # OUCAE — Água Espraiada
    "Brooklin":          [sei, capacity, brooklin,           quarantine],
    "Berrini":           [sei, capacity, berrini,            quarantine],
    "Marginal Pinheiros":[sei, capacity, marginal_pinheiros, quarantine],
    "Chucri Zaidan":     [sei, capacity, chucri_zaidan,      quarantine],
    "Jabaquara":         [sei, capacity, jabaquara,          quarantine],

    # OUCFL — Faria Lima (sem regras setoriais específicas além de SEI + quarentena)
    "Hélio Pelegrino":   [sei, quarantine],
    "Faria Lima":        [sei, quarantine],
    "Pinheiros":         [sei, quarantine],
    "Olimpíadas":        [sei, quarantine],

    # OUCAB — Água Branca
    # capacity: no-op efetivo (teto 1.85M excede consumo NR máximo de 500k)
    # oucab_setor: tetos R e NR por setor (setor_estoque_lei)
    # r_nao_incentivado: teto cross-setor de 675.000 m² para R Não-Incentivado
    "Setor A":           [sei, capacity, oucab_setor, r_nao_incentivado, quarantine],
    "Setor A1":          [sei, capacity, oucab_setor, r_nao_incentivado, quarantine],
    "Setor A2":          [sei, capacity, oucab_setor, r_nao_incentivado, quarantine],
    "Setor A3":          [sei, capacity, oucab_setor, r_nao_incentivado, quarantine],
    "Setor B":           [sei, capacity, oucab_setor, r_nao_incentivado, quarantine],
    "Setor C":           [sei, capacity, oucab_setor, r_nao_incentivado, quarantine],
    "Setor D":           [sei, capacity, oucab_setor, r_nao_incentivado, quarantine],
    "Setor E":           [sei, capacity, oucab_setor, r_nao_incentivado, quarantine],
    "Setor E1":          [sei, capacity, oucab_setor, r_nao_incentivado, quarantine],
    "Setor E2":          [sei, capacity, oucab_setor, r_nao_incentivado, quarantine],
    "Setor F":           [sei, capacity, oucab_setor, r_nao_incentivado, quarantine],
    "Setor F1":          [sei, capacity, oucab_setor, r_nao_incentivado, quarantine],
    "Setor F2":          [sei, capacity, oucab_setor, r_nao_incentivado, quarantine],
    "Setor G":           [sei, capacity, oucab_setor, r_nao_incentivado, quarantine],
    "Setor H":           [sei, capacity, oucab_setor, r_nao_incentivado, quarantine],
    "Setor I":           [sei, capacity, oucab_setor, r_nao_incentivado, quarantine],
    "Setor I1":          [sei, capacity, oucab_setor, r_nao_incentivado, quarantine],
    "Setor I2":          [sei, capacity, oucab_setor, r_nao_incentivado, quarantine],
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
