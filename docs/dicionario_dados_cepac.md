# Dicionário de Dados — Projeto CEPAC (SP Urbanismo)
> PostgreSQL 15 · Gerado a partir das migrations 001–020

---

## Visão Geral

O banco possui **13 tabelas** organizadas em duas fases de desenvolvimento:

| # | Tabela | Fase | Finalidade |
|---|--------|------|------------|
| 1 | `operacao_urbana` | 1 | Catálogo de Operações Urbanas Consorciadas |
| 2 | `setor` | 1 | Setores de cada OUC (com hierarquia de subsetores) |
| 3 | `titulo_cepac` | 1 | Títulos CEPAC individuais |
| 4 | `solicitacao_vinculacao` | 1 | Pedidos de vinculação de CEPACs |
| 5 | `solicitacao_titulos` | 1 | Junção N:N solicitação ↔ título |
| 6 | `movimentacao` | 1 | Log de auditoria (append-only) |
| 7 | `proposta` | 2 | Projetos/empreendimentos |
| 8 | `certidao` | 2 | Certidões emitidas |
| 9 | `usuario` | 2 | Usuários Azure AD |
| 10 | `documento_processo` | 2 | Metadados de docs no Blob Storage |
| 11 | `medicao_obra` | 2 | Série histórica de medições |
| 12 | `parametro_sistema` | 2 | Parâmetros configuráveis |
| 13 | `configuracao_operacao` | 2 | Singleton com parâmetros globais |

**Dados de referência carregados:**

| OUC | `operacao_urbana_id` | Setores |
|-----|----------------------|---------|
| Água Espraiada (AE) | 1 | Jabaquara, Brooklin, Berrini, Marginal Pinheiros, Chucri Zaidan |
| Faria Lima (FL) | 2 | Hélio Pelegrino, Faria Lima, Pinheiros, Olimpíadas |
| Água Branca (AB) | 3 | Setor A (pai), A3, Setor B, C, E (pai), E1, E2, F (pai), F1, F2, G, H, I1 |

---

## Tipos ENUM

| Tipo | Valores |
|------|---------|
| `uso_enum` | `R`, `NR`, `MISTO` |
| `origem_enum` | `ACA`, `NUVEM` |
| `estado_titulo_enum` | `DISPONIVEL`, `EM_ANALISE`, `CONSUMIDO`, `QUARENTENA` |
| `status_solicitacao_enum` | `PENDENTE`, `APROVADA`, `REJEITADA`, `CANCELADA`, `EM_ANALISE` |
| `status_pa_enum` | `DEFERIDO`, `INDEFERIDO`, `ANALISE` |
| `requerimento_enum` | `VINCULACAO`, `ALTERACAO`, `DESVINCULACAO` |
| `tipo_certidao_enum` | `VINCULAÇÃO`, `DESVINCULAÇÃO`, `ALTERAÇÃO` |
| `situacao_certidao_enum` | `VALIDA`, `CANCELADA`, `ANALISE` |
| `papel_usuario_enum` | `TECNICO`, `DIRETOR` |
| `tipo_processo_enum` | `SIMPROC`, `SEI` |

---

## Tabela 1 — `operacao_urbana`

> Catálogo de Operações Urbanas Consorciadas (OUC) de São Paulo. Tabela de referência — seus parâmetros globais definem os limites de estoque de cada operação.

| Coluna | Tipo | Nulo | Default | Descrição |
|--------|------|------|---------|-----------|
| `id` | SERIAL | NÃO | autoincrement | Chave primária |
| `nome` | VARCHAR(100) | NÃO | — | Nome completo da OUC |
| `sigla` | VARCHAR(5) | NÃO | — | Sigla única (AE, FL, AB) |
| `lei_vigente` | VARCHAR(100) | SIM | NULL | Lei municipal vigente |
| `estoque_maximo_global_r` | NUMERIC(15,2) | SIM | NULL | Estoque máximo global de uso R em m² |
| `estoque_maximo_global_nr` | NUMERIC(15,2) | SIM | NULL | Estoque máximo global de uso NR em m² |
| `possui_nuvem` | BOOLEAN | NÃO | FALSE | Indica se a OUC opera com CEPACs NUVEM |
| `valor_cepac_ref` | NUMERIC(15,2) | SIM | NULL | Preço de referência do CEPAC (último leilão) |
| `data_ultima_posicao` | DATE | SIM | NULL | Data de referência da última posição de estoque |
| `ativo` | BOOLEAN | NÃO | TRUE | Se a OUC está operacional |

