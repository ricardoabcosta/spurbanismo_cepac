-- =============================================================================
-- CEPAC — Migration 026: Seed lei_ouc
--
-- Popula o catálogo de leis para cada OUC.
--
-- OUCAE (id=1): 1 lei vigente (18.174/2024)
-- OUCAB (id=3): 1 lei vigente (15.893/2013 c/ atualização 17.561/21)
-- OUCFL (id=2): 3 leis (11.732/1995 anterior, 13.769/2004 anterior, 18.175/2024 vigente)
--
-- Referência: docs/planejamento-carga-oucfl.md §2
-- =============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- OUCAE — Água Espraiada (operacao_urbana_id = 1)
-- ---------------------------------------------------------------------------
INSERT INTO lei_ouc (operacao_urbana_id, identificador, nome, ordem, vigente, estoque_geral_m2)
VALUES (1, '18.174/2024', 'Lei nº 18.174/2024 — OUCAE', 1, TRUE, 4600000.00);

-- ---------------------------------------------------------------------------
-- OUCAB — Água Branca (operacao_urbana_id = 3)
-- ---------------------------------------------------------------------------
INSERT INTO lei_ouc (operacao_urbana_id, identificador, nome, ordem, vigente, estoque_geral_m2)
VALUES (3, '15.893/2013', 'Lei nº 15.893/2013 c/c Lei nº 17.561/21 — OUCAB', 1, TRUE, 1850000.00);

-- ---------------------------------------------------------------------------
-- OUCFL — Faria Lima (operacao_urbana_id = 2)
-- ---------------------------------------------------------------------------
INSERT INTO lei_ouc (operacao_urbana_id, identificador, nome, ordem, vigente,
                     data_vigencia_inicio, data_vigencia_fim,
                     consumo_historico_r_m2, consumo_historico_nr_m2, estoque_geral_m2)
VALUES
    (2, '11.732/1995', 'Lei nº 11.732/1995 — Pré-OUC Faria Lima',
     1, FALSE,
     '1995-01-01', '2004-12-31',
     NULL, NULL, 940000.00),

    (2, '13.769/2004', 'Lei nº 13.769/2004 — Criação OUCFL',
     2, FALSE,
     '2004-01-01', '2023-12-31',
     646099.80, 426934.24, 1506155.00),

    (2, '18.175/2024', 'Lei nº 18.175/2024 — Revisão OUCFL',
     3, TRUE,
     '2024-01-01', NULL,
     NULL, NULL, 1756155.00);

-- ---------------------------------------------------------------------------
-- Validação pós-seed
-- ---------------------------------------------------------------------------
DO $$
DECLARE
    total_ae INT; total_ab INT; total_fl INT;
BEGIN
    SELECT COUNT(*) INTO total_ae FROM lei_ouc WHERE operacao_urbana_id = 1;
    SELECT COUNT(*) INTO total_ab FROM lei_ouc WHERE operacao_urbana_id = 3;
    SELECT COUNT(*) INTO total_fl FROM lei_ouc WHERE operacao_urbana_id = 2;

    IF total_ae <> 1 THEN
        RAISE EXCEPTION 'OUCAE: esperado 1 lei, encontrado %', total_ae;
    END IF;
    IF total_ab <> 1 THEN
        RAISE EXCEPTION 'OUCAB: esperado 1 lei, encontrado %', total_ab;
    END IF;
    IF total_fl <> 3 THEN
        RAISE EXCEPTION 'OUCFL: esperado 3 leis, encontrado %', total_fl;
    END IF;
END;
$$;

COMMIT;
