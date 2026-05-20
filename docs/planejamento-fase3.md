# Planejamento Fase 3 — Administração de OUCs, Setores e Filtro de Pesquisa

**Data:** 2026-05-04  
**Status:** Em execução — Bloco A

---

## Contexto

Com as três Operações Urbanas (OUCAE, OUCFL, OUCAB) e seus 22 setores cadastrados no banco (Fase 2), a Fase 3 reestrutura a interface de administração do Portal para refletir essa realidade e habilita a pesquisa de propostas filtrada por OUC.

---

## Decisões arquiteturais registradas

### D1 — Configuração por OUC (Opção B)

`configuracao_operacao` é um singleton global que continha dados na prática específicos da OUCAE (`reserva_tecnica_m2`, `cepacs_leiloados`, `cepacs_colocacao_privada`, `cepacs_totais`). Com múltiplas OUCs, esses campos migram para `operacao_urbana`.

**Decisão:** Migrar os campos para `operacao_urbana` (migration 024). A tabela `configuracao_operacao` é mantida temporariamente como **legacy** para não quebrar o Dashboard, que lê esses valores via `GET /admin/configuracao`. O Dashboard será migrado na Fase 4 para consumir dados por OUC via `GET /admin/operacoes-urbanas/{id}`.

**Impacto imediato:**
- Migration 024 adiciona 4 colunas em `operacao_urbana` e copia os valores atuais da OUCAE.
- `PUT /admin/configuracao` é substituído por `PUT /admin/operacoes-urbanas/{id}` (novo endpoint do Bloco A).
- `GET /admin/configuracao` permanece funcional e inalterado — atendendo o Dashboard até a Fase 4.
- `ConfiguracaoOperacaoPage.tsx` passa a editar `operacao_urbana` (escrita pela nova tela da Fase 3).

**Fase 4 (deferred):**
- Remover `configuracao_operacao` ou torná-la uma VIEW computada.
- Atualizar Dashboard para consumir dados por OUC.

---

### D2 — Hierarquia visual de setores

Setores são exibidos em lista plana ordenada: pais alfabéticos → filhos logo abaixo com indentação `└─`. Máximo 2 níveis (dado real: OUCAB tem Pais + Filhos). Detecção de ciclo transitivo não é implementada — apenas `setor_pai_id != setor_id`.

---

### D3 — Cascata Setor na Pesquisa (client-side)

`GET /admin/setores` (sem filtro) continua retornando todos os setores. O portal filtra client-side pela `operacao_urbana_id` do setor. Não exige nova requisição ao mudar a OUC selecionada (~22 setores, custo desprezível).

---

### D4 — `GET /admin/setores` mantém contrato atual

O endpoint existente passa a retornar os novos campos (`operacao_urbana_id`, `setor_pai_id`, `fator_equivalencia_f1`, `fator_equivalencia_f2`) como **adicionais** ao contrato original. Nenhum campo existente é removido. PropostasPage legada continua funcionando sem alteração.

---

## Escopo — o que NÃO entra na Fase 3

- Dashboard (nenhuma alteração de tela ou endpoint do dashboard)
- Carga de solicitações para OUCFL/OUCAB
- Exclusão de OUCs ou Setores (apenas criação e edição)
- Remoção da tabela `configuracao_operacao` (deferred Fase 4)

---

## Blocos de trabalho

### Bloco A — Backend (FastAPI + SQLAlchemy 2)

Ordem de execução: A1 → A2 → A3 → A4 (sequencial — cada task depende dos schemas da anterior)

| # | Task | Entregáveis | Complexidade |
|---|------|------------|:---:|
| A1 | Schemas Pydantic | `OperacaoUrbanaIn/Out/Resumo` em `admin.py`; estender `SetorIn/Out` com `operacao_urbana_id`, `setor_pai_id`, `teto_r_m2`¹, F1/F2 | P |
| A2 | Migration 024 | ADD 4 colunas config em `operacao_urbana`; seed OUCAE com valores atuais | P |
| A3 | Rotas CRUD OUC | `GET/POST /admin/operacoes-urbanas` e `GET/PUT /admin/operacoes-urbanas/{id}` (sem DELETE) | P |
| A4 | Rotas Setores v2 | `GET /admin/operacoes-urbanas/{id}/setores`; `?operacao_urbana_id=` em `GET /admin/setores`; validações de pai cruzado em POST/PUT | M |
| A5 | Filtro OUC em Propostas | `?operacao_urbana_id=` em `GET /portal/propostas` com join em setor | P |

¹ `teto_r_m2` já existe no modelo `Setor` mas estava ausente de `SetorIn`.

**Endpoints novos/modificados:**

```
GET  /admin/operacoes-urbanas                → list[OperacaoUrbanaOut]  (require_tecnico)
POST /admin/operacoes-urbanas                → OperacaoUrbanaOut 201    (require_diretor)
GET  /admin/operacoes-urbanas/{id}           → OperacaoUrbanaOut        (require_tecnico)
PUT  /admin/operacoes-urbanas/{id}           → OperacaoUrbanaOut        (require_diretor)
GET  /admin/operacoes-urbanas/{id}/setores   → list[SetorOut]           (require_tecnico)

# Modificados (backward-compat):
GET  /admin/setores?operacao_urbana_id=      → list[SetorOut]           (require_tecnico)
POST /admin/setores                          → SetorOut 201             (require_diretor)  ← novos campos
PUT  /admin/setores/{id}                     → SetorOut                 (require_diretor)  ← novos campos

# Portal:
GET  /portal/propostas?operacao_urbana_id=   → paginado                 (require_tecnico)
```

