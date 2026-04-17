"""
Schemas Pydantic v2 para o endpoint GET /saldo/{setor}.
"""
from datetime import date
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel, Field, model_validator


class SaldoOut(BaseModel):
    """
    Resposta do GET /saldo/{setor}.

    Inclui saldo calculado e limites do setor para facilitar a exibição
    em dashboards e relatórios de auditoria CVM/TCM.
    """

    setor: str
    data_referencia: date = Field(..., description="Data de referência do snapshot")

    # Consumos NR
    nr_consumido_aca: Decimal
    nr_consumido_nuvem: Decimal
    nr_em_analise: Decimal
    nr_total_comprometido: Decimal

    # Saldo disponível NR
    saldo_nr_disponivel: Decimal
    teto_nr: Decimal
    bloqueado: bool = Field(
        ..., description="True quando saldo_nr_disponivel <= 0"
    )

    model_config = {"json_encoders": {Decimal: str}}