**Constraints:** `pk_operacao_urbana` (PK), `uq_operacao_urbana_sigla` (UNIQUE sigla).

**Dados atuais:**

| sigla | nome | possui_nuvem |
|-------|------|-------------|
| AE | Operação Urbana Consorciada Água Espraiada | TRUE |
| FL | Operação Urbana Consorciada Faria Lima | TRUE |
| AB | Operação Urbana Consorciada Água Branca | FALSE |

---

## Tabela 2 — `setor`

> Setores de cada Operação Urbana Consorciada. Armazena apenas parâmetros estruturais — saldo de CEPACs é sempre calculado via `movimentacao`, nunca armazenado aqui. Suporta hierarquia de subsetores via auto-referência.

| Coluna | Tipo | Nulo | Default | Descrição |
|--------|------|------|---------|-----------|
| `id` | UUID | NÃO | gen_random_uuid() | Chave primária |
| `nome` | VARCHAR(100) | NÃO | — | Nome do setor (único globalmente) |
| `estoque_total_m2` | NUMERIC(15,2) | NÃO | — | Estoque total em m² |
| `teto_nr_m2` | NUMERIC(15,2) | NÃO | — | Teto máximo de área NR em m² |
| `teto_r_m2` | NUMERIC(15,2) | SIM | NULL | Teto máximo de área R em m² |
| `reserva_r_m2` | NUMERIC(15,2) | SIM | NULL | Reserva residencial (só Chucri Zaidan: 216.442,47 m²) |
| `piso_r_percentual` | NUMERIC(5,2) | SIM | NULL | Piso mínimo de R% no consumido (ex: Marginal Pinheiros = 30%) |
| `cepacs_convertidos_aca` | INTEGER | NÃO | 0 | CEPACs convertidos via ACA |
| `cepacs_convertidos_parametros` | INTEGER | NÃO | 0 | CEPACs convertidos via parâmetros |
| `cepacs_desvinculados_aca` | INTEGER | NÃO | 0 | CEPACs desvinculados via ACA |
| `cepacs_desvinculados_parametros` | INTEGER | NÃO | 0 | CEPACs desvinculados via parâmetros |
| `ativo` | BOOLEAN | NÃO | TRUE | Se o setor está ativo |
| `bloqueio_nr` | BOOLEAN | NÃO | FALSE | Bloqueia criação NR (ex: Berrini = TRUE) |
| `created_at` | TIMESTAMPTZ | NÃO | now() | Data de criação |
| `operacao_urbana_id` | INTEGER | NÃO | — | FK → operacao_urbana — identifica a qual OUC o setor pertence |
| `setor_pai_id` | UUID | SIM | NULL | FK self-ref → setor — NULL = setor raiz; preenchido em subsetores (ex: OUCAB Setor A3 → Setor A) |
| `fator_equivalencia_f1` | NUMERIC(10,6) | SIM | NULL | Fator F1 de equivalência de CEPACs (NULL em setores Pai/container) |
| `fator_equivalencia_f2` | NUMERIC(10,6) | SIM | NULL | Fator F2 de equivalência de CEPACs (NULL em setores Pai/container) |

**Constraints:** `pk_setor` (PK), `uq_setor_nome` (UNIQUE nome), `fk_setor_operacao_urbana`, `fk_setor_pai` (self-ref, nullable).  
**Índices:** `idx_setor_operacao_urbana_id`, `idx_setor_pai_id`.

**Parâmetros por OUC:**

