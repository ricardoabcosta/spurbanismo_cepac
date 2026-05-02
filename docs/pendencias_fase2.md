# Pendências Fase 2 — CEPAC SP Urbanismo

> Documento de controle das atividades que restam para finalizar a Fase 2 em produção.
> Atualizado em: 02/05/2026 (Bloco 7 concluído — gerenciamento de usuários via portal)

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
| CI/CD — deploy automático | ⏳ Job `deploy` adicionado, aguarda `AZURE_CREDENTIALS` | 02/05/2026 |
| Testes de integração | ✅ 35/35 passando local e no CI (commit b32535b) | 01/05/2026 |
| Bugs do portal (auth + cache) | ✅ Corrigidos e em produção (commit 9e8de63) | 02/05/2026 |
| Primeiro login real | ✅ Confirmado — portal e dashboard | 02/05/2026 |
| Primeiro DIRETOR promovido | ✅ ricardoabinader@prodam.sp.gov.br | 02/05/2026 |
| Blob Storage funcional | ✅ Container criado + API configurada | 02/05/2026 |
| Gerenciamento de usuários (Bloco 7) | ✅ T22 backend + T23 frontend em produção | 02/05/2026 |
| Deploy automático CI → Azure | ⏳ Aguarda secret `AZURE_CREDENTIALS` no GitHub | 02/05/2026 |

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

### Estado atual das imagens (02/05/2026 — Bloco 7 em produção)

- `cepacregistry.azurecr.io/cepac-api:sha-05c693c` — Bloco 7 backend (`GET /admin/me` + gestão usuários)
- `cepacregistry.azurecr.io/cepac-portal:sha-05c693c` — Bloco 7 frontend (UserContext + `/admin/usuarios`)
- `cepacregistry.azurecr.io/cepac-dashboard:sha-05c693c` — sem mudanças funcionais

Revisões ativas: `cepac-api--0000020`, `cepac-portal--0000021`, `cepac-dashboard--0000015`

> **Nota:** script `scripts/deploy.sh --status` mostra em tempo real o que cada Container App está rodando vs o que existe no ACR.

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

## Bloco 3c — Bugs do portal no primeiro deploy real ✅ CONCLUÍDO

**Concluído em:** 02/05/2026

Bugs encontrados e corrigidos após a ativação do Azure AD real (DEV_BYPASS_AUTH=false).

### Fixes aplicados

| Fix | Arquivo(s) | Commit | Autor |
|---|---|---|---|
| favicon.svg ausente em `public/` → 404 | `frontend/portal/public/favicon.svg`, `frontend/dashboard/public/favicon.svg` | `231e994` | Claude |
| `dashboard/index.html` referenciava `/vite.svg` inexistente | `frontend/dashboard/index.html` | `231e994` | Claude |
| Interceptor Axios enviava requisição sem token quando `acquireTokenSilent` levantava exceção | `frontend/portal/src/api/client.ts`, `frontend/dashboard/src/api/client.ts` | `e151bed` | Ricardo |
| `navigateToLoginRequestUrl` ausente — MSAL não retornava à rota original após login | `frontend/portal/src/authConfig.ts` | `e8ea951` | Ricardo |
| `ProtectedRoute` renderizava children antes de `isAuthenticated` ser confirmado | `frontend/portal/src/components/ProtectedRoute.tsx` | `03a5180` | Ricardo |
| Interceptor Axios retornava `config` sem `Authorization` quando `accounts.length === 0` → API recebia requisição sem token → 401 | `frontend/portal/src/api/client.ts` | `ff5e043` | Claude |
| `index.html` sem `Cache-Control: no-store` → browser usava bundle antigo cacheado com `immutable` após novo deploy | `infra/nginx-spa.conf`, `infra/nginx-spa-dashboard.conf` | `9e8de63` | Claude |

### Raiz dos bugs

