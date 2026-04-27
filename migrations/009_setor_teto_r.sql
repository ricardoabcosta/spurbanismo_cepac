-- =============================================================================
-- CEPAC — Migration 009: Campo teto_r_m2 na tabela setor
-- Limite máximo de área residencial (m²) por setor — fonte: planilha
-- OUCAE_ESTOQUE_abr_rv01.xlsx, aba Consolidado_OUC-AE, coluna "R" do bloco
-- "ESTOQUE MÁXIMO POR SETOR (m²)".
-- Idempotente via IF NOT EXISTS.
-- =============================================================================

BEGIN;

ALTER TABLE setor
    ADD COLUMN IF NOT EXISTS teto_r_m2 NUMERIC(15, 2) NULL;

UPDATE setor SET teto_r_m2 =   420000.00 WHERE nome = 'Brooklin';
UPDATE setor SET teto_r_m2 =   175000.00 WHERE nome = 'Berrini';
UPDATE setor SET teto_r_m2 =   180000.00 WHERE nome = 'Marginal Pinheiros';
UPDATE setor SET teto_r_m2 =   600000.00 WHERE nome = 'Chucri Zaidan';
UPDATE setor SET teto_r_m2 =    75000.00 WHERE nome = 'Jabaquara';

COMMIT;
