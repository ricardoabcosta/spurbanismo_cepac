-- =============================================================================
-- CEPAC — Migration 012: Campos da planilha OUCAE na tabela proposta
--
-- Alterações:
--   1. 21 colunas novas de controle/auditoria da planilha (contribuinte, ACA,
--      nuvem, certidão, contrapartida, responsáveis, cross-check, obs).
--   2. Separação de cnpj_cpf em cnpj e cpf distintos, com migração dos dados
--      existentes (heurística: presença de "/" identifica CNPJ).
--   3. Novo valor EM_ANALISE em status_solicitacao_enum (idempotente).
--   4. Novo valor MISTO em uso_enum (idempotente).
--   5. Campo data_proposta DATE (item 2.1 do formulário).
--   6. Campo tipo_interessado VARCHAR(5) — valores 'PF' ou 'PJ'.
--
-- Idempotente via ADD COLUMN IF NOT EXISTS e ALTER TYPE ... ADD VALUE IF NOT EXISTS.
-- =============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. 21 novas colunas na tabela proposta
-- ---------------------------------------------------------------------------

ALTER TABLE proposta
    ADD COLUMN IF NOT EXISTS contribuinte_sq       TEXT,
    ADD COLUMN IF NOT EXISTS contribuinte_lote     TEXT,
    ADD COLUMN IF NOT EXISTS uso_aca               VARCHAR(10),
    ADD COLUMN IF NOT EXISTS aca_r_m2              NUMERIC(15, 2),
    ADD COLUMN IF NOT EXISTS aca_nr_m2             NUMERIC(15, 2),
    ADD COLUMN IF NOT EXISTS aca_total_m2          NUMERIC(15, 2),
    ADD COLUMN IF NOT EXISTS tipo_contrapartida    VARCHAR(20),
    ADD COLUMN IF NOT EXISTS valor_oodc_rs         NUMERIC(18, 2),
    ADD COLUMN IF NOT EXISTS cepac_aca             INTEGER,
    ADD COLUMN IF NOT EXISTS cepac_parametros      INTEGER,
    ADD COLUMN IF NOT EXISTS cepac_total           INTEGER,
    ADD COLUMN IF NOT EXISTS certidao              VARCHAR(30),
    ADD COLUMN IF NOT EXISTS situacao_certidao     VARCHAR(20),
    ADD COLUMN IF NOT EXISTS data_certidao         DATE,
    ADD COLUMN IF NOT EXISTS nuvem_r_m2            NUMERIC(15, 2),
    ADD COLUMN IF NOT EXISTS nuvem_nr_m2           NUMERIC(15, 2),
    ADD COLUMN IF NOT EXISTS nuvem_total_m2        NUMERIC(15, 2),
    ADD COLUMN IF NOT EXISTS nuvem_cepac           INTEGER,
    ADD COLUMN IF NOT EXISTS obs                   TEXT,
    ADD COLUMN IF NOT EXISTS resp_data             VARCHAR(100),
    ADD COLUMN IF NOT EXISTS cross_check           VARCHAR(100);

COMMENT ON COLUMN proposta.contribuinte_sq IS
    'Número de Contribuinte — coluna SQ da planilha OUCAE.';
COMMENT ON COLUMN proposta.contribuinte_lote IS
    'Identificação do lote do contribuinte — planilha OUCAE.';
COMMENT ON COLUMN proposta.uso_aca IS
    'Uso na ACA: R (Residencial), NR (Não-Residencial) ou MISTO.';
COMMENT ON COLUMN proposta.aca_r_m2 IS
    'Área construída adicional residencial registrada na ACA (m²).';
COMMENT ON COLUMN proposta.aca_nr_m2 IS
    'Área construída adicional não-residencial registrada na ACA (m²).';
COMMENT ON COLUMN proposta.aca_total_m2 IS
    'Área construída adicional total registrada na ACA (m²).';
COMMENT ON COLUMN proposta.tipo_contrapartida IS
    'Forma de pagamento da contrapartida: ''CEPAC (título)'' ou ''OODC (dinheiro)''.';
COMMENT ON COLUMN proposta.valor_oodc_rs IS
    'Valor pago via OODC em reais, quando tipo_contrapartida = ''OODC (dinheiro)''.';
COMMENT ON COLUMN proposta.cepac_aca IS
    'Quantidade de CEPACs utilizados para conversão de área (ACA).';
