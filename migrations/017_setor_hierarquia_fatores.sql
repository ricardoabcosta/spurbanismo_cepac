-- =============================================================================
-- CEPAC — Migration 017: Hierarquia de subsetores + Fatores de Equivalência
--
-- Adiciona:
--   setor_pai_id          — FK self-referencial (NULL = setor raiz)
--   fator_equivalencia_f1 — Fator F1 (NULL até parametrização por operação)
--   fator_equivalencia_f2 — Fator F2 (NULL até parametrização por operação)
--
-- Todos os campos iniciam como NULL em todos os setores existentes.
-- =============================================================================

BEGIN;

ALTER TABLE setor
    ADD COLUMN setor_pai_id          UUID         REFERENCES setor(id),
    ADD COLUMN fator_equivalencia_f1 NUMERIC(10,6),
    ADD COLUMN fator_equivalencia_f2 NUMERIC(10,6);

CREATE INDEX idx_setor_pai_id ON setor(setor_pai_id);

COMMIT;
