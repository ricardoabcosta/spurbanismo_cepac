# =============================================================================
# CEPAC — Dockerfile multi-stage
# Base: python:3.12-slim
# Stage 1 (builder): instala dependências em venv isolado
# Stage 2 (runtime): copia venv, roda com usuário não-root
# =============================================================================

# ---------------------------------------------------------------------------
# Stage 1 — builder
# ---------------------------------------------------------------------------
FROM python:3.12-slim AS builder

WORKDIR /app

# Dependências de sistema para compilar psycopg2-binary e asyncpg
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
 && rm -rf /var/lib/apt/lists/*

# Cria venv explícito para facilitar cópia no stage final
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copia apenas requirements primeiro — maximiza cache de camadas
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
 && pip install --no-cache-dir -r requirements.txt

# ---------------------------------------------------------------------------
# Stage 2 — runtime
# ---------------------------------------------------------------------------
FROM python:3.12-slim AS runtime

# Dependências de runtime (libpq para asyncpg/psycopg)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
 && rm -rf /var/lib/apt/lists/*

# Usuário não-root
RUN addgroup --system cepac && adduser --system --ingroup cepac cepac

WORKDIR /app

# Copia venv compilado do builder
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copia código-fonte
COPY --chown=cepac:cepac . .

USER cepac

# Porta padrão da aplicação
EXPOSE 8000

# Uvicorn com 2 workers (Azure Container Apps escala via réplicas, não workers)
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2"]
