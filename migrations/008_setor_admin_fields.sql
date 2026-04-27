-- =============================================================================
-- CEPAC — Migration 008: Campos administrativos na tabela setor
-- Adiciona: ativo, bloqueio_nr, piso_r_percentual
-- Idempotente via IF NOT EXISTS
-- =============================================================================

BEGIN;

ALTER TABLE setor
    ADD COLUMN IF NOT EXISTS ativo BOOLEAN NOT NULL DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS bloqueio_nr BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS piso_r_percentual NUMERIC(5, 2) NULL;

-- Berrini: NR incondicional bloqueado (estoque NR esgotado)
UPDATE setor SET bloqueio_nr = TRUE WHERE nome = 'Berrini';

-- Marginal Pinheiros: piso de 30% para uso R no total consumido
UPDATE setor SET piso_r_percentual = 30.00 WHERE nome = 'Marginal Pinheiros';

COMMIT;
