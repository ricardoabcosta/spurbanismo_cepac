-- =============================================================================
-- CEPAC — Migration 027: Seed setor_estoque_lei
--
-- Popula setor_estoque_lei espelhando os valores atuais de setor.* para
-- cada lei vigente de cada OUC + insere registros adicionais para OUCFL
-- Lei 13.769 (estoques antigos dos 4 setores).
--
-- Compatibilidade retroativa: setor.estoque_total_m2 continua como
-- denormalização da lei vigente (item R3 do roadmap).
-- =============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- Helper: associar cada setor à sua lei vigente, espelhando os campos atuais
-- ---------------------------------------------------------------------------
WITH setor_com_lei AS (
    SELECT
        s.id AS setor_id,
        lo.id AS lei_ouc_id,
        -- R = estoque_total_m2 - teto_nr_m2 (para OUCAE sem teto_r_m2 explícito)
        -- OU = teto_r_m2 quando explícito
        COALESCE(s.teto_r_m2, s.estoque_total_m2 - s.teto_nr_m2) AS estoque_r,
        s.teto_nr_m2 AS estoque_nr,
        s.teto_r_m2,
        s.teto_nr_m2,
        s.reserva_r_m2
    FROM setor s
    JOIN lei_ouc lo ON lo.operacao_urbana_id = s.operacao_urbana_id AND lo.vigente = TRUE
)
INSERT INTO setor_estoque_lei (setor_id, lei_ouc_id, estoque_total_r_m2, estoque_total_nr_m2,
                                teto_r_m2, teto_nr_m2, reserva_r_m2)
SELECT setor_id, lei_ouc_id, estoque_r, estoque_nr,
       teto_r_m2, teto_nr_m2, reserva_r_m2
FROM setor_com_lei;

-- ---------------------------------------------------------------------------
-- OUCFL — Estoque antigo Lei 13.769/2004 (4 setores, estoques diferentes)
-- ---------------------------------------------------------------------------
-- Fonte: planilha OUCFL_ESTOQUE_abr_rv02.xlsx
-- Para a Lei 13.769 os estoques eram MENORES que os da Lei 18.175.
-- Quando a lei vigente for 13.769, o sistema usa estes valores.
INSERT INTO setor_estoque_lei (setor_id, lei_ouc_id, estoque_total_r_m2, estoque_total_nr_m2,
                                teto_r_m2, teto_nr_m2, reserva_r_m2)
SELECT
    s.id AS setor_id,
    lo.id AS lei_ouc_id,
    CASE s.nome
        WHEN 'Hélio Pelegrino' THEN 257010.00
        WHEN 'Faria Lima'      THEN 275040.00
        WHEN 'Pinheiros'       THEN 241195.00
        WHEN 'Olimpíadas'      THEN 148910.00
    END AS estoque_r,
    CASE s.nome
        WHEN 'Hélio Pelegrino' THEN 182505.00
        WHEN 'Faria Lima'      THEN  73715.00
        WHEN 'Pinheiros'       THEN  96600.00
        WHEN 'Olimpíadas'      THEN  95565.00
    END AS estoque_nr,
    -- teto_r_m2 = mesmo valor do estoque R (Lei 13.769 não tinha subsetores)
    CASE s.nome
        WHEN 'Hélio Pelegrino' THEN 257010.00
        WHEN 'Faria Lima'      THEN 275040.00
        WHEN 'Pinheiros'       THEN 241195.00
        WHEN 'Olimpíadas'      THEN 148910.00
    END AS teto_r_m2,
    CASE s.nome
        WHEN 'Hélio Pelegrino' THEN 182505.00
        WHEN 'Faria Lima'      THEN  73715.00
        WHEN 'Pinheiros'       THEN  96600.00
        WHEN 'Olimpíadas'      THEN  95565.00
    END AS teto_nr_m2,
    NULL AS reserva_r_m2
FROM setor s
JOIN lei_ouc lo ON lo.operacao_urbana_id = 2 AND lo.identificador = '13.769/2004'
WHERE s.operacao_urbana_id = 2;

-- ---------------------------------------------------------------------------
-- OUCFL — Estoque Lei 11.732/1995 (pré-OUC, consumido congelado)
-- ---------------------------------------------------------------------------
-- A Lei 11.732/1995 não tem estoque por setor — apenas consumo histórico
-- global de 940.000 m² (já registrado em lei_ouc).
-- Não insere registros em setor_estoque_lei para esta lei.

-- ---------------------------------------------------------------------------
-- Validação
-- ---------------------------------------------------------------------------
DO $$
DECLARE
    total_ae INT; total_ab INT; total_fl_175 INT; total_fl_769 INT;
BEGIN
    -- OUCAE: 5 setores × 1 lei vigente
    SELECT COUNT(*) INTO total_ae FROM setor_estoque_lei sel
        JOIN lei_ouc lo ON lo.id = sel.lei_ouc_id
        WHERE lo.operacao_urbana_id = 1;
    IF total_ae <> 5 THEN
        RAISE EXCEPTION 'OUCAE setor_estoque_lei: esperado 5, encontrado %', total_ae;
    END IF;

    -- OUCAB: 13 setores × 1 lei vigente
    SELECT COUNT(*) INTO total_ab FROM setor_estoque_lei sel
        JOIN lei_ouc lo ON lo.id = sel.lei_ouc_id
        WHERE lo.operacao_urbana_id = 3;
    IF total_ab <> 13 THEN
        RAISE EXCEPTION 'OUCAB setor_estoque_lei: esperado 13, encontrado %', total_ab;
    END IF;

    -- OUCFL Lei 18.175: 4 setores
    SELECT COUNT(*) INTO total_fl_175 FROM setor_estoque_lei sel
        JOIN lei_ouc lo ON lo.id = sel.lei_ouc_id
        WHERE lo.operacao_urbana_id = 2 AND lo.identificador = '18.175/2024';
    IF total_fl_175 <> 4 THEN
        RAISE EXCEPTION 'OUCFL 18.175 setor_estoque_lei: esperado 4, encontrado %', total_fl_175;
    END IF;

    -- OUCFL Lei 13.769: 4 setores
    SELECT COUNT(*) INTO total_fl_769 FROM setor_estoque_lei sel
        JOIN lei_ouc lo ON lo.id = sel.lei_ouc_id
        WHERE lo.operacao_urbana_id = 2 AND lo.identificador = '13.769/2004';
    IF total_fl_769 <> 4 THEN
        RAISE EXCEPTION 'OUCFL 13.769 setor_estoque_lei: esperado 4, encontrado %', total_fl_769;
    END IF;
END;
$$;

COMMIT;
