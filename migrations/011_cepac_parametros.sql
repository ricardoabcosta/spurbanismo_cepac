-- =============================================================================
-- CEPAC — Migration 011: Parâmetros de CEPACs emitidos
-- Adiciona campos de controle de CEPACs à tabela singleton configuracao_operacao
-- e campos de conversão/desvinculação por setor à tabela setor.
-- Idempotente via IF NOT EXISTS.
-- =============================================================================

BEGIN;

-- Campos globais na tabela singleton configuracao_operacao
ALTER TABLE configuracao_operacao
    ADD COLUMN IF NOT EXISTS cepacs_leiloados         INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS cepacs_colocacao_privada  INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS cepacs_totais             INTEGER NOT NULL DEFAULT 0;

-- Campos por setor na tabela setor
ALTER TABLE setor
    ADD COLUMN IF NOT EXISTS cepacs_convertidos_aca        INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS cepacs_convertidos_parametros INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS cepacs_desvinculados_aca      INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS cepacs_desvinculados_parametros INTEGER NOT NULL DEFAULT 0;

COMMIT;
