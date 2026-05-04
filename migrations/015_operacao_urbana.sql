-- =============================================================================
-- CEPAC — Migration 015: Cria tabela operacao_urbana e carga inicial
--
-- Contexto:
--   O sistema CEPAC foi originalmente modelado para a OUCAE (Operação Urbana
--   Consorciada Água Espraiada). Para suportar múltiplas Operações Urbanas
--   (Água Espraiada, Faria Lima, Água Branca), criamos esta tabela de
--   catálogo com os parâmetros globais de cada OUC.
--
-- Nota: Esta tabela é independente — nenhuma FK existente depende dela.
--       A vinculação com a tabela `setor` será feita em migration futura.
-- =============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- DDL
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS operacao_urbana (
    id                          SERIAL PRIMARY KEY,
    nome                        VARCHAR(100) NOT NULL,
    sigla                       VARCHAR(5) NOT NULL UNIQUE,
    lei_vigente                 VARCHAR(100),
    estoque_maximo_global_r     NUMERIC(15,2),
    estoque_maximo_global_nr    NUMERIC(15,2),
    possui_nuvem                BOOLEAN DEFAULT FALSE,
    valor_cepac_ref             NUMERIC(15,2),
    data_ultima_posicao         DATE,
    ativo                       BOOLEAN DEFAULT TRUE
);

-- ---------------------------------------------------------------------------
-- Seed — 3 Operações Urbanas Consorciadas de São Paulo
-- ---------------------------------------------------------------------------

INSERT INTO operacao_urbana (sigla, nome, lei_vigente,
                             estoque_maximo_global_r, estoque_maximo_global_nr,
                             possui_nuvem, valor_cepac_ref, data_ultima_posicao)
VALUES
    ('AE',
     'Operação Urbana Consorciada Água Espraiada',
     'Lei nº 18.174/2024',
     1450000.00,   -- Subtotal R permitido
     3150000.00,   -- Subtotal NR permitido
     TRUE,         -- possui NUVEM
     2175.37,      -- Preço mínimo do leilão mais recente
     '2026-04-13'),

    ('FL',
     'Operação Urbana Consorciada Faria Lima',
     'Lei nº 18.175/2024',
     1057770.00,   -- Base Lei 13.769/04
     448385.00,    -- Base Lei 13.769/04
     TRUE,         -- possui NUVEM
     17600.00,     -- Preço mínimo do leilão de agosto/2025
     '2026-04-08'),

    ('AB',
     'Operação Urbana Consorciada Água Branca',
     'Lei nº 15.893/2013 (atualizada pela Lei 17.561/21)',
     1350000.00,   -- Total, sendo 675.000m² limitados a uso R não incentivado
     500000.00,
     FALSE,        -- NÃO possui NUVEM
     1128.27,      -- Referência Não Residencial do leilão de out/2025
     '2026-03-31');

COMMIT;
