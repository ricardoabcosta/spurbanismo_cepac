"""
Configurações da aplicação via pydantic-settings.

Lê variáveis de ambiente e do arquivo .env.

Variáveis obrigatórias em produção:
  DATABASE_URL          — connection string PostgreSQL+asyncpg
  AZURE_AD_TENANT_ID    — tenant UUID do Azure AD da SP Urbanismo
  AZURE_AD_CLIENT_ID    — client_id do app registration CEPAC

Variáveis opcionais:
  CORS_ORIGINS             — origens permitidas separadas por vírgula (default: *)
  AZURE_BLOB_ACCOUNT_NAME  — nome da storage account
  AZURE_BLOB_CONTAINER_NAME — nome do container (default: cepac-documentos)
"""
from typing import Optional

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # --- Banco de dados ---
    # ⚠️ Sem default em produção — definir DATABASE_URL obrigatoriamente (T21)
    database_url: str = "postgresql+asyncpg://cepac:cepac@localhost:5432/cepac"

    # --- Azure AD (T12) ---
    # None = Azure AD não configurado; app sobe mas rejeita requests autenticados
    azure_ad_tenant_id: Optional[str] = None
    azure_ad_client_id: Optional[str] = None

    # --- CORS ---
    # Em produção: defina CORS_ORIGINS com as URLs dos Container Apps separadas por vírgula
    # Ex: https://cepac-portal.xyz.eastus.azurecontainerapps.io,https://cepac-dashboard.xyz.eastus.azurecontainerapps.io
    cors_origins: str = "*"

    # --- Azure Blob Storage (T13) ---
    azure_blob_account_name: Optional[str] = None
    azure_blob_account_key: Optional[str] = None
    azure_blob_container_name: str = "cepac-documentos"

    class Config:
        env_file = ".env"


settings = Settings()
