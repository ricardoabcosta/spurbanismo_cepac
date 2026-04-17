# Motor de Regras CEPAC — Documentação Técnica

> **Versão da documentação:** 16/04/2026

---

## Visão geral

O motor de regras (`RulesEngine`) é um componente puro — sem acesso a banco de dados, sem dependência de FastAPI e sem estado interno. Recebe um `SolicitacaoDTO` com todos os dados pré-calculados pelo repositório e executa uma cadeia de validators em sequência. O primeiro validator que retornar um erro interrompe a cadeia (short-circuit) e o resultado final é retornado como `ValidationResult(aprovado=False, erro=RulesError(...))`.

**Arquivo:** `src/core/engine/rules_engine.py`

---

## Ordem de execução dos validators

Para todos os setores reconhecidos, a ordem é sempre:

```
1. sei           → falha rápida, sem cálculos
2. capacity      → teto global da OUCAE
3. <setorial>    → regra específica do setor (brooklin / berrini / marginal_pinheiros / chucri_zaidan / jabaquara)
4. quarantine    → disponibilidade individual de cada título do lote
```

Mapeamento completo por setor:

| Setor              | Cadeia de validators                              |
|--------------------|---------------------------------------------------|
| Brooklin           | sei → capacity → brooklin → quarantine            |
| Berrini            | sei → capacity → berrini → quarantine             |
| Marginal Pinheiros | sei → capacity → marginal_pinheiros → quarantine  |
| Chucri Zaidan      | sei → capacity → chucri_zaidan → quarantine       |
| Jabaquara          | sei → capacity → jabaquara → quarantine           |

Se o setor informado não for um dos cinco acima, o engine retorna imediatamente `SETOR_INVALIDO` sem executar nenhum validator.

---

## DTOs envolvidos

### SaldoSetorDTO

Pré-calculado pelo repositório a partir da tabela `movimentacao`. O `RulesEngine` nunca acessa o banco.

| Campo                  | Tipo    | Descrição                                                  |
|------------------------|---------|------------------------------------------------------------|
| `setor`                | str     | Nome do setor                                              |
| `nr_consumido_aca`     | Decimal | m² NR em estado CONSUMIDO, origem ACA                     |
| `nr_consumido_nuvem`   | Decimal | m² NR em estado CONSUMIDO, origem NUVEM                   |
| `nr_em_analise`        | Decimal | m² NR em estado EM_ANALISE (qualquer origem)              |
| `r_consumido_aca`      | Decimal | m² R em estado CONSUMIDO, origem ACA                      |
| `r_consumido_nuvem`    | Decimal | m² R em estado CONSUMIDO, origem NUVEM                    |
| `r_em_analise`         | Decimal | m² R em estado EM_ANALISE (qualquer origem)               |
| `consumo_total_global` | Decimal | Soma total de todos os setores (para validator `capacity`) |

**Propriedades calculadas:**

- `nr_total_comprometido` = `nr_consumido_aca + nr_consumido_nuvem + nr_em_analise`
- `r_total_consumido` = `r_consumido_aca + r_consumido_nuvem` (sem em_analise)

> **Por que `nr_em_analise` entra no comprometido?** Títulos em `EM_ANALISE` já tiveram saldo reservado em aprovações anteriores. Incluí-los impede que aprovações paralelas ultrapassem o teto antes da confirmação final (corrida entre requisições concorrentes).

### RulesError

| Campo           | Tipo            | Descrição                                              |
|-----------------|-----------------|--------------------------------------------------------|
| `codigo`        | str             | Código único da regra violada                          |
| `mensagem`      | str             | Mensagem legível em português                          |
| `setor`         | str \| None     | Setor envolvido                                        |
| `saldo_atual`   | Decimal \| None | Saldo NR disponível no momento da rejeição             |
| `limite`        | Decimal \| None | Teto NR aplicável                                      |
| `dias_restantes`| int \| None     | Dias restantes de quarentena (exclusivo: `QUARENTENA_ATIVA`) |

---

## Validators

### 1. SEI — Validação de número de processo

**Arquivo:** `src/core/engine/validators/sei.py`

**Regra:** Garante que o número do processo SEI foi informado antes de qualquer cálculo de saldo ou verificação de capacidade. É executado sempre primeiro como mecanismo de falha rápida.

**Lógica:**
```
SE numero_processo_sei é None OU strip() == "" → NUMERO_SEI_OBRIGATORIO
```

**Aplica-se a:** todos os setores, todos os usos (R e NR).

**Código de erro retornado:**

| Código                    | Condição                                        |
|---------------------------|-------------------------------------------------|
| `NUMERO_SEI_OBRIGATORIO`  | Campo ausente, vazio ou contendo apenas espaços/tabulações |

