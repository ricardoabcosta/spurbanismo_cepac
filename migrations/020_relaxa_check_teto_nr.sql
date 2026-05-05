-- =============================================================================
-- CEPAC — Migration 021: Relaxa check teto_nr_m2 de > 0 para >= 0
--
-- Contexto: Setor C da OUCAB é exclusivamente residencial (teto NR = 0).
-- O constraint original não previa setores sem quota NR.
-- =============================================================================

BEGIN;

ALTER TABLE setor DROP CONSTRAINT ck_setor_teto_nr_positivo;
ALTER TABLE setor ADD CONSTRAINT ck_setor_teto_nr_positivo CHECK (teto_nr_m2 >= 0);

COMMIT;
