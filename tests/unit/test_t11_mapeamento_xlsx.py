"""
T20 — Testes unitários: Mapeamento de campos e validação SEI (T11/D2).

Verifica:
  - Regex SEI aceita padrão novo: 7810.2025/0001500-9
  - Regex SIMPROC aceita padrão antigo: 2005-0060565-0
  - Formatos inválidos são rejeitados pelo Pydantic.
  - SolicitacaoPortalIn valida corretamente area_m2 (Decimal > 0).
  - Decisão D2: dois padrões históricos aceitos no Portal.
"""
from __future__ import annotations

import re
from decimal import Decimal

import pytest
from pydantic import ValidationError

from src.api.schemas.portal import SolicitacaoPortalIn

# Regex extraída de SolicitacaoPortalIn (D2)
_SEI_PATTERN = re.compile(r"^\d{4}\.\d{4}/\d{7}-\d$")
_SIMPROC_PATTERN = re.compile(r"^\d{4}-\d\.\d{3}\.\d{3}-\d$")


class TestSeiPatternRegex:
    """Testa diretamente os padrões regex do SEI (D2)."""

    def test_sei_novo_valido(self) -> None:
        assert _SEI_PATTERN.match("7810.2025/0001500-9")

    def test_sei_formato_genericos(self) -> None:
        assert _SEI_PATTERN.match("6016.2026/0001234-5")
        assert _SEI_PATTERN.match("0001.2000/0000001-0")

    def test_simproc_antigo_valido(self) -> None:
        assert _SIMPROC_PATTERN.match("2005-0.060-565-0") is None  # formato errado
        assert _SIMPROC_PATTERN.match("2005-0.060.565-0")

    def test_sei_formato_invalido(self) -> None:
        assert _SEI_PATTERN.match("INVALIDO") is None
        assert _SEI_PATTERN.match("7810.2025-0001500-9") is None
        assert _SEI_PATTERN.match("7810.2025/00001500-9") is None  # 8 dígitos

    def test_simproc_formato_invalido(self) -> None:
        assert _SIMPROC_PATTERN.match("2005.0060565-0") is None


class TestSolicitacaoPortalInValidacao:
    """Testa SolicitacaoPortalIn.numero_processo_sei via Pydantic."""

    _BASE_PAYLOAD = {
        "setor": "Brooklin",
        "uso": "NR",
        "origem": "ACA",
        "area_m2": "100.00",
        # min_length=1 exigido pelo schema; UUID sintético suficiente para testes unitários
        "titulo_ids": ["00000000-0000-0000-0000-000000000001"],
    }

    def _make(self, sei: str) -> SolicitacaoPortalIn:
        return SolicitacaoPortalIn(
            **self._BASE_PAYLOAD,
            numero_processo_sei=sei,
        )

    def test_sei_novo_aceito(self) -> None:
        sol = self._make("7810.2025/0001500-9")
        assert sol.numero_processo_sei == "7810.2025/0001500-9"

    def test_simproc_aceito(self) -> None:
        sol = self._make("2005-0.060.565-0")
        assert sol.numero_processo_sei == "2005-0.060.565-0"

    def test_sei_invalido_levanta_validation_error(self) -> None:
        with pytest.raises(ValidationError) as exc_info:
            self._make("FORMATO-INVALIDO")
        errors = exc_info.value.errors()
        fields = [e["loc"][-1] for e in errors]
        assert "numero_processo_sei" in fields

    def test_area_m2_positiva_aceita(self) -> None:
        # Usa merge de dict para substituir area_m2 sem duplicar o kwarg
        sol_custom = SolicitacaoPortalIn(
            **{**self._BASE_PAYLOAD, "area_m2": "999.99"},
            numero_processo_sei="7810.2026/0000001-0",
        )
        assert sol_custom.area_m2 == Decimal("999.99")

    def test_area_m2_zero_rejeitada(self) -> None:
        with pytest.raises(ValidationError):
            SolicitacaoPortalIn(
                **{**self._BASE_PAYLOAD, "area_m2": "0"},
                numero_processo_sei="7810.2026/0000001-0",
            )

    def test_area_m2_negativa_rejeitada(self) -> None:
        with pytest.raises(ValidationError):
            SolicitacaoPortalIn(
                **{**self._BASE_PAYLOAD, "area_m2": "-10.00"},
                numero_processo_sei="7810.2026/0000001-0",
            )
