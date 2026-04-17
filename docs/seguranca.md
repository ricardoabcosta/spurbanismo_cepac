# Relatório de Segurança — CEPAC Core Engine

**Data:** 2026-04-16
**Revisor:** Agente de Segurança (Claude Sonnet 4.6)
**Escopo:** Core Engine (`src/`) + schema SQL (`migrations/`) + infraestrutura de deploy (`infra/`, `.github/`)
**Versão analisada:** estado atual do repositório em `/home/rcosta/Projetos/CEPAC`

---

## 1. Resumo Executivo

O Core Engine apresenta **postura de segurança geral satisfatória** para operação atrás do Azure APIM. Foram identificados:

- **8 itens CONFORME**
- **2 itens PARCIAL** (sem comprometer a operação, mas requerem atenção)
- **0 itens NÃO CONFORME**

### Achados principais

| # | Classificação | Achado |
|---|--------------|--------|
| 1 | PARCIAL | `get_operador()` retorna `"desconhecido"` em vez de 401 quando o JWT não pode ser decodificado |
| 2 | PARCIAL | `numero_processo_sei` valida apenas não-vazio — não há regex que bloqueie caracteres especiais perigosos |

Nenhum achado bloqueia o deploy, mas ambos devem ser endereçados antes da entrada em produção com usuários externos (fase GOV.BR).

---

## 2. Tabela do Checklist

| # | Item | Status | Evidência | Observação |
|---|------|--------|-----------|------------|
| 1 | API retorna 401 sem header `Authorization` | **CONFORME** | `dependencies.py:54` — `Header(...)` (obrigatório) | FastAPI retorna 422 automaticamente se o header estiver ausente. Nota: retorna 422, não 401 — ver achado 1 |
| 2 | Confiança no APIM documentada (sem validação de assinatura) | **CONFORME** | `dependencies.py:3-6`, `dependencies.py:58-59` | Comentário explícito de módulo e docstring da função documentam a responsabilidade do APIM |
| 3 | Extração segura do operador (sem header arbitrário do cliente) | **CONFORME** | `dependencies.py:54,64-65` | Extrai exclusivamente do payload JWT (`upn`/`sub`), não de headers customizados do cliente |
| 4 | Campos decimais usam `Decimal` (não `float`) | **CONFORME** | `dtos.py:9,23,33-40,58`, `schemas/solicitacao.py:4,17`, `validators/brooklin.py:12`, `validators/chucri_zaidan.py:18-20`, `saldo_repository.py:75-81,133` | Todos os valores monetários/m² usam `Decimal` end-to-end |
| 5 | Sanitização do SEI previne caracteres especiais | **PARCIAL** | `schemas/solicitacao.py:25-29`, `schemas/movimentacao.py:30-35`, `validators/sei.py:19-22` | Valida apenas não-vazio e strip; sem regex que bloqueie injeção de caracteres especiais |
| 6 | Sem rotas `PUT`/`DELETE` para `movimentacao` | **CONFORME** | `routes/movimentacoes.py:21`, `routes/titulos.py`, `routes/saldo.py`, `routes/solicitacoes.py` | Somente `POST` e `GET` expostos; nenhuma rota de mutação direta de `movimentacao` |
| 7 | Trigger SQL bloqueia `UPDATE`/`DELETE` em `movimentacao` | **CONFORME** | `migrations/001_initial_schema.sql:190-212` | Dois triggers (`trg_movimentacao_no_update`, `trg_movimentacao_no_delete`) bloqueiam com `RAISE EXCEPTION` |
| 8 | ORM SQLAlchemy sem raw SQL interpolado | **CONFORME** | `titulo_repository.py`, `saldo_repository.py`, `routes/saldo.py:49-51` | Todas as queries usam construtores ORM (`select()`, `.where()`, `.join()`); `text()` usado apenas em `server_default` (valores literais fixos, sem interpolação) |
| 9 | Rate limiting configurado (APIM) | **CONFORME** | `docs/planejamento.md:254,514` | Documentado como responsabilidade do APIM; fora do escopo da API |
| 10 | Sem credenciais hardcoded no código | **CONFORME** | `config.py:10`, `infra/Dockerfile`, `.github/workflows/ci.yml:110-112` | `config.py` tem URL padrão de desenvolvimento (localhost); produção lê de secret Azure Key Vault via `secretRef`; credenciais ACR via GitHub Secrets |

---

## 3. Achados Detalhados

### Achado 1 — PARCIAL: Comportamento do `get_operador()` em caso de falha de decodificação JWT

**Arquivo:** `src/api/dependencies.py`, linhas 54–67

**Descrição:**
A função `get_operador()` captura qualquer exceção durante a decodificação do JWT e retorna a string `"desconhecido"` em vez de levantar uma exceção. Isso significa que, se o header `Authorization` estiver presente mas contiver um token malformado (não-JWT, string aleatória, payload inválido), a requisição prosseguirá com `operador="desconhecido"` registrado na movimentação.

```python
# dependencies.py:62-67
try:
    token = authorization.replace("Bearer ", "")
    payload = jwt.decode(token, options={"verify_signature": False})
    return payload.get("upn") or payload.get("sub") or "desconhecido"
except Exception:
    return "desconhecido"  # ← requisição prossegue sem operador identificado
```