**Exemplo numérico:**

- Pedido NR de 100.000 m² no Brooklin com `numero_processo_sei = ""` → bloqueado com `NUMERO_SEI_OBRIGATORIO`. Nenhum cálculo de saldo é executado.

---

### 2. Capacity — Teto global da OUCAE

**Arquivo:** `src/core/engine/validators/capacity.py`

**Regra:** Aplica o limite máximo de emissão de CEPACs NR de toda a Operação Urbana Consorciada Água Espraiada (OUCAE), descontada a reserva técnica. Baseado na Lei 15.893/2013.

**Parâmetros:**

| Parâmetro         | Valor          |
|-------------------|----------------|
| Capacidade total  | 4.850.000,00 m² |
| Reserva técnica   | 250.000,00 m²  |
| **Limite operação** | **4.600.000,00 m²** |

**Aplica-se a:** apenas solicitações com `uso = "NR"`. Solicitações `R` retornam `None` sem cálculo.

**Fórmula:**
```
projetado = consumo_total_global + area_m2
SE projetado > 4.600.000,00 → TETO_GLOBAL_EXCEDIDO
```

**Código de erro retornado:**

| Código               | Campos preenchidos no RulesError              |
|----------------------|-----------------------------------------------|
| `TETO_GLOBAL_EXCEDIDO` | `saldo_atual` = saldo global disponível, `limite` = 4.600.000,00 |

**Exemplo numérico:**

- `consumo_total_global` = 4.550.000,00 m²; pedido NR = 60.000 m²
- Projetado: 4.550.000,00 + 60.000 = 4.610.000,00 > 4.600.000,00 → **bloqueado**
- `saldo_atual` retornado: 4.600.000,00 − 4.550.000,00 = **50.000,00 m²**

---

### 3. Brooklin — Teto NR setorial

**Arquivo:** `src/core/engine/validators/brooklin.py`

**Regra:** Impede que o consumo NR acumulado do setor ultrapasse 70% do estoque total (980.000,00 m²). O NR em análise é incluído no comprometido para bloquear aprovações simultâneas.

**Parâmetros:**

| Parâmetro  | Valor          |
|------------|----------------|
| Teto NR    | 980.000,00 m²  |
| Saldo NR em 13/04/2026 | 263.529,99 m² |

**Aplica-se a:** apenas `uso = "NR"`.

**Fórmula:**
```
comprometido = nr_consumido_aca + nr_consumido_nuvem + nr_em_analise
projetado = comprometido + area_m2
SE projetado > 980.000,00 → TETO_NR_EXCEDIDO
```

**Código de erro retornado:**

| Código           | Campos preenchidos no RulesError            |
|------------------|---------------------------------------------|
| `TETO_NR_EXCEDIDO` | `saldo_atual` = teto − comprometido, `limite` = 980.000,00 |

**Exemplo numérico (seed de 13/04/2026):**

- `nr_consumido_aca` = 716.470,01 m²; `nr_consumido_nuvem` = 0; `nr_em_analise` = 0
- Comprometido: 716.470,01 m²
- Pedido NR = 100.000 m² → projetado: 716.470,01 + 100.000 = **816.470,01 < 980.000,00 → aprovado**
- Pedido NR = 264.000 m² → projetado: 716.470,01 + 264.000 = **980.470,01 > 980.000,00 → bloqueado**
  - `saldo_atual` retornado: 980.000,00 − 716.470,01 = **263.529,99 m²**

---

### 4. Berrini — Bloqueio incondicional de NR

**Arquivo:** `src/core/engine/validators/berrini.py`

**Regra:** O setor Berrini atingiu e superou seu teto NR histórico de 175.000,00 m² (consumo acumulado NR: 203.202,23 m²). Qualquer nova solicitação NR é rejeitada **incondicionalmente**, sem consultar o saldo recebido no DTO.

**Parâmetros:**

| Parâmetro             | Valor          |
|-----------------------|----------------|
| Teto NR histórico     | 175.000,00 m²  |
| NR acumulado (seed)   | 203.202,23 m²  |
| Saldo NR disponível   | 0,00 m² (BLOQUEADO) |

**Aplica-se a:** apenas `uso = "NR"`. Solicitações `R` são aprovadas normalmente.

**Lógica:**
```
SE uso == "NR" → sempre TETO_NR_EXCEDIDO (sem cálculo)
```

**Código de erro retornado:**

| Código           | Campos preenchidos no RulesError          |
|------------------|-------------------------------------------|
| `TETO_NR_EXCEDIDO` | `saldo_atual` = 0, `limite` = 175.000,00 |

**Exemplo numérico:**

