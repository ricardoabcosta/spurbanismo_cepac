-- =============================================================================
-- CEPAC — Migration 032: proposta — campos ACA R Incentivado / Não-Incentivado
--
-- Contexto: OUCAB distingue uso residencial em duas categorias:
--   - R Incentivado (UI — Unidade Habitacional Incentivada, art. 5º IX da Lei 15.893/2013):
--     HIS/EHIS, área privativa 45–50 m², sempre disponível (art. 46 §1).
--   - R Não-Incentivado: uso residencial comum; sujeito ao teto cross-setor de
--     675.000 m² (art. 39 §2 da Lei 15.893/2013).
--
-- Os novos campos ficam NULL para OUCAE e OUCFL (sem distinção).
-- Invariante (não enforced no banco): aca_r_m2 = aca_r_inc_m2 + aca_r_nao_inc_m2
--   quando ambos estão preenchidos.
--
-- Referência: docs/planejamento-carga-oucab.md §5.1, T-AB1.4
-- =============================================================================

BEGIN;

ALTER TABLE proposta
    ADD COLUMN aca_r_inc_m2     NUMERIC(15, 2) NULL,
    ADD COLUMN aca_r_nao_inc_m2 NUMERIC(15, 2) NULL;

COMMENT ON COLUMN proposta.aca_r_inc_m2 IS
    'ACA Residencial Incentivada (HIS/EHIS — art. 5º IX, Lei 15.893/2013). NULL para OUCAE/OUCFL.';
COMMENT ON COLUMN proposta.aca_r_nao_inc_m2 IS
    'ACA Residencial Não-Incentivada. Sujeita ao teto de 675.000 m² (art. 39 §2). NULL para OUCAE/OUCFL.';

COMMIT;
