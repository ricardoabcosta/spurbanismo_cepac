# Pendências Fase 2 — CEPAC SP Urbanismo

> Documento de controle das atividades que restam para finalizar a Fase 2 em produção.
> Atualizado em: 17/04/2026

---

## Status geral

| Bloco | Estado |
|---|---|
| Código (Fase 1 + Fase 2) | ✅ Concluído |
| Infraestrutura Azure | ✅ Provisionada |
| Banco de dados populado | ✅ 237 títulos, 197 propostas |
| CORS configurado | ✅ URLs reais |
| GitHub Secrets (parcial) | ✅ ACR + VITE_API_URL + TENANT_ID |
| App Registration | ⏳ Aguardando Infra |
| Primeiro deploy CI/CD | ⏳ Bloqueado pelo App Registration |
| Blob Storage funcional | ⏳ Bloqueado pelo primeiro deploy |

---

## Bloco 1 — App Registration (pré-requisito de tudo)

**Responsável:** Infra / Prodam  
**Bloqueio:** todos os itens abaixo dependem deste

### O que solicitar

Criar **2 registros** no Azure AD (Entra ID) do tenant `f398df9c-fd0c-4829-a003-c770a1c4a063`:

#### Registro 1 — CEPAC-API (backend)

| Campo | Valor |
|---|---|
| Nome | `CEPAC-API` |
| Tipo de conta | Contas somente neste diretório |
| URI de redirecionamento | (nenhum — API sem UI) |
| Expose an API → Application ID URI | `api://<CLIENT_ID_GERADO>` |
| Scope a criar | `CEPAC.Access` (consentimento: Admins and users) |

#### Registro 2 — CEPAC-Frontend (portal + dashboard)

| Campo | Valor |
|---|---|
| Nome | `CEPAC-Frontend` |
| Tipo de conta | Contas somente neste diretório |
| URI de redirecionamento (SPA) | `https://cepac-portal.redpond-877494a8.eastus.azurecontainerapps.io` |
| URI de redirecionamento (SPA) | `https://cepac-dashboard.redpond-877494a8.eastus.azurecontainerapps.io` |
| URI de redirecionamento (dev) | `http://localhost:3000` |
| URI de redirecionamento (dev) | `http://localhost:3001` |
| API Permissions | `CEPAC-API / CEPAC.Access` (delegated) |

> **Retorno esperado:** `CLIENT_ID` do Registro 1 e `CLIENT_ID` do Registro 2.

---

## Bloco 2 — Configuração pós-App Registration

Executar **em ordem** assim que os CLIENT_IDs chegarem.

### 2.1 — Remover DEV_BYPASS_AUTH

O bypass foi criado para permitir testes locais enquanto o App Registration não existe.
**Deve ser removido antes do primeiro deploy em produção.**

Arquivos a alterar:

- `.env` → remover ou definir `DEV_BYPASS_AUTH=false`
- `frontend/portal/.env` → remover `VITE_DEV_BYPASS_AUTH=true`
- `frontend/dashboard/.env` → remover `VITE_DEV_BYPASS_AUTH=true`

> O código do bypass (`DEV_BYPASS` em `ProtectedRoute`, `client.ts`, `main.tsx`,
> `dependencies.py`) pode permanecer como flag de emergência, desde que a var
> não esteja definida. Vite remove o código morto no build de produção.

### 2.2 — Atualizar variáveis de ambiente da API

Na cepac-api (Azure Container App ou `.env`):

```
AZURE_AD_CLIENT_ID=<CLIENT_ID do Registro 1 — CEPAC-API>
```

```bash
az containerapp update \
  --name cepac-api \
  --resource-group rg_spurbanismo_cepac \
  --set-env-vars "AZURE_AD_CLIENT_ID=<CLIENT_ID>"
```

### 2.3 — Configurar GitHub Secrets restantes

```bash
gh secret set PORTAL_AZURE_CLIENT_ID   --body "<CLIENT_ID do Registro 2>" --repo ricardoabcosta/spurbanismo_cepac
gh secret set DASHBOARD_AZURE_CLIENT_ID --body "<CLIENT_ID do Registro 2>" --repo ricardoabcosta/spurbanismo_cepac
```

> `PORTAL_AZURE_CLIENT_ID` e `DASHBOARD_AZURE_CLIENT_ID` usam o **mesmo** CLIENT_ID
> (Registro 2 cobre os dois frontends).

