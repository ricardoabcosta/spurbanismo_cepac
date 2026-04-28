"""
Testes unitários para src/api/schemas/portal.py — PropostaPortalIn.

Cobre os model_validators de validação cruzada:
- uso_aca == 'MISTO' exige aca_r_m2 e aca_nr_m2
- tipo_interessado == 'PJ' exige cnpj
- tipo_interessado == 'PF' exige cpf
- casos válidos (PJ, PF, MISTO com áreas) não levantam erro

Sem dependência de banco, ORM ou chamadas HTTP.
"""
from decimal import Decimal

import pytest
from pydantic import ValidationError

from src.api.schemas.portal import PropostaPortalIn


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _base_payload(**overrides) -> dict:
    """Payload mínimo válido sem campos obrigatórios de uso/interessado."""
    return {**overrides}


def _pj_payload(**overrides) -> dict:
    return {"tipo_interessado": "PJ", "cnpj": "12.345.678/0001-99", **overrides}


def _pf_payload(**overrides) -> dict:
    return {"tipo_interessado": "PF", "cpf": "123.456.789-00", **overrides}


def _misto_payload(**overrides) -> dict:
    return {
        "uso_aca": "MISTO",
        "aca_r_m2": Decimal("500.00"),
        "aca_nr_m2": Decimal("300.00"),
        **overrides,
    }


# ---------------------------------------------------------------------------
# uso_aca MISTO — exige aca_r_m2 e aca_nr_m2
# ---------------------------------------------------------------------------

class TestValidacaoMisto:
    def test_misto_sem_aca_r_m2_levanta_validation_error(self):
        with pytest.raises(ValidationError) as exc_info:
            PropostaPortalIn(uso_aca="MISTO", aca_nr_m2=Decimal("300.00"))
        erros = exc_info.value.errors()
        msgs = [e["msg"] for e in erros]
        assert any("aca_r_m2" in m for m in msgs), (
            f"Esperava mensagem sobre aca_r_m2. Erros: {msgs}"
        )

    def test_misto_sem_aca_nr_m2_levanta_validation_error(self):
        with pytest.raises(ValidationError) as exc_info:
            PropostaPortalIn(uso_aca="MISTO", aca_r_m2=Decimal("500.00"))
        erros = exc_info.value.errors()
        msgs = [e["msg"] for e in erros]
        assert any("aca_nr_m2" in m for m in msgs), (
            f"Esperava mensagem sobre aca_nr_m2. Erros: {msgs}"
        )

    def test_misto_sem_ambas_as_areas_levanta_validation_error(self):
        with pytest.raises(ValidationError):
            PropostaPortalIn(uso_aca="MISTO")

    def test_misto_com_ambas_as_areas_valido(self):
        """MISTO com aca_r_m2 e aca_nr_m2 preenchidos não deve levantar erro."""
        proposta = PropostaPortalIn(
            uso_aca="MISTO",
            aca_r_m2=Decimal("500.00"),
            aca_nr_m2=Decimal("300.00"),
        )
        assert proposta.uso_aca == "MISTO"
        assert proposta.aca_r_m2 == Decimal("500.00")
        assert proposta.aca_nr_m2 == Decimal("300.00")

    def test_r_puro_sem_areas_valido(self):
        """uso_aca='R' não exige aca_r_m2 nem aca_nr_m2."""
        proposta = PropostaPortalIn(uso_aca="R")
        assert proposta.uso_aca == "R"

    def test_nr_puro_sem_areas_valido(self):
        """uso_aca='NR' não exige aca_r_m2 nem aca_nr_m2."""
        proposta = PropostaPortalIn(uso_aca="NR")
        assert proposta.uso_aca == "NR"

    def test_uso_aca_invalido_levanta_validation_error(self):
        with pytest.raises(ValidationError):
            PropostaPortalIn(uso_aca="INVALIDO")


# ---------------------------------------------------------------------------
# tipo_interessado PJ — exige cnpj
# ---------------------------------------------------------------------------

class TestValidacaoPJ:
    def test_pj_sem_cnpj_levanta_validation_error(self):
        with pytest.raises(ValidationError) as exc_info:
            PropostaPortalIn(tipo_interessado="PJ")
        erros = exc_info.value.errors()
        msgs = [e["msg"] for e in erros]
        assert any("cnpj" in m for m in msgs), (
            f"Esperava mensagem sobre cnpj. Erros: {msgs}"
        )

    def test_pj_cnpj_vazio_levanta_validation_error(self):
        """cnpj='' é falsy — deve ser rejeitado."""
        with pytest.raises(ValidationError) as exc_info:
            PropostaPortalIn(tipo_interessado="PJ", cnpj="")
        erros = exc_info.value.errors()
        msgs = [e["msg"] for e in erros]
        assert any("cnpj" in m for m in msgs), (
            f"Esperava mensagem sobre cnpj. Erros: {msgs}"
        )

    def test_pj_com_cnpj_valido(self):
        """PJ com CNPJ preenchido não deve levantar erro."""
        proposta = PropostaPortalIn(
            tipo_interessado="PJ",
            cnpj="12.345.678/0001-99",
        )
        assert proposta.tipo_interessado == "PJ"
        assert proposta.cnpj == "12.345.678/0001-99"

    def test_pj_com_cpf_mas_sem_cnpj_levanta_validation_error(self):
        """PJ não deve aceitar cpf no lugar de cnpj."""
        with pytest.raises(ValidationError):
            PropostaPortalIn(tipo_interessado="PJ", cpf="123.456.789-00")


