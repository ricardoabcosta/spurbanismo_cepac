# Planejamento — Carga OUCAB

**Status**: 🟡 **Planejamento — pendente validação do cliente**
**Origem**: `docs/novos/OUCAB_CONTROLE_ESTOQUES_mar_2026.xlsx` (posição 31/03/2026) + `docs/novos/GUIA_PRATICO_OUCAB_FINAL.pdf` (versão 1.1, 14/12/2023)
**Lei vigente**: Lei nº 15.893/2013 (alterada pela Lei nº 17.561/2021 — substitui Quadro III de fatores de equivalência)
**Decreto regulamentador**: Decreto nº 55.392/2014
**Data**: 2026-05-06

---

## 1. Objetivo

Carregar os dados reais da Operação Urbana Consorciada Água Branca (OUCAB) — segunda distribuição pública (12/12/2023) — no sistema CEPAC. Diferentemente da OUCFL, a OUCAB **não tem leis anteriores** consumidas (modelo multi-lei já implementado é suficiente: 1 lei vigente). A complexidade está em:

1. **Hierarquia de subsetores** (já parcialmente implementada): A→A1/A2/A3, E→E1/E2, F→F1/F2, I→I1/I2.
2. **Categoria R Incentivada vs R Não Incentivada** (HIS/EHIS) com **limite global cross-setor de 675.000 m²** (art. 39 §2 da Lei 15.893/2013) — já implementada via `incentivado` flag e `teto_r_nao_incentivado_m2`.
3. **Fatores de Equivalência Fe únicos por setor** (Quadro III da Lei 17.561/2021), divergem dos fatores F1/F2 já gravados na migration 021.
4. **ACA não onerosa = área de fruição pública** (art. 28 da Lei 15.893/2013) — pode ser modelado com os campos `aca_*_beneficios_m2` já existentes.
5. **Setores sem estoque**: A1, A2, D, I2 (estoque = 0) — atualmente ausentes do banco.

## 2. Contexto da OUCAB

### 2.1 Estoque global (Lei 15.893/2013, art. 39)

| Categoria | Estoque máximo |
|---|---|
| Residencial (R) | 1.350.000 m² |
| Não Residencial (nR) | 500.000 m² |
| **TOTAL** | **1.850.000 m²** |

Limite cumulativo R **não-incentivado** (cross-setor): **675.000 m²** (art. 39 §2). O excedente do estoque R (até 1.350.000) só pode ser consumido por **unidades habitacionais incentivadas (HIS/EHIS)** — definidas no art. 5º, IX da lei (área privativa entre 45 e 50 m², 1 sanitário, 1 vaga). Estoques residenciais estão **sempre disponíveis** para vinculação de UI (art. 46 §1).

### 2.2 Setores e subsetores (12 unidades, Quadro IV)

| Setor | Pai | R (m²) | nR (m²) | Total (m²) | Fe (Lei 17.561/2021) |
|---|---|---:|---:|---:|---:|
| A | — | 90.000 | 55.000 | 145.000 | 1,00 |
| A1 | A | 0 | 0 | 0 | N/A |
| A2 | A | 0 | 0 | 0 | N/A |
| A3 | A | 90.000 | 55.000 | 145.000 | 1,00 |
| B | — | 300.000 | 110.000 | 410.000 | 1,00 |
| C | — | 20.000 | 0 | 20.000 | 0,60 |
| D | — | 0 | 0 | 0 | N/A |
| E | — | 270.000 | 130.000 | 400.000 | 1,00 |
| E1 | E | 50.000 | 50.000 | 100.000 | 1,00 |
| E2 | E | 220.000 | 80.000 | 300.000 | 1,00 |
| F | — | 260.000 | 70.000 | 330.000 | 1,00 |
| F1 | F | 60.000 | 40.000 | 100.000 | 1,00 |
| F2 | F | 200.000 | 30.000 | 230.000 | 1,00 |
| G | — | 175.000 | 50.000 | 225.000 | 1,00 |
| H | — | 165.000 | 85.000 | 250.000 | 0,60 |
| I | — | 70.000 | 0 | 70.000 | 0,40 |
| I1 | I | 70.000 | 0 | 70.000 | 0,40 |
| I2 | I | 0 | 0 | 0 | N/A |
| **TOTAL** | | **1.350.000** | **500.000** | **1.850.000** | |

> **Nota crítica**: o seed atual (`migrations/021_seed_setores_oucab.sql`) cadastrou apenas 13 setores (5 standalone + 3 pais + 5 filhos) e usa `fator_equivalencia_f1` / `f2` com valores que **não correspondem ao Quadro III da Lei 17.561/2021**. Setores A1, A2, D e I2 estão ausentes; setor I (pai) também está ausente. Ver §5 (lacunas).

### 2.3 Posição real (planilha mar/2026)

A 2ª distribuição pública ocorreu em **12/12/2023**. Em 31/03/2026, a posição é praticamente zerada — apenas **6 propostas deferidas** (5 no setor B, 1 no setor H) e **1 cancelada**:

