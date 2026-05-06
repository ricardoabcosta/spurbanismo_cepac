-- Migration 029: Amplia proposta.interessado de VARCHAR(300) para TEXT
-- Motivo: planilha OUCFL contém interessados compostos com múltiplas
--         pessoas/empresas que excedem 300 caracteres (máximo observado: 662).
-- Data: 2026-05-06

BEGIN;

ALTER TABLE proposta ALTER COLUMN interessado TYPE TEXT;

COMMIT;
