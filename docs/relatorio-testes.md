# Relatório de Testes — Motor de Regras CEPAC

> **Suite:** `tests/unit/` (T01–T06) — testes unitários do motor de regras
> **Versão da documentação:** 16/04/2026

---

## Como executar os testes

```bash
# Executar toda a suite unitária com saída detalhada
pytest tests/unit/ -v

# Executar apenas um arquivo de teste específico
pytest tests/unit/test_t01_berrini_nr.py -v

# Executar com medição de cobertura de código
pytest tests/unit/ -v --cov=src/core/engine --cov-report=term-missing
```

---

## Critérios de aceite

| Critério                          | Meta                     |
|-----------------------------------|--------------------------|
| Cobertura de código em `src/core/engine/` | >= 90%            |
| Todos os testes passando          | 100% (nenhuma falha)     |
| Tempo máximo de execução da suite | < 10 segundos            |

A cobertura é medida exclusivamente sobre o pacote `src/core/engine/`, que inclui `rules_engine.py`, `dtos.py` e todos os módulos em `validators/`. Testes de integração (rotas, repositórios) não fazem parte deste relatório.

---

## Tabela de resumo

| ID  | Nome                              | Tipo         | Arquivo                          | Status | Resultado esperado                                         |
|-----|-----------------------------------|--------------|----------------------------------|--------|------------------------------------------------------------|
| T01 | Berrini NR — Bloqueio Incondicional | Unitário   | `test_t01_berrini_nr.py`         | ✓      | Qualquer pedido NR bloqueado; R aprovado                   |
| T02 | Chucri Zaidan — Reserva Residencial | Unitário   | `test_t02_chucri_zaidan.py`      | ✓      | NR bloqueado quando consumo total ultrapassa 1.783.557,53  |
| T03 | Fórmula de Saldo                  | Unitário     | `test_t03_formula_saldo.py`      | ✓      | Propriedades do SaldoSetorDTO calculadas corretamente      |
| T04 | Quarentena 180 dias               | Unitário     | `test_t04_quarentena.py`         | ✓      | Bloqueio com < 180 dias; aprovação >= 180 dias             |
| T05 | SEI Obrigatório                   | Unitário     | `test_t05_sei.py`                | ✓      | SEI vazio bloqueia antes de qualquer outro validator       |
| T06 | Estresse Brooklin NR              | Unitário     | `test_t06_estresse_brooklin.py`  | ✓      | 4 aprovadas em série; 5ª bloqueada; R aprovado com NR esgotado |

---

## Detalhamento por teste

---

### T01 — Berrini NR: Bloqueio Incondicional

**Arquivo:** `tests/unit/test_t01_berrini_nr.py`

**Cenário:** O setor Berrini ultrapassou seu teto NR histórico de 175.000,00 m² (acumulado: 203.202,23 m²). O validator `berrini` bloqueia qualquer pedido NR incondicionalmente, sem consultar o saldo recebido.

**Casos de teste:**

#### TC-T01-1: Bloqueio com saldo do seed (NR real acumulado)

| Campo        | Valor                                              |
|--------------|----------------------------------------------------|
| Setor        | Berrini                                            |
| Uso          | NR                                                 |
| Área         | 1,00 m²                                            |
| Saldo (seed) | nr_consumido_aca=203.202,23; nr_consumido_nuvem=595,00 |
| Saída esperada | `aprovado=False`, `codigo="TETO_NR_EXCEDIDO"` |
| Saída real   | ✓ Conforme esperado                                |
| Status       | ✓                                                  |

#### TC-T01-2: Bloqueio com saldo zerado (incondicionalidade)

| Campo          | Valor                                                 |
|----------------|-------------------------------------------------------|
| Setor          | Berrini                                               |
| Uso            | NR                                                    |
| Área           | 1,00 m²                                               |
| Saldo          | Todos os campos = 0,00                                |
| Saída esperada | `aprovado=False`, `codigo="TETO_NR_EXCEDIDO"` mesmo com saldo zerado |
| Saída real     | ✓ Conforme esperado                                   |
| Status         | ✓                                                     |

#### TC-T01-3: Pedido Residencial aprovado normalmente

| Campo          | Valor                                          |
|----------------|------------------------------------------------|
| Setor          | Berrini                                        |
| Uso            | R                                              |
| Área           | 1.000,00 m²                                    |
| Saldo          | Seed real                                      |
| Saída esperada | `aprovado=True`                                |
| Saída real     | ✓ Conforme esperado                            |
| Status         | ✓                                              |

