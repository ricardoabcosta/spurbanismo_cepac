# Planejamento: Fase 2 — Portal Operacional e Dashboard Executivo CEPAC
**SP Urbanismo / Prodam**
**Data:** 2026-04-16
**Versão:** 1.2 — Decisões técnicas finalizadas com SP Urbanismo (16/04/2026)
**Continuação de:** `docs/planejamento.md` v1.8 (Fase 1 — Core Engine, T1–T9)

---

## Visão Geral da Fase 2

A Fase 1 entregou o **Core Engine**: motor de regras, API REST, ciclo de vida dos títulos e infraestrutura Azure. A Fase 2 constrói quatro frentes sobre esse núcleo:

1. **Carga Inicial Real** — substituição dos 13 títulos sintéticos do seed da Fase 1 pelos ~250 registros reais da planilha `OUCAE_ESTOQUE_abr_rv01.xlsx`, que é o Livro Razão oficial da operação.
2. **Autenticação institucional real** — validação direta de tokens Azure AD, substituindo a confiança implícita no APIM.
3. **Portal de Operações Técnicas** — interface web para técnicos cadastrarem solicitações, vincularem processos SEI e anexarem documentos no Azure Blob Storage.
4. **Dashboard Executivo** — painel com big numbers, gráficos de ocupação setorial, alertas de travas, velocímetro 2029 e reconstrução histórica.
5. **Consulta Pública de Autenticidade** — módulo para consulta de certidões emitidas (ABA 3 da planilha), acessível ao munícipe sem autenticação.

---

## Planilha `OUCAE_ESTOQUE_abr_rv01.xlsx` — Fonte de Dados

A planilha é o documento oficial de controle da OUCAE e deve ser tratada como fonte única de verdade para a Carga Inicial. Ela contém 7 abas:

| Aba | Conteúdo | Uso no sistema |
|-----|----------|----------------|
| `Consolidado_OUC-AE` | Painel executivo: estoques máximos, consumido (ACA/NUVEM), saldo disponível | Validação dos Big Numbers do Dashboard |
| `1_controle_codigo` | 384 propostas únicas com código, certidão, interessado e status | Índice de deduplicação da importação |
| `2_CONTROLE_ESTOQUE` | Ledger completo (~413 registros com dados + ~2.580 linhas de detalhe) com cada transação, setor, uso, área, CEPACs e processo SEI | **Fonte primária da Carga Inicial** |
| `3_controle_certidoes` | 35 certidões recentes (2024–2026) com tipo, data, proposta e número | Módulo de Consulta Pública de Autenticidade |
| `4_resumo_propostas` | 251 propostas com todas as certidões vinculadas (histórico de emendas) | Carga de propostas em análise (EM_ANALISE) |
| `METADADOS` | Dicionário de dados com descrição de cada coluna | Referência para o script de importação |
| `lista_suspensa` | Listas de valores válidos para dropdowns | Validação dos enums do sistema |

### Estrutura dos Registros em `2_CONTROLE_ESTOQUE`

Colunas relevantes para a importação:

| Coluna | Campo DB mapeado |
|--------|-----------------|
| `CODIGO` | `titulo_cepac.codigo` |
| `PA (16 digitos)` | `titulo_cepac.numero_processo_sei` (padrão novo) |
| `DATA AUTUACAO PA` | `titulo_cepac.created_at` (data original) |
| `STATUS PA` | Determina estado: DEFERIDO→CONSUMIDO, ANALISE→EM_ANALISE |
| `INTERESSADO` | `solicitacao_vinculacao.interessado` (campo novo — ver T10) |
| `CNPJ` / `CPF` | `solicitacao_vinculacao.cnpj_cpf` |
| `ENDEREÇO` | `solicitacao_vinculacao.endereco` |
| `SETOR OUC` | `titulo_cepac.setor_id` (FK via nome) |
| `REQUERIMENTO` | `movimentacao.motivo` (VINCULACAO, ALTERACAO, DESVINCULACAO) |
| `USO DA ACA` | `titulo_cepac.uso` (R / NR / MISTO→split) |
| `ACA-R` + `ACA-NR` | `titulo_cepac.valor_m2` por tipo |
| `NUVEM m² - R` + `NUVEM m² -nR` | origem=NUVEM na importação |
| `CERTIDAO` | `certidao.numero_certidao` |
| `SITUACAO` | VALIDA → ativo; CANCELADA → inativo |
| `DATA CERTIDAO` | `certidao.data_emissao` |

### Classificação dos 413 Registros Reais

| Status PA | Situação | Requerimento | Qtd | Estado no sistema |
|-----------|----------|--------------|-----|-------------------|
| DEFERIDO | VALIDA | VINCULACAO | 180 | **CONSUMIDO** |
| DEFERIDO | VALIDA | ALTERACAO | 51 | **CONSUMIDO** (emenda a proposta existente) |
| DEFERIDO | VALIDA | DESVINCULACAO | 19 | **QUARENTENA** ou DISPONIVEL (≥ 180 dias) |
| DEFERIDO | CANCELADA | VINCULACAO/ALTER | 142 | Ignorado na importação (histórico) |
| ANALISE | ANALISE | DESVINCULACAO | 5 | **EM_ANALISE** |
| ANALISE | ANALISE | ALTERACAO | 3 | **EM_ANALISE** |
| ANALISE | ANALISE | VINCULACAO | 1 | **EM_ANALISE** |
| ANALISE | VALIDA | ALTERACAO | 1 | **CONSUMIDO** |
| INDEFERIDO | CANCELADA | * | 10 | Ignorado |

**Registros que entram no banco: 260** (231 CONSUMIDO + 19 QUARENTENA/DISPONIVEL + 10 EM_ANALISE)

---

## ⚠️ Discrepâncias — Seed Fase 1 vs. Planilha XLSX

A planilha revela que os 13 títulos sintéticos da `002_seed_abril_2026.sql` contêm erros. A migration de carga real (T11) deve **substituir** o seed sintético.

| Setor | Campo | Seed Fase 1 (sintético) | XLSX (correto) | Ação |
|-------|-------|------------------------|----------------|------|
| Brooklin | ACA_R consumido | 0 (ausente) | **716.469,73 m²** | Adicionar |
| Brooklin | ACA_NR consumido | 716.470,01 m² (ERRADO — era R) | **113.342,09 m²** | Corrigir |
| Brooklin | Em Análise R | 0 | **8.795,18 m²** | Adicionar |
| Marginal Pinheiros | ACA_R consumido | 0 (ausente) | **198.945,31 m²** | Adicionar |
| Marginal Pinheiros | Em Análise R | 0 | **59.398,03 m²** | Adicionar |
| Chucri Zaidan | ACA_NR consumido | 1.050.881,42 m² | 1.050.881,42 m² | ✓ OK |
| Chucri Zaidan | ACA_R consumido | 751.909,09 m² | 751.909,09 m² | ✓ OK |
| CEPACs em circulação | Big Number | 142.268 (briefing verbal) | **193.779** | Corrigir |

> ⚠️ **O seed sintético de Brooklin está com os valores de uso invertidos.** O campo `NR_ACA = 716.470,01` na Fase 1 corresponde na realidade ao consumido **R** (residencial). A planilha é inequívoca: `Consumido ACA R = 716.469,73` e `Consumido ACA NR = 113.342,09`. A migration T11 deve revogar o seed sintético e substituir pelos dados reais.