| OUC | Setor | teto_r_m2 | teto_nr_m2 | estoque_total_m2 | F1 | F2 | setor_pai |
|-----|-------|-----------|------------|-----------------|----|----|-----------|
| AE | Jabaquara | NULL | 175.000 | 250.000 | 3.0 | 2.0 | — |
| AE | Brooklin | NULL | 980.000 | 1.400.000 | 1.0 | 1.0 | — |
| AE | Berrini | NULL | 175.000 | 350.000 | 1.0 | 2.0 | — |
| AE | Marginal Pinheiros | NULL | 420.000 | 600.000 | 2.0 | 2.0 | — |
| AE | Chucri Zaidan | NULL | 1.783.557,53 | 2.000.000 | 1.0 | 2.0 | — |
| FL | Hélio Pelegrino | 292.445 | 182.505 | 474.950 | 1.0 | 1.0 | — |
| FL | Faria Lima | 288.190 | 73.715 | 361.905 | 1.0 | 1.0 | — |
| FL | Pinheiros | 286.695 | 96.600 | 383.295 | 1.0 | 1.0 | — |
| FL | Olimpíadas | 190.440 | 95.565 | 286.005 | 1.0 | 1.0 | — |
| AB | Setor A *(pai)* | 90.000 | 55.000 | 145.000 | — | — | — |
| AB | Setor A3 | 90.000 | 55.000 | 145.000 | 1.0 | 0.8 | Setor A |
| AB | Setor B | 300.000 | 110.000 | 410.000 | 0.8 | 0.7 | — |
| AB | Setor C | 20.000 | 0 | 20.000 | 1.0 | 0.6 | — |
| AB | Setor E *(pai)* | 270.000 | 130.000 | 400.000 | — | — | — |
| AB | Setor E1 | 50.000 | 50.000 | 100.000 | 0.7 | 0.6 | Setor E |
| AB | Setor E2 | 220.000 | 80.000 | 300.000 | 0.7 | 0.6 | Setor E |
| AB | Setor F *(pai)* | 260.000 | 70.000 | 330.000 | — | — | — |
| AB | Setor F1 | 60.000 | 40.000 | 100.000 | 0.7 | 0.6 | Setor F |
| AB | Setor F2 | 200.000 | 30.000 | 230.000 | 0.7 | 0.6 | Setor F |
| AB | Setor G | 15.000 | 15.000 | 30.000 | 0.4 | 0.6 | — |
| AB | Setor H | 150.000 | 110.000 | 260.000 | 0.4 | 0.6 | — |
| AB | Setor I1 | 15.000 | 10.000 | 25.000 | 0.4 | 0.6 | — |

> **Nota OUCAE:** `teto_r_m2` é NULL em todos os setores da OUCAE exceto Chucri Zaidan (`reserva_r_m2 = 216.442,47`). `piso_r_percentual = 30%` em Marginal Pinheiros.  
> **Nota OUCAB:** Setores Pai (A, E, F) têm `fator_equivalencia_f1/f2 = NULL` — são containers de agrupamento; os tetos do Pai equivalem à soma dos filhos.  
> **Nota Setor C:** `teto_nr_m2 = 0` — setor exclusivamente residencial.

---

## Tabela 3 — `titulo_cepac`

> Cada título CEPAC individual. Estado transiciona via registro em `movimentacao`.

| Coluna | Tipo | Nulo | Default | Descrição |
|--------|------|------|---------|-----------|
| `id` | UUID | NÃO | gen_random_uuid() | Chave primária |
| `codigo` | VARCHAR(50) | NÃO | — | Código único do título |
| `setor_id` | UUID | NÃO | — | FK → setor |
| `valor_m2` | NUMERIC(15,2) | NÃO | — | Valor de conversão em m² (> 0) |
| `uso` | uso_enum | NÃO | — | Uso: R ou NR |
| `origem` | origem_enum | NÃO | — | Origem: ACA ou NUVEM |
| `estado` | estado_titulo_enum | NÃO | `DISPONIVEL` | Estado atual do título |
| `data_desvinculacao` | TIMESTAMPTZ | SIM | NULL | Obrigatório quando estado = QUARENTENA |
| `created_at` | TIMESTAMPTZ | NÃO | now() | Data de criação |
| `updated_at` | TIMESTAMPTZ | NÃO | now() | Atualizado automaticamente por trigger |

