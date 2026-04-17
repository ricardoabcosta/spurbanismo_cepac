# Revisão de Código — CEPAC Core Engine

**Data:** 16/04/2026
**Revisor:** Agente de Revisão de Código (Claude Sonnet)
**Escopo:** Core Engine, Repositórios, API, Testes Unitários, Configuração
**Stack:** Python 3.12 + FastAPI + SQLAlchemy 2.x (async) + PostgreSQL 15

---

## 1. Resumo Executivo

| Status       | Quantidade |
|--------------|-----------|
| CONFORME     | 9         |
| PARCIAL      | 1         |
| NÃO CONFORME | 0         |

**Resultado geral:** o Core Engine apresenta qualidade elevada. Nenhum item foi classificado como NÃO CONFORME. Existe apenas um achado PARCIAL de baixo risco relacionado a um valor padrão (`default`) de credencial hardcoded em `src/config.py`, mitigado pelo mecanismo de sobrescrita via variável de ambiente e arquivo `.env`.

---

## 2. Tabela do Checklist

| # | Item | Status | Evidência | Observação |
|---|------|--------|-----------|------------|
| 1 | Sem `float` em cálculos financeiros | **CONFORME** | `src/core/engine/dtos.py:9,23,59`; todos os campos de área e valor usam `Decimal`. Busca por `float` em `/src` e `/tests` retornou zero ocorrências. | Conftest documenta explicitamente "nunca float" (linha 5). |
| 2 | Validators são funções puras | **CONFORME** | `validators/sei.py`, `capacity.py`, `brooklin.py`, `berrini.py`, `marginal_pinheiros.py`, `chucri_zaidan.py`, `jabaquara.py`, `quarantine.py` — nenhum import de SQLAlchemy, FastAPI, `requests` ou I/O. Recebem e retornam apenas DTOs. | Única dependência de "mundo externo" no `quarantine.py` é `datetime.now(timezone.utc)` (linha 26), necessária para calcular dias de quarentena — side effect aceitável e justificado. |
| 3 | Sem lógica de negócio nas rotas | **CONFORME** | `routes/solicitacoes.py:54–123`, `routes/saldo.py:48–79`, `routes/movimentacoes.py:39–58`, `routes/titulos.py:42–103` — rotas apenas orquestram: recebem payload, chamam repositório/engine, retornam resposta. | Cálculo `saldo_nr_disponivel = teto_nr - nr_total` em `saldo.py:65` é apresentação de dados (view layer), não regra de negócio. |
| 4 | `movimentacao` sem rota de modificação | **CONFORME** | `routes/movimentacoes.py` expõe apenas `@router.post("")` (linha 21). Ausência total de `@router.put`, `@router.patch` e `@router.delete` confirmada por busca nos arquivos de rotas. | Tabela `movimentacao` é append-only por design. |
| 5 | Seed idempotente | **CONFORME** | `migrations/002_seed_abril_2026.sql`: setores usam `ON CONFLICT (nome) DO NOTHING` (linha 36); títulos usam `WHERE NOT EXISTS (SELECT 1 FROM titulo_cepac WHERE codigo = ...)` (ex.: linha 74); movimentações seed usam `WHERE NOT EXISTS` por `(titulo_id, motivo='SEED_INICIAL')` (linhas 239–244). Toda a migration está envolta em `BEGIN`/`COMMIT`. | Cobertura de idempotência completa nos três tipos de entidade inseridos. |
| 6 | Cobertura dos cenários T01–T06 | **CONFORME** | T01 (`test_t01_berrini_nr.py`): 4 casos — bloqueio incondicional, saldo zerado, uso R aprovado, código de erro correto. T02 (`test_t02_chucri_zaidan.py`): 4 casos — borda exata, 1 centésimo acima, R aprovado, fórmula usando consumo total. T03 (`test_t03_formula_saldo.py`): 7 casos — propriedades `nr_total_comprometido` e `r_total_consumido`, valores do seed, NR zerado. T04 (`test_t04_quarentena.py`): 8 casos — 90 dias, 181 dias, 179 dias, 180 dias exatos, sem data, EM_ANALISE, CONSUMIDO, lote misto. T05 (`test_t05_sei.py`): 7 casos — vazio, espaços, None, tab, 1 caractere, precedência sobre validators setoriais. T06 (`test_t06_estresse_brooklin.py`): 8 casos — séries sequenciais 1ª–5ª, borda exata em 980.000, 1 centésimo acima, R aprovado após NR esgotado. | Total: 38 testes unitários cobrindo todos os cenários definidos no planejamento. |
| 7 | Imports sem circularidade | **CONFORME** | Cadeia verificada: `routes` importam `dependencies` e `repositories`; `dependencies` importa `config` e `rules_engine`; `rules_engine` importa `dtos` e `validators`; `validators` importam apenas `dtos`. Nenhum ciclo detectado. `app.py` usa importação lazy (`from src.api.dependencies import _AsyncSessionLocal`) dentro do lifespan para evitar ciclo com o job (linha 34 e 99). | Design correto de camadas: routes → dependencies → engine → dtos (fluxo unidirecional). |
| 8 | Tratamento de erros consistente | **CONFORME** | Erros de negócio retornam `ErroNegocioOut` via `Response` com `status_code=422` (`solicitacoes.py:86–98`). Erros 500 no job de expiração são capturados com `logger.exception` (`app.py:64`). `get_db()` faz `rollback` em exceções (`dependencies.py:50`). Handler global para 422 Pydantic em `app.py:148–182`. | Rotas de não-existência retornam 404 com `HTTPException` (`solicitacoes.py:60–63`, `titulos.py:82–85`). Cobertura de erros adequada para produção. |
| 9 | Nenhuma string hardcoded de credencial | **PARCIAL** | `src/config.py:10` — `database_url` possui valor default `"postgresql+asyncpg://cepac:cepac@localhost:5432/cepac"`. Credencial hardcoded como fallback de desenvolvimento. Em produção é sobrescrita via variável de ambiente `DATABASE_URL` ou arquivo `.env` (linhas 12–13 da classe `Config`). | Ver achado detalhado na seção 3. |
| 10 | `asyncio_mode = auto` no pytest.ini | **CONFORME** | `pytest.ini:3` — `asyncio_mode = auto`. Testes async não precisam de `@pytest.mark.asyncio` explícito. | Configuração correta para pytest-asyncio. |