| Proposta | Certidão | Setor | Interessado | ACA Onerosa (m²) | Tipo | Nº CEPAC | Status |
|---|---|---|---|---:|---|---:|---|
| AB-0096 | AB-001/2023 | B | WINDSOR Investimentos | 0 | — | 0 | Cancelada |
| AB-0112 | AB-001/2024 | B | WINDSOR | 22.996,69 | R não-Inc | 22.286 | Deferido |
| AB-0113 | AB-002/2024 | B | WINDSOR | 48.341,24 | R não-Inc | 47.794 | Deferido |
| AB-0096 | AB-003/2024 | B | WINDSOR | 24.997,61 | R não-Inc | 24.207 | Deferido |
| AB-0114 | AB-004/2024 | B | WINDSOR | 19.217,54 | R não-Inc | 18.717 | Deferido |
| AB-0115 | AB-001/2025 | B | WINDSOR | 37.432,40 | R não-Inc | 37.433 | Deferido |
| AB-0116 | AB-001/2026 | H | BSP Empreendimentos | 4.380,03 | nR | 7.301 | Deferido |

**Subtotais consolidados**:

| Setor | R não-Inc consumido | nR consumido | Disponível R | Disponível nR |
|---|---:|---:|---:|---:|
| B | 152.985,48 m² | 0 | 147.014,52 m² | 110.000 m² |
| H | 0 | 4.380,03 m² | 165.000 m² | 80.619,97 m² |

**R não-Incentivado consumido global**: 152.985,48 m² · **disponível**: 522.014,52 m² (= 675.000 − 152.985,48).
**Estoque total disponível**: 1.692.634,49 m² (= 1.850.000 − 152.985,48 − 4.380,03).

### 2.4 Inconsistências detectadas na planilha

1. **Aba "B" sub-total inflacionado**: a linha `B / AB-0116 / setor H` está duplicada na aba B (linha 11) e na aba H (linha 5) — soma 4.380,03 m² no subtotal da B (157.365,51) que pertence ao setor H. A aba **Geral** repete o erro: marca `B / R não Inc consumido = 157.365,51` quando o correto seria 152.985,48.
2. **Status do setor H em "Em análise" no Geral**: a aba Geral indica `H / em análise nR = 4.380,03`, mas a aba H mostra status `DEFERIDO` em 09/03/2026. Provavelmente a aba Geral não foi atualizada após o deferimento.
3. **Coluna "AREA ADICIONAL DE UNIDADE" sempre zero**: nenhuma proposta utilizou o estoque de Unidade Incentivada até agora.

⚠️ Confirmar com o cliente qual fonte é a correta antes da carga.

## 3. Estado atual da implementação OUCAB no sistema

### 3.1 ✅ Já implementado

| Funcionalidade | Localização | Observação |
|---|---|---|
| OperacaoUrbana com sigla `AB` | migration 015/021 | id=3 |
| 13 setores OUCAB | migration 021 | A, A3, B, C, E, E1, E2, F, F1, F2, G, H, I1 |
| Hierarquia setor-pai via `setor_pai_id` | migration 017/021 | A→A3, E→E1/E2, F→F1/F2 |
| Lei 15.893/2013 cadastrada | migration 026 | `lei_ouc.identificador='15.893/2013'` |
| `setor_estoque_lei` para 13 setores | migration 027 | uma linha por setor |
| Flag `incentivado` em titulo/movimentacao/solicitacao | migration 023 | NULL = sem distinção, TRUE/FALSE = OUCAB |
| `operacao_urbana.teto_r_nao_incentivado_m2 = 675.000` | migration 022 | Específico OUCAB |
| Validator `r_nao_incentivado.py` | engine/validators | Aplica teto cross-setor de R-NI |
| Engine reconhece os 13 setores | rules_engine.py L51-63 | Cadeia: SEI → r_nao_incentivado → quarentena |
| Campos benefícios em `proposta` | migration 028 | `aca_r_real_m2`, `aca_r_beneficios_m2`, `aca_nr_real_m2`, `aca_nr_beneficios_m2` |

### 3.2 🔴 Lacunas críticas identificadas

#### L1 — Fatores de equivalência divergentes

A migration 021 cadastrou `fator_equivalencia_f1` e `fator_equivalencia_f2` com **valores que não correspondem ao Quadro III da Lei 17.561/2021**. Comparativo:

| Setor | Migration 021 (F1 / F2) | Lei 17.561/2021 (Fe único) |
|---|---:|---:|
| B | 0,80 / 0,70 | **1,00** |
| C | 1,00 / 0,60 | **0,60** |
| G | 0,40 / 0,60 | **1,00** |
| H | 0,40 / 0,60 | **0,60** |
| I1 | 0,40 / 0,60 | **0,40** |
| A3 | 1,00 / 0,80 | **1,00** |
| E1, E2 | 0,70 / 0,60 | **1,00** |
| F1, F2 | 0,70 / 0,60 | **1,00** |

Decisão necessária: a OUCAB tem **um único Fe por setor** (não dois como a OUCAE). É preciso escolher entre:
- **(a)** Reutilizar `fator_equivalencia_f1` como o Fe único e ignorar `f2` (NULL para OUCAB).
- **(b)** Adicionar coluna `fator_equivalencia_unico` em `setor` para deixar a semântica explícita.