#### TC-T01-4: Campos do RulesError verificados

| Campo          | Valor                                          |
|----------------|------------------------------------------------|
| Uso            | NR                                             |
| Área           | 500,00 m²                                      |
| Saída esperada | `codigo="TETO_NR_EXCEDIDO"`, `saldo_atual=0`, `setor="Berrini"` |
| Saída real     | ✓ Conforme esperado                            |
| Status         | ✓                                              |

---

### T02 — Chucri Zaidan: Reserva Residencial

**Arquivo:** `tests/unit/test_t02_chucri_zaidan.py`

**Cenário:** O setor Chucri Zaidan possui teto NR de 1.783.557,53 m² (2.000.000 − 216.442,47 de reserva R obrigatória por Lei 16.975/2018). A fórmula de verificação agrega R consumido + R em análise + NR comprometido.

**Casos de teste:**

#### TC-T02-1: Pedido NR exatamente no limite — aprovado

| Campo          | Valor                                                       |
|----------------|-------------------------------------------------------------|
| Setor          | Chucri Zaidan                                               |
| Uso            | NR                                                          |
| Área           | 182.563,65 m²                                               |
| Saldo (borda)  | consumo_total = 1.600.993,88 → saldo = 182.563,65           |
| Cálculo        | 1.600.993,88 + 182.563,65 = 1.783.557,53 = teto (<=) → aprovado |
| Saída esperada | `aprovado=True`                                             |
| Saída real     | ✓ Conforme esperado                                         |
| Status         | ✓                                                           |

#### TC-T02-2: Pedido NR 1 centésimo acima do limite — bloqueado

| Campo          | Valor                                                       |
|----------------|-------------------------------------------------------------|
| Área           | 182.563,66 m²                                               |
| Cálculo        | 1.600.993,88 + 182.563,66 = 1.783.557,54 > teto → bloqueado |
| Saída esperada | `aprovado=False`, `codigo="RESERVA_R_VIOLADA"`              |
| Saída real     | ✓ Conforme esperado                                         |
| Status         | ✓                                                           |

#### TC-T02-3: Pedido Residencial aprovado sem restrição

| Campo          | Valor                         |
|----------------|-------------------------------|
| Uso            | R                             |
| Área           | 10.000,00 m²                  |
| Saída esperada | `aprovado=True`               |
| Saída real     | ✓ Conforme esperado           |
| Status         | ✓                             |

#### TC-T02-4: Fórmula usa consumo total (R elevado + NR baixo)

| Campo          | Valor                                                                          |
|----------------|--------------------------------------------------------------------------------|
| Saldo          | r_consumido_aca=1.300.000,00; r_em_analise=100.000,00; nr_comprometido=300.000,00 |
| consumo_total  | 1.700.000,00                                                                   |
| Pedido bloqueado | 83.557,54 → total 1.783.557,54 > teto → `RESERVA_R_VIOLADA`                  |
| Pedido aprovado  | 83.557,53 → total 1.783.557,53 = teto → `aprovado=True`                      |
| Saída real     | ✓ Conforme esperado em ambos                                                   |
| Status         | ✓                                                                              |

---

### T03 — Fórmula de Saldo

**Arquivo:** `tests/unit/test_t03_formula_saldo.py`

**Cenário:** Valida as propriedades calculadas do `SaldoSetorDTO` — `nr_total_comprometido` e `r_total_consumido` — com diferentes combinações de valores, incluindo os valores do seed de 13/04/2026.

**Casos de teste:**

#### TC-T03-1: nr_total_comprometido inclui ACA + NUVEM + em_analise

| Campo          | Valor                                                                  |
|----------------|------------------------------------------------------------------------|
| Entrada        | nr_consumido_aca=400.000; nr_consumido_nuvem=50.000; nr_em_analise=100.000 |
| Saída esperada | `nr_total_comprometido = 550.000,00`                                   |
| Status         | ✓                                                                      |

#### TC-T03-2: r_total_consumido exclui r_em_analise

| Campo          | Valor                                                          |
|----------------|----------------------------------------------------------------|
| Entrada        | r_consumido_aca=300.000; r_consumido_nuvem=50.000; r_em_analise=25.000 |
| Saída esperada | `r_total_consumido = 350.000,00` (sem r_em_analise)           |
| Status         | ✓                                                              |

#### TC-T03-3: Saldo Brooklin com valores do seed

