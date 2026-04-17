# Parâmetros Setoriais — OUCAE (Operação Urbana Consorciada Água Espraiada)
**SP Urbanismo / Prodam**
**Versão:** 1.2
**Data:** 2026-04-15
**Fonte:** Planilha de controle SP Urbanismo 2026 + Lei 16.975/2018

> Este documento é a **fonte única de verdade** para os parâmetros de entrada do motor de regras.
> Qualquer alteração deve ser versionada e revisada pelo Tech Lead antes de ser aplicada ao código.

---

## 1. Parâmetros Globais do Sistema

| Parâmetro | Valor | Observação |
|---|---|---|
| Capacidade Total da Operação | 4.850.000,00 m² | Teto absoluto — bloqueio mandatório |
| Subtotal Permitido (Setores) | 4.600.000,00 m² | Soma dos estoques setoriais |
| Reserva Técnica Inalienável | 250.000,00 m² | Não pode ser consumida por nenhum setor |
| Emissão Total de CEPAC | 4.490.999 unidades | Total de títulos emitidos |
| Títulos em Circulação | 142.268 unidades | Saldo corrente em circulação — controlado por transação |
| TTL de Reserva ("Em Análise") | 48 horas | Expiração automática — volta a DISPONIVEL |
| Prazo de Quarentena | 180 dias | Após desvinculação — bloqueio para reuso |

---

## 2. Limites de Estoque Setorial

### 2.1 Setor Brooklin

| Parâmetro | Valor |
|---|---|
| Estoque Total Máximo | 1.400.000,00 m² |
| Teto Absoluto NR | 980.000,00 m² (70% do estoque) |
| Mínimo Obrigatório R | 30% do consumo acumulado do setor |
| NR Acumulado (2026) | 716.470,01 m² |
| **Saldo NR Disponível** | **263.529,99 m²** |

**Lógica do validator:**
```
BLOQUEIA se: acumulado_NR + solicitacao_NR > 980.000,00
```

---

### 2.2 Setor Berrini

| Parâmetro | Valor |
|---|---|
| Estoque Total Máximo | 350.000,00 m² |
| Teto Absoluto NR | 175.000,00 m² (50% do estoque) |
| Teto Absoluto R | 175.000,00 m² (50% do estoque) |
| NR Consumido ACA | 203.202,23 m² |
| NR Consumido NUVEM | 595,00 m² |
| **NR Total Consumido** | **203.797,23 m²** ⚠️ |
| R Consumido NUVEM | 100,62 m² |
| **Saldo NR Disponível** | **0,00 m² — LIMITE EXCEDIDO** |

> ⚠️ **ATENÇÃO:** O consumo NR atual (203.202,23 m²) já **ultrapassa** o teto de 175.000,00 m².
> O motor de regras deve bloquear **todos** os novos pedidos NR para este setor imediatamente.

**Lógica do validator:**
```
BLOQUEIA SEMPRE: qualquer solicitacao_NR > 0
(acumulado já excedeu o teto — não há saldo disponível)
```

---

### 2.3 Setor Marginal Pinheiros

| Parâmetro | Valor |
|---|---|
| Estoque Total Máximo | 600.000,00 m² |
| Teto Absoluto NR | 420.000,00 m² (70% do estoque) |
| Mínimo Obrigatório R | 30% do consumo acumulado do setor |
| NR Consumido — origem ACA | 258.908,19 m² |
| NR Consumido — origem NUVEM | 0,00 m² |
| NR Em Análise (reservas) | 11.173,06 m² |
| **Total Comprometido NR** | **270.081,25 m²** (258.908,19 + 0,00 + 11.173,06) |
| **Saldo NR Disponível** | **149.918,75 m²** (420.000,00 − 270.081,25) ✓ |

> **Origem do consumo — ACA vs NUVEM:** O sistema registra duas categorias de origem para
> consumo NR: `ACA` (vinculações por alvará/certidão de aceite) e `NUVEM` (vinculações digitais).
> O validator soma **ambas** para calcular o total comprometido. Ver impacto no modelo de dados abaixo.

**Fórmula do validator:**
```
Total_Comprometido_NR = Consumido_NR_ACA + Consumido_NR_NUVEM + Em_Analise_NR
Saldo_NR              = 420.000,00 − Total_Comprometido_NR

BLOQUEIA se: Total_Comprometido_NR + solicitacao_NR > 420.000,00
```

---

### 2.4 Setor Chucri Zaidan