- Pedido NR de 1 m² no Berrini com saldo zerado → **bloqueado** (`TETO_NR_EXCEDIDO`, `saldo_atual=0`)
- Pedido NR de 1 m² no Berrini com saldo fictício positivo → **ainda bloqueado** (o bloqueio ignora o saldo)
- Pedido R de 5.000 m² no Berrini → **aprovado** (NR não se aplica)

---

### 5. Marginal Pinheiros — Teto NR setorial

**Arquivo:** `src/core/engine/validators/marginal_pinheiros.py`

**Regra:** Impede que o consumo NR acumulado ultrapasse 70% do estoque total (420.000,00 m²). O NR em análise é bloqueante, reservando saldo contra aprovações concorrentes.

**Parâmetros:**

| Parâmetro  | Valor          |
|------------|----------------|
| Teto NR    | 420.000,00 m²  |
| Saldo NR em 13/04/2026 | 149.918,75 m² |

**Aplica-se a:** apenas `uso = "NR"`.

**Fórmula:**
```
comprometido = nr_consumido_aca + nr_consumido_nuvem + nr_em_analise
projetado = comprometido + area_m2
SE projetado > 420.000,00 → TETO_NR_EXCEDIDO
```

**Código de erro retornado:**

| Código           | Campos preenchidos no RulesError            |
|------------------|---------------------------------------------|
| `TETO_NR_EXCEDIDO` | `saldo_atual` = teto − comprometido, `limite` = 420.000,00 |

**Exemplo numérico (seed de 13/04/2026):**

- `nr_consumido_aca` = 258.908,19; `nr_em_analise` = 11.173,06 → comprometido = 270.081,25
- Pedido NR = 100.000 m² → projetado: 270.081,25 + 100.000 = **370.081,25 < 420.000 → aprovado**
- Pedido NR = 150.000 m² → projetado: 270.081,25 + 150.000 = **420.081,25 > 420.000 → bloqueado**

---

### 6. Chucri Zaidan — Fórmula especial com reserva residencial

**Arquivo:** `src/core/engine/validators/chucri_zaidan.py`

**Regra:** A Lei 16.975/2018 reserva 216.442,47 m² do estoque total exclusivamente para uso Residencial. Para garantir que aprovações NR não indiretamente consumam essa reserva, a fórmula agrega **todo o consumo do setor** (R + NR + em análise de ambos) contra o teto NR.

**Parâmetros:**

| Parâmetro       | Valor            |
|-----------------|------------------|
| Estoque total   | 2.000.000,00 m²  |
| Reserva R (Lei 16.975/2018) | 216.442,47 m² |
| **Teto NR**     | **1.783.557,53 m²** |
| Saldo NR em 13/04/2026 | 182.563,65 m² |

**Aplica-se a:** apenas `uso = "NR"`.

**Fórmula:**
```
consumo_total = r_total_consumido + r_em_analise + nr_total_comprometido

onde:
  r_total_consumido    = r_consumido_aca + r_consumido_nuvem
  nr_total_comprometido = nr_consumido_aca + nr_consumido_nuvem + nr_em_analise

projetado = consumo_total + area_m2
SE projetado > 1.783.557,53 → RESERVA_R_VIOLADA
```

**Código de erro retornado:**

| Código           | Campos preenchidos no RulesError                |
|------------------|-------------------------------------------------|
| `RESERVA_R_VIOLADA` | `saldo_atual` = teto − consumo_total, `limite` = 1.783.557,53 |

**Exemplo numérico (borda com saldo 182.563,65 m²):**

- `r_consumido_aca` = 500.000,00; `r_em_analise` = 50.000,00; `nr_consumido_aca` = 1.050.993,88
- `consumo_total` = 500.000,00 + 50.000,00 + 1.050.993,88 = 1.600.993,88
- Pedido NR = 182.563,65 m² → projetado: 1.600.993,88 + 182.563,65 = **1.783.557,53 = teto → aprovado** (limite inclusive)
- Pedido NR = 182.563,66 m² → projetado: 1.600.993,88 + 182.563,66 = **1.783.557,54 > teto → bloqueado**

**Por que a fórmula agrega R e NR?**
Se considerasse apenas NR, um setor com alto consumo R poderia aprovar NR além do permitido — sobrando menos espaço do que a reserva exige. A fórmula total garante que a soma de todo o consumo nunca ultrapasse o que a lei permite para NR.

---

### 7. Jabaquara — Teto NR setorial

**Arquivo:** `src/core/engine/validators/jabaquara.py`

**Regra:** Impede que o consumo NR acumulado ultrapasse o limite absoluto de 175.000,00 m² do setor.

**Parâmetros:**

| Parâmetro  | Valor          |
|------------|----------------|
| Teto NR    | 175.000,00 m²  |
| Saldo NR em 13/04/2026 | 175.000,00 m² (intacto) |

