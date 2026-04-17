"""
Enumerações Python para os tipos ENUM nativos do PostgreSQL.

Todos os enums são mapeados com SAEnum(..., native_enum=True) nos modelos,
garantindo que o banco use os tipos ENUM definidos na migration.
"""
import enum


class UsoEnum(str, enum.Enum):
    """Uso do título/solicitação: Residencial ou Não-Residencial."""
    R = "R"
    NR = "NR"


class OrigemEnum(str, enum.Enum):
    """Origem do título: ACA (Agente de Custódia) ou NUVEM (plataforma digital)."""
    ACA = "ACA"
    NUVEM = "NUVEM"


class EstadoTituloEnum(str, enum.Enum):
    """Estado de ciclo de vida de um título CEPAC."""
    DISPONIVEL = "DISPONIVEL"
    EM_ANALISE = "EM_ANALISE"
    CONSUMIDO = "CONSUMIDO"
    QUARENTENA = "QUARENTENA"


class StatusSolicitacaoEnum(str, enum.Enum):
    """Status de uma solicitação de vinculação."""
    PENDENTE = "PENDENTE"
    APROVADA = "APROVADA"
    REJEITADA = "REJEITADA"
    CANCELADA = "CANCELADA"


# ---------------------------------------------------------------------------
# Fase 2
# ---------------------------------------------------------------------------

class StatusPaEnum(str, enum.Enum):
    """Status do processo administrativo de uma proposta."""
    DEFERIDO = "DEFERIDO"
    INDEFERIDO = "INDEFERIDO"
    ANALISE = "ANALISE"


class RequerimentoEnum(str, enum.Enum):
    """Tipo de requerimento da proposta."""
    VINCULACAO = "VINCULACAO"
    ALTERACAO = "ALTERACAO"
    DESVINCULACAO = "DESVINCULACAO"


class TipoCertidaoEnum(str, enum.Enum):
    """Tipo de certidão emitida."""
    VINCULACAO = "VINCULAÇÃO"
    DESVINCULACAO = "DESVINCULAÇÃO"
    ALTERACAO = "ALTERAÇÃO"


class SituacaoCertidaoEnum(str, enum.Enum):
    """Situação de uma certidão."""
    VALIDA = "VALIDA"
    CANCELADA = "CANCELADA"


class PapelUsuarioEnum(str, enum.Enum):
    """Papel do usuário autenticado via Azure AD."""
    TECNICO = "TECNICO"
    DIRETOR = "DIRETOR"


class TipoProcessoEnum(str, enum.Enum):
    """Tipo de processo administrativo (padrão histórico)."""
    SIMPROC = "SIMPROC"
    SEI = "SEI"
