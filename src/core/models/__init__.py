"""
Modelos SQLAlchemy 2.x do projeto CEPAC.

Importar `Base` e todos os modelos por aqui garante que o metadata do SQLAlchemy
esteja completo antes de qualquer operação com o banco (create_all, Alembic, etc.).

Exemplo de uso com Alembic (env.py):

    from src.core.models import Base
    target_metadata = Base.metadata

Exemplo de criação de tabelas em testes:

    from src.core.models import Base
    Base.metadata.create_all(bind=engine)
"""

from .base import Base

# Enums — Fase 1
from .enums import EstadoTituloEnum, OrigemEnum, StatusSolicitacaoEnum, UsoEnum

# Enums — Fase 2
from .enums import (
    PapelUsuarioEnum,
    RequerimentoEnum,
    SituacaoCertidaoEnum,
    StatusPaEnum,
    TipoCertidaoEnum,
    TipoProcessoEnum,
)

# Modelos — Fase 1
from .movimentacao import Movimentacao
from .setor import Setor
from .solicitacao_titulos import SolicitacaoTitulos
from .solicitacao_vinculacao import SolicitacaoVinculacao
from .titulo_cepac import TituloCepac

# Config global
from .configuracao_operacao import ConfiguracaoOperacao

# Modelos — Fase 2
from .certidao import Certidao
from .documento_processo import DocumentoProcesso
from .medicao_obra import MedicaoObra
from .parametro_sistema import ParametroSistema
from .proposta import Proposta
from .usuario import Usuario

__all__ = [
    # Base
    "Base",
    # Enums — Fase 1
    "EstadoTituloEnum",
    "OrigemEnum",
    "StatusSolicitacaoEnum",
    "UsoEnum",
    # Enums — Fase 2
    "PapelUsuarioEnum",
    "RequerimentoEnum",
    "SituacaoCertidaoEnum",
    "StatusPaEnum",
    "TipoCertidaoEnum",
    "TipoProcessoEnum",
    # Modelos — Fase 1 (ordem topológica das dependências)
    "Setor",
    "TituloCepac",
    "SolicitacaoVinculacao",
    "SolicitacaoTitulos",
    "Movimentacao",
    # Modelos — Fase 2 (ordem topológica das dependências)
    "Usuario",
    "Proposta",
    "Certidao",
    "DocumentoProcesso",
    "MedicaoObra",
    "ParametroSistema",
    "ConfiguracaoOperacao",
]