| Parâmetro | Valor |
|---|---|
| Estoque Total Máximo | 2.000.000,00 m² |
| Reserva Residencial Obrigatória (Lei 16.975/2018) | 216.442,47 m² — uso exclusivamente R |
| Teto Absoluto NR | 1.783.557,53 m² (Estoque Total − Reserva R) |
| R Consumido ACA | 751.909,09 m² *(posição 13/04/2026)* |
| R Consumido NUVEM | 204,70 m² |
| **R Total Consumido** | **752.113,79 m²** |
| NR Consumido ACA | 1.050.881,42 m² ⚠️ *ver nota de divergência* |
| NR Consumido NUVEM | 434,79 m² |
| **NR Total Consumido** | **1.051.316,21 m²** |
| Em Análise (todo R) | 14.006,35 m² |
| **Saldo NR Disponível** | **182.563,65 m²** ✓ |

> ⚠️ **Divergência NR ACA Chucri Zaidan:** Seed anterior (v1.5) registrava 1.111.411,24 m²; planilha de 13/04/2026 indica **1.050.881,42 m²** (diferença: −60.529,82 m²). Valor adotado: **1.050.881,42 m²** (posição mais recente com fórmula validada).

**Fórmula do validator (obrigatória — validada em 13/04/2026):**
```
R_total       = Consumido_R_ACA  + Consumido_R_NUVEM  = 751.909,09 + 204,70     = 752.113,79
NR_total      = Consumido_NR_ACA + Consumido_NR_NUVEM = 1.050.881,42 + 434,79  = 1.051.316,21
Em_Analise    = 14.006,35  (100% uso R na posição atual)

Saldo_NR = 2.000.000,00 − (R_total + NR_total + Em_Analise)
         = 2.000.000,00 − (752.113,79 + 1.051.316,21 + 14.006,35)
         = 2.000.000,00 − 1.817.436,35
         = 182.563,65 m²  ✓
```

**Regra de isolamento:**
- O estoque NR trava quando o consumo total do setor atinge **1.783.557,53 m²**
  (garantindo que os 216.442,47 m² restantes sejam exclusivamente R)
- `Em_Analise` entra na fórmula pois reservas temporárias comprometem o saldo NR disponível

**Lógica do validator:**
```python
consumo_total = R_total + NR_total + em_analise

BLOQUEIA pedido NR se: consumo_total + solicitacao_NR > 1.783.557,53
```

---

### 2.5 Setor Jabaquara

| Parâmetro | Valor |
|---|---|
| Estoque Total Máximo | 250.000,00 m² |
| Teto Absoluto NR | 175.000,00 m² |
| NR Acumulado (2026) | 0,00 m² |
| **Saldo NR Disponível** | **175.000,00 m²** |

**Lógica do validator:**
```
BLOQUEIA se: acumulado_NR + solicitacao_NR > 175.000,00
```

---

## 3. Resumo Consolidado de Saldos (Estado 2026)

| Setor | Estoque Total | Teto NR | NR Consumido | NR Em Análise | Saldo NR | Status |
|---|---|---|---|---|---|---|
| Brooklin | 1.400.000,00 | 980.000,00 | 716.470,01 | — | **263.529,99** | 🟡 Parcialmente consumido |
| Berrini | 350.000,00 | 175.000,00 | 203.202,23 | — | **0,00** | 🔴 Limite excedido (+28.202,23) |
| Marginal Pinheiros | 600.000,00 | 420.000,00 | 258.908,19 (ACA) + 0,00 (NUVEM) | 11.173,06 | **149.918,75** ✓ | 🟡 Parcialmente consumido |
| Chucri Zaidan | 2.000.000,00 | 1.783.557,53 | NR: 1.051.316,21 / R: 752.113,79 | 14.006,35 (R) | **182.563,65** ✓ | 🟡 Parcialmente consumido |
| Jabaquara | 250.000,00 | 175.000,00 | 0,00 | — | **175.000,00** | 🟢 Livre |
| **Total setores** | **4.600.000,00** | — | — | — | — | — |

> ✓ Saldo Marginal Pinheiros confirmado: 149.918,75 m². Divergência anterior resolvida — o total comprometido é composto por duas origens de consumo (ACA + NUVEM), não apenas uma.

---

## 4. Script de Seed — Estado Inicial do Banco (Abril 2026)

Valores exatos a serem inseridos na tabela `setor` na migration de seed inicial.
Usar estes números como estado de partida para todos os ambientes (dev, staging, prod).

