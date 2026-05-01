# Pendências Fase 2 — CEPAC SP Urbanismo

> Documento de controle das atividades que restam para finalizar a Fase 2 em produção.
> Atualizado em: 01/05/2026 (CI totalmente verde — testes + mypy + builds)

---

## Status geral

| Bloco | Estado | Atualizado em |
|---|---|---|
| Código (Fase 1 + Fase 2) | ✅ Concluído | 16/04/2026 |
| Infraestrutura Azure | ✅ Provisionada | 17/04/2026 |
| Banco de dados populado | ✅ 237 títulos, 197 propostas | 17/04/2026 |
| CORS configurado | ✅ URLs reais | 17/04/2026 |
| App Registration | ✅ PN1006-CEPAC-API + PN1006-CEPAC-Frontend | 01/05/2026 |
| GitHub Secrets (completo) | ✅ ACR + VITE_API_URL + TENANT_ID + CLIENT_IDs | 01/05/2026 |
| DEV_BYPASS desativado | ✅ Container App + código frontend | 01/05/2026 |
| CI/CD — builds e deploy | ✅ Pipeline totalmente verde (commit 07167b5) | 01/05/2026 |
| Testes de integração | ✅ 35/35 passando local e no CI (commit b32535b) | 01/05/2026 |
| Primeiro login real | ⏳ Pendente | — |
| Blob Storage funcional | ⏳ Pendente | — |

---

## Bloco 1 — App Registration ✅ CONCLUÍDO

**Concluído em:** 01/05/2026
**Responsável:** Infra / Prodam

### Registro 1 — PN1006-CEPAC-API (backend)

| Campo | Valor |
|---|---|
| Client ID | `e7525560-a7ae-4688-8ea9-6f1f923ef8c3` |
| Tenant ID | `f398df9c-fd0c-4829-a003-c770a1c4a063` |
| Application ID URI | `api://e7525560-a7ae-4688-8ea9-6f1f923ef8c3` |
| Scope exposto | `CEPAC.Acesso` (consentimento: Admins and users) |
| Client Secret | Gerado (não necessário para validação JWT — ver nota abaixo) |

### Registro 2 — PN1006-CEPAC-Frontend (portal + dashboard)

| Campo | Valor |
|---|---|
| Client ID | `39d6d992-23d8-4abf-b9a0-9b0f89bfe8bf` |
| Tenant ID | `f398df9c-fd0c-4829-a003-c770a1c4a063` |
| URIs de redirecionamento (SPA) | `https://cepac-portal.redpond-877494a8.eastus.azurecontainerapps.io/` |
| | `https://cepac-dashboard.redpond-877494a8.eastus.azurecontainerapps.io/` |
| | `http://localhost:3000/`, `http://localhost:5173/` |
| | `http://localhost:3001/`, `http://localhost:5174/` |
| API Permissions | `CEPAC-API / CEPAC.Acesso` (delegated) ✅ |

> **Nota sobre o Client Secret:** a API valida JWTs via JWKS (chaves públicas do Azure AD) — não precisa
> do client secret para isso. O secret **não deve ser configurado** no Container App. Caso necessário para
> outras integrações futuras, regenerar antes de usar (o original foi exposto em texto no canal de comunicação).

---

## Bloco 2 — Configuração pós-App Registration ✅ CONCLUÍDO

**Concluído em:** 01/05/2026

### 2.1 — DEV_BYPASS desativado ✅

- Container App `cepac-api`: `DEV_BYPASS_AUTH=false` (via `az containerapp update`)
- 9 arquivos frontend: `const DEV_BYPASS = true` → `import.meta.env.VITE_DEV_BYPASS_AUTH === "true"`

### 2.2 — Variáveis de ambiente da API ✅

```
AZURE_AD_CLIENT_ID=e7525560-a7ae-4688-8ea9-6f1f923ef8c3
AZURE_AD_TENANT_ID=f398df9c-fd0c-4829-a003-c770a1c4a063
DEV_BYPASS_AUTH=false
```

### 2.3 — GitHub Secrets ✅

```
ACR_LOGIN_SERVER          ✅ cepacregistry.azurecr.io
ACR_USERNAME              ✅
ACR_PASSWORD              ✅
VITE_API_URL              ✅
AZURE_AD_TENANT_ID        ✅ f398df9c-fd0c-4829-a003-c770a1c4a063
PORTAL_AZURE_CLIENT_ID    ✅ 39d6d992-23d8-4abf-b9a0-9b0f89bfe8bf
DASHBOARD_AZURE_CLIENT_ID ✅ 39d6d992-23d8-4abf-b9a0-9b0f89bfe8bf
AZURE_AD_API_CLIENT_ID    ✅ e7525560-a7ae-4688-8ea9-6f1f923ef8c3
```

### 2.4 — `.env.production` dos frontends ✅

Ambos `frontend/portal/.env.production` e `frontend/dashboard/.env.production`:

```
VITE_DEV_BYPASS_AUTH=false
VITE_API_BASE_URL=https://cepac-api.redpond-877494a8.eastus.azurecontainerapps.io
VITE_AZURE_CLIENT_ID=39d6d992-23d8-4abf-b9a0-9b0f89bfe8bf
VITE_AZURE_API_CLIENT_ID=e7525560-a7ae-4688-8ea9-6f1f923ef8c3
VITE_AZURE_TENANT_ID=f398df9c-fd0c-4829-a003-c770a1c4a063
```

### 2.5 — Correção de bug: audience JWT ✅

`src/api/auth/azure_ad.py`: tokens v2.0 têm `aud: "api://<client_id>"`. Corrigido para aceitar
`[client_id, "api://client_id"]` — evita `InvalidAudienceError` no primeiro login real.

---

## Bloco 3 — CI/CD e Deploy ✅ CONCLUÍDO

**Concluído em:** 01/05/2026

### Fixes aplicados ao longo do processo

| Fix | Arquivo(s) | Commit |
|---|---|---|
| `--workers 2` incompatível com Container Apps | `infra/Dockerfile` | `02ec3a5` |
| `.dockerignore` excluía `frontend/dist/` do build context | `.dockerignore` | `ee827ef` |
| Migrations 008–014 ausentes no conftest de testes | `tests/integration/conftest.py` | `1fe9621` |
| `Event loop is closed` no pytest-asyncio 0.23 | `tests/integration/conftest.py`, `pytest.ini` | `bbe53bf` |
| `datetime` aware em coluna `TIMESTAMP WITHOUT TIME ZONE` | `src/api/auth/dependencies.py` | `1169180` |
| `audience` JWT sem prefixo `api://` | `src/api/auth/azure_ad.py` | `4b22542` |
| Credencial SSH para GitHub (dois accounts) | `~/.ssh/config` | — |

### Estado atual das imagens (01/05/2026)

- `cepacregistry.azurecr.io/cepac-api:sha-4d7d481` — com `DEV_BYPASS_AUTH=false`
- `cepacregistry.azurecr.io/cepac-portal:sha-4d7d481` — MSAL real, VITE_DEV_BYPASS_AUTH=false
- `cepacregistry.azurecr.io/cepac-dashboard:sha-4d7d481` — MSAL real, VITE_DEV_BYPASS_AUTH=false

### Verificar deploy

```bash
curl https://cepac-api.redpond-877494a8.eastus.azurecontainerapps.io/health

az containerapp logs show --name cepac-api --resource-group rg_spurbanismo_cepac --follow
az containerapp logs show --name cepac-portal --resource-group rg_spurbanismo_cepac --follow
```

---

## Bloco 3b — Testes de integração + CI ✅ CONCLUÍDO

**Concluído em:** 01/05/2026 — commits `4db34d1` → `b32535b` → `07167b5`

### Correções nos testes (lógica)

| Teste | Causa | Correção |
|---|---|---|
| `test_primeiro_login_cria_tecnico` | `datetime` aware em `TIMESTAMP WITHOUT TIME ZONE` | `.replace(tzinfo=None)` em `dependencies.py` |
| `test_post_medicao_nova` | Seed `006` ocupa `2026-10-01` | Payload movido para `2027-03-01` |
| `test_post_medicao_data_duplicada_retorna_422` | Efeito cascata | Payload movido para `2027-04-01` |
| `test_criar_solicitacao_pendente` | Status inicial é `EM_ANALISE`, não `PENDENTE` | Asserção corrigida em `test_portal.py` |
| `test_cancelar_nao_pendente_retorna_422` | `exception_handler(422)` stringificava `exc.detail` dict | `isinstance(exc, HTTPException)` antes de acessar `.detail` |

### Correções na infraestrutura de testes (conftest)

| Problema | Causa | Correção |
|---|---|---|
| `ValidationError: Extra inputs not permitted` | `DEEPSEEK_API_KEY` no ambiente local | `extra = "ignore"` no `Settings` (`config.py`) |
| `DEV_BYPASS_AUTH=true` no `.env` local | Todos os requests autenticados pelo bypass, 401 nunca disparado | `os.environ["DEV_BYPASS_AUTH"] = "false"` antes dos imports no conftest |
| `docker.errors.NotFound` no Ryuk | Docker rootless — container Ryuk inicializa e desaparece | `os.environ["TESTCONTAINERS_RYUK_DISABLED"] = "true"` no conftest |
| `RuntimeError: no current event loop` (Python 3.12+) | `asyncio.run()` no `pg_container` fechava o loop; `get_event_loop()` não cria loop implícito | `asyncio.set_event_loop(loop)` no fixture + `pg_container` depende de `event_loop` |
| `MEDICAO_JA_EXISTE` falso para `2027-03-01` | FK `operador_id → usuario.id` violada — UUID sintético do `DIRETOR_USER` não existia na tabela | `_seed_usuario()` insere o usuário sintético dentro da transação do teste |
| `mypy: Exception has no attribute detail` | Handler assinava `exc: Exception` mas acessava `.detail` diretamente | `isinstance(exc, HTTPException)` explícito antes de acessar `.detail` |