#### L2 — Setores ausentes no banco (A1, A2, D, I, I2)

Faltam **5 entidades** que aparecem no Quadro IV da lei mas têm estoque zero. A planilha confirma sua existência.

| Setor | Pai | Estoque | Fe | Por que está ausente? |
|---|---|---:|---|---|
| A1 | A | 0 | N/A | Migration 021 não inclui — nunca terá CEPAC |
| A2 | A | 0 | N/A | idem |
| D | — | 0 | N/A | Subsetor sem estoque, citado na lei |
| I (pai) | — | 70.000 R | 0,40 | Pai do I1 — segue padrão A/E/F mas não foi seedado |
| I2 | I | 0 | N/A | Migration 021 não inclui |

**Decisão necessária**: criar todos os 18 setores oficiais (mesmo com estoque 0) **OU** manter apenas os 13 atuais e tratar A1/A2/D/I2 como inválidos para vinculação?

#### L3 — Distinção R Incentivado / Não-Incentivado no estoque setorial

Atualmente, `setor_estoque_lei.estoque_total_r_m2` armazena **um único valor R**. A OUCAB exige diferenciar:

- **Estoque R total**: 1.350.000 m² (cap setorial — soma de todos os setores).
- **Estoque R não-Incentivado**: 675.000 m² (cap **global** cross-setor — não por setor).
- **Estoque R Incentivado**: até 675.000 m² **adicionais** (tudo o que sobrar do R total).

O modelo atual lida bem no nível global (via `operacao_urbana.teto_r_nao_incentivado_m2`), mas **as métricas setoriais por categoria** (R-Inc consumido em B, R-NI consumido em B, etc.) precisam ser separadas para o dashboard. O campo `incentivado` no `titulo_cepac`/`movimentacao` permite calcular isso por agregação. Precisaremos:

- (a) Repositório que agregue saldo setorial por categoria (`r_inc_consumido`, `r_nao_inc_consumido`, `nr_consumido`).
- (b) Dashboard exibindo as 3 colunas (R não-Inc, R Inc, nR) por setor — formato Geral.csv.

#### L4 — Categoria de uso na PROPOSTA não distingue R Inc / R Não-Inc

`Proposta` tem `uso_aca` ∈ {`R`, `NR`, `MISTO`} e `aca_r_m2` (área R total). Para OUCAB, é necessário decompor:
- `aca_r_inc_m2` (UI — Unidade Incentivada)
- `aca_r_nao_inc_m2` (R comum)
- `aca_nr_m2` (já existe)

**Opções**:
- **(a) Adicionar colunas** `aca_r_inc_m2` e `aca_r_nao_inc_m2` em `proposta`. NULL para OUCAE/OUCFL.
- **(b) Reutilizar** `incentivado` da `solicitacao_vinculacao` e segregar via JOIN. Não funciona se uma proposta tiver ACA mista (R-Inc + R-NI).

A opção **(a)** é mais explícita e segura. A planilha tem coluna "AREA ADICIONAL DE UNIDADE INCENTIVADA" separada da "AREA DE CONSTRUCAO ADICIONAL ONEROSA", confirmando a decomposição.

#### L5 — ACA não onerosa (Fruição Pública, art. 28)

A Lei 15.893/2013 art. 28 prevê **acréscimo gratuito de até 100% da área de fruição pública** (mín. 500 m², averbada). Na prática:

- `ACA = (Ato × Cproj) − (Ato × CB)` — área computável adicional bruta
- `ACA não onerosa = área de fruição pública` (ganho gratuito)
- `ACA onerosa = ACA − ACA não onerosa` (a que consome CEPAC)

Mapeamento sugerido para `proposta`:
- `aca_r_real_m2` = ACA bruta R (o `Ato × Cproj` para uso R, antes de descontar fruição)
- `aca_r_beneficios_m2` = parcela R da ACA não onerosa (fruição pública atribuída a R)
- `aca_r_m2` = `aca_r_real_m2 − aca_r_beneficios_m2` (ACA onerosa R — o que consome CEPAC)

✅ **O modelo OUCFL já tem esses campos**. Aplicação direta na carga.

#### L6 — Validators setoriais OUCAB inexistentes

O `rules_engine.py` mapeia cada setor OUCAB para `[sei, r_nao_incentivado, quarantine]` — **não existe validator que confira teto NR setorial nem teto R setorial** para os setores OUCAB. Implicações:

- Uma proposta NR no Setor C (estoque NR = 0) **passaria** pelas validações atuais. ❌
- Uma proposta R no Setor I1 acima de 70.000 m² **passaria**. ❌
- Falta também o validator de **capacidade global da OUC**: 1.850.000 m² total da OUCAB (já gravado em `lei_ouc.estoque_geral_m2`, mas não consultado no engine).

Precisamos:
- **`validators/oucab_setor.py`** — genérico OUCAB que consulta `setor_estoque_lei` e bloqueia quando `consumido + solicitacao > estoque_setorial`.
- **`validators/capacity.py`** — generalizar (hoje é hardcoded `4.850.000 − 250.000 = 4.600.000` para OUCAE) para ler `lei_ouc.estoque_geral_m2`.

