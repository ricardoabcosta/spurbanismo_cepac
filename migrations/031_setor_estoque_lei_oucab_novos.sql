-- =============================================================================
-- CEPAC — Migration 031: setor_estoque_lei para os 5 novos setores OUCAB
--
-- Vincula A1, A2, D, I, I2 à lei 15.893/2013 (lei vigente da OUCAB).
-- Todos com estoque 0, exceto Setor I (herda 70.000 R do seu único filho ativo).
--
-- Pré-requisito: migration 030 (setores criados) deve ter rodado.
-- Referência: docs/planejamento-carga-oucab.md §5.1, T-AB1.3
-- =============================================================================

BEGIN;

INSERT INTO setor_estoque_lei (
    setor_id, lei_ouc_id,
    estoque_total_r_m2, estoque_total_nr_m2,
    teto_r_m2, teto_nr_m2, reserva_r_m2
)
SELECT
    s.id,
    lo.id,
    s.teto_r_m2,
    s.teto_nr_m2,
    s.teto_r_m2,
    s.teto_nr_m2,
    NULL
FROM setor s
CROSS JOIN (
    SELECT id FROM lei_ouc
    WHERE operacao_urbana_id = 3
      AND identificador = '15.893/2013'
) lo
WHERE s.operacao_urbana_id = 3
  AND s.nome IN ('Setor A1', 'Setor A2', 'Setor D', 'Setor I', 'Setor I2');

-- ---------------------------------------------------------------------------
-- Sanidade: agora OUCAB deve ter 18 registros em setor_estoque_lei
-- ---------------------------------------------------------------------------
DO $$
DECLARE
    total INT;
BEGIN
    SELECT COUNT(*) INTO total
    FROM setor_estoque_lei sel
    JOIN lei_ouc lo ON lo.id = sel.lei_ouc_id
    WHERE lo.operacao_urbana_id = 3;

    IF total <> 18 THEN
        RAISE EXCEPTION 'OUCAB setor_estoque_lei: esperado 18, encontrado %.', total;
    END IF;
END;
$$;

COMMIT;
