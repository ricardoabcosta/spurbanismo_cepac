# Planejamento — Carga OUCFL e Modelo Multi-lei

**Status**: aprovado · pronto para execução
**Origem**: planilha `docs/novos/OUCFL_ESTOQUE_abr_rv02.xlsx` + `20250805_workshop_OUCFL_part1.pdf`
**Data**: 2026-05-05

## 1. Objetivo

Carregar os dados da Operação Urbana Consorciada Faria Lima (OUCFL) no sistema CEPAC e generalizar o modelo de dados para suportar **múltiplas leis vigentes ao longo do tempo** numa mesma OUC. OUCFL é o primeiro caso real de OUC com lei anterior (11.732/1995), lei de criação (13.769/2004) e lei de revisão (18.175/2024). O modelo deve ser flexível para receber casos futuros (OUCAE e OUCAB ainda não têm lei anterior, mas podem ter no futuro).

## 2. Contexto da OUCFL

**4 setores macro**: HÉLIO PELEGRINO, FARIA LIMA, PINHEIROS, OLIMPÍADAS (já seedados na migration 019).

**18 sub-setores** (1a–1d, 2a–2e, 3a–3e, 4a–4d) com fatores F1/F2 distintos definidos pela Lei 18.175/24 — **fora do escopo desta carga**, virão como necessidade futura.

**Linha do tempo de leis**:

| Ordem | Lei | Vigência | Papel |
|---|---|---|---|
| 1 | 11.732/1995 | até 2004 | pré-OUC (consumo congelado em **940.000 m²**) |
| 2 | 13.769/2004 | 2004–2024 | criação da OUC; estoque máximo de 1.506.155 m² |
| 3 | 18.175/2024 | a partir de jan/2024 | atual; expandiu estoque para 1.756.155 m² |

**Volume da carga**:
- 270 propostas (243 Lei 13.769/04 + 26 Lei 18.175/24 + 1 sem lei)
- 264 deferidas, 4 em análise, 2 sem status
- 195 vinculações + 65 alterações + 8 desvinculações
- 1.000.000 CEPACs emitidos · 774.382 convertidos · 7.100 em circulação · saldo 218.518

## 3. Decisões consolidadas

| # | Tema | Decisão |
|---|---|---|
| D1 | Lei na proposta | Adicionar `proposta.lei_vigente` (texto livre); NULL para OUCAE/OUCAB |
| D2 | Estoque por lei | Tabela 1:N `setor_estoque_lei` (extensível) |
| D3 | ACA Real / Benefícios | Adicionar `aca_r_real_m2`, `aca_r_beneficios_m2`, `aca_nr_real_m2`, `aca_nr_beneficios_m2` em `proposta`; NULL para Lei 13.769 |
| D4 | Sub-setores | Carga inicial vincula tudo ao **setor pai**; sub-setores ficam para futuro |
| D5 | Restituição 90 dias | **Ignorar** na carga; cliente fará manual; funcionalidade vai para roadmap |
| D6 | Formato do PA | Aceitar 12 e 16 dígitos sem normalização (campo livre) |
| D7 | USO ACA = MISTO | Já é valor válido no `UsoEnum` — preservar na carga |
| D8 | Consumo de lei anterior | Modelar via `lei_ouc.consumo_historico_*` (apenas OUCFL terá registros pré-vigentes; OUCAE/OUCAB ficam só com lei vigente) |
| D9 | Saldo geral | Derivado de `Movimentacao` por filtro de `proposta.lei_vigente` (já é o padrão) |

## 4. Modelagem de dados

### 4.1 Novas tabelas

```sql
-- Catálogo de leis aplicáveis a uma OUC, em ordem cronológica
CREATE TABLE lei_ouc (
  id                       SERIAL PRIMARY KEY,
  operacao_urbana_id       INTEGER NOT NULL REFERENCES operacao_urbana(id),
  identificador            VARCHAR(30) NOT NULL,   -- "11.732/1995", "13.769/2004", "18.175/2024"
  nome                     VARCHAR(150),
  data_vigencia_inicio     DATE,
  data_vigencia_fim        DATE,                   -- NULL = lei atual
  ordem                    INTEGER NOT NULL,       -- 1 = mais antiga
  vigente                  BOOLEAN NOT NULL DEFAULT FALSE,
  -- Consumo histórico congelado (preenchido só em leis encerradas/anteriores)
  consumo_historico_r_m2   NUMERIC(15,2),
  consumo_historico_nr_m2  NUMERIC(15,2),
  -- Estoque global da OUC sob essa lei (limite p/ oferta de CEPAC)
  estoque_geral_m2         NUMERIC(15,2),
  UNIQUE (operacao_urbana_id, identificador),
  UNIQUE (operacao_urbana_id, ordem)
);
CREATE INDEX idx_lei_ouc_vigente ON lei_ouc(operacao_urbana_id, vigente);

-- Estoque por setor para cada lei (estoque max muda entre leis)
CREATE TABLE setor_estoque_lei (
  id                     SERIAL PRIMARY KEY,
  setor_id               UUID NOT NULL REFERENCES setor(id),
  lei_ouc_id             INTEGER NOT NULL REFERENCES lei_ouc(id),
  estoque_total_r_m2     NUMERIC(15,2) NOT NULL,
  estoque_total_nr_m2    NUMERIC(15,2) NOT NULL,
  teto_r_m2              NUMERIC(15,2),
  teto_nr_m2             NUMERIC(15,2),
  reserva_r_m2           NUMERIC(15,2),
  UNIQUE (setor_id, lei_ouc_id)
);
```

