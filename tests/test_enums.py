"""
Testes unitários para src/core/models/enums.py.

Verificações:
- UsoEnum.MISTO existe e vale "MISTO"
- StatusSolicitacaoEnum.EM_ANALISE existe e vale "EM_ANALISE"
"""
import pytest

from src.core.models.enums import StatusSolicitacaoEnum, UsoEnum


class TestUsoEnum:
    def test_misto_existe(self):
        assert hasattr(UsoEnum, "MISTO"), "UsoEnum deve ter o membro MISTO"

    def test_misto_valor_string(self):
        assert UsoEnum.MISTO == "MISTO"

    def test_misto_value_attribute(self):
        assert UsoEnum.MISTO.value == "MISTO"

    def test_misto_e_str(self):
        """UsoEnum herda de str — deve comparar diretamente com string."""
        assert isinstance(UsoEnum.MISTO, str)

    def test_r_e_nr_continuam_presentes(self):
        """Regressão: membros existentes não foram removidos."""
        assert UsoEnum.R == "R"
        assert UsoEnum.NR == "NR"

    def test_todos_os_membros(self):
        nomes = {m.name for m in UsoEnum}
        assert nomes == {"R", "NR", "MISTO"}


class TestStatusSolicitacaoEnum:
    def test_em_analise_existe(self):
        assert hasattr(StatusSolicitacaoEnum, "EM_ANALISE"), (
            "StatusSolicitacaoEnum deve ter o membro EM_ANALISE"
        )

    def test_em_analise_valor_string(self):
        assert StatusSolicitacaoEnum.EM_ANALISE == "EM_ANALISE"

    def test_em_analise_value_attribute(self):
        assert StatusSolicitacaoEnum.EM_ANALISE.value == "EM_ANALISE"

    def test_em_analise_e_str(self):
        assert isinstance(StatusSolicitacaoEnum.EM_ANALISE, str)

    def test_outros_membros_preservados(self):
        """Regressão: membros históricos não foram removidos."""
        assert StatusSolicitacaoEnum.PENDENTE == "PENDENTE"
        assert StatusSolicitacaoEnum.APROVADA == "APROVADA"
        assert StatusSolicitacaoEnum.REJEITADA == "REJEITADA"
        assert StatusSolicitacaoEnum.CANCELADA == "CANCELADA"

    def test_todos_os_membros(self):
        nomes = {m.name for m in StatusSolicitacaoEnum}
        assert nomes == {"PENDENTE", "EM_ANALISE", "APROVADA", "REJEITADA", "CANCELADA"}
