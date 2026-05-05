-- =============================================================================
-- CEPAC — Migration 019: Seed setores OUC Faria Lima (operacao_urbana_id = 2)
--
-- Fonte: Consolidado_OUC-FL.csv (Lei 13.769/04)
-- Setores: Hélio Pelegrino, Faria Lima, Pinheiros, Olimpíadas
-- Todos F1=1.0, F2=1.0 — sem hierarquia (todos são setores raiz)
-- =============================================================================

BEGIN;

INSERT INTO setor (
    nome, estoque_total_m2, teto_r_m2, teto_nr_m2,
    operacao_urbana_id,
    fator_equivalencia_f1, fator_equivalencia_f2
)
VALUES
    ('Hélio Pelegrino', 474950.00, 292445.00, 182505.00, 2, 1.000000, 1.000000),
    ('Faria Lima',      361905.00, 288190.00,  73715.00, 2, 1.000000, 1.000000),
    ('Pinheiros',       383295.00, 286695.00,  96600.00, 2, 1.000000, 1.000000),
    ('Olimpíadas',      286005.00, 190440.00,  95565.00, 2, 1.000000, 1.000000);

DO $$
DECLARE total INT;
BEGIN
    SELECT COUNT(*) INTO total FROM setor WHERE operacao_urbana_id = 2;
    IF total <> 4 THEN
        RAISE EXCEPTION 'Seed OUCFL incompleto: esperado 4 setores, encontrado %.', total;
    END IF;
END;
$$;

COMMIT;