---

## Big Numbers Corrigidos (fonte: planilha XLSX)

| Indicador | Valor CORRETO | Fonte na planilha |
|-----------|--------------|-------------------|
| Custo Total Incorrido | R$ 3.987.822.642,21 | `medicao_obra` (seed inicial — não alterado) |
| Capacidade Total da Operação | 4.850.000,00 m² | Constante legal (TOTAL PERMITIDO na aba Consolidado) |
| Saldo Geral Disponível | **1.162.000,74 m²** | Linha ESTOQUE GERAL DISPONÍVEL do Consolidado |
| CEPACs em Circulação | **193.779 títulos** | Linha EM CIRCULAÇÃO do Consolidado |

> **Nota:** O Saldo Geral de 1.162.000,74 m² **não desconta o Em Análise** (que seria 0 na posição do Consolidado). O valor exibido no Dashboard deve ser o saldo líquido: `Saldo − Em Análise`, calculado em runtime a partir da tabela `movimentacao`, não da planilha.

---

## Posição Setorial Corrigida (13/04/2026)

| Setor | ACA R consumido | ACA NR consumido | NUVEM R | NUVEM NR | Em Análise R | Em Análise NR | Saldo NR (líq.) |
|-------|----------------|-----------------|---------|----------|-------------|--------------|----------------|
| Brooklin | 716.469,73 | 113.342,09 | 0 | 0 | 8.795,18 | 0 | 866.657,91 |
| Berrini | 134.590,11 | 202.607,23 | 100,62 | 595,00 | 0 | 0 | **0** (BLOQUEADO) |
| Marginal Pinheiros | 198.945,31 | 258.908,19 | 1.301,13 | 0 | 59.398,03 | 11.173,06 | 149.918,75 |
| Chucri Zaidan | 751.909,09 | 1.050.881,42 | 204,70 | 434,79 | 14.006,35 | 0 | **196.634,52** |
| Jabaquara | 7.709,85 | 0 | 0 | 0 | 0 | 0 | 175.000,00 |

> **Diferença Chucri Zaidan:** O saldo NR líquido no XLSX é **196.634,52 m²**, não 182.563,65 como calculado na Fase 1. A diferença decorre do denominador real da fórmula. A planilha é a fonte de verdade — o validator da Fase 1 pode precisar de ajuste de parâmetro.

---

## Alertas Setoriais (Mapa de Travas)

| Setor | Tipo | Condição | Severidade |
|-------|------|---------|-----------|
| Berrini | Estoque NR Esgotado | NR acumulado (203.202,23) > teto (175.000,00) — permanente | 🔴 CRÍTICO |
| Chucri Zaidan | Reserva R Protegida | Monitoramento do isolamento obrigatório de 216.442,47 m² | 🟡 AVISO |
| Chucri Zaidan | Teto NR Iminente | `consumo_total + em_analise > 1.783.557,53 × 0,98` | 🔴 CRÍTICO |
| Qualquer setor | Saldo < 10% | `saldo_disponivel < estoque_total × 0,10` | 🟡 AVISO |

---

## Decisões Arquiteturais — Fase 2

### 1. Validação de Token Azure AD no Backend
Na Fase 1 a API confiava no APIM para validar o JWT (achado T8-1). Na Fase 2 o backend valida a assinatura diretamente via JWKS endpoint.

```
[Frontend React]
      │  Authorization: Bearer <AAD token>
      ▼
[Azure APIM]  ← rate limiting, roteamento de produto
      │
      ▼
[FastAPI — Core Engine]
   validates token via JWKS (keys.microsoft.com)
   extracts: upn, roles (CEPAC.TECNICO | CEPAC.DIRETOR)
```

**Biblioteca:** `python-jose[cryptography]` para validação JWKS.

### 2. Frontend — React + TypeScript + Vite
Stack proposta (a confirmar com equipe Prodam):
- **React 18 + TypeScript** — SPA com roteamento por papel
- **Vite** — build tool, compatível com Azure Static Web Apps
- **MSAL React (`@azure/msal-react`)** — autenticação Azure AD
- **Recharts** — gráficos de barra e gauge do prazo 2029

### 3. Atualização em Tempo Real — Polling 60s
Dashboard consulta `/dashboard/snapshot` a cada 60 segundos. WebSockets desnecessários para o volume da OUCAE; upgrade para SSE disponível na Fase 3.

### 4. Documentos — Azure Blob Storage com SAS Tokens
Arquivo físico nunca transita pelo backend — upload direto ao Blob via SAS URL (TTL 30min upload, 1h download).

### 5. Carga Inicial — Python Script + SQL Migration
A importação real usa um script Python que lê o XLSX linha a linha, valida os dados, e gera a migration `003_carga_inicial.sql`. O script é idempotente (controla duplicatas pelo código da proposta).

---

## Modelo de Dados — Novas Tabelas (Fase 2)

### `proposta` *(nova — representa cada projeto vinculado)*
| Campo | Tipo | Descrição |
|---|---|---|
| id | UUID PK | |
| codigo | VARCHAR(20) UNIQUE NOT NULL | Código da proposta (ex: `AE-0002`) |
| numero_pa | VARCHAR(50) | Número do processo administrativo (padrão novo: `7810.0000/0000000-0`) |
| data_autuacao | DATE | Data de autuação do PA |
| status_pa | ENUM('DEFERIDO','INDEFERIDO','ANALISE') | Status atual do PA |
| interessado | VARCHAR(300) | Nome do empreendedor |
| cnpj_cpf | VARCHAR(20) | CNPJ ou CPF |
| endereco | TEXT | Endereço do empreendimento |
| setor_id | UUID FK → setor | |
| requerimento | ENUM('VINCULACAO','ALTERACAO','DESVINCULACAO') | |
| area_terreno | NUMERIC(15,2) | Área do terreno em m² |
| created_at | TIMESTAMP | |
| updated_at | TIMESTAMP | |

### `certidao`
| Campo | Tipo | Descrição |
|---|---|---|
| id | UUID PK | |
| proposta_id | UUID FK → proposta | Proposta à qual pertence |
| numero_certidao | VARCHAR(20) UNIQUE NOT NULL | Ex: `AE-001/2024`, `DV-001/2026` |
| tipo | ENUM('VINCULAÇÃO','DESVINCULAÇÃO','ALTERAÇÃO') | |
| data_emissao | DATE | |
| numero_processo_sei | VARCHAR(50) | SEI do processo |
| situacao | ENUM('VALIDA','CANCELADA') DEFAULT 'VALIDA' | |
| created_at | TIMESTAMP | Imutável |

> **Módulo de Consulta Pública:** `certidao` é consultável sem autenticação pelo número da certidão. Permite ao munícipe verificar autenticidade.

### `usuario`
| Campo | Tipo | Descrição |
|---|---|---|
| id | UUID PK | |
| upn | VARCHAR(200) UNIQUE NOT NULL | User Principal Name (Azure AD) |
| nome | VARCHAR(200) | |
| papel | ENUM('TECNICO','DIRETOR') | Role do AAD |
| ativo | BOOLEAN DEFAULT true | |
| created_at | TIMESTAMP | |
| last_login_at | TIMESTAMP | Atualizado a cada autenticação |

