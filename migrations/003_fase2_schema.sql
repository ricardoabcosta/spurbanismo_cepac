-- =============================================================================
-- CEPAC — SP Urbanismo / Prodam
-- Migration 003: Schema Fase 2
-- PostgreSQL 15
--
-- Novas tabelas:
--   proposta          — cada projeto/empreendimento que vinculou CEPACs
--   certidao          — certidões emitidas (consulta pública de autenticidade)
--   usuario           — técnicos e diretores autenticados via Azure AD
--   documento_processo — documentos no Azure Blob Storage (metadados apenas)
--   medicao_obra      — série histórica de medições de obras (append-only)
--   parametro_sistema — valores configuráveis (CEPACs em circulação, datas, etc.)
--
-- Nenhuma tabela da Fase 1 é alterada.
-- Idempotente: CREATE TABLE IF NOT EXISTS + CREATE TYPE com tratamento de duplicatas.
-- =============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- ENUM TYPES (Fase 2)
-- ---------------------------------------------------------------------------

DO $$ BEGIN
    CREATE TYPE status_pa_enum AS ENUM ('DEFERIDO', 'INDEFERIDO', 'ANALISE');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE requerimento_enum AS ENUM ('VINCULACAO', 'ALTERACAO', 'DESVINCULACAO');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE tipo_certidao_enum AS ENUM ('VINCULAÇÃO', 'DESVINCULAÇÃO', 'ALTERAÇÃO');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE situacao_certidao_enum AS ENUM ('VALIDA', 'CANCELADA');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE papel_usuario_enum AS ENUM ('TECNICO', 'DIRETOR');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE tipo_processo_enum AS ENUM ('SIMPROC', 'SEI');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ---------------------------------------------------------------------------
