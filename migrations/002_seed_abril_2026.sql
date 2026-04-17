-- =============================================================================
-- CEPAC — SP Urbanismo / Prodam
-- Migration 002: Seed de Dados — Posição Estoque em 13/04/2026
-- PostgreSQL 15
--
-- Estratégia de idempotência:
--   - Setores: INSERT ... ON CONFLICT (nome) DO NOTHING
--   - Títulos sintéticos: INSERT ... WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = ...)
--   - Movimentações seed: INSERT ... WHERE NOT EXISTS (SELECT 1 FROM movimentacao WHERE titulo_id = ... AND motivo = 'SEED_INICIAL')
--
-- Cada título sintético representa consumo/reserva agregado por
-- combinação (setor × uso × origem × estado).
-- Códigos seguem o padrão: SEED-{SETOR}-{USO}-{ORIGEM}-{ESTADO}
--
-- Totalizando 13 títulos sintéticos:
--   Brooklin         : 1 título
--   Berrini          : 3 títulos
--   Marginal Pinheiros: 3 títulos
--   Chucri Zaidan    : 5 títulos
--   Jabaquara        : 0 títulos (todos zerados)
-- =============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Inserir setores (idempotente via ON CONFLICT)
-- ---------------------------------------------------------------------------

INSERT INTO setor (nome, estoque_total_m2, teto_nr_m2, reserva_r_m2)
VALUES
    ('Brooklin',           1400000.00,  980000.00,       NULL),
    ('Berrini',             350000.00,  175000.00,       NULL),
    ('Marginal Pinheiros',  600000.00,  420000.00,       NULL),
    ('Chucri Zaidan',      2000000.00, 1783557.53, 216442.47),
    ('Jabaquara',           250000.00,  175000.00,       NULL)
ON CONFLICT (nome) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 2. Inserir títulos sintéticos de consolidação (idempotente via WHERE NOT EXISTS)
--
-- Posição em 13/04/2026:
--
-- Brooklin:
--   NR ACA  CONSUMIDO  = 716.470,01 m²
--
-- Berrini:
--   NR ACA   CONSUMIDO = 203.202,23 m²
--   NR NUVEM CONSUMIDO =     595,00 m²
--   R  NUVEM CONSUMIDO =     100,62 m²
--
-- Marginal Pinheiros:
--   NR ACA   CONSUMIDO = 258.908,19 m²
--   R  NUVEM CONSUMIDO =   1.301,13 m²
--   NR ACA   EM_ANALISE =  11.173,06 m²
--
-- Chucri Zaidan:
--   NR ACA   CONSUMIDO  = 1.050.881,42 m²
--   NR NUVEM CONSUMIDO  =       434,79 m²
--   R  ACA   CONSUMIDO  =   751.909,09 m²
--   R  NUVEM CONSUMIDO  =       204,70 m²
--   R  ACA   EM_ANALISE =    14.006,35 m²
--
-- Jabaquara: todos zerados — nenhum título inserido.
-- ---------------------------------------------------------------------------

-- ---[ Brooklin ]-------------------------------------------------------------

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado)
SELECT
    'SEED-BROOKLIN-NR-ACA-CONSUMIDO',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    716470.01,
    'NR', 'ACA', 'CONSUMIDO'
WHERE NOT EXISTS (
    SELECT 1 FROM titulo_cepac
    WHERE codigo = 'SEED-BROOKLIN-NR-ACA-CONSUMIDO'
);

-- ---[ Berrini ]--------------------------------------------------------------

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado)
SELECT
    'SEED-BERRINI-NR-ACA-CONSUMIDO',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    203202.23,
    'NR', 'ACA', 'CONSUMIDO'
WHERE NOT EXISTS (
    SELECT 1 FROM titulo_cepac
    WHERE codigo = 'SEED-BERRINI-NR-ACA-CONSUMIDO'
);

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado)
SELECT
    'SEED-BERRINI-NR-NUVEM-CONSUMIDO',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    595.00,
    'NR', 'NUVEM', 'CONSUMIDO'
WHERE NOT EXISTS (
    SELECT 1 FROM titulo_cepac
    WHERE codigo = 'SEED-BERRINI-NR-NUVEM-CONSUMIDO'
);

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado)
SELECT
    'SEED-BERRINI-R-NUVEM-CONSUMIDO',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    100.62,
    'R', 'NUVEM', 'CONSUMIDO'
WHERE NOT EXISTS (
    SELECT 1 FROM titulo_cepac
    WHERE codigo = 'SEED-BERRINI-R-NUVEM-CONSUMIDO'
);