---

## 3. Achados Detalhados

### 3.1 Credencial com valor default em `src/config.py` (PARCIAL)

**Arquivo:** `src/config.py:10`

```python
database_url: str = "postgresql+asyncpg://cepac:cepac@localhost:5432/cepac"
```

**Descrição:** O campo `database_url` possui um valor padrão hardcoded que inclui usuário e senha (`cepac:cepac`). Embora seja um valor claramente de desenvolvimento local (hostname `localhost`), a string com credenciais reside no código-fonte versionado.

**Impacto:** Baixo em produção, pois a variável de ambiente `DATABASE_URL` sobrescreve o default. O risco real é que um deploy mal configurado (sem `DATABASE_URL` definida) usaria o valor padrão e tentaria se conectar ao banco local — o que falhará em ambiente de cloud, mas não expõe credenciais de produção. O risco de vazamento de credenciais de produção via repositório é nulo desde que o `.env` de produção não seja commitado.

**Recomendação:** Remover o valor default do campo, forçando que a variável de ambiente seja sempre fornecida explicitamente:

```python
database_url: str  # sem default — DATABASE_URL é obrigatória
```

Alternativamente, manter o default apenas para ambientes de CI/teste, documentando explicitamente no código e no README que não é para uso em produção.

---

## 4. Pontos Fortes

### 4.1 Arquitetura de DTOs imutáveis e separação de responsabilidades

Os DTOs (`dtos.py`) são `dataclasses(frozen=True)`, garantindo imutabilidade durante o pipeline de validação. O `RulesEngine` não possui acesso ao banco de dados e não instancia modelos ORM — recebe apenas DTOs pré-montados. Essa separação elimina toda possibilidade de side effects no núcleo de regras.

### 4.2 Pattern de função pura em todos os validators