-- TABLE: proposta
--
-- Representa cada projeto/empreendimento que solicitou vinculação de CEPACs.
-- Código no formato AE-XXXX. Agrupa as certidões de emenda do mesmo projeto.
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS proposta (
    id               UUID          NOT NULL DEFAULT gen_random_uuid(),
    codigo           VARCHAR(20)   NOT NULL,
    -- Número do processo administrativo (aceita SIMPROC e SEI — D2)
    numero_pa        TEXT          NULL,
    tipo_processo    tipo_processo_enum NULL,
    data_autuacao    DATE          NULL,
    status_pa        status_pa_enum NOT NULL DEFAULT 'ANALISE',
    interessado      VARCHAR(300)  NULL,
    cnpj_cpf         VARCHAR(20)   NULL,
    endereco         TEXT          NULL,
    setor_id         UUID          NOT NULL,
    requerimento     requerimento_enum NOT NULL,
    area_terreno_m2  NUMERIC(15, 2) NULL,
    -- Observação sobre diferença devida em certidões de alteração (D7)
    observacao_alteracao TEXT      NULL,
    created_at       TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ   NOT NULL DEFAULT now(),

    CONSTRAINT pk_proposta PRIMARY KEY (id),
    CONSTRAINT uq_proposta_codigo UNIQUE (codigo),
    CONSTRAINT fk_proposta_setor FOREIGN KEY (setor_id)
        REFERENCES setor (id) ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_proposta_setor_status
    ON proposta (setor_id, status_pa);

CREATE INDEX IF NOT EXISTS idx_proposta_numero_pa
    ON proposta (numero_pa)
    WHERE numero_pa IS NOT NULL;

COMMENT ON TABLE proposta IS
    'Cada projeto/empreendimento que solicitou vinculação de CEPACs na OUCAE. '
    'Código no formato AE-XXXX. Agrupa todas as certidões de emenda do mesmo projeto.';
COMMENT ON COLUMN proposta.numero_pa IS
    'Número do processo administrativo. Aceita padrão SIMPROC (2004-2015) '
    'e padrão SEI (2016+). Armazenado como TEXT sem validação de formato (D2).';
COMMENT ON COLUMN proposta.observacao_alteracao IS
    'Preenchido quando certidão de alteração tem área diferente da anterior. '
    'Registra situação de diferença devida ou excedente em NUVEM (D7).';

-- ---------------------------------------------------------------------------
-- TABLE: certidao
--
-- Certidões emitidas pela SP Urbanismo. Base do módulo de Consulta Pública
-- de Autenticidade — acessível ao munícipe sem autenticação (T14).
-- Append-only: certidões emitidas não são deletadas nem alteradas.
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS certidao (
    id                  UUID         NOT NULL DEFAULT gen_random_uuid(),
    proposta_id         UUID         NOT NULL,
    numero_certidao     VARCHAR(20)  NOT NULL,
    tipo                tipo_certidao_enum NOT NULL,
    data_emissao        DATE         NULL,
    -- Aceita ambos os padrões SIMPROC e SEI (D2)
    numero_processo_sei TEXT         NULL,
    situacao            situacao_certidao_enum NOT NULL DEFAULT 'VALIDA',
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT now(),

    CONSTRAINT pk_certidao PRIMARY KEY (id),
    CONSTRAINT uq_certidao_numero UNIQUE (numero_certidao),
    CONSTRAINT fk_certidao_proposta FOREIGN KEY (proposta_id)
        REFERENCES proposta (id) ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_certidao_proposta
    ON certidao (proposta_id);

CREATE INDEX IF NOT EXISTS idx_certidao_situacao_tipo
    ON certidao (situacao, tipo);

COMMENT ON TABLE certidao IS
    'Certidões de vinculação, desvinculação e alteração emitidas pela SP Urbanismo. '
    'Base do módulo de Consulta Pública de Autenticidade (T14). Append-only.';
COMMENT ON COLUMN certidao.numero_certidao IS
    'Formato: AE-001/2024 (vinculação/alteração) ou DV-001/2026 (desvinculação).';

-- ---------------------------------------------------------------------------
-- TABLE: usuario
--
-- Técnicos e Diretores autenticados via Azure AD.
-- Roles gerenciados na aplicação (não no AD) — D4.
-- Criado automaticamente no primeiro login com papel=TECNICO.
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS usuario (
    id             UUID         NOT NULL DEFAULT gen_random_uuid(),
    upn            VARCHAR(200) NOT NULL,
    nome           VARCHAR(200) NULL,
    papel          papel_usuario_enum NOT NULL DEFAULT 'TECNICO',
    ativo          BOOLEAN      NOT NULL DEFAULT true,
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
    last_login_at  TIMESTAMPTZ  NULL,

    CONSTRAINT pk_usuario PRIMARY KEY (id),
    CONSTRAINT uq_usuario_upn UNIQUE (upn)
);

COMMENT ON TABLE usuario IS
    'Usuários autenticados via Azure AD. Roles (TECNICO/DIRETOR) gerenciados '
    'internamente na aplicação — não usa App Roles do Azure AD (D4). '
    'Criado automaticamente no primeiro login com papel=TECNICO.';
COMMENT ON COLUMN usuario.upn IS
    'User Principal Name do Azure AD (ex: joao.silva@spurbanismo.sp.gov.br).';
COMMENT ON COLUMN usuario.papel IS
    'Papel do usuário. Default TECNICO. Promoção a DIRETOR via endpoint '
    'administrativo PATCH /admin/usuarios/{id}/papel.';

-- ---------------------------------------------------------------------------
-- TABLE: documento_processo
--
-- Metadados de documentos armazenados no Azure Blob Storage.
-- O arquivo físico nunca é armazenado no banco — apenas o caminho no Blob.
-- Append-only: documentos não são deletados (exigência de auditoria).
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS documento_processo (
    id                  UUID          NOT NULL DEFAULT gen_random_uuid(),
    proposta_id         UUID          NOT NULL,
    -- Aceita ambos os padrões SIMPROC e SEI (D2)
    numero_processo_sei TEXT          NOT NULL,
    nome_arquivo        VARCHAR(500)  NOT NULL,
    blob_path           VARCHAR(1000) NOT NULL,
    content_type        VARCHAR(100)  NULL,
    tamanho_bytes       BIGINT        NULL,
    operador_id         UUID          NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),

    CONSTRAINT pk_documento PRIMARY KEY (id),
    CONSTRAINT fk_documento_proposta FOREIGN KEY (proposta_id)
        REFERENCES proposta (id) ON DELETE RESTRICT,
    CONSTRAINT fk_documento_operador FOREIGN KEY (operador_id)
        REFERENCES usuario (id) ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_documento_proposta
    ON documento_processo (proposta_id);

COMMENT ON TABLE documento_processo IS
    'Metadados de documentos no Azure Blob Storage. '
    'Arquivo físico nunca transita pelo backend — upload direto via SAS URL (T13). '
    'Append-only: documentos não são deletados por exigência de auditoria.';
COMMENT ON COLUMN documento_processo.blob_path IS
    'Caminho no Blob Storage: {ano}/{mes}/{uuid}-{nome_arquivo}. '
    'Container: cepac-documentos (private — acesso via SAS token).';

-- Trigger: impede DELETE em documento_processo
CREATE OR REPLACE FUNCTION fn_documento_immutable()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION
        'Documentos são imutáveis. DELETE em documento_processo não é permitido.';
END;
$$;

DROP TRIGGER IF EXISTS trg_documento_no_delete ON documento_processo;
CREATE TRIGGER trg_documento_no_delete
    BEFORE DELETE ON documento_processo
    FOR EACH ROW EXECUTE FUNCTION fn_documento_immutable();

-- ---------------------------------------------------------------------------
-- TABLE: medicao_obra
--
-- Série histórica de medições mensais de obras — base do "Custo Total Incorrido".
-- Append-only: idêntico ao padrão de movimentacao (Fase 1).
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS medicao_obra (
    id               UUID          NOT NULL DEFAULT gen_random_uuid(),
    -- Primeiro dia do mês de competência (ex: 2026-04-01)
    data_referencia  DATE          NOT NULL,
    -- Valor da medição mensal em R$
    valor_medicao    NUMERIC(18, 2) NOT NULL,
    -- Custo total acumulado após esta medição (calculado pela aplicação)
    valor_acumulado  NUMERIC(18, 2) NOT NULL,
    descricao        TEXT          NULL,
    -- Aceita ambos os padrões SIMPROC e SEI (D2)
    numero_processo_sei TEXT        NOT NULL,
    operador_id      UUID          NOT NULL,
    created_at       TIMESTAMPTZ   NOT NULL DEFAULT now(),

    CONSTRAINT pk_medicao PRIMARY KEY (id),
    CONSTRAINT uq_medicao_data UNIQUE (data_referencia),
    CONSTRAINT ck_medicao_data_primeiro_dia CHECK (EXTRACT(DAY FROM data_referencia) = 1),
    CONSTRAINT ck_medicao_valor_positivo CHECK (valor_medicao > 0),
    CONSTRAINT ck_medicao_acumulado_positivo CHECK (valor_acumulado > 0),
    CONSTRAINT fk_medicao_operador FOREIGN KEY (operador_id)
        REFERENCES usuario (id) ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_medicao_data_desc
    ON medicao_obra (data_referencia DESC);

COMMENT ON TABLE medicao_obra IS
    'Série histórica de medições mensais de obras da OUCAE. '
    'Append-only (trigger bloqueia UPDATE/DELETE). '
    'valor_acumulado = soma de todas as medições anteriores + atual. '
    'Alimenta o Big Number "Custo Total Incorrido" do Dashboard.';
COMMENT ON COLUMN medicao_obra.data_referencia IS
    'Sempre o primeiro dia do mês de competência (constraint CHECK).';
COMMENT ON COLUMN medicao_obra.valor_acumulado IS
    'Calculado pela aplicação no momento da inserção. Nunca enviado pelo cliente.';

-- Trigger: impede UPDATE e DELETE em medicao_obra (mesmo padrão de movimentacao)
CREATE OR REPLACE FUNCTION fn_medicao_obra_immutable()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        RAISE EXCEPTION
            'Medições de obra são imutáveis. UPDATE em medicao_obra não é permitido.';
    ELSIF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION
            'Medições de obra são imutáveis. DELETE em medicao_obra não é permitido.';
    END IF;
    RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_medicao_no_update ON medicao_obra;
CREATE TRIGGER trg_medicao_no_update
    BEFORE UPDATE ON medicao_obra
    FOR EACH ROW EXECUTE FUNCTION fn_medicao_obra_immutable();

DROP TRIGGER IF EXISTS trg_medicao_no_delete ON medicao_obra;
CREATE TRIGGER trg_medicao_no_delete
    BEFORE DELETE ON medicao_obra
    FOR EACH ROW EXECUTE FUNCTION fn_medicao_obra_immutable();

-- ---------------------------------------------------------------------------
-- TABLE: parametro_sistema
--
-- Valores configuráveis: CEPACs em circulação, data início OUCAE, etc.
-- Atualizável por DIRETOR via endpoint administrativo.
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS parametro_sistema (
    chave        VARCHAR(100)  NOT NULL,
    valor        TEXT          NOT NULL,
    descricao    TEXT          NULL,
    updated_at   TIMESTAMPTZ   NOT NULL DEFAULT now(),
    operador_id  UUID          NULL,

    CONSTRAINT pk_parametro PRIMARY KEY (chave),
    CONSTRAINT fk_parametro_operador FOREIGN KEY (operador_id)
        REFERENCES usuario (id) ON DELETE SET NULL
);

COMMENT ON TABLE parametro_sistema IS
    'Parâmetros configuráveis do sistema. Atualizável por DIRETOR. '
    'Chaves predefinidas: cepacs_em_circulacao (193779), data_inicio_oucae (2004-01-01).';

-- ---------------------------------------------------------------------------
-- Trigger updated_at para proposta
-- ---------------------------------------------------------------------------

DROP TRIGGER IF EXISTS trg_proposta_updated_at ON proposta;
CREATE TRIGGER trg_proposta_updated_at
    BEFORE UPDATE ON proposta
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

COMMENT ON TRIGGER trg_proposta_updated_at ON proposta IS
    'Atualiza updated_at automaticamente (reusa fn_set_updated_at da Fase 1).';

COMMIT;
