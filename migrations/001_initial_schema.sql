-- =============================================================================
-- CEPAC — SP Urbanismo / Prodam
-- Migration 001: Initial Schema
-- PostgreSQL 15
-- =============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- ENUM TYPES
-- ---------------------------------------------------------------------------

CREATE TYPE uso_enum AS ENUM ('R', 'NR');

CREATE TYPE origem_enum AS ENUM ('ACA', 'NUVEM');

CREATE TYPE estado_titulo_enum AS ENUM (
    'DISPONIVEL',
    'EM_ANALISE',
    'CONSUMIDO',
    'QUARENTENA'
);

CREATE TYPE status_solicitacao_enum AS ENUM (
    'PENDENTE',
    'APROVADA',
    'REJEITADA'
);

-- ---------------------------------------------------------------------------
-- TABLE: setor
-- Armazena APENAS parâmetros estruturais imutáveis.
-- Saldo é sempre calculado a partir de movimentacao.
-- ---------------------------------------------------------------------------

CREATE TABLE setor (
    id               UUID         NOT NULL DEFAULT gen_random_uuid(),
    nome             VARCHAR(100) NOT NULL,
    estoque_total_m2 NUMERIC(15,2) NOT NULL,
    teto_nr_m2       NUMERIC(15,2) NOT NULL,
    reserva_r_m2     NUMERIC(15,2) NULL,
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT now(),

    CONSTRAINT pk_setor PRIMARY KEY (id),
    CONSTRAINT uq_setor_nome UNIQUE (nome),
    CONSTRAINT ck_setor_estoque_total_positivo CHECK (estoque_total_m2 > 0),
    CONSTRAINT ck_setor_teto_nr_positivo       CHECK (teto_nr_m2 > 0),
    CONSTRAINT ck_setor_reserva_r_positivo     CHECK (reserva_r_m2 IS NULL OR reserva_r_m2 > 0)
);

COMMENT ON TABLE setor IS
    'Setores da Operação Urbana Consorciada. Contém apenas parâmetros '
    'estruturais imutáveis. Saldo é sempre derivado de movimentacao.';
COMMENT ON COLUMN setor.reserva_r_m2 IS
    'Obrigatório apenas para Chucri Zaidan (216.442,47 m²). NULL nos demais setores.';

-- ---------------------------------------------------------------------------
-- TABLE: titulo_cepac
-- ---------------------------------------------------------------------------

CREATE TABLE titulo_cepac (
    id                UUID         NOT NULL DEFAULT gen_random_uuid(),
    codigo            VARCHAR(50)  NOT NULL,
    setor_id          UUID         NOT NULL,
    valor_m2          NUMERIC(15,2) NOT NULL,
    uso               uso_enum     NOT NULL,
    origem            origem_enum  NOT NULL,
    estado            estado_titulo_enum NOT NULL DEFAULT 'DISPONIVEL',
    data_desvinculacao TIMESTAMPTZ NULL,
    created_at        TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ  NOT NULL DEFAULT now(),

    CONSTRAINT pk_titulo_cepac PRIMARY KEY (id),
    CONSTRAINT uq_titulo_cepac_codigo UNIQUE (codigo),
    CONSTRAINT fk_titulo_cepac_setor
        FOREIGN KEY (setor_id) REFERENCES setor(id) ON DELETE RESTRICT,
    CONSTRAINT ck_titulo_cepac_valor_positivo CHECK (valor_m2 > 0),
    CONSTRAINT ck_titulo_cepac_desvinculacao
        CHECK (
            (estado = 'QUARENTENA' AND data_desvinculacao IS NOT NULL)
            OR (estado <> 'QUARENTENA')
        )
);

COMMENT ON TABLE titulo_cepac IS
    'Títulos CEPAC individuais. Estado transiciona via movimentacao.';
COMMENT ON COLUMN titulo_cepac.data_desvinculacao IS
    'Preenchido quando o título entra em QUARENTENA. Obrigatório neste estado.';

-- ---------------------------------------------------------------------------
-- TABLE: solicitacao_vinculacao
-- ---------------------------------------------------------------------------

CREATE TABLE solicitacao_vinculacao (
    id                   UUID         NOT NULL DEFAULT gen_random_uuid(),
    setor_id             UUID         NOT NULL,
    uso                  uso_enum     NOT NULL,
    origem               origem_enum  NOT NULL,
    area_m2              NUMERIC(15,2) NOT NULL,
    quantidade_cepacs    INTEGER      NOT NULL,
    numero_processo_sei  VARCHAR(50)  NOT NULL,
    status               status_solicitacao_enum NOT NULL DEFAULT 'PENDENTE',
    motivo_rejeicao      TEXT         NULL,
    created_at           TIMESTAMPTZ  NOT NULL DEFAULT now(),

    CONSTRAINT pk_solicitacao_vinculacao PRIMARY KEY (id),
    CONSTRAINT fk_solicitacao_vinculacao_setor
        FOREIGN KEY (setor_id) REFERENCES setor(id) ON DELETE RESTRICT,
    CONSTRAINT ck_solicitacao_area_positiva
        CHECK (area_m2 > 0),
    CONSTRAINT ck_solicitacao_qtd_cepacs_positiva
        CHECK (quantidade_cepacs > 0),
    CONSTRAINT ck_solicitacao_processo_sei_nao_vazio
        CHECK (length(numero_processo_sei) > 0),
    CONSTRAINT ck_solicitacao_rejeicao_consistente
        CHECK (
            (status = 'REJEITADA' AND motivo_rejeicao IS NOT NULL)
            OR (status <> 'REJEITADA')
        )
);

