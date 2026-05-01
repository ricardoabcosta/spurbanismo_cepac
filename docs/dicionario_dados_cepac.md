# Dicionário de Dados — Projeto CEPAC (SP Urbanismo)
> PostgreSQL 15 · Gerado a partir das migrations 001–013

---

## Visão Geral

O banco possui **11 tabelas** organizadas em duas fases de desenvolvimento:

| # | Tabela | Fase | Finalidade |
|---|--------|------|------------|
| 1 | `setor` | 1 | Setores da Operação Urbana |
| 2 | `titulo_cepac` | 1 | Títulos CEPAC individuais |
| 3 | `solicitacao_vinculacao` | 1 | Pedidos de vinculação de CEPACs |
| 4 | `solicitacao_titulos` | 1 | Junção N:N solicitação ↔ título |
| 5 | `movimentacao` | 1 | Log de auditoria (append-only) |
| 6 | `proposta` | 2 | Projetos/empreendimentos |
| 7 | `certidao` | 2 | Certidões emitidas |
| 8 | `usuario` | 2 | Usuários Azure AD |
| 9 | `documento_processo` | 2 | Metadados de docs no Blob Storage |
| 10 | `medicao_obra` | 2 | Série histórica de medições |
| 11 | `parametro_sistema` | 2 | Parâmetros configuráveis |
| 12 | `configuracao_operacao` | 2 | Singleton com parâmetros globais |

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

## Tabela 1 — `setor`

> Parâmetros estruturais dos setores da OUCAE. Saldo nunca é armazenado; é sempre calculado via `movimentacao`.

| Coluna | Tipo | Nulo | Default | Descrição |
|--------|------|------|---------|-----------|
| `id` | UUID | NÃO | gen_random_uuid() | Chave primária |
| `nome` | VARCHAR(100) | NÃO | — | Nome do setor (único) |
| `estoque_total_m2` | NUMERIC(15,2) | NÃO | — | Estoque total em m² (> 0) |
| `teto_nr_m2` | NUMERIC(15,2) | NÃO | — | Teto de área NR em m² (> 0) |
| `reserva_r_m2` | NUMERIC(15,2) | SIM | NULL | Reserva residencial (só Chucri Zaidan: 216.442,47 m²) |
| `created_at` | TIMESTAMPTZ | NÃO | now() | Data de criação |
| `ativo` | BOOLEAN | NÃO | TRUE | Se o setor está ativo |
| `bloqueio_nr` | BOOLEAN | NÃO | FALSE | Bloqueia criação NR (Berrini: TRUE) |
| `piso_r_percentual` | NUMERIC(5,2) | SIM | NULL | Piso mínimo de R% no consumido (Marginal Pinheiros: 30%) |
| `teto_r_m2` | NUMERIC(15,2) | SIM | NULL | Teto máximo de área R em m² |
| `cepacs_convertidos_aca` | INTEGER | NÃO | 0 | CEPACs convertidos via ACA |
| `cepacs_convertidos_parametros` | INTEGER | NÃO | 0 | CEPACs convertidos via parâmetros |
| `cepacs_desvinculados_aca` | INTEGER | NÃO | 0 | CEPACs desvinculados via ACA |
| `cepacs_desvinculados_parametros` | INTEGER | NÃO | 0 | CEPACs desvinculados via parâmetros |

**Constraints:** `pk_setor` (PK), `uq_setor_nome` (UNIQUE nome), checks em valores positivos.

---

## Tabela 2 — `titulo_cepac`

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

## Tabela 3 — `solicitacao_vinculacao`

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
| `proposta_id` | UUID | SIM | NULL | FK → proposta (adicionado migration 005) |
| `observacao` | TEXT | SIM | NULL | Observação livre (migration 005) |

**Constraints:** PK, FK para setor (RESTRICT), FK opcional para proposta (RESTRICT), checks de consistência.

---

## Tabela 4 — `solicitacao_titulos`

> Tabela de junção N:N entre `solicitacao_vinculacao` e `titulo_cepac`.

| Coluna | Tipo | Nulo | Default | Descrição |
|--------|------|------|---------|-----------|
| `solicitacao_id` | UUID | NÃO | — | FK → solicitacao_vinculacao |
| `titulo_id` | UUID | NÃO | — | FK → titulo_cepac |
| `area_m2` | NUMERIC(15,2) | NÃO | — | Contribuição deste título (m²) |

**Constraints:** PK composta (solicitacao_id, titulo_id), ambas FK com RESTRICT.

---

## Tabela 5 — `movimentacao`

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

---

## Tabela 6 — `proposta`

> Cada projeto/empreendimento que solicitou vinculação de CEPACs na OUCAE. Código no formato AE-XXXX.

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

## Tabela 7 — `certidao`

> Certidões de vinculação, desvinculação e alteração emitidas pela SP Urbanismo. Append-only (base da Consulta Pública de Autenticidade).

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

## Tabela 8 — `usuario`

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

## Tabela 9 — `documento_processo`

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

## Tabela 10 — `medicao_obra`

> Série histórica de medições mensais de obras da OUCAE. Alimenta o "Custo Total Incorrido" do dashboard. Append-only.

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

## Tabela 11 — `parametro_sistema`

> Pares chave-valor configuráveis. Atualizável por DIRETOR. Chaves predefinidas: `cepacs_em_circulacao`, `data_inicio_oucae`.

| Coluna | Tipo | Nulo | Default | Descrição |
|--------|------|------|---------|-----------|
| `chave` | VARCHAR(100) | NÃO | — | Chave do parâmetro (PK) |
| `valor` | TEXT | NÃO | — | Valor do parâmetro |
| `descricao` | TEXT | SIM | NULL | Descrição do parâmetro |
| `updated_at` | TIMESTAMPTZ | NÃO | now() | Data da última atualização |
| `operador_id` | UUID | SIM | NULL | FK → usuario (SET NULL ao excluir usuário) |

---

## Tabela 12 — `configuracao_operacao`

> Singleton (id sempre = 1) com parâmetros globais da OUCAE.

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
configuracao_operacao (singleton)

setor ─────────────────────────┐
  │                            │
  ├──< titulo_cepac            │
  │       │                   │
  │       └──< movimentacao    │
  │       │                   │
  │       └──< solicitacao_titulos >──┐
  │                            │     │
  ├──< solicitacao_vinculacao ──┘     │
  │       │                         │
  │       └── proposta_id (opt) ─┐  │
  │                              │  │
  └──< proposta ─────────────────┘  │
          │                         │
          ├──< certidao             │
          └──< documento_processo   │
                  │                 │
usuario ──────────┴─────────────────┘
  │
  ├──< medicao_obra
  └──< parametro_sistema
```

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
