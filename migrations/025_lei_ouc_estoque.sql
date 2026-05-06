-- =============================================================================
-- CEPAC — Migration 025: Tabelas lei_ouc e setor_estoque_lei
--
-- Cria o catálogo cronológico de leis aplicáveis a cada OUC (lei_ouc)
-- e o estoque por setor × lei (setor_estoque_lei).
--
-- Referência: docs/planejamento-carga-oucfl.md §4.1
-- =============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- lei_ouc: Catálogo de leis de uma OUC em ordem cronológica
-- ---------------------------------------------------------------------------
CREATE TABLE lei_ouc (
    id                       SERIAL PRIMARY KEY,
    operacao_urbana_id       INTEGER NOT NULL REFERENCES operacao_urbana(id) ON DELETE CASCADE,
    identificador            VARCHAR(30) NOT NULL,   -- Ex: "11.732/1995", "18.175/2024"
    nome                     VARCHAR(150),
    data_vigencia_inicio     DATE,
    data_vigencia_fim        DATE,                   -- NULL = lei vigente
    ordem                    INTEGER NOT NULL,       -- 1 = mais antiga
    vigente                  BOOLEAN NOT NULL DEFAULT FALSE,
    consumo_historico_r_m2   NUMERIC(15,2),          -- Preenchido só em leis encerradas
    consumo_historico_nr_m2  NUMERIC(15,2),          -- Preenchido só em leis encerradas
    estoque_geral_m2         NUMERIC(15,2),          -- Estoque global da OUC sob esta lei
    UNIQUE (operacao_urbana_id, identificador),
    UNIQUE (operacao_urbana_id, ordem)
);
CREATE INDEX idx_lei_ouc_vigente ON lei_ouc(operacao_urbana_id, vigente);

COMMENT ON TABLE lei_ouc IS 'Catálogo cronológico de leis aplicáveis a cada OUC';
COMMENT ON COLUMN lei_ouc.consumo_historico_r_m2 IS
    'Consumo R congelado de leis encerradas (preenchido apenas em leis anteriores à vigente)';
COMMENT ON COLUMN lei_ouc.consumo_historico_nr_m2 IS
    'Consumo NR congelado de leis encerradas (preenchido apenas em leis anteriores à vigente)';

-- ---------------------------------------------------------------------------
-- setor_estoque_lei: Estoque por setor para cada lei
-- ---------------------------------------------------------------------------
CREATE TABLE setor_estoque_lei (
    id                     SERIAL PRIMARY KEY,
    setor_id               UUID NOT NULL REFERENCES setor(id) ON DELETE CASCADE,
    lei_ouc_id             INTEGER NOT NULL REFERENCES lei_ouc(id) ON DELETE CASCADE,
    estoque_total_r_m2     NUMERIC(15,2) NOT NULL,
    estoque_total_nr_m2    NUMERIC(15,2) NOT NULL,
    teto_r_m2              NUMERIC(15,2),
    teto_nr_m2             NUMERIC(15,2),
    reserva_r_m2           NUMERIC(15,2),
    UNIQUE (setor_id, lei_ouc_id)
);

COMMENT ON TABLE setor_estoque_lei IS
    'Estoque máximo de cada setor segregado por lei (R e NR)';

COMMIT;