Cada validator setorial expõe uma única função `validar(solicitacao: SolicitacaoDTO) -> Optional[RulesError]`. Sem estado, sem I/O, sem dependências externas. Isso torna o código diretamente testável sem mocks e elimina a necessidade de fixtures de banco nos testes unitários.

### 4.3 Fail-fast com encadeamento ordenado de validators

A cadeia `sei → capacity → <setorial> → quarantine` no `RulesEngine` garante falha rápida: o validator mais barato (SEI) executa primeiro, impedindo que cálculos desnecessários sejam realizados. O retorno no primeiro erro encontrado (`rules_engine.py:72–74`) é correto.

### 4.4 Cálculo de saldo sempre derivado de movimentações (append-only)

O `saldo_repository.py` nunca lê de coluna calculada — sempre agrega a partir da tabela `movimentacao`. Isso garante auditabilidade completa e suporte a consultas point-in-time via `data_referencia` para fins de CVM/TCM (`saldo_repository.py:21–134`).

### 4.5 Proteção contra corrida entre aprovações paralelas

Os validators setoriais incluem `nr_em_analise` no cômputo de "comprometido" (ex.: `brooklin.py:26`, `marginal_pinheiros.py:26–31`, `jabaquara.py:23`). Solicitações ainda em análise já reservam saldo, impedindo que aprovações concorrentes ultrapassem o teto setorial.

### 4.6 Fórmula especial Chucri Zaidan implementada corretamente

O validator `chucri_zaidan.py` implementa corretamente a fórmula que agrega R consumido + R em análise + NR comprometido contra o TETO_NR (`chucri_zaidan.py:37–41`), garantindo que a reserva residencial obrigatória da Lei 16.975/2018 seja preservada indiretamente.

### 4.7 Tratamento robusto de timezone no validator de quarentena

O `quarantine.py` normaliza o timezone de `data_desvinculacao` antes da comparação (`quarantine.py:42–44`), evitando `TypeError` para datas naive armazenadas sem timezone no banco.

### 4.8 Seed de dados com idempotência completa

A migration `002_seed_abril_2026.sql` utiliza três mecanismos distintos de idempotência (ON CONFLICT, WHERE NOT EXISTS por código, WHERE NOT EXISTS por titulo_id+motivo), todos envolvidos em uma única transação com `BEGIN`/`COMMIT`. Seguro para ser re-executado em caso de falha parcial.

### 4.9 Job de expiração TTL resiliente

O loop `_run_expiry_job_loop()` em `app.py` captura todas as exceções com `logger.exception` e continua executando (`app.py:63–65`), garantindo que uma falha pontual no job não derrube a aplicação.

### 4.10 Cobertura de casos de borda nos testes

Os testes T02, T04 e T06 verificam explicitamente os casos de borda: exatamente no limite (aprovado), 1 centésimo acima (bloqueado). Isso garante que a comparação `>` (e não `>=`) está corretamente implementada nos validators.

---

## 5. Veredito Final

### **Aprovado com ressalvas**

O Core Engine está adequado para produção. A arquitetura é sólida, os validators são corretos e testados com boa cobertura de casos de borda. Não foram encontradas violações críticas de qualidade.

**Condição para aprovação irrestrita:**

1. **Obrigatória (antes do deploy em produção):** Remover o valor padrão hardcoded de `database_url` em `src/config.py` ou garantir documentação explícita de que `DATABASE_URL` é variável de ambiente obrigatória em todos os ambientes de produção/homologação. Verificar que o arquivo `.env` de produção não está no repositório (confirmar `.gitignore`).

**Recomendações adicionais (não bloqueantes):**

2. Adicionar logging de erros de negócio na rota `POST /solicitacoes` (atualmente apenas o job TTL e exceções inesperadas são logadas; erros de negócio como TETO_NR_EXCEDIDO não produzem log, o que dificulta auditoria operacional).
3. Adicionar testes para o setor Marginal Pinheiros e Jabaquara com cenários de borda análogos ao T06, cobrindo os cinco setores de forma completa.
4. Avaliar se o `get_operador` em `dependencies.py:54–67` deve retornar `"desconhecido"` silenciosamente ou levantar 401 quando o JWT for inválido — dependendo da política de segurança acordada com o Azure APIM.
