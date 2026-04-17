# Planejamento: Core Engine — Sistema de Controle de Estoque de CEPAC
**SP Urbanismo / Prodam**
**Data:** 2026-04-15
**Versão:** 1.8 — **PROJETO CONCLUÍDO** (16/04/2026) — T1–T9 entregues; revisão de segurança e código aprovadas com ressalvas documentadas

---

## Status de Conclusão (16/04/2026)

**Todas as 9 tasks do Core Engine foram concluídas.** O sistema está aprovado para deploy atrás do Azure APIM com as ressalvas documentadas abaixo.

### Resultado das Revisões Finais

| Revisão | Resultado | Detalhes |
|---------|-----------|----------|
| T8 — Segurança | **Aprovado com ressalvas** (8 CONFORME / 2 PARCIAL) | Ver `docs/seguranca.md` |
| T9 — Código | **Aprovado com ressalvas** (9 CONFORME / 1 PARCIAL) | Ver `docs/revisao-codigo.md` |

### ⚠️ Pontos de Atenção — Obrigatórios antes da fase GOV.BR

Três achados identificados nas revisões T8 e T9 que **não bloqueiam o deploy inicial atrás do APIM** mas **devem ser corrigidos antes de expor o sistema a usuários externos (GOV.BR)**:

#### [T8-1] `get_operador()` degrada silenciosamente para `"desconhecido"`
- **Arquivo:** `src/api/dependencies.py:62-67`
- **Problema:** JWT malformado faz a requisição prosseguir com `operador="desconhecido"` em vez de retornar 401. Em ambiente APIM o risco é baixo, mas em caso de misconfiguration de network policy movimentações seriam registradas sem operador identificado, comprometendo o audit trail CVM/TCM.
- **Recomendação:** Substituir `except Exception: return "desconhecido"` por `raise HTTPException(status_code=401, detail="Token inválido")`.

#### [T8-2] `numero_processo_sei` sem validação de formato por regex
- **Arquivo:** `src/api/schemas/solicitacao.py:25-29`, `src/api/schemas/movimentacao.py:30-35`
- **Problema:** Valida apenas não-vazio; sem padrão como `^\d{4}\.\d{4}/\d{7}-\d$`. Não há risco de SQL injection (ORM parametrizado), mas strings arbitrárias podem causar problemas em integrações downstream com o sistema SEI.
- **Recomendação:** Adicionar `pattern=r"^\d{4}\.\d{4}/\d{7}-\d$"` no campo Pydantic quando o formato SEI for confirmado com a equipe SP Urbanismo.

#### [T9-1] `DATABASE_URL` com credencial default no código-fonte
- **Arquivo:** `src/config.py:10`
- **Problema:** O valor default `postgresql+asyncpg://cepac:cepac@localhost:5432/cepac` fica versionado no repositório. Em produção é sobrescrito via variável de ambiente, mas a credencial de desenvolvimento não deve residir no código.
- **Recomendação:** Remover o default e tornar `DATABASE_URL` obrigatória (sem valor padrão), forçando configuração explícita em todos os ambientes.

### Documentação produzida

| Arquivo | Conteúdo |
|---------|----------|
| `docs/api.md` | Endpoints, schemas, exemplos cURL/JSON, erros |
| `docs/motor-de-regras.md` | Validators, fórmulas, exemplos numéricos reais |
| `docs/relatorio-testes.md` | 39 casos de teste T01–T06, critérios de aceite |
| `docs/seguranca.md` | Checklist de segurança completo + achados detalhados |
| `docs/revisao-codigo.md` | Code review final + pontos fortes + veredito |

### Entregáveis de infraestrutura

| Arquivo | Propósito |
|---------|-----------|
| `infra/Dockerfile` | Imagem Python 3.12-slim multi-stage, usuário não-root |
| `infra/docker-compose.yml` | Ambiente local: PostgreSQL + migrate + API |
| `infra/azure/container-app.yaml` | Manifesto Azure Container Apps |
| `.github/workflows/ci.yml` | Pipeline CI: Ruff → mypy → pytest → Docker build |
| `requirements.txt` | Dependências de produção fixadas |

---

---

## Visão Geral do Projeto

O objetivo é construir o **Core Engine** do Sistema de Controle de Estoque de CEPAC (Certificado de Potencial Adicional de Construção) da SP Urbanismo, com foco no motor de regras e na validação de limites setoriais da Operação Urbana Consorciada Água Espraiada (OUCAE).

O sistema funcionará como uma "Contabilidade de Ativos" que separa o inventário físico (m²) do inventário financeiro (Títulos de CEPAC), garantindo rastreabilidade total via número de processo SEI.

---

## Decisões Arquiteturais Críticas (v1.6)

### 1. Event-Sourcing para Auditoria Point-in-Time (CVM / TCM)

**Requisito:** Gerar "Snapshot de Transparência" com saldo exato de qualquer setor em qualquer data retroativa (exigência CVM e TCM).

**Decisão:** A tabela `movimentacao` é **append-only** e é o log canônico do sistema. Saldo nunca é lido de coluna calculada — é sempre **computado a partir do histórico de movimentações**.

```
Saldo(setor, data_alvo) = Σ movimentacoes WHERE setor = X AND created_at <= data_alvo
```

Implicações:
- `setor` armazena apenas parâmetros estruturais imutáveis (tetos, reservas) — nunca saldo corrente
- Saldo em tempo real = query sobre `movimentacao` com `created_at <= NOW()`
- Saldo histórico = mesma query com `created_at <= data_solicitada`
- Índice obrigatório em `(setor_id, uso, origem, estado, created_at)`