**Constraints:** PK, UNIQUE(codigo), FK para setor (RESTRICT), check valor > 0, check desvinculacao consistente.  
**Trigger:** `trg_titulo_cepac_updated_at` — atualiza `updated_at` automaticamente.

---

## Tabela 4 — `solicitacao_vinculacao`

> Pedidos de vinculação de CEPACs a processos SEI/SIMPROC.

| Coluna | Tipo | Nulo | Default | Descrição |
|--------|------|------|---------|-----------|
| `id` | UUID | NÃO | gen_random_uuid() | Chave primária |
| `setor_id` | UUID | NÃO | — | FK → setor |
| `uso` | uso_enum | NÃO | — | Uso pretendido: R, NR ou MISTO |
| `origem` | origem_enum | NÃO | — | Origem: ACA ou NUVEM |
| `area_m2` | NUMERIC(15,2) | NÃO | — | Área solicitada em m² (> 0) |
| `quantidade_cepacs` | INTEGER | NÃO | — | Quantidade de CEPACs solicitados (> 0) |
| `numero_processo_sei` | VARCHAR(50) | NÃO | — | Número do processo (não vazio) |
| `status` | status_solicitacao_enum | NÃO | `PENDENTE` | Status da solicitação |
| `motivo_rejeicao` | TEXT | SIM | NULL | Obrigatório quando status = REJEITADA |
| `created_at` | TIMESTAMPTZ | NÃO | now() | Data de criação |
| `proposta_id` | UUID | SIM | NULL | FK → proposta (migration 005) |
| `observacao` | TEXT | SIM | NULL | Observação livre (migration 005) |

**Constraints:** PK, FK para setor (RESTRICT), FK opcional para proposta (RESTRICT), checks de consistência.

---

## Tabela 5 — `solicitacao_titulos`

> Tabela de junção N:N entre `solicitacao_vinculacao` e `titulo_cepac`.

| Coluna | Tipo | Nulo | Default | Descrição |
|--------|------|------|---------|-----------|
| `solicitacao_id` | UUID | NÃO | — | FK → solicitacao_vinculacao |
| `titulo_id` | UUID | NÃO | — | FK → titulo_cepac |
| `area_m2` | NUMERIC(15,2) | NÃO | — | Contribuição deste título (m²) |

**Constraints:** PK composta (solicitacao_id, titulo_id), ambas FK com RESTRICT.

---

## Tabela 6 — `movimentacao`

> Log de auditoria **append-only** de todas as transições de estado dos títulos. UPDATE e DELETE bloqueados por trigger.

| Coluna | Tipo | Nulo | Default | Descrição |
|--------|------|------|---------|-----------|
| `id` | UUID | NÃO | gen_random_uuid() | Chave primária |
| `titulo_id` | UUID | NÃO | — | FK → titulo_cepac |
| `setor_id` | UUID | NÃO | — | FK → setor (desnormalizado para queries) |
| `uso` | uso_enum | NÃO | — | Uso do título no momento |
| `origem` | origem_enum | NÃO | — | Origem do título |
| `estado_anterior` | estado_titulo_enum | SIM | NULL | NULL apenas no seed inicial |
| `estado_novo` | estado_titulo_enum | NÃO | — | Estado resultante da operação |
| `numero_processo_sei` | VARCHAR(50) | NÃO | — | Processo que originou a movimentação |
| `motivo` | TEXT | SIM | NULL | Motivo (ex: SEED_INICIAL, EXPIRAÇÃO_TTL) |
| `operador` | VARCHAR(200) | NÃO | — | UPN ou ID do sistema que operou |
| `created_at` | TIMESTAMPTZ | NÃO | now() | Imutável — base do audit trail |

**Triggers:** `trg_movimentacao_no_update` e `trg_movimentacao_no_delete` bloqueiam qualquer alteração.  
**Índice:** `idx_movimentacao_saldo` em (setor_id, uso, origem, estado_novo, created_at) — usado em todas as queries de saldo.

---

## Tabela 7 — `proposta`

