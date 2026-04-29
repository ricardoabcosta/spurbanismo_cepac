-- =============================================================================
-- CEPAC — Migration 014: Remove certidões com formato de número inválido
--
-- Contexto:
--   Em 2026-04-20 21:11:36 foram inseridos 16 registros via script ad hoc
--   (não versionado) com numeração no formato legado SIMPROC: AE-XXXX-NNN.
--   O padrão correto é AE-NNN/AAAA. Esses registros têm data_emissao NULL,
--   não constam em nenhuma planilha oficial (XLSX/ODS) e são dados inválidos.
-- =============================================================================

BEGIN;

DELETE FROM certidao
WHERE numero_certidao ~ '^[A-Z]+-[0-9]+-[0-9]+$';

-- Esperado: 16 linhas deletadas (AE-0001-380, AE-0001-402, AE-0149-411,
-- AE-0169-391, AE-0187-383, AE-0199-379/381/382/412, AE-0200-392/393/394,
-- AE-0206-409/410, AE-0214-375, AE-0216-408)

COMMIT;