#### L7 — Subsetor: a planilha lança no setor pai ou no filho?

A planilha tem abas **separadas** para cada subsetor (A3, E1, E2, F1, F2, I1) e abas **inexistentes** para setores sem subsetor (B, C, D, G, H). Isso sugere: a vinculação se dá **sempre no subsetor folha** (A3, E1, E2, F1, F2, I1) ou no setor standalone (B, C, G, H, D).

Decisão pela carga: **vincular ao setor da aba** (A3/B/C/E1/E2/F1/F2/G/H/I1) — não ao pai. As 6 propostas reais foram para B (5×) e H (1×), todos sem subsetor.

#### L8 — Validador de capacidade global hardcoded para OUCAE

`engine/validators/capacity.py` linhas 17-19 fixa `4.850.000 / 250.000`. Para OUCAB precisaria ler de `lei_ouc.estoque_geral_m2`. Já existe `LimitesOucDTO.capacidade_global_m2` (atualmente populado mas não consultado pelo validator). **Refator necessário**: validator passa a ler de `limites_ouc.capacidade_global_m2` e degrada para no-op quando NULL.

#### L9 — Dashboard de OUCAB ainda não tem layout próprio

A tela atual do dashboard exibe Big Numbers da OUCAE (Brooklin, Berrini etc.). Para OUCAB, o cliente espera ver:
- Saldo R não-Incentivado disponível (frente aos 675.000 m²).
- Saldo R Incentivado.
- Saldo nR.
- Por setor: R não-Inc / R Inc / nR consumido / disponível.

Decisão: usar mesma estrutura de cards mas alimentada por novo endpoint `/dashboard/oucab` ou parametrizar `/dashboard/oucae` com query param `?ouc=AB`.

## 4. Decisões a confirmar com o cliente

| # | Tema | Opção sugerida | Alternativa |
|---|---|---|---|
| Q1 | Fatores Fe — coluna semântica | (a) reutilizar `fator_equivalencia_f1` para Fe único; `f2` = NULL | (b) Nova coluna `fator_equivalencia_unico` |
| Q2 | Setores sem estoque | Cadastrar A1, A2, D, I, I2 com estoque 0 (catálogo completo) | Manter os 13 atuais |
| Q3 | Decomposição R Inc / R Não-Inc na proposta | Adicionar `aca_r_inc_m2` e `aca_r_nao_inc_m2` em `proposta` | Manter agregado `aca_r_m2` + flag `incentivado` |
| Q4 | Tratar inconsistência subtotal aba B (157.365,51 vs 152.985,48) | Confiar nas linhas individuais (152.985,48) | Confiar no Geral (157.365,51) |
| Q5 | Status do setor H (Em análise vs Deferido) | Considerar Deferido (aba H, 09/03/2026) | Considerar Em análise (aba Geral) |
| Q6 | Tela do dashboard OUCAB | Reutilizar layout OUCAE com 3 categorias por setor | Nova tela específica |
| Q7 | Subsetores na carga | Vincular sempre ao setor da aba (folha ou standalone) | Sempre ao pai |
| Q8 | Operações pré-2ª distribuição | Não há (1ª distribuição = 2013, 2ª = 12/12/2023) | — |

## 5. Modelagem de dados (proposta)

### 5.1 Migrations adicionais

