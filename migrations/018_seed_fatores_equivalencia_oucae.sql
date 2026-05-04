-- =============================================================================
-- CEPAC — Migration 018: Seed Fatores de Equivalência F1 e F2 — OUCAE
--
-- Fonte: parâmetros da Operação Urbana Consorciada Água Espraiada.
-- =============================================================================

BEGIN;

UPDATE setor SET fator_equivalencia_f1 = 3.0, fator_equivalencia_f2 = 2.0 WHERE nome = 'Jabaquara';
UPDATE setor SET fator_equivalencia_f1 = 1.0, fator_equivalencia_f2 = 1.0 WHERE nome = 'Brooklin';
UPDATE setor SET fator_equivalencia_f1 = 1.0, fator_equivalencia_f2 = 2.0 WHERE nome = 'Berrini';
UPDATE setor SET fator_equivalencia_f1 = 2.0, fator_equivalencia_f2 = 2.0 WHERE nome = 'Marginal Pinheiros';
UPDATE setor SET fator_equivalencia_f1 = 1.0, fator_equivalencia_f2 = 2.0 WHERE nome = 'Chucri Zaidan';

-- Sanidade: garante que todos os 5 setores foram atualizados
DO $$
DECLARE
    total INT;
BEGIN
    SELECT COUNT(*) INTO total
    FROM setor
    WHERE nome IN ('Jabaquara', 'Brooklin', 'Berrini', 'Marginal Pinheiros', 'Chucri Zaidan')
      AND fator_equivalencia_f1 IS NOT NULL
      AND fator_equivalencia_f2 IS NOT NULL;

    IF total <> 5 THEN
        RAISE EXCEPTION 'Seed incompleto: apenas % de 5 setores atualizados. Verifique os nomes na tabela.', total;
    END IF;
END;
$$;

COMMIT;