# ---------------------------------------------------------------------------
# tipo_interessado PF — exige cpf
# ---------------------------------------------------------------------------

class TestValidacaoPF:
    def test_pf_sem_cpf_levanta_validation_error(self):
        with pytest.raises(ValidationError) as exc_info:
            PropostaPortalIn(tipo_interessado="PF")
        erros = exc_info.value.errors()
        msgs = [e["msg"] for e in erros]
        assert any("cpf" in m for m in msgs), (
            f"Esperava mensagem sobre cpf. Erros: {msgs}"
        )

    def test_pf_cpf_vazio_levanta_validation_error(self):
        """cpf='' é falsy — deve ser rejeitado."""
        with pytest.raises(ValidationError) as exc_info:
            PropostaPortalIn(tipo_interessado="PF", cpf="")
        erros = exc_info.value.errors()
        msgs = [e["msg"] for e in erros]
        assert any("cpf" in m for m in msgs), (
            f"Esperava mensagem sobre cpf. Erros: {msgs}"
        )

    def test_pf_com_cpf_valido(self):
        """PF com CPF preenchido não deve levantar erro."""
        proposta = PropostaPortalIn(
            tipo_interessado="PF",
            cpf="123.456.789-00",
        )
        assert proposta.tipo_interessado == "PF"
        assert proposta.cpf == "123.456.789-00"

    def test_pf_com_cnpj_mas_sem_cpf_levanta_validation_error(self):
        """PF não deve aceitar cnpj no lugar de cpf."""
        with pytest.raises(ValidationError):
            PropostaPortalIn(tipo_interessado="PF", cnpj="12.345.678/0001-99")

    def test_tipo_interessado_invalido_levanta_validation_error(self):
        with pytest.raises(ValidationError):
            PropostaPortalIn(tipo_interessado="OUTRO")


# ---------------------------------------------------------------------------
# Casos válidos combinados
# ---------------------------------------------------------------------------

class TestCasosValidosCombinados:
    def test_pj_misto_com_todos_os_campos_obrigatorios(self):
        """Payload completo PJ + MISTO deve ser aceito sem erros."""
        proposta = PropostaPortalIn(
            codigo="AE-0183",
            tipo_interessado="PJ",
            cnpj="12.345.678/0001-99",
            uso_aca="MISTO",
            aca_r_m2=Decimal("500.00"),
            aca_nr_m2=Decimal("300.00"),
            aca_total_m2=Decimal("800.00"),
            tipo_contrapartida="CEPAC (título)",
            cepac_total=12,
        )
        assert proposta.tipo_interessado == "PJ"
        assert proposta.uso_aca == "MISTO"

    def test_pf_nr_sem_campos_opcionais(self):
        """Payload mínimo PF + NR deve ser aceito."""
        proposta = PropostaPortalIn(
            tipo_interessado="PF",
            cpf="123.456.789-00",
            uso_aca="NR",
        )
        assert proposta.tipo_interessado == "PF"
        assert proposta.uso_aca == "NR"

    def test_payload_vazio_valido(self):
        """Todos os campos são opcionais — payload vazio deve ser aceito."""
        proposta = PropostaPortalIn()
        assert proposta.tipo_interessado is None
        assert proposta.uso_aca is None


# ---------------------------------------------------------------------------
# Verificação do status padrão no repository (inspeção de código-fonte)
# ---------------------------------------------------------------------------

class TestRepositoryStatusPadrao:
    """
    Verifica que criar_solicitacao usa StatusSolicitacaoEnum.EM_ANALISE como
    status padrão, sem precisar de banco de dados.

    A abordagem inspeciona o código-fonte do repositório para garantir que o
    valor correto está hard-coded na função, independente de mocks de sessão.
    """

    def test_criar_solicitacao_usa_em_analise_no_codigo_fonte(self):
        import inspect
        from src.core.repositories import portal_repository

        source = inspect.getsource(portal_repository.criar_solicitacao)
        assert "StatusSolicitacaoEnum.EM_ANALISE" in source, (
            "criar_solicitacao deve definir status=StatusSolicitacaoEnum.EM_ANALISE, "
            "não PENDENTE nem outro valor."
        )

    def test_criar_solicitacao_nao_usa_pendente(self):
        import inspect
        from src.core.repositories import portal_repository

        source = inspect.getsource(portal_repository.criar_solicitacao)
        # Garante que PENDENTE não é o valor atribuído ao status na criação
        # (pode aparecer em comentários; checamos a linha de atribuição)
        linhas_com_status = [
            linha.strip() for linha in source.splitlines()
            if "status=" in linha and "StatusSolicitacaoEnum" in linha
        ]
        assert linhas_com_status, "Deve haver ao menos uma linha com status=StatusSolicitacaoEnum.*"
        for linha in linhas_com_status:
            assert "PENDENTE" not in linha, (
                f"criar_solicitacao não deve usar PENDENTE como status. Linha: {linha!r}"
            )