### 2. N Títulos CEPAC por Solicitação

**Requisito:** Uma solicitação consome um "lote" de títulos. O sistema deve registrar a quantidade exata de CEPACs convertidos por transação para controle do saldo **Em Circulação** (atualmente 142.268 unidades).

**Decisão:** Nova tabela `solicitacao_titulos` (relação N:N entre `solicitacao_vinculacao` e `titulo_cepac`).

```
solicitacao_vinculacao (1) ──── (N) solicitacao_titulos (N) ──── (1) titulo_cepac
```

### 3. ACA vs NUVEM — Universal para Todos os Setores

**Confirmado:** A distinção de origem existe em todos os setores para R e NR.
- `ACA` = Área Adicional de Construção (vinculação física/presencial)
- `NUVEM` = Estoque virtual ou transferido (vinculação digital)
- Brooklin e Jabaquara têm NUVEM zerado atualmente — schema deve prever as colunas para movimentações futuras

---

## Task Analysis

- Sistema de controle de estoque de CEPACs com motor de regras setoriais complexas (limites por setor, por uso, por quarentena)
- Contabilidade dupla: inventário físico (m²) + financeiro (Títulos CEPAC) com ciclo de vida de estados
- Stack técnica: Python (padrão Prodam), banco SQL relacional, contêineres Azure, sem frontend definido

### Tecnologias Detectadas
- **Backend:** Python 3.12+ + FastAPI (confirmado)
- **Banco de dados:** PostgreSQL 15 + SQLAlchemy 2.x
- **Infraestrutura:** Docker + Azure Container Apps
- **Testes:** pytest + pytest-asyncio + testcontainers
- **Rastreabilidade:** Número de processo SEI como campo string obrigatório (sem integração com API SEI nesta fase)

---

## Modelo de Dados (Esquema Conceitual)

### Entidades Principais

#### `estoque_geral`
| Campo | Tipo | Descrição |
|---|---|---|
| id | UUID PK | Identificador único |
| estoque_total_m2 | DECIMAL(15,2) | Total do estoque (cap: 4.850.000,00 m²) |
| reserva_tecnica_m2 | DECIMAL(15,2) | Reserva técnica (250.000,00 m²) |
| created_at | TIMESTAMP | Data de criação |
| updated_at | TIMESTAMP | Última atualização |

#### `setor`
| Campo | Tipo | Descrição |
|---|---|---|
| id | UUID PK | Identificador único |
| nome | VARCHAR(100) | Nome do setor (Brooklin, Berrini, Chucri Zaidan, Jabaquara) |
| capacidade_total_m2 | DECIMAL(15,2) | Capacidade total do setor |
| limite_nr_m2 | DECIMAL(15,2) | Limite para Não Residencial (nullable) |
| reserva_r_m2 | DECIMAL(15,2) | Reserva para Residencial (nullable) |
| percentual_minimo_r | DECIMAL(5,2) | % mínimo Residencial (nullable) |
| percentual_maximo_nr | DECIMAL(5,2) | % máximo Não Residencial (nullable) |

#### `titulo_cepac`
| Campo | Tipo | Descrição |
|---|---|---|
| id | UUID PK | Identificador único |
| codigo | VARCHAR(50) UNIQUE | Código do título |
| setor_id | UUID FK | Setor de origem |
| valor_m2 | DECIMAL(15,2) | Potencial construtivo em m² |
| uso | ENUM('R', 'NR') | Residencial ou Não Residencial |
| origem | ENUM('ACA', 'NUVEM') | Origem da vinculação — impacta agrupamento no saldo |
| estado | ENUM | Ver estados abaixo |
| numero_processo_sei | VARCHAR(50) | Obrigatório em toda movimentação |
| data_desvinculacao | TIMESTAMP | Data do último desvinculo (para quarentena) |
| created_at | TIMESTAMP | |
| updated_at | TIMESTAMP | |

> **Campo `origem` (ACA / NUVEM):** Identificado na conferência do Marginal Pinheiros (v1.5).
> O validator soma o consumo de ambas as origens para calcular o total comprometido do setor.
> `ACA` = vinculações por Alvará / Certidão de Aceite. `NUVEM` = vinculações digitais.

**Estados do título:**
- `DISPONIVEL` — Livre para vinculação
- `EM_ANALISE` — Reserva temporária (pedido em análise)
- `CONSUMIDO` — Vinculado a um empreendimento
- `QUARENTENA` — Desvinculado, bloqueado por 180 dias

#### `movimentacao`
| Campo | Tipo | Descrição |
|---|---|---|
| id | UUID PK | Identificador único |
| titulo_id | UUID FK | Título movimentado |
| estado_anterior | ENUM | Estado antes da movimentação |
| estado_novo | ENUM | Estado após a movimentação |
| numero_processo_sei | VARCHAR(50) NOT NULL | **Obrigatório** |
| motivo | TEXT | Justificativa (incluindo `"EXPIRAÇÃO_TTL"` para expirações automáticas) |
| operador | VARCHAR(100) | Responsável (extraído do JWT via APIM) |
| created_at | TIMESTAMP | **Imutável** — base do audit trail point-in-time |

> **Append-only:** Nenhuma linha de `movimentacao` pode ser alterada ou deletada após inserção. É o log canônico para reconstituição de saldo histórico (requisito CVM/TCM).