### `documento_processo`
| Campo | Tipo | Descrição |
|---|---|---|
| id | UUID PK | |
| proposta_id | UUID FK → proposta | |
| numero_processo_sei | VARCHAR(50) NOT NULL | |
| nome_arquivo | VARCHAR(500) NOT NULL | |
| blob_path | VARCHAR(1000) NOT NULL | Caminho no Azure Blob |
| content_type | VARCHAR(100) | |
| tamanho_bytes | BIGINT | |
| operador_id | UUID FK → usuario | |
| created_at | TIMESTAMP | Imutável |

### `medicao_obra` *(append-only)*
| Campo | Tipo | Descrição |
|---|---|---|
| id | UUID PK | |
| data_referencia | DATE NOT NULL UNIQUE | Primeiro dia do mês |
| valor_medicao | NUMERIC(18,2) NOT NULL | Valor mensal em R$ |
| valor_acumulado | NUMERIC(18,2) NOT NULL | Custo total incorrido após esta medição |
| descricao | TEXT | |
| numero_processo_sei | VARCHAR(50) NOT NULL | |
| operador_id | UUID FK → usuario | |
| created_at | TIMESTAMP | Append-only |

### `parametro_sistema`
| Campo | Tipo | Descrição |
|---|---|---|
| chave | VARCHAR(100) PK | Ex: `cepacs_em_circulacao`, `data_inicio_oucae` |
| valor | TEXT | |
| updated_at | TIMESTAMP | |
| operador_id | UUID FK → usuario | |

---

## Velocímetro de Prazo 2029

```
Início da OUCAE: a confirmar (referência proposta: 2004-01-01 — data 1ª certidão AE-001/2004)
Encerramento:    2029-12-31
% decorrido = (hoje − início) / (2029-12-31 − início) × 100
Zona verde:  0% – 60%   |   Zona amarela: 60% – 85%   |   Zona vermelha: 85% – 100%
```

---

## Ordem de Execução das Tasks

```
T10 (Schema Fase 2)
  ├─► T11 (Carga Inicial Real — Import XLSX) ──────────────────────────────────┐
  ├─► T12 (Auth Azure AD) ─────────────────────────────────────────────────┐   │
  │         ├─► T15 (Portal Backend) ───────────────► T18 (Frontend Portal) │   │
  │         └─► T16 (Dashboard Backend) ──────────► T19 (Frontend Dashboard)│   │
  ├─► T13 (Blob Storage) ──────────────────────────► T15                    │   │
  ├─► T14 (Consulta Pública) ── depende de T11 ───────────────────────────┘ │   │
  └─► T17 (Financeiro/Medições) ──────────────────► T16                     │   │
                                                                              ▼   ▼
                                                                         T20 (Testes)
                                                                              ▼
                                                                         T21 (DevOps)
```

**Paralelismos possíveis após T10:**
- T11, T12, T13, T17 → em paralelo (independentes entre si)
- T14 → após T11 (precisa dos dados carregados)
- T15 → após T12 **e** T13
- T16 → após T12 **e** T17
- T18, T19 → em paralelo após T15 e T16 respectivamente
- T20 → após T18 **e** T19

---

## Tasks Técnicas

---

### T10 — Schema do Banco de Dados — Fase 2
**Agente:** `@agent-python-expert`
**Depende de:** T9 concluída

**Objetivo:** Estender o schema PostgreSQL com as tabelas da Fase 2 sem alterar nenhuma tabela existente da Fase 1.

**Entregáveis:**
- `migrations/003_fase2_schema.sql` — criação das novas tabelas e ENUMs
- `src/core/models/proposta.py`, `certidao.py`, `usuario.py`, `documento_processo.py`, `medicao_obra.py`
- Atualização de `src/core/models/__init__.py`

**Tabelas obrigatórias e seus índices:**

| Tabela | Índices críticos |
|--------|-----------------|
| `proposta` | `UNIQUE(codigo)`, `INDEX(setor_id, status_pa)` |
| `certidao` | `UNIQUE(numero_certidao)`, `INDEX(proposta_id)`, `INDEX(situacao, tipo)` |
| `usuario` | `UNIQUE(upn)` |
| `documento_processo` | `INDEX(proposta_id)` |
| `medicao_obra` | `UNIQUE(data_referencia)`, `INDEX(data_referencia DESC)` |
| `parametro_sistema` | PK = `chave` |

**Constraints obrigatórias:**
- Trigger `fn_medicao_obra_immutable()` — bloqueia `UPDATE`/`DELETE` em `medicao_obra` (idêntico ao de `movimentacao`)
- Trigger `fn_documento_immutable()` — bloqueia `DELETE` em `documento_processo`
- `certidao.created_at` imutável (sem trigger necessário — API nunca oferece endpoint de modificação)
- Migration idempotente com `CREATE TABLE IF NOT EXISTS` e `DO $$ BEGIN CREATE TYPE ... EXCEPTION WHEN duplicate_object THEN null; END $$`

**Critérios de aceite:**
- `\d proposta` no psql mostra todas as colunas e constraints
- `migrations/002_seed_abril_2026.sql` ainda executa sem erro (tabelas Fase 1 intactas)
- Nenhuma coluna de saldo calculado nas novas tabelas

---

### T11 — Carga Inicial Real — Importação da Planilha XLSX
**Agente:** `@agent-python-expert`
**Depende de:** T10 concluída

**Objetivo:** Substituir os 13 títulos sintéticos da `002_seed_abril_2026.sql` pelos ~260 registros reais da planilha XLSX. É a task mais crítica da Fase 2 — o banco de dados fica com o Ledger real da operação a partir daqui.

**Entregáveis:**
- `scripts/importar_planilha.py` — script Python que lê o XLSX e gera a migration SQL
- `migrations/004_carga_inicial_real.sql` — output do script, revisado e aprovado pelo Tech Lead antes de executar em produção
- `migrations/004a_revogar_seed_sintetico.sql` — remove os registros SEED-* inseridos pela migration 002 antes de inserir os reais

**Estratégia de importação (script `importar_planilha.py`):**

```python
# Pseudocódigo do script
def importar(xlsx_path: str) -> str:
    """Gera SQL de importação."""
    wb = openpyxl.load_workbook(xlsx_path, data_only=True)
    ws = wb['2_CONTROLE_ESTOQUE']

    sql_output = []
    sql_output.append("BEGIN;")

    for row in ws.iter_rows(values_only=True):
        if not row[0] or not row[4]:
            continue  # linha vazia ou sem CODIGO/STATUS

        codigo    = row[0]           # CODIGO da proposta
        status_pa = row[4].strip()   # DEFERIDO | ANALISE | INDEFERIDO
        situacao  = row[24].strip() if row[24] else ''  # VALIDA | CANCELADA | ANALISE
        req       = row[10].strip() if row[10] else ''  # VINCULACAO | ALTERACAO | DESVINCULACAO

        if status_pa == 'INDEFERIDO':
            continue  # nunca entra no sistema

        if status_pa == 'DEFERIDO' and situacao == 'CANCELADA':
            continue  # histórico — não entra

        estado = mapear_estado(status_pa, situacao, req, data_certidao=row[25])
        # estado pode ser: CONSUMIDO, EM_ANALISE, QUARENTENA, DISPONIVEL

        # Gerar INSERT proposta
        sql_output.append(gerar_sql_proposta(row))

        # Gerar INSERT certidao se houver
        if row[23]:
            sql_output.append(gerar_sql_certidao(row))

        # Gerar INSERTs de titulo_cepac (um por uso×origem com valor > 0)
        for uso, origem, valor_m2 in extrair_areas(row):
            sql_output.append(gerar_sql_titulo(codigo, setor, uso, origem, valor_m2, estado))
            sql_output.append(gerar_sql_movimentacao(titulo_codigo, estado, row))

    sql_output.append("COMMIT;")
    return '\n'.join(sql_output)
```