**Aplica-se a:** apenas `uso = "NR"`.

**Fórmula:**
```
comprometido = nr_consumido_aca + nr_consumido_nuvem + nr_em_analise
projetado = comprometido + area_m2
SE projetado > 175.000,00 → TETO_NR_EXCEDIDO
```

**Código de erro retornado:**

| Código           | Campos preenchidos no RulesError            |
|------------------|---------------------------------------------|
| `TETO_NR_EXCEDIDO` | `saldo_atual` = teto − comprometido, `limite` = 175.000,00 |

**Exemplo numérico (seed de 13/04/2026, saldo intacto):**

- Comprometido = 0,00 m²
- Pedido NR = 175.000 m² → projetado: 0 + 175.000 = **175.000,00 = teto → aprovado** (limite inclusive)
- Pedido NR = 175.000,01 m² → projetado: **175.000,01 > 175.000 → bloqueado**

---

### 8. Quarantine — Disponibilidade individual dos títulos

**Arquivo:** `src/core/engine/validators/quarantine.py`

**Regra:** Percorre todos os títulos do lote e verifica dois aspectos:

1. **Quarentena ativa:** título em estado `QUARENTENA` com menos de 180 dias desde a desvinculação é rejeitado.
2. **Indisponibilidade:** título em qualquer estado diferente de `DISPONIVEL` (após verificar quarentena) é rejeitado.

O validator retorna no **primeiro título inválido** encontrado, sem percorrer o restante do lote.

**Parâmetros:**

| Parâmetro        | Valor    |
|------------------|----------|
| Período de quarentena | 180 dias |
| TTL EM_ANALISE (informativo) | 48 horas |

**Aplica-se a:** todos os setores, todos os usos.

**Lógica:**
```
PARA CADA título no lote:
  SE estado == "QUARENTENA":
    SE data_desvinculacao é None:
      → QUARENTENA_ATIVA (inconsistência de dados, sem dias_restantes)
    dias_em_quarentena = (agora - data_desvinculacao).days
    SE dias_em_quarentena < 180:
      → QUARENTENA_ATIVA com dias_restantes = 180 - dias_em_quarentena
    SENÃO:
      continua (quarentena cumprida)
  SE estado != "DISPONIVEL":
    → TITULO_INDISPONIVEL
```

**Códigos de erro retornados:**

| Código              | Condição                                                   | Campos adicionais          |
|---------------------|------------------------------------------------------------|----------------------------|
| `QUARENTENA_ATIVA`  | Título em QUARENTENA com < 180 dias desde desvinculação    | `dias_restantes` preenchido |
| `QUARENTENA_ATIVA`  | Título em QUARENTENA sem `data_desvinculacao` (inconsistência) | `dias_restantes = null`  |
| `TITULO_INDISPONIVEL` | Título em `EM_ANALISE` ou `CONSUMIDO`                   | —                          |

**Exemplos numéricos:**

- Título desvinculado há 90 dias → `dias_em_quarentena = 90 < 180` → **bloqueado** com `dias_restantes = 90`
- Título desvinculado há 179 dias → `dias_em_quarentena = 179 < 180` → **bloqueado** com `dias_restantes = 1`
- Título desvinculado há 180 dias → `dias_em_quarentena = 180 >= 180` → **quarentena cumprida, aprovado**
- Título desvinculado há 181 dias → `dias_em_quarentena = 181 >= 180` → **aprovado**
- Título em `EM_ANALISE` → **bloqueado** com `TITULO_INDISPONIVEL`
- Lote com 1 título `DISPONIVEL` + 1 título em QUARENTENA recente → **bloqueado** no segundo título

---

## Tabela consolidada de códigos de erro

| Código                    | Validator   | Aplica-se a        | Descrição                                              |
|---------------------------|-------------|--------------------|--------------------------------------------------------|
| `SETOR_INVALIDO`          | RulesEngine | —                  | Setor não reconhecido                                  |
| `NUMERO_SEI_OBRIGATORIO`  | sei         | R e NR, todos setores | SEI ausente ou vazio                               |
| `TETO_GLOBAL_EXCEDIDO`    | capacity    | NR, todos setores  | Limite global da OUCAE (4.600.000 m²) seria ultrapassado |
| `TETO_NR_EXCEDIDO`        | brooklin, berrini, marginal_pinheiros, jabaquara | NR | Teto NR setorial seria ultrapassado |
| `RESERVA_R_VIOLADA`       | chucri_zaidan | NR              | Reserva residencial obrigatória seria violada          |
| `QUARENTENA_ATIVA`        | quarantine  | R e NR, todos setores | Título em período de quarentena ativo               |
| `TITULO_INDISPONIVEL`     | quarantine  | R e NR, todos setores | Título não está em estado DISPONIVEL               |