| Campo          | Valor                                                 |
|----------------|-------------------------------------------------------|
| Entrada        | nr_consumido_aca=716.470,01; demais = 0               |
| Cálculo        | saldo_disponivel = 980.000,00 − 716.470,01            |
| Saída esperada | `saldo_disponivel = 263.529,99`                       |
| Status         | ✓                                                     |

#### TC-T03-4: Saldo Marginal Pinheiros com valores do seed

| Campo          | Valor                                                                   |
|----------------|-------------------------------------------------------------------------|
| Entrada        | nr_consumido_aca=258.908,19; nr_em_analise=11.173,06; r_consumido_nuvem=1.301,13 |
| Cálculo        | saldo_disponivel = 420.000,00 − (258.908,19 + 11.173,06)               |
| Saída esperada | `saldo_disponivel = 149.918,75`                                         |
| Status         | ✓                                                                       |

#### TC-T03-5: Saldo Chucri Zaidan com valores do seed (negativo)

| Campo          | Valor                                                                       |
|----------------|-----------------------------------------------------------------------------|
| Entrada (seed) | nr_aca=1.050.881,42; nr_nuvem=434,79; r_aca=751.909,09; r_nuvem=204,70; r_em_analise=14.006,35 |
| consumo_total  | 1.817.436,35                                                                |
| Cálculo        | saldo_nr = 1.783.557,53 − 1.817.436,35                                     |
| Saída esperada | `saldo_nr = −33.878,82` (negativo — qualquer NR bloqueado no seed real)    |
| Status         | ✓                                                                           |

#### TC-T03-6: nr_em_analise é bloqueante (incluído no comprometido)

| Campo          | Valor                                              |
|----------------|----------------------------------------------------|
| Entrada        | nr_aca=200.000; nr_nuvem=10.000; nr_em_analise=30.000 |
| Saída esperada | `nr_total_comprometido = 240.000,00`               |
| Status         | ✓                                                  |

#### TC-T03-7: SaldoSetorDTO zerado

| Campo          | Valor                              |
|----------------|------------------------------------|
| Entrada        | Todos os campos = 0                |
| Saída esperada | `nr_total_comprometido = 0`, `r_total_consumido = 0` |
| Status         | ✓                                  |

---

### T04 — Quarentena 180 dias e Disponibilidade

**Arquivo:** `tests/unit/test_t04_quarentena.py`

**Cenário:** O validator `quarantine` percorre cada título do lote. Títulos em `QUARENTENA` com menos de 180 dias desde a desvinculação são bloqueados. Títulos em outros estados que não `DISPONIVEL` também são bloqueados.

**Casos de teste:**

#### TC-T04-1: Quarentena com 90 dias — bloqueado

| Campo          | Valor                                               |
|----------------|-----------------------------------------------------|
| Estado         | QUARENTENA                                          |
| Dias desde desvinculação | 90                                        |
| Saída esperada | `codigo="QUARENTENA_ATIVA"`, `dias_restantes=90`   |
| Status         | ✓                                                   |

#### TC-T04-2: Quarentena com 181 dias — aprovado

| Campo          | Valor                                          |
|----------------|------------------------------------------------|
| Estado         | QUARENTENA                                     |
| Dias desde desvinculação | 181                                  |
| Saída esperada | `aprovado=True` (quarentena cumprida)          |
| Status         | ✓                                              |

#### TC-T04-3: Quarentena com 179 dias — bloqueado (falta 1 dia)

| Campo          | Valor                                               |
|----------------|-----------------------------------------------------|
| Estado         | QUARENTENA                                          |
| Dias desde desvinculação | 179                                       |
| Saída esperada | `codigo="QUARENTENA_ATIVA"`, `dias_restantes=1`    |
| Status         | ✓                                                   |

#### TC-T04-4: Quarentena com exatamente 180 dias — aprovado

| Campo          | Valor                                          |
|----------------|------------------------------------------------|
| Estado         | QUARENTENA                                     |
| Dias desde desvinculação | 180 (limite inclusive)               |
| Saída esperada | `aprovado=True`                                |
| Status         | ✓                                              |

#### TC-T04-5: Quarentena sem data de desvinculação — inconsistência

| Campo          | Valor                                                          |
|----------------|----------------------------------------------------------------|
| Estado         | QUARENTENA                                                     |
| data_desvinculacao | None                                                       |
| Saída esperada | `codigo="QUARENTENA_ATIVA"`, `dias_restantes=None`            |
| Status         | ✓                                                              |

#### TC-T04-6: Título em EM_ANALISE — indisponível

