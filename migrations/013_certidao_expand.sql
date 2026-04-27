-- =============================================================================
-- CEPAC — Migration 013: Expandir tabela certidao com campos da planilha
--
-- Alterações:
--   1. Adicionar ANALISE ao enum situacao_certidao_enum (idempotente).
--   2. 17 novas colunas na tabela certidao (uso_aca, ACA, contrapartida,
--      CEPACs, NUVEM, contribuinte, obs).
--   3. Campo situacao_certidao VARCHAR(10) na tabela proposta
--      (status derivado da certidão representativa do AE-XXXX).
--
-- Idempotente via ADD COLUMN IF NOT EXISTS e ALTER TYPE ... ADD VALUE IF NOT EXISTS.
-- =============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Adicionar ANALISE ao enum situacao_certidao_enum
-- ---------------------------------------------------------------------------

ALTER TYPE situacao_certidao_enum ADD VALUE IF NOT EXISTS 'ANALISE';

-- ---------------------------------------------------------------------------
-- 2. Novos campos na tabela certidao
-- ---------------------------------------------------------------------------

ALTER TABLE certidao
  ADD COLUMN IF NOT EXISTS uso_aca           VARCHAR(10),
  ADD COLUMN IF NOT EXISTS aca_r_m2          NUMERIC(15, 2),
  ADD COLUMN IF NOT EXISTS aca_nr_m2         NUMERIC(15, 2),
  ADD COLUMN IF NOT EXISTS aca_total_m2      NUMERIC(15, 2),
  ADD COLUMN IF NOT EXISTS tipo_contrapartida TEXT,
  ADD COLUMN IF NOT EXISTS valor_oodc_rs     NUMERIC(18, 2),
  ADD COLUMN IF NOT EXISTS cepac_aca         INTEGER,
  ADD COLUMN IF NOT EXISTS cepac_parametros  INTEGER,
  ADD COLUMN IF NOT EXISTS cepac_total       INTEGER,
  ADD COLUMN IF NOT EXISTS nuvem_r_m2        NUMERIC(15, 2),
  ADD COLUMN IF NOT EXISTS nuvem_nr_m2       NUMERIC(15, 2),
  ADD COLUMN IF NOT EXISTS nuvem_total_m2    NUMERIC(15, 2),
  ADD COLUMN IF NOT EXISTS nuvem_cepac       INTEGER,
  ADD COLUMN IF NOT EXISTS contribuinte_sq   TEXT,
  ADD COLUMN IF NOT EXISTS contribuinte_lote TEXT,
  ADD COLUMN IF NOT EXISTS obs               TEXT;

COMMENT ON COLUMN certidao.uso_aca IS
    'Uso na ACA conforme linha da planilha: R, NR ou MISTO.';
COMMENT ON COLUMN certidao.aca_r_m2 IS
    'Área construída adicional residencial (m²) registrada na ACA para esta certidão.';
COMMENT ON COLUMN certidao.aca_nr_m2 IS
    'Área construída adicional não-residencial (m²) registrada na ACA para esta certidão.';
COMMENT ON COLUMN certidao.aca_total_m2 IS
    'Área construída adicional total (m²) registrada na ACA para esta certidão.';
COMMENT ON COLUMN certidao.tipo_contrapartida IS
    'Forma de pagamento: CEPAC (título) ou OODC (dinheiro).';
COMMENT ON COLUMN certidao.valor_oodc_rs IS
    'Valor pago via OODC (R$) quando tipo_contrapartida = OODC (dinheiro).';
COMMENT ON COLUMN certidao.cepac_aca IS
    'Quantidade de CEPACs utilizados para conversão de área (ACA) nesta certidão.';
COMMENT ON COLUMN certidao.cepac_parametros IS
    'Quantidade de CEPACs utilizados para parâmetros urbanísticos nesta certidão.';
COMMENT ON COLUMN certidao.cepac_total IS
    'Total de CEPACs desta certidão (aca + parametros).';
COMMENT ON COLUMN certidao.nuvem_r_m2 IS
    'Área residencial (m²) registrada na plataforma NUVEM para esta certidão.';
COMMENT ON COLUMN certidao.nuvem_nr_m2 IS
    'Área não-residencial (m²) registrada na plataforma NUVEM para esta certidão.';
COMMENT ON COLUMN certidao.nuvem_total_m2 IS
    'Área total (m²) registrada na plataforma NUVEM para esta certidão.';
COMMENT ON COLUMN certidao.nuvem_cepac IS
    'Quantidade de CEPACs registrados na plataforma NUVEM para esta certidão.';
COMMENT ON COLUMN certidao.contribuinte_sq IS
    'Número de Contribuinte SQ associado a esta certidão.';
COMMENT ON COLUMN certidao.contribuinte_lote IS
    'Identificação do lote do contribuinte associado a esta certidão.';
COMMENT ON COLUMN certidao.obs IS
    'Observações livres sobre esta certidão.';

-- ---------------------------------------------------------------------------
-- 3. Campo situacao_certidao na tabela proposta
--    (status derivado da certidão representativa; preenchido pelo script de carga)
--
-- Nota: a coluna já existe como VARCHAR(20) desde a migration 012.
-- A instrução ADD COLUMN IF NOT EXISTS é idempotente — não causa erro quando
-- a coluna já existe, portanto este bloco é mantido apenas como documentação
-- de intenção. O script de carga (carga_planilha_abr2026.py) preenche este
-- campo com o SITUACAO da linha representativa de cada AE-XXXX.
-- ---------------------------------------------------------------------------

ALTER TABLE proposta
  ADD COLUMN IF NOT EXISTS situacao_certidao VARCHAR(10);

COMMIT;