-- ---[ Marginal Pinheiros ]---------------------------------------------------

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado)
SELECT
    'SEED-MARGINAL-NR-ACA-CONSUMIDO',
    (SELECT id FROM setor WHERE nome = 'Marginal Pinheiros'),
    258908.19,
    'NR', 'ACA', 'CONSUMIDO'
WHERE NOT EXISTS (
    SELECT 1 FROM titulo_cepac
    WHERE codigo = 'SEED-MARGINAL-NR-ACA-CONSUMIDO'
);

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado)
SELECT
    'SEED-MARGINAL-R-NUVEM-CONSUMIDO',
    (SELECT id FROM setor WHERE nome = 'Marginal Pinheiros'),
    1301.13,
    'R', 'NUVEM', 'CONSUMIDO'
WHERE NOT EXISTS (
    SELECT 1 FROM titulo_cepac
    WHERE codigo = 'SEED-MARGINAL-R-NUVEM-CONSUMIDO'
);

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado)
SELECT
    'SEED-MARGINAL-NR-ACA-EM_ANALISE',
    (SELECT id FROM setor WHERE nome = 'Marginal Pinheiros'),
    11173.06,
    'NR', 'ACA', 'EM_ANALISE'
WHERE NOT EXISTS (
    SELECT 1 FROM titulo_cepac
    WHERE codigo = 'SEED-MARGINAL-NR-ACA-EM_ANALISE'
);

-- ---[ Chucri Zaidan ]--------------------------------------------------------

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado)
SELECT
    'SEED-CHUCRI-NR-ACA-CONSUMIDO',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    1050881.42,
    'NR', 'ACA', 'CONSUMIDO'
WHERE NOT EXISTS (
    SELECT 1 FROM titulo_cepac
    WHERE codigo = 'SEED-CHUCRI-NR-ACA-CONSUMIDO'
);

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado)
SELECT
    'SEED-CHUCRI-NR-NUVEM-CONSUMIDO',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    434.79,
    'NR', 'NUVEM', 'CONSUMIDO'
WHERE NOT EXISTS (
    SELECT 1 FROM titulo_cepac
    WHERE codigo = 'SEED-CHUCRI-NR-NUVEM-CONSUMIDO'
);

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado)
SELECT
    'SEED-CHUCRI-R-ACA-CONSUMIDO',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    751909.09,
    'R', 'ACA', 'CONSUMIDO'
WHERE NOT EXISTS (
    SELECT 1 FROM titulo_cepac
    WHERE codigo = 'SEED-CHUCRI-R-ACA-CONSUMIDO'
);

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado)
SELECT
    'SEED-CHUCRI-R-NUVEM-CONSUMIDO',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    204.70,
    'R', 'NUVEM', 'CONSUMIDO'
WHERE NOT EXISTS (
    SELECT 1 FROM titulo_cepac
    WHERE codigo = 'SEED-CHUCRI-R-NUVEM-CONSUMIDO'
);

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado)
SELECT
    'SEED-CHUCRI-R-ACA-EM_ANALISE',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    14006.35,
    'R', 'ACA', 'EM_ANALISE'
WHERE NOT EXISTS (
    SELECT 1 FROM titulo_cepac
    WHERE codigo = 'SEED-CHUCRI-R-ACA-EM_ANALISE'
);

-- ---------------------------------------------------------------------------
-- 3. Inserir movimentações seed para cada título sintético
--
-- Regras:
--   - estado_anterior = NULL  (registro inicial — sem estado prévio)
--   - motivo           = 'SEED_INICIAL'
--   - operador         = 'SISTEMA'
--   - numero_processo_sei = 'SEED-INICIAL-2026'
--   - Idempotente: WHERE NOT EXISTS por (titulo_id, motivo)
-- ---------------------------------------------------------------------------

INSERT INTO movimentacao (
    titulo_id,
    setor_id,
    uso,
    origem,
    estado_anterior,
    estado_novo,
    numero_processo_sei,
    motivo,
    operador
)
SELECT
    t.id,
    t.setor_id,
    t.uso,
    t.origem,
    NULL,           -- estado_anterior NULL = registro inicial
    t.estado,
    'SEED-INICIAL-2026',
    'SEED_INICIAL',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo LIKE 'SEED-%'
  AND NOT EXISTS (
      SELECT 1
      FROM movimentacao m
      WHERE m.titulo_id = t.id
        AND m.motivo = 'SEED_INICIAL'
  );

COMMIT;