Adicionalmente, o parâmetro `Header(...)` (obrigatório) faz o FastAPI retornar **HTTP 422** (não 401) quando o header `Authorization` está ausente — comportamento tecnicamente correto para o contexto FastAPI mas semanticamente inadequado para um endpoint de autenticação.

**Risco:** Baixo em ambiente APIM (o APIM garante JWT válido). Médio se a porta for acessada diretamente (cenário de misconfiguration de network policy): movimentações seriam registradas com `operador="desconhecido"`, comprometendo o audit trail exigido pela CVM/TCM.

**Recomendação:**
1. Substituir `except Exception: return "desconhecido"` por `except Exception: raise HTTPException(status_code=401, detail="Token inválido")`.
2. Avaliar o uso de `Header(..., alias="Authorization")` combinado com um handler que retorne 401 (em vez de 422) para header ausente, se o contrato da API exigir isso.
3. Documentar explicitamente no `README` / runbook que o endpoint `/health` (sem autenticação) é o único endpoint público — todos os demais dependem do APIM.

---

### Achado 2 — PARCIAL: `numero_processo_sei` sem validação de formato por regex

**Arquivos:**
- `src/api/schemas/solicitacao.py`, linhas 18–29
- `src/api/schemas/movimentacao.py`, linhas 20–35
- `src/core/engine/validators/sei.py`, linhas 19–22

**Descrição:**
O campo `numero_processo_sei` é validado apenas quanto à presença e não-vazio (`.strip()`). Não há regex que restrinja o formato esperado (ex.: `6016.2024/0000001-0`). Isso permite que valores como `'; DROP TABLE movimentacao;--` ou strings com caracteres Unicode de controle sejam aceitos como entrada válida.

Embora o ORM SQLAlchemy mitigue completamente a injeção SQL (nenhuma interpolação de string identificada), o valor é armazenado nas colunas `movimentacao.numero_processo_sei` (VARCHAR 50) e `solicitacao_vinculacao.numero_processo_sei` (VARCHAR 50) e exibido de volta nas respostas da API. Valores maliciosos podem causar problemas em integrações downstream (ex.: sistemas SEI que parsem o número), logs corrompidos, ou XSS em interfaces que exibam o campo sem sanitização.

**Risco:** Baixo para injeção SQL (ORM parameterizado). Médio para integridade de dados e integrações downstream.

**Recomendação:**
Adicionar um `field_validator` com regex correspondendo ao padrão oficial do SEI SP. Exemplo:

```python
import re

SEI_PATTERN = re.compile(r"^\d{4}\.\d{4}/\d{7}-\d$")

@field_validator("numero_processo_sei")
@classmethod
def validar_formato_sei(cls, v: str) -> str:
    v = v.strip()
    if not v:
        raise ValueError("numero_processo_sei não pode ser vazio")
    if not SEI_PATTERN.fullmatch(v):
        raise ValueError("numero_processo_sei deve seguir o formato NNNN.AAAA/NNNNNNN-D")
    return v
```

Aplicar nos schemas `SolicitacaoIn`, `MovimentacaoIn` e no validator `sei.py`.

---

## 4. Itens Fora do Escopo da API

Os controles abaixo são responsabilidade do Azure APIM e/ou da infraestrutura Azure, não do Core Engine Python:

| Controle | Responsável | Evidência / Referência |
|----------|------------|------------------------|
| Validação de assinatura do JWT (Azure AD / GOV.BR) | Azure APIM | `dependencies.py:3-6`; `docs/planejamento.md:263` |
| Rate limiting nos endpoints de solicitação | Azure APIM | `docs/planejamento.md:254,514` |
| Terminação TLS (HTTPS) | Azure APIM + Container Apps ingress | `infra/azure/container-app.yaml:39` (`allowInsecure: false`) |
| Isolamento de rede (API não acessível diretamente) | Azure network policy / VNet | `docs/planejamento.md:509`; responsabilidade de infra |
| Rotação de credenciais do banco de dados | Azure Key Vault + Container Apps secrets | `infra/azure/container-app.yaml:58-60` |
| Autenticação GOV.BR (fase 2) | Azure APIM | `docs/planejamento.md:681` |

---

## 5. Conclusão

O Core Engine CEPAC **pode ser considerado seguro para deploy atrás do Azure APIM**, com as seguintes condições:

**Pré-condições obrigatórias antes de produção:**
1. A porta 8000 do Container App deve ser acessível **exclusivamente** pelo APIM via VNet/network policy — este é o controle de segurança primário que sustenta toda a arquitetura de autenticação.
2. O achado 1 (degradação silenciosa do operador) deve ser corrigido antes da fase GOV.BR para garantir integridade do audit trail exigido pela CVM/TCM.
3. O achado 2 (ausência de regex no SEI) deve ser corrigido para garantir integridade de dados e segurança em integrações downstream.

**Pontos fortes identificados:**
- Uso consistente de `Decimal` em todos os cálculos financeiros — sem risco de erro de ponto flutuante.
- Proteção append-only de `movimentacao` com dois triggers SQL independentes — audit trail protegido mesmo contra acesso direto ao banco.
- ORM SQLAlchemy parameterizado sem interpolação de strings — sem superfície de injeção SQL.
- Dockerfile multi-stage com usuário não-root (`cepac`) e sem credenciais hardcoded.
- Credenciais de produção gerenciadas via Azure Key Vault com Managed Identity — sem segredos em variáveis de ambiente planas.
- Arquitetura de confiança no APIM documentada em múltiplos pontos do código.