> Cada projeto/empreendimento que solicitou vinculação de CEPACs.

| Coluna | Tipo | Nulo | Default | Descrição |
|--------|------|------|---------|-----------|
| `id` | UUID | NÃO | gen_random_uuid() | Chave primária |
| `codigo` | VARCHAR(20) | NÃO | — | Código único (ex: AE-0001) |
| `numero_pa` | TEXT | SIM | NULL | Número do processo administrativo (SIMPROC ou SEI) |
| `tipo_processo` | tipo_processo_enum | SIM | NULL | SIMPROC ou SEI |
| `data_autuacao` | DATE | SIM | NULL | Data de autuação do processo |
| `status_pa` | status_pa_enum | NÃO | `ANALISE` | Status: DEFERIDO, INDEFERIDO ou ANALISE |
| `interessado` | VARCHAR(300) | SIM | NULL | Nome do interessado |
| `cnpj_cpf` | VARCHAR(20) | SIM | NULL | Campo legado — mantido por compatibilidade |
| `cnpj` | TEXT | SIM | NULL | CNPJ do interessado (pessoa jurídica) |
| `cpf` | TEXT | SIM | NULL | CPF do interessado (pessoa física) |
| `tipo_interessado` | VARCHAR(5) | SIM | NULL | PF ou PJ |
| `endereco` | TEXT | SIM | NULL | Endereço do empreendimento |
| `setor_id` | UUID | NÃO | — | FK → setor |
| `requerimento` | requerimento_enum | NÃO | — | VINCULACAO, ALTERACAO ou DESVINCULACAO |
| `area_terreno_m2` | NUMERIC(15,2) | SIM | NULL | Área do terreno em m² |
| `observacao_alteracao` | TEXT | SIM | NULL | Obs. sobre diferença devida (certidões de alteração) |
| `data_proposta` | DATE | SIM | NULL | Data da proposta (item 2.1 do formulário) |
| `contribuinte_sq` | TEXT | SIM | NULL | Número de Contribuinte SQ |
| `contribuinte_lote` | TEXT | SIM | NULL | Identificação do lote |
| `uso_aca` | VARCHAR(10) | SIM | NULL | Uso na ACA: R, NR ou MISTO |
| `aca_r_m2` | NUMERIC(15,2) | SIM | NULL | Área adicional residencial na ACA (m²) |
| `aca_nr_m2` | NUMERIC(15,2) | SIM | NULL | Área adicional não-residencial na ACA (m²) |
| `aca_total_m2` | NUMERIC(15,2) | SIM | NULL | Área adicional total na ACA (m²) |
| `tipo_contrapartida` | VARCHAR(20) | SIM | NULL | CEPAC (título) ou OODC (dinheiro) |
| `valor_oodc_rs` | NUMERIC(18,2) | SIM | NULL | Valor pago via OODC em R$ |
| `cepac_aca` | INTEGER | SIM | NULL | CEPACs para conversão de área (ACA) |
| `cepac_parametros` | INTEGER | SIM | NULL | CEPACs para parâmetros urbanísticos |
| `cepac_total` | INTEGER | SIM | NULL | Total de CEPACs vinculados |
| `certidao` | VARCHAR(30) | SIM | NULL | Número da certidão vinculada |
| `situacao_certidao` | VARCHAR(20) | SIM | NULL | VALIDA ou CANCELADA |
| `data_certidao` | DATE | SIM | NULL | Data de emissão da certidão |
| `nuvem_r_m2` | NUMERIC(15,2) | SIM | NULL | Área R registrada na NUVEM (m²) |
| `nuvem_nr_m2` | NUMERIC(15,2) | SIM | NULL | Área NR registrada na NUVEM (m²) |
| `nuvem_total_m2` | NUMERIC(15,2) | SIM | NULL | Área total registrada na NUVEM (m²) |
| `nuvem_cepac` | INTEGER | SIM | NULL | CEPACs registrados na NUVEM |
| `obs` | TEXT | SIM | NULL | Observações livres |
| `resp_data` | VARCHAR(100) | SIM | NULL | Responsável e data de análise |
| `cross_check` | VARCHAR(100) | SIM | NULL | Resultado do cruzamento ACA × NUVEM |
| `created_at` | TIMESTAMPTZ | NÃO | now() | Data de criação |
| `updated_at` | TIMESTAMPTZ | NÃO | now() | Atualizado por trigger |