### 4.2 Campos novos em `proposta`

```sql
ALTER TABLE proposta ADD COLUMN lei_vigente VARCHAR(30);
ALTER TABLE proposta ADD COLUMN aca_r_real_m2 NUMERIC(15,2);
ALTER TABLE proposta ADD COLUMN aca_r_beneficios_m2 NUMERIC(15,2);
ALTER TABLE proposta ADD COLUMN aca_nr_real_m2 NUMERIC(15,2);
ALTER TABLE proposta ADD COLUMN aca_nr_beneficios_m2 NUMERIC(15,2);

-- Invariante (apenas para Lei 18.175/24): real - beneficios = aca (computável)
-- Não é CHECK no SQL pois Lei 13.769 deixa esses campos NULL
```

### 4.3 Compatibilidade com `setor.*`

Os campos `setor.estoque_total_m2`, `setor.teto_nr_m2`, `setor.reserva_r_m2` continuam por enquanto como **denormalização da lei vigente** (atualizados via trigger ou aplicação ao mudar `lei_ouc.vigente`). Isso evita reescrever todo o `RulesEngine` num só passo.

Após validação da carga OUCFL, faremos PR separado removendo os campos denormalizados e migrando todas as queries para `setor_estoque_lei`.

## 5. Sequência de migrations

| Arquivo | Conteúdo |
|---|---|
| `025_lei_ouc_estoque.sql` | Cria `lei_ouc` e `setor_estoque_lei` |
| `026_seed_lei_ouc.sql` | Popula `lei_ouc` para OUCAE (1 lei vigente), OUCAB (1 lei vigente), OUCFL (3 leis: 11.732 anterior, 13.769 anterior, 18.175 vigente) |
| `027_seed_setor_estoque_lei.sql` | Popula `setor_estoque_lei` espelhando os atuais `setor.*` para cada `lei_ouc.vigente` + insere registros adicionais para OUCFL Lei 13.769 (estoques antigos) |
| `028_proposta_lei_beneficios.sql` | Adiciona campos novos em `proposta` (`lei_vigente`, 4 campos de benefícios) |

Atualizar `MIGRATION_ORDER` em `tests/integration/conftest.py` para incluir 025–028.

## 6. Mudanças no código backend

### 6.1 Models SQLAlchemy
- Novo `src/core/models/lei_ouc.py` (`LeiOuc`)
- Novo `src/core/models/setor_estoque_lei.py` (`SetorEstoqueLei`)
- `Proposta`: adicionar 5 colunas
- `Setor`: adicionar relationship `estoques_por_lei: list[SetorEstoqueLei]`
- `OperacaoUrbana`: adicionar relationship `leis: list[LeiOuc]` + property `lei_vigente`

### 6.2 Repositórios
- `saldo_repository.calcular_saldo()`: recebe opcionalmente `lei_id`; quando NULL usa lei vigente do setor
- `saldo_repository.get_limites_ouc()`: lê de `setor_estoque_lei` filtrado pela lei vigente, soma `consumo_historico_*` das leis anteriores no cálculo do saldo geral
- `dashboard_repository.montar_snapshot()`: soma consumo histórico de `lei_ouc` no big number `total_consumido_m2` (todas as OUCs)

### 6.3 Engine de regras
- `SolicitacaoDTO` recebe `lei_vigente: Optional[str]`
- Validators que olham `setor.estoque_total_m2` passam a olhar o `setor_estoque_lei` da lei correspondente
- Por ora, sem mudança em fatores F1/F2 (sub-setores ficam fora)

### 6.4 Endpoints
- `GET /admin/operacoes-urbanas/{id}/leis` (CRUD de `lei_ouc`)
- `GET /admin/setores/{id}/estoques-por-lei` (CRUD de `setor_estoque_lei`)
- `POST /portal/propostas` aceita `lei_vigente` e benefícios opcionais

### 6.5 Frontend
- Tela admin `OUCAdminPage`: aba/seção "Leis" listando histórico cronológico
- Tela admin `SetoresPorOUCPage`: editar estoque por setor selecionando a lei
- Formulário de nova proposta: dropdown `lei_vigente` populado com as leis da OUC selecionada (default: lei vigente)

## 7. Script de carga OUCFL

`scripts/carga_oucfl.py` — idempotente, transacional, com flag `--dry-run`.

