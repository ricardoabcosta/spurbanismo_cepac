# API CEPAC — Documentação de Endpoints

> **Stack:** Python 3.12 · FastAPI · SQLAlchemy 2.x (async) · PostgreSQL 15
> **Versão da documentação:** 16/04/2026

---

## Autenticação

A API não valida a assinatura do JWT internamente. O **Azure APIM** é responsável por autenticar e autorizar a requisição antes de encaminhá-la à aplicação. A API extrai o identificador do operador a partir dos claims `upn` ou `sub` do token JWT recebido no cabeçalho `Authorization: Bearer <token>` — sem reverificação de assinatura.

Toda operação que registra movimentação (POST /solicitacoes e POST /movimentacoes) utiliza esse identificador extraído como campo `operador` no registro de auditoria.

---

## Endpoints

### 1. POST /solicitacoes

**Propósito:** Submete uma solicitação de vinculação de títulos CEPAC a um processo SEI. Executa o motor de regras completo (validators SEI → capacidade → setorial → quarentena). Em caso de aprovação, transiciona os títulos para o estado `EM_ANALISE` e registra as movimentações. Em caso de reprovação, retorna HTTP 422 com corpo de erro estruturado.

#### Request Body

| Campo              | Tipo           | Obrigatório | Descrição                                                  |
|--------------------|----------------|:-----------:|------------------------------------------------------------|
| `setor`            | string         | Sim         | Nome do setor da OUC (ex.: `"Brooklin"`)                  |
| `uso`              | `"R"` ou `"NR"` | Sim        | Uso residencial (`R`) ou não-residencial (`NR`)            |
| `origem`           | `"ACA"` ou `"NUVEM"` | Sim  | Origem do CEPAC: leilão ACA ou nuvem                       |
| `area_m2`          | Decimal (> 0)  | Sim         | Área solicitada em m²                                      |
| `numero_processo_sei` | string (min 1) | Sim     | Número do processo SEI; não pode ser vazio ou só espaços   |
| `titulo_ids`       | array[UUID]    | Sim (min 1) | Lista de IDs dos títulos CEPAC a vincular                  |

#### Response Body — HTTP 200 (aprovado)

| Campo           | Tipo    | Descrição                              |
|-----------------|---------|----------------------------------------|
| `solicitacao_id` | UUID   | Identificador único da solicitação     |
| `status`        | string  | Sempre `"APROVADA"` neste caso         |
| `area_m2`       | Decimal | Área solicitada (eco do campo de entrada) |

#### Response Body — HTTP 422 (reprovado por regra de negócio)

| Campo           | Tipo            | Descrição                                                           |
|-----------------|-----------------|---------------------------------------------------------------------|
| `codigo_erro`   | string          | Código da regra violada (ver tabela de erros abaixo)               |
| `mensagem`      | string          | Mensagem legível descrevendo o motivo do bloqueio                   |
| `setor`         | string \| null  | Setor envolvido                                                     |
| `saldo_atual`   | Decimal \| null | Saldo NR disponível no momento da rejeição                          |
| `limite`        | Decimal \| null | Teto NR do setor ou da operação                                     |
| `dias_restantes`| int \| null     | Dias restantes de quarentena (apenas para `QUARENTENA_ATIVA`)       |

#### Exemplo — Request cURL

```bash
curl -X POST https://api.cepac.prefeitura.sp.gov.br/solicitacoes \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "setor": "Brooklin",
    "uso": "NR",
    "origem": "ACA",
    "area_m2": "100000.00",
    "numero_processo_sei": "6016.2024/0000001-0",
    "titulo_ids": ["00000000-0000-0000-0000-000000000001"]
  }'
```

#### Exemplo — Response 200

```json
{
  "solicitacao_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "status": "APROVADA",
  "area_m2": "100000.00"
}
```

#### Exemplo — Response 422