```sql
-- 030_setores_oucab_completos.sql — corrige L1 + L2
-- (a) Adiciona setores A1, A2, D, I, I2 com estoque 0
-- (b) Atualiza fatores Fe conforme Quadro III da Lei 17.561/2021

BEGIN;

-- Setores ausentes
INSERT INTO setor (nome, estoque_total_m2, teto_r_m2, teto_nr_m2, operacao_urbana_id, fator_equivalencia_f1)
VALUES
    ('Setor D', 0, 0, 0, 3, NULL);

INSERT INTO setor (nome, estoque_total_m2, teto_r_m2, teto_nr_m2, operacao_urbana_id, fator_equivalencia_f1)
VALUES
    ('Setor I', 70000, 70000, 0, 3, 0.40);

INSERT INTO setor (nome, estoque_total_m2, teto_r_m2, teto_nr_m2, operacao_urbana_id, setor_pai_id, fator_equivalencia_f1)
SELECT 'Setor A1', 0, 0, 0, 3, id, NULL FROM setor WHERE nome = 'Setor A' AND operacao_urbana_id = 3
UNION ALL
SELECT 'Setor A2', 0, 0, 0, 3, id, NULL FROM setor WHERE nome = 'Setor A' AND operacao_urbana_id = 3;

INSERT INTO setor (nome, estoque_total_m2, teto_r_m2, teto_nr_m2, operacao_urbana_id, setor_pai_id, fator_equivalencia_f1)
SELECT 'Setor I2', 0, 0, 0, 3, id, NULL FROM setor WHERE nome = 'Setor I' AND operacao_urbana_id = 3;

-- Reparenta I1 → Setor I (hoje órfão)
UPDATE setor s SET setor_pai_id = (SELECT id FROM setor WHERE nome = 'Setor I' AND operacao_urbana_id = 3)
WHERE s.nome = 'Setor I1' AND s.operacao_urbana_id = 3;

-- Corrige Fe (Quadro III, Lei 17.561/2021) — setando f1 como Fe único
UPDATE setor SET fator_equivalencia_f1 = 1.00, fator_equivalencia_f2 = NULL WHERE nome = 'Setor A'  AND operacao_urbana_id = 3;
UPDATE setor SET fator_equivalencia_f1 = 1.00, fator_equivalencia_f2 = NULL WHERE nome = 'Setor A3' AND operacao_urbana_id = 3;
UPDATE setor SET fator_equivalencia_f1 = 1.00, fator_equivalencia_f2 = NULL WHERE nome = 'Setor B'  AND operacao_urbana_id = 3;
UPDATE setor SET fator_equivalencia_f1 = 0.60, fator_equivalencia_f2 = NULL WHERE nome = 'Setor C'  AND operacao_urbana_id = 3;
UPDATE setor SET fator_equivalencia_f1 = 1.00, fator_equivalencia_f2 = NULL WHERE nome = 'Setor E'  AND operacao_urbana_id = 3;
UPDATE setor SET fator_equivalencia_f1 = 1.00, fator_equivalencia_f2 = NULL WHERE nome = 'Setor E1' AND operacao_urbana_id = 3;
UPDATE setor SET fator_equivalencia_f1 = 1.00, fator_equivalencia_f2 = NULL WHERE nome = 'Setor E2' AND operacao_urbana_id = 3;
UPDATE setor SET fator_equivalencia_f1 = 1.00, fator_equivalencia_f2 = NULL WHERE nome = 'Setor F'  AND operacao_urbana_id = 3;
UPDATE setor SET fator_equivalencia_f1 = 1.00, fator_equivalencia_f2 = NULL WHERE nome = 'Setor F1' AND operacao_urbana_id = 3;
UPDATE setor SET fator_equivalencia_f1 = 1.00, fator_equivalencia_f2 = NULL WHERE nome = 'Setor F2' AND operacao_urbana_id = 3;
UPDATE setor SET fator_equivalencia_f1 = 1.00, fator_equivalencia_f2 = NULL WHERE nome = 'Setor G'  AND operacao_urbana_id = 3;
UPDATE setor SET fator_equivalencia_f1 = 0.60, fator_equivalencia_f2 = NULL WHERE nome = 'Setor H'  AND operacao_urbana_id = 3;
UPDATE setor SET fator_equivalencia_f1 = 0.40, fator_equivalencia_f2 = NULL WHERE nome = 'Setor I1' AND operacao_urbana_id = 3;

COMMIT;

-- 031_setor_estoque_lei_oucab_completos.sql
-- Adiciona registros de setor_estoque_lei para os 5 setores novos (A1, A2, D, I, I2)
-- com estoque zero. Vinculados à lei 15.893/2013.

-- 032_proposta_aca_r_incentivado.sql — endereça L4
ALTER TABLE proposta
    ADD COLUMN aca_r_inc_m2 NUMERIC(15,2) NULL,        -- ACA Residencial Incentivada (HIS/EHIS)
    ADD COLUMN aca_r_nao_inc_m2 NUMERIC(15,2) NULL;    -- ACA Residencial Não-Incentivada
-- Invariante (não enforced no SQL): aca_r_m2 = aca_r_inc_m2 + aca_r_nao_inc_m2 quando ambos preenchidos
```

### 5.2 Sem mudança em `lei_ouc` / `setor_estoque_lei`

A OUCAB tem **uma única lei vigente**. O modelo multi-lei (já implementado) cobre o caso. Apenas precisamos garantir que os 5 setores novos (Q2 = sim) tenham linha em `setor_estoque_lei` apontando para `lei_ouc.id` da 15.893/2013.

## 6. Mudanças no código backend

### 6.1 Models SQLAlchemy
- `Proposta`: adicionar `aca_r_inc_m2` e `aca_r_nao_inc_m2` (Q3=a).

### 6.2 Repositórios
- `saldo_repository.calcular_saldo_setor()`: agregar movimentações **separadas por categoria** (R-Inc, R-NI, NR) usando o campo `incentivado`. Hoje agrega R/NR sem distinção.
- `saldo_repository.get_limites_ouc()`: já lê `lei_ouc.estoque_geral_m2` ✅.
- `dashboard_repository`: novo método `get_resumo_oucab()` que retorna estrutura compatível com a aba Geral da planilha.

### 6.3 Engine de regras
- **Novo validator** `validators/oucab_setor.py`: valida estoque setorial OUCAB (L6).
  - Bloqueia se `(R consumido + R em análise + R solicitação) > estoque_setor_r`.
  - Bloqueia se `(NR consumido + NR em análise + NR solicitação) > estoque_setor_nr`.
- **Refator** `validators/capacity.py`: ler `limites_ouc.capacidade_global_m2` em vez de constante hardcoded (L8). No-op quando NULL.
- **Atualizar** `VALIDATORS_POR_SETOR` em `rules_engine.py`: cada setor OUCAB roda `[sei, capacity, oucab_setor, r_nao_incentivado, quarantine]`.