#### `solicitacao_vinculacao`
| Campo | Tipo | Descrição |
|---|---|---|
| id | UUID PK | |
| setor_id | UUID FK | Setor solicitado |
| uso | ENUM('R', 'NR') | |
| origem | ENUM('ACA', 'NUVEM') | Origem da vinculação — impacta agrupamento de saldo |
| area_m2 | DECIMAL(15,2) | Área total solicitada |
| quantidade_cepacs | INTEGER NOT NULL | Quantidade de títulos CEPAC do lote |
| numero_processo_sei | VARCHAR(50) NOT NULL | **Obrigatório** |
| status | ENUM('PENDENTE', 'APROVADA', 'REJEITADA') | |
| motivo_rejeicao | TEXT | Preenchido pelo motor de regras |
| created_at | TIMESTAMP | |

#### `solicitacao_titulos` *(junction table — nova em v1.6)*
| Campo | Tipo | Descrição |
|---|---|---|
| solicitacao_id | UUID FK | Referência à `solicitacao_vinculacao` |
| titulo_id | UUID FK | Referência ao `titulo_cepac` |
| area_m2 | DECIMAL(15,2) | m² que este título específico contribui para a solicitação |

> **Chave primária composta:** `(solicitacao_id, titulo_id)`. Um título só pode participar de uma solicitação ativa por vez.

---

## Regras de Negócio — Engine Constraints

> **Princípio geral consolidado:** Todas as validações de limite NR/R são calculadas sobre o **acumulado do setor** (consumido + em análise), não por solicitação individual.

### Parâmetros Setoriais da Água Espraiada

| Regra | Setor | Estoque Total | Teto NR | NR Acumulado (2026) | Saldo NR | Ação |
|---|---|---|---|---|---|---|
| Capacidade Geral | Todos | 4.850.000,00 m² | — | — | — | ERRO mandatório acima do teto |
| Teto NR por acumulado | Brooklin | 1.400.000,00 m² | 980.000,00 m² (70%) | 716.470,01 m² | 263.529,99 m² | ERRO quando acumulado NR ≥ 980.000,00 |
| Teto NR — limite excedido | Berrini | 350.000,00 m² | 175.000,00 m² (50%) | 203.202,23 m² ⚠️ | **0,00 m²** | ERRO imediato para qualquer pedido NR |
| Teto NR por acumulado | Marginal Pinheiros | 600.000,00 m² | 420.000,00 m² (70%) | A confirmar | A confirmar | ERRO quando acumulado NR ≥ 420.000,00 |
| Fórmula de consumo total | Chucri Zaidan | 2.000.000,00 m² | 1.783.557,53 m² | 1.111.411,24 m² | Calculado em runtime¹ | ERRO quando consumo total ≥ 1.783.557,53 |
| Limite absoluto NR | Jabaquara | 250.000,00 m² | 175.000,00 m² | 0,00 m² | 175.000,00 m² | ERRO acima do limite absoluto |
| Quarentena | Todos | — | — | — | — | ERRO antes de 180 dias do desvinculo |

> ¹ **Chucri Zaidan — fórmula definitiva do validator:**
> ```
> Saldo_NR = 2.000.000,00 − (Consumido_R + Consumido_NR + Em_Analise)
> BLOQUEIA pedido NR se: (Consumido_R + Consumido_NR + Em_Analise) + solicitacao_NR > 1.783.557,53
> ```
> O teto NR de 1.783.557,53 m² garante matematicamente que os 216.442,47 m² de reserva R (Lei 16.975/2018) nunca sejam invadidos.

> ⚠️ **Berrini:** NR acumulado (203.202,23 m²) já excede o teto de 175.000,00 m². O motor deve bloquear 100% dos novos pedidos NR sem consultar saldo.

### Detalhamento por Setor

#### Brooklin
- **Estoque total:** 1.400.000,00 m²
- **Teto NR (70%):** 980.000,00 m²
- **Mínimo R (30%):** 420.000,00 m²
- **NR acumulado em 2026:** 716.470,01 m² *(saldo NR disponível: 263.529,99 m²)*
- **Lógica:** O motor valida se `acumulado_NR + solicitacao_NR > 980.000,00`. Se verdadeiro → ERRO, mesmo que haja estoque geral disponível no setor.