**Fluxo**:
1. Lê `docs/novos/OUCFL_ESTOQUE_abr_rv02.xlsx` aba `2_CONTROLE_ESTOQUE`
2. Para cada linha com `CODIGO` preenchido:
   - Busca ou cria `Proposta` por `codigo` (ex.: `FL-0399`)
   - Atribui `setor_id` pelo nome do setor pai (decisão D4)
   - Preenche todos os campos (incluindo `lei_vigente`, benefícios, nuvem por uso)
   - Se `STATUS PA = DEFERIDO` e `SITUACAO = VALIDA`: cria `Certidao` correspondente
   - Para vinculações: cria `TituloCepac` (estado=CONSUMIDO) + `Movimentacao` negativa
   - Para desvinculações: cria `Movimentacao` positiva
3. Atualiza contadores em `setor` (`cepacs_convertidos_aca/parametros`, `cepacs_desvinculados_aca/parametros`) e em `operacao_urbana` (`cepacs_totais`, `cepacs_leiloados`, `cepacs_colocacao_privada`)
4. Atualiza `lei_ouc` da OUCFL com `consumo_historico_*` da Lei 13.769 lido das totalizações da aba `Consolidado_OUC-FL`
5. Loga relatório final: propostas criadas, atualizadas, erros, totais consolidados

**Re-execução**: detecta propostas existentes por `codigo` e faz `UPDATE` sem duplicar `Movimentacao` (chave: `codigo + tipo + data`).

## 8. Validação pós-carga

Comparar valores agregados Excel × DB (tolerância: ≤ 1,00 m² por arredondamento):

| Indicador | Excel (Consolidado_OUC-FL) | Query DB |
|---|---|---|
| Consumido R Lei 13.769 (total OUCFL) | 646.099,80 | `SUM(aca_r_m2) FROM proposta WHERE lei_vigente='13.769/2004' AND status_pa='DEFERIDO' AND situacao_certidao='VALIDA'` |
| Consumido NR Lei 13.769 | 426.934,24 | idem para `aca_nr_m2` |
| Consumido R Lei 18.175 | 70.352,02 | mesma query com `lei_vigente='18.175/2024'` |
| Consumido NR Lei 18.175 | 51.046,38 | idem |
| Em análise R Lei 18.175 | 4.854,71 | mesma query com `status_pa='ANALISE'` |
| Em análise NR Lei 18.175 | 175,83 | idem |
| CEPACs convertidos OUCFL | 774.382 | `SUM(cepac_total) FROM proposta WHERE setor.operacao_urbana_id=2 AND requerimento='VINCULACAO' AND status_pa='DEFERIDO'` |
| CEPACs desvinculados ACA | 17.136 | `SUM(cepac_aca) FROM proposta WHERE requerimento='DESVINCULACAO'` |
| CEPACs desvinculados Parâmetros | 4.416 | idem para `cepac_parametros` |
| Saldo R por setor | (4 valores) | `setor_estoque_lei.estoque_total_r_m2` − consumido por lei |

Se houver divergência > 1 m² em qualquer linha, parar e investigar antes do deploy.

## 9. Roadmap pós-carga (não bloqueia esta fase)

| Item | Justificativa | Prioridade |
|---|---|---|
| **R1 — Restituição manual com prazo de 90 dias** | Decisão D5; cliente precisa marcar desvinculações pendentes que devolvem estoque após 90 dias da publicação do despacho | Alta — cliente fará manual enquanto não houver UI |
| **R2 — Vinculação a sub-setor (1a/1b/2a etc.)** | Decisão D4; novas propostas Lei 18.175 que dependam de fatores F1/F2 do sub-setor | Média — só quando aparecer caso real |
| **R3 — Remoção de campos denormalizados em `setor`** | Após validação OUCFL, migrar todas as queries para usar `setor_estoque_lei` exclusivamente | Baixa — refactor |
| **R4 — UI de admin de leis** | Hoje só carga via SQL/script; cliente deve conseguir cadastrar nova lei pelo portal | Média |

## 10. Plano de execução em 3 sessões

| Sessão | Entregas |
|---|---|
| **1 — Modelagem + migrations** | Migrations 025–028, models, repositórios atualizados, testes de integração passando, deploy backend |
| **2 — Script de carga + UI admin** | `scripts/carga_oucfl.py`, telas admin atualizadas para `lei_ouc` e `setor_estoque_lei`, deploy frontend |
| **3 — Carga real e validação** | Rodar script no Azure, comparar valores Excel × DB, ajustar divergências, fechar e atualizar `pendencias_fase2.md` com roadmap |

## 11. Riscos e mitigações

| Risco | Mitigação |
|---|---|
| Quebrar OUCAE/OUCAB ao mudar `setor` | Manter campos denormalizados em `setor` durante a transição (item R3 do roadmap) |
| Divergência grande na validação | Script `--dry-run` que produz CSV comparativo antes do INSERT real |
| Propostas com dados inconsistentes na planilha | Logar e pular registros sem `setor` ou sem `codigo`; relatório final com cada caso |
| Re-execução duplicar movimentações | Idempotência por `codigo + tipo + data` |