### 6.4 Schemas Pydantic
- `PropostaIn` no portal: aceitar `aca_r_inc_m2` e `aca_r_nao_inc_m2` (opcional).
- `SolicitacaoPortalIn`: validar que `incentivado` é obrigatório quando `setor` é OUCAB e `uso=R`.

### 6.5 Endpoints
- `GET /dashboard/oucab` — Big Numbers + tabela por setor (formato Geral.csv).
- `POST /portal/propostas`: aceitar campos novos.

### 6.6 Frontend
- **Dashboard**: aba "OUCAB" com Big Numbers (R-NI disponível, R-Inc disponível, nR disponível) + tabela 13×4 (setor, R-NI, R-Inc, nR consumido).
- **Portal**: form de nova proposta — quando OUC=AB, exibir radio R-Incentivada × R-Não-Incentivada.

## 7. Script de carga

`scripts/carga_oucab.py` — espelho de `scripts/carga_oucfl.py`. Idempotente, transacional, com `--dry-run`.

**Fluxo**:
1. Lê `docs/novos/OUCAB_CONTROLE_ESTOQUES_mar_2026.xlsx`.
2. Para cada aba de subsetor (A3, B, C, E1, E2, F1, F2, G, H, I1) — pula linhas vazias e modelo:
   - Cria `Proposta` com `codigo` (AB-XXXX), atribui `setor_id` pelo nome do setor da linha.
   - Define `lei_vigente='15.893/2013'`.
   - Como a planilha não detalha ACA bruta vs benefícios, preenche apenas `aca_r_m2`/`aca_nr_m2` (campo "AREA DE CONSTRUÇÃO ADICIONAL ONEROSA"); `aca_r_real_m2 = aca_r_m2`, `aca_r_beneficios_m2 = 0`.
   - Se houver "AREA ADICIONAL DE UNIDADE": preencher `aca_r_inc_m2`. Restante R vai para `aca_r_nao_inc_m2`.
   - Se status=Deferido e situação=VÁLIDA: cria `Certidao` (TipoCertidaoEnum.VINCULACAO).
   - Cria `TituloCepac`(estado=CONSUMIDO, incentivado=FALSE para R-NI / TRUE para R-Inc / NULL para NR) + `Movimentacao` negativa.
3. **Não há histórico cross-lei** — não há leis anteriores na OUCAB.
4. Loga relatório final de comparação Excel × DB.

**Idempotência**: por `codigo + numero_certidao + data_certidao`.

## 8. Validação pós-carga

| Indicador | Excel (mar/2026) | Query DB esperada |
|---|---:|---|
| R não-Inc consumido OUCAB (global) | 152.985,48 m² | `SUM(aca_r_nao_inc_m2)` para propostas DEFERIDAS |
| R Inc consumido OUCAB | 0 | idem para `aca_r_inc_m2` |
| nR consumido OUCAB | 4.380,03 m² | `SUM(aca_nr_m2)` |
| Setor B — R consumido | 152.985,48 m² | filtrado por setor_id |
| Setor H — nR consumido | 4.380,03 m² | idem |
| Saldo R não-Inc disponível | 522.014,52 m² | 675.000 − consumido |
| Saldo total OUCAB | 1.692.634,49 m² | 1.850.000 − total consumido |
| CEPACs convertidos OUCAB | 157.738 | `SUM(cepac_total)` para deferidas |

Tolerância: ≤ 1,00 m² por arredondamento. Divergência > 1 m² em qualquer linha = parar e investigar antes do deploy.

## 9. Riscos

| Risco | Mitigação |
|---|---|
| Quebra OUCAE/OUCFL ao adicionar setores OUCAB ou alterar Fe | Migrations apenas tocam `operacao_urbana_id = 3`; testes de integração das outras OUCs antes do deploy |
| Validators OUCAB bloqueiam propostas legítimas | `--dry-run` simula validação para os 6 registros reais antes do INSERT |
| Refator do `capacity.py` quebra OUCAE | Rodar bateria completa de testes (5 setores OUCAE) com OUCAE ainda lendo `4.850.000` (LimitesOucDTO.capacidade_global_m2 = 4.600.000) |
| Inconsistência aba B vs Geral (Q4) | Carga consulta apenas as linhas de proposta nas abas individuais — Geral é validação visual |
| Cliente alterar Fe pós-implantação | Endpoint admin já existe (`PATCH /admin/setores/{id}`) com permissão DIRETOR |

## 10. Plano de execução em 4 sessões

| Sessão | Entregas | Bloqueios |
|---|---|---|
| **1 — Decisões + Modelagem** | Confirmar Q1–Q8 com cliente. Migrations 030–032. Atualizar models. Atualizar `MIGRATION_ORDER` em conftest. | Aguarda respostas Q1–Q8 |
| **2 — Engine + Repositórios** | Novo validator `oucab_setor.py`. Refator `capacity.py` para ler `limites_ouc`. Repositório agregando R-Inc/R-NI/NR. Endpoint `/dashboard/oucab`. Testes unitários dos validators. | S1 |
| **3 — Carga real** | `scripts/carga_oucab.py` com `--dry-run`. Validação Excel × DB. Carga em produção (Azure). | S2 |
| **4 — Frontend dashboard + portal** | Aba OUCAB no dashboard (Big Numbers + tabela). Form portal com toggle R-Inc / R-Não-Inc. Deploy Container Apps. | S3 |

