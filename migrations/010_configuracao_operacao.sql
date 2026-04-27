-- =============================================================================
-- CEPAC — Migration 010: Tabela configuracao_operacao
-- Parâmetros globais da OUCAE. Singleton (id = 1 sempre).
-- reserva_tecnica_m2: CEPACs reservados para uso técnico da Prefeitura,
-- somados ao estoque setorial para compor a capacidade total da operação.
-- Idempotente via IF NOT EXISTS / ON CONFLICT DO NOTHING.
-- =============================================================================

BEGIN;

CREATE TABLE IF NOT EXISTS configuracao_operacao (
    id            SMALLINT    PRIMARY KEY DEFAULT 1,
    reserva_tecnica_m2  NUMERIC(15, 2) NOT NULL DEFAULT 0,
    updated_at    TIMESTAMP   NOT NULL DEFAULT now(),
    CONSTRAINT ck_singleton CHECK (id = 1)
);

INSERT INTO configuracao_operacao (id, reserva_tecnica_m2)
VALUES (1, 0)
ON CONFLICT DO NOTHING;

COMMIT;