**Constraints:** PK, UNIQUE(codigo), FK para setor (RESTRICT).  
**Trigger:** `trg_proposta_updated_at` atualiza `updated_at`.

---

## Tabela 8 — `certidao`

> Certidões de vinculação, desvinculação e alteração emitidas pela SP Urbanismo. Base da Consulta Pública de Autenticidade.

| Coluna | Tipo | Nulo | Default | Descrição |
|--------|------|------|---------|-----------|
| `id` | UUID | NÃO | gen_random_uuid() | Chave primária |
| `proposta_id` | UUID | NÃO | — | FK → proposta |
| `numero_certidao` | VARCHAR(20) | NÃO | — | Número único (ex: AE-001/2024, DV-001/2026) |
| `tipo` | tipo_certidao_enum | NÃO | — | VINCULAÇÃO, DESVINCULAÇÃO ou ALTERAÇÃO |
| `data_emissao` | DATE | SIM | NULL | Data de emissão |
| `numero_processo_sei` | TEXT | SIM | NULL | Processo de referência |
| `situacao` | situacao_certidao_enum | NÃO | `VALIDA` | VALIDA, CANCELADA ou ANALISE |
| `uso_aca` | VARCHAR(10) | SIM | NULL | Uso na ACA: R, NR ou MISTO |
| `aca_r_m2` | NUMERIC(15,2) | SIM | NULL | Área adicional R na ACA (m²) |
| `aca_nr_m2` | NUMERIC(15,2) | SIM | NULL | Área adicional NR na ACA (m²) |
| `aca_total_m2` | NUMERIC(15,2) | SIM | NULL | Área adicional total na ACA (m²) |
| `tipo_contrapartida` | TEXT | SIM | NULL | CEPAC (título) ou OODC (dinheiro) |
| `valor_oodc_rs` | NUMERIC(18,2) | SIM | NULL | Valor pago via OODC (R$) |
| `cepac_aca` | INTEGER | SIM | NULL | CEPACs para conversão de área |
| `cepac_parametros` | INTEGER | SIM | NULL | CEPACs para parâmetros urbanísticos |
| `cepac_total` | INTEGER | SIM | NULL | Total de CEPACs da certidão |
| `nuvem_r_m2` | NUMERIC(15,2) | SIM | NULL | Área R registrada na NUVEM (m²) |
| `nuvem_nr_m2` | NUMERIC(15,2) | SIM | NULL | Área NR registrada na NUVEM (m²) |
| `nuvem_total_m2` | NUMERIC(15,2) | SIM | NULL | Área total registrada na NUVEM (m²) |
| `nuvem_cepac` | INTEGER | SIM | NULL | CEPACs registrados na NUVEM |
| `contribuinte_sq` | TEXT | SIM | NULL | Número de Contribuinte SQ |
| `contribuinte_lote` | TEXT | SIM | NULL | Identificação do lote |
| `obs` | TEXT | SIM | NULL | Observações livres |
| `created_at` | TIMESTAMPTZ | NÃO | now() | Data de criação |

**Constraints:** PK, UNIQUE(numero_certidao), FK para proposta (RESTRICT).

---

## Tabela 9 — `usuario`

> Técnicos e Diretores autenticados via Azure AD. Roles gerenciados na aplicação (não no AD).

| Coluna | Tipo | Nulo | Default | Descrição |
|--------|------|------|---------|-----------|
| `id` | UUID | NÃO | gen_random_uuid() | Chave primária |
| `upn` | VARCHAR(200) | NÃO | — | User Principal Name do Azure AD (único) |
| `nome` | VARCHAR(200) | SIM | NULL | Nome de exibição |
| `papel` | papel_usuario_enum | NÃO | `TECNICO` | TECNICO ou DIRETOR |
| `ativo` | BOOLEAN | NÃO | TRUE | Conta ativa |
| `created_at` | TIMESTAMPTZ | NÃO | now() | Data de criação (1º login) |
| `last_login_at` | TIMESTAMPTZ | SIM | NULL | Data do último login |

