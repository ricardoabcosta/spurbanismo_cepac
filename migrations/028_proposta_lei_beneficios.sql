-- =============================================================================
-- CEPAC — Migration 028: Campos de lei vigente e benefícios em proposta
--
-- Adiciona colunas para suportar múltiplas leis e ACA Real/Benefícios.
--
-- Referência: docs/planejamento-carga-oucfl.md §4.2 (Decisões D1, D3)
-- =============================================================================

BEGIN;

ALTER TABLE proposta
    ADD COLUMN lei_vigente             VARCHAR(30),
    ADD COLUMN aca_r_real_m2           NUMERIC(15,2),
    ADD COLUMN aca_r_beneficios_m2     NUMERIC(15,2),
    ADD COLUMN aca_nr_real_m2          NUMERIC(15,2),
    ADD COLUMN aca_nr_beneficios_m2    NUMERIC(15,2);

COMMENT ON COLUMN proposta.lei_vigente IS
    'Lei aplicável à proposta (ex: "13.769/2004", "18.175/2024"). NULL para OUCAE/OUCAB (1 lei vigente apenas).';
COMMENT ON COLUMN proposta.aca_r_real_m2 IS
    'Área real R (sem benefícios). Preenchido apenas para Lei 18.175/24 (OUCFL). NULL = Lei 13.769.';
COMMENT ON COLUMN proposta.aca_r_beneficios_m2 IS
    'Área R com benefícios (adicional sobre real). Preenchido apenas para Lei 18.175/24.';

COMMIT;
