-- =============================================================================
-- CEPAC — SP Urbanismo / Prodam
-- Migration 007: Seed parametros_sistema
-- PostgreSQL 15
--
-- Popula a tabela parametro_sistema com os valores calibrados da planilha
-- OUCAE_ESTOQUE_abr_rv01.xlsx (posição 13/04/2026).
--
-- Valores (D5):
--   cepacs_em_circulacao = 193779 (planilha: 193.779 títulos CEPAC)
--
-- Idempotente: INSERT ... ON CONFLICT (chave) DO UPDATE.
-- =============================================================================

BEGIN;

INSERT INTO parametro_sistema (chave, valor, descricao)
VALUES (
    'cepacs_em_circulacao',
    '193779',
    'Total de CEPACs em circulação — fonte: planilha OUCAE_ESTOQUE_abr_rv01.xlsx (13/04/2026)'
)
ON CONFLICT (chave) DO UPDATE
    SET valor     = EXCLUDED.valor,
        descricao = EXCLUDED.descricao;

COMMIT;