**Regras de mapeamento de estado:**

| STATUS PA | SITUAÇÃO | REQUERIMENTO | Estado no sistema |
|-----------|---------|--------------|-------------------|
| DEFERIDO | VALIDA | VINCULACAO | CONSUMIDO |
| DEFERIDO | VALIDA | ALTERACAO | CONSUMIDO |
| DEFERIDO | VALIDA | DESVINCULACAO | QUARENTENA (se `data_certidao + 180 dias > hoje`) ou DISPONIVEL |
| ANALISE | ANALISE | VINCULACAO | EM_ANALISE |
| ANALISE | ANALISE | ALTERACAO | EM_ANALISE |
| ANALISE | ANALISE | DESVINCULACAO | EM_ANALISE |
| ANALISE | VALIDA | ALTERACAO | CONSUMIDO |

**Regras de extração de áreas (uma linha pode gerar múltiplos títulos):**

| Caso | Títulos gerados |
|------|----------------|
| `USO = 'R'` com `ACA-R > 0` | 1 título: uso=R, origem=ACA |
| `USO = 'NR'` com `ACA-NR > 0` | 1 título: uso=NR, origem=ACA |
| `USO = 'MISTO'` com ambos > 0 | 2 títulos: R+ACA e NR+ACA |
| `NUVEM m² - R > 0` | +1 título: uso=R, origem=NUVEM |
| `NUVEM m² -nR > 0` | +1 título: uso=NR, origem=NUVEM |

**Remoção do seed sintético (`004a_revogar_seed_sintetico.sql`):**
```sql
BEGIN;
-- Remove movimentações dos títulos sintéticos
DELETE FROM movimentacao
WHERE titulo_id IN (
    SELECT id FROM titulo_cepac WHERE codigo LIKE 'SEED-%'
);
-- Remove os títulos sintéticos
DELETE FROM titulo_cepac WHERE codigo LIKE 'SEED-%';
COMMIT;
```

**Validação pós-importação (assertions obrigatórias no script):**
```python
# Após gerar o SQL, o script deve calcular e imprimir para conferência:
# Brooklin: R=716469.73, NR=113342.09 (comparar com Consolidado)
# Berrini:  R=134590.11+100.62, NR=202607.23+595.00
# Marginal: R=198945.31+1301.13, NR=258908.19
# Chucri:   R=751909.09+204.70, NR=1050881.42+434.79
# Jabaquara: R=7709.85
```

**Critérios de aceite:**
- Após execução de `004a` + `004`: `SELECT COUNT(*) FROM titulo_cepac WHERE codigo LIKE 'SEED-%'` retorna 0
- `GET /saldo/Brooklin` retorna `consumido_r = 716469.73`, `consumido_nr = 113342.09`
- `GET /saldo/Berrini` retorna `saldo_nr = 0` e `bloqueado = true`
- `GET /saldo/Chucri Zaidan` retorna `saldo_nr ≈ 196634.52`
- Nenhuma linha duplicada por `(proposta_id, uso, origem)` para o mesmo registro

---

### T12 — Autenticação Azure AD — Validação Real de Token
**Agente:** `@agent-python-expert`
**Depende de:** T10 concluída (paralelo com T11, T13, T17)

**Objetivo:** Substituir a confiança implícita no APIM (achado T8-1) pela validação real da assinatura JWT via JWKS. Criar sistema de roles `TECNICO`/`DIRETOR`.

**Entregáveis:**
- `src/api/auth/azure_ad.py` — validação JWKS + extração de `upn`/`roles`, cache de 1h
- `src/api/auth/dependencies.py` — `get_current_user()`, `require_tecnico()`, `require_diretor()`
- Atualização de `src/api/dependencies.py` — substituir `get_operador()` pelo novo `get_current_user()`
- `src/config.py` — novos campos: `azure_ad_tenant_id`, `azure_ad_client_id`

**Interface das dependências FastAPI:**
```python
@dataclass(frozen=True)
class UsuarioAutenticado:
    upn: str            # joao.silva@spurbanismo.sp.gov.br
    nome: str
    roles: list[str]    # ["CEPAC.TECNICO"] | ["CEPAC.DIRETOR"]
    token_exp: datetime

async def get_current_user(token: str = Depends(oauth2_scheme)) -> UsuarioAutenticado: ...
async def require_tecnico(user = Depends(get_current_user)) -> UsuarioAutenticado: ...
async def require_diretor(user = Depends(get_current_user)) -> UsuarioAutenticado: ...
```

**Fluxo de validação:**
1. Extrai `Bearer <token>` do header `Authorization`
2. GET JWKS endpoint (`https://login.microsoftonline.com/{tenant_id}/discovery/v2.0/keys`) — cacheado 1h
3. Valida assinatura, `aud` (client_id), `iss` (tenant), expiração
4. Extrai `upn`, `name`, `roles` do payload
5. Upsert em `usuario` — cria se novo, atualiza `last_login_at`
6. Token inválido/expirado → `HTTPException(401)` (**nunca degrada para "desconhecido"**)

**Critérios de aceite:**
- JWT malformado → 401 (corrige achado T8-1 da Fase 1)
- JWT sem role `CEPAC.*` → 403
- JWT expirado → 401
- JWKS não consultado a cada request (cache válido por 1h)
- `upn` e `last_login_at` atualizados a cada login bem-sucedido

---

### T13 — Módulo de Documentos — Azure Blob Storage
**Agente:** `@agent-python-expert`
**Depende de:** T10 concluída (paralelo com T11, T12, T17)

**Objetivo:** Upload e download de documentos via SAS tokens. O arquivo nunca transita pelo backend.

**Entregáveis:**
- `src/core/storage/blob_client.py` — wrapper do SDK Azure Blob com `gerar_sas_upload()` e `gerar_sas_download()`
- `src/api/routes/documentos.py` — endpoints `/documentos/upload-url`, `/documentos/{id}/download-url`, `GET /documentos`
- `src/api/schemas/documento.py`
- `src/config.py` — `azure_blob_account_name`, `azure_blob_container_name`

**Fluxo de upload (arquivo nunca passa pelo backend):**
```
POST /documentos/upload-url { proposta_id, nome_arquivo, content_type }
  → API gera blob_path = "{ano}/{mes}/{uuid}-{nome_arquivo}"
  → API gera SAS URL de escrita (TTL 30min)
  → API insere metadados em documento_processo (tombstone antes do upload)
  → Response: { documento_id, sas_url_upload }
  → Frontend faz PUT direto no Blob com a SAS URL
GET /documentos/{id}/download-url
  → API gera SAS URL de leitura (TTL 1h)
```

