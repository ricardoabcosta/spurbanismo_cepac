-- =============================================================================
-- CEPAC — Migration 030: Setores OUCAB completos + correção de fatores Fe
--
-- (a) Adiciona 5 setores ausentes: A1, A2, D, I (pai de I1/I2), I2
--     Todos com estoque 0, exceto Setor I (70.000 R — container de I1).
-- (b) Reparenta I1 → Setor I (hoje orphão sem pai, como G/H).
-- (c) Corrige fator_equivalencia_f1 para todos os setores OUCAB conforme
--     Quadro III da Lei nº 17.561/2021 (substituiu a tabela original da 15.893).
-- (d) Zera fator_equivalencia_f2 para todos os setores OUCAB — OUCAB tem
--     apenas um Fe único por setor (f1 reutilizado conforme decisão Q1).
--
-- Fonte: Guia Prático OUCAB v1.1 (14/12/2023), pág. 18 — Tabela de Conversão.
-- Referência: docs/planejamento-carga-oucab.md §5.1, T-AB1.2
-- =============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- 0. Relaxar constraint — setores sem estoque (A1, A2, D, I2) precisam de 0
--    A constraint original (> 0) foi criada para OUCs com setores sempre ativos.
--    OUCAB tem subsetores legais sem estoque próprio (estoque está nos irmãos).
-- ---------------------------------------------------------------------------
ALTER TABLE setor DROP CONSTRAINT IF EXISTS ck_setor_estoque_total_positivo;
ALTER TABLE setor ADD CONSTRAINT ck_setor_estoque_total_nao_negativo CHECK (estoque_total_m2 >= 0);

-- ---------------------------------------------------------------------------
-- 1. Inserir Setor I (pai de I1 e I2) — standalone, estoque = teto de I1
-- ---------------------------------------------------------------------------
INSERT INTO setor (
    nome, estoque_total_m2, teto_r_m2, teto_nr_m2,
    operacao_urbana_id,
    fator_equivalencia_f1, fator_equivalencia_f2
)
VALUES ('Setor I', 70000.00, 70000.00, 0.00, 3, 0.400000, NULL);

-- ---------------------------------------------------------------------------
-- 2. Inserir Setor D — standalone, estoque 0, sem Fe aplicável
-- ---------------------------------------------------------------------------
INSERT INTO setor (
    nome, estoque_total_m2, teto_r_m2, teto_nr_m2,
    operacao_urbana_id,
    fator_equivalencia_f1, fator_equivalencia_f2
)
VALUES ('Setor D', 0.00, 0.00, 0.00, 3, NULL, NULL);

-- ---------------------------------------------------------------------------
-- 3. Inserir filhos de Setor A (A1, A2) com estoque 0
-- ---------------------------------------------------------------------------
INSERT INTO setor (
    nome, estoque_total_m2, teto_r_m2, teto_nr_m2,
    operacao_urbana_id, setor_pai_id,
    fator_equivalencia_f1, fator_equivalencia_f2
)
SELECT 'Setor A1', 0.00, 0.00, 0.00, 3, id, NULL, NULL
FROM setor WHERE nome = 'Setor A' AND operacao_urbana_id = 3;

INSERT INTO setor (
    nome, estoque_total_m2, teto_r_m2, teto_nr_m2,
    operacao_urbana_id, setor_pai_id,
    fator_equivalencia_f1, fator_equivalencia_f2
)
SELECT 'Setor A2', 0.00, 0.00, 0.00, 3, id, NULL, NULL
FROM setor WHERE nome = 'Setor A' AND operacao_urbana_id = 3;

-- ---------------------------------------------------------------------------
-- 4. Inserir filho I2 de Setor I (estoque 0)
-- ---------------------------------------------------------------------------
INSERT INTO setor (
    nome, estoque_total_m2, teto_r_m2, teto_nr_m2,
    operacao_urbana_id, setor_pai_id,
    fator_equivalencia_f1, fator_equivalencia_f2
)
SELECT 'Setor I2', 0.00, 0.00, 0.00, 3, id, NULL, NULL
FROM setor WHERE nome = 'Setor I' AND operacao_urbana_id = 3;

-- ---------------------------------------------------------------------------
-- 5. Reparentar I1 → Setor I (hoje sem pai)
-- ---------------------------------------------------------------------------
UPDATE setor
SET setor_pai_id = (
    SELECT id FROM setor WHERE nome = 'Setor I' AND operacao_urbana_id = 3
)
WHERE nome = 'Setor I1' AND operacao_urbana_id = 3;

