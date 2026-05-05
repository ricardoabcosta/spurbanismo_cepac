-- =============================================================================
-- CEPAC — Migration 020: Seed setores OUC Água Branca (operacao_urbana_id = 3)
--
-- Fonte: Geral.csv (Lei 15.893/13) + Cartilha OUCAB (fatores de equivalência)
--
-- Ordem de inserção obrigatória (FK setor_pai_id):
--   1. Setores standalone (sem hierarquia)
--   2. Setores Pai (containers — teto = soma dos filhos, F1/F2 = NULL)
--   3. Setores Filho (referenciam o Pai via INSERT ... SELECT)
--
-- Nota: Setor C tem teto_nr_m2 = 0.00 (setor exclusivamente residencial).
-- =============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Setores standalone
-- ---------------------------------------------------------------------------

INSERT INTO setor (
    nome, estoque_total_m2, teto_r_m2, teto_nr_m2,
    operacao_urbana_id,
    fator_equivalencia_f1, fator_equivalencia_f2
)
VALUES
    ('Setor B',  410000.00, 300000.00, 110000.00, 3, 0.800000, 0.700000),
    ('Setor C',   20000.00,  20000.00,      0.00, 3, 1.000000, 0.600000),
    ('Setor G',   30000.00,  15000.00,  15000.00, 3, 0.400000, 0.600000),
    ('Setor H',  260000.00, 150000.00, 110000.00, 3, 0.400000, 0.600000),
    ('Setor I1',  25000.00,  15000.00,  10000.00, 3, 0.400000, 0.600000);

-- ---------------------------------------------------------------------------
-- 2. Setores Pai (containers — teto derivado da soma dos filhos)
--    Setor A: teto_r=90.000 + teto_nr=55.000 = 145.000
--    Setor E: teto_r=270.000 + teto_nr=130.000 = 400.000
--    Setor F: teto_r=260.000 + teto_nr=70.000 = 330.000
-- ---------------------------------------------------------------------------

INSERT INTO setor (
    nome, estoque_total_m2, teto_r_m2, teto_nr_m2,
    operacao_urbana_id
)
VALUES
    ('Setor A', 145000.00,  90000.00,  55000.00, 3),
    ('Setor E', 400000.00, 270000.00, 130000.00, 3),
    ('Setor F', 330000.00, 260000.00,  70000.00, 3);

-- ---------------------------------------------------------------------------
-- 3. Setores Filho (INSERT ... SELECT garante que o pai já existe na transação)
-- ---------------------------------------------------------------------------

-- Filhos de Setor A
INSERT INTO setor (
    nome, estoque_total_m2, teto_r_m2, teto_nr_m2,
    operacao_urbana_id, setor_pai_id,
    fator_equivalencia_f1, fator_equivalencia_f2
)
SELECT 'Setor A3', 145000.00, 90000.00, 55000.00, 3, id, 1.000000, 0.800000
FROM setor WHERE nome = 'Setor A' AND operacao_urbana_id = 3;

-- Filhos de Setor E
INSERT INTO setor (
    nome, estoque_total_m2, teto_r_m2, teto_nr_m2,
    operacao_urbana_id, setor_pai_id,
    fator_equivalencia_f1, fator_equivalencia_f2
)
SELECT 'Setor E1', 100000.00, 50000.00, 50000.00, 3, id, 0.700000, 0.600000
FROM setor WHERE nome = 'Setor E' AND operacao_urbana_id = 3;

INSERT INTO setor (
    nome, estoque_total_m2, teto_r_m2, teto_nr_m2,
    operacao_urbana_id, setor_pai_id,
    fator_equivalencia_f1, fator_equivalencia_f2
)
SELECT 'Setor E2', 300000.00, 220000.00, 80000.00, 3, id, 0.700000, 0.600000
FROM setor WHERE nome = 'Setor E' AND operacao_urbana_id = 3;

-- Filhos de Setor F
INSERT INTO setor (
    nome, estoque_total_m2, teto_r_m2, teto_nr_m2,
    operacao_urbana_id, setor_pai_id,
    fator_equivalencia_f1, fator_equivalencia_f2
)
SELECT 'Setor F1', 100000.00, 60000.00, 40000.00, 3, id, 0.700000, 0.600000
FROM setor WHERE nome = 'Setor F' AND operacao_urbana_id = 3;

INSERT INTO setor (
    nome, estoque_total_m2, teto_r_m2, teto_nr_m2,
    operacao_urbana_id, setor_pai_id,
    fator_equivalencia_f1, fator_equivalencia_f2
)
SELECT 'Setor F2', 230000.00, 200000.00, 30000.00, 3, id, 0.700000, 0.600000
FROM setor WHERE nome = 'Setor F' AND operacao_urbana_id = 3;

-- ---------------------------------------------------------------------------
-- Sanidade: 13 setores OUCAB (5 standalone + 3 pais + 5 filhos), 5 com pai
-- ---------------------------------------------------------------------------

DO $$
DECLARE
    total_oucab  INT;
    total_filhos INT;
BEGIN
    SELECT COUNT(*) INTO total_oucab  FROM setor WHERE operacao_urbana_id = 3;
    SELECT COUNT(*) INTO total_filhos FROM setor WHERE operacao_urbana_id = 3 AND setor_pai_id IS NOT NULL;

    IF total_oucab <> 13 THEN
        RAISE EXCEPTION 'Seed OUCAB incompleto: esperado 13 setores, encontrado %.', total_oucab;
    END IF;
    IF total_filhos <> 5 THEN
        RAISE EXCEPTION 'Seed OUCAB: esperado 5 setores filho, encontrado %.', total_filhos;
    END IF;
END;
$$;

COMMIT;