**Critérios de aceite:**
- SAS de upload expira em 30min; download em 1h
- MIME types permitidos: PDF, DOCX, XLSX, JPG, PNG (422 para outros)
- Tamanho máximo: 50 MB (validado pelo SDK antes de gerar SAS)
- Nenhuma credencial Blob hardcoded

---

### T14 — Consulta Pública de Autenticidade
**Agente:** `@agent-fastapi-expert`
**Depende de:** T11 concluída (precisa dos dados da ABA 3 carregados)

**Objetivo:** Permitir ao munícipe verificar a autenticidade de certidões emitidas pela SP Urbanismo, sem necessidade de autenticação.

**Entregáveis:**
- `src/api/routes/certidoes.py` — endpoints públicos (sem `Depends(get_current_user)`)
- `src/api/schemas/certidao.py`
- `src/core/repositories/certidao_repository.py`

**Endpoints:**

| Método | Rota | Auth | Descrição |
|--------|------|------|-----------|
| `GET` | `/certidoes/{numero}` | ❌ Público | Busca certidão por número (ex: `AE-001/2024`); retorna dados de autenticidade |
| `GET` | `/certidoes` | ❌ Público | Lista certidões com filtros: `tipo`, `ano`, `situacao` |
| `GET` | `/certidoes/{numero}/proposta` | ✅ TECNICO | Retorna os dados completos da proposta vinculada à certidão |

**Schema de resposta `GET /certidoes/{numero}` (público):**
```python
class CertidaoPublicaOut(BaseModel):
    numero_certidao: str           # "AE-001/2024"
    tipo: str                      # "VINCULAÇÃO"
    data_emissao: Optional[date]
    situacao: str                  # "VALIDA" | "CANCELADA"
    proposta_codigo: str           # "AE-0183"
    setor: str                     # "BROOKLIN"
    # Dados omitidos por privacidade: interessado, CNPJ, endereço
    autenticidade: Literal["CERTIDÃO AUTÊNTICA", "CERTIDÃO CANCELADA", "CERTIDÃO NÃO ENCONTRADA"]
```

> **Privacidade:** O endpoint público **não expõe** `interessado`, `CNPJ/CPF` ou `endereço`. Apenas confirma a autenticidade e dados públicos da certidão.

**Critérios de aceite:**
- `GET /certidoes/AE-001/2024` retorna `autenticidade: "CERTIDÃO AUTÊNTICA"` (sem token)
- `GET /certidoes/AE-999/9999` retorna 404 com `autenticidade: "CERTIDÃO NÃO ENCONTRADA"`
- `GET /certidoes/AE-002/2024` retorna `autenticidade: "CERTIDÃO CANCELADA"` (linha CANCELADA da ABA 3)
- Endpoint público não requer header `Authorization`
- CNPJ/CPF não exposto em nenhum campo do response público

---

### T15 — Portal de Operações Técnicas — Backend
**Agente:** `@agent-fastapi-expert`
**Depende de:** T12 e T13 concluídas

**Objetivo:** Endpoints para técnicos cadastrarem solicitações recebidas via e-mail, vincularem processos SEI, selecionarem títulos e anexarem documentos.

**Entregáveis:**
- `src/api/routes/portal.py`
- `src/api/schemas/portal.py`
- `src/core/repositories/portal_repository.py`

**Endpoints:**

| Método | Rota | Role | Descrição |
|--------|------|------|-----------|
| `POST` | `/portal/solicitacoes` | TECNICO | Cadastra nova solicitação; executa `RulesEngine.validar()`; retorna aprovado/erro |
| `GET` | `/portal/solicitacoes` | TECNICO, DIRETOR | Lista paginada com filtros (setor, status, uso, origem, datas) |
| `GET` | `/portal/solicitacoes/{id}` | TECNICO, DIRETOR | Detalhe com documentos e histórico completo |
| `PATCH` | `/portal/solicitacoes/{id}/cancelar` | TECNICO | Cancela PENDENTE; libera títulos EM_ANALISE |
| `GET` | `/portal/titulos` | TECNICO | Lista títulos DISPONIVEL por setor/uso/origem |
| `GET` | `/portal/propostas/{codigo}` | TECNICO, DIRETOR | Busca proposta real por código (ex: `AE-0183`) |

**Campos do formulário `SolicitacaoPortalIn`:**
```python
class SolicitacaoPortalIn(BaseModel):
    setor: str
    uso: Literal["R", "NR"]
    origem: Literal["ACA", "NUVEM"]
    area_m2: Decimal
    numero_processo_sei: str   # regex validado — corrige achado T8-2
    titulo_ids: list[UUID]
    proposta_codigo: Optional[str]  # vínculo opcional à proposta existente
    observacao: Optional[str]
```

**Validação do SEI (corrige achado T8-2 da Fase 1):**
```python
@field_validator("numero_processo_sei")
def validar_sei(cls, v):
    # Padrão novo: "7810.0000/0000000-0"
    # Padrão antigo: "0000-0.000.000-0"
    # Ambos aceitos — confirmar regex exata com SP Urbanismo
    import re
    pattern_novo = r"^\d{4}\.\d{4}/\d{7}-\d$"
    pattern_antigo = r"^\d{4}-\d\.\d{3}\.\d{3}-\d$"
    if not (re.match(pattern_novo, v) or re.match(pattern_antigo, v)):
        raise ValueError("Formato de processo SEI inválido")
    return v
```

**Critérios de aceite:**
- `POST /portal/solicitacoes` registra `upn` do usuário em `movimentacao.operador`
- Cancelamento de APROVADA → 422 `SOLICITACAO_NAO_CANCELAVEL`
- Cancelamento de PENDENTE libera todos os títulos EM_ANALISE do lote
- Listagem retorna `{ items, total, page, page_size, total_pages }`
- `GET /portal/titulos` retorna apenas DISPONIVEL

---

### T16 — APIs do Dashboard Executivo — Backend
**Agente:** `@agent-fastapi-expert`
**Depende de:** T12 e T17 concluídas

**Objetivo:** Endpoints que o Dashboard consome: big numbers, ocupação setorial, alertas, velocímetro e snapshot histórico point-in-time.

**Entregáveis:**
- `src/api/routes/dashboard.py`
- `src/api/schemas/dashboard.py`
- `src/core/repositories/dashboard_repository.py`

**Endpoints:**

| Método | Rota | Role | Descrição |
|--------|------|------|-----------|
| `GET` | `/dashboard/snapshot` | TECNICO, DIRETOR | Todos os indicadores em uma resposta (polling 60s) |
| `GET` | `/dashboard/snapshot?data=YYYY-MM-DD` | DIRETOR | Reconstrução histórica — estado do dashboard em data passada |
| `GET` | `/dashboard/setores` | TECNICO, DIRETOR | Ocupação por setor (dados para gráfico de barras) |
| `GET` | `/dashboard/alertas` | TECNICO, DIRETOR | Travas ativas por setor |
| `GET` | `/dashboard/medicoes` | DIRETOR | Série histórica de medições (custo mensal) |

**Schema `DashboardSnapshotOut`:**
```python
class DashboardSnapshotOut(BaseModel):
    gerado_em: datetime

    # Big Numbers (corrigidos via XLSX)
    custo_total_incorrido: Decimal          # R$ 3.987.822.642,21
    capacidade_total_operacao: Decimal       # 4.850.000,00 m²
    saldo_geral_disponivel: Decimal          # derivado de movimentacao (exclui Em Análise)
    cepacs_em_circulacao: int                # 193.779 (de parametro_sistema)

    prazo_percentual_decorrido: float        # 0.0 – 100.0
    prazo_dias_restantes: int
    prazo_zona: Literal["VERDE", "AMARELO", "VERMELHO"]

    alertas: list[AlertaSetorialOut]
    setores: list[OcupacaoSetorOut]
```