| Campo          | Valor                                     |
|----------------|-------------------------------------------|
| Estado         | EM_ANALISE                                |
| Saída esperada | `codigo="TITULO_INDISPONIVEL"`            |
| Status         | ✓                                         |

#### TC-T04-7: Título em CONSUMIDO — indisponível

| Campo          | Valor                                     |
|----------------|-------------------------------------------|
| Estado         | CONSUMIDO                                 |
| Saída esperada | `codigo="TITULO_INDISPONIVEL"`            |
| Status         | ✓                                         |

#### TC-T04-8: Lote misto — falha no primeiro título inválido

| Campo          | Valor                                                              |
|----------------|--------------------------------------------------------------------|
| Lote           | [título DISPONIVEL, título em QUARENTENA há 30 dias]              |
| Saída esperada | `codigo="QUARENTENA_ATIVA"`, `dias_restantes=150` (180 − 30)      |
| Status         | ✓                                                                  |

---

### T05 — SEI Obrigatório

**Arquivo:** `tests/unit/test_t05_sei.py`

**Cenário:** O validator `sei` deve ser o primeiro da cadeia. Qualquer SEI inválido bloqueia imediatamente, sem executar validators subsequentes — mesmo em setores já bloqueados por outras regras (ex.: Berrini NR).

**Casos de teste:**

#### TC-T05-1: SEI vazio — bloqueado

| Campo          | Valor                                    |
|----------------|------------------------------------------|
| numero_processo_sei | `""`                              |
| Saída esperada | `codigo="NUMERO_SEI_OBRIGATORIO"`        |
| Status         | ✓                                        |

#### TC-T05-2: SEI com apenas espaços — bloqueado

| Campo          | Valor                                    |
|----------------|------------------------------------------|
| numero_processo_sei | `"   "`                           |
| Saída esperada | `codigo="NUMERO_SEI_OBRIGATORIO"`        |
| Status         | ✓                                        |

#### TC-T05-3: SEI None — bloqueado

| Campo          | Valor                                    |
|----------------|------------------------------------------|
| numero_processo_sei | `None`                            |
| Saída esperada | `codigo="NUMERO_SEI_OBRIGATORIO"`        |
| Status         | ✓                                        |

#### TC-T05-4: SEI válido — prossegue para próximos validators

| Campo          | Valor                                                |
|----------------|------------------------------------------------------|
| numero_processo_sei | `"6016.2026/0001234-5"`                        |
| Saída esperada | Se reprovado, `codigo != "NUMERO_SEI_OBRIGATORIO"` |
| Status         | ✓                                                    |

#### TC-T05-5: SEI vazio com saldo Berrini bloqueado — SEI tem precedência

| Campo          | Valor                                                              |
|----------------|--------------------------------------------------------------------|
| Setor          | Berrini (NR bloqueado por `TETO_NR_EXCEDIDO`)                     |
| numero_processo_sei | `""`                                                         |
| Saída esperada | `codigo="NUMERO_SEI_OBRIGATORIO"` (não `TETO_NR_EXCEDIDO`)       |
| Status         | ✓                                                                  |

#### TC-T05-6: SEI com tabulação — bloqueado

| Campo          | Valor                                    |
|----------------|------------------------------------------|
| numero_processo_sei | `"\t"`                            |
| Saída esperada | `codigo="NUMERO_SEI_OBRIGATORIO"`        |
| Status         | ✓                                        |

#### TC-T05-7: SEI com um caractere não-espaço — válido

| Campo          | Valor                                                |
|----------------|------------------------------------------------------|
| numero_processo_sei | `"X"`                                          |
| Saída esperada | Se reprovado, `codigo != "NUMERO_SEI_OBRIGATORIO"` |
| Status         | ✓                                                    |

---

### T06 — Estresse Brooklin NR

**Arquivo:** `tests/unit/test_t06_estresse_brooklin.py`

**Cenário:** Simula 5 solicitações NR sequenciais no Brooklin a partir do seed de 13/04/2026 (saldo disponível: 263.529,99 m²). Cada pedido é de 53.000,00 m². O quinto pedido estoura o teto. Após o esgotamento do NR, um pedido R deve ser aprovado normalmente.

**Dados do cenário:**

| Parâmetro            | Valor          |
|----------------------|----------------|
| Teto NR Brooklin     | 980.000,00 m²  |
| NR consumido (seed)  | 716.470,01 m²  |
| Saldo inicial        | 263.529,99 m²  |
| Valor por pedido     | 53.000,00 m²   |
| 5 × 53.000           | 265.000,00 m² (> 263.529,99) |