---

## TASKS

### Sessão 1 — Decisões + Modelagem (~1 dia)

#### T-AB1.1 — Confirmação de decisões com o cliente
**Owner**: Tech Lead · **Bloqueia**: todas as outras tasks
**Entregáveis**: ata de decisão Q1–Q8 atualizada neste documento.
**Critério de aceite**: todas as 8 questões respondidas e este documento atualizado com a decisão.

#### T-AB1.2 — Migration 030: setores ausentes + correção de Fe
**Arquivos**: `migrations/030_setores_oucab_completos.sql`
**Conteúdo**:
- INSERT setores A1, A2, D, I, I2 (todos com estoque 0; A1, A2, I2 com `setor_pai_id` apontando para A e I; D standalone).
- UPDATE I1.setor_pai_id = id de I.
- UPDATE de `fator_equivalencia_f1` em todos os setores OUCAB conforme Quadro III (Lei 17.561/2021).
- UPDATE de `fator_equivalencia_f2 = NULL` em todos os setores OUCAB (Q1=a).
- DO $$...$$ valida 18 setores OUCAB no final.
**Critério de aceite**: `SELECT COUNT(*) FROM setor WHERE operacao_urbana_id = 3` retorna 18.

#### T-AB1.3 — Migration 031: setor_estoque_lei para novos setores
**Arquivos**: `migrations/031_setor_estoque_lei_oucab_novos.sql`
**Conteúdo**: INSERT em `setor_estoque_lei` para A1, A2, D, I, I2 vinculados a `lei_ouc.id` da 15.893/2013, todos com estoque 0 (exceto I que herda 70.000 R + 0 nR).
**Critério de aceite**: `SELECT COUNT(*) FROM setor_estoque_lei sel JOIN lei_ouc lo ON sel.lei_ouc_id = lo.id WHERE lo.operacao_urbana_id = 3` = 18.

#### T-AB1.4 — Migration 032: proposta — campos R Incentivado/Não-Inc
**Arquivos**: `migrations/032_proposta_aca_r_incentivado.sql`
**Conteúdo**: ALTER TABLE proposta ADD COLUMN `aca_r_inc_m2 NUMERIC(15,2) NULL`, `aca_r_nao_inc_m2 NUMERIC(15,2) NULL`.
**Critério de aceite**: schema atualizado; campos NULL para todas as propostas existentes (OUCAE/OUCFL não preenchem).

#### T-AB1.5 — Atualizar models SQLAlchemy
**Arquivos**: `src/core/models/proposta.py`
**Conteúdo**: adicionar mappings dos 2 campos novos.
**Critério de aceite**: `SELECT aca_r_inc_m2 FROM proposta` funciona via SQLAlchemy.

#### T-AB1.6 — Atualizar MIGRATION_ORDER
**Arquivos**: `tests/integration/conftest.py`
**Conteúdo**: incluir 030, 031, 032 na lista ordenada.
**Critério de aceite**: `pytest tests/integration` passa.

---

### Sessão 2 — Engine + Repositórios (~2 dias)

#### T-AB2.1 — Novo validator `oucab_setor.py`
**Arquivos**: `src/core/engine/validators/oucab_setor.py` (novo)
**Conteúdo**: lê `solicitacao.limites_setor.estoque_total_m2` e `teto_nr_m2` (já parametrizados via `setor_estoque_lei`); bloqueia quando consumido + solicitação > limite.
**Critério de aceite**: testes unitários para os 6 cenários (R/NR/MISTO × dentro/fora do limite).

#### T-AB2.2 — Refator `capacity.py` para ler de `limites_ouc`
**Arquivos**: `src/core/engine/validators/capacity.py`
**Conteúdo**: substituir constantes hardcoded por `solicitacao.limites_ouc.capacidade_global_m2`. No-op se NULL. Atualizar `saldo_repository` para popular este campo (já existe ✅).
**Critério de aceite**: bateria de testes OUCAE continua passando; teste novo OUCAB (1.850.000 m²) bloqueia corretamente.

#### T-AB2.3 — Cadeia de validators OUCAB no engine
**Arquivos**: `src/core/engine/rules_engine.py`
**Conteúdo**: para cada setor OUCAB, cadeia `[sei, capacity, oucab_setor, r_nao_incentivado, quarantine]`. Mapear todos os 18 setores (incluir A1/A2/D/I/I2 que retornam SETOR_INVALIDO se chegar solicitação — mas isso é via `oucab_setor` que detecta estoque 0).
**Critério de aceite**: testes de integração do engine cobrem propostas em A1, A2, D — todos retornam erro estruturado.

