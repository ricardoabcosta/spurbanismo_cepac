-- =============================================================================
-- CEPAC — Migration 016: FK setor → operacao_urbana
--
-- Contexto:
--   Todos os setores existentes pertencem à OUCAE (Água Espraiada).
--   Esta migration associa cada setor à sua operação urbana via FK,
--   preparando o sistema para suportar múltiplas OUCs.
--
-- Estratégia (zero-downtime):
--   1. ADD COLUMN nullable     — instantâneo, sem lock
--   2. UPDATE todos os rows    — popula com id da OUCAE (sigla='AE')
--   3. SET NOT NULL            — seguro pois todos os rows já têm valor
--   4. ADD FK + índice
-- =============================================================================

BEGIN;

ALTER TABLE setor ADD COLUMN operacao_urbana_id INTEGER;

UPDATE setor
SET operacao_urbana_id = (SELECT id FROM operacao_urbana WHERE sigla = 'AE');

ALTER TABLE setor ALTER COLUMN operacao_urbana_id SET NOT NULL;

ALTER TABLE setor
    ADD CONSTRAINT fk_setor_operacao_urbana
    FOREIGN KEY (operacao_urbana_id) REFERENCES operacao_urbana(id);

CREATE INDEX idx_setor_operacao_urbana_id ON setor(operacao_urbana_id);

COMMIT;
