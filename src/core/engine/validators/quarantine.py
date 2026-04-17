"""
Validator de quarentena e disponibilidade de títulos CEPAC.

Regras verificadas para cada título no lote:
  1. Títulos em QUARENTENA só podem ser reutilizados após 180 dias da desvinculação.
  2. Títulos em qualquer estado diferente de DISPONIVEL são rejeitados (EM_ANALISE,
     CONSUMIDO, ou estados inconsistentes).

A verificação percorre todos os títulos do lote e retorna no primeiro erro encontrado.
"""
from datetime import datetime, timezone
from typing import Optional

from src.core.engine.dtos import RulesError, SolicitacaoDTO

DIAS_QUARENTENA = 180


def validar(solicitacao: SolicitacaoDTO) -> Optional[RulesError]:
    """
    Retorna RulesError no primeiro título inválido encontrado, None se todos aprovados.

    Verifica quarentena antes de disponibilidade para fornecer mensagens de erro
    mais precisas (incluindo dias_restantes) quando o título está em quarentena.
    """
    agora = datetime.now(timezone.utc)

    for titulo in solicitacao.titulos:
        if titulo.estado == "QUARENTENA":
            if titulo.data_desvinculacao is None:
                # Inconsistência de dados: título em quarentena sem data de desvinculação
                return RulesError(
                    codigo="QUARENTENA_ATIVA",
                    mensagem=(
                        f"Título {titulo.id} está em quarentena mas não possui "
                        "data de desvinculação registrada. Contate o administrador do sistema."
                    ),
                    setor=solicitacao.setor,
                )

            # Normaliza timezone para comparação segura
            data_desvinc = titulo.data_desvinculacao
            if data_desvinc.tzinfo is None:
                data_desvinc = data_desvinc.replace(tzinfo=timezone.utc)

            dias_em_quarentena = (agora - data_desvinc).days

            if dias_em_quarentena < DIAS_QUARENTENA:
                dias_restantes = DIAS_QUARENTENA - dias_em_quarentena
                return RulesError(
                    codigo="QUARENTENA_ATIVA",
                    mensagem=(
                        f"Título {titulo.id} ainda está em período de quarentena. "
                        f"Restam {dias_restantes} dia(s) para liberação."
                    ),
                    setor=solicitacao.setor,
                    dias_restantes=dias_restantes,
                )

            # Quarentena cumprida — título pode ser reutilizado; continua o loop
            continue

        if titulo.estado != "DISPONIVEL":
            return RulesError(
                codigo="TITULO_INDISPONIVEL",
                mensagem=f"Título {titulo.id} está em estado {titulo.estado}.",
                setor=solicitacao.setor,
            )

    return None