COMMENT ON COLUMN proposta.cepac_parametros IS
    'Quantidade de CEPACs utilizados para parâmetros urbanísticos.';
COMMENT ON COLUMN proposta.cepac_total IS
    'Total de CEPACs vinculados ao empreendimento (aca + parametros).';
COMMENT ON COLUMN proposta.certidao IS
    'Número da certidão vinculada à proposta (ex: AE-001/2024).';
COMMENT ON COLUMN proposta.situacao_certidao IS
    'Situação da certidão: VALIDA ou CANCELADA.';
COMMENT ON COLUMN proposta.data_certidao IS
    'Data de emissão da certidão.';
COMMENT ON COLUMN proposta.nuvem_r_m2 IS
    'Área residencial registrada na plataforma NUVEM (m²).';
COMMENT ON COLUMN proposta.nuvem_nr_m2 IS
    'Área não-residencial registrada na plataforma NUVEM (m²).';
COMMENT ON COLUMN proposta.nuvem_total_m2 IS
    'Área total registrada na plataforma NUVEM (m²).';
COMMENT ON COLUMN proposta.nuvem_cepac IS
    'Quantidade de CEPACs registrados na plataforma NUVEM.';
COMMENT ON COLUMN proposta.obs IS
    'Observações livres sobre a proposta — campo de texto da planilha.';
COMMENT ON COLUMN proposta.resp_data IS
    'Responsável e data de análise (coluna resp_data da planilha).';
COMMENT ON COLUMN proposta.cross_check IS
    'Resultado do cruzamento de dados entre ACA e NUVEM (coluna cross_check).';

-- ---------------------------------------------------------------------------
-- 2. Separação de cnpj_cpf em cnpj e cpf distintos
--    A coluna original cnpj_cpf é mantida por compatibilidade; os novos campos
--    são populados via heurística: presença de "/" identifica CNPJ.
-- ---------------------------------------------------------------------------

ALTER TABLE proposta
    ADD COLUMN IF NOT EXISTS cnpj TEXT,
    ADD COLUMN IF NOT EXISTS cpf  TEXT;

COMMENT ON COLUMN proposta.cnpj IS
    'CNPJ do interessado (pessoa jurídica). Separado de cpf a partir da migration 012.';
COMMENT ON COLUMN proposta.cpf IS
    'CPF do interessado (pessoa física). Separado de cnpj a partir da migration 012.';

-- Migração dos dados: cnpj_cpf que contenha "/" é CNPJ, caso contrário CPF.
UPDATE proposta
SET
    cnpj = CASE WHEN cnpj_cpf LIKE '%/%' THEN cnpj_cpf ELSE NULL END,
    cpf  = CASE WHEN cnpj_cpf NOT LIKE '%/%' AND cnpj_cpf IS NOT NULL THEN cnpj_cpf ELSE NULL END
WHERE cnpj_cpf IS NOT NULL
  AND cnpj IS NULL
  AND cpf  IS NULL;

-- ---------------------------------------------------------------------------
-- 3. Adicionar EM_ANALISE ao enum status_solicitacao_enum (idempotente)
-- ---------------------------------------------------------------------------

ALTER TYPE status_solicitacao_enum ADD VALUE IF NOT EXISTS 'EM_ANALISE';

-- ---------------------------------------------------------------------------
-- 4. Adicionar MISTO ao enum uso_enum (idempotente)
-- ---------------------------------------------------------------------------

ALTER TYPE uso_enum ADD VALUE IF NOT EXISTS 'MISTO';

-- ---------------------------------------------------------------------------
-- 5. Campo data_proposta DATE — item 2.1 do formulário
-- ---------------------------------------------------------------------------

ALTER TABLE proposta
    ADD COLUMN IF NOT EXISTS data_proposta DATE;

COMMENT ON COLUMN proposta.data_proposta IS
    'Data da proposta conforme item 2.1 do formulário de vinculação.';

-- ---------------------------------------------------------------------------
-- 6. Campo tipo_interessado — 'PF' (pessoa física) ou 'PJ' (pessoa jurídica)
-- ---------------------------------------------------------------------------

ALTER TABLE proposta
    ADD COLUMN IF NOT EXISTS tipo_interessado VARCHAR(5);

COMMENT ON COLUMN proposta.tipo_interessado IS
    'Tipo do interessado: PF (pessoa física) ou PJ (pessoa jurídica).';

COMMIT;