| Problema | Causa raiz |
|---|---|
| Portal 401 após login | `client.ts` retornava requisição sem Bearer quando `getAllAccounts()` vazia — enviava request ao invés de redirecionar para login |
| Browser rodando bundle antigo após deploy | nginx não setava `Cache-Control: no-store` no `index.html`; browser aplicava heuristic caching e servia HTML velho que apontava para bundle cacheado com `immutable` |

### Padrão correto do interceptor Axios (portal = dashboard)

```typescript
if (accounts.length === 0) {
  await msalInstance.loginRedirect(loginRequest);
  return new Promise(() => undefined); // nunca resolve — browser já navegou
}
try {
  const token = await msalInstance.acquireTokenSilent({...});
  config.headers.Authorization = `Bearer ${token.accessToken}`;
  return config;
} catch (error) {
  if (error instanceof InteractionRequiredAuthError) {
    await msalInstance.loginRedirect(loginRequest);
  }
  return new Promise(() => undefined);
}
```

---

## Bloco 4 — Primeiro login real ✅ CONCLUÍDO

**Concluído em:** 02/05/2026 — login confirmado no portal e no dashboard; `ricardoabinader@prodam.sp.gov.br` promovido a DIRETOR.

Pré-requisito: Bloco 3c concluído ✅

> **Importante:** ao testar após um novo deploy, abrir o portal em **janela anônima/privativa**
> para garantir sessionStorage e cache zerados. Com o fix do nginx (Bloco 3c), `index.html` passa
> a ser `no-store` e o browser sempre buscará o bundle correto em deploys futuros.

### 4.1 — Acessar o Portal

Abrir `https://cepac-portal.redpond-877494a8.eastus.azurecontainerapps.io` com uma conta
do tenant SP Urbanismo (`@spurbanismo.sp.gov.br`). O primeiro login cria o usuário no banco
com `papel=TECNICO` (Decisão D4).

### 4.2 — Promover primeiro DIRETOR ✅

Executado via psql em 02/05/2026:

```sql
UPDATE usuario SET papel = 'DIRETOR' WHERE upn = 'ricardoabinader@prodam.sp.gov.br';
-- id: edc42106-7059-4647-8ea8-f6ac7c59e308
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

## Bloco 5 — Blob Storage (documentos de processo) ✅ CONCLUÍDO

**Concluído em:** 02/05/2026

### 5.1 — Container de documentos ✅

Container `cepac-documentos` criado em 17/04/2026 (provisionamento inicial), acesso privado.
Confirmado em 02/05/2026 via `az storage container show` — vazio, aguardando primeiro upload real.

### 5.2 — API configurada ✅

Env vars já presentes na Container App `cepac-api` desde o provisionamento:

```
AZURE_BLOB_ACCOUNT_NAME    = cepacstorageacct
AZURE_BLOB_ACCOUNT_KEY     → secretRef: blob-account-key
AZURE_BLOB_CONTAINER_NAME  = cepac-documentos
```

### 5.3 — Teste de upload

Pendente confirmação manual via Portal (abrir solicitação → aba Documentos → upload PDF).

---

## Bloco 7 — Gerenciamento de usuários via portal ✅ CONCLUÍDO

**Concluído em:** 02/05/2026 — commits `9bb2900` (código) + deploy manual para `sha-05c693c`

### O que foi implementado

Tela `/admin/usuarios` no portal, acessível apenas para conta com papel `DIRETOR`.
Elimina a necessidade de acionar a API diretamente para promover ou desativar usuários.

| Componente | Arquivo | Descrição |
|---|---|---|
| Backend — schemas | `src/api/schemas/admin.py` | `UsuarioOut`, `PapelUpdate`, `AtivoUpdate` |
| Backend — rotas | `src/api/routes/admin.py` | `GET /admin/me`, `GET /admin/usuarios`, `PATCH .../papel`, `PATCH .../ativo` |
| Frontend — tipos | `frontend/portal/src/types/api.ts` | `PapelUsuario`, `UsuarioOut` |
| Frontend — API | `frontend/portal/src/api/admin.ts` | `getMeuPerfil`, `listarUsuarios`, `alterarPapel`, `alterarAtivo` |
| Frontend — contexto | `frontend/portal/src/contexts/UserContext.tsx` | Busca `GET /admin/me` após auth MSAL, expõe `isDiretor` |
| Frontend — página | `frontend/portal/src/pages/UsuariosAdminPage.tsx` | Tabela com select de perfil + toggle ativo/inativo |
| Frontend — rota | `frontend/portal/src/App.tsx` | `/admin/usuarios` + `UserProvider` |
| Frontend — nav | `frontend/portal/src/pages/PropostasPage.tsx` | Botão "Usuários" visível apenas para `isDiretor` |

### Comportamento

- Usuários criados automaticamente no primeiro login Azure AD (`papel=TECNICO`)
- DIRETOR vê botão "Usuários" na nav bar → acessa `/admin/usuarios`
- TECNICO não vê o botão; URL direta retorna 403 do backend
- Na tabela: a própria conta tem select/toggle desabilitados (guarda contra auto-promoção/desativação)

---

## Bloco 8 — Deploy automático CI → Azure ⏳ PENDENTE

**Problema identificado em:** 02/05/2026

O CI constrói e faz push das imagens para o ACR mas **não atualiza os Container Apps**.
Isso cria um gap silencioso: ACR tem imagem nova, Azure continua rodando a antiga.

### O que já foi feito

- Job `deploy` adicionado ao `.github/workflows/ci.yml` (commit `05c693c`)
- Script local `scripts/deploy.sh` criado (commit `41308f7`) para deploy manual e diagnóstico

### O que falta — ação necessária (DIRETOR / responsável infra)

**Criar o App Registration de deploy e adicionar o secret `AZURE_CREDENTIALS` no GitHub.**

O `az ad sp create-for-rbac` falha localmente (bug az CLI + Python 3.14 no Fedora 43).
Usar o **Portal do Azure** em vez do CLI:

#### Passo 1 — Criar o App Registration

1. [portal.azure.com](https://portal.azure.com) → **Microsoft Entra ID** → **App registrations** → **+ New registration**
2. Name: `cepac-github-deploy` → **Register**
3. Anote os valores exibidos:
   - **Application (client) ID** ← guardar aqui: `_______________`
   - **Directory (tenant) ID**: `f398df9c-fd0c-4829-a003-c770a1c4a063` (já conhecido)

#### Passo 2 — Criar o Client Secret

1. Ainda no app → **Certificates & secrets** → **New client secret**
2. Description: `github-actions` · Expires: **24 months** → **Add**
3. **Copiar o campo `Value` imediatamente** (desaparece ao sair da tela)

#### Passo 3 — Atribuir role Contributor no Resource Group

1. [portal.azure.com](https://portal.azure.com) → **Resource groups** → `rg_spurbanismo_cepac`
2. **Access control (IAM)** → **+ Add** → **Add role assignment**
3. Role: **Contributor** → Next → **+ Select members** → buscar `cepac-github-deploy` → **Review + assign**

#### Passo 4 — Adicionar secret no GitHub

Repositório → **Settings → Secrets and variables → Actions → New repository secret**

Nome: `AZURE_CREDENTIALS`

Valor (preencher com os dados dos passos anteriores):
```json
{
  "clientId": "<Application (client) ID — Passo 1>",
  "clientSecret": "<Value copiado — Passo 2>",
  "subscriptionId": "506f92c4-471f-4f5f-8b5c-9ff96ad5ce8c",
  "tenantId": "f398df9c-fd0c-4829-a003-c770a1c4a063"
}
```

### Após configurar

Todo push para `main` irá automaticamente:
1. Rodar lint + testes + typecheck
2. Construir as 3 imagens Docker e fazer push para o ACR
3. **Atualizar os 3 Container Apps** com a nova imagem (job `deploy`)

### Enquanto não configurado — deploy manual

```bash
# Ver o que está rodando vs o que existe no ACR
./scripts/deploy.sh --status

# Deployar a HEAD atual (após CI completar o build)
./scripts/deploy.sh

# Deployar uma tag específica
./scripts/deploy.sh sha-9bb2900
```

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