---

## Bloco 4 — Primeiro login real ⏳ PENDENTE

Pré-requisito: Bloco 3 concluído ✅

### 4.1 — Acessar o Portal

Abrir `https://cepac-portal.redpond-877494a8.eastus.azurecontainerapps.io` com uma conta
do tenant SP Urbanismo (`@spurbanismo.sp.gov.br`). O primeiro login cria o usuário no banco
com `papel=TECNICO` (Decisão D4).

### 4.2 — Promover primeiro DIRETOR

O primeiro usuário que logar vira TECNICO. No bootstrap inicial, promover diretamente no banco:

```sql
UPDATE usuario SET papel = 'DIRETOR' WHERE upn = 'seu.email@spurbanismo.sp.gov.br';
```

Após ter um DIRETOR logado, os demais podem ser promovidos via endpoint:

```bash
# Listar usuários
curl -H "Authorization: Bearer <TOKEN_DIRETOR>" \
  https://cepac-api.redpond-877494a8.eastus.azurecontainerapps.io/admin/usuarios

# Promover
curl -X PATCH \
  -H "Authorization: Bearer <TOKEN_DIRETOR>" \
  -H "Content-Type: application/json" \
  -d '{"papel": "DIRETOR"}' \
  https://cepac-api.redpond-877494a8.eastus.azurecontainerapps.io/admin/usuarios/<UUID>/papel
```

### 4.3 — Validar dados no Dashboard

Acessar `https://cepac-dashboard.redpond-877494a8.eastus.azurecontainerapps.io` e conferir:
- Big Numbers: CEPACs em circulação = 193.779
- Saldos por setor batem com a planilha `OUCAE_ESTOQUE_abr_rv01.xlsx`
- Velocímetro 2029 indica percentual correto a partir de 01/01/2004

---

## Bloco 5 — Blob Storage (documentos de processo) ⏳ PENDENTE

Pré-requisito: Bloco 4 concluído.

### 5.1 — Criar container de documentos

```bash
az storage container create \
  --name cepac-documentos \
  --account-name cepacstorageacct \
  --public-access off
```

### 5.2 — Configurar na API

```bash
KEY=$(az storage account keys list \
  --account-name cepacstorageacct \
  --resource-group rg_spurbanismo_cepac \
  --query "[0].value" -o tsv)

az containerapp update \
  --name cepac-api \
  --resource-group rg_spurbanismo_cepac \
  --set-env-vars \
    "AZURE_BLOB_ACCOUNT_NAME=cepacstorageacct" \
    "AZURE_BLOB_ACCOUNT_KEY=$KEY" \
    "AZURE_BLOB_CONTAINER_NAME=cepac-documentos"
```

### 5.3 — Testar upload de documento

Via Portal: abrir uma solicitação existente → aba Documentos → fazer upload de um PDF.
Verificar que o blob aparece em `cepacstorageacct / cepac-documentos`.

---

## Bloco 6 — Melhoria de cálculo de saldo (planejado)

Identificado durante validação dos dados do dashboard (01/05/2026).

**Problema:** o cálculo de `total_consumido` nos setores considera todas as movimentações,
incluindo as de desvinculação. Desvinculações devem ser excluídas do consumo (o setor
"devolve" área quando uma proposta é desvinculada).

**Decisão:** filtrar `proposta.requerimento != 'DESVINCULACAO'` no cálculo do saldo por setor.

**Arquivos afetados:**
- `src/core/repositories/saldo_repository.py` — `calcular_saldo()`
- `src/core/repositories/dashboard_repository.py` — `calcular_ocupacao_setores()`
- Testes correspondentes

**Estado:** planejado, não implementado.

---

## Referência rápida — recursos Azure

| Recurso | Endereço |
|---|---|
| API | `https://cepac-api.redpond-877494a8.eastus.azurecontainerapps.io` |
| Portal | `https://cepac-portal.redpond-877494a8.eastus.azurecontainerapps.io` |
| Dashboard | `https://cepac-dashboard.redpond-877494a8.eastus.azurecontainerapps.io` |
| PostgreSQL | `cepac-pgdb.postgres.database.azure.com` |
| ACR | `cepacregistry.azurecr.io` |
| Storage | `cepacstorageacct` |
| Tenant ID | `f398df9c-fd0c-4829-a003-c770a1c4a063` |
| Subscription | `506f92c4-471f-4f5f-8b5c-9ff96ad5ce8c` |
| Resource Group | `rg_spurbanismo_cepac` |
| App Reg API Client ID | `e7525560-a7ae-4688-8ea9-6f1f923ef8c3` |
| App Reg Frontend Client ID | `39d6d992-23d8-4abf-b9a0-9b0f89bfe8bf` |