---

### Bloco B — Frontend (React 18 + TypeScript)

Ordem: B5 → B6 ‖ B7 (paralelas) → B8 → B9

| # | Task | Entregáveis | Complexidade |
|---|------|------------|:---:|
| B5 | Tipos + API client | Interfaces `OperacaoUrbanaOut/In/Resumo`; estender `SetorOut/In`; funções `listarOUCs`, `criarOUC`, `atualizarOUC`, `listarSetoresPorOUC` | P |
| B6 | `OUCAdminPage.tsx` | Lista OUCs + modal Criar/Editar; botão "Setores" → `/admin/operacoes-urbanas/:id/setores` | M |
| B7 | `SetoresPorOUCPage.tsx` | Lista setores da OUC com hierarquia visual `└─`, F1/F2, select Setor Pai no modal | **G** |
| B8 | Redirect + ConfigPage | `/admin/setores` redireciona para `/admin/operacoes-urbanas`; `SetoresAdminPage` config extraída para `/admin/configuracao` (`ConfiguracaoOperacaoPage.tsx`) — que passa a usar `PUT /admin/operacoes-urbanas/{id}` | P |
| B9 | Filtro OUC em Propostas | Select OUC com cascata Setor em `PropostasPage.tsx`; contar cards respeitando OUC | M |

---

### Bloco C — Qualidade

Após Blocos A e B completos (paralelos entre si):

| # | Task | Entregáveis | Status |
|---|------|------------|:---:|
| C10 | Testes integração backend | `test_admin_operacoes_urbanas.py`, `test_admin_setores_v2.py`, `test_portal_propostas_filtro_ouc.py` | ✅ criados em `tests/integration/` |
| C11 | Code review | RBAC, ausência de N+1 nas queries novas, contrato backward-compat de `GET /admin/setores` | ⏳ |

---

## Migration 024 — detalhe

```sql
ALTER TABLE operacao_urbana
    ADD COLUMN reserva_tecnica_m2       NUMERIC(15,2) NOT NULL DEFAULT 0,
    ADD COLUMN cepacs_leiloados         INTEGER       NOT NULL DEFAULT 0,
    ADD COLUMN cepacs_colocacao_privada INTEGER       NOT NULL DEFAULT 0,
    ADD COLUMN cepacs_totais            INTEGER       NOT NULL DEFAULT 0;

-- Copia valores atuais da OUCAE (id=1) a partir do singleton configuracao_operacao
UPDATE operacao_urbana
SET
    reserva_tecnica_m2       = (SELECT reserva_tecnica_m2       FROM configuracao_operacao WHERE id = 1),
    cepacs_leiloados         = (SELECT cepacs_leiloados         FROM configuracao_operacao WHERE id = 1),
    cepacs_colocacao_privada = (SELECT cepacs_colocacao_privada FROM configuracao_operacao WHERE id = 1),
    cepacs_totais            = (SELECT cepacs_totais            FROM configuracao_operacao WHERE id = 1)
WHERE sigla = 'AE';
```

`configuracao_operacao` **não é alterada** — continua servindo o Dashboard até a Fase 4.

---

## Diagrama de navegação (Portal — após Fase 3)

```
/admin/operacoes-urbanas          ← OUCAdminPage (lista OUCs)
  └─ /admin/operacoes-urbanas/:id/setores  ← SetoresPorOUCPage (setores hierárquicos)
/admin/configuracao               ← ConfiguracaoOperacaoPage (Reserva Técnica + CEPACs por OUC)
/propostas                        ← PropostasPage (+ filtro OUC → cascata Setor)

Legado (redirect):
/admin/setores  →  /admin/operacoes-urbanas
```

---

## Riscos residuais

| # | Risco | Mitigação |
|---|-------|----------|
| R1 | `configuracao_operacao` fica desatualizada após diretor editar OUC | Aceito — Dashboard é read-only para esses dados e a divergência é tolerada até Fase 4 |
| R2 | Validação de ciclo transitivo em hierarquia de setores | Aceito — implementado apenas `setor_pai_id != setor_id`; máximo 2 níveis no dado real |
| R3 | Nomes de setor não globalmente únicos ao adicionar OUCFL/OUCAB | Não é risco atual — nomes são únicos na tabela (constraint UNIQUE em `setor.nome`) |

---

## Histórico de decisões

| Data | Decisão | Tomada por |
|------|---------|-----------|
| 2026-05-04 | Múltiplas OUCs no banco (migrations 015–021) | Ricardo + Claude (Fase 2) |
| 2026-05-04 | OUCAB R Incentivado via `LimitesOucDTO` sem hardcode | Ricardo + Claude (Fase 2) |
| 2026-05-04 | Opção B — migrar config para `operacao_urbana`, manter `configuracao_operacao` como legacy | Ricardo (Fase 3) |