```json
{
  "codigo_erro": "TETO_NR_EXCEDIDO",
  "mensagem": "Setor Brooklin: teto NR de 980,000.00 m² excedido. Saldo disponível: 63,529.99 m².",
  "setor": "Brooklin",
  "saldo_atual": "63529.99",
  "limite": "980000.00",
  "dias_restantes": null
}
```

#### Códigos de erro possíveis

| Código                  | HTTP | Situação                                                                 |
|-------------------------|------|--------------------------------------------------------------------------|
| `NUMERO_SEI_OBRIGATORIO` | 422 | Campo `numero_processo_sei` ausente, vazio ou contendo apenas espaços    |
| `TETO_GLOBAL_EXCEDIDO`  | 422  | Capacidade total da OUCAE (4.600.000 m² NR) seria ultrapassada           |
| `TETO_NR_EXCEDIDO`      | 422  | Teto NR do setor seria ultrapassado (Brooklin, Marginal Pinheiros, Jabaquara, Berrini) |
| `RESERVA_R_VIOLADA`     | 422  | Pedido NR no Chucri Zaidan violaria a reserva residencial obrigatória     |
| `QUARENTENA_ATIVA`      | 422  | Título em período de quarentena (< 180 dias desde desvinculação)          |
| `TITULO_INDISPONIVEL`   | 422  | Título em estado diferente de `DISPONIVEL` (ex.: `EM_ANALISE`, `CONSUMIDO`) |
| `SETOR_INVALIDO`        | 422  | Nome do setor não reconhecido pelo motor de regras                        |
| —                       | 404  | Um ou mais `titulo_ids` não encontrados no banco de dados                 |

---

### 2. GET /saldo/{setor}

**Propósito:** Retorna o saldo de CEPACs NR de um setor. Suporta snapshot histórico via parâmetro `?data=YYYY-MM-DD` para fins de auditoria CVM/TCM. O saldo é sempre calculado dinamicamente a partir da tabela `movimentacao` — nunca de coluna pré-calculada.

#### Parâmetros

| Parâmetro | Localização | Obrigatório | Descrição                                                              |
|-----------|-------------|:-----------:|------------------------------------------------------------------------|
| `setor`   | path        | Sim         | Nome do setor (ex.: `Brooklin`, `Berrini`)                            |
| `data`    | query       | Não         | Data de referência para snapshot histórico no formato `YYYY-MM-DD`. Se omitido, retorna saldo atual. |

#### Response Body — HTTP 200

| Campo                   | Tipo    | Descrição                                                        |
|-------------------------|---------|------------------------------------------------------------------|
| `setor`                 | string  | Nome do setor consultado                                         |
| `data_referencia`       | date    | Data efetiva do snapshot (`YYYY-MM-DD`)                         |
| `nr_consumido_aca`      | Decimal | m² NR consumidos com origem ACA                                  |
| `nr_consumido_nuvem`    | Decimal | m² NR consumidos com origem NUVEM                                |
| `nr_em_analise`         | Decimal | m² NR em estado EM_ANALISE (reservados, ainda não confirmados)   |
| `nr_total_comprometido` | Decimal | Soma: `nr_consumido_aca + nr_consumido_nuvem + nr_em_analise`   |
| `saldo_nr_disponivel`   | Decimal | `teto_nr - nr_total_comprometido`                               |
| `teto_nr`               | Decimal | Teto NR do setor conforme parametrização                        |
| `bloqueado`             | boolean | `true` quando `saldo_nr_disponivel <= 0`                        |

#### Exemplo — Request cURL

```bash
# Saldo atual
curl https://api.cepac.prefeitura.sp.gov.br/saldo/Brooklin \
  -H "Authorization: Bearer <token>"

# Snapshot histórico em 31/12/2025
curl "https://api.cepac.prefeitura.sp.gov.br/saldo/Brooklin?data=2025-12-31" \
  -H "Authorization: Bearer <token>"
```

