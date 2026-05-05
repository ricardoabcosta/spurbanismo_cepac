-- =============================================================================
-- CEPAC — Migration 022: Adiciona teto_r_nao_incentivado_m2 em operacao_urbana
--
-- Contexto: OUCAB limita R Não Incentivado a 675.000 m² (Lei 15.893/13).
-- O campo é NULL para OUCs sem essa distinção (OUCAE, OUCFL).
-- O valor é lido pelo RulesEngine via LimitesOucDTO — sem hardcode no Python.
-- =============================================================================

BEGIN;

ALTER TABLE operacao_urbana
    ADD COLUMN teto_r_nao_incentivado_m2 NUMERIC(15, 2) NULL;

UPDATE operacao_urbana
    SET teto_r_nao_incentivado_m2 = 675000.00
    WHERE sigla = 'AB';

COMMIT;