COMMENT ON TABLE solicitacao_vinculacao IS
    'Solicitações de vinculação de CEPACs a processos SEI.';

-- ---------------------------------------------------------------------------
-- TABLE: solicitacao_titulos (junction N:N)
-- ---------------------------------------------------------------------------

CREATE TABLE solicitacao_titulos (
    solicitacao_id UUID          NOT NULL,
    titulo_id      UUID          NOT NULL,
    area_m2        NUMERIC(15,2) NOT NULL,

    CONSTRAINT pk_solicitacao_titulos
        PRIMARY KEY (solicitacao_id, titulo_id),
    CONSTRAINT fk_solicitacao_titulos_solicitacao
        FOREIGN KEY (solicitacao_id)
        REFERENCES solicitacao_vinculacao(id) ON DELETE RESTRICT,
    CONSTRAINT fk_solicitacao_titulos_titulo
        FOREIGN KEY (titulo_id)
        REFERENCES titulo_cepac(id) ON DELETE RESTRICT,
    CONSTRAINT ck_solicitacao_titulos_area_positiva
        CHECK (area_m2 > 0)
);

COMMENT ON TABLE solicitacao_titulos IS
    'Associação N:N entre solicitações e títulos CEPAC. '
    'area_m2 indica a contribuição deste título para a solicitação.';

-- ---------------------------------------------------------------------------
-- TABLE: movimentacao (APPEND-ONLY — log de auditoria)
-- ---------------------------------------------------------------------------

CREATE TABLE movimentacao (
    id                  UUID              NOT NULL DEFAULT gen_random_uuid(),
    titulo_id           UUID              NOT NULL,
    setor_id            UUID              NOT NULL,
    uso                 uso_enum          NOT NULL,
    origem              origem_enum       NOT NULL,
    estado_anterior     estado_titulo_enum NULL,
    estado_novo         estado_titulo_enum NOT NULL,
    numero_processo_sei VARCHAR(50)       NOT NULL,
    motivo              TEXT              NULL,
    operador            VARCHAR(200)      NOT NULL,
    created_at          TIMESTAMPTZ       NOT NULL DEFAULT now(),

    CONSTRAINT pk_movimentacao PRIMARY KEY (id),
    CONSTRAINT fk_movimentacao_titulo
        FOREIGN KEY (titulo_id) REFERENCES titulo_cepac(id) ON DELETE RESTRICT,
    CONSTRAINT fk_movimentacao_setor
        FOREIGN KEY (setor_id) REFERENCES setor(id) ON DELETE RESTRICT,
    CONSTRAINT ck_movimentacao_processo_sei_nao_vazio
        CHECK (length(numero_processo_sei) > 0),
    CONSTRAINT ck_movimentacao_operador_nao_vazio
        CHECK (length(operador) > 0)
);

COMMENT ON TABLE movimentacao IS
    'Log de auditoria append-only de todas as transições de estado dos títulos. '
    'UPDATE e DELETE são bloqueados por trigger. '
    'estado_anterior NULL apenas no registro inicial (seed). '
    'Motivo SEED_INICIAL para registros de seed; EXPIRAÇÃO_TTL para expirações automáticas.';
COMMENT ON COLUMN movimentacao.created_at IS
    'Imutável. Base do audit trail. Nunca deve ser alterado.';

-- ---------------------------------------------------------------------------
-- TRIGGER: bloqueia UPDATE e DELETE em movimentacao
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fn_movimentacao_immutable()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'A tabela movimentacao é append-only. '
        'Operações UPDATE e DELETE não são permitidas. '
        'TG_OP=%, id=%',
        TG_OP,
        COALESCE(OLD.id::text, '?');
END;
$$;

CREATE TRIGGER trg_movimentacao_no_update
    BEFORE UPDATE ON movimentacao
    FOR EACH ROW
    EXECUTE FUNCTION fn_movimentacao_immutable();

CREATE TRIGGER trg_movimentacao_no_delete
    BEFORE DELETE ON movimentacao
    FOR EACH ROW
    EXECUTE FUNCTION fn_movimentacao_immutable();

-- ---------------------------------------------------------------------------
-- TRIGGER: atualiza updated_at em titulo_cepac automaticamente
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fn_set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_titulo_cepac_updated_at
    BEFORE UPDATE ON titulo_cepac
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_at();

-- ---------------------------------------------------------------------------
-- ÍNDICES
-- ---------------------------------------------------------------------------

-- Para queries de saldo histórico (CVM/TCM) — mais importante
CREATE INDEX idx_movimentacao_saldo
    ON movimentacao (setor_id, uso, origem, estado_novo, created_at);

-- Para queries de saldo por setor
CREATE INDEX idx_titulo_setor_estado
    ON titulo_cepac (setor_id, uso, origem, estado);

-- Para job de expiração TTL
CREATE INDEX idx_titulo_em_analise
    ON titulo_cepac (estado, updated_at)
    WHERE estado = 'EM_ANALISE';

-- Para quarentena
CREATE INDEX idx_titulo_quarentena
    ON titulo_cepac (estado, data_desvinculacao)
    WHERE estado = 'QUARENTENA';

-- Índices auxiliares para FK lookups
CREATE INDEX idx_titulo_cepac_setor_id
    ON titulo_cepac (setor_id);

CREATE INDEX idx_solicitacao_vinculacao_setor_id
    ON solicitacao_vinculacao (setor_id);

CREATE INDEX idx_solicitacao_titulos_titulo_id
    ON solicitacao_titulos (titulo_id);

CREATE INDEX idx_movimentacao_titulo_id
    ON movimentacao (titulo_id);

COMMIT;
