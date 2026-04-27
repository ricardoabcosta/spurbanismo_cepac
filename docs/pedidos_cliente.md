# Pedidos ao Cliente — SP Urbanismo / OUCAE

Itens que dependem de informações ou ações do cliente para avançar no sistema.

---

## 1. Série histórica de consumo de estoque e custo incorrido

**Contexto:**
A planilha `OUCAE_ESTOQUE_abr_rv01.xlsx` contém apenas a posição consolidada de 13/04/2026. Não há série temporal. Por isso, o Dashboard Executivo em modo snapshot histórico exibe consumo zero e custo R$ 0,00 para qualquer data anterior a abril/2026 — todos os dados de consumo aparecem como se tivessem ocorrido em abril/2026.

**O que precisamos — opção A (ideal):**
Exportação do sistema de origem (SIMPROC / SEI / planilha de controle) com o histórico de vinculações aprovadas, contendo pelo menos: data de aprovação, setor, uso (R/NR), origem (ACA/NUVEM) e área (m²). Com isso carregamos o consumo mês a mês retroativamente.

**O que precisamos — opção B (mínimo viável):**
Tabela com consumo acumulado por setor/ano (ou mês/ano), no formato:

| ano  | setor              | uso | origem | consumido_acumulado_m2 |
|------|--------------------|-----|--------|------------------------|
| 2010 | Brooklin           | NR  | ACA    | 50.000,00              |
| 2011 | Brooklin           | NR  | ACA    | 120.000,00             |
| …    | …                  | …   | …      | …                      |

**Custo Total Incorrido — série separada:**

| data_referencia | valor_acumulado (R$) |
|-----------------|---------------------|
| 2010-12-31      | 15.000.000,00       |
| 2011-12-31      | 42.000.000,00       |
| …               | …                   |
| 2026-04-01      | 3.987.822.642,21    | ← já carregado |

**Responsável no cliente:** área de obras / contabilidade / gestão da OUCAE
**Impacto:** médio — afeta apenas a visão histórica do dashboard; tempo real está correto.

---

## 2. App Registration no Azure AD

**O que precisamos:**
Criação do App Registration no Azure AD (tenant `f398df9c-fd0c-4829-a003-c770a1c4a063`) para habilitar autenticação real com contas corporativas SP Urbanismo.

**Detalhes técnicos necessários após criação:**
- `client_id` do App Registration (Portal) → GitHub Secret `PORTAL_AZURE_CLIENT_ID`
- `client_id` do App Registration (Dashboard) → GitHub Secret `DASHBOARD_AZURE_CLIENT_ID`
- Redirect URIs cadastradas: `https://<portal-url>/` e `https://<dashboard-url>/`
- App Roles criados: `TECNICO` e `DIRETOR`

**Responsável no cliente:** time de infraestrutura / Azure AD admin
**Impacto:** alto — sem isso, login com conta corporativa não funciona; sistema opera apenas em modo DEV_BYPASS.

---
