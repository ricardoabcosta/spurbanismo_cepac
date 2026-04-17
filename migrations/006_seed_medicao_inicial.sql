-- =============================================================================
-- Migration 006 — Seed da medição inicial de obra (T17)
-- =============================================================================
-- Insere o Custo Total Incorrido acumulado conforme planilha
-- OUCAE_ESTOQUE_abr_rv01.xlsx (posição 13/04/2026).
--
-- Como medicao_obra.operador_id é NOT NULL, primeiro garante a existência
-- de um usuário de sistema (ativo=false — nunca faz login) e usa seu ID.
-- =============================================================================

DO $$
DECLARE
    v_operador_id UUID;
BEGIN
    -- Garantir existência do usuário de sistema (idempotente)
    INSERT INTO usuario (upn, nome, papel, ativo)
    VALUES (
        'sistema@cepac.spurbanismo.sp.gov.br',
        'Sistema CEPAC — seed',
        'TECNICO',
        false
    )
    ON CONFLICT (upn) DO NOTHING;

    SELECT id INTO v_operador_id
    FROM usuario
    WHERE upn = 'sistema@cepac.spurbanismo.sp.gov.br';

    -- Inserir medição inicial (idempotente)
    INSERT INTO medicao_obra (
        data_referencia,
        valor_medicao,
        valor_acumulado,
        descricao,
        numero_processo_sei,
        operador_id
    )
    VALUES (
        '2026-04-01',
        3987822642.21,
        3987822642.21,
        'Carga inicial — Custo Total Incorrido acumulado conforme planilha OUCAE_ESTOQUE_abr_rv01.xlsx (posição 13/04/2026)',
        '7810.2026/0000001-0',
        v_operador_id
    )
    ON CONFLICT (data_referencia) DO NOTHING;
END $$;