**Constraints:** PK, UNIQUE(upn).

---

## Tabela 10 — `documento_processo`

> Metadados de documentos no Azure Blob Storage. O arquivo físico nunca transita pelo backend (upload via SAS URL). Append-only.

| Coluna | Tipo | Nulo | Default | Descrição |
|--------|------|------|---------|-----------|
| `id` | UUID | NÃO | gen_random_uuid() | Chave primária |
| `proposta_id` | UUID | NÃO | — | FK → proposta |
| `numero_processo_sei` | TEXT | NÃO | — | Processo de referência |
| `nome_arquivo` | VARCHAR(500) | NÃO | — | Nome original do arquivo |
| `blob_path` | VARCHAR(1000) | NÃO | — | Caminho no Blob: {ano}/{mes}/{uuid}-{nome} |
| `content_type` | VARCHAR(100) | SIM | NULL | MIME type |
| `tamanho_bytes` | BIGINT | SIM | NULL | Tamanho em bytes |
| `operador_id` | UUID | NÃO | — | FK → usuario (quem fez upload) |
| `created_at` | TIMESTAMPTZ | NÃO | now() | Data de upload |

**Constraints:** PK, FK para proposta (RESTRICT), FK para usuario (RESTRICT).  
**Trigger:** `trg_documento_no_delete` bloqueia DELETE.

---

## Tabela 11 — `medicao_obra`

> Série histórica de medições mensais de obras. Alimenta o custo total incorrido do dashboard. Append-only.

| Coluna | Tipo | Nulo | Default | Descrição |
|--------|------|------|---------|-----------|
| `id` | UUID | NÃO | gen_random_uuid() | Chave primária |
| `data_referencia` | DATE | NÃO | — | Primeiro dia do mês de competência (UNIQUE) |
| `valor_medicao` | NUMERIC(18,2) | NÃO | — | Valor da medição mensal em R$ (> 0) |
| `valor_acumulado` | NUMERIC(18,2) | NÃO | — | Custo total acumulado após esta medição (> 0) |
| `descricao` | TEXT | SIM | NULL | Descrição livre da medição |
| `numero_processo_sei` | TEXT | NÃO | — | Processo de referência |
| `operador_id` | UUID | NÃO | — | FK → usuario |
| `created_at` | TIMESTAMPTZ | NÃO | now() | Data de registro |

**Constraints:** PK, UNIQUE(data_referencia), CHECK(data = primeiro dia do mês), FK para usuario.  
**Triggers:** bloqueiam UPDATE e DELETE.

---

## Tabela 12 — `parametro_sistema`

> Pares chave-valor configuráveis. Atualizável por DIRETOR. Chaves predefinidas: `cepacs_em_circulacao`, `data_inicio_oucae`.

| Coluna | Tipo | Nulo | Default | Descrição |
|--------|------|------|---------|-----------|
| `chave` | VARCHAR(100) | NÃO | — | Chave do parâmetro (PK) |
| `valor` | TEXT | NÃO | — | Valor do parâmetro |
| `descricao` | TEXT | SIM | NULL | Descrição do parâmetro |
| `updated_at` | TIMESTAMPTZ | NÃO | now() | Data da última atualização |
| `operador_id` | UUID | SIM | NULL | FK → usuario (SET NULL ao excluir usuário) |

---

## Tabela 13 — `configuracao_operacao`

> Singleton (id sempre = 1) com parâmetros globais da operação.

| Coluna | Tipo | Nulo | Default | Descrição |
|--------|------|------|---------|-----------|
| `id` | SMALLINT | NÃO | 1 | PK — sempre 1 (CHECK id=1) |
| `reserva_tecnica_m2` | NUMERIC(15,2) | NÃO | 0 | CEPACs reservados para uso técnico da Prefeitura |
| `cepacs_leiloados` | INTEGER | NÃO | 0 | Total de CEPACs vendidos em leilão |
| `cepacs_colocacao_privada` | INTEGER | NÃO | 0 | CEPACs por colocação privada |
| `cepacs_totais` | INTEGER | NÃO | 0 | Total geral de CEPACs emitidos |
| `updated_at` | TIMESTAMP | NÃO | now() | Data de atualização |

