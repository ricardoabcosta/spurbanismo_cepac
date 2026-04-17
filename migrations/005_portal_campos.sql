-- =============================================================================
-- Migration 005 — Portal: campos adicionais em solicitacao_vinculacao (T15)
-- =============================================================================
-- ATENÇÃO: ALTER TYPE ADD VALUE em PG 15 é transacional.
-- Execute este script em uma sessão com autocommit ou fora de um bloco BEGIN.
-- =============================================================================

-- 1. Adiciona o valor CANCELADA ao ENUM (idempotente em PG 9.3+)
ALTER TYPE status_solicitacao_enum ADD VALUE IF NOT EXISTS 'CANCELADA';

-- 2. Adiciona colunas opcionais ao solicitacao_vinculacao
ALTER TABLE solicitacao_vinculacao
    ADD COLUMN IF NOT EXISTS proposta_id UUID
        REFERENCES proposta(id) ON DELETE RESTRICT,
    ADD COLUMN IF NOT EXISTS observacao TEXT;

-- Índice para busca por proposta (consultas do portal)
CREATE INDEX IF NOT EXISTS ix_solicitacao_vinculacao_proposta_id
    ON solicitacao_vinculacao (proposta_id)
    WHERE proposta_id IS NOT NULL;