-- ---------------------------------------------------------------------------
-- 6. Corrigir Fe (fator_equivalencia_f1) — Quadro III, Lei 17.561/2021
--    Zerar f2 (OUCAB tem Fe único — decisão Q1)
-- ---------------------------------------------------------------------------
UPDATE setor SET fator_equivalencia_f1 = 1.000000, fator_equivalencia_f2 = NULL WHERE nome = 'Setor A'  AND operacao_urbana_id = 3;
UPDATE setor SET fator_equivalencia_f1 = 1.000000, fator_equivalencia_f2 = NULL WHERE nome = 'Setor A3' AND operacao_urbana_id = 3;
UPDATE setor SET fator_equivalencia_f1 = 1.000000, fator_equivalencia_f2 = NULL WHERE nome = 'Setor B'  AND operacao_urbana_id = 3;
UPDATE setor SET fator_equivalencia_f1 = 0.600000, fator_equivalencia_f2 = NULL WHERE nome = 'Setor C'  AND operacao_urbana_id = 3;
UPDATE setor SET fator_equivalencia_f1 = 1.000000, fator_equivalencia_f2 = NULL WHERE nome = 'Setor E'  AND operacao_urbana_id = 3;
UPDATE setor SET fator_equivalencia_f1 = 1.000000, fator_equivalencia_f2 = NULL WHERE nome = 'Setor E1' AND operacao_urbana_id = 3;
UPDATE setor SET fator_equivalencia_f1 = 1.000000, fator_equivalencia_f2 = NULL WHERE nome = 'Setor E2' AND operacao_urbana_id = 3;
UPDATE setor SET fator_equivalencia_f1 = 1.000000, fator_equivalencia_f2 = NULL WHERE nome = 'Setor F'  AND operacao_urbana_id = 3;
UPDATE setor SET fator_equivalencia_f1 = 1.000000, fator_equivalencia_f2 = NULL WHERE nome = 'Setor F1' AND operacao_urbana_id = 3;
UPDATE setor SET fator_equivalencia_f1 = 1.000000, fator_equivalencia_f2 = NULL WHERE nome = 'Setor F2' AND operacao_urbana_id = 3;
UPDATE setor SET fator_equivalencia_f1 = 1.000000, fator_equivalencia_f2 = NULL WHERE nome = 'Setor G'  AND operacao_urbana_id = 3;
UPDATE setor SET fator_equivalencia_f1 = 0.600000, fator_equivalencia_f2 = NULL WHERE nome = 'Setor H'  AND operacao_urbana_id = 3;
UPDATE setor SET fator_equivalencia_f1 = 0.400000, fator_equivalencia_f2 = NULL WHERE nome = 'Setor I'  AND operacao_urbana_id = 3;
UPDATE setor SET fator_equivalencia_f1 = 0.400000, fator_equivalencia_f2 = NULL WHERE nome = 'Setor I1' AND operacao_urbana_id = 3;
-- A1, A2, D, I2: f1 = NULL (N/A — Lei 17.561/2021)

-- ---------------------------------------------------------------------------
-- Sanidade final
-- ---------------------------------------------------------------------------
DO $$
DECLARE
    total_oucab   INT;
    total_filhos  INT;
    total_raiz    INT;
    fe_errado     INT;
BEGIN
    SELECT COUNT(*) INTO total_oucab  FROM setor WHERE operacao_urbana_id = 3;
    SELECT COUNT(*) INTO total_filhos FROM setor WHERE operacao_urbana_id = 3 AND setor_pai_id IS NOT NULL;
    SELECT COUNT(*) INTO total_raiz   FROM setor WHERE operacao_urbana_id = 3 AND setor_pai_id IS NULL;

    -- Verifica que nenhum setor com Fe=1.0 ficou com valor diferente (exclui C/H/I/I1 que têm outros valores)
    SELECT COUNT(*) INTO fe_errado FROM setor
    WHERE operacao_urbana_id = 3
      AND nome IN ('Setor A', 'Setor A3', 'Setor B',
                   'Setor E', 'Setor E1', 'Setor E2',
                   'Setor F', 'Setor F1', 'Setor F2', 'Setor G')
      AND (fator_equivalencia_f1 IS NULL OR ABS(fator_equivalencia_f1 - 1.0) > 0.001
           OR fator_equivalencia_f2 IS NOT NULL);

    -- 18 total: 9 raízes (A,B,C,D,E,F,G,H,I) + 9 filhos (A1,A2,A3,E1,E2,F1,F2,I1,I2)
    IF total_oucab <> 18 THEN
        RAISE EXCEPTION 'Seed OUCAB incompleto: esperado 18 setores, encontrado %.', total_oucab;
    END IF;
    IF total_filhos <> 9 THEN
        RAISE EXCEPTION 'Seed OUCAB: esperado 9 setores filho, encontrado %.', total_filhos;
    END IF;
    IF total_raiz <> 9 THEN
        RAISE EXCEPTION 'Seed OUCAB: esperado 9 setores raiz, encontrado %.', total_raiz;
    END IF;
    IF fe_errado > 0 THEN
        RAISE EXCEPTION 'Fator Fe incorreto em % setores OUCAB esperando Fe=1.0.', fe_errado;
    END IF;
END;
$$;

COMMIT;