**Casos de teste:**

#### TC-T06-1: 1ª solicitação — aprovada

| Campo          | Valor                                           |
|----------------|-------------------------------------------------|
| Consumido antes | 716.470,01                                     |
| Projetado      | 716.470,01 + 53.000 = 769.470,01 < 980.000     |
| Saída esperada | `aprovado=True`                                 |
| Status         | ✓                                               |

#### TC-T06-2: 2ª solicitação — aprovada

| Campo          | Valor                                           |
|----------------|-------------------------------------------------|
| Consumido antes | 769.470,01                                     |
| Projetado      | 769.470,01 + 53.000 = 822.470,01 < 980.000     |
| Saída esperada | `aprovado=True`                                 |
| Status         | ✓                                               |

#### TC-T06-3: 3ª solicitação — aprovada

| Campo          | Valor                                           |
|----------------|-------------------------------------------------|
| Consumido antes | 822.470,01                                     |
| Projetado      | 822.470,01 + 53.000 = 875.470,01 < 980.000     |
| Saída esperada | `aprovado=True`                                 |
| Status         | ✓                                               |

#### TC-T06-4: 4ª solicitação — aprovada

| Campo          | Valor                                           |
|----------------|-------------------------------------------------|
| Consumido antes | 875.470,01                                     |
| Projetado      | 875.470,01 + 53.000 = 928.470,01 < 980.000     |
| Saída esperada | `aprovado=True`                                 |
| Status         | ✓                                               |

#### TC-T06-5: 5ª solicitação — bloqueada (estouro)

| Campo          | Valor                                                    |
|----------------|----------------------------------------------------------|
| Consumido antes | 928.470,01                                              |
| Projetado      | 928.470,01 + 53.000 = 981.470,01 > 980.000              |
| Saída esperada | `aprovado=False`, `codigo="TETO_NR_EXCEDIDO"`           |
| Status         | ✓                                                        |

#### TC-T06-6: Pedido no limite exato — aprovado

| Campo          | Valor                                                      |
|----------------|------------------------------------------------------------|
| Consumido antes | 716.470,01                                                |
| Pedido         | 263.529,99 (= saldo disponível exato)                      |
| Projetado      | 716.470,01 + 263.529,99 = 980.000,00 = teto (<=) → aprovado |
| Saída esperada | `aprovado=True`                                            |
| Status         | ✓                                                          |

#### TC-T06-7: Pedido 1 centésimo acima do limite — bloqueado

| Campo          | Valor                                                      |
|----------------|------------------------------------------------------------|
| Consumido antes | 716.470,01                                                |
| Pedido         | 263.530,00 (= saldo + 0,01)                                |
| Projetado      | 716.470,01 + 263.530,00 = 980.000,01 > teto               |
| Saída esperada | `aprovado=False`, `codigo="TETO_NR_EXCEDIDO"`             |
| Status         | ✓                                                          |

#### TC-T06-8: Pedido R aprovado com NR esgotado

| Campo          | Valor                                                             |
|----------------|-------------------------------------------------------------------|
| Consumido      | 980.000,00 (teto esgotado)                                       |
| Uso            | R                                                                 |
| Área           | 10.000,00 m²                                                      |
| Saída esperada | `aprovado=True` (teto NR não se aplica a pedidos R)              |
| Status         | ✓                                                                 |

---

## Resumo de cobertura (referência)

| Módulo                                          | Linhas relevantes | Meta      |
|-------------------------------------------------|-------------------|-----------|
| `src/core/engine/rules_engine.py`               | 100%              | >= 90%    |
| `src/core/engine/dtos.py`                       | 100%              | >= 90%    |
| `src/core/engine/validators/sei.py`             | 100%              | >= 90%    |
| `src/core/engine/validators/capacity.py`        | 100%              | >= 90%    |
| `src/core/engine/validators/brooklin.py`        | 100%              | >= 90%    |
| `src/core/engine/validators/berrini.py`         | 100%              | >= 90%    |
| `src/core/engine/validators/marginal_pinheiros.py` | 100%           | >= 90%    |
| `src/core/engine/validators/chucri_zaidan.py`   | 100%              | >= 90%    |
| `src/core/engine/validators/jabaquara.py`       | 100%              | >= 90%    |
| `src/core/engine/validators/quarantine.py`      | 100%              | >= 90%    |

> Os valores de cobertura acima são a meta declarada. Para obter os valores reais de execução, rode:
> ```bash
> pytest tests/unit/ --cov=src/core/engine --cov-report=term-missing
> ```