#### Marginal Pinheiros *(setor adicionado na v1.3)*
- **Estoque total:** 600.000,00 m²
- **Teto NR (70%):** 420.000,00 m²
- **Mínimo R (30%):** do consumo acumulado do setor
- **NR acumulado 2026:** A confirmar (ver Dúvidas em Aberto #1)
- **Lógica:** Idêntica ao Brooklin. Motor verifica `acumulado_NR + solicitacao_NR > 420.000,00`.

#### Berrini
- **Estoque total:** 350.000,00 m²
- **Teto NR (50%):** 175.000,00 m²
- **NR acumulado 2026:** 203.202,23 m² — **excede o teto em 28.202,23 m²**
- **Lógica:** Bloqueio incondicional. O motor **não consulta saldo** — qualquer `solicitacao_NR > 0` retorna `ERRO("TETO_NR_EXCEDIDO")` imediatamente.

#### Chucri Zaidan
- **Estoque total:** 2.000.000,00 m²
- **Reserva R obrigatória (Lei 16.975/2018):** 216.442,47 m²
- **Teto NR:** 1.783.557,53 m² (= 2.000.000,00 − 216.442,47)
- **NR acumulado 2026:** 1.111.411,24 m²
- **Fórmula definitiva do validator:**
  ```
  Saldo_NR = 2.000.000,00 − (Consumido_R + Consumido_NR + Em_Analise)
  BLOQUEIA se: consumo_total + solicitacao_NR > 1.783.557,53
  ```
- **Semântica:** O teto não é só sobre NR — é sobre o **consumo total do setor**. O sistema trava o NR quando a soma de tudo que foi consumido (R + NR + reservado) atingiria o ponto em que não sobraria os 216.442,47 m² para R.

#### Jabaquara
- **Limite absoluto NR:** 175.000,00 m²
- **Lógica:** `acumulado_NR + solicitacao_NR > 175.000,00` → ERRO.

### Fórmula de Saldo
```
Saldo Disponível = Estoque Total − (Consumido + Em Análise)
```

### Fluxo de Estados
```
DISPONIVEL
    │
    ▼ (reservar — cria reserva com TTL 48h)
EM_ANALISE ──(TTL 48h expirado)──► DISPONIVEL  ← job de expiração automática
    │                   │
    ▼ (confirmar)       ▼ (cancelar manual)
CONSUMIDO          DISPONIVEL
    │
    ▼ (desvincular)
QUARENTENA  ──(180 dias)──► DISPONIVEL
```

> **TTL "Em Análise":** Reservas temporárias expiram em **48 horas**. Um job de background (scheduler) deve varrer periodicamente os registros `EM_ANALISE` cuja `created_at < now() - 48h` e revertê-los para `DISPONIVEL`, registrando a movimentação automaticamente com motivo `"EXPIRAÇÃO_TTL"`.

### Arquitetura de Autenticação

```
[Cliente Interno]                    [Cliente Externo]
  Prodam / SP Urbanismo                 GOV.BR (fase 2)
        │                                    │
        ▼                                    ▼
   Azure AD token                      GOV.BR token
        │                                    │
        └─────────────────┬──────────────────┘
                          ▼
              Azure API Management (APIM)
              ┌──────────────────────────┐
              │  Validação de token      │
              │  Rate limiting           │
              │  Roteamento por produto  │
              └──────────────┬───────────┘
                             ▼
                    Core Engine API (FastAPI)
                    ← recebe JWT já validado pelo APIM
```

**Implicação para o Core Engine:**
- A API FastAPI **não valida tokens diretamente** — confia no APIM como proxy autenticado
- Deve extrair o `sub` / `upn` do JWT repassado pelo APIM para rastreabilidade de operador
- Headers esperados do APIM: `X-MS-CLIENT-PRINCIPAL`, `Authorization: Bearer <token>`
- **Task 7 (security-expert)** deve revisar a configuração de confiança do APIM e garantir que a API não seja acessível diretamente sem passar pelo APIM

---

## Tasks Técnicas

### Ordem de Execução

```
T1 ✓ (Schema DB)
  └─► T2 ✓ (Motor de Regras)
              ├─► T3 ✓ (API REST) ──┐
              └─► T4 ✓ (Testes) ────┘
                                     └─► T5 ✓ (TTL Job + Seed)
                                                 └─► T6 ✓ (DevOps / Azure)
                                                             ├─► T7 ✓ (Docs) ──┐
                                                             └─► T8 ✓ (Seg.) ──┘
                                                                                 └─► T9 ✓ (Revisão)
```

---

### T1 — Schema do Banco de Dados ✅ CONCLUÍDA
**Agente:** `@agent-python-expert`
**Depende de:** nada — inicia imediatamente

**Objetivo:** Projetar e gerar o esquema SQL completo do sistema, refletindo todas as decisões arquiteturais consolidadas no planejamento.

**Entregáveis:**
- `migrations/001_initial_schema.sql` — DDL completo com todas as tabelas, constraints e índices
- `src/core/models/` — modelos SQLAlchemy 2.x mapeados para cada tabela

**Tabelas obrigatórias:**
| Tabela | Detalhe-chave |
|---|---|
| `setor` | Parâmetros estruturais imutáveis: `estoque_total_m2`, `teto_nr_m2`, `reserva_r_m2` (nullable). **Sem colunas de saldo** — saldo é sempre calculado de `movimentacao` |
| `titulo_cepac` | Campos `uso ENUM('R','NR')`, `origem ENUM('ACA','NUVEM')`, `estado ENUM('DISPONIVEL','EM_ANALISE','CONSUMIDO','QUARENTENA')`, `data_desvinculacao` |
| `solicitacao_vinculacao` | `uso`, `origem`, `area_m2`, `quantidade_cepacs`, `numero_processo_sei NOT NULL`, `status ENUM('PENDENTE','APROVADA','REJEITADA')` |
| `solicitacao_titulos` | Junction N:N — `(solicitacao_id, titulo_id)` PK composta; `area_m2` por título |
| `movimentacao` | **Append-only.** `estado_anterior`, `estado_novo`, `numero_processo_sei NOT NULL`, `operador`, `created_at` imutável. Base do audit trail |

**Índices obrigatórios:**
- `movimentacao(setor_id, uso, origem, estado, created_at)` — para queries de saldo histórico (CVM/TCM)
- `titulo_cepac(setor_id, uso, origem, estado)` — para queries de saldo por setor

**Critérios de aceite:**
- Nenhuma coluna de saldo calculado em `setor` (saldo é sempre derivado)
- `movimentacao` sem `UPDATE` ou `DELETE` permitido (constraint ou trigger)
- Chaves estrangeiras com `ON DELETE RESTRICT` em todos os FKs
- Todos os `numero_processo_sei` com `NOT NULL` e `CHECK (length > 0)`

---

### T2 — Motor de Regras (RulesEngine) ✅ CONCLUÍDA
**Agente:** `@agent-python-expert`
**Depende de:** T1 concluída

**Objetivo:** Implementar o `RulesEngine` como módulo Python puro, sem dependência de framework web — testável de forma isolada.

**Entregáveis:**
- `src/core/engine/rules_engine.py` — orquestrador que recebe uma `SolicitacaoDTO` e executa todos os validators em sequência
- `src/core/engine/validators/` — um módulo por regra:

| Módulo | Regra implementada |
|---|---|
| `capacity.py` | Teto global 4.850.000,00 m²; desconta reserva técnica 250.000,00 m² |
| `brooklin.py` | `acumulado_NR(ACA+NUVEM) + solicitacao_NR > 980.000,00` → ERRO |
| `berrini.py` | Qualquer `solicitacao_NR > 0` → ERRO imediato (sem consulta de saldo) |
| `marginal_pinheiros.py` | `(acumulado_NR + em_analise_NR) + solicitacao_NR > 420.000,00` → ERRO |
| `chucri_zaidan.py` | `(R_total + NR_total + Em_Analise) + solicitacao_NR > 1.783.557,53` → ERRO. R_total e NR_total somam ACA+NUVEM |
| `jabaquara.py` | `acumulado_NR + solicitacao_NR > 175.000,00` → ERRO |
| `quarantine.py` | `data_desvinculacao + 180 dias > hoje` → ERRO com `dias_restantes` no payload |
| `sei.py` | `numero_processo_sei` nulo ou vazio → `ValidationError` antes de qualquer outra regra |

**Interface do RulesEngine:**
```python
@dataclass
class SolicitacaoDTO:
    setor: str
    uso: Literal["R", "NR"]
    origem: Literal["ACA", "NUVEM"]
    area_m2: Decimal
    numero_processo_sei: str
    titulo_ids: list[UUID]          # lote de N títulos

class RulesEngine:
    def validar(self, solicitacao: SolicitacaoDTO) -> ValidationResult:
        # retorna aprovado ou RulesError com código + detalhes
        ...
```

**Códigos de erro obrigatórios:**
`NUMERO_SEI_OBRIGATORIO`, `TETO_GLOBAL_EXCEDIDO`, `TETO_NR_EXCEDIDO`, `RESERVA_R_VIOLADA`, `QUARENTENA_ATIVA`, `TITULO_INDISPONIVEL`

**Critérios de aceite:**
- Cada validator é uma função pura — sem side effects, sem I/O
- `RulesEngine` recebe os dados de saldo como parâmetro (não consulta o banco diretamente)
- Todos os 6 testes obrigatórios (T01–T06) passam via T4

---

### T3 — API REST (FastAPI) ✅ CONCLUÍDA
**Agente:** `@agent-fastapi-expert`
**Depende de:** T2 concluída
**Roda em paralelo com:** T4

**Objetivo:** Expor o motor de regras e o ciclo de vida dos títulos via API REST assíncrona.

**Entregáveis:**
- `src/api/routes/` — endpoints abaixo
- `src/api/schemas/` — Pydantic v2 schemas para request/response
- OpenAPI automático via FastAPI (`/docs`)

**Endpoints obrigatórios:**

| Método | Rota | Descrição |
|---|---|---|
| `POST` | `/solicitacoes` | Submete lote de vinculação; executa `RulesEngine.validar()`; retorna aprovado ou erro com detalhes |
| `GET` | `/saldo/{setor}` | Retorna saldo atual calculado a partir de `movimentacao` (nunca de coluna cacheada) |
| `GET` | `/saldo/{setor}?data=YYYY-MM-DD` | Snapshot histórico point-in-time (auditoria CVM/TCM) |
| `POST` | `/movimentacoes` | Registra transição de estado de um ou mais títulos com SEI obrigatório |
| `GET` | `/titulos/{id}/historico` | Trilha de auditoria completa de um título |
| `GET` | `/titulos` | Lista com filtros por setor, uso, origem, estado |

**Autenticação:**
- Confiar no header `Authorization: Bearer <token>` repassado pelo Azure APIM
- Extrair `operador` do claim `upn` ou `sub` do JWT para registrar em `movimentacao`
- **Não validar assinatura do token** — responsabilidade do APIM

**Critérios de aceite:**
- `GET /saldo/{setor}?data=2025-01-01` retorna o saldo correto naquela data
- `POST /solicitacoes` sem `numero_processo_sei` retorna `422` com detalhe do erro SEI
- Resposta de erro inclui sempre: `codigo_erro`, `setor`, `saldo_atual`, `limite`

---

### T4 — Suíte de Testes ✅ CONCLUÍDA (38 testes, todos passando)
**Agente:** `@agent-testing-expert`
**Depende de:** T2 concluída
**Roda em paralelo com:** T3

**Objetivo:** Cobrir todos os cenários obrigatórios definidos pelo Tech Lead com testes unitários (motor de regras isolado) e de integração (banco real via testcontainers).

**Entregáveis:**
- `tests/unit/` — testes do `RulesEngine` com mocks de saldo
- `tests/integration/` — testes com PostgreSQL real (testcontainers)

**Cenários obrigatórios:**

| ID | Nome | Tipo | Validação |
|---|---|---|---|
| T01 | Berrini NR Bloqueio Incondicional | Unit | `RulesEngine` retorna `TETO_NR_EXCEDIDO` para qualquer pedido NR no Berrini |
| T02 | Chucri Zaidan Reserva R | Unit | Pedido R dentro da reserva → aprovado; pedido NR que invadiria → `RESERVA_R_VIOLADA` |
| T03 | Fórmula de Saldo | Unit | `Saldo = Total − (Consumido + Em_Análise)` com valores exatos do seed |
| T04 | Quarentena 90 dias | Unit | Título desvinculado há 90 dias → `QUARENTENA_ATIVA` com `dias_restantes=90` |
| T05 | SEI Obrigatório | Unit | Transação sem SEI → `ValidationError("NUMERO_SEI_OBRIGATORIO")` antes de qualquer outra validação |
| T06 | Estresse Brooklin NR | Integration | Série de pedidos NR satura limite em 980.000,00 m²; pedido após o teto é bloqueado; pedido R posterior é aprovado |

**Cenários adicionais obrigatórios:**
- Snapshot histórico: saldo calculado para data passada bate com estado conhecido
- TTL: título em `EM_ANALISE` há 49h deve aparecer como `DISPONIVEL` após job de expiração
- N títulos: solicitação com lote de 50 títulos registra 50 entradas em `solicitacao_titulos`
- Origem ACA/NUVEM: saldo Marginal Pinheiros com NR_ACA=258.908,19 e NR_NUVEM=0 resulta em saldo 149.918,75

**Critérios de aceite:**
- Cobertura ≥ 90% dos módulos em `src/core/engine/`
- Testes de integração rodam com `docker compose up` sem configuração adicional
- Nenhum teste usa mock do banco — integração usa PostgreSQL real

---

### T5 — Job de Expiração TTL + Seed ✅ CONCLUÍDA
**Agente:** `@agent-python-expert`
**Depende de:** T3 e T4 concluídas

**Objetivo:** Implementar o job de background que expira reservas vencidas e popular o banco com o estado inicial de Abril 2026.

**Entregáveis:**
- `src/core/jobs/expiry_job.py` — varre `titulo_cepac` com `estado=EM_ANALISE` e `updated_at < now() - 48h`; reverte para `DISPONIVEL`; registra em `movimentacao` com `motivo="EXPIRAÇÃO_TTL"` e `operador="SISTEMA"`
- `migrations/002_seed_abril_2026.sql` — seed completo (ver `docs/parametros-setoriais.md` seção 4)
- Scheduler integrado ao startup do FastAPI (APScheduler ou similar)

**Valores do seed (posição 13/04/2026):**

| Setor | NR ACA | NR NUVEM | R ACA | R NUVEM | Em Análise |
|---|---|---|---|---|---|
| Brooklin | 716.470,01 | 0,00 | — | 0,00 | — |
| Berrini | 203.202,23 | 595,00 | — | 100,62 | — |
| Marginal Pinheiros | 258.908,19 | 0,00 | — | 1.301,13 | 11.173,06 NR |
| Chucri Zaidan | 1.050.881,42 | 434,79 | 751.909,09 | 204,70 | 14.006,35 R |
| Jabaquara | 0,00 | 0,00 | — | 0,00 | — |

**Critérios de aceite:**
- Job idempotente — executar duas vezes não duplica movimentações
- Após seed, `GET /saldo/Berrini` retorna `saldo_nr=0` e `bloqueado=true`
- Após seed, `GET /saldo/Chucri Zaidan` retorna `saldo_nr=182.563,65`
- Após seed, `GET /saldo/Marginal Pinheiros` retorna `saldo_nr=149.918,75`

---

### T6 — DevOps / Infraestrutura Azure ✅ CONCLUÍDA
**Agente:** `@agent-devops-cicd-expert`
**Depende de:** T5 concluída

**Objetivo:** Containerizar a aplicação e preparar a infraestrutura para deploy no Azure.

**Entregáveis:**
- `infra/Dockerfile` — imagem Python 3.12-slim, multi-stage build
- `infra/docker-compose.yml` — ambiente local com FastAPI + PostgreSQL + APScheduler
- `infra/azure/container-app.yaml` — manifesto Azure Container Apps
- `.github/workflows/ci.yml` — pipeline: lint (Ruff) → mypy → pytest → build imagem

**Critérios de aceite:**
- `docker compose up` sobe o sistema completo e aplica seed automaticamente
- Pipeline CI falha se qualquer teste falhar
- Imagem não contém credenciais hardcoded — usa variáveis de ambiente

---

### T7 — Documentação Técnica ✅ CONCLUÍDA
**Agente:** `@agent-documentation-specialist`
**Depende de:** T6 concluída
**Roda em paralelo com:** T8

**Objetivo:** Produzir documentação técnica completa para equipe Prodam e SP Urbanismo.

**Entregáveis:**
- `docs/api.md` — documentação dos endpoints com exemplos de request/response
- `docs/motor-de-regras.md` — explicação de cada validator com exemplos numéricos reais dos setores
- `docs/relatorio-testes.md` — template de relatório de execução dos 6 testes obrigatórios (T01–T06)
- Atualização do OpenAPI spec gerado pelo FastAPI

---

### T8 — Revisão de Segurança ✅ CONCLUÍDA (8 CONFORME / 2 PARCIAL)
**Agente:** `@agent-security-expert`
**Depende de:** T6 concluída
**Roda em paralelo com:** T7

**Objetivo:** Garantir que o Core Engine não seja acessível sem passar pelo APIM e que inputs sejam validados contra injeção e manipulação.

**Checklist obrigatório:**
- [ ] API não responde requisições sem header `Authorization` (retorna 401)
- [ ] API não é acessível diretamente — porta exposta apenas para o APIM (network policy)
- [ ] Todos os inputs decimais passam por `Decimal` (não `float`) para evitar arredondamento
- [ ] `numero_processo_sei` sanitizado — sem caracteres que permitam SQLi
- [ ] `movimentacao` verificada como append-only (sem rotas de UPDATE/DELETE)
- [ ] JWT claim `upn`/`sub` extraído de forma segura; sem confiança em header arbitrário do cliente
- [ ] Rate limiting configurado no APIM para endpoints de solicitação

---

### T9 — Revisão de Código ✅ CONCLUÍDA (9 CONFORME / 1 PARCIAL — Aprovado com ressalvas)
**Agente:** `@agent-code-reviewer`
**Depende de:** T7 e T8 concluídas

**Objetivo:** Revisão final de qualidade, coesão e aderência aos padrões Prodam.

**Checklist obrigatório:**
- [ ] Ruff sem warnings; mypy sem erros com `strict=true`
- [ ] Nenhum `float` em cálculos financeiros — apenas `Decimal`
- [ ] Validators do `RulesEngine` são funções puras e testáveis isoladamente
- [ ] Nenhuma lógica de negócio nos endpoints FastAPI — apenas orquestração
- [ ] Cobertura de testes ≥ 90% em `src/core/engine/`
- [ ] `movimentacao` não tem rota de modificação exposta
- [ ] Seed idempotente confirmado

---

## Cenários de Teste Obrigatórios

### T01 — Berrini NR: Limite Excedido
```python
def test_berrini_nr_limite_excedido():
    """
    DADO que o setor Berrini já atingiu 50% de NR
    QUANDO uma solicitação de 1 m² NR for submetida
    ENTÃO o motor deve retornar RulesError("LIMITE_NR_EXCEDIDO", setor="Berrini")
    """
```

### T02 — Chucri Zaidan: Reserva Residencial
```python
def test_chucri_zaidan_residencial_dentro_reserva():
    """
    DADO que há saldo na reserva R de 216.442,47 m²
    QUANDO uma solicitação R for submetida dentro da reserva
    ENTÃO deve ser aprovada

    DADO que a solicitação NR invadiria a reserva R
    QUANDO submetida ao motor
    ENTÃO deve retornar RulesError("RESERVA_R_VIOLADA", setor="Chucri Zaidan")
    """
```

### T03 — Segurança de Saldo
```python
def test_formula_saldo_disponivel():
    """
    DADO estoque_total=1000, consumido=400, em_analise=100
    QUANDO o saldo for calculado
    ENTÃO saldo_disponivel == 500
    """
```

### T04 — Quarentena
```python
def test_quarentena_90_dias():
    """
    DADO um título desvinculado há 90 dias (< 180 dias)
    QUANDO uma nova vinculação for solicitada
    ENTÃO o motor deve retornar RulesError("QUARENTENA_ATIVA", dias_restantes=90)
    """
```

### T05 — Obrigatoriedade SEI
```python
def test_transacao_sem_sei():
    """
    DADO uma movimentação sem número de processo SEI
    QUANDO submetida ao repositório
    ENTÃO deve lançar ValidationError("NUMERO_SEI_OBRIGATORIO")
    """
```

### T06 — Estresse Brooklin NR (novo)
```python
def test_estresse_brooklin_nr():
    """
    DADO que o setor Brooklin tem 716.470,01 m² NR já acumulados
         e o teto é 980.000,00 m²
         (saldo NR restante: 263.529,99 m²)

    CENÁRIO A — dentro do limite:
    QUANDO uma solicitação NR de 263.529,99 m² for submetida
    ENTÃO deve ser aprovada (acumulado atinge exatamente o teto)

    CENÁRIO B — ultrapassagem exata:
    QUANDO uma solicitação NR de 263.530,00 m² (1 m² acima) for submetida
    ENTÃO deve retornar RulesError("TETO_NR_EXCEDIDO", setor="Brooklin",
                                    acumulado=716.470,01, teto=980.000,00)

    CENÁRIO C — série de solicitações que somam ultrapassagem:
    DADO que 5 solicitações de 53.000,00 m² NR são enviadas sequencialmente
         (5 × 53.000 = 265.000 > 263.529,99)
    QUANDO a 5ª solicitação for processada
    ENTÃO as 4 primeiras devem ser aprovadas e a 5ª deve retornar ERRO,
         mesmo com estoque geral disponível no setor

    CENÁRIO D — uso R não é bloqueado pelo teto NR:
    QUANDO uma solicitação R for submetida após o teto NR ser atingido
    ENTÃO deve ser aprovada normalmente
    """
```

> **Nota:** A mesma lógica de estresse se aplica ao Berrini (50/50). Como o limite NR já está atingido no estado atual, qualquer pedido NR deve falhar imediatamente — o Cenário B se aplica desde o primeiro byte de pedido NR.

---

## Estrutura de Pastas Esperada

```
CEPAC/
├── docs/
│   ├── planejamento.md          # Este documento
│   └── parametros-setoriais.md  # Fonte única de verdade — limites OUCAE
├── src/
│   ├── core/
│   │   ├── models/              # Modelos de dados
│   │   ├── engine/              # Motor de regras
│   │   │   └── validators/      # Um módulo por regra setorial
│   │   └── repositories/        # Acesso ao banco
│   ├── api/
│   │   ├── routes/              # Endpoints FastAPI
│   │   └── schemas/             # Pydantic schemas
│   └── config/                  # Configurações por ambiente
├── tests/
│   ├── unit/                    # Testes unitários do motor
│   └── integration/             # Testes de integração com banco real
├── infra/
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── azure/                   # Manifesto Container Apps
├── migrations/                  # SQL migrations
│   └── 001_initial_schema.sql
└── schema.sql                   # DDL completo
```

---

## Requisitos Técnicos

| Item | Decisão |
|---|---|
| Linguagem | Python 3.12+ |
| Framework API | FastAPI (assíncrono, OpenAPI nativo) |
| ORM/Banco | SQLAlchemy 2.x + PostgreSQL 15 |
| Testes | pytest + pytest-asyncio + testcontainers |
| Containerização | Docker + Azure Container Apps |
| CI/CD | GitHub Actions |
| Padrão de código | PEP 8 + Ruff + mypy (tipagem estrita) |
| Autenticação inicial | API Key por header (expandível para Azure AD) |

---

## Decisões Registradas

| # | Questão | Decisão |
|---|---|---|
| D1 | Framework backend | **Python 3.12 + FastAPI** (confirmado) |
| D2 | Integração SEI | **Sem integração nesta fase** — campo string obrigatório, validação de formato local |
| D3 | Lógica Brooklin/Berrini | **Cálculo por acumulado do setor**, não por solicitação individual |
| D4 | Brooklin NR atual | **716.470,01 m²** já consumidos; teto em 980.000,00 m² |
| D5 | Berrini NR | **50/50 — limite já atingido**; qualquer pedido NR retorna ERRO imediato |
| D6 | Autenticação (fase 1) | **Azure AD (Prodam)** — consumo interno via Azure API Management |
| D7 | Autenticação (fase 2) | **GOV.BR** — consumo externo, também gerenciado pelo Azure APIM |
| D8 | TTL "Em Análise" | **48 horas** — reserva temporária expira automaticamente e volta a DISPONIVEL |
| D9 | Chucri Zaidan — NR acumulado | **1.111.411,24 m²** NR já consumidos (seed de dados) |
| D10 | Jabaquara — NR acumulado | **0,00 m²** — estoque NR totalmente livre (seed de dados) |
| D11 | Chucri Zaidan — fórmula validator | `Saldo_NR = 2.000.000 − (Consumido_R + Consumido_NR + Em_Analise)`; trava em 1.783.557,53 m² |
| D12 | Berrini — estoque total e NR acumulado | Total: 350.000 m²; teto NR: 175.000 m²; acumulado: 203.202,23 m² (excede o teto) |
| D13 | Jabaquara — estoque total | 250.000,00 m²; teto NR: 175.000,00 m² |
| D14 | Marginal Pinheiros | Setor confirmado: 600.000 m² total, teto NR 420.000 m² (70%); NR acumulado a confirmar |
| D15 | Referência canônica de parâmetros | Ver `docs/parametros-setoriais.md` — fonte única de verdade para os limites |
| D16 | Marginal Pinheiros — seed completo | NR consumido ACA: 258.908,19; NUVEM: 0,00; Em Análise: 11.173,06; total comprometido: 270.081,25; saldo: 149.918,75 m² ✓ |
| D17 | Origem de consumo (ACA / NUVEM) | Todas as vinculações têm origem ACA ou NUVEM; ambas somadas = total comprometido no validator; campo adicionado ao modelo `titulo_cepac` |
| D18 | N títulos por solicitação | Obrigatório — projetos demandam lotes de CEPACs; nova tabela `solicitacao_titulos` (N:N) adicionada ao modelo |
| D19 | Auditoria point-in-time | Requisito crítico CVM/TCM — `movimentacao` append-only como log canônico; saldo reconstruído por query histórica |
| D20 | Saldo "Em Circulação" | 142.268 unidades de CEPAC atualmente em circulação; deve ser controlado por transação |
| D21 | NUVEM por setor (seed completo) | Berrini: R=100,62 / NR=595,00; Marginal Pinheiros: R=1.301,13 / NR=0,00; Chucri Zaidan: R=204,70 / NR=434,79; Brooklin/Jabaquara: 0,00 (prever colunas) |
| D22 | Chucri Zaidan — seed completo validado (13/04/2026) | R_total=752.113,79 (ACA 751.909,09 + NUVEM 204,70); NR_total=1.051.316,21 (ACA 1.050.881,42 + NUVEM 434,79); Em_Análise=14.006,35 R; Saldo_NR=182.563,65 ✓ |
| D23 | Divergência NR ACA Chucri Zaidan | Seed v1.5 tinha 1.111.411,24; planilha 13/04/2026 corrige para 1.050.881,42 (−60.529,82 m²). Valor adotado: 1.050.881,42 |

---

## Planejamento Fechado para Implementação

Todas as decisões arquiteturais e de negócio estão registradas. O time pode iniciar a Task 1.

*Documento gerado com suporte do Tech Lead Orchestrator — revisão humana obrigatória antes do início da implementação.*