#### Exemplo — Response 200

```json
{
  "setor": "Brooklin",
  "data_referencia": "2026-04-16",
  "nr_consumido_aca": "716470.01",
  "nr_consumido_nuvem": "0.00",
  "nr_em_analise": "0.00",
  "nr_total_comprometido": "716470.01",
  "saldo_nr_disponivel": "263529.99",
  "teto_nr": "980000.00",
  "bloqueado": false
}
```

#### Códigos de erro possíveis

| Código HTTP | Situação                          |
|-------------|-----------------------------------|
| 404         | Setor não encontrado no banco de dados |

---

### 3. POST /movimentacoes

**Propósito:** Registra uma transição de estado manual de um título CEPAC. Utilizada para operações administrativas como devolver um título para `DISPONIVEL`, marcá-lo como `CONSUMIDO` ou colocá-lo em `QUARENTENA`. Toda transição é rastreada com o número do processo SEI e o operador autenticado.

#### Request Body

| Campo                 | Tipo                                              | Obrigatório | Descrição                                        |
|-----------------------|---------------------------------------------------|:-----------:|--------------------------------------------------|
| `titulo_id`           | UUID                                              | Sim         | ID do título a transicionar                      |
| `estado_novo`         | `"DISPONIVEL"`, `"EM_ANALISE"`, `"CONSUMIDO"` ou `"QUARENTENA"` | Sim | Novo estado do título |
| `numero_processo_sei` | string (min 1)                                    | Sim         | Número do processo SEI; não pode ser vazio       |
| `motivo`              | string                                            | Não         | Motivo da transição (texto livre)                |

#### Response Body — HTTP 200

| Campo        | Tipo   | Descrição                                   |
|--------------|--------|---------------------------------------------|
| `titulo_id`  | UUID   | ID do título transicionado                  |
| `estado_novo`| string | Novo estado registrado                      |
| `mensagem`   | string | Sempre `"Transição registrada com sucesso."` |

#### Exemplo — Request cURL

```bash
curl -X POST https://api.cepac.prefeitura.sp.gov.br/movimentacoes \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "titulo_id": "00000000-0000-0000-0000-000000000001",
    "estado_novo": "CONSUMIDO",
    "numero_processo_sei": "6016.2024/0000001-0",
    "motivo": "Vinculação ao projeto X"
  }'
```

#### Exemplo — Response 200

```json
{
  "titulo_id": "00000000-0000-0000-0000-000000000001",
  "estado_novo": "CONSUMIDO",
  "mensagem": "Transição registrada com sucesso."
}
```

#### Códigos de erro possíveis

| Código HTTP | Situação                              |
|-------------|---------------------------------------|
| 404         | Título não encontrado no banco de dados |
| 422         | Payload inválido (Pydantic)           |

---

### 4. GET /titulos

**Propósito:** Lista os títulos CEPAC cadastrados. Todos os filtros são opcionais e combinados com lógica AND. Sem filtros, retorna todos os títulos.

#### Parâmetros de query (todos opcionais)

| Parâmetro | Tipo                                              | Descrição                   |
|-----------|---------------------------------------------------|-----------------------------|
| `setor`   | string                                            | Filtrar por nome do setor   |
| `uso`     | `"R"` ou `"NR"`                                   | Filtrar por uso             |
| `origem`  | `"ACA"` ou `"NUVEM"`                              | Filtrar por origem          |
| `estado`  | `"DISPONIVEL"`, `"EM_ANALISE"`, `"CONSUMIDO"` ou `"QUARENTENA"` | Filtrar por estado |

#### Response Body — HTTP 200

Array de objetos com os campos:

| Campo                | Tipo                                              | Descrição                                  |
|----------------------|---------------------------------------------------|--------------------------------------------|
| `id`                 | UUID                                              | Identificador único do título              |
| `setor`              | string                                            | Setor ao qual o título pertence            |
| `uso`                | `"R"` ou `"NR"`                                   | Uso residencial ou não-residencial         |
| `origem`             | `"ACA"` ou `"NUVEM"`                              | Origem do CEPAC                            |
| `estado`             | `"DISPONIVEL"`, `"EM_ANALISE"`, `"CONSUMIDO"` ou `"QUARENTENA"` | Estado atual |
| `valor_m2`           | Decimal                                           | Valor unitário em R$/m²                    |
| `data_desvinculacao` | datetime \| null                                  | Data/hora da desvinculação (ISO 8601)      |

#### Exemplo — Request cURL

```bash
# Todos os títulos NR disponíveis no Brooklin
curl "https://api.cepac.prefeitura.sp.gov.br/titulos?setor=Brooklin&uso=NR&estado=DISPONIVEL" \
  -H "Authorization: Bearer <token>"
```

#### Exemplo — Response 200

```json
[
  {
    "id": "00000000-0000-0000-0000-000000000001",
    "setor": "Brooklin",
    "uso": "NR",
    "origem": "ACA",
    "estado": "DISPONIVEL",
    "valor_m2": "350.00",
    "data_desvinculacao": null
  }
]
```

---

### 5. GET /titulos/{titulo_id}/historico

**Propósito:** Retorna o histórico cronológico completo de movimentações de um título CEPAC, em ordem cronológica ascendente (da mais antiga para a mais recente). Utilizado para auditoria e rastreabilidade.

#### Parâmetros

| Parâmetro  | Localização | Obrigatório | Descrição         |
|------------|-------------|:-----------:|-------------------|
| `titulo_id`| path        | Sim         | UUID do título    |

#### Response Body — HTTP 200

Array de objetos com os campos:

| Campo               | Tipo                                              | Descrição                                           |
|---------------------|---------------------------------------------------|-----------------------------------------------------|
| `id`                | UUID                                              | Identificador único da movimentação                 |
| `titulo_id`         | UUID                                              | ID do título referenciado                           |
| `estado_anterior`   | string \| null                                    | Estado antes da transição (null na criação)         |
| `estado_novo`       | string                                            | Estado após a transição                             |
| `numero_processo_sei`| string                                           | Número do processo SEI vinculado                    |
| `motivo`            | string \| null                                    | Motivo da transição (texto livre)                   |
| `operador`          | string                                            | Identificador do operador (claim `upn`/`sub` do JWT) |
| `created_at`        | datetime                                          | Data/hora da movimentação (ISO 8601, UTC)           |

#### Exemplo — Request cURL

```bash
curl https://api.cepac.prefeitura.sp.gov.br/titulos/00000000-0000-0000-0000-000000000001/historico \
  -H "Authorization: Bearer <token>"
```

#### Exemplo — Response 200

```json
[
  {
    "id": "aaaaaaaa-0000-0000-0000-000000000001",
    "titulo_id": "00000000-0000-0000-0000-000000000001",
    "estado_anterior": null,
    "estado_novo": "DISPONIVEL",
    "numero_processo_sei": "6016.2024/0000001-0",
    "motivo": "Emissão inicial",
    "operador": "operador@sp.gov.br",
    "created_at": "2024-01-15T10:00:00Z"
  },
  {
    "id": "bbbbbbbb-0000-0000-0000-000000000002",
    "titulo_id": "00000000-0000-0000-0000-000000000001",
    "estado_anterior": "DISPONIVEL",
    "estado_novo": "EM_ANALISE",
    "numero_processo_sei": "6016.2024/0000001-0",
    "motivo": "Solicitacao a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "operador": "operador@sp.gov.br",
    "created_at": "2026-04-13T14:32:00Z"
  }
]
```

#### Códigos de erro possíveis

| Código HTTP | Situação                          |
|-------------|-----------------------------------|
| 404         | Título não encontrado no banco de dados |