#### T-AB2.4 — Repositório agregando R-Inc / R-NI / NR
**Arquivos**: `src/core/repositories/saldo_repository.py`
**Conteúdo**: novo `SaldoSetorOucabDTO` com 6 campos (r_inc_consumido, r_inc_em_analise, r_nao_inc_consumido, r_nao_inc_em_analise, nr_consumido, nr_em_analise) — agregação por flag `incentivado`.
**Critério de aceite**: para cada setor OUCAB, `calcular_saldo_oucab(setor_id)` bate com a aba Geral.

#### T-AB2.5 — Endpoint `/dashboard/oucab`
**Arquivos**: `src/api/routes/dashboard.py`, `src/api/schemas/dashboard.py`
**Conteúdo**: retorna estrutura `{ totals: {...}, setores: [{nome, r_inc_consumido, r_nao_inc_consumido, nr_consumido, r_inc_disponivel, r_nao_inc_disponivel, nr_disponivel}] }`.
**Critério de aceite**: response bate com a aba Geral da planilha (após carga).

#### T-AB2.6 — Schema Portal aceita campos novos
**Arquivos**: `src/api/schemas/portal.py`
**Conteúdo**: `PropostaIn` opcional `aca_r_inc_m2`, `aca_r_nao_inc_m2`. Validação: se OUC=AB e uso=R, ao menos um dos dois deve ser > 0.
**Critério de aceite**: POST com setor B + uso=R + aca_r_inc_m2=100 + aca_r_nao_inc_m2=200 cria proposta com áreas separadas.

---

### Sessão 3 — Carga real (~1 dia)

#### T-AB3.1 — Script `scripts/carga_oucab.py`
**Arquivos**: `scripts/carga_oucab.py` (novo)
**Conteúdo**: lê XLSX OUCAB, percorre abas por subsetor, cria Proposta + Certidao + TituloCepac + Movimentacao. Idempotente. `--dry-run` produz CSV comparativo.
**Critério de aceite**: `python scripts/carga_oucab.py --dry-run` exibe os 7 registros (6 deferidos + 1 cancelada) sem alterar o banco; valores batem com Excel.

#### T-AB3.2 — Carga em ambiente local
**Conteúdo**: rodar `python scripts/carga_oucab.py` contra Postgres local (testcontainers ou dev). Validar 9 indicadores da §8.
**Critério de aceite**: todos os 9 indicadores ≤ 1 m² de divergência.

#### T-AB3.3 — Carga em produção (Azure)
**Conteúdo**: backup do banco, rodar carga, validar via `/dashboard/oucab`.
**Critério de aceite**: `/dashboard/oucab` em produção retorna os mesmos números da §8.

---

### Sessão 4 — Frontend (~1,5 dia)

#### T-AB4.1 — Tipos TypeScript + API functions
**Arquivos**: `frontend/dashboard/src/types/api.ts`, `frontend/dashboard/src/api/oucab.ts`
**Conteúdo**: `OucabResumoOut`, `OucabSetorRow`, função `getDashboardOucab()`.
**Critério de aceite**: chamada à API resolve com tipos.

#### T-AB4.2 — Página Dashboard OUCAB
**Arquivos**: `frontend/dashboard/src/pages/OucabPage.tsx` (novo)
**Conteúdo**: Big Numbers (3 cards: R-NI, R-Inc, nR) + tabela 13×7 (setor, R-NI cons/disp, R-Inc cons/disp, nR cons/disp).
**Critério de aceite**: visualmente espelha a aba Geral da planilha.

#### T-AB4.3 — Toggle OUC no menu
**Arquivos**: `frontend/dashboard/src/App.tsx`, header
**Conteúdo**: dropdown OUCAE / OUCFL / OUCAB → roteia para a página correspondente.
**Critério de aceite**: navegação fluida entre as 3 OUCs.

#### T-AB4.4 — Portal: form de nova proposta com R-Inc/R-NI
**Arquivos**: `frontend/portal/src/components/NovaProposta.tsx`
**Conteúdo**: quando OUC=AB e uso=R, exibir radio "Unidade Incentivada (HIS/EHIS)" / "Residencial padrão"; campos `aca_r_inc_m2`/`aca_r_nao_inc_m2` aparecem condicionalmente.
**Critério de aceite**: submissão cria proposta com decomposição correta.

#### T-AB4.5 — Deploy Container Apps
**Conteúdo**: `gh workflow run deploy.yml`. Validar revisões dashboard e portal.
**Critério de aceite**: dashboard e portal em produção exibem aba/toggle OUCAB; nova proposta em B funciona.

---

## 11. Resumo executivo

- A OUCAB **já tem boa parte da infraestrutura pronta** no sistema (lei, setores, hierarquia, flag incentivado, teto cross-setor de 675K).
- **Lacunas pequenas mas críticas**: Fe errados, 5 setores ausentes, falta validator de teto setorial OUCAB, capacity.py hardcoded para OUCAE, dashboard sem visão OUCAB.
- **Carga é trivial em volume** (7 registros) — o esforço está nas adequações de modelo/regras antes da carga.
- **Plano em 4 sessões (~5,5 dias úteis)** com 18 tasks numeradas, decisões claras a confirmar com o cliente, critérios de aceite verificáveis.

**Pendência bloqueante**: respostas Q1–Q8 da §4.