---

## Diagrama de Relacionamentos

```
operacao_urbana
  │
  └──< setor ──────────────────────────┐ (setor_pai_id — self-ref)
         │                             │
         ├──< titulo_cepac             │
         │       │                     │
         │       ├──< movimentacao     │
         │       │                     │
         │       └──< solicitacao_titulos >──┐
         │                                   │
         ├──< solicitacao_vinculacao ─────────┘
         │       │
         │       └── proposta_id (opt) ─┐
         │                              │
         └──< proposta ─────────────────┘
                 │
                 ├──< certidao
                 └──< documento_processo
                         │
usuario ─────────────────┴──────────────
  │
  ├──< medicao_obra
  └──< parametro_sistema

configuracao_operacao (singleton — sem FK)
```

---

## Histórico de Migrations

| Migration | Descrição |
|-----------|-----------|
| 001 | Schema inicial: setor, titulo_cepac, solicitacao_vinculacao, movimentacao |
| 002 | Seed setores OUCAE (Brooklin, Berrini, Marginal Pinheiros, Chucri Zaidan, Jabaquara) |
| 003 | Tabelas Fase 2: usuario, proposta, certidao, documento_processo |
| 004 | Carga inicial real (399KB — dados históricos da OUCAE) |
| 004a | Revoga seed sintético anterior à carga real |
| 005 | Campos portal em proposta (proposta_id em solicitacao, observacao) |
| 006 | Seed medicao_obra inicial |
| 007 | Seed parametro_sistema |
| 008 | ADD setor: ativo, bloqueio_nr, piso_r_percentual |
| 009 | ADD setor: teto_r_m2 |
| 010 | CREATE configuracao_operacao (singleton) |
| 011 | ADD setor: campos CEPAC desagregados por origem (aca / parametros) |
| 012 | Campos adicionais em proposta (planilha) |
| 013 | Expansão tabela certidao |
| 014 | Limpeza de certidões com formato inválido |
| 015 | CREATE operacao_urbana + seed AE, FL, AB |
| 016 | FK setor.operacao_urbana_id — todos os setores OUCAE → AE |
| 017 | ADD setor: setor_pai_id (hierarquia) + fator_equivalencia_f1/f2 |
| 018 | Seed F1/F2 dos setores OUCAE |
| 019 | Seed setores OUC Faria Lima (4 setores) |
| 020 | Seed setores OUC Água Branca (13 setores — 5 standalone, 3 pais, 5 filhos) |

---

## Regras de Negócio Críticas

| Regra | Onde Implementada |
|-------|-------------------|
| `movimentacao` é append-only (imutável) | Trigger `trg_movimentacao_no_update/delete` |
| `medicao_obra` é append-only | Trigger `trg_medicao_no_update/delete` |
| `documento_processo` não pode ser deletado | Trigger `trg_documento_no_delete` |
| Saldo de CEPACs sempre calculado, nunca armazenado | Arquitetura — derivado de `movimentacao` |
| `configuracao_operacao` sempre tem exatamente 1 linha | CHECK (id = 1) |
| `data_desvinculacao` obrigatório quando estado = QUARENTENA | CHECK em `titulo_cepac` |
| `motivo_rejeicao` obrigatório quando status = REJEITADA | CHECK em `solicitacao_vinculacao` |
| `data_referencia` sempre primeiro dia do mês | CHECK em `medicao_obra` |
| Usuário criado automaticamente no 1º login com papel=TECNICO | Lógica de aplicação |
| Promoção a DIRETOR via endpoint PATCH /admin/usuarios/{id}/papel | API REST |
| Setores Pai (OUCAB) são containers — F1/F2 sempre NULL | Convenção de dados |
| `setor.nome` é UNIQUE globalmente entre todas as OUCs | UNIQUE constraint |
