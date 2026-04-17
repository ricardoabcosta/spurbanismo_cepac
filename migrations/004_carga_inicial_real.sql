-- =============================================================================
-- CEPAC — SP Urbanismo / Prodam
-- Migration 004: Carga Inicial Real — Planilha OUCAE_ESTOQUE_abr_rv01.xlsx
-- PostgreSQL 15
-- Posição: 13/04/2026 | Gerado: 2026-04-16T14:59:05
--
-- ATENÇÃO: Execute APÓS 004a_revogar_seed_sintetico.sql.
-- ATENÇÃO: Revisar e aprovar antes de executar em produção.
--
-- Registros importados da ABA 2_CONTROLE_ESTOQUE:
--   - Propostas únicas inseridas (ON CONFLICT DO NOTHING)
--   - Certidões únicas inseridas (ON CONFLICT DO NOTHING)
--   - Títulos reais e movimentações de importação
-- Certidões da ABA 3_controle_certidoes acrescentadas ao final.
-- =============================================================================

BEGIN;

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0200',
    '7810.2025/0001500-9',
    'SEI'::tipo_processo_enum,
    '2025-11-18',
    'ANALISE'::status_pa_enum,
    'AK-25 EMPREENDIMENTOS E PARTICIPAÇOES LTDA',
    '28857292/0001-10;',
    'RUA CHAFIC MALUF, 299, 321, 327, 333, 381; RUA FRANCISCO ROMERO SOBRINHO, 140, 158',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'DESVINCULACAO'::requerimento_enum,
    4977.32
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0200'),
    'DV-001/2026',
    'DESVINCULAÇÃO'::tipo_certidao_enum,
    '2026-02-03',
    '7810.2025/0001500-9',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0169',
    '7810.2025/0001463-0',
    'SEI'::tipo_processo_enum,
    '2025-11-07',
    'ANALISE'::status_pa_enum,
    'HELIOMAR LTDA',
    '60852605/0001-32;',
    'AVENIDA DAS NAÇÕES UNIDAS, 1641',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'DESVINCULACAO'::requerimento_enum,
    16138.52
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0169'),
    'DV-002/2026',
    'DESVINCULAÇÃO'::tipo_certidao_enum,
    '2026-03-04',
    '7810.2025/0001463-0',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0184',
    '7810.2025/0001515-7',
    'SEI'::tipo_processo_enum,
    '2025-11-19',
    'ANALISE'::status_pa_enum,
    'MAIRIPORÃ INCORPORADORA LTDA.;',
    '17922338/0001-01;',
    'RUA ENGENHEIRO MESQUITA SAMPAIO, 714;',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'DESVINCULACAO'::requerimento_enum,
    17793.50
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0002',
    '2005-0060565-0',
    'SIMPROC'::tipo_processo_enum,
    '2005-03-11',
    'DEFERIDO'::status_pa_enum,
    'EVEN CONSTRUTORA E INCORPORADORA LTDA',
    '43470988/0001-65;',
    'AVENIDA NOVA INDEPENDENCIA, 1004',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    'VINCULACAO'::requerimento_enum,
    3237.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0002'),
    'AE-001/2005',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2005-08-10',
    '2005-0060565-0',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-001-2005-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    8229.43,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-001-2005-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2005-0060565-0',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-001-2005-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0003',
    '2003-0288319-0',
    'SIMPROC'::tipo_processo_enum,
    '2003-11-05',
    'DEFERIDO'::status_pa_enum,
    'QUALITY INVESTMENTOS IMOBILIARIOS LTDA',
    '05973743/0001-61;',
    'RUA PRINCESA ISABEL, 347',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    2000.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0003'),
    'AE-003/2005',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2005-10-07',
    '2003-0288319-0',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-003-2005-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    3681.35,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-003-2005-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2003-0288319-0',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-003-2005-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0004',
    '2005-0017200-1',
    'SIMPROC'::tipo_processo_enum,
    '2005-01-27',
    'DEFERIDO'::status_pa_enum,
    'HELBOR EMPREENDIMENTOS IMOBILIARIOS LTDA',
    '49263189/0001-02;',
    'RUA ZACARIAS DE GOIAS, 881',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    2116.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0004'),
    'AE-002/2005',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2005-10-05',
    '2005-0017200-1',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-002-2005-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    6348.00,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-002-2005-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2005-0017200-1',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-002-2005-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0005',
    '2005-0069305-2',
    'SIMPROC'::tipo_processo_enum,
    '2005-02-22',
    'DEFERIDO'::status_pa_enum,
    'JARDIM MORUMBI EMPREENDIMENTO IMOBILIARIO S/A',
    '06124921/0001-42;',
    'RUA JAIME COSTA, 425',
    (SELECT id FROM setor WHERE nome = 'Marginal Pinheiros'),
    'VINCULACAO'::requerimento_enum,
    6398.40
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0005'),
    'AE-004/2005',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2005-12-29',
    '2005-0069305-2',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-004-2005-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Marginal Pinheiros'),
    7701.74,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-004-2005-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2005-0069305-2',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-004-2005-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0006',
    '2005-0004974-9',
    'SIMPROC'::tipo_processo_enum,
    '2005-01-07',
    'DEFERIDO'::status_pa_enum,
    'SEGA SPE - EMPREENDIMENTO IMOBILIARIO LTDA',
    '07599698/0001-52;',
    'RUA LUIS CORREIA DE MELO, 250',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    2713.80
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0006'),
    'AE-007/2007',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2007-05-09',
    '2005-0004974-9',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-007-2007-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    8129.05,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-007-2007-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2005-0004974-9',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-007-2007-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0007',
    '2005-0326086-6',
    'SIMPROC'::tipo_processo_enum,
    '2005-12-26',
    'DEFERIDO'::status_pa_enum,
    'PORTLAND INCORPORADORA LTDA',
    '05405356/0001-29;',
    'RUA MANUEL CHEREM, LOTES 12 AO 20',
    (SELECT id FROM setor WHERE nome = 'Jabaquara'),
    'VINCULACAO'::requerimento_enum,
    4500.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0007'),
    'AE-012/2007',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2007-06-27',
    '2005-0326086-6',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-012-2007-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Jabaquara'),
    7709.85,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-012-2007-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2005-0326086-6',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-012-2007-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0008',
    '2005-0226943-6',
    'SIMPROC'::tipo_processo_enum,
    '2005-09-16',
    'DEFERIDO'::status_pa_enum,
    'GRAPIA PARTICIPAÇÕES LTDA',
    '06078362/0001-81;',
    'RUA GABRIELE D'' ANNUNZIO, 824',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    2260.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0008'),
    'AE-002/2006',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2006-05-23',
    '2005-0226943-6',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-002-2006-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    6780.00,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-002-2006-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2005-0226943-6',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-002-2006-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0009',
    '2005-0022209-2',
    'SIMPROC'::tipo_processo_enum,
    '2006-07-20',
    'DEFERIDO'::status_pa_enum,
    'CAMPO BELISSIMO PARTICIPACOES S/A',
    '07727022/0001-05;',
    'Rua Volta Redonda, 270; Rua Conde de Porto Alegre; Rua Joao Alvares Soares; Avenida Jornalista Roberto Marinho',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    8561.45
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0009'),
    'AE-010/2007',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2007-06-06',
    '2005-0022209-2',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-010-2007-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    25450.62,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-010-2007-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2005-0022209-2',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-010-2007-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0009'),
    'AE-003/2006',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2006-07-24',
    '2005-0022209-2',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0010',
    '2005-0198476-0',
    'SIMPROC'::tipo_processo_enum,
    '2005-08-17',
    'DEFERIDO'::status_pa_enum,
    'HELBOR EMPREENDIMENTOS IMOBILIARIOS LTDA',
    '49263189/0001-02;',
    'RUA BACAETAVA, 66',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    2000.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0010'),
    'AE-004/2006',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2006-08-24',
    '2005-0198476-0',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-004-2006-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    5784.40,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-004-2006-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2005-0198476-0',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-004-2006-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0011',
    '2004-0155989-7',
    'SIMPROC'::tipo_processo_enum,
    '2004-06-23',
    'DEFERIDO'::status_pa_enum,
    'GAFISA S/A',
    '01545826/0001-07;',
    'RUA FERNANDES MOREIRA, 2000',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    5852.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0011'),
    'AE-003/2007',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2007-03-12',
    '2004-0155989-7',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-003-2007-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    11636.70,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-003-2007-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2004-0155989-7',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-003-2007-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0012',
    '2006-0127566-3',
    'SIMPROC'::tipo_processo_enum,
    '2006-05-11',
    'DEFERIDO'::status_pa_enum,
    'AK9 EMPREENDIMENTOS E PARTICIPACOES SPE LTDA',
    '07851948/0001-08;',
    'RUA ALCEU MAYNARD ARAUJO; RUA LUIS SERAPHICO JUNIOR',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    5105.78
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0012'),
    'AE-011/2007',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2007-06-21',
    '2006-0127566-3',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-011-2007-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    15317.34,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-011-2007-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2006-0127566-3',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-011-2007-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0013',
    '2005-0022487-7',
    'SIMPROC'::tipo_processo_enum,
    '2005-02-02',
    'DEFERIDO'::status_pa_enum,
    'VOLTA REDONDA DESENVOLVIMETNO IMOBILIARIO LTDA',
    '07241448/0001-46;',
    'RUA VOLTA REDONDA, 376, 388, 394',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    4915.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0013'),
    'AE-005/2006',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2006-09-15',
    '2005-0022487-7',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-005-2006-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    14745.00,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-005-2006-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2005-0022487-7',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-005-2006-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0014',
    '2005-0327484-0',
    'SIMPROC'::tipo_processo_enum,
    '2005-12-27',
    'DEFERIDO'::status_pa_enum,
    'CYRELA ACONCAGUA EMPREENDIMENTOS IMOBILIARIOS LTDA',
    '06243143/0001-00;',
    'RUA GABRIELLE D''ANNUNZIO X BARAO DO TRINUFO',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    3449.35
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0014'),
    'AE-005/2007',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2007-03-21',
    '2005-0327484-0',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-005-2007-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    7262.61,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-005-2007-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2005-0327484-0',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-005-2007-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0015',
    '2005-0293001-9',
    'SIMPROC'::tipo_processo_enum,
    '2005-11-23',
    'DEFERIDO'::status_pa_enum,
    'F. REIS ADMINISTRACAO DE IMOVEIS LTDA',
    '00076468/0001-60;',
    'RUA GEORGE OHM X RUA JAMES WATT X RUA SAMUEL MORSE',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    'VINCULACAO'::requerimento_enum,
    1569.69
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0015'),
    'AE-007/2006',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2006-12-07',
    '2005-0293001-9',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-007-2006-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    3130.75,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-007-2006-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2005-0293001-9',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-007-2006-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0016',
    '2006-0173155-3',
    'SIMPROC'::tipo_processo_enum,
    '2006-06-29',
    'DEFERIDO'::status_pa_enum,
    'HELBOR EMPREENDIMENTOS IMOBILIARIOS LTDA',
    '49263189/0001-02;',
    'RUA DA PAZ, 2150',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    6952.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0016'),
    'AE-017/2007',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2007-08-01',
    '2006-0173155-3',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-017-2007-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    20764.23,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-017-2007-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2006-0173155-3',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-017-2007-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0017',
    '2004-0301504-5',
    'SIMPROC'::tipo_processo_enum,
    '2004-12-28',
    'DEFERIDO'::status_pa_enum,
    'PAULA EDUARDO INCORPORADORA E CONSTRUTORA LTDA',
    '50473552/0001-95;',
    'RUA SURUBIM, 577',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    'VINCULACAO'::requerimento_enum,
    3146.98
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0017'),
    'AE-002/2007',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2007-01-16',
    '2004-0301504-5',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-002-2007-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    9429.61,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-002-2007-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2004-0301504-5',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-002-2007-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0018',
    '2007-0173371-0',
    'SIMPROC'::tipo_processo_enum,
    '2007-05-30',
    'DEFERIDO'::status_pa_enum,
    'ROCHAVERÁ DESENVOLVIMENTO IMOBILIÁRIO LTDA',
    '03609818/0001-02;',
    'AVENIDA DAS NAÇÕES UNIDAS, 14171',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    37730.16
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0018'),
    'AE-020/2008',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2008-08-06',
    '2007-0173371-0',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-020-2008-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    74290.69,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-020-2008-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2007-0173371-0',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-020-2008-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0018'),
    'AE-006/2007',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2007-04-24',
    '2006-0033291-4',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-006-2007-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    3773.02,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-006-2007-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2006-0033291-4',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-006-2007-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0019',
    '2006-0176918-6',
    'SIMPROC'::tipo_processo_enum,
    '2006-07-03',
    'DEFERIDO'::status_pa_enum,
    'VILA SOLO EMPREENDIMENTOS S/A',
    '07465335/0001-24;',
    'RUA PROFESSOR JOSE LEITE DE OITICICA, 133;',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    3338.30
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0019'),
    'AE-021/2008',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2008-08-27',
    '2006-0176918-6',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-021-2008-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    9647.35,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-021-2008-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2006-0176918-6',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-021-2008-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0019'),
    'AE-001/2007',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2007-01-16',
    '2006-0176918-6',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-001-2007-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    9647.35,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-001-2007-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2006-0176918-6',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-001-2007-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0020',
    '2006-0072422-7',
    'SIMPROC'::tipo_processo_enum,
    '2006-03-15',
    'DEFERIDO'::status_pa_enum,
    'DINCO EMPREENDIMENTOS IMOBILIÁRIOS LTDA.',
    '08085999/0001-20;',
    'RUA BACAETAVA, 264; RUA VIEIRA DA SILVA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    2841.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0020'),
    'AE-009/2007',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2007-05-21',
    '2006-0072422-7',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-009-2007-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    5716.94,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-009-2007-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2006-0072422-7',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-009-2007-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0021',
    '2006-0205168-8',
    'SIMPROC'::tipo_processo_enum,
    '2006-07-31',
    'DEFERIDO'::status_pa_enum,
    'QUEIROZ GALVÃO CYRELA OKLAHOMA EMPREENDIMENTO IMOBILIÁRIO SPE LTDA',
    '07035584/0001-80;',
    'RUA EDSON, 80 E 26; RUA GABRIELE D''ANNUNZIO, 73,83,95 E 105',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    3545.90
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0021'),
    'AE-001/2008',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2008-01-11',
    '2006-0205168-8',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-001-2008-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    7791.74,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-001-2008-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2006-0205168-8',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-001-2008-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0022',
    '2006-0224232-7',
    'SIMPROC'::tipo_processo_enum,
    '2006-08-18',
    'DEFERIDO'::status_pa_enum,
    'BRASCAN IMOBILIÁRIA INCORPORAÇÕES S/A',
    '29964749/0001-30;',
    'RUA XAVIER GOUVEIA, 241, 259 265 E 273',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    3655.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0022'),
    'AE-004/2007',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2007-03-21',
    '2006-0224232-7',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-004-2007-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    10963.90,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-004-2007-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2006-0224232-7',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-004-2007-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0023',
    '2006-0059296-7',
    'SIMPROC'::tipo_processo_enum,
    '2006-03-02',
    'DEFERIDO'::status_pa_enum,
    'PARQUEVEN EMPREENDIMENTOS LTDA',
    '07589891/0001-02;',
    'RUA LUIS CORREA DE MELO; RUA LUIS SERAPHICO JUNIOR',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    20623.90
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0023'),
    'AE-016/2007',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2007-07-24',
    '2006-0059296-7',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-016-2007-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    41442.79,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-016-2007-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2006-0059296-7',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-016-2007-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0024',
    '2006-0317644-1',
    'SIMPROC'::tipo_processo_enum,
    '2006-11-28',
    'DEFERIDO'::status_pa_enum,
    'AK 10 EMPREENDIMENTOS E PARTICIPAÇÕES SPE LTDA',
    '07851946/0001-00;',
    'RUA ANTONIO DE MACEDO SOARES, 970',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    2284.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0024'),
    'AE-012/2008',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2004-04-04',
    '2006-0317644-1',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-012-2008-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    6730.72,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-012-2008-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2006-0317644-1',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-012-2008-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0024'),
    'AE-008/2007',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2007-05-16',
    '2006-0317644-1',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0025',
    '2006-0112727-3',
    'SIMPROC'::tipo_processo_enum,
    '2006-04-26',
    'DEFERIDO'::status_pa_enum,
    'MULTIPLAN EMPREENDIMENTOS IMOBILIÁRIOS S/A',
    '07816890/0001-53;',
    'RUA OSCAR RODRIGUES CAJADO FILHO',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    2622.84
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0025'),
    'AE-032/2008',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2008-06-11',
    '2006-0112727-3',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-032-2008-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    7632.46,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-032-2008-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2006-0112727-3',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-032-2008-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0026',
    '2006-0331628-6',
    'SIMPROC'::tipo_processo_enum,
    '2006-07-03',
    'DEFERIDO'::status_pa_enum,
    'SAIPH INCORPORADORA LTDA.',
    '08350881/0001-82;',
    'RUA ESTEVÃO BAIÃO, 520; RUA TAMOIOS; AVENIDA WASHINGTON LUIS; RUA TAPES',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    9947.50
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0026'),
    'AE-014/2007',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2007-11-07',
    '2006-0331628-6',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0026'),
    'AE-033/2008',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2008-11-12',
    '2006-0331628-6',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-033-2008-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    16559.40,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-033-2008-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2006-0331628-6',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-033-2008-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0027',
    '2006-0120179-1',
    'SIMPROC'::tipo_processo_enum,
    '2006-05-04',
    'DEFERIDO'::status_pa_enum,
    'HELBOR EMPREENDIMENTOS IMOBILIÁRIOS LTDA.',
    '49263189/0001-02;',
    'RUA BARÃO DO TRIUNFO, 1048, 1052, 1058; RUA GABRIELLE D''ANNUNZIO, 341, 337, 345, 353, 377, 359, 367; AVENIDA VEREADOR JOSE DINIZ, 3305, 3009 E QD 123',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    3440.67
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0027'),
    'AE-015/2007',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2007-07-23',
    '2006-0120179-1',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0027'),
    'AE-030/2008',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2008-10-16',
    '2006-0120179-1',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-030-2008-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    10184.21,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-030-2008-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2006-0120179-1',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-030-2008-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0028',
    '2007-0113485-9',
    'SIMPROC'::tipo_processo_enum,
    '2007-04-03',
    'DEFERIDO'::status_pa_enum,
    'GAFISA S/A',
    '01545826/0001-07;',
    'RUA ZACARIAS DE GÓES S/N',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    4277.57
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0028'),
    'AE-013/2007',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2007-07-04',
    '2007-0113485-9',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0028'),
    'AE-006/2008',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2008-03-05',
    '2007-0113485-9',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-006-2008-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    12832.69,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-006-2008-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2007-0113485-9',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-006-2008-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0029',
    '2006-0160229-0',
    'SIMPROC'::tipo_processo_enum,
    '2006-06-14',
    'DEFERIDO'::status_pa_enum,
    'BROOKLIN COMPANY LTDA.; DALGLISH DESENVOLVIMENTO IMOBILIÁRIO LTDA.',
    '04482739/0001-38; 04463020/0001-50',
    'RUA CONSTANTINO DE SOUZA; RUA GABRIELLE D''ANNUNZIO; RUA BARÃO JACEGUAI E EDSON',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    9375.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0029'),
    'AE-018/2007',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2007-08-01',
    '2006-0160229-0',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0029'),
    'AE-023/2008',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2008-09-05',
    '2006-0160229-0',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-023-2008-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    28125.00,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-023-2008-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2006-0160229-0',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-023-2008-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0030',
    '2007-0090155-4',
    'SIMPROC'::tipo_processo_enum,
    '2007-03-15',
    'DEFERIDO'::status_pa_enum,
    'GAFISA S/A',
    '01545826/0001-07;',
    'RUA EDSON S/N',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    6955.28
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0030'),
    'AE-019/2007',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2007-08-24',
    '2007-0090155-4',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0030'),
    'AE-008/2008',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2008-03-19',
    '2007-0090155-4',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-008-2008-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    20845.67,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-008-2008-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2007-0090155-4',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-008-2008-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0031',
    '2007-0185759-1',
    'SIMPROC'::tipo_processo_enum,
    '2007-06-12',
    'DEFERIDO'::status_pa_enum,
    'CATCH EMPREENDIMENTOS E PARTICIPAÇÕES S/A',
    '08369575/0001-98;',
    'AVENIDA NAÇÕES UNIDAS; AVENIDA JORNALISTA ROBERTO MARINHO',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    'ALTERACAO'::requerimento_enum,
    13719.54
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0031'),
    'AE-004/2011',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2011-02-17',
    '2007-0185759-1',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-004-2011-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    41158.62,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-004-2011-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2007-0185759-1',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-004-2011-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0032',
    '2007-0139274-2',
    'SIMPROC'::tipo_processo_enum,
    '2007-04-26',
    'DEFERIDO'::status_pa_enum,
    'COLUMBA EVEN EMPREENDIMENTOS IMOBILIÁRIOS LTDA.',
    '08504358/0001-63;',
    'RUA GABRIELE D''ANNUNZIO, 1066',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    2911.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0032'),
    'AE-020/2007',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2007-09-14',
    '2007-0139274-2',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0032'),
    'AE-010/2008',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2008-03-25',
    '2007-0139274-2',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-010-2008-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    8732.72,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-010-2008-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2007-0139274-2',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-010-2008-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0033',
    '2005-0020884-7',
    'SIMPROC'::tipo_processo_enum,
    '2005-02-01',
    'DEFERIDO'::status_pa_enum,
    'CAMARGO CORREA DESENVOLVIMENTO IMOBILIARIO S/A',
    '67203208/0001-89;',
    'RUA NICOLAU BARRETO, 614, 644; RUA MIGUEL SUTIL, 229, 233, 237; RUA REBELO JUNIOR',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    'VINCULACAO'::requerimento_enum,
    2965.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0033'),
    'AE-022/2007',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2007-09-24',
    '2005-0020884-7',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-022-2007-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    8604.80,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-022-2007-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2005-0020884-7',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-022-2007-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0034',
    '2007-0113709-2',
    'SIMPROC'::tipo_processo_enum,
    '2007-04-03',
    'DEFERIDO'::status_pa_enum,
    'SPE SAO PAULO INCORPORACAO 2 LTDA',
    '08713817/0001-19;',
    'RUA DIOGO QUADROS, 340',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    1849.25
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0034'),
    'AE-023/2007',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2007-10-31',
    '2007-0113709-2',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-023-2007-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    3698.32,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-023-2007-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2007-0113709-2',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-023-2007-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0035',
    '2007-0150912-7',
    'SIMPROC'::tipo_processo_enum,
    '2007-05-09',
    'DEFERIDO'::status_pa_enum,
    'COMPANY S/A',
    '58877812/0001-08;',
    'RUA ARIZONA, 1051',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    4490.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0035'),
    'AE-024/2007',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2007-11-09',
    '2007-0150912-7',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0035'),
    'AE-031/2008',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2008-10-16',
    '2007-0150912-7',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-031-2008-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    9829.65,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-031-2008-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2007-0150912-7',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-031-2008-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0036',
    '2007-0215879-4',
    'SIMPROC'::tipo_processo_enum,
    '2007-07-05',
    'DEFERIDO'::status_pa_enum,
    'CENTAURUS EVEN EMPREENDIMENTOS IMOBILIARIOS LTDA.',
    '08504745/0001-08;',
    'RUA CONDE DE PORTO ALEGRE, 944',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    4866.99
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0036'),
    'AE-025/2007',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2007-11-14',
    '2007-0215879-4',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0036'),
    'AE-015/2008',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2008-05-09',
    '2007-0215879-4',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-015-2008-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    14600.59,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-015-2008-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2007-0215879-4',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-015-2008-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0037',
    '2007-0186392-3',
    'SIMPROC'::tipo_processo_enum,
    '2007-06-12',
    'DEFERIDO'::status_pa_enum,
    'F.REIS ADMINISTRACAO DE IMOVEIS LTDA.',
    '00076468/0001-60;',
    'RUA SURUBIM, 504, 508; RUA OSWALDO CASEMIRO MULLER, 245, 251, 237, 243',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    'VINCULACAO'::requerimento_enum,
    1200.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0037'),
    'AE-026/2007',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2007-12-10',
    '2007-0186392-3',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-026-2007-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    3600.00,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-026-2007-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2007-0186392-3',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-026-2007-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0038',
    '2007-0194763-9',
    'SIMPROC'::tipo_processo_enum,
    '2007-12-12',
    'DEFERIDO'::status_pa_enum,
    'RUBI SPE S/A; COMPANY S/A',
    '08530862/0001-38; 58877812/0001-08;',
    'RUA GEORGE OHM; RUA ARIZONA; RUA ARANDU',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    3604.98
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0038'),
    'AE-027/2007',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2007-12-12',
    '2007-0194763-9',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-027-2007-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    7766.43,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-027-2007-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2007-0194763-9',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-027-2007-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0039',
    '2007-0260557-0',
    'SIMPROC'::tipo_processo_enum,
    '2007-08-17',
    'DEFERIDO'::status_pa_enum,
    'CONSTRUTORA BRACCO LTDA.',
    '43282490/0001-79;',
    'RUA CONCEICAO MARCONDES SILVA, 166, 170; RUA PAIAGUAS, 163',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    2280.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0039'),
    'AE-002/2008',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2008-01-11',
    '2007-0260557-0',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-002-2008-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    6839.64,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-002-2008-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2007-0260557-0',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-002-2008-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0040',
    '2007-0243390-6',
    'SIMPROC'::tipo_processo_enum,
    '2007-08-02',
    'DEFERIDO'::status_pa_enum,
    'HERCULES EVEN EMPREENDIMENTOS EMOBILIARIOS LTDA.',
    '08747240/0001-00;',
    'RUA CONDE DE PORTO ALEGRE, 869',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    3102.40
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0040'),
    'AE-003/2008',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2008-01-31',
    '2007-0243390-6',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0040'),
    'AE-016/2008',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2008-05-14',
    '2007-0243390-6',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-016-2008-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    9302.77,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-016-2008-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2007-0243390-6',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-016-2008-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0041',
    '2010-0293984-0',
    'SIMPROC'::tipo_processo_enum,
    '2010-10-27',
    'DEFERIDO'::status_pa_enum,
    'AKLW2 EMPREENDIMENTOS E PARTICIPACOES SPE LTDA.',
    '08999947/0001-60;',
    'RUA DOUTOR RUBENS GOMES BUENO, 395',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    7206.96
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0041'),
    'AE-024/2010',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2010-11-17',
    '2010-0293984-0',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-024-2010-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    17311.84,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-024-2010-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2010-0293984-0',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-024-2010-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0042',
    '2015-0282090-7',
    'SIMPROC'::tipo_processo_enum,
    '2015-10-21',
    'DEFERIDO'::status_pa_enum,
    'JCR CONSTRUÇÃO CIVIL LTDA E HAVER CONSULTORIA E EMPREENDIMENTOS LTDA',
    '46847075/0001-03;',
    ' RUA FRANCISCO DIAS VELHO; AVENIDA JORNALISTA ROBERTO MARINHO;  AVENIDA JURUBATUBA',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    'DESVINCULACAO'::requerimento_enum,
    3331.97
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0042'),
    'DV-001/2017',
    'DESVINCULAÇÃO'::tipo_certidao_enum,
    '2017-05-16',
    '2015-0282090-7',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'DV-001-2017-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    649.16,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'DISPONIVEL'::estado_titulo_enum,
    '2017-05-16'
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'DV-001-2017-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'DISPONIVEL'::estado_titulo_enum,
    '2015-0282090-7',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'DV-001-2017-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0042'),
    'AE-003/2017',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2016-07-01',
    '2015-0282090-7',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-003-2017-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    9995.91,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-003-2017-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2015-0282090-7',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-003-2017-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-003-2017-NR-NUVEM',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    595.00,
    'NR'::uso_enum,
    'NUVEM'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-003-2017-NR-NUVEM');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2015-0282090-7',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-003-2017-NR-NUVEM'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0043',
    '2007-0238082-9',
    'SIMPROC'::tipo_processo_enum,
    '2007-07-27',
    'DEFERIDO'::status_pa_enum,
    'FLEXPAR EMPREENDIMENTOS E PARTICIPAÇÕES LTDA',
    '08797019/0001-12;',
    'AVENIDA JURUBATUBA',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    'VINCULACAO'::requerimento_enum,
    1120.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0043'),
    'AE-007/2008',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2008-03-06',
    '2007-0238082-9',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-007-2008-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    1169.11,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-007-2008-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2007-0238082-9',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-007-2008-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0044',
    '2007-0265224-1',
    'SIMPROC'::tipo_processo_enum,
    '2007-08-22',
    'DEFERIDO'::status_pa_enum,
    'CAPRICORNUS EVEN EMPREENDIMENTOS IMOBILIARIOS LTDA',
    '08689445/0001-32;',
    'RUA CONDE DE PORTOALEGRE, 1033',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    6281.70
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0044'),
    'AE-018/2008',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2008-06-12',
    '2007-0265224-1',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-018-2008-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    18832.45,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-018-2008-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2007-0265224-1',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-018-2008-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0044'),
    'AE-005/2008',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2008-02-27',
    '2007-0265224-1',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0045',
    '2007-0305862-9',
    'SIMPROC'::tipo_processo_enum,
    '2007-09-27',
    'DEFERIDO'::status_pa_enum,
    'LIMOGES INCORPORADORA LTDA',
    '08204931/0001-13;',
    'AVENIDA JÔNIA, 515; RUA TEBAS, 228, 296, 304, 310 e 316',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    4080.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0045'),
    'AE-014/2008',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2008-04-24',
    '2007-0305862-9',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0045'),
    'AE-005/2010',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2008-04-24',
    '2009-0311697-5',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-005-2010-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    8158.06,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-005-2010-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2009-0311697-5',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-005-2010-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0046',
    '2005-0022320-0',
    'SIMPROC'::tipo_processo_enum,
    '2005-02-02',
    'DEFERIDO'::status_pa_enum,
    'IGUATEMI EMPRESA DE SHOPPING CENTERS S/A',
    '51218147/0001-93;',
    'AVENIDA DAS NAÇÕES UNIDAS, 13.947; AVENIDA DOUTOR CHUCRI ZAIDAN, 902, 920, 940',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    33360.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0046'),
    'AE-013/2008',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2008-04-17',
    '2005-0022320-0',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-013-2008-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    4591.30,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-013-2008-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2005-0022320-0',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-013-2008-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0047',
    '2006-0267610-6',
    'SIMPROC'::tipo_processo_enum,
    '2006-10-04',
    'DEFERIDO'::status_pa_enum,
    'JHSF INCORPORADORA LTDA',
    '05345215/0001-68;',
    'AVENIDA MAGALHÃES DE CASTRO, 12.000; RUA ARMANDO PETRELLA',
    (SELECT id FROM setor WHERE nome = 'Marginal Pinheiros'),
    'VINCULACAO'::requerimento_enum,
    22555.01
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0047'),
    'AE-011/2008',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2008-03-26',
    '2006-0267610-6',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-011-2008-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Marginal Pinheiros'),
    67665.03,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-011-2008-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2006-0267610-6',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-011-2008-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0048',
    '2008-0180360-4',
    'SIMPROC'::tipo_processo_enum,
    '2008-06-16',
    'DEFERIDO'::status_pa_enum,
    'CYGNUS EVEN EMPREENDIMENTOS IMOBILIÁRIOS LTDA',
    '08504577/0001-42;',
    'AVENIDA LUIS CARLOS BERRINI, 1774, 1748; RUA LEE DE FOREST; RUA JOHN BAIRD',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    'VINCULACAO'::requerimento_enum,
    3269.40
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0048'),
    'AE-019/2008',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2008-07-18',
    '2008-0180360-4',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-019-2008-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    6500.76,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-019-2008-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2008-0180360-4',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-019-2008-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0049',
    '2008-0203754-9',
    'SIMPROC'::tipo_processo_enum,
    '2008-07-07',
    'DEFERIDO'::status_pa_enum,
    'CANTABRIA EMPREENDIMENTOS IMOBILIARIOS LTDA',
    '08255223/0001-01;',
    'AVENIDA DAS NAÇÕES UNIDAS; RUA VERBO DIVINO',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'ALTERACAO'::requerimento_enum,
    7237.14
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0049'),
    'AE-016/2010',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2010-09-27',
    '2008-0203754-9',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-016-2010-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    21530.49,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-016-2010-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2008-0203754-9',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-016-2010-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0050',
    '2007-0194550-4',
    'SIMPROC'::tipo_processo_enum,
    '2007-06-19',
    'DEFERIDO'::status_pa_enum,
    'REC BERRINI S/A',
    '07922482/0001-86;',
    'AVENIDA DAS NAÇÕES UNIDAS S/N; AVENIDA ENGENHEIRO LUIS CARLOS BERRINI; RUA HANS OERSTED; RUA GERALDO FLAUSINO GOMES',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    'VINCULACAO'::requerimento_enum,
    23474.57
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0050'),
    'AE-022/2008',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2008-08-28',
    '2007-0194550-4',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-022-2008-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    38897.36,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-022-2008-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2007-0194550-4',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-022-2008-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0051',
    '2007-0252903-2',
    'SIMPROC'::tipo_processo_enum,
    '2007-08-10',
    'DEFERIDO'::status_pa_enum,
    'BROOKFIELD SÃO PAULO EMPREENDIMENTOS IMOBILIÁRIOS LTDA.; DAVILAR - PROJETOS E EMPREENDIMENTOS LTDA.; FDR EMPREENDIMENTOS E PARTICIPAÇÕES LTDA.',
    '58877812/0001-08;',
    'RUA GABRIELLE D''ANNUZIO, 974, 992, 1002; RUA JOÃO ÁLVARES SOARES, 871, 879, 887; RUA VOLTA REDONDA, 313;',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    2459.90
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0051'),
    'AE-023/2010',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2010-11-11',
    '2007-0252903-2',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-023-2010-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    6065.39,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-023-2010-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2007-0252903-2',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-023-2010-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0052',
    '7810.2020/0000795-3',
    'SEI'::tipo_processo_enum,
    '2020-07-21',
    'DEFERIDO'::status_pa_enum,
    'BERRINI BANDEIRANTES EMPREENDIMENTOS IMOBILIÁRIOS SPE LTDA.; ',
    '07860032/0001-06;',
    'AVENIDA LUIS CARLOS BERRINI, 105',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    'ALTERACAO'::requerimento_enum,
    35279.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0052'),
    'AE-008/2020',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2020-12-10',
    '7810.2020/0000795-3',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-008-2020-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    12945.73,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-008-2020-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '7810.2020/0000795-3',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-008-2020-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-008-2020-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    54429.64,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-008-2020-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '7810.2020/0000795-3',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-008-2020-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0052'),
    'DV-001/2018',
    'DESVINCULAÇÃO'::tipo_certidao_enum,
    '2018-12-05',
    '2018-0.029.273-9',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'DV-001-2018-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    3287.53,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'DISPONIVEL'::estado_titulo_enum,
    '2018-12-05'
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'DV-001-2018-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'DISPONIVEL'::estado_titulo_enum,
    '2018-0.029.273-9',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'DV-001-2018-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0052'),
    'DV-003/2020',
    'DESVINCULAÇÃO'::tipo_certidao_enum,
    '2020-12-10',
    '7810.2020/0000795-3',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'DV-003-2020-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    10821.99,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'DISPONIVEL'::estado_titulo_enum,
    '2020-12-10'
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'DV-003-2020-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'DISPONIVEL'::estado_titulo_enum,
    '7810.2020/0000795-3',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'DV-003-2020-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0052'),
    'DV-002/2014',
    'DESVINCULAÇÃO'::tipo_certidao_enum,
    '2014-08-04',
    '2013-0173853-7',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'DV-002-2014-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    12945.47,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'DISPONIVEL'::estado_titulo_enum,
    '2014-08-04'
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'DV-002-2014-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'DISPONIVEL'::estado_titulo_enum,
    '2013-0173853-7',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'DV-002-2014-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0053',
    '2008-0200218-4',
    'SIMPROC'::tipo_processo_enum,
    '2008-07-03',
    'DEFERIDO'::status_pa_enum,
    'MAXCASA XX EMPREENDIMENTOS IMOBILIÁRIOS LETDA.',
    '09253375/0001-38;',
    'RUA LEON FOUCAULT 56, 45, 51, 49, 42, 33; RUA JAMES JOULE, 290, 292; AVENIDA LUIS CARLOS BERRINI 1584, 1604, 1606, 1612, 1616, 1618, 1622, 1624, 1636; RUA LEON FOUCAULT, 41 E 37, 290 X AVENIDA ENGENHEIRO LUIS CARLOS BERRINI',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    'VINCULACAO'::requerimento_enum,
    2843.75
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0053'),
    'AE-006/2011',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2011-03-02',
    '2008-0200218-4',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-006-2011-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    5687.48,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-006-2011-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2008-0200218-4',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-006-2011-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0054',
    '2008-0279762-4',
    'SIMPROC'::tipo_processo_enum,
    '2008-09-17',
    'DEFERIDO'::status_pa_enum,
    'INCORPORADORA INDEPENDENCIA LTDA. - SPE',
    '09548248/0001-66;',
    'RUA NOVA INDEPENDÊNCIA, 87; RUA ANÉSIO PINTO, 29, 37, 41, 43, 61, 63',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    'VINCULACAO'::requerimento_enum,
    1633.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0054'),
    'AE-025/2008',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2008-10-06',
    '2008-0279762-4',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-025-2008-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    3266.00,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-025-2008-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2008-0279762-4',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-025-2008-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0054'),
    'AE-004/2009',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2009-08-11',
    '2009-0204436-9',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0055',
    '2008-0244347-4',
    'SIMPROC'::tipo_processo_enum,
    '2008-08-14',
    'DEFERIDO'::status_pa_enum,
    'SP MARGINAL EMPREENDIMENTOS IMOBILIÁRIOS LTDA.; BOLSA DE IMÓVEIS DESENVOLVIMENTO IMOBILIÁRIO LTDA.; PAULA EDUARDO INCORPORADORA E CONSTRUTORA LTDA.; GENERAL LEGEND DESENVOLVIMENTO IMOBILIÁRIO E COMERCIAL LTDA.; KENDALL DESENVOLVIMENTO IMOBILIÁRIO E COMERCIAL LTDA.;',
    '09026447/0001-04;',
    'RUA SURUBIM; AVENIDA DAS NAÇÕES UNIDAS; RUA OSWALDO CASEMIRO MULLER',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    'VINCULACAO'::requerimento_enum,
    2553.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0055'),
    'AE-006/2012',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2012-03-28',
    '2008-0244347-4',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-006-2012-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    7637.70,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-006-2012-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2008-0244347-4',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-006-2012-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0056',
    '7810.2019/0000979-2',
    'SEI'::tipo_processo_enum,
    '2019-10-18',
    'DEFERIDO'::status_pa_enum,
    'MORUMBI DO BRASIL PROJETOS IMOBILIÁRIOS LTDA.',
    '08588838/0001-50;',
    'AVENIDA DOUTOR CHUCRI ZAIDAN, 296',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    'VINCULACAO'::requerimento_enum,
    44083.42
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0056'),
    'AE-009/2021',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2021-11-22',
    '7810.2019/0000979-2',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-009-2021-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    19933.62,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-009-2021-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '7810.2019/0000979-2',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-009-2021-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0057',
    '2008-0286570-0',
    'SIMPROC'::tipo_processo_enum,
    '2008-09-23',
    'DEFERIDO'::status_pa_enum,
    'F.REIS ADMINISTRAÇÃO DE IMÓVEIS LTDA.',
    '00076468/0001-60;',
    'AVENIDA ENGENHEIRO LUIS CARLOS BERRINI; RUA JAMES WATT;',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    'VINCULACAO'::requerimento_enum,
    1582.20
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0057'),
    'AE-028/2008',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2008-10-14',
    '2008-0286570-0',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-028-2008-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    3164.40,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-028-2008-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2008-0286570-0',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-028-2008-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0058',
    '7810.2018/0000679-1',
    'SEI'::tipo_processo_enum,
    '2018-09-04',
    'DEFERIDO'::status_pa_enum,
    'COMPANHIA ZAFFARI COMÉRCIO E INDÚSTRIA',
    '93015006/0001-13;',
    'AVENIDA JURUBATUBA, 333',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    'VINCULACAO'::requerimento_enum,
    5418.03
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0058'),
    'AE-003/2018',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2018-11-26',
    '7810.2018/0000679-1',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-003-2018-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    14628.68,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-003-2018-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '7810.2018/0000679-1',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-003-2018-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0059',
    '2013-0074173-9',
    'SIMPROC'::tipo_processo_enum,
    '2013-03-14',
    'DEFERIDO'::status_pa_enum,
    'FREJUS HOLDINGS S/A;',
    '08986330/0001-00;',
    'RUA WILLIAM KELVIN, 12, 23, 26, 27, 29; RUA JEAN PELTIER, 35, 47; RUA LEE FOREST, 23',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    'ALTERACAO'::requerimento_enum,
    2197.40
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0059'),
    'AE-026/2010',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2014-01-30',
    '2013-0074173-9',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-026-2010-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    4342.20,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-026-2010-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2013-0074173-9',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-026-2010-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0059'),
    'DV-001/2014',
    'DESVINCULAÇÃO'::tipo_certidao_enum,
    '2014-01-30',
    '2013-0074173-9',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0060',
    '2007-0254134-2',
    'SIMPROC'::tipo_processo_enum,
    '2007-08-13',
    'DEFERIDO'::status_pa_enum,
    'VISTA ALEGRE EMPREENDIMENTOS IMOBILIÁRIOS S/A',
    '08717943/0001-41;',
    'RUA MINISTRO JOSÉ GALLOTTI, 322, 342, 354, 358, 362/370;',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    3000.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0060'),
    'AE-034/2008',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2008-11-12',
    '2007-0254134-2',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-034-2008-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    9000.00,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-034-2008-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2007-0254134-2',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-034-2008-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0061',
    '2009-0159541-8',
    'SIMPROC'::tipo_processo_enum,
    '2009-05-28',
    'DEFERIDO'::status_pa_enum,
    'GARICEMA EMPREENDIMENTOS IMOBILIÁRIOS LTDA.',
    '08246511/0001-08;',
    'RUA ANTONIO DE OLIVEIRA E PROLONGAMENTO DA AVENIDA DOUTOR CHUCRI ZAIDAN',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    8059.22
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0061'),
    'AE-003/2009',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2009-07-14',
    '2009-0159541-8',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-003-2009-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    19890.29,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-003-2009-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2009-0159541-8',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-003-2009-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0063',
    '2007-0270987-1',
    'SIMPROC'::tipo_processo_enum,
    '2007-08-28',
    'DEFERIDO'::status_pa_enum,
    'AEROPORTO II SPE EMPREENDIMENTOS IMOBILIÁRIOS LTDA.',
    '08598693/0001-78;',
    'RUA CARLOS PINTO ALVES; RUA IPIRANGA; AVENIDA JORNALISTA ROBERTO MARINHO;',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    3671.99
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0063'),
    'AE-003/2011',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2011-09-19',
    '2007-0270987-1',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-003-2011-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    7311.29,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-003-2011-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2007-0270987-1',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-003-2011-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0064',
    '2007-0331946-5',
    'SIMPROC'::tipo_processo_enum,
    '2007-10-23',
    'DEFERIDO'::status_pa_enum,
    'CONTRUTORA BRACCO LTDA.',
    '43282490/0001-79;',
    'RUA FRANCISCO DIAS VELHO, 100;',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    3050.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0064'),
    'AE-005/2009',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2009-08-19',
    '2007-0331946-5',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-005-2009-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    9143.93,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-005-2009-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2007-0331946-5',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-005-2009-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0066',
    '2009-0253432-3',
    'SIMPROC'::tipo_processo_enum,
    '2009-08-31',
    'DEFERIDO'::status_pa_enum,
    'CONCIVIL CONSTRUTORA E INCORPORADORA LTDA.; LUCIUS EMPREENDIMENTOS IMOBILIÁRIOS LTDA.',
    '72951130/0001-10; 46213765/0001-00',
    'RUA RIBEIRO DO VALE, 140/152 E 162; RUA PITU, 42, 50, 58, 68, 72, 78 E 82; PRAÇA ANTONIO BIAS DA COSTA BUENO S/N',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    3430.38
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0066'),
    'AE-010/2009',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2009-11-18',
    '2009-0253432-3',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-010-2009-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    5224.89,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-010-2009-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2009-0253432-3',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-010-2009-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-010-2009-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    5066.25,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-010-2009-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2009-0253432-3',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-010-2009-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0067',
    '2008-0214421-3',
    'SIMPROC'::tipo_processo_enum,
    '2008-07-17',
    'DEFERIDO'::status_pa_enum,
    'TDSP - MARATONA EMPREENDIMENTOS IMOBILIÁRIOS SPE LTDA.',
    '08396968/0001-90;',
    'RUA MARATONA, 285; AVENIDA MASCOTE ',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    5497.74
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0067'),
    'AE-007/2009',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2009-10-13',
    '2008-0214421-3',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0067'),
    'AE-011/2010',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2010-09-17',
    '2008-0214421-3',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-011-2010-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    16493.22,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-011-2010-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2008-0214421-3',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-011-2010-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0068',
    '2008-0197796-3',
    'SIMPROC'::tipo_processo_enum,
    '2008-07-01',
    'DEFERIDO'::status_pa_enum,
    'GAFISA S/A',
    '01545826/0001-07;',
    'RUA GEORGE OHM, 330',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    4360.60
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0068'),
    'AE-009/2009',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2009-11-12',
    '2008-0197796-3',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-009-2009-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    13073.08,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-009-2009-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2008-0197796-3',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-009-2009-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0069',
    '2009-0314766-8',
    'SIMPROC'::tipo_processo_enum,
    '2009-10-27',
    'DEFERIDO'::status_pa_enum,
    'F.REIS ADMINISTRAÇÃO DE IMÓVEIS LTDA.',
    '00076468/0001-60;',
    'RUA GUARAIUVA, 117, 125, 135, 143, 145, 149, 151; RUA CASTILHO, 243, 253, 255',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    2070.20
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0069'),
    'AE-011/2009',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2009-12-11',
    '2009-0314766-8',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-011-2009-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    6210.60,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-011-2009-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2009-0314766-8',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-011-2009-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0069'),
    'AE-003/2012',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2012-01-26',
    '2009-0314766-8',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0070',
    '2009-0352407-0',
    'SIMPROC'::tipo_processo_enum,
    '2009-12-02',
    'DEFERIDO'::status_pa_enum,
    'SEGA II SPE EMPREENDIMENTOS IMOBILIÁRIOS LTDA.',
    '09132973/0001-59;',
    'RUA LUIZ CORREIA DE MELO, 86; RUA PAULO ASSUMPÇÃO',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    3301.25
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0070'),
    'AE-001/2010',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2010-02-03',
    '2009-0352407-0',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-001-2010-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    9903.59,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-001-2010-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2009-0352407-0',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-001-2010-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0071',
    '2009-0346918-5',
    'SIMPROC'::tipo_processo_enum,
    '2009-11-27',
    'DEFERIDO'::status_pa_enum,
    'EMPAGE CONSTRUÇÕES, EMPREENDIMENTOS E PARTICIPAÇÕES IMOBILIÁRIAS LTDA.; BRAGANÇA EMPREENDIMENTOS IMOBILIÁRIOS S/A',
    '47686431/0001-17; 47684774/0001-42',
    'RUA VERBO DIVINO, S/N',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    3109.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0071'),
    'AE-002/2010',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2010-02-26',
    '2009-0346918-5',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-002-2010-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    9327.00,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-002-2010-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2009-0346918-5',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-002-2010-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0072',
    '2009-0369740-4',
    'SIMPROC'::tipo_processo_enum,
    '2009-12-18',
    'DEFERIDO'::status_pa_enum,
    'TREVISO INCORPORADORA LTDA.',
    '09061475/0001-62;',
    'RUA GABRIELLE D''ANUZZIO, 509, 517, 523, 541; RUA CONSTANTINO DE SOUSA, 1168, 1156, 1144/943 E 1130; RUA EDILSON, 514, 524',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    4039.62
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0072'),
    'AE-006/2010',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2010-03-24',
    '2009-0369740-4',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-006-2010-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    12118.86,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-006-2010-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2009-0369740-4',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-006-2010-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0073',
    '2010-0040873-2',
    'SIMPROC'::tipo_processo_enum,
    '2010-10-02',
    'DEFERIDO'::status_pa_enum,
    'TORINO INCORPORADORA LTDA.',
    '09158915/0001-02;',
    'RUA ALCEU MAYNARD DE ARAUJO; RUA DALVA DE OLIVEIRA; RUA AURORA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    2765.24
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0073'),
    'AE-007/2010',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2010-05-06',
    '2010-0040873-2',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-007-2010-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    5530.48,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-007-2010-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2010-0040873-2',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-007-2010-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0074',
    '2010-0057196-0',
    'SIMPROC'::tipo_processo_enum,
    '2010-03-01',
    'DEFERIDO'::status_pa_enum,
    'RAGUSA EMPREENDIMENTOS IMOBILIÁRIOS LTDA',
    '08995916/0001-30;',
    'RUA BARTOLOMEU FEIO',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'ALTERACAO'::requerimento_enum,
    4776.22
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0074'),
    'AE-014/2012',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2012-08-06',
    '2010-0057196-0',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-014-2012-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    11320.14,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-014-2012-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2010-0057196-0',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-014-2012-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0075',
    '2009-0370866-0',
    'SIMPROC'::tipo_processo_enum,
    '2009-12-21',
    'DEFERIDO'::status_pa_enum,
    'SERPENS EVEN EMPREENDIMENTOS IMOBILIÁRIOS LTDA',
    '08504673/0001-90;',
    'RUA ANTONIO MACEDO SOARES, 878; RUA VOLTA REDONDA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    2660.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0075'),
    'AE-012/2010',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2010-09-17',
    '2009-0370866-0',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-012-2010-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    7980.00,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-012-2010-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2009-0370866-0',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-012-2010-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0075'),
    'AE-004/2010',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2010-03-23',
    '2009-0370866-0',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0076',
    '2009-0128266-5',
    'SIMPROC'::tipo_processo_enum,
    '2009-04-30',
    'DEFERIDO'::status_pa_enum,
    'BRPR XIII EMPREENDIMENTOS E PARTICIPAÇÕES LTDA',
    '09230719/0001-93;',
    'AVENIDA ALFREDO EGIDIO DE SOUZA ARANHA, 145',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    3480.42
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0076'),
    'AE-018/2010',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2010-10-05',
    '2009-0128266-5',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-018-2010-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    2764.36,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-018-2010-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2009-0128266-5',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-018-2010-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0076'),
    'AE-009/2010',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2010-05-28',
    '2009-0128266-5',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0077',
    '2010-0074379-5',
    'SIMPROC'::tipo_processo_enum,
    '2010-03-16',
    'DEFERIDO'::status_pa_enum,
    'MULTIPLAN EMPREENDIMENTOS IMOBILIÁRIOS S/A',
    '07816890/0001-53;',
    'RUA HENRI DUNAT, 27',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    19977.32
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0077'),
    'AE-014/2010',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2010-09-27',
    '2010-0074379-5',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-014-2010-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    59931.96,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-014-2010-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2010-0074379-5',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-014-2010-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0078',
    '2010-0149490-0',
    'SIMPROC'::tipo_processo_enum,
    '2010-05-27',
    'DEFERIDO'::status_pa_enum,
    'ALEXANDRIA INCORPORADORA LTDA',
    '09280707/0001-73;',
    'RUA ENXOVIA, 472',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    4475.77
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0078'),
    'AE-020/2010',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2010-10-07',
    '2010-0149490-0',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-020-2010-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    13427.31,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-020-2010-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2010-0149490-0',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-020-2010-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0079',
    '2010-0096394-9',
    'SIMPROC'::tipo_processo_enum,
    '2010-04-07',
    'DEFERIDO'::status_pa_enum,
    'DRAGON EVEN EMPREENDIMENTOS IMOBILIÁRIOS LTDA',
    '09244754/0001-61;',
    'RUA PORTO UNIAO, S/N; RUA CASTILHO, 119, 123, 131, 139, 147, 155, 163, 173, 179',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    3430.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0079'),
    'AE-002/2011',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2011-02-01',
    '2010-0096394-9',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-002-2011-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    10290.00,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-002-2011-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2010-0096394-9',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-002-2011-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0079'),
    'AE-010/2010',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2010-06-29',
    '2010-0096394-9',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0080',
    '2010-0197007-0',
    'SIMPROC'::tipo_processo_enum,
    '2010-07-12',
    'DEFERIDO'::status_pa_enum,
    'PAULA EDUARDO INCORPORADORA E CONSTRUTORA LTDA; KENDALL DESENVOLVIMENTO IMOBILIÁRIO E COMERCIAL LTDA; GENERAL LEGEND DESENVOLVIMENTO IMOBILIÁRIO E COMERCIAL LTDA',
    '50473552/0001-95; 07241414/0001-51; 06078347/0001-33',
    'RUA CONCEICAO DE MONTE ALEGRE, 63, 69, 75, 87, 99, 107, 109, 117, S/Nº, 135, 147, 155; RUA GEORGE  OHM, 156, 174, 180, 188, 198, 206, 210, 220, 230, 234, 250; RUA CASTILHO, 465, 475, 479, 481, 483, 489',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    5877.47
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0080'),
    'AE-013/2010',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2010-09-22',
    '2010-0197007-0',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-013-2010-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    17485.10,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-013-2010-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2010-0197007-0',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-013-2010-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0081',
    '2010-0189999-3',
    'SIMPROC'::tipo_processo_enum,
    '2010-07-12',
    'DEFERIDO'::status_pa_enum,
    'CONCEIÇÃO DE MONTE ALEGRE EMPREENDIMENTO IMOBILIÁRIO LTDA',
    '10271612/0001-72;',
    'RUA CONCEIÇÃO DE MONTE ALEGRE, 220, 214, 210, 204, 198; RUA CASTILHO, 354, 366, 378, 982, 388, 392, 394, 390, 398, 408, 412',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    2881.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0081'),
    'AE-015/2010',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2010-09-27',
    '2010-0189999-3',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-015-2010-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    8643.00,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-015-2010-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2010-0189999-3',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-015-2010-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0081'),
    'AE-020/2013',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2013-06-28',
    '2013-0156645-0',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-020-2013-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    304.26,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-020-2013-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2013-0156645-0',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-020-2013-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0082',
    '2010-0219293-1',
    'SIMPROC'::tipo_processo_enum,
    '2010-08-10',
    'DEFERIDO'::status_pa_enum,
    'GAFISA SPE-91 EMPREENDIMENTOS IMOBIIÁRIOS LTDA',
    '10761429/0001-55;',
    'RUA LUIZ SERAPHICO JUNIOR; RUA CARMO DO RIO VERDE',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    6200.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0082'),
    'AE-021/2010',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2010-10-26',
    '2010-0219293-1',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-021-2010-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    18599.88,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-021-2010-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2010-0219293-1',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-021-2010-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0083',
    '2010-0246867-8',
    'SIMPROC'::tipo_processo_enum,
    '2010-09-03',
    'DEFERIDO'::status_pa_enum,
    'LYRA EVEN EMPREENDIMENTOS IMOBILIÁRIOS LTDA',
    '08720169/0001-28;',
    'RUA GABRIELLE D''ANNUZIO; RUA DR. ESTÁCIO DE COIMBRA; RUA CONSTANTINO DE SOUZA; RUA BARÃO DE JACEGUAI',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    4563.27
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0083'),
    'AE-019/2010',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2010-10-05',
    '2010-0246867-8',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0083'),
    'AE-005/2011',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2011-03-02',
    '2010-0246867-8',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-005-2011-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    13689.35,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-005-2011-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2010-0246867-8',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-005-2011-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0084',
    '2010-0246869-4',
    'SIMPROC'::tipo_processo_enum,
    '2010-09-03',
    'DEFERIDO'::status_pa_enum,
    'CARP EVEN EMPREENDIMENTOS IMOBILIÁRIOS LTDA',
    '10322138/0001-60;',
    'AVENIDA PORTUGAL, S/Nº 1048 e 1058',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    2950.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0084'),
    'AE-008/2011',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2011-03-15',
    '2010-0246869-4',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-008-2011-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    8849.54,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-008-2011-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2010-0246869-4',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-008-2011-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0084'),
    'AE-017/2010',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2010-09-29',
    '2010-0246869-4',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0085',
    '2010-0119440-0',
    'SIMPROC'::tipo_processo_enum,
    '2010-04-29',
    'DEFERIDO'::status_pa_enum,
    'PORTUGAL EMPREENDIMENTO IMOBILIÁRIO SP LTDA',
    '11347335/0001-05;',
    'AVENIDA PORTUGAL, 1213, 1223, 1229, 1239, 1249',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    2000.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0085'),
    'AE-022/2010',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2010-11-10',
    '2010-0119440-0',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-022-2010-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    6000.00,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-022-2010-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2010-0119440-0',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-022-2010-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0086',
    '2010-0296329-6',
    'SIMPROC'::tipo_processo_enum,
    '2010-10-28',
    'DEFERIDO'::status_pa_enum,
    'SOLIDAIRE EMPREENDIMENTOS IMOBILIÁRIOS LTDA',
    '09101709/0001-58;',
    'RUA MARATONA, S/Nº, 219, 235',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    2302.01
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0086'),
    'AE-025/2010',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2010-12-17',
    '2010-0296329-6',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-025-2010-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    4604.02,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-025-2010-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2010-0296329-6',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-025-2010-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0088',
    '2009-0373280-3',
    'SIMPROC'::tipo_processo_enum,
    '2009-12-23',
    'DEFERIDO'::status_pa_enum,
    'INCORPORADORA RPF LTDA',
    '06974169/0001-29;',
    'RUA SOBERANA, 49',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    'VINCULACAO'::requerimento_enum,
    2367.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0088'),
    'AE-015/2014',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2014-08-04',
    '2009-0373280-3',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-015-2014-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    755.94,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-015-2014-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2009-0373280-3',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-015-2014-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-015-2014-R-NUVEM',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    100.62,
    'R'::uso_enum,
    'NUVEM'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-015-2014-R-NUVEM');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2009-0373280-3',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-015-2014-R-NUVEM'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0088'),
    'DV-001/2016',
    'DESVINCULAÇÃO'::tipo_certidao_enum,
    '2016-01-21',
    '2015-0.093.871-4',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'DV-001-2016-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    100.62,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'DISPONIVEL'::estado_titulo_enum,
    '2016-01-21'
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'DV-001-2016-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'DISPONIVEL'::estado_titulo_enum,
    '2015-0.093.871-4',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'DV-001-2016-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0089',
    '2010-0348275-5',
    'SIMPROC'::tipo_processo_enum,
    '2010-12-21',
    'DEFERIDO'::status_pa_enum,
    'VR ALUGUEIS E SERVIÇOS LTDA',
    '01041019/0001-49;',
    'RUA ROSA GAETA LAZARA; AVENIDA DOS BANDEIRANTES; RUA ARABERI',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    'VINCULACAO'::requerimento_enum,
    3219.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0089'),
    'AE-004/2012',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2012-03-13',
    '2010-0348275-5',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-004-2012-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    6438.00,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-004-2012-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2010-0348275-5',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-004-2012-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0090',
    '2010-0182160-9',
    'SIMPROC'::tipo_processo_enum,
    '2010-07-01',
    'DEFERIDO'::status_pa_enum,
    'BROOKFIELD SÃO PAULO EMPREENDIMENTOS IMOBILIÁRIOS S/A',
    '58877812/0001-08;',
    'RUA  PROFESSOR JOSÉ LEITE DE OITICICA ESQUINA COM A RUA HENRIQUE FISCHER ',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    3477.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0090'),
    'AE-007/2011',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2011-03-14',
    '2010-0182160-9',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-007-2011-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    10330.80,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-007-2011-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2010-0182160-9',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-007-2011-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0091',
    '2010-0309276-0',
    'SIMPROC'::tipo_processo_enum,
    '2010-11-11',
    'DEFERIDO'::status_pa_enum,
    'GABRIELE EMPREENDIMENTOS IMOBILIÁRIO SPE LTDA',
    '12257101/0001-00;',
    'RUA GABRIELE D''ANNUNZIO, 772, 762, 760, 752, 742, 720/730; RUA BARÃO DE JACEGUAI, 888, 874/828, 864, 856, 842; RUA ESTÁCIO COIMBRA, 151, 161, 57, 191; RUA ANTÔNIO DE MACEDO SOARES 881, 889, 895, 905',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    5113.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0091'),
    'AE-011/2011',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2011-03-24',
    '2010-0309276-0',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-011-2011-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    15339.00,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-011-2011-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2010-0309276-0',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-011-2011-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0092',
    '2011-0012029-3',
    'SIMPROC'::tipo_processo_enum,
    '2011-01-17',
    'DEFERIDO'::status_pa_enum,
    'CYRELA POLINÉSIA EMPREENDIMENTOS IMOBILIÁRIOS LTDA',
    '09474398/0001-72;',
    'AVENIDA WASHIGTON LUIS x RUA VUPABUSSU',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    3063.20
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0092'),
    'AE-012/2011',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2011-04-11',
    '2011-0012029-3',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-012-2011-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    9173.98,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-012-2011-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2011-0012029-3',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-012-2011-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0093',
    '2011-0051286-8',
    'SIMPROC'::tipo_processo_enum,
    '2011-02-23',
    'DEFERIDO'::status_pa_enum,
    'GD VI EMPREENDIMENTO IMOBILIÁRIO LTDA',
    '10460895/0001-09;',
    'RUA GABRIELE DANNUZIO 518, 530, 542; RUA CONSTANTINO DE SOUZA 1236, 1244; RUA BARÃO DE SABARÁ 46, 64, 68, 76',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    2324.37
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0093'),
    'AE-010/2011',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2011-03-24',
    '2011-0051286-8',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0093'),
    'AE-014/2011',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2011-05-05',
    '2011-0051286-8',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-014-2011-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    6973.11,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-014-2011-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2011-0051286-8',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-014-2011-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0094',
    '2011-0050860-7',
    'SIMPROC'::tipo_processo_enum,
    '2011-02-23',
    'DEFERIDO'::status_pa_enum,
    'IRIGNY EMPREENDIMENTOS IMOBILIÁRIOS S.A',
    '11396329/0001-30;',
    'RUA ARIZONA X RUA PITU',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    2820.56
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0094'),
    'AE-009/2011',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2011-03-24',
    '2011-0050860-7',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0094'),
    'AE-013/2011',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2011-04-19',
    '2011-0050860-7',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-013-2011-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    8461.68,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-013-2011-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2011-0050860-7',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-013-2011-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0095',
    '2011-0066888-4',
    'SIMPROC'::tipo_processo_enum,
    '2011-03-11',
    'DEFERIDO'::status_pa_enum,
    'GAFISA S/A',
    '01545826/0001-07;',
    'RUA LACEDEMONIA, 520, 524, 540, 556',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    2040.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0095'),
    'AE-015/2011',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2011-05-09',
    '2011-0066888-4',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-015-2011-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    6120.00,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-015-2011-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2011-0066888-4',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-015-2011-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0096',
    '2011-0136404-8',
    'SIMPROC'::tipo_processo_enum,
    '2011-05-18',
    'DEFERIDO'::status_pa_enum,
    'EVEN-SP 24/10 EMPREENDIMENTOS IMOBILIARIOS LTDA',
    '12383542/0001-70;',
    'RUA MICHIGAN 517, 531, 547; RUA ARIZONA 394, 404, 410, 420',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    4000.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0096'),
    'AE-020/2011',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2011-11-08',
    '2011-0136404-8',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-020-2011-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    12000.00,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-020-2011-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2011-0136404-8',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-020-2011-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0096'),
    'AE-016/2011',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2011-11-08',
    '2011-0136404-8',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0098',
    '2011-0181552-0',
    'SIMPROC'::tipo_processo_enum,
    '2012-07-01',
    'DEFERIDO'::status_pa_enum,
    'YUNY STAN PROJETO IMOBILIARIO I S/A',
    '11939724/0001-11;',
    'RUA FLORIDA; RUA NOVA IORQUE; RUA MICHIGAN',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    5000.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0098'),
    'AE-023/2012',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2012-08-30',
    '2011-0181552-0',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-023-2012-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    13922.10,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-023-2012-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2011-0181552-0',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-023-2012-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-023-2012-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    1077.90,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-023-2012-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2011-0181552-0',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-023-2012-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0099',
    '2011-0047799-9',
    'SIMPROC'::tipo_processo_enum,
    '2010-03-03',
    'DEFERIDO'::status_pa_enum,
    'MSB CAMPO BELO EMPREENDIMENTOS IMOBILIARIOS LTDA.',
    '11342548/0001-36;',
    'RUA BERNARDINO DE CAMPOS 255, 263, 271, 277, 297; RUA BARAO DO TRIUNFO 618, 608, 604',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    2750.72
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0099'),
    'AE-023/2011',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2011-10-14',
    '2011-0047799-9',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-023-2011-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    8249.13,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-023-2011-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2011-0047799-9',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-023-2011-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0100',
    '2010-0252313-0',
    'SIMPROC'::tipo_processo_enum,
    '2011-06-07',
    'DEFERIDO'::status_pa_enum,
    'MAXCASA XIX EMPREENDIMENTOS IMOBILIARIOS S.A.',
    '10439139/0001-90;',
    'RUA JOAQUIM GUARANI; RUA DIOGO DE QUADROS',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    3131.79
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0100'),
    'AE-002/2012',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2012-01-24',
    '2010-0252313-0',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-002-2012-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    5927.74,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-002-2012-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2010-0252313-0',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-002-2012-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0101',
    '2011-0117870-8',
    'SIMPROC'::tipo_processo_enum,
    '2011-04-29',
    'DEFERIDO'::status_pa_enum,
    'BRASCOM EMPREENDIMENTOS E PARTICIPACOES LTDA.',
    '02255731/0001-03;',
    'RUA FRANCISCO TRAMONTANO; AVENIDA ULYSSES REAIS DE MATTOS',
    (SELECT id FROM setor WHERE nome = 'Marginal Pinheiros'),
    'VINCULACAO'::requerimento_enum,
    3067.81
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0101'),
    'AE-019/2011',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2011-09-01',
    '2011-0117870-8',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-019-2011-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Marginal Pinheiros'),
    9203.43,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-019-2011-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2011-0117870-8',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-019-2011-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0102',
    '2010-0061078-7',
    'SIMPROC'::tipo_processo_enum,
    '2010-03-03',
    'DEFERIDO'::status_pa_enum,
    'LUBA 4 EMPREENDIMENTOS IMOBILIARIOS LTDA.',
    '10197393/0001-29;',
    'RUA JACERU, 384',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    2448.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0102'),
    'AE-018/2011',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2011-08-31',
    '2010-0061078-7',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-018-2011-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    7341.94,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-018-2011-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2010-0061078-7',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-018-2011-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0103',
    '2010-0343298-7',
    'SIMPROC'::tipo_processo_enum,
    '2010-12-15',
    'DEFERIDO'::status_pa_enum,
    'WTORRE ALFA EMPREENDIMENTOS IMOBILIARIOS LTDA.',
    '07588933/0001-90;',
    'AVENIDA NACOES UNIDAS, 14261',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    22548.40
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0103'),
    'AE-024/2011',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2011-11-03',
    '2010-0343298-7',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-024-2011-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    67645.20,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-024-2011-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2010-0343298-7',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-024-2011-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0104',
    '2010-0330627-6',
    'SIMPROC'::tipo_processo_enum,
    NULL,
    'DEFERIDO'::status_pa_enum,
    'BROOKFIELD SAO PAULO EMPREENDIMENTOS IMOBILIARIOS S/A',
    '58877812/0001-08;',
    'RUA ABILIO BORIN; RUA BRAGANCA PAULISTA, 1036; RUA ADERALDO DE MORAES',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    4000.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0104'),
    'AE-021/2011',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2011-09-13',
    '2010-0330627-6',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-021-2011-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    11986.16,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-021-2011-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2010-0330627-6',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-021-2011-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0105',
    '2011-0047799-9',
    'SIMPROC'::tipo_processo_enum,
    '2011-02-21',
    'DEFERIDO'::status_pa_enum,
    'BROOKFIELD SAO PAULO EMPREENDIMENTOS IMOBILIARIOS S/A',
    '58877812/0001-08;',
    'RUA MICHIGAN, 457, 467, 507; RUA NOVA YORK 141, 159, 161, 185, 189; RUA ARIZONA, 342, 354, 363, 372, 384',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    4900.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0105'),
    'AE-022/2011',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2011-10-14',
    '2011-0047799-9',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-022-2011-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    14686.80,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-022-2011-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2011-0047799-9',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-022-2011-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0106',
    '2011-0267977-8',
    'SIMPROC'::tipo_processo_enum,
    '2011-09-21',
    'DEFERIDO'::status_pa_enum,
    'HALW1 EMPREENDIMENTO IMOBILIARIO SPE LTDA.',
    '08427297/0001-88;',
    'RUA HENRI DURANT, 873; RUA AMARO GUERRA, 820',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    3373.90
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0106'),
    'AE-007/2012',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2012-03-28',
    '2011-0267977-8',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-007-2012-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    10121.70,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-007-2012-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2011-0267977-8',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-007-2012-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0106'),
    'AE-025/2011',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2011-11-04',
    '2011-0267977-8',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0107',
    '7810.2021/0001423-4',
    'SEI'::tipo_processo_enum,
    '2021-09-24',
    'DEFERIDO'::status_pa_enum,
    'ARCONTE DESENVOLVIMEN TO IMOBILIÁRIO LTDA.',
    '10460869/0001-45;',
    'AVENIDA MAJOR SYLVIO DE MAGALHAES PADILHA, KM 14',
    (SELECT id FROM setor WHERE nome = 'Marginal Pinheiros'),
    'ALTERACAO'::requerimento_enum,
    44397.06
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0107'),
    'AE-002/2022',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2022-01-19',
    '7810.2021/0001423-4',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-002-2022-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Marginal Pinheiros'),
    29082.74,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-002-2022-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '7810.2021/0001423-4',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-002-2022-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0108',
    '2011-0230134-1',
    'SIMPROC'::tipo_processo_enum,
    '2011-08-16',
    'DEFERIDO'::status_pa_enum,
    'CYRELA POLINESIA EMPREENDIMENTOS IMOBILIARIOS LTDA.',
    '09474398/0001-72;',
    'RUA BARTOLOMEU FEIO; RUA PORTUGUAL',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    2435.18
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0108'),
    'AE-026/2011',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2011-11-08',
    '2011-0230134-1',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-026-2011-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    6883.77,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-026-2011-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2011-0230134-1',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-026-2011-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0110',
    '2011-0237615-5',
    'SIMPROC'::tipo_processo_enum,
    '2014-03-27',
    'DEFERIDO'::status_pa_enum,
    'CBD COMPANHIA BRASILEIRA DE DISTRIBUCAO ',
    '47508411/0001-56;',
    'RUA ZACARIAS DE GOIS; RUA JOAO ALVARES SOARES; RUA BERNARDINO DE CAMPOS',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    8033.87
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0110'),
    'AE-010/2014',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2014-03-27',
    '2011-0237615-5',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0111',
    '2010-0310511-0',
    'SIMPROC'::tipo_processo_enum,
    '2010-11-11',
    'DEFERIDO'::status_pa_enum,
    'GARICEMA EMPREENDIMENTOS IMOBILIARIOS LTDA.',
    '08246511/0001-08;',
    'AVENIDA DOUTOR CHUCRI ZAIDAN',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'ALTERACAO'::requerimento_enum,
    23440.96
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0111'),
    'AE-005/2012',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2012-03-23',
    '2010-0310511-0',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-005-2012-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    70322.88,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-005-2012-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2010-0310511-0',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-005-2012-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0112',
    '2013-0019912-8',
    'SIMPROC'::tipo_processo_enum,
    '2013-01-22',
    'DEFERIDO'::status_pa_enum,
    'ROBERTO MARINHO EMPREENDIMENTO IMOBILIARIO LTDA.',
    '13018895/0001-33;',
    'AVENIDA JORNALISTA ROBERTO MARINHO; RUA ANTONIO DE MACEDO SOARES; RUA DOUTOR ESTACIO DE COIMBRA; RUA BARAO DE JACEGUAI',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    4316.06
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0112'),
    'AE-029/2013',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2013-10-09',
    '2013-0019912-8',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-029-2013-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    7974.78,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-029-2013-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2013-0019912-8',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-029-2013-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0113',
    '2011-0314665-0',
    'SIMPROC'::tipo_processo_enum,
    '2011-11-04',
    'DEFERIDO'::status_pa_enum,
    'QUADCITY ZACARIAS DE GOES EMPREENDIMENTO E PARTICIPACOES LTDA.',
    '12993209/0001-82;',
    'RUA ZACARIAS DE GOES; RUA WALTER FONTENELLE RIBEIRO; RUA XAVIER GOUVEIA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    2668.40
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0113'),
    'AE-011/2012',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2012-06-18',
    '2011-0314665-0',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-011-2012-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    8005.20,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-011-2012-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2011-0314665-0',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-011-2012-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0113'),
    'AE-027/2011',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2011-12-08',
    '2011-0314665-0',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0114',
    '7810.2019/0000110-4',
    'SEI'::tipo_processo_enum,
    '2019-02-07',
    'DEFERIDO'::status_pa_enum,
    'STAN G LARA EMPREENDIMENTO SPE LTDA',
    '12514587/0001-36;',
    'RUA BARTOLOMEU FEIO, 855; RUA GABRIEL DE LARA, 4, 6, 8, 10, 12, 37',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'ALTERACAO'::requerimento_enum,
    3175.40
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0114'),
    'AE-006/2019',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2019-07-17',
    '7810.2019/0000110-4',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-006-2019-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    7846.10,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-006-2019-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '7810.2019/0000110-4',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-006-2019-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0115',
    '2012-0004621-4',
    'SIMPROC'::tipo_processo_enum,
    '2012-01-05',
    'DEFERIDO'::status_pa_enum,
    'AVEIRO INCORPORACOES S/A',
    '08274761/0001-43;',
    'RUA ARMANDO PETRELLA, 311',
    (SELECT id FROM setor WHERE nome = 'Marginal Pinheiros'),
    'ALTERACAO'::requerimento_enum,
    7476.62
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0115'),
    'AE-009/2015',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2015-07-29',
    '2012-0004621-4',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-009-2015-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Marginal Pinheiros'),
    9708.42,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-009-2015-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2012-0004621-4',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-009-2015-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-009-2015-R-NUVEM',
    (SELECT id FROM setor WHERE nome = 'Marginal Pinheiros'),
    1301.13,
    'R'::uso_enum,
    'NUVEM'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-009-2015-R-NUVEM');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2012-0004621-4',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-009-2015-R-NUVEM'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0116',
    '2012-0056682-0',
    'SIMPROC'::tipo_processo_enum,
    '2012-02-28',
    'DEFERIDO'::status_pa_enum,
    'JLO BROOKLIN EMPREENDIMENTO IMOBILIARIO SPE LTDA.',
    '12436890/0001-08;',
    'RUA JOSE LEITE E OITICICA, 125',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    1231.25
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0116'),
    'AE-008/2012',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2012-04-03',
    '2012-0056682-0',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-008-2012-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    3676.16,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-008-2012-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2012-0056682-0',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-008-2012-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0117',
    '2010-0263866-2',
    'SIMPROC'::tipo_processo_enum,
    '2012-05-17',
    'DEFERIDO'::status_pa_enum,
    'SK EDSON EMPREENDIMENTOS IMOBILIARIOS SPE LTDA.',
    '09009224/0001-39;',
    'RUA EDSON, 110',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    3367.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0117'),
    'AE-010/2012',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2012-05-17',
    '2010-0263866-2',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-010-2012-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    10099.37,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-010-2012-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2010-0263866-2',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-010-2012-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0118',
    '2016-0193172-3',
    'SIMPROC'::tipo_processo_enum,
    '2016-08-24',
    'DEFERIDO'::status_pa_enum,
    'ODEBRECHT REALIZACOES SP 02 EMPREENDIMENTO IMOBILIARIO LTDA.',
    '12998645/0001-44;',
    'RUA DOUTOR JOSE AUREO BASTAMANTE; RUA TAPIRA; RUA AVELINO; RUA HENRI DUNANT',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'ALTERACAO'::requerimento_enum,
    9977.50
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0118'),
    'AE-009/2017',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2017-12-20',
    '2016-0193172-3',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-009-2017-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    8089.12,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-009-2017-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2016-0193172-3',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-009-2017-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-009-2017-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    19139.89,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-009-2017-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2016-0193172-3',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-009-2017-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-009-2017-R-NUVEM',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    204.70,
    'R'::uso_enum,
    'NUVEM'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-009-2017-R-NUVEM');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2016-0193172-3',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-009-2017-R-NUVEM'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-009-2017-NR-NUVEM',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    434.79,
    'NR'::uso_enum,
    'NUVEM'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-009-2017-NR-NUVEM');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2016-0193172-3',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-009-2017-NR-NUVEM'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0118'),
    'AE-042/2013',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2013-11-25',
    '2013-0132078-8',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-042-2013-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    38894.29,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-042-2013-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2013-0132078-8',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-042-2013-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0118'),
    'AE-041/2013',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2013-11-25',
    '2013-0132073-7',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-041-2013-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    22847.94,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-041-2013-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2013-0132073-7',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-041-2013-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0119',
    '2012-0072564-2',
    'SIMPROC'::tipo_processo_enum,
    '2012-03-13',
    'DEFERIDO'::status_pa_enum,
    'GAFISA S/A.',
    '01545826/0001-07;',
    'RUA JACERU, 332 A374; RUA VIEIRA DA SILVA, 45',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    2014.90
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0119'),
    'AE-009/2012',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2012-04-16',
    '2012-0072564-2',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-009-2012-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    6044.70,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-009-2012-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2012-0072564-2',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-009-2012-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0120',
    '2012-0076897-0',
    'SIMPROC'::tipo_processo_enum,
    '2012-03-15',
    'DEFERIDO'::status_pa_enum,
    'OPI3 SAO PAULO EMPREENDIMENTOS IMOBILIARIOS SPE LTDA.',
    '12755368/0001-49;',
    'RUA IRMA GABRIELA, 51',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    'VINCULACAO'::requerimento_enum,
    1500.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0120'),
    'AE-016/2012',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2012-08-08',
    '2012-0076897-0',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0121',
    '2013-0023966-9',
    'SIMPROC'::tipo_processo_enum,
    '2013-01-24',
    'DEFERIDO'::status_pa_enum,
    'NEIBENFLUSS EMPREENDIMENTOS LTDA.',
    '09267985/0001-90;',
    'RUA LUIZ CORREA DE MELO; AVENIDA DAS NACOES UNIDAS;',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    13602.18
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0121'),
    'AE-016/2013',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2013-06-03',
    '2013-0023966-9',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-016-2013-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    16216.32,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-016-2013-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2013-0023966-9',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-016-2013-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-016-2013-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    24590.22,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-016-2013-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2013-0023966-9',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-016-2013-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0122',
    '2012-0108.811-5',
    'SIMPROC'::tipo_processo_enum,
    '2012-04-16',
    'DEFERIDO'::status_pa_enum,
    'EVEN SP 55/11 EMPREENDIMENTOS IMOBILIÁRIOS LTDA.',
    '13266969/0001-50;',
    'RUA ARIZONA, 432 A 472',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    2500.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0122'),
    'AE-012/2012',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2012-07-27',
    '2012-0108.811-5',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-012-2012-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    7500.00,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-012-2012-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2012-0108.811-5',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-012-2012-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0123',
    '2011-0055735-5',
    'SIMPROC'::tipo_processo_enum,
    '2011-02-28',
    'DEFERIDO'::status_pa_enum,
    'OXFORD INCORPORACAO SPE LTDA.',
    '10382727/0001-34;',
    'RUA LUIZ SERAPHICO JUNIOR',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    2918.90
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0123'),
    'AE-025/2012',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2012-12-19',
    '2011-0055735-5',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-025-2012-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    7735.00,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-025-2012-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2011-0055735-5',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-025-2012-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0124',
    '2012-0116227-7',
    'SIMPROC'::tipo_processo_enum,
    '2012-05-16',
    'DEFERIDO'::status_pa_enum,
    'JOSE DELLA VOLPE; MARLENE NAVAJAS DELLA VOLPE; JZM PLANEJAMENTO IMOBILIÁRIO E CONSTRUÇÕES LTDA.',
    '52118668/0001-31;',
    'RUA DERVAL, 51, 65; AVENIDA MASCOTE, 1476 À 1534',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    3752.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0124'),
    'AE-026/2012',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2012-09-06',
    '2012-0116227-7',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-026-2012-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    11256.00,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-026-2012-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2012-0116227-7',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-026-2012-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0125',
    '2014-0311923-2',
    'SIMPROC'::tipo_processo_enum,
    '2014-11-05',
    'DEFERIDO'::status_pa_enum,
    'JSL EMPREENDIMENTO IMOBILIARIO SPE LTDA.',
    '11792563/0001-86;',
    'RUA PALESTINA, 290, 296, 300, 310, 318, 326, 330, 346',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    2255.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0125'),
    'AE-022/2014',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2014-11-25',
    '2014-0311923-2',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-022-2014-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    6765.00,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-022-2014-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2014-0311923-2',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-022-2014-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0126',
    '2012-0116229-3',
    'SIMPROC'::tipo_processo_enum,
    '2012-04-23',
    'DEFERIDO'::status_pa_enum,
    'DELLA VOLPE EMPREENDIMENTOS IMOBILIARIOS LTDA.',
    '07314070/0001-63;',
    'RUA LACEDEMONIA, 399, 405; RUA DOUTOR ABELARDO VERGUEIRO CESAR, 371, 381, 385, 393, 403',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    3000.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0126'),
    'AE-027/2012',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2012-09-10',
    '2012-0116229-3',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-027-2012-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    9000.00,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-027-2012-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2012-0116229-3',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-027-2012-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0127',
    '2012-0169411-2',
    'SIMPROC'::tipo_processo_enum,
    '2012-06-14',
    'DEFERIDO'::status_pa_enum,
    'CARVI ASSESSORIA CONSULTORIA E NEGOCIOS LTDA',
    '01906318/0001-07;',
    'RUA AMERICO BARASLIENSE, 1664',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    6794.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0127'),
    'AE-015/2012',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2012-08-06',
    '2012-0169411-2',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-015-2012-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    20382.00,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-015-2012-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2012-0169411-2',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-015-2012-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0128',
    '2012-0166702-6',
    'SIMPROC'::tipo_processo_enum,
    '2012-06-13',
    'DEFERIDO'::status_pa_enum,
    'EVEN SP 63/11 EMPREENDIMENTOS IMOBILIARIOS LTDA.',
    '13598245/0001-04;',
    'RUA CALIFORNIA, 1234 À 1282',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    2260.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0128'),
    'AE-019/2012',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2012-08-17',
    '2012-0166702-6',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-019-2012-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    6780.00,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-019-2012-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2012-0166702-6',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-019-2012-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0129',
    '2012-0175753-0',
    'SIMPROC'::tipo_processo_enum,
    '2012-06-20',
    'DEFERIDO'::status_pa_enum,
    'YUNY STAN PROJETO IMOBILIARIO I SA',
    '11939724/0001-11;',
    'RUA FLORIDA; RUA NOVA IORQUE; RUA MICHIGAN',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    7500.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0129'),
    'AE-024/2012',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2013-10-14',
    '2012-0175753-0',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-024-2012-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    22500.00,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-024-2012-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2012-0175753-0',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-024-2012-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0130',
    '2012-0175760-2',
    'SIMPROC'::tipo_processo_enum,
    '2012-06-20',
    'DEFERIDO'::status_pa_enum,
    'YUNY STAN PROJETO IMOBILIARIO I SA',
    '11939724/0001-11;',
    'RUA FLORIDA; RUA CALIFÓRNIA; RUA MICHIGAN',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    7500.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0130'),
    'AE-020/2012',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2012-08-17',
    '2012-0175760-2',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-020-2012-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    22500.00,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-020-2012-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2012-0175760-2',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-020-2012-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0131',
    '2012-0128546-8',
    'SIMPROC'::tipo_processo_enum,
    '2012-05-07',
    'DEFERIDO'::status_pa_enum,
    'QUEIROZ GALVÃO PAULISTA 12 DESENVOLVIMENTO IMOBILIÁRIO LTDA',
    '13996333/0001-64;',
    'RUA VIAZA, RUA IPIRANGA, RUA VISCONDE DE OUREM',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    4010.99
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0131'),
    'AE-018/2012',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2012-08-15',
    '2012-0128546-8',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-018-2012-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    12032.97,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-018-2012-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2012-0128546-8',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-018-2012-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0132',
    '2012-0161783-5',
    'SIMPROC'::tipo_processo_enum,
    '2012-06-06',
    'DEFERIDO'::status_pa_enum,
    'EVEN SP 48/10 EMPREENDIMENTOS IMOBILIÁRIOS LTDA',
    '12993158/0001-99;',
    'RUA JOAQUIM GUARANI, 452 a 490; RUA ANDREIA PAULINETTI, 463 A 497',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    2336.33
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0132'),
    'AE-032/2012',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2012-10-26',
    '2012-0161783-5',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-032-2012-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    4672.66,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-032-2012-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2012-0161783-5',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-032-2012-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0134',
    '2012-0184709-1',
    'SIMPROC'::tipo_processo_enum,
    '2012-06-28',
    'DEFERIDO'::status_pa_enum,
    'MULTIALLIANCE EMPREENDIMENTOS E PARTICIPAÇÕES IMOBILIÁRIAS LTDA.; EMPAGE CONSTRUÇÕES EMPREENDIMENTOS E PARTICIPAÇÕES IMOBILIÁRIOAS LTDA.; BRAGANÇA EMPREENDIMENTOS IMOBILIÁRIOS S/A.',
    '03561702/0001-32; 47686431/0001-17; 47684774/0001-42',
    'RUA ALFREDO EGÍDIO DE SOUZA ARANHA - LOTES A, B, C E D',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    11411.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0134'),
    'AE-022/2012',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2012-08-23',
    '2012-0184709-1',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-022-2012-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    28233.00,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-022-2012-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2012-0184709-1',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-022-2012-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-022-2012-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    6000.00,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-022-2012-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2012-0184709-1',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-022-2012-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0136',
    '2012-0183266-3',
    'SIMPROC'::tipo_processo_enum,
    '2012-06-27',
    'DEFERIDO'::status_pa_enum,
    'LCJ INCORPORADORA SPE LTDA.',
    '11566398/0001-44;',
    'RUA JACERU, 184, 194 E 226',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    2272.75
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0136'),
    'AE-030/2012',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2012-10-17',
    '2012-0183266-3',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-030-2012-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    6818.25,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-030-2012-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2012-0183266-3',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-030-2012-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0137',
    '2017-0141671-5',
    'SIMPROC'::tipo_processo_enum,
    '2017-09-11',
    'DEFERIDO'::status_pa_enum,
    'EXTO MORUMBI K2 EMPREENDIMENTOS IMOBILIÁRIOS S/A.',
    '19269576/0001-87;',
    'AVENIDA ULYSSES REIS DE MATTOS, 100',
    (SELECT id FROM setor WHERE nome = 'Marginal Pinheiros'),
    'ALTERACAO'::requerimento_enum,
    10993.45
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0137'),
    'AE-008/2017',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2017-10-20',
    '2017-0141671-5',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-008-2017-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Marginal Pinheiros'),
    9615.47,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-008-2017-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2017-0141671-5',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-008-2017-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-008-2017-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Marginal Pinheiros'),
    2278.92,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-008-2017-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2017-0141671-5',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-008-2017-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0138',
    '2012-0157989-5',
    'SIMPROC'::tipo_processo_enum,
    '2012-06-04',
    'DEFERIDO'::status_pa_enum,
    'UNIÃO BRASILEIRA DE REFINADORES LTDA.',
    '02340486/0001-32;',
    'RUA ANTONIO DAS CHAGAS, 1725 E 1733',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    1638.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0138'),
    'AE-028/2012',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2012-09-19',
    '2012-0157989-5',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-028-2012-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    4914.00,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-028-2012-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2012-0157989-5',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-028-2012-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0139',
    '2013-0247053-8',
    'SIMPROC'::tipo_processo_enum,
    '2013-08-28',
    'DEFERIDO'::status_pa_enum,
    'CYRELA MAGIKLZ OITICICA EMPREENDIMENTOS IMOBILIARIOS LTDA',
    '10982471/0001-04;',
    'RUA PROFESSOR JOSE LEITE E OITICICA, 207, 237; RUA BACAETAVA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    2180.73
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0139'),
    'AE-047/2013',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2013-12-12',
    '2013-0247053-8',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-047-2013-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    4361.46,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-047-2013-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2013-0247053-8',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-047-2013-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0140',
    '7810.2023/0000775-4',
    'SEI'::tipo_processo_enum,
    '2023-06-14',
    'DEFERIDO'::status_pa_enum,
    'AK 14 EMPREENDIMENTOS E PARTICIPAÇÕES LTDA',
    '08227075/0001-11;',
    'RUA LAGUNA, 625',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'DESVINCULACAO'::requerimento_enum,
    6406.56
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0140'),
    'DV-002/2023',
    'DESVINCULAÇÃO'::tipo_certidao_enum,
    '2023-10-19',
    '7810.2023/0000775-4',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'DV-002-2023-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    16288.68,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'DISPONIVEL'::estado_titulo_enum,
    '2023-10-19'
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'DV-002-2023-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'DISPONIVEL'::estado_titulo_enum,
    '7810.2023/0000775-4',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'DV-002-2023-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0142',
    '2013-0020169-6',
    'SIMPROC'::tipo_processo_enum,
    '2013-01-22',
    'DEFERIDO'::status_pa_enum,
    'JCR CONSTRUÇÃO CIVIL LTDA',
    '46847075/0001-03;',
    'RUA BRITO PEIXOTO, 544, 550, 554; RUA BARTOLOMEU FEIO, 554, 560; RUA PASCOAL PAIS, 525, 537',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    6221.14
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0142'),
    'AE-009/2014',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2014-03-24',
    '2013-0020169-6',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0142'),
    'AE-030/2013',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2013-10-14',
    '2013-0341463-1',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-030-2013-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    18357.98,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-030-2013-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2013-0341463-1',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-030-2013-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0143',
    NULL,
    NULL::tipo_processo_enum,
    NULL,
    'DEFERIDO'::status_pa_enum,
    'BROOKFIELD SÃO PAULO EMPREENDIMENTOS IMOBILIÁRIOS S/A',
    '58877812/0001-08;',
    'AVENIDA MORUMBI, 7766, 7750; RUA DOUTOR PASCHOAL IMPERATRIZ',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    2793.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0143'),
    'AE-009/2013',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2013-03-08',
    NULL,
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-009-2013-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    7857.26,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-009-2013-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    'IMPORTACAO-XLSX',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-009-2013-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0144',
    '2013-0088166-2',
    'SIMPROC'::tipo_processo_enum,
    '2013-03-28',
    'DEFERIDO'::status_pa_enum,
    'LIMOGES INCORPORADORA LTDA',
    '08204931/0001-13;',
    ' RUA TEBAS, 379 A 417; RUA ÁTICA, 550 A 676',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    3468.44
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0144'),
    'AE-019/2013',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2013-06-20',
    '2013-0088166-2',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-019-2013-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    9012.05,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-019-2013-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2013-0088166-2',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-019-2013-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0145',
    '2014-0318126-4',
    'SIMPROC'::tipo_processo_enum,
    '2014-11-10',
    'DEFERIDO'::status_pa_enum,
    'BROOKFIELD SÃO PAULO EMPREENDIMENTOS IMOBILIÁRIOS; SIGMA MALL PARTICIPAÇÕES S/A; TORRE SIGMA PARTICIPAÇÕES S/A',
    '58877812/0001-08;14143116/0001-94;14149451/0001-08;',
    'AVENIDA DAS NAÇÕES UNIDAS; RUA ACARI; RUA DOUTOR RUBENS GOMES BUENO, 691',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'ALTERACAO'::requerimento_enum,
    25590.21
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0145'),
    'AE-026/2014',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2014-12-04',
    '2014-0318126-4',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-026-2014-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    76770.63,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-026-2014-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2014-0318126-4',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-026-2014-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0146',
    '7810.2020/0000438-5',
    'SEI'::tipo_processo_enum,
    '2020-05-05',
    'DEFERIDO'::status_pa_enum,
    'SIQUEM SPE EMPREENDIMENTOS IMOBILIARIOS S.A.',
    '14119406/0001-00;',
    'RUA GABRIELLE D'' ANUNZIO; RUA PRINCESA ISABEL',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'ALTERACAO'::requerimento_enum,
    3435.43
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0146'),
    'AE-007/2020',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2020-11-13',
    '7810.2020/0000438-5',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-007-2020-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    10306.29,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-007-2020-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '7810.2020/0000438-5',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-007-2020-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0146'),
    'DV-002/2020',
    'DESVINCULAÇÃO'::tipo_certidao_enum,
    '2020-11-13',
    '7810.2020/0000438-5',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0147',
    NULL,
    NULL::tipo_processo_enum,
    NULL,
    'DEFERIDO'::status_pa_enum,
    'SOREAL COMÉRCIO E ADMINISTRAÇÃO LTDA',
    '50251271/0001-98;',
    'AVENIDA ALFREDO EGÍDIO DE SOUZA ARANHA, 360 - LOTE E',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    2445.78
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0147'),
    'AE-004/2013',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2013-02-19',
    NULL,
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-004-2013-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    7337.34,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-004-2013-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    'IMPORTACAO-XLSX',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-004-2013-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0148',
    '2014-0147872-3',
    'SIMPROC'::tipo_processo_enum,
    '2014-05-27',
    'DEFERIDO'::status_pa_enum,
    'BMX REALIZAÇÕES IMOBILIÁRIAS E PARTICIPAÇÕES S/A',
    '11408707/0001-58;',
    'AVENIDA DAS NAÇÕES UNIDAS, S/N.',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'ALTERACAO'::requerimento_enum,
    83671.91
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0148'),
    'AE-023/2014',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2014-11-25',
    '2014-0147872-3',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-023-2014-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    36911.40,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-023-2014-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2014-0147872-3',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-023-2014-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-023-2014-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    214104.33,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-023-2014-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2014-0147872-3',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-023-2014-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0149',
    '2013-0358100-7',
    'SIMPROC'::tipo_processo_enum,
    '2013-12-04',
    'DEFERIDO'::status_pa_enum,
    'TAAUBEN EMPREENDIMENTOS IMOBILIARIOS LTDA',
    '11510133/0001-24;',
    'RUA MINISTRO JOSÉ GALLOTTI, 495; AVENIDA JORNALISTA ROBERTO MARINHO',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'ALTERACAO'::requerimento_enum,
    4567.50
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0149'),
    'AE-004/2014',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2014-03-06',
    '2013-0358100-7',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-004-2014-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    8795.18,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-004-2014-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2013-0358100-7',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-004-2014-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0150',
    NULL,
    NULL::tipo_processo_enum,
    NULL,
    'DEFERIDO'::status_pa_enum,
    'COMERCIAL E EMPREENDIMENTOS BRASIL S/A',
    '60583747/0001-41;',
    'RUA FRANCISCO TRAMONTANO; AVENIDA MAGALHÃES DE CASTRO (AVENIDA MARGINAL DO RIO PINHEIROS)',
    (SELECT id FROM setor WHERE nome = 'Marginal Pinheiros'),
    'VINCULACAO'::requerimento_enum,
    6103.14
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0150'),
    'AE-037/2012',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2012-12-19',
    NULL,
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-037-2012-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Marginal Pinheiros'),
    18309.42,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-037-2012-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    'IMPORTACAO-XLSX',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-037-2012-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0151',
    '2014-0101202-3',
    'SIMPROC'::tipo_processo_enum,
    '2014-04-08',
    'DEFERIDO'::status_pa_enum,
    'ODEBRECHT REALIZAÇÕES SP 32 EMPREENDIMENTO IMOBILIÁRIO LTDA',
    '15251790/0001-55;',
    'RUA GABRIELLE DANUNZIO, 48 A 58; AVENIDA SANTO AMARO, 3999 A 4039',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'ALTERACAO'::requerimento_enum,
    3776.67
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0151'),
    'AE-036/2013',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2014-08-07',
    '2014-0101202-3',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-036-2013-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    10937.24,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-036-2013-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2014-0101202-3',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-036-2013-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0151'),
    'DV-003/2014',
    'DESVINCULAÇÃO'::tipo_certidao_enum,
    '2014-08-07',
    '2014-0101202-3',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'DV-003-2014-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    392.77,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'DISPONIVEL'::estado_titulo_enum,
    '2014-08-07'
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'DV-003-2014-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'DISPONIVEL'::estado_titulo_enum,
    '2014-0101202-3',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'DV-003-2014-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0152',
    '7810.2023/0000582-4',
    'SEI'::tipo_processo_enum,
    '2023-05-02',
    'DEFERIDO'::status_pa_enum,
    'COLMAR INCORPORADORA LTDA',
    '37969004/0001-92;',
    'RUA VERBO DIVINO, 1661; RUA ARQUITETO MARCELO ROBERTO',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'ALTERACAO'::requerimento_enum,
    10289.60
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0152'),
    'AE-011/2023',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2023-08-18',
    '7810.2023/0000582-4',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-011-2023-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    25001.67,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-011-2023-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '7810.2023/0000582-4',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-011-2023-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0153',
    NULL,
    NULL::tipo_processo_enum,
    NULL,
    'DEFERIDO'::status_pa_enum,
    'LUBA 9 EMPREENDIMENTOS IMOBILIÁRIOS LTDA',
    '12145795/0001-05;',
    'RUA ARIZONA, 232A 274',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    2200.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0153'),
    'AE-003/2013',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2013-02-18',
    NULL,
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-003-2013-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    6600.00,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-003-2013-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    'IMPORTACAO-XLSX',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-003-2013-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0154',
    NULL,
    NULL::tipo_processo_enum,
    NULL,
    'DEFERIDO'::status_pa_enum,
    'LUBA 11 EMPREENDIMENTOS LTDA',
    '13794885/0001-90;',
    'RUA FLORIDA, 79, 93, 103',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    2236.80
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0154'),
    'AE-011/2013',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2013-03-14',
    NULL,
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-011-2013-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    6710.40,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-011-2013-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    'IMPORTACAO-XLSX',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-011-2013-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0155',
    '7810.2022/0000086-3',
    'SEI'::tipo_processo_enum,
    '2022-01-14',
    'DEFERIDO'::status_pa_enum,
    'HESA 96 INVESTIMENTOS IMOBILIÁRIOS LTDA',
    '09343543/0001-86;',
    'RUA ENXOVIA, 423, 455',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'DESVINCULACAO'::requerimento_enum,
    12346.81
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0155'),
    'DV-001/2022',
    'DESVINCULAÇÃO'::tipo_certidao_enum,
    '2022-07-27',
    '7810.2022/0000086-3',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0155'),
    'AE-010/2022',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2022-08-15',
    '7810.2022/0000629-2',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-010-2022-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    9738.12,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-010-2022-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '7810.2022/0000629-2',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-010-2022-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-010-2022-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    27302.31,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-010-2022-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '7810.2022/0000629-2',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-010-2022-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0156',
    '2012-0342490-2',
    'SIMPROC'::tipo_processo_enum,
    '2012-12-07',
    'DEFERIDO'::status_pa_enum,
    'SALAS EMPREENDIMENTOS E PARTICIPAÇÕES LTDA',
    '49467186/0001-82;',
    'RUA BACAETAVA, 401',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    1425.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0156'),
    'AE-006/2013',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2013-03-05',
    '2012-0342490-2',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-006-2013-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    4275.00,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-006-2013-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2012-0342490-2',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-006-2013-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0157',
    '2012-0342486-4',
    'SIMPROC'::tipo_processo_enum,
    '2012-12-07',
    'DEFERIDO'::status_pa_enum,
    'ROQUE PETRONI EMPREENDIMENTO IMOBILIÁRIO - SPE LTDA',
    '12434469/0001-18;',
    'RUA ROQUE PETRONI JUNIOR, S/N.º ESQUINA COM RUA JACEU E BACAETAA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    4127.47
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0157'),
    'AE-008/2013',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2013-03-07',
    '2012-0342486-4',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-008-2013-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    12382.41,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-008-2013-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2012-0342486-4',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-008-2013-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0158',
    '2012-0353658-1',
    'SIMPROC'::tipo_processo_enum,
    '2012-12-19',
    'DEFERIDO'::status_pa_enum,
    'ALTA GRACIA EMPREENDIMENTOS IMOBILIÁRIOS LTDA',
    '10212122/0001-03;',
    'RUA HENRI DUNANT, 1066',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    3046.45
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0158'),
    'AE-014/2013',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2013-04-19',
    '2012-0353658-1',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-014-2013-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    9135.39,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-014-2013-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2012-0353658-1',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-014-2013-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0159',
    '2013-0017003-0',
    'SIMPROC'::tipo_processo_enum,
    '2013-01-18',
    'DEFERIDO'::status_pa_enum,
    'GAFISA S/A',
    '01545826/0001-07;',
    'RUA DOUTOR PASCHOAL IMPERATRIZ, 75 A 119',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    3350.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0159'),
    'AE-012/2013',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2013-04-04',
    '2013-0017003-0',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-012-2013-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    10050.00,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-012-2013-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2013-0017003-0',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-012-2013-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0160',
    '2013-0225689-7',
    'SIMPROC'::tipo_processo_enum,
    '2013-08-08',
    'DEFERIDO'::status_pa_enum,
    'CONCIVIL CONSTRUTORA E INCORPORADORA LTDA',
    '72951130/0001-10;',
    'RUA GUARAIUVA, 33 A 67; RUA ARAÇAÍBA, 117 A 173',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    4210.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0160'),
    'AE-034/2013',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2013-11-12',
    '2013-0225689-7',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-034-2013-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    12630.00,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-034-2013-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2013-0225689-7',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-034-2013-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0162',
    '7810.2022/0001645-0',
    'SEI'::tipo_processo_enum,
    '2022-11-12',
    'DEFERIDO'::status_pa_enum,
    'AV ROBERTO MARINHO EMPREENDIMENTO IMOBILIÁRIO SPE LTDA',
    '16746551/0001-39;',
    'RUA ARIZONA, 433 A 491; RUA CALIFÓRNIA, 1335 A 1355',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'ALTERACAO'::requerimento_enum,
    3561.94
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0162'),
    'AE-005/2023',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2023-04-19',
    '7810.2022/0001645-0',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-005-2023-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    9661.86,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-005-2023-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '7810.2022/0001645-0',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-005-2023-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0163',
    '2013-0062363-9',
    'SIMPROC'::tipo_processo_enum,
    '2013-03-04',
    'DEFERIDO'::status_pa_enum,
    'ARIZONA EMPREENDIMENTOS IMOBILIÁRIOS LTDA',
    '12383668/0001-44;',
    'RUA ARIZONA, 672',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    2095.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0163'),
    'AE-021/2013',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2013-08-01',
    '2013-0062363-9',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-021-2013-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    6285.00,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-021-2013-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2013-0062363-9',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-021-2013-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0164',
    '2016-0213017-1',
    'SIMPROC'::tipo_processo_enum,
    '2016-09-20',
    'DEFERIDO'::status_pa_enum,
    'AAMR-09 EMPREENDIMENTO IMOBILIÁRIO LTDA',
    '12086714/0001-43;',
    'RUA PORTO UNIÃO E CASTILHO; AVENIDA JORNALISTA ROBERTO MARINHO',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'ALTERACAO'::requerimento_enum,
    4322.52
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0164'),
    'AE-002/2017',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2017-04-03',
    '2016-0213017-1',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-002-2017-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    8886.05,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-002-2017-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2016-0213017-1',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-002-2017-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0165',
    '7810.2022/0001154-7',
    'SEI'::tipo_processo_enum,
    '2022-08-03',
    'DEFERIDO'::status_pa_enum,
    'AURI 06 PAZ SPE EMPREENDIMENTOS IMOBILIÁRIOS LTDA',
    '11580181/0001-99;',
    'RUA DA PAZ, 1651, 1673, 1683; RUA ANTONIO DE OLIVEIRA, 486 E 530; RUA ANTONIO DAS CHAGAS, 1228, 1234',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'ALTERACAO'::requerimento_enum,
    3277.07
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0165'),
    'AE-015/2022',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2022-10-25',
    '7810.2022/0001154-7',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-015-2022-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    9831.21,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-015-2022-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '7810.2022/0001154-7',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-015-2022-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0166',
    '2013-0122363-4',
    'SIMPROC'::tipo_processo_enum,
    '2013-04-29',
    'DEFERIDO'::status_pa_enum,
    'ALDABRA EMPREENDIMENTOS IMOBILIÁRIOS LTDA',
    '09017257/0001-20;',
    'RUA AMERICO BRASILIENSE, 2210 A 2224; RUA JOSÉ VICENTE CAVALHEIRO, 225 E 239',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    1742.50
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0166'),
    'AE-018/2013',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2013-06-12',
    '2013-0122363-4',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-018-2013-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    5227.50,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-018-2013-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2013-0122363-4',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-018-2013-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0167',
    '2013-0277715-3',
    'SIMPROC'::tipo_processo_enum,
    '2013-09-23',
    'DEFERIDO'::status_pa_enum,
    'OITICICA EMPREENDIMENTOS IMOBILIÁRIOS LTDA',
    '08673118/0001-92;',
    'RUA JACERÚ, 235',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    5079.60
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0167'),
    'AE-001/2014',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2014-06-01',
    '2013-0277715-3',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-001-2014-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    15200.20,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-001-2014-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2013-0277715-3',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-001-2014-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0168',
    '2018-0039804-9',
    'SIMPROC'::tipo_processo_enum,
    '2018-04-17',
    'DEFERIDO'::status_pa_enum,
    'GMR MORUMBI EMPREENDIMENTOS IMOBILIÁRIOS LTDA; JITAÍ EMPREENDIMENTOS E PARTICIPAÇÕES S/A',
    '18943643/0001-34; 67463901/0001-90;',
    'RUA JACERÚ, 247, 339, 345, 349, 355, 413, 419, S/N.º, ESQUINA COM A AVENIDA ROQUE PETRONI; RUA VIEIRA DA SILVA, S/N.º',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'ALTERACAO'::requerimento_enum,
    38900.54
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0168'),
    'AE-002/2018',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2018-07-04',
    '2018-0039804-9',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-002-2018-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    30789.36,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-002-2018-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2018-0039804-9',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-002-2018-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-002-2018-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    23388.14,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-002-2018-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2018-0039804-9',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-002-2018-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0170',
    '7810.2020/0001102-0',
    'SEI'::tipo_processo_enum,
    '2020-09-18',
    'DEFERIDO'::status_pa_enum,
    'GUARÁ INCORPORADORA LTDA',
    '12802327/0001-66;',
    'RUA SANTO ARCÁDIO, 120',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'ALTERACAO'::requerimento_enum,
    5939.13
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0170'),
    'AE-004/2021',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2021-08-13',
    '7810.2020/0001102-0',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-004-2021-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    17817.39,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-004-2021-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '7810.2020/0001102-0',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-004-2021-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0172',
    '2013-0189226-9',
    'SIMPROC'::tipo_processo_enum,
    '2013-07-03',
    'DEFERIDO'::status_pa_enum,
    'HESA 88 INVESTIMENTOS IMOBILIÁRIOS LTDA; KAR EMPREENDIMENTOS IMOBILIÁRIOS LTDA; NK EMPREENDIMENTOS IMOBILIÁRIOS LTDA; LMKF EMPREENDIMENTOS IMOBILIÁRIOS LTDA',
    '12444488/0001-25; 57015166/0001-07; 14763012/0001-82; 14797307/0001-70',
    'RUA BACAETAVA, 191, ESQUINA COM A RUA PROFESSOR JOSÉ LEITE DE OITICICA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    2273.60
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0172'),
    'AE-026/2013',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2013-12-03',
    '2013-0189226-9',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-026-2013-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    6820.80,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-026-2013-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2013-0189226-9',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-026-2013-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0173',
    '7810.2020/0000022-3',
    'SEI'::tipo_processo_enum,
    '2021-04-07',
    'DEFERIDO'::status_pa_enum,
    'HESA 135 - INVESTIMENTOS IMOBILIÁRIOS LTDA',
    '15564234/0001-39;',
    'RUA GODOI COLAÇO, 575, 597 X RUA BARTOLOMEU FEIO, 766, 774, 778, 790, 798',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'ALTERACAO'::requerimento_enum,
    2020.79
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0173'),
    'AE-001/2021',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2021-04-07',
    '7810.2020/0000022-3',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0173'),
    'DV-001/2021',
    'DESVINCULAÇÃO'::tipo_certidao_enum,
    '2021-04-07',
    '7810.2020/0000022-3',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'DV-001-2021-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    6062.37,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'DISPONIVEL'::estado_titulo_enum,
    '2021-04-07'
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'DV-001-2021-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'DISPONIVEL'::estado_titulo_enum,
    '7810.2020/0000022-3',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'DV-001-2021-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0174',
    '2013-0205749-5',
    'SIMPROC'::tipo_processo_enum,
    '2013-07-22',
    'DEFERIDO'::status_pa_enum,
    'QUEIROZ GALVÃO PAULISTA 16 DESENVOLVIMENTO IMOBILIÁRIO LTDA',
    '13996325/0001-18;',
    'RUA DA PAZ;  RUA BRANCO DE MORAIS; RUA  ANTONIO CHAGAS; RUA PAIS DA SILVA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    4238.25
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0174'),
    'AE-038/2013',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2013-11-22',
    '2013-0205749-5',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-038-2013-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    12714.75,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-038-2013-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2013-0205749-5',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-038-2013-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0177',
    '7812.2022/0001627-1',
    'SEI'::tipo_processo_enum,
    '2023-09-19',
    'DEFERIDO'::status_pa_enum,
    'HESA 159 - INVESTIMENTOS IMOBILIARIOS S.A.',
    '17617049/0001-57;',
    'AVENIDA JOAO DIAS, 2426',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'ALTERACAO'::requerimento_enum,
    26090.44
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0177'),
    'AE-010/2023',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2023-09-19',
    '7812.2022/0001627-1',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-010-2023-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    28910.09,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-010-2023-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '7812.2022/0001627-1',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-010-2023-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0178',
    '2013-0301643-1',
    'SIMPROC'::tipo_processo_enum,
    '2013-10-09',
    'DEFERIDO'::status_pa_enum,
    'TDSP VOLTA REDONDA EMPREENDIMENTOS IMOBILIÁRIOS SPE LTDA',
    '13494803/0001-91;',
    'RUA REPÚBLICA DO IRAQUE, 855',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    2906.73
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0178'),
    'AE-043/2013',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2013-12-02',
    '2013-0301643-1',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-043-2013-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    8712.67,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-043-2013-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2013-0301643-1',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-043-2013-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0179',
    '2014-0260293-2',
    'SIMPROC'::tipo_processo_enum,
    '2015-05-25',
    'DEFERIDO'::status_pa_enum,
    'PONSWINNECKE EMPREENDIMENTOS E PARTICIPAÇÕES LTDA;  AUTONOMY INVESTIMENTOS LTDA; VARICRED EMPREENDIMENTOS E PARTICIPAÇÕES',
    '09395277/0001-35;07689403/0001-39; 4339034/0001-87;',
    'AVENIDA NAÇOES UNIDAS, 15187 X RUA ALEXANDRE DUMAS, 2200',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'ALTERACAO'::requerimento_enum,
    13819.80
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0179'),
    'AE-006/2015',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2015-05-25',
    '2014-0260293-2',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-006-2015-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    27456.82,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-006-2015-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2014-0260293-2',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-006-2015-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0180',
    '2015-0159364-8',
    'SIMPROC'::tipo_processo_enum,
    '2015-06-18',
    'DEFERIDO'::status_pa_enum,
    'IMOPAR PARTICIPAÇÕES E ADMINISTRAÇÃO IMOBILIÁRIA LTDA.;',
    '56338759/0001-33;',
    'AVENIDA NAÇOES UNIDAS, 15.101',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'ALTERACAO'::requerimento_enum,
    59445.94
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0180'),
    'AE-001/2016',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2016-01-18',
    '2015-0159364-8',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-001-2016-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    62683.50,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-001-2016-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2015-0159364-8',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-001-2016-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0181',
    '7810.2019/0000882-6',
    'SEI'::tipo_processo_enum,
    '2019-09-23',
    'DEFERIDO'::status_pa_enum,
    'PLANO CAMBARÁ EMP REEN DIMEN TOS IMOBILIÁRIOS LTDA',
    '09109872/0001-67;',
    'RUA LAGUNA, 214',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'DESVINCULACAO'::requerimento_enum,
    6300.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0181'),
    'DV-001/2020',
    'DESVINCULAÇÃO'::tipo_certidao_enum,
    '2020-07-07',
    '7810.2019/0000882-6',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'DV-001-2020-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    18900.00,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'DISPONIVEL'::estado_titulo_enum,
    '2020-07-07'
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'DV-001-2020-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'DISPONIVEL'::estado_titulo_enum,
    '7810.2019/0000882-6',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'DV-001-2020-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0182',
    '7810.2021/0001620-2',
    'SEI'::tipo_processo_enum,
    '2021-08-11',
    'DEFERIDO'::status_pa_enum,
    'BW2 RPJ EMPREENDIMENTO IMOBILIÁRIO LTDA.',
    '12423850/0001-81;',
    'RUA SANTO ARCÁDIO, 290',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'ALTERACAO'::requerimento_enum,
    15006.71
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0182'),
    'AE-004/2022',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2022-02-11',
    '7810.2021/0001620-2',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-004-2022-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    42593.05,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-004-2022-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '7810.2021/0001620-2',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-004-2022-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-004-2022-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    2427.08,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-004-2022-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '7810.2021/0001620-2',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-004-2022-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0182'),
    'AE-011/2022',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2022-09-09',
    '7810.2021/0001619-9',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-011-2022-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    8290.77,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-011-2022-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '7810.2021/0001619-9',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-011-2022-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0182'),
    'AE-015/2023',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2023-12-01',
    '7810.2023/0001037-2',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-015-2023-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    9905.91,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-015-2023-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '7810.2023/0001037-2',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-015-2023-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0182'),
    'AE-016/2023',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2023-12-21',
    '7810.2023/0001041-0',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-016-2023-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    11913.51,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-016-2023-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '7810.2023/0001041-0',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-016-2023-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0182'),
    'DV-001/2019',
    'DESVINCULAÇÃO'::tipo_certidao_enum,
    '2019-08-30',
    '7810.2019/0000493-6',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'DV-001-2019-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    27933.26,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'DISPONIVEL'::estado_titulo_enum,
    '2019-08-30'
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'DV-001-2019-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'DISPONIVEL'::estado_titulo_enum,
    '7810.2019/0000493-6',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'DV-001-2019-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0183',
    '7810.2023/0001000-3',
    'SEI'::tipo_processo_enum,
    '2023-07-28',
    'DEFERIDO'::status_pa_enum,
    'JHSF INCORPORAÇÕES LTDA.',
    '05345215/0001-68;',
    'RUA PROFESSOR DOUTOR ANTÔNIO BARROS DE ULHOA CINTRA, LOTES 1 A 8',
    (SELECT id FROM setor WHERE nome = 'Marginal Pinheiros'),
    'ALTERACAO'::requerimento_enum,
    6095.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0183'),
    'AE-001/2024',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2024-05-09',
    '7810.2023/0001000-3',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-001-2024-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Marginal Pinheiros'),
    11863.63,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-001-2024-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '7810.2023/0001000-3',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-001-2024-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0183'),
    'DV-001/2024',
    'DESVINCULAÇÃO'::tipo_certidao_enum,
    '2024-05-09',
    '7810.2023/0001000-3',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'DV-001-2024-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Marginal Pinheiros'),
    2183.52,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'DISPONIVEL'::estado_titulo_enum,
    '2024-05-09'
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'DV-001-2024-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'DISPONIVEL'::estado_titulo_enum,
    '7810.2023/0001000-3',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'DV-001-2024-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0183'),
    'DV-001/2023',
    'DESVINCULAÇÃO'::tipo_certidao_enum,
    '2023-06-30',
    '7810.2022/0001104-0',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'DV-001-2023-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Marginal Pinheiros'),
    4238.75,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'DISPONIVEL'::estado_titulo_enum,
    '2023-06-30'
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'DV-001-2023-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'DISPONIVEL'::estado_titulo_enum,
    '7810.2022/0001104-0',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'DV-001-2023-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0187',
    '2015-0100494-4',
    'SIMPROC'::tipo_processo_enum,
    '2015-04-17',
    'DEFERIDO'::status_pa_enum,
    'AVEIRO INCORPORAÇÕES S/A.;',
    '08274761/0001-43;',
    'AVENIDA ALCIDES SANGIRARDI S/N;',
    (SELECT id FROM setor WHERE nome = 'Marginal Pinheiros'),
    'ALTERACAO'::requerimento_enum,
    20256.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0187'),
    'AE-011/2015',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2015-07-22',
    '2015-0100494-4',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-011-2015-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Marginal Pinheiros'),
    46064.70,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-011-2015-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2015-0100494-4',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-011-2015-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0188',
    '2014-0312450-3',
    'SIMPROC'::tipo_processo_enum,
    '2014-11-05',
    'DEFERIDO'::status_pa_enum,
    'MIGUEL SUTIL IMOVEIS SPE LTDA;',
    '11006714/0001-23;',
    'RUA MIGUEL SUTIL; RUA FRANCISCO DIAS VELHO; AVENIDA JORNALISTA ROBERTO MARINHO; ',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    'VINCULACAO'::requerimento_enum,
    2214.68
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0188'),
    'AE-002/2015',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2015-03-18',
    '2014-0312450-3',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0189',
    '2013-0310774-7',
    'SIMPROC'::tipo_processo_enum,
    '2013-10-17',
    'DEFERIDO'::status_pa_enum,
    'HESA 146 INVESTIMENTOS IMOBILIARIOS LTDA.',
    '15650345/0001-68;',
    'RUA CARMO DO RIO VERDE, 109',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    3550.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0189'),
    'AE-003/2015',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2015-03-19',
    '2013-0310774-7',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-003-2015-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    10482.80,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-003-2015-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '2013-0310774-7',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-003-2015-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0195',
    '7810.2018/0000844-1',
    'SEI'::tipo_processo_enum,
    '2018-10-25',
    'DEFERIDO'::status_pa_enum,
    'BR PROPERTIES S/A;',
    '06977751/0001-49;',
    'AVENIDA DAS NACOES UNIDAS, 12495',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    'VINCULACAO'::requerimento_enum,
    13682.50
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0195'),
    'AE-002/2019',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2019-04-30',
    '7810.2018/0000844-1',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-002-2019-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    763.60,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-002-2019-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '7810.2018/0000844-1',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-002-2019-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0196',
    '7810.2022/0001129-6',
    'SEI'::tipo_processo_enum,
    '2022-07-28',
    'DEFERIDO'::status_pa_enum,
    'ROMANO S/A MATERIAIS PARA CONSTRUÇÕES',
    '61300042/0001-32;',
    'AVENIDA DOUTOR CHUCRI ZAIDAN, 230',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    'VINCULACAO'::requerimento_enum,
    12938.06
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0196'),
    'AE-014/2023',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2023-10-27',
    '7810.2022/0001129-6',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-014-2023-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    6000.00,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-014-2023-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '7810.2022/0001129-6',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-014-2023-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-014-2023-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    19463.77,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-014-2023-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '7810.2022/0001129-6',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-014-2023-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0197',
    '7810.2019/0001055-3',
    'SEI'::tipo_processo_enum,
    '2019-11-11',
    'DEFERIDO'::status_pa_enum,
    'CAOA PATRIMONIAL LTDA',
    '02173595/0001-02;',
    'AVENIDA MORUMBI, 7554 e 7500',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    10153.61
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0197'),
    'AE-002/2020',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2020-04-29',
    '7810.2019/0001055-3',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-002-2020-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    10448.06,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-002-2020-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '7810.2019/0001055-3',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-002-2020-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0198',
    '7810.2020/0000300-1',
    'SEI'::tipo_processo_enum,
    '2020-03-20',
    'DEFERIDO'::status_pa_enum,
    'DRV H ADMINISTRACAO DE BENS IMOVEIS LTDA',
    '23379890/0001-90;',
    'Rua Engenheiro Mesquita Sampaio, 513 e 523',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'VINCULACAO'::requerimento_enum,
    1677.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0198'),
    'AE-006/2020',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2020-07-15',
    '7810.2020/0000300-1',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-006-2020-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    5031.00,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-006-2020-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '7810.2020/0000300-1',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-006-2020-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0201',
    '7810.2023/0000622-7',
    'SEI'::tipo_processo_enum,
    '2023-05-09',
    'DEFERIDO'::status_pa_enum,
    'COMPANHIA ZAFFARI COMÉRCIO E INDUSTRIA',
    '93015006/0001-13;',
    'AVENIDA CHUCRI ZAIDAN. S/Nº',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    'ALTERACAO'::requerimento_enum,
    18291.32
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0201'),
    'AE-008/2023',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2023-07-12',
    '7810.2023/0000622-7',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-008-2023-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    37639.88,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-008-2023-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '7810.2023/0000622-7',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-008-2023-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0202',
    '7810.2022/0001145-8',
    'SEI'::tipo_processo_enum,
    '2022-08-02',
    'DEFERIDO'::status_pa_enum,
    'COMPANHIA ZAFFARI COMÉRCIO E INDUSTRIA',
    '93015006/0001-13;',
    'AVENIDA CHUCRI ZAIDAN. S/Nº',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    'VINCULACAO'::requerimento_enum,
    4675.81
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0202'),
    'AE-012/2022',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2020-09-23',
    '7810.2022/0001145-8',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-012-2022-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Berrini'),
    9384.35,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-012-2022-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '7810.2022/0001145-8',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-012-2022-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0207',
    '7810.2022/0001379-5',
    'SEI'::tipo_processo_enum,
    '2022-09-19',
    'DEFERIDO'::status_pa_enum,
    'ANA MARIA BASTOS LIVRERI; HELIO LÚCIO LIVRERI; PEDRO LUIZ LIVRERI',
    '814359168-91; 662285908-63; 272763928-72',
    'RUA PORTO UNIÃO S/Nº - PARTE DO LOTE 11 E 12; AVENIDA JORNALISTA ROBERTO MARINHO S/Nº, PARTES DO LOTE 11 E 12',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    612.19
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0207'),
    'AE-016/2022',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2022-12-26',
    '7810.2022/0001379-5',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0208',
    '7810.2022/0001353-1',
    'SEI'::tipo_processo_enum,
    '2022-09-12',
    'DEFERIDO'::status_pa_enum,
    'FRANCESCO RENATO CAMILLI; DORA RAMONASS CAMILLI',
    '029295388-72; 307.504.968-94',
    'RUA EDSON Nº 578',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    625.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0208'),
    'AE-001/2023',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2023-02-06',
    '7810.2022/0001353-1',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0209',
    '7810.2023/0000120-9',
    'SEI'::tipo_processo_enum,
    '2023-01-30',
    'DEFERIDO'::status_pa_enum,
    'MSB MADRID EMPREENDIMENTOS IMOBILIÁRIOS LTDA',
    '17773660/0001-03;',
    'RUA EDSON, 1400',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    2000.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0209'),
    'AE-007/2023',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2023-06-30',
    '7810.2023/0000120-9',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-007-2023-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    5998.40,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-007-2023-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '7810.2023/0000120-9',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-007-2023-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0210',
    '7810.2023/0000760-6',
    'SEI'::tipo_processo_enum,
    '2023-06-13',
    'DEFERIDO'::status_pa_enum,
    'ILKA BRIGITTE RAUERT CELEGHIN; NIELSV ICTOR RAUERT CELEGHIN',
    '060817368-14; 033810498-44',
    'RUA CONSTANTINO DE SOUZA, 1258',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    265.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0210'),
    'AE-012/2023',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2023-09-18',
    '7810.2023/0000760-6',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0212',
    '7810.2024/0000850-7',
    'SEI'::tipo_processo_enum,
    '2024-05-17',
    'DEFERIDO'::status_pa_enum,
    'POLINCORP INCORPORACOES E PARTICIPACOES IMOBILIARIAS LTDA',
    '02867900/0001-66;',
    'RUA GIL EANES, 48',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    1000.00
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0212'),
    'AE-003/2024',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2024-07-09',
    '7810.2024/0000850-7',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-003-2024-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    3000.00,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-003-2024-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '7810.2024/0000850-7',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-003-2024-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0211',
    '7810.2024/0000033-6',
    'SEI'::tipo_processo_enum,
    '2024-05-13',
    'DEFERIDO'::status_pa_enum,
    'CBR 037 EMPREENDIMENTOS IMOBILIARIOS LTDA',
    '18983186/0001-01;',
    'RUA GABRIELE D''ANNUZIO, 1053, 1067, 1077, 1077, 1087, 1035, 1045',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    2915.93
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0211'),
    'AE-004/2024',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2024-08-13',
    '7810.2024/0000033-6',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-004-2024-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    8747.79,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-004-2024-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '7810.2024/0000033-6',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-004-2024-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0182'),
    'DV-002/2024',
    'DESVINCULAÇÃO'::tipo_certidao_enum,
    '2024-11-14',
    '7810.2024/0001139-7',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'DV-002-2024-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    10745.76,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'DISPONIVEL'::estado_titulo_enum,
    '2024-11-14'
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'DV-002-2024-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'DISPONIVEL'::estado_titulo_enum,
    '7810.2024/0001139-7',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'DV-002-2024-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'DV-002-2024-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    11407.84,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'DISPONIVEL'::estado_titulo_enum,
    '2024-11-14'
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'DV-002-2024-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'DISPONIVEL'::estado_titulo_enum,
    '7810.2024/0001139-7',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'DV-002-2024-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0176',
    '7810.2024/0001231-8',
    'SEI'::tipo_processo_enum,
    NULL,
    'DEFERIDO'::status_pa_enum,
    'BNC MADRI DESENVOLVIMENTO IMOBILIARIO SPE LTDA',
    '17871680/0001-23;',
    'AVENIDA SANTO AMARO, 3291; RUA GABRILLE D''ANNUNZIO, 47, 55, 61',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'DESVINCULACAO'::requerimento_enum,
    2913.50
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0176'),
    'DV-003/2024',
    'DESVINCULAÇÃO'::tipo_certidao_enum,
    '2025-02-07',
    '7810.2024/0001231-8',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'DV-003-2024-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    110.10,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'DISPONIVEL'::estado_titulo_enum,
    '2025-02-07'
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'DV-003-2024-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'DISPONIVEL'::estado_titulo_enum,
    '7810.2024/0001231-8',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'DV-003-2024-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'DV-003-2024-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    8616.00,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'DISPONIVEL'::estado_titulo_enum,
    '2025-02-07'
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'DV-003-2024-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'DISPONIVEL'::estado_titulo_enum,
    '7810.2024/0001231-8',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'DV-003-2024-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0208'),
    'AE-008/2025',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2025-12-08',
    '7810.2025/0000238-1',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-008-2025-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    11848.21,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-008-2025-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '7810.2025/0000238-1',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-008-2025-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0199',
    '7810.2025/0000511-9',
    'SEI'::tipo_processo_enum,
    '2025-04-07',
    'DEFERIDO'::status_pa_enum,
    'PORTLAND INCORPORADORA LTDA',
    '38026360/0001-35;',
    'AVENIDA ROQUE PETRONI JUNIOR, 837',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'ALTERACAO'::requerimento_enum,
    7772.11
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0199'),
    'AE-004/2026',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2026-02-20',
    '7810.2025/0000511-9',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-004-2026-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    26327.24,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-004-2026-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '7810.2025/0000511-9',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-004-2026-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-0187-S002-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Marginal Pinheiros'),
    59398.03,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'EM_ANALISE'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-0187-S002-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'EM_ANALISE'::estado_titulo_enum,
    '7810.2025/0000284-5',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-0187-S002-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-0187-S003-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Marginal Pinheiros'),
    11173.06,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'EM_ANALISE'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-0187-S003-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'EM_ANALISE'::estado_titulo_enum,
    '7810.2025/0000284-5',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-0187-S003-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0046'),
    'AE-004/2025',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2025-05-20',
    '7810.2025/0000346-9',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-004-2025-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    8249.61,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-004-2025-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '7810.2025/0000346-9',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-004-2025-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0169'),
    'DV-001/2025',
    'DESVINCULAÇÃO'::tipo_certidao_enum,
    '2025-05-19',
    '7810.2024/0001381-0',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'DV-001-2025-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    11988.17,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'DISPONIVEL'::estado_titulo_enum,
    '2025-05-19'
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'DV-001-2025-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'DISPONIVEL'::estado_titulo_enum,
    '7810.2024/0001381-0',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'DV-001-2025-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0213',
    '7810.2025/0000079-6',
    'SEI'::tipo_processo_enum,
    '2025-01-16',
    'DEFERIDO'::status_pa_enum,
    'ANAROB CONSULTORIA IMOBILIÁRIA LTDA',
    '01691722/0001-00;',
    'RUA GABRIELE D''ANNUNZIO, 732',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'VINCULACAO'::requerimento_enum,
    338.49
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0213'),
    'AE-005/2025',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2025-05-20',
    '7810.2025/0000079-6',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0169'),
    'DV-002/2025',
    'DESVINCULAÇÃO'::tipo_certidao_enum,
    '2025-10-24',
    '7810.2025/0000970-0',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'DV-002-2025-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    5010.86,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'QUARENTENA'::estado_titulo_enum,
    '2025-10-24'
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'DV-002-2025-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'QUARENTENA'::estado_titulo_enum,
    '7810.2025/0000970-0',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'DV-002-2025-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0190',
    '7810.2025/0001465-7',
    'SEI'::tipo_processo_enum,
    '2025-11-07',
    'DEFERIDO'::status_pa_enum,
    'MULTIPLAN EMPREENDIMENTOS IMOBILIARIOS S/A;',
    '07816890/0001-53;',
    'AVENIDA ROQUE PETRONI JUNIOR, 1089',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    'ALTERACAO'::requerimento_enum,
    56474.86
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0190'),
    'AE-009/2025',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2025-12-22',
    '7810.2025/0001465-7',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-009-2025-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    9788.50,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-009-2025-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '7810.2025/0001465-7',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-009-2025-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0184'),
    'AE-006/2026',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2026-02-24',
    '7810.2025/0001515-7',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-006-2026-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    53380.50,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-006-2026-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '7810.2025/0001515-7',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-006-2026-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0215',
    '7810.2025/0001505-0',
    'SEI'::tipo_processo_enum,
    '2025-11-18',
    'DEFERIDO'::status_pa_enum,
    'NOVA BRISTOL EMPREENDIMENTOS IMOBILIARIOS LTDA',
    '41098261/0001-73;',
    'RUA VOLTA REDONDA, 379 A 477 X RUA ZACARIAS DE GOIS 815 A 841',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'ALTERACAO'::requerimento_enum,
    3085.54
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0215'),
    'AE-002/2026',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2026-01-19',
    '7810.2025/0001505-0',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-002-2026-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    10242.42,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-002-2026-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '7810.2025/0001505-0',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-002-2026-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0200'),
    'AE-003/2026',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2026-02-03',
    '7810.2025/0001500-9',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-003-2026-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    18911.83,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-003-2026-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '7810.2025/0001500-9',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-003-2026-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0169'),
    'AE-007/2026',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2026-03-04',
    '7810.2025/0001463-0',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-007-2026-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    58350.43,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-007-2026-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '7810.2025/0001463-0',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-007-2026-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0001',
    '7810.2026/0000143-3',
    'SEI'::tipo_processo_enum,
    '2026-01-28',
    'DEFERIDO'::status_pa_enum,
    'JHSF MALLS S.A.',
    '07859510/0001-68;',
    'AVENIDA MAGALHÃES DE CASTRO, 12.000',
    (SELECT id FROM setor WHERE nome = 'Marginal Pinheiros'),
    'ALTERACAO'::requerimento_enum,
    49777.94
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0001'),
    'AE-005/2026',
    'ALTERAÇÃO'::tipo_certidao_enum,
    NULL,
    '7810.2026/0000143-3',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-005-2026-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Marginal Pinheiros'),
    77839.32,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-005-2026-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '7810.2026/0000143-3',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-005-2026-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-005-2026-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Marginal Pinheiros'),
    50837.73,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-005-2026-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '7810.2026/0000143-3',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-005-2026-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0204',
    '7810.2026/0000237-5',
    'SEI'::tipo_processo_enum,
    '2026-02-18',
    'DEFERIDO'::status_pa_enum,
    'NOVA VERSALHES EMPREENDIMENTOS IMOBILIARIOS LTDA',
    '35952698/0001-20;',
    'RUA MICHIGAN 561, 567, 569, 575, 585 E 605',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    'ALTERACAO'::requerimento_enum,
    2848.58
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0204'),
    'AE-011/2026',
    'ALTERAÇÃO'::tipo_certidao_enum,
    NULL,
    '7810.2026/0000237-5',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-011-2026-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    8545.46,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-011-2026-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '7810.2026/0000237-5',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-011-2026-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0133',
    '7810.2026/0000141-7',
    'SEI'::tipo_processo_enum,
    '2026-01-27',
    'DEFERIDO'::status_pa_enum,
    'GOLF VILLAGE EMPREENDIMENTOS IMOBILIÁRIOS S.A',
    '05730704/0001-33;',
    'AVENIDA MAJOR SYLVIO DE MAGALHÃES PADILHA, KM 14',
    (SELECT id FROM setor WHERE nome = 'Marginal Pinheiros'),
    'ALTERACAO'::requerimento_enum,
    35916.78
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0133'),
    'AE-009/2026',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2026-04-07',
    '7810.2026/0000141-7',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-009-2026-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Marginal Pinheiros'),
    21632.68,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-009-2026-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '7810.2026/0000141-7',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-009-2026-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-009-2026-NR-ACA',
    (SELECT id FROM setor WHERE nome = 'Marginal Pinheiros'),
    64548.96,
    'NR'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-009-2026-NR-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '7810.2026/0000141-7',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-009-2026-NR-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0133'),
    'DV-003/2026',
    'DESVINCULAÇÃO'::tipo_certidao_enum,
    '2026-04-07',
    '7810.2026/0000141-7',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0206',
    '7810.2026/0000251-0',
    'SEI'::tipo_processo_enum,
    '2026-02-20',
    'DEFERIDO'::status_pa_enum,
    'REAL PARQUE 01 INVESTIMENTOS IMOBILIARIOS SPE LTDA',
    '37685080/0001-76;',
    'RUA DUQUESA DE GOIS, 523; AVENIDA ULYSSES REAIS DE MATOS',
    (SELECT id FROM setor WHERE nome = 'Marginal Pinheiros'),
    'ALTERACAO'::requerimento_enum,
    10580.14
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0206'),
    'AE-010/2026',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2026-03-11',
    '7810.2026/0000251-0',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-010-2026-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Marginal Pinheiros'),
    31501.31,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-010-2026-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '7810.2026/0000251-0',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-010-2026-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO proposta (codigo, numero_pa, tipo_processo, data_autuacao, status_pa, interessado, cnpj_cpf, endereco, setor_id, requerimento, area_terreno_m2)