**Schema `OcupacaoSetorOut` (dados para gráfico de barras):**
```python
class OcupacaoSetorOut(BaseModel):
    nome: str
    estoque_total: Decimal
    consumido_r: Decimal
    consumido_nr: Decimal
    em_analise_r: Decimal
    em_analise_nr: Decimal
    disponivel: Decimal              # estoque_total - consumido_total - em_analise_total
    percentual_ocupado: float
    teto_nr: Optional[Decimal]
    saldo_nr_liquido: Optional[Decimal]   # descontado Em Análise NR
    bloqueado_nr: bool
```

**Critérios de aceite:**
- Resposta em < 500ms (índices de `movimentacao` garantem isso)
- Snapshot histórico `?data=2025-01-01` retorna os mesmos valores de `GET /saldo/{setor}?data=2025-01-01`
- Berrini aparece `bloqueado_nr=true`
- `cepacs_em_circulacao` = 193.779 após a carga inicial real

---

### T17 — Rastreabilidade Financeira — Medições de Obras
**Agente:** `@agent-python-expert`
**Depende de:** T10 concluída (paralelo com T11, T12, T13)

**Objetivo:** Módulo de entrada mensal de medições que alimenta o "Custo Total Incorrido". Histórico append-only idêntico ao padrão de `movimentacao`.

**Entregáveis:**
- `src/api/routes/medicoes.py`
- `src/api/schemas/medicao.py`
- `src/core/repositories/medicao_repository.py`
- `migrations/005_seed_medicao_inicial.sql` — seed com `data_referencia=2026-04-01, valor_acumulado=3987822642.21`

**Endpoints:**

| Método | Rota | Role | Descrição |
|--------|------|------|-----------|
| `POST` | `/medicoes` | DIRETOR | Registra nova medição; calcula `valor_acumulado` automaticamente |
| `GET` | `/medicoes` | DIRETOR, TECNICO | Histórico ordenado por `data_referencia DESC` |
| `GET` | `/medicoes/atual` | DIRETOR, TECNICO | Custo Total Incorrido atual |

**Critérios de aceite:**
- `valor_acumulado` calculado pela aplicação (nunca enviado pelo cliente)
- Duplicata de `data_referencia` → 422
- `GET /medicoes/atual` retorna `valor_acumulado = R$ 3.987.822.642,21` após seed

---

### T18 — Frontend — Portal de Operações Técnicas (React)
**Agente:** `@agent-frontend-expert`
**Depende de:** T15 concluída

**Objetivo:** Interface web para técnicos cadastrarem solicitações com autenticação MSAL, seleção de títulos, upload de documentos e listagem paginada.

**Entregáveis:**
- `frontend/portal/` — React + TypeScript + Vite
- Páginas: Login (MSAL), Nova Solicitação, Lista Solicitações, Detalhes
- Componente: UploadDocumento (PUT direto no Blob via SAS URL)
- `src/api/client.ts` — cliente HTTP com token Bearer injetado

**Fluxo principal do técnico:**
```
1. Login via MSAL → token salvo em sessionStorage
2. Seleciona setor, uso, origem → carrega títulos DISPONIVEL
3. Seleciona lote de títulos
4. Preenche número SEI (validação de formato no frontend)
5. Upload de documento PDF/DOCX: POST /upload-url → PUT direto no Blob
6. Submete: POST /portal/solicitacoes → exibe resultado
```

**Mensagens de erro por código:**

| Código | Mensagem |
|--------|---------|
| `TETO_NR_EXCEDIDO` | "Setor Berrini: estoque NR esgotado. Pedidos NR não podem ser processados." |
| `RESERVA_R_VIOLADA` | "Setor Chucri Zaidan: pedido NR invadiria a reserva residencial protegida." |
| `QUARENTENA_ATIVA` | "Título em quarentena — disponível em {dias_restantes} dias." |
| `NUMERO_SEI_OBRIGATORIO` | "Informe o número do processo SEI antes de enviar." |

**Critérios de aceite:**
- Usuário sem role `CEPAC.*` → página de acesso negado
- Upload > 50 MB → erro antes de chamar API
- Token expirado → redireciona para login sem perder formulário
- Listagem paginada com Anterior/Próxima

---

### T19 — Frontend — Dashboard Executivo (React)
**Agente:** `@agent-frontend-expert`
**Depende de:** T16 concluída (paralelo com T18)

**Objetivo:** Painel executivo com big numbers corrigidos, gráficos de barra setorial, velocímetro 2029, mapa de alertas e snapshot histórico.

**Entregáveis:**
- `frontend/dashboard/` — React + TypeScript + Vite
- Componentes: BigNumbers, GraficoOcupacao, VelocimetroProzo, MapaAlertas, SeletorData
- Hook: `useSnapshot(dataHistorica?)` — polling 60s em tempo real, fetch único em histórico

**Big Numbers (valores corretos após T11):**

| Cartão | Valor pós-carga real | Subtítulo |
|--------|---------------------|-----------|
| Custo Total Incorrido | R$ 3.987.822.642,21 | "Obras e intervenções acumuladas" |
| Capacidade da Operação | 4.850.000,00 m² | "Teto máximo legal OUCAE" |
| Saldo Geral Disponível | calculado em runtime | "Exclui reservas temporárias (48h)" |
| CEPACs em Circulação | **193.779 títulos** | "Estoque disponível para negociação" |

**Gráfico de Barras (Recharts `BarChart`):**
- 3 séries por setor: Consumido (azul), Em Análise (laranja), Disponível (verde)
- Linha horizontal tracejada: teto máximo
- Brooklin exibe R e NR separados (ambos têm volume significativo)

**Mapa de Alertas:**
- 🔴 Berrini: "Estoque NR Esgotado — 202.607,23 m² acima do teto de 175.000,00 m²"
- 🟡 Chucri Zaidan: "Reserva R protegida: 196.634,52 m² disponíveis para NR"

**Snapshot histórico:**
- Date picker → `GET /dashboard/snapshot?data=YYYY-MM-DD`
- Banner: "Visualizando estado de {data} — dados históricos, não tempo real"
- Botão "Voltar ao tempo real"

**Critérios de aceite:**
- Polling 60s sem memory leak (clearInterval no cleanup)
- `cepacs_em_circulacao` = 193.779 (não 142.268)
- Berrini aparece como CRÍTICO em qualquer data após 2025
- Responsivo para 1280px+

---

### T20 — Testes — Fase 2 ✅ CONCLUÍDA (16/04/2026)
**Agente:** `@agent-testing-expert`
**Depende de:** T18 e T19 concluídas

**Objetivo:** Cobrir os novos módulos com testes de integração (backend) e unitários.