### 2.4 — Validar `.env` local e `.env` frontends

`frontend/portal/.env`:
```
VITE_AZURE_CLIENT_ID=<CLIENT_ID do Registro 2>
VITE_DEV_BYPASS_AUTH=    # deixar vazio ou remover
```

`frontend/dashboard/.env`: idem.

`.env` (raiz):
```
AZURE_AD_CLIENT_ID=<CLIENT_ID do Registro 1>
DEV_BYPASS_AUTH=false
```

---

## Bloco 3 — Primeiro push CI/CD

Pré-requisito: Bloco 2 concluído.

### 3.1 — Disparar pipeline

```bash
git push origin main
```

O pipeline `.github/workflows/ci.yml` irá:
1. `lint` → `typecheck` → `test-unit` → `test-integ`
2. Build das imagens Docker (API, Portal, Dashboard) com os `VITE_*` injetados
3. Push para `cepacregistry.azurecr.io`
4. Deploy nos Container Apps via `az containerapp update --image`

### 3.2 — Verificar deploy

```bash
# Health check da API
curl https://cepac-api.redpond-877494a8.eastus.azurecontainerapps.io/health

# Logs em tempo real
az containerapp logs show --name cepac-api --resource-group rg_spurbanismo_cepac --follow
az containerapp logs show --name cepac-portal --resource-group rg_spurbanismo_cepac --follow
az containerapp logs show --name cepac-dashboard --resource-group rg_spurbanismo_cepac --follow
```

### 3.3 — Primeiro login real

Acessar `https://cepac-portal.redpond-877494a8.eastus.azurecontainerapps.io` e logar
com uma conta do tenant SP Urbanismo. O primeiro login cria o usuário no banco com
`papel=TECNICO` (Decisão D4).

---

## Bloco 4 — Blob Storage (documentos de processo)

Pré-requisito: Bloco 3 concluído (API rodando com imagem real).

### 4.1 — Obter chave da Storage Account

```bash
az storage account keys list \
  --account-name cepacstorageacct \
  --resource-group rg_spurbanismo_cepac \
  --query "[0].value" -o tsv
```

### 4.2 — Criar container de documentos

```bash
az storage container create \
  --name cepac-documentos \
  --account-name cepacstorageacct \
  --public-access off
```

### 4.3 — Configurar na API

```bash
az containerapp update \
  --name cepac-api \
  --resource-group rg_spurbanismo_cepac \
  --set-env-vars \
    "AZURE_BLOB_ACCOUNT_NAME=cepacstorageacct" \
    "AZURE_BLOB_ACCOUNT_KEY=<CHAVE>" \
    "AZURE_BLOB_CONTAINER_NAME=cepac-documentos"
```

Atualizar também `.env` local para testes.

### 4.4 — Testar upload de documento

Via Portal: abrir uma solicitação existente → aba Documentos → fazer upload de um PDF.
Verificar que o blob aparece em `cepacstorageacct / cepac-documentos`.

---

## Bloco 5 — Acesso inicial e configuração de usuários

### 5.1 — Promover primeiro DIRETOR

O primeiro usuário que logar vira TECNICO (D4). Para promover a DIRETOR:

```bash
# Descobrir o ID do usuário após o primeiro login
curl -H "Authorization: Bearer <TOKEN>" \
  https://cepac-api.redpond-877494a8.eastus.azurecontainerapps.io/admin/usuarios

# Promover
curl -X PATCH \
  -H "Authorization: Bearer <TOKEN_DIRETOR>" \
  -H "Content-Type: application/json" \
  -d '{"papel": "DIRETOR"}' \
  https://cepac-api.redpond-877494a8.eastus.azurecontainerapps.io/admin/usuarios/<UUID>/papel
```

> No bootstrap inicial, usar o banco diretamente:
> ```sql
> UPDATE usuario SET papel = 'DIRETOR' WHERE upn = 'seu.email@spurbanismo.sp.gov.br';
> ```

### 5.2 — Validar dados no Dashboard

Acessar `https://cepac-dashboard.redpond-877494a8.eastus.azurecontainerapps.io` e conferir:
- Big Numbers: CEPACs em circulação = 193.779
- Saldos por setor batem com a planilha `OUCAE_ESTOQUE_abr_rv01.xlsx`
- Velocímetro 2029 indica percentual correto a partir de 01/01/2004

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
