# Processo CEPAC — Proposta e Vinculação

## 1. Visão geral

O sistema CEPAC gerencia dois objetos de negócio distintos:

| Objeto | Tabela | Quem cria | Representa |
|--------|--------|-----------|------------|
| **Proposta** | `proposta` | Técnico/admin (ou empreendedor via portal) | O empreendimento AE-XXXX que requereu vinculação de CEPACs |
| **Vinculação** | `solicitacao_vinculacao` | Técnico/admin (painel de Administração) | O ato transacional de consumir títulos CEPAC físicos para uma proposta |

Eles **não se convertem um no outro**. A proposta descreve o empreendimento; a vinculação executa o consumo dos títulos.

---

## 2. Ciclo de vida da Proposta

```
[Cadastro]
    ↓
 ANALISE  ──── técnico analisa documentação, área, CEPACs calculados
    ↓               ↓
DEFERIDO      INDEFERIDO
```

### Estados (`status_pa`)

| Estado | Significado |
|--------|-------------|
| `ANALISE` | Proposta recebida, em análise técnica. Estado inicial. |
| `DEFERIDO` | Aprovada. Os CEPACs calculados foram confirmados e podem ser vinculados. |
| `INDEFERIDO` | Negada. Proposta arquivada sem consumo de títulos. |

### Atributos principais da proposta

- **Identificação:** `codigo` (AE-XXXX), `numero_pa` (SEI ou SIMPROC), `data_autuacao`
- **Interessado:** `interessado`, `tipo_interessado` (PF/PJ), `cnpj`/`cpf`, `endereco`
- **Localização:** `setor_id` (FK → setor), `contribuinte_sq`, `contribuinte_lote`
- **Área e uso:** `area_terreno_m2`, `uso_aca` (R/NR/MISTO), `aca_r_m2`, `aca_nr_m2`, `aca_total_m2`
- **CEPACs calculados:** `cepac_aca`, `cepac_parametros`, `cepac_total`
- **NUVEM:** `nuvem_r_m2`, `nuvem_nr_m2`, `nuvem_total_m2`, `nuvem_cepac`
- **Contrapartida:** `tipo_contrapartida`, `valor_oodc_rs`
- **Certidão emitida:** `certidao`, `situacao_certidao`, `data_certidao`
- **Controle:** `requerimento` (VINCULACAO/ALTERACAO/DESVINCULACAO), `obs`, `resp_data`

---

## 3. Ciclo de vida da Vinculação

Uma proposta DEFERIDA pode gerar uma ou mais vinculações (ex.: ACA em um momento, NUVEM em outro).

```
[Técnico seleciona títulos CEPAC disponíveis]
    ↓
 EM_ANALISE  ──── engine de regras valida saldo setorial, teto NR, piso R, prazo
    ↓               ↓
 APROVADA      REJEITADA (com motivo_rejeicao)
    ↓
 títulos → CONSUMIDO
    ↓
 [pode ser cancelada enquanto EM_ANALISE → títulos voltam a DISPONIVEL]
```

### Estados (`status` da solicitacao_vinculacao)

| Estado | Significado |
|--------|-------------|
| `EM_ANALISE` | Vinculação criada, títulos reservados (estado EM_ANALISE no titulo_cepac) |
| `APROVADA` | Títulos consumidos definitivamente (estado CONSUMIDO no titulo_cepac) |
| `REJEITADA` | Engine ou diretor rejeitou; títulos voltam a DISPONIVEL; `motivo_rejeicao` preenchido |
| `CANCELADA` | Cancelada pelo técnico antes da aprovação; títulos voltam a DISPONIVEL |
| `PENDENTE` | Legado — não usado em novos registros |

### Atributos da vinculação