**Entregáveis:**
- `tests/integration/test_carga_inicial.py` — validar que totais por setor batem com o Consolidado da planilha
- `tests/integration/test_auth.py` — JWKS mockado, roles, 401/403
- `tests/integration/test_certidoes.py` — consulta pública sem token, privacidade CNPJ
- `tests/integration/test_portal.py` — solicitação com usuário autenticado, cancelamento, paginação
- `tests/integration/test_dashboard.py` — snapshot atual/histórico, alertas Berrini, CEPACs=193779
- `tests/integration/test_medicoes.py` — append-only, cálculo acumulado, duplicate constraint
- `tests/unit/test_t10_auth_roles.py` — roles sem banco
- `tests/unit/test_t11_mapeamento_xlsx.py` — mapeamento estado (DEFERIDO+VALIDA→CONSUMIDO, etc.)
- `tests/unit/test_t12_prazo_2029.py` — cálculo percentual e zona

**Cenários obrigatórios:**

| ID | Cenário | Tipo |
|----|---------|------|
| T10 | Carga real: `consumido_nr_brooklin = 113342.09` (não 716470.01 do seed sintético) | Integration |
| T11 | Token sem role → 403; expirado → 401; JWKS cacheado | Unit |
| T12 | SAS upload TTL 30min; download TTL 1h | Unit (mock) |
| T13 | `GET /certidoes/AE-001/2024` sem token → 200 com `autenticidade=CERTIDÃO AUTÊNTICA` | Integration |
| T14 | `GET /certidoes/AE-002/2024` → `CERTIDÃO CANCELADA`; CNPJ ausente no response | Integration |
| T15 | Snapshot histórico 2025-01-01 bate com `/saldo/Berrini?data=2025-01-01` | Integration |
| T16 | `GET /dashboard/snapshot` → `cepacs_em_circulacao = 193779` | Integration |
| T17 | Nova medição: `valor_acumulado = anterior + nova`; duplicata de data → 422 | Integration |

**Critérios de aceite:**
- PostgreSQL real via testcontainers (sem mocks de banco)
- JWKS e Azure Blob mockados (`respx` ou `pytest-httpx`)
- Cobertura ≥ 85% nos novos módulos `src/core/` da Fase 2

---

### T21 — DevOps — Fase 2 ✅ CONCLUÍDA (16/04/2026)
**Agente:** `@agent-devops-cicd-expert`
**Depende de:** T20 concluída

**Objetivo:** Atualizar infraestrutura para os dois frontends React, Azure Blob Storage e novas variáveis de ambiente.

**Entregáveis:**
- `infra/docker-compose.yml` — atualizado com services `portal` e `dashboard`
- `infra/azure/container-app-portal.yaml` — manifesto do Portal
- `infra/azure/container-app-dashboard.yaml` — manifesto do Dashboard
- `infra/azure/storage.bicep` — container Blob `cepac-documentos`
- `.github/workflows/ci.yml` — atualizado: `npm ci + npm run build` para cada frontend
- `migrations/005_seed_medicao_inicial.sql` — seed da medição inicial (R$ 3.987.822.642,21)
- `migrations/006_seed_parametros_sistema.sql` — seed do `parametro_sistema` com `cepacs_em_circulacao=193779`

**Novas variáveis de ambiente:**
```
AZURE_AD_TENANT_ID
AZURE_AD_CLIENT_ID
AZURE_BLOB_ACCOUNT_NAME
AZURE_BLOB_CONTAINER_NAME
DATABASE_URL           ← agora obrigatória (sem default — corrige achado T9-1)
```

**Critérios de aceite:**
- `docker compose up` sobe backend + portal + dashboard + postgres
- Pipeline CI falha se build de qualquer frontend falhar
- Nenhuma credencial hardcoded — todas via GitHub Secrets / Key Vault
- `migrations/007` idempotente via `INSERT ... ON CONFLICT (chave) DO UPDATE`

**Nota de implementação (desvios do spec):**
- Spec mencionava `005_seed_medicao_inicial.sql` e `006_seed_parametros_sistema.sql`.
  Como `005` já foi reservada para `portal_campos` (T15), os números finais são:
  - `006_seed_medicao_inicial.sql` (T17)
  - `007_seed_parametros_sistema.sql` (T21)
- Bicep completo em `infra/bicep/main.bicep` (inclui ACR + Storage + ContainerEnv + 3 apps).
- Dockerfiles de frontend usam nginx:1.27-alpine com config SPA (`infra/nginx-spa.conf`).
- `AZURE_AD_TENANT_ID` / `AZURE_AD_CLIENT_ID` adicionados ao docker-compose.yml via `.env`.
- Container Apps Portal e Dashboard usam East US (resource group `rg_spurbanismo_cepac`).

---

## Resumo das Tasks

| Task | Módulo | Depende de | Paralelo com | Estado |
|------|--------|-----------|--------------|--------|
| T10 | Schema Fase 2 | T9 | — | ✅ concluída |
| T11 | Carga Inicial Real (XLSX) | T10 | T12, T13, T17 | ✅ concluída |
| T12 | Auth Azure AD | T10 | T11, T13, T17 | ✅ concluída |
| T13 | Blob Storage | T10 | T11, T12, T17 | ✅ concluída |
| T14 | Consulta Pública Autenticidade | T11 | T15, T16, T17 | ✅ concluída |
| T15 | Portal Backend | T12 + T13 | T16, T14 | ✅ concluída |
| T16 | Dashboard Backend | T12 + T17 | T15, T14 | ✅ concluída |
| T17 | Financeiro/Medições | T10 | T11, T12, T13 | ✅ concluída |
| T18 | Frontend Portal | T15 | T19 | ✅ concluída |
| T19 | Frontend Dashboard | T16 | T18 | ✅ concluída |
| T20 | Testes Fase 2 | T18 + T19 | — | ✅ concluída |
| T21 | DevOps Fase 2 | T20 | — | ✅ concluída |

**Total de tasks da Fase 2:** 12 (T10–T21)
**Total do projeto (Fase 1 + 2):** 21 tasks

---

## Pontos de Atenção Herdados da Fase 1 — Endereçados

| Achado Fase 1 | Task que resolve |
|---------------|-----------------|
| [T8-1] `get_operador()` degrada para "desconhecido" | **T12** — novo `get_current_user()` com `HTTPException(401)` |
| [T8-2] `numero_processo_sei` sem regex | **T15** — `@field_validator` com regex dos dois padrões SEI |
| [T9-1] `DATABASE_URL` default hardcoded | **T21** — variável obrigatória sem default |

---

## Decisões Técnicas Finalizadas (16/04/2026)

Todas as dúvidas abertas foram respondidas por SP Urbanismo. As decisões abaixo têm impacto direto em T10–T21.

---

### D1 — Frontend: React + TypeScript + Vite ✅
Confirmado. Stack proposta aprovada.

**Impacto:** Nenhum — já estava prevista.

---

### D2 — Campo `numero_processo_sei`: string flexível, dois padrões históricos

**Decisão:** O campo aceita **ambos os formatos** sem bloqueio de validação na importação:
- **SIMPROC** (2004–2015): ex. `2005-0060565-0` — processos da primeira década da operação
- **SEI** (2016–presente): ex. `7810.2025/0001500-9` — padrão obrigatório atual

**Regras por contexto:**

| Contexto | Regra |
|---------|-------|
| Importação histórica (T11) | Aceita ambos sem validação de formato |
| Novos inputs no Portal (T18) | Aceita apenas SEI (`7810.XXXX/XXXXXXX-X`) — erro de validação para SIMPROC |
| Busca e auditoria | Aceita ambos como chave de busca |