SELECT
    'AE-0216',
    '7810.2026/0000403-3',
    'SEI'::tipo_processo_enum,
    '2026-03-26',
    'ANALISE'::status_pa_enum,
    'JARDIM DA PACOBA EMPREENDIMENTOS E PARTICIPACOES LTDA.',
    '61893974/0001-36;',
    'RUA ARMANDO PETRELLA, 456',
    (SELECT id FROM setor WHERE nome = 'Marginal Pinheiros'),
    'VINCULACAO'::requerimento_enum,
    2243.95
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-0149-S002-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Brooklin'),
    8795.18,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'EM_ANALISE'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-0149-S002-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'EM_ANALISE'::estado_titulo_enum,
    '7810.2026/0000427-0',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-0149-S002-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-0199-S002-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    14006.35,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'EM_ANALISE'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-0199-S002-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'EM_ANALISE'::estado_titulo_enum,
    '7810.2026/0000153-0',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-0199-S002-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0199'),
    'AE-001/2025',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2025-02-12',
    '7810.2024/0001014-5',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO titulo_cepac (codigo, setor_id, valor_m2, uso, origem, estado, data_desvinculacao)
SELECT
    'AE-001-2025-R-ACA',
    (SELECT id FROM setor WHERE nome = 'Chucri Zaidan'),
    12549.47,
    'R'::uso_enum,
    'ACA'::origem_enum,
    'CONSUMIDO'::estado_titulo_enum,
    NULL
WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = 'AE-001-2025-R-ACA');

INSERT INTO movimentacao (titulo_id, setor_id, uso, origem, estado_anterior, estado_novo, numero_processo_sei, motivo, operador)
SELECT
    t.id, t.setor_id, t.uso, t.origem,
    NULL,
    'CONSUMIDO'::estado_titulo_enum,
    '7810.2024/0001014-5',
    'IMPORTACAO_XLSX',
    'SISTEMA'
FROM titulo_cepac t
WHERE t.codigo = 'AE-001-2025-R-ACA'
  AND NOT EXISTS (
      SELECT 1 FROM movimentacao m
      WHERE m.titulo_id = t.id AND m.motivo = 'IMPORTACAO_XLSX'
  );

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0046'),
    'AE-002/2024',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2024-06-05',
    NULL,
    'CANCELADA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0200'),
    'AE-002/2025',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2025-02-27',
    '7810.2024/0000902-3',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0206'),
    'AE-005/2024',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2025-10-30',
    NULL,
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0169'),
    'AE-003/2025',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2025-05-19',
    '7810.2024/0001381-0',
    'CANCELADA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0215'),
    'AE-006/2025',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2025-08-19',
    '7810.2025/0000953-0',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0169'),
    'AE-007/2025',
    'VINCULAÇÃO'::tipo_certidao_enum,
    '2025-10-24',
    '7810.2025/0000970-0',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0133'),
    'AE-001/2026',
    'ALTERAÇÃO'::tipo_certidao_enum,
    '2026-01-13',
    '7810.2025/0001487-8',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;

INSERT INTO certidao (proposta_id, numero_certidao, tipo, data_emissao, numero_processo_sei, situacao)
SELECT
    (SELECT id FROM proposta WHERE codigo = 'AE-0199'),
    'AE-008/2026',
    'ALTERAÇÃO'::tipo_certidao_enum,
    NULL,
    '7810.2026/0000158-1',
    'VALIDA'::situacao_certidao_enum
ON CONFLICT (numero_certidao) DO NOTHING;
COMMIT;