- `proposta_id` — FK para a proposta associada (obrigatório nos novos fluxos)
- `setor_id` — setor dos títulos (deve coincidir com o setor da proposta)
- `uso` — R ou NR (o engine trata R e NR separadamente)
- `origem` — ACA ou NUVEM
- `area_m2` — metros quadrados desta vinculação específica
- `quantidade_cepacs` — títulos a consumir
- `numero_processo_sei` — SEI do processo de vinculação
- `motivo_rejeicao` — obrigatório se REJEITADA

---

## 4. Relação entre Proposta e Vinculação

```
proposta AE-0123  (Brooklin, PJ Fulano, 1.200 m² ACA MISTO, 240 CEPACs)
  │
  ├── solicitacao_vinculacao #1  (ACA, uso=R,  origem=ACA,   160 CEPACs → APROVADA)
  │     └── solicitacao_titulos → titulo_cepac #45, #46, ... (160 títulos CONSUMIDOS)
  │
  └── solicitacao_vinculacao #2  (NUVEM, uso=NR, origem=NUVEM, 80 CEPACs → EM_ANALISE)
        └── solicitacao_titulos → titulo_cepac #201, #202, ... (80 títulos EM_ANALISE)
```

Uma proposta pode ter **zero ou N vinculações**. O `proposta_id` na vinculação é opcional (legado) mas deve ser obrigatório nos novos registros.

---

## 5. Onde cada ação ocorre no sistema

| Ação | Quem | Onde | Tabela afetada |
|------|------|------|----------------|
| Cadastrar proposta | Técnico/empreendedor | Portal → "Nova Proposta" | `proposta` (INSERT) |
| Alterar status PA (deferir/indeferir) | Técnico | Painel Admin | `proposta` (UPDATE status_pa) |
| Criar vinculação | Técnico | Painel Admin → detalhe da proposta → "Nova Vinculação" | `solicitacao_vinculacao` (INSERT) + `titulo_cepac` (→ EM_ANALISE) |
| Aprovar vinculação | Diretor | Painel Admin | `solicitacao_vinculacao` (→ APROVADA) + `titulo_cepac` (→ CONSUMIDO) + `movimentacao` (INSERT) |
| Rejeitar vinculação | Diretor | Painel Admin | `solicitacao_vinculacao` (→ REJEITADA) + `titulo_cepac` (→ DISPONIVEL) + `movimentacao` |
| Cancelar vinculação | Técnico | Portal ou Admin | `solicitacao_vinculacao` (→ CANCELADA) + `titulo_cepac` (→ DISPONIVEL) |

---

## 6. Engine de regras (validação automática)

Quando uma vinculação é criada, o `RulesEngine` valida automaticamente:

- **Saldo setorial:** setor tem CEPACs disponíveis suficientes?
- **Teto NR:** consumo NR não ultrapassa o limite do setor?
- **Piso R:** consumo R está acima do mínimo do setor?
- **Uso MISTO:** divide a área 50/50 entre R e NR para fins de validação
- **Prazo da operação:** a OUCAE ainda está dentro do prazo vigente?
- **Berrini específico:** bloqueia qualquer uso NR/MISTO neste setor

Se alguma regra falhar, a vinculação é automaticamente REJEITADA com `motivo_rejeicao` descritivo.

---

## 7. O que ainda falta implementar

| Funcionalidade | Prioridade | Notas |
|----------------|-----------|-------|
| Listar `proposta` na tela "Propostas de CEPAC" | Alta | Hoje lista `solicitacao_vinculacao` |
| Endpoint `GET /portal/propostas` (listagem paginada) | Alta | Endpoint de busca individual já existe |
| Formulário "Nova Proposta" criar `proposta` (não `solicitacao_vinculacao`) | Alta | Requer refatoração do `NovaPropostaPage` |
| Tela admin: deferir/indeferir proposta | Alta | Mudar `status_pa` |
| Tela admin: "Nova Vinculação" dentro do detalhe da proposta | Média | Criar `solicitacao_vinculacao` linkada à proposta |
| Tornar `proposta_id` obrigatório nas novas vinculações | Média | Migration + validação Pydantic |
