-- =============================================================================
-- CEPAC — SP Urbanismo / Prodam
-- Migration 004a: Remoção do Seed Sintético (Migration 002)
-- PostgreSQL 15
--
-- Remove os 13 títulos SEED-* inseridos pela migration 002_seed_abril_2026.sql.
-- Deve ser executada ANTES de 004_carga_inicial_real.sql.
-- Idempotente: DELETE ... WHERE codigo LIKE 'SEED-%' não falha se já removido.
-- =============================================================================

BEGIN;

-- movimentacao é append-only via trigger; desabilitamos temporariamente para
-- poder remover registros do seed sintético (único caso legítimo de DELETE)
ALTER TABLE movimentacao DISABLE TRIGGER USER;

DELETE FROM movimentacao
WHERE titulo_id IN (
    SELECT id FROM titulo_cepac WHERE codigo LIKE 'SEED-%'
);

ALTER TABLE movimentacao ENABLE TRIGGER USER;

DELETE FROM titulo_cepac WHERE codigo LIKE 'SEED-%';

COMMIT;
