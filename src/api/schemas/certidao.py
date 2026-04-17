"""
Schemas Pydantic v2 para os endpoints de certidões (T14).
"""
from __future__ import annotations

from datetime import date, datetime
from typing import Literal, Optional
from uuid import UUID

from pydantic import BaseModel, Field


# ---------------------------------------------------------------------------
# Público — sem dados sensíveis (privacidade do munícipe)
# ---------------------------------------------------------------------------

class CertidaoPublicaOut(BaseModel):
    """
    Resposta do endpoint público de consulta de autenticidade.

    Campos de privacidade omitidos: interessado, CNPJ/CPF, endereço.
    """

    numero_certidao: str = Field(..., description="Número da certidão (ex: AE-001/2024)")
    tipo: str = Field(..., description="Tipo da certidão: VINCULAÇÃO, ALTERAÇÃO ou DESVINCULAÇÃO")
    data_emissao: Optional[date] = None
    situacao: str = Field(..., description="VALIDA ou CANCELADA")
    proposta_codigo: str = Field(..., description="Código da proposta vinculada (ex: AE-0183)")
    setor: str = Field(..., description="Nome do setor (ex: BROOKLIN)")
    autenticidade: Literal[
        "CERTIDÃO AUTÊNTICA",
        "CERTIDÃO CANCELADA",
        "CERTIDÃO NÃO ENCONTRADA",
    ] = Field(..., description="Resultado da consulta de autenticidade")

    model_config = {
        "json_schema_extra": {
            "example": {
                "numero_certidao": "AE-001/2024",
                "tipo": "VINCULAÇÃO",
                "data_emissao": "2024-03-15",
                "situacao": "VALIDA",
                "proposta_codigo": "AE-0183",
                "setor": "BROOKLIN",
                "autenticidade": "CERTIDÃO AUTÊNTICA",
            }
        }
    }


# ---------------------------------------------------------------------------
# Restrito — dados completos da proposta vinculada (TECNICO/DIRETOR)
# ---------------------------------------------------------------------------

class PropostaResumidaOut(BaseModel):
    """Dados completos da proposta — somente para técnicos autenticados."""

    id: UUID
    codigo: str
    numero_pa: Optional[str] = None
    tipo_processo: Optional[str] = None
    data_autuacao: Optional[date] = None
    status_pa: str
    interessado: Optional[str] = None
    cnpj_cpf: Optional[str] = None
    endereco: Optional[str] = None
    setor: str
    requerimento: str
    area_terreno_m2: Optional[float] = None
    observacao_alteracao: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class CertidaoComPropostaOut(BaseModel):
    """Certidão + dados completos da proposta (endpoint restrito)."""

    numero_certidao: str
    tipo: str
    data_emissao: Optional[date] = None
    situacao: str
    numero_processo_sei: Optional[str] = None
    created_at: datetime
    proposta: PropostaResumidaOut

    model_config = {"from_attributes": True}


# ---------------------------------------------------------------------------
# Listagem pública (filtros: tipo, ano, situacao)
# ---------------------------------------------------------------------------

class CertidaoListaOut(BaseModel):
    """Item da listagem pública de certidões."""

    numero_certidao: str
    tipo: str
    data_emissao: Optional[date] = None
    situacao: str
    proposta_codigo: str
    setor: str

    model_config = {"from_attributes": True}
