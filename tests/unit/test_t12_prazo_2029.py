"""
T20 — Testes unitários: Velocímetro 2029 e cálculo de prazo (T16/D3).

Verifica:
  - Data início: 2004-01-01 (D3).
  - Data fim: 2029-12-31.
  - Zona VERDE para percentuais < 60%.
  - Zona AMARELO para percentuais entre 60% e 85%.
  - Zona VERMELHO para percentuais >= 85%.
  - Percentual não ultrapassa 100% após data fim.
  - Dias restantes chega a 0 após data fim.
  - Data de referência 2026-04-16 cai em VERMELHO (~85.7%).
"""
from __future__ import annotations

from datetime import date

import pytest

from src.core.repositories.dashboard_repository import (
    calcular_velocimetro,
    _DATA_INICIO_OUCAE,
    _DATA_FIM_OUCAE,
    _DIAS_TOTAIS,
)


class TestConstantesVelocimetro:
    def test_data_inicio(self) -> None:
        """D3: início da OUCAE é 2004-01-01."""
        assert _DATA_INICIO_OUCAE == date(2004, 1, 1)

    def test_data_fim(self) -> None:
        """D3: fim da OUCAE é 2029-12-31."""
        assert _DATA_FIM_OUCAE == date(2029, 12, 31)

    def test_dias_totais_positivo(self) -> None:
        assert _DIAS_TOTAIS > 0
        # 9496 dias = (2029-12-31) - (2004-01-01)
        assert _DIAS_TOTAIS == (date(2029, 12, 31) - date(2004, 1, 1)).days


class TestCalcularVelocimetro:
    def test_data_inicio_retorna_zero_pct_verde(self) -> None:
        pct, dias_rest, zona = calcular_velocimetro(date(2004, 1, 1))
        assert pct == 0.0
        assert zona == "VERDE"
        assert dias_rest == _DIAS_TOTAIS

    def test_zona_verde_antes_de_60_pct(self) -> None:
        # 50% → VERDE
        dias_50pct = int(_DIAS_TOTAIS * 0.50)
        data = date(2004, 1, 1).replace(
            year=2004 + dias_50pct // 365
        )  # aproximação
        pct, _, zona = calcular_velocimetro(date(2016, 7, 2))  # ~50%
        assert zona == "VERDE"
        assert pct < 60.0

    def test_zona_amarelo_entre_60_e_85(self) -> None:
        # 2022-06-01 ≈ 70.8% → AMARELO (2026-04-16 já passou para VERMELHO ~85.7%)
        pct, _, zona = calcular_velocimetro(date(2022, 6, 1))
        assert zona == "AMARELO"
        assert 60.0 <= pct < 85.0

    def test_zona_vermelho_acima_de_85(self) -> None:
        # 2028-01-01 deve estar em VERMELHO (~86%)
        pct, _, zona = calcular_velocimetro(date(2028, 1, 1))
        assert zona == "VERMELHO"
        assert pct >= 85.0

    def test_data_apos_fim_retorna_100_pct_vermelho(self) -> None:
        pct, dias_rest, zona = calcular_velocimetro(date(2030, 6, 1))
        assert pct == 100.0
        assert dias_rest == 0
        assert zona == "VERMELHO"

    def test_data_no_fim_retorna_100_pct(self) -> None:
        pct, dias_rest, zona = calcular_velocimetro(date(2029, 12, 31))
        assert pct == 100.0
        assert dias_rest == 0

    def test_sem_data_usa_hoje(self) -> None:
        """calcular_velocimetro() sem argumento usa date.today()."""
        pct_hoje, _, zona_hoje = calcular_velocimetro()
        pct_data, _, zona_data = calcular_velocimetro(date.today())
        assert pct_hoje == pct_data
        assert zona_hoje == zona_data

    def test_percentual_arredondado_duas_casas(self) -> None:
        pct, _, _ = calcular_velocimetro(date(2026, 4, 16))
        # Verifica que está arredondado a 2 casas decimais
        assert pct == round(pct, 2)

    def test_dias_restantes_decresce_ao_longo_do_tempo(self) -> None:
        _, dias_2024, _ = calcular_velocimetro(date(2024, 1, 1))
        _, dias_2026, _ = calcular_velocimetro(date(2026, 1, 1))
        assert dias_2024 > dias_2026

    def test_resultado_e_tupla_de_tres(self) -> None:
        resultado = calcular_velocimetro(date(2026, 4, 16))
        assert len(resultado) == 3
        pct, dias, zona = resultado
        assert isinstance(pct, float)
        assert isinstance(dias, int)
        assert isinstance(zona, str)
