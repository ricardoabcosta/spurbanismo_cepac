-- =============================================================================
-- CEPAC — Migration 023: Adiciona flag `incentivado` em titulo_cepac,
--         movimentacao e solicitacao_vinculacao
--
-- Contexto: OUCAB divide o estoque R em Incentivado (HIS/HMP) e Não Incentivado.
-- NULL = OUC sem distinção (OUCAE, OUCFL) ou título anterior à feature.
-- TRUE  = R Incentivado (HIS/HMP — sem teto próprio)
-- FALSE = R Não Incentivado (sujeito ao teto de 675.000 m²)
-- =============================================================================

BEGIN;

ALTER TABLE titulo_cepac
    ADD COLUMN incentivado BOOLEAN NULL;

ALTER TABLE movimentacao
    ADD COLUMN incentivado BOOLEAN NULL;

ALTER TABLE solicitacao_vinculacao
    ADD COLUMN incentivado BOOLEAN NULL;

COMMIT;