```sql
-- seed/001_estado_inicial_abril_2026.sql
-- Fonte: Planilha Consolidada SP Urbanismo — Abril 2026
-- ACA = Área Adicional de Construção | NUVEM = Estoque virtual/transferido

-- Tabela de setores com limites estruturais (imutáveis)
INSERT INTO setor (nome, estoque_total_m2, teto_nr_m2, reserva_r_m2) VALUES
  ('Brooklin',          1400000.00,  980000.00,       NULL),
  ('Berrini',            350000.00,  175000.00,       NULL),
  ('Marginal Pinheiros', 600000.00,  420000.00,       NULL),
  ('Chucri Zaidan',    2000000.00, 1783557.53, 216442.47),  -- reserva R: Lei 16.975/2018
  ('Jabaquara',          250000.00,  175000.00,       NULL);

-- Estado inicial: consumo NR por setor, uso e origem (Abril 2026)
-- Forma o ponto de partida do log de movimentações (event-sourcing)
INSERT INTO movimentacao_seed (setor_nome, uso, origem, area_m2, estado, data_referencia) VALUES
  -- BROOKLIN
  ('Brooklin',          'NR', 'ACA',   716470.01, 'CONSUMIDO',  '2026-04-01'),
  ('Brooklin',          'NR', 'NUVEM',      0.00, 'CONSUMIDO',  '2026-04-01'),  -- prever coluna
  ('Brooklin',          'R',  'NUVEM',      0.00, 'CONSUMIDO',  '2026-04-01'),  -- prever coluna

  -- BERRINI (NR excede teto — bloqueio incondicional)
  ('Berrini',           'NR', 'ACA',   203202.23, 'CONSUMIDO',  '2026-04-01'),
  ('Berrini',           'NR', 'NUVEM',    595.00, 'CONSUMIDO',  '2026-04-01'),  -- total NR: 203.797,23
  ('Berrini',           'R',  'NUVEM',    100.62, 'CONSUMIDO',  '2026-04-01'),

  -- MARGINAL PINHEIROS
  ('Marginal Pinheiros','NR', 'ACA',   258908.19, 'CONSUMIDO',  '2026-04-01'),
  ('Marginal Pinheiros','NR', 'NUVEM',      0.00, 'CONSUMIDO',  '2026-04-01'),
  ('Marginal Pinheiros','NR', 'ACA',    11173.06, 'EM_ANALISE', '2026-04-01'),
  ('Marginal Pinheiros','R',  'NUVEM',   1301.13, 'CONSUMIDO',  '2026-04-01'),

  -- CHUCRI ZAIDAN (posição 13/04/2026 — fórmula validada)
  ('Chucri Zaidan',     'NR', 'ACA',  1050881.42, 'CONSUMIDO',  '2026-04-13'),  -- ⚠️ corrigido de 1.111.411,24
  ('Chucri Zaidan',     'NR', 'NUVEM',    434.79, 'CONSUMIDO',  '2026-04-13'),  -- NR total: 1.051.316,21
  ('Chucri Zaidan',     'R',  'ACA',   751909.09, 'CONSUMIDO',  '2026-04-13'),
  ('Chucri Zaidan',     'R',  'NUVEM',    204.70, 'CONSUMIDO',  '2026-04-13'),  -- R total: 752.113,79
  ('Chucri Zaidan',     'R',  'ACA',    14006.35, 'EM_ANALISE', '2026-04-13'),  -- Em Análise: todo R

  -- JABAQUARA
  ('Jabaquara',         'NR', 'ACA',        0.00, 'CONSUMIDO',  '2026-04-01'),
  ('Jabaquara',         'NR', 'NUVEM',      0.00, 'CONSUMIDO',  '2026-04-01'),  -- prever coluna
  ('Jabaquara',         'R',  'NUVEM',      0.00, 'CONSUMIDO',  '2026-04-01');  -- prever coluna
```

> **Nota de validação pós-seed:** O motor de regras deve retornar os seguintes estados:
> | Setor | Pedido NR de 1 m² | Saldo NR |
> |---|---|---|
> | Brooklin | ✅ Aprovado | 263.529,99 m² |
> | Berrini | ❌ ERRO `TETO_NR_EXCEDIDO` | 0,00 m² (bloqueio incondicional) |
> | Marginal Pinheiros | ✅ Aprovado | 149.918,75 m² |
> | Chucri Zaidan | ✅ Aprovado | calculado em runtime |
> | Jabaquara | ✅ Aprovado | 175.000,00 m² |

---

## 5. Referências Legais

| Norma | Descrição |
|---|---|
| Lei 16.975/2018 | Estabelece a reserva residencial obrigatória de 216.442,47 m² no setor Chucri Zaidan |

---

*Documento de referência — não modificar sem aprovação do Tech Lead e da SP Urbanismo.*
*Posição de referência: Planilha Consolidada SP Urbanismo, 13/04/2026. Versão do documento: 1.2.*