**Impacto em T10:** `numero_processo_sei` é `TEXT` (não `VARCHAR` com CHECK constraint de formato).

**Impacto em T11:** Script de importação não rejeita nenhum formato — apenas armazena como string.

**Impacto em T15:** Validator Pydantic com dois padrões aceitos no Portal; UI instrui o técnico a usar o formato SEI para novos pedidos.

---

### D3 — Data de Início da OUCAE: 2004-01-01 ✅

**Decisão:** Marco inicial do Velocímetro 2029 = **2004-01-01** (data do primeiro registro histórico AE-001/2004).

**Fórmula do Velocímetro:**
```
% decorrido = (hoje − 2004-01-01) / (2029-12-31 − 2004-01-01) × 100
Zona verde:    0% – 60%
Zona amarela: 60% – 85%
Zona vermelha: 85% – 100%
```

**Impacto em T16/T19:** Constante `DATA_INICIO_OUCAE = date(2004, 1, 1)` no código e no `parametro_sistema`.

---

### D4 — Roles gerenciados na aplicação, não no Azure AD

**Decisão:** Os papéis `TECNICO` e `DIRETOR` são gerenciados internamente na tabela `usuario` do banco, **não** como App Roles no Azure AD.

**Fluxo de autenticação revisado:**
```
1. JWT validado via JWKS → extrai upn
2. Lookup em usuario WHERE upn = ? → retorna papel
3. Primeiro login: cria usuario com papel='TECNICO' (default)
4. Promoção a DIRETOR: feita por endpoint administrativo (DIRETOR pode promover TECNICO)
```

**Impacto em T12:** `get_current_user()` após validar JWT faz `SELECT papel FROM usuario WHERE upn = ?`. Se usuário não existe ainda → insere com `papel=TECNICO`. Não lê claims de roles do JWT.

**Impacto em T10:** Campo `usuario.papel` é editável por um DIRETOR via endpoint `PATCH /admin/usuarios/{id}/papel`. Adicionar tabela sem `App Role` dependency.

**Impacto em T15:** Novo endpoint `PATCH /admin/usuarios/{id}/papel` — somente DIRETOR. Listagem de usuários `GET /admin/usuarios` — somente DIRETOR.

---

### D5 — Big Numbers: sempre usar valores da planilha XLSX ✅

**Decisão:** A planilha `OUCAE_ESTOQUE_abr_rv01.xlsx` é a fonte de verdade absoluta. Valores verbais anteriores eram aproximações para o sistema não nascer vazio.

**Valores definitivos:**
- CEPACs em Circulação: **193.779** (não 142.268)
- Saldo Geral Disponível: **1.162.000,74 m²** (calculado em runtime — não fixo)

**Impacto em T11:** Seed de `parametro_sistema` usa `cepacs_em_circulacao = 193779`.

---

### D6 — Desvinculações: QUARENTENA com indicador visual de vencimento

**Decisão:** CEPACs desvinculados entram em **QUARENTENA** e permanecem nesse estado até **liberação manual** pelo técnico. O sistema **não muda o estado automaticamente** após 180 dias.

**Comportamento do sistema:**
- Estado: `QUARENTENA` permanente até ação manual
- UI: quando `data_desvinculacao + 180 dias < hoje` → badge visual colorido (ex: badge amarelo "Quarentena vencida — liberação disponível")
- Transição para `DISPONIVEL`: somente via ação explícita do técnico no Portal

**Impacto em T15:** Endpoint `PATCH /portal/cepacs/{id}/liberar-quarentena` (role: TECNICO). Requer confirmação explícita. Registra movimentação com `motivo='LIBERACAO_QUARENTENA'`.

**Impacto em T16/T19:** Dashboard e Portal exibem contagem de "CEPACs em quarentena com liberação disponível" como indicador de atenção.

**Impacto em T11:** As 19 desvinculações `DEFERIDO+VALIDA+DESVINCULACAO` da planilha entram com `estado=QUARENTENA`. O campo `data_desvinculacao` é preenchido com a `DATA CERTIDAO` da linha.

**Revoga a expiração automática do job TTL:** O job de expiração da Fase 1 (`expiry_job.py`) opera apenas sobre `EM_ANALISE → DISPONIVEL`. Quarentena não é afetada pelo TTL.

---

### D7 — Certidões de Alteração: última VALIDA substitui, sem somatório. Excedente vai para NUVEM.

**Decisão:** Uma proposta com múltiplas certidões de alteração usa **apenas a última certidão VALIDA** como área definitiva. Não há somatório entre certidões da mesma proposta.

**Regra de negócio:**

| Cenário | Comportamento |
|---------|--------------|
| Nova área **maior** que certidão anterior | Cliente pagou CEPACs parcialmente — diferença ainda devida. Sistema registra observação. |
| Nova área **menor** que certidão anterior | Excedente de CEPACs vai para `origem=NUVEM` — retido até cliente solicitar desvinculação. |

**Impacto em T11:** Script de importação, ao encontrar múltiplas certidões VALIDA para uma mesma proposta, usa apenas a de `DATA CERTIDAO` mais recente. Calcula o delta com a anterior e, se negativo, cria um CEPAC adicional com `origem=NUVEM`.

**Impacto em T10/T15:** Campo `proposta.observacao_alteracao TEXT` para registrar a situação de diferença devida.

---

### D8 — Marginal Pinheiros: estoque disponível sem restrição de uso após mínimo R atingido

**Decisão:** O setor Marginal Pinheiros já consumiu o mínimo legal de 30% residencial. Portanto, o estoque disponível (149.918,75 m² NR) **pode ser alocado para qualquer uso** — R ou NR — sem restrição adicional.

**Impacto em validator `marginal_pinheiros.py` (Fase 1):** O validator atual bloqueia NR apenas quando `acumulado_NR + solicitacao_NR > 420.000`. Essa lógica continua correta. O que muda é que a checagem de "mínimo R" não precisa ser aplicada porque o piso já foi atingido. Verificar se o validator atual já reflete isso corretamente.

**Impacto no Dashboard (T19):** Exibir nota no card de Marginal Pinheiros: "Mínimo R (30%) atingido — estoque disponível alocável para qualquer uso."

---

### D9 — Terminologia: "CEPAC" no lugar de "título" nas interfaces voltadas ao usuário

**Decisão:** O usuário entende o ativo como **CEPAC**, não como "título". "Título" é termo técnico interno do sistema.

**Regra:**
- **Código interno / banco de dados / logs:** `titulo_cepac`, `titulo_id` — mantidos (padrão Fase 1)
- **Schemas de response da API (campos visíveis ao usuário):** usar `cepac_id`, `cepacs`, `numero_cepac`
- **Frontend Portal e Dashboard:** todas as labels usam "CEPAC"
- **Mensagens de erro:** "CEPAC em quarentena", "Estoque de CEPACs esgotado", etc.

**Impacto em T15/T18/T19:** Schemas Pydantic de response para o Portal adicionam alias `cepac_id = Field(alias='titulo_id')` ou usam campos renomeados no response. Modelos ORM internos não mudam.

---

## Dúvidas em Aberto

Todas as dúvidas originais foram respondidas (ver seção "Decisões Técnicas Finalizadas" acima). Nenhuma pendência bloqueia o início de T10.
