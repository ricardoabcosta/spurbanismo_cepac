BEGIN;

ALTER TABLE operacao_urbana
    ADD COLUMN reserva_tecnica_m2       NUMERIC(15,2) NOT NULL DEFAULT 0,
    ADD COLUMN cepacs_leiloados         INTEGER       NOT NULL DEFAULT 0,
    ADD COLUMN cepacs_colocacao_privada INTEGER       NOT NULL DEFAULT 0,
    ADD COLUMN cepacs_totais            INTEGER       NOT NULL DEFAULT 0;

-- Copia valores atuais da OUCAE a partir do singleton configuracao_operacao
UPDATE operacao_urbana
SET
    reserva_tecnica_m2       = (SELECT reserva_tecnica_m2       FROM configuracao_operacao WHERE id = 1),
    cepacs_leiloados         = (SELECT cepacs_leiloados         FROM configuracao_operacao WHERE id = 1),
    cepacs_colocacao_privada = (SELECT cepacs_colocacao_privada FROM configuracao_operacao WHERE id = 1),
    cepacs_totais            = (SELECT cepacs_totais            FROM configuracao_operacao WHERE id = 1)
WHERE sigla = 'AE';

COMMIT;
