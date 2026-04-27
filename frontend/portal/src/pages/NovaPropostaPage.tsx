/**
 * Página /propostas/nova — wizard 4 etapas para criação de proposta.
 *
 * Etapa 1 — Dados do Imóvel:   setor, uso, origem, área m², endereço
 * Etapa 2 — Características:   tipo interessado, nome/CNPJ/CPF, uso ACA, áreas MISTO
 * Etapa 3 — CEPACs:            cepac_aca, cepac_parametros, títulos disponíveis
 * Etapa 4 — Documentação:      SEI, código proposta, observação, upload, enviar
 */
import { useState, useEffect, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import { listarTitulosDisponiveis, criarProposta, isErroNegocioError } from "../api/portal";
import { listarSetores } from "../api/admin";
import UploadDocumento from "../components/UploadDocumento";
import type { TituloDisponivel, SetorOut } from "../types/api";
import type { ErroNegocio } from "../types/api";

const SEI_NOVO = /^\d{4}\.\d{4}\/\d{7}-\d$/;
const SEI_SIMPROC = /^\d{4}-\d\.\d{3}\.\d{3}-\d$/;
const validarSEI = (v: string) => SEI_NOVO.test(v) || SEI_SIMPROC.test(v);

const MENSAGENS_ERRO: Record<string, (erro: ErroNegocio) => string> = {
  TETO_NR_EXCEDIDO: () => "Setor Berrini: estoque NR esgotado. Pedidos NR não podem ser processados.",
  RESERVA_R_VIOLADA: () => "Setor Chucri Zaidan: pedido NR invadiria a reserva residencial protegida.",
  QUARENTENA_ATIVA: (e) => `Título em quarentena — disponível em ${e.dias_restantes ?? "?"} dias.`,
  NUMERO_SEI_OBRIGATORIO: () => "Informe o número do processo SEI antes de enviar.",
  SOLICITACAO_NAO_CANCELAVEL: (e) => e.mensagem,
};

function traduzirErroNegocio(erro: ErroNegocio): string {
  const fn = MENSAGENS_ERRO[erro.codigo_erro];
  return fn ? fn(erro) : erro.mensagem;
}

function mascaraCNPJ(valor: string): string {
  const digits = valor.replace(/\D/g, "").slice(0, 14);
  if (digits.length <= 2) return digits;
  if (digits.length <= 5) return `${digits.slice(0, 2)}.${digits.slice(2)}`;
  if (digits.length <= 8) return `${digits.slice(0, 2)}.${digits.slice(2, 5)}.${digits.slice(5)}`;
  if (digits.length <= 12) return `${digits.slice(0, 2)}.${digits.slice(2, 5)}.${digits.slice(5, 8)}/${digits.slice(8)}`;
  return `${digits.slice(0, 2)}.${digits.slice(2, 5)}.${digits.slice(5, 8)}/${digits.slice(8, 12)}-${digits.slice(12)}`;
}

function mascaraCPF(valor: string): string {
  const digits = valor.replace(/\D/g, "").slice(0, 11);
  if (digits.length <= 3) return digits;
  if (digits.length <= 6) return `${digits.slice(0, 3)}.${digits.slice(3)}`;
  if (digits.length <= 9) return `${digits.slice(0, 3)}.${digits.slice(3, 6)}.${digits.slice(6)}`;
  return `${digits.slice(0, 3)}.${digits.slice(3, 6)}.${digits.slice(6, 9)}-${digits.slice(9)}`;
}

const TIPO_CONTRAPARTIDA_FIXO = "CEPAC (título)";
// ---------------------------------------------------------------------------
// Steps
// ---------------------------------------------------------------------------

const STEPS = [
  { id: 1, label: "Dados do Imóvel" },
  { id: 2, label: "Características" },
  { id: 3, label: "CEPACs" },
  { id: 4, label: "Documentação" },
];

// ---------------------------------------------------------------------------
// StepIndicator
// ---------------------------------------------------------------------------

function StepIndicator({ atual }: { atual: number }) {
  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        background: "#fff",
        borderBottom: "1px solid #e0e4ea",
        padding: "20px 32px",
      }}
    >
      {STEPS.map((step, idx) => {
        const concluido = step.id < atual;
        const ativo = step.id === atual;
        return (
          <div key={step.id} style={{ display: "flex", alignItems: "center", flex: idx < STEPS.length - 1 ? 1 : undefined }}>
            {/* Círculo numerado */}
            <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: "6px" }}>
              <div
                style={{
                  width: "36px",
                  height: "36px",
                  borderRadius: "50%",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  fontWeight: 700,
                  fontSize: "14px",
                  background: concluido ? "#003087" : ativo ? "#003087" : "#e8ecf0",
                  color: concluido || ativo ? "#fff" : "#888",
                  border: ativo ? "3px solid #1a5fbf" : "3px solid transparent",
                  boxSizing: "border-box",
                  transition: "all 0.2s",
                  flexShrink: 0,
                }}
              >
                {concluido ? "✓" : step.id}
              </div>
              <span
                style={{
                  fontSize: "11px",
                  fontWeight: ativo ? 700 : 500,
                  color: ativo ? "#003087" : concluido ? "#555" : "#aaa",
                  whiteSpace: "nowrap",
                  letterSpacing: "0.3px",
                }}
              >
                {step.label}
              </span>
            </div>
            {/* Linha conectora */}
            {idx < STEPS.length - 1 && (
              <div
                style={{
                  flex: 1,
                  height: "2px",
                  background: concluido ? "#003087" : "#e0e4ea",
                  marginBottom: "22px",
                  marginLeft: "8px",
                  marginRight: "8px",
                  transition: "background 0.2s",
                }}
              />
            )}
          </div>
        );
      })}
    </div>
  );
}

// ---------------------------------------------------------------------------
// Estilos
// ---------------------------------------------------------------------------

const s: Record<string, React.CSSProperties> = {
  label: { display: "block", marginBottom: "5px", fontSize: "14px", fontWeight: 500, color: "#222" },
  labelSec: { display: "block", marginBottom: "5px", fontSize: "13px", fontWeight: 500, color: "#444" },
  input: { padding: "8px 10px", border: "1px solid #ccc", borderRadius: "5px", fontSize: "14px", width: "100%", boxSizing: "border-box" as const, background: "#fff" },
  inputErr: { borderColor: "#cc0000" },
  inputDis: { background: "#f0f0f0", color: "#666", cursor: "not-allowed" },
  select: { padding: "8px 10px", border: "1px solid #ccc", borderRadius: "5px", fontSize: "14px", width: "100%", boxSizing: "border-box" as const, background: "#fff" },
  textarea: { padding: "8px 10px", border: "1px solid #ccc", borderRadius: "5px", fontSize: "14px", width: "100%", boxSizing: "border-box" as const, minHeight: "80px", resize: "vertical" as const, background: "#fff" },
  secao: { marginBottom: "20px" },
  hint: { fontSize: "12px", color: "#666", marginTop: "3px" },
  errBox: { color: "#cc0000", background: "#fff0f0", padding: "12px", borderRadius: "5px", marginBottom: "16px", border: "1px solid rgba(204,0,0,0.2)", fontSize: "14px" },
  linhaDupla: { display: "grid", gridTemplateColumns: "1fr 1fr", gap: "14px" },
  linha: { display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: "14px" },
  radioGroup: { display: "flex", gap: "20px", alignItems: "center", paddingTop: "4px" },
  radioItem: { display: "flex", alignItems: "center", gap: "6px", fontSize: "14px", cursor: "pointer" },
  subsecao: { marginTop: "14px", borderLeft: "3px solid #d0d8e8", paddingLeft: "12px" },
  listaTitulos: { maxHeight: "260px", overflowY: "auto" as const, border: "1px solid #e0e4ea", borderRadius: "6px", padding: "8px", background: "#fff" },
  itemTitulo: { display: "flex", alignItems: "flex-start", gap: "8px", padding: "6px 0", borderBottom: "1px solid #f0f0f0" },
  checkboxLabel: { fontSize: "13px", cursor: "pointer", flex: 1 },
};

// ---------------------------------------------------------------------------
// Componente principal
// ---------------------------------------------------------------------------

export default function NovaPropostaPage() {
  const navigate = useNavigate();

  // Estado do wizard
  const [etapa, setEtapa] = useState(1);
  const [erroEtapa, setErroEtapa] = useState("");

  // Etapa 1 — Dados do Imóvel
  const [setores, setSetores] = useState<SetorOut[]>([]);
  const [setor, setSetor] = useState("");
  const [uso, setUso] = useState<"R" | "NR" | "">("");
  const [origem, setOrigem] = useState<"ACA" | "NUVEM" | "">("");
  const [areaM2, setAreaM2] = useState("");
  const [endereco, setEndereco] = useState("");

  // Etapa 2 — Características
  const [dataProposta, setDataProposta] = useState("");
  const [tipoInteressado, setTipoInteressado] = useState<"PF" | "PJ" | "">("");
  const [razaoSocial, setRazaoSocial] = useState("");
  const [cnpj, setCnpj] = useState("");
  const [cpf, setCpf] = useState("");
  const [usoAca, setUsoAca] = useState<"R" | "NR" | "MISTO" | "">("");
  const [acaRm2, setAcaRm2] = useState("");
  const [acaNrm2, setAcaNrm2] = useState("");

  // Etapa 3 — CEPACs
  const [cepacAca, setCepacAca] = useState("");
  const [cepacParametros, setCepacParametros] = useState("");
  const [titulos, setTitulos] = useState<TituloDisponivel[]>([]);
  const [titulosSelecionados, setTitulosSelecionados] = useState<Set<string>>(new Set());
  const [carregandoTitulos, setCarregandoTitulos] = useState(false);

  // Etapa 4 — Documentação
  const [sei, setSei] = useState("");
  const [seiTocado, setSeiTocado] = useState(false);
  const [proposta, setProposta] = useState("");
  const [observacao, setObservacao] = useState("");

  // Envio
  const [enviando, setEnviando] = useState(false);
  const [erroEnvio, setErroEnvio] = useState("");

  const [hoveredVoltar, setHoveredVoltar] = useState(false);

  const seiInvalido = seiTocado && sei !== "" && !validarSEI(sei);
  const tipoContrapartida = TIPO_CONTRAPARTIDA_FIXO;

  // ---------------------------------------------------------------------------
  // Carregar setores ao montar
  // ---------------------------------------------------------------------------
  useEffect(() => {
    listarSetores()
      .then((lista) => setSetores(lista.filter((s) => s.ativo)))
      .catch(() => setSetores([]));
  }, []);

  // ---------------------------------------------------------------------------
  // Carregar títulos quando setor/uso/origem estão selecionados (etapa 3)
  // ---------------------------------------------------------------------------
  const carregarTitulos = useCallback(async () => {
    if (!setor || !uso || !origem) {
      setTitulos([]);
      setTitulosSelecionados(new Set());
      return;
    }
    setCarregandoTitulos(true);
    try {
      const dados = await listarTitulosDisponiveis({ setor, uso, origem });
      setTitulos(dados);
      setTitulosSelecionados(new Set());
    } catch {
      setTitulos([]);
    } finally {
      setCarregandoTitulos(false);
    }
  }, [setor, uso, origem]);

  useEffect(() => {
    if (etapa === 3) void carregarTitulos();
  }, [etapa, carregarTitulos]);

  // ---------------------------------------------------------------------------
  // Persistência rascunho
  // ---------------------------------------------------------------------------
  useEffect(() => {
    const rascunho = {
      setor, uso, origem, areaM2, endereco,
      dataProposta, tipoInteressado, razaoSocial, cnpj, cpf,
      usoAca, acaRm2, acaNrm2, cepacAca, cepacParametros,
      sei, proposta, observacao,
    };
    sessionStorage.setItem("cepac_nova_proposta_rascunho", JSON.stringify(rascunho));
  }, [
    setor, uso, origem, areaM2, endereco,
    dataProposta, tipoInteressado, razaoSocial, cnpj, cpf,
    usoAca, acaRm2, acaNrm2, cepacAca, cepacParametros,
    sei, proposta, observacao,
  ]);

  useEffect(() => {
    const raw = sessionStorage.getItem("cepac_nova_proposta_rascunho");
    if (!raw) return;
    try {
      const r = JSON.parse(raw) as Record<string, string>;
      if (r.setor) setSetor(r.setor);
      if (r.uso) setUso(r.uso as "R" | "NR");
      if (r.origem) setOrigem(r.origem as "ACA" | "NUVEM");
      if (r.areaM2) setAreaM2(r.areaM2);
      if (r.endereco) setEndereco(r.endereco);
      if (r.dataProposta) setDataProposta(r.dataProposta);
      if (r.tipoInteressado) setTipoInteressado(r.tipoInteressado as "PF" | "PJ");
      if (r.razaoSocial) setRazaoSocial(r.razaoSocial);
      if (r.cnpj) setCnpj(r.cnpj);
      if (r.cpf) setCpf(r.cpf);
      if (r.usoAca) setUsoAca(r.usoAca as "R" | "NR" | "MISTO");
      if (r.acaRm2) setAcaRm2(r.acaRm2);
      if (r.acaNrm2) setAcaNrm2(r.acaNrm2);
      if (r.cepacAca) setCepacAca(r.cepacAca);
      if (r.cepacParametros) setCepacParametros(r.cepacParametros);
      if (r.sei) setSei(r.sei);
      if (r.proposta) setProposta(r.proposta);
      if (r.observacao) setObservacao(r.observacao);
    } catch { /* ignora rascunho corrompido */ }
  }, []);

  // ---------------------------------------------------------------------------
  // Validação por etapa
  // ---------------------------------------------------------------------------
  function validarEtapa(n: number): string {
    if (n === 1) {
      if (!setor) return "Selecione o setor.";
      if (!uso) return "Selecione o uso.";
      if (!origem) return "Selecione a origem.";
      if (!areaM2 || isNaN(parseFloat(areaM2)) || parseFloat(areaM2) <= 0)
        return "Informe uma área em m² válida (maior que zero).";
    }
    if (n === 2) {
      if (!tipoInteressado) return "Selecione o tipo de interessado.";
      if (!razaoSocial.trim())
        return `Informe o campo "${tipoInteressado === "PJ" ? "Razão Social" : "Nome"}".`;
      if (tipoInteressado === "PJ" && !cnpj) return "Informe o CNPJ.";
      if (tipoInteressado === "PF" && !cpf) return "Informe o CPF.";
      if (usoAca === "MISTO") {
        if (!acaRm2 || parseFloat(acaRm2) <= 0) return "Informe a Área R (m²) para uso MISTO.";
        if (!acaNrm2 || parseFloat(acaNrm2) <= 0) return "Informe a Área NR (m²) para uso MISTO.";
      }
    }
    if (n === 3) {
      if (titulosSelecionados.size === 0) return "Selecione ao menos um título CEPAC.";
    }
    if (n === 4) {
      if (!sei || !validarSEI(sei)) return "Informe o número do processo SEI no formato correto.";
    }
    return "";
  }

  function avancar() {
    const erro = validarEtapa(etapa);
    if (erro) { setErroEtapa(erro); return; }
    setErroEtapa("");
    setEtapa((e) => Math.min(e + 1, 4));
  }

  function voltar() {
    setErroEtapa("");
    setEtapa((e) => Math.max(e - 1, 1));
  }

  function toggleTitulo(id: string) {
    setTitulosSelecionados((prev) => {
      const novo = new Set(prev);
      if (novo.has(id)) novo.delete(id); else novo.add(id);
      return novo;
    });
  }

  // ---------------------------------------------------------------------------
  // Envio final
  // ---------------------------------------------------------------------------
  async function handleEnviar() {
    setErroEnvio("");
    const erroDoc = validarEtapa(4);
    if (erroDoc) { setErroEnvio(erroDoc); return; }

    setEnviando(true);
    try {
      const nova = await criarProposta({
        setor,
        uso: uso as "R" | "NR",
        origem: origem as "ACA" | "NUVEM",
        area_m2: parseFloat(areaM2),
        numero_processo_sei: sei,
        titulo_ids: Array.from(titulosSelecionados),
        proposta_codigo: proposta || undefined,
        observacao: observacao || undefined,
        tipo_contrapartida: tipoContrapartida,
        area_total_r: usoAca === "MISTO" && acaRm2 ? parseFloat(acaRm2) : undefined,
        area_total_nr: usoAca === "MISTO" && acaNrm2 ? parseFloat(acaNrm2) : undefined,
        cepac_aca: cepacAca ? parseInt(cepacAca, 10) : undefined,
        cepac_parametros: cepacParametros ? parseInt(cepacParametros, 10) : undefined,
      });
      sessionStorage.removeItem("cepac_nova_proposta_rascunho");
      navigate(`/propostas/${nova.id}`);
    } catch (e) {
      if (isErroNegocioError(e)) {
        setErroEnvio(traduzirErroNegocio(e.erroNegocio));
      } else {
        setErroEnvio("Erro inesperado ao criar a proposta. Tente novamente.");
      }
    } finally {
      setEnviando(false);
    }
  }

  // ---------------------------------------------------------------------------
  // Render etapas
  // ---------------------------------------------------------------------------

  function renderEtapa1() {
    return (
      <>
        <h2 style={{ fontSize: "18px", fontWeight: 700, color: "#003087", marginBottom: "20px" }}>
          Dados do Imóvel
        </h2>

        <div style={{ ...s.secao, ...s.linha }}>
          <div>
            <label style={s.label} htmlFor="setor">Setor *</label>
            <select id="setor" style={s.select} value={setor} onChange={(e) => setSetor(e.target.value)} required>
              <option value="">Selecione…</option>
              {setores.map((st) => (
                <option key={st.id} value={st.nome}>{st.nome}</option>
              ))}
            </select>
          </div>
          <div>
            <label style={s.label} htmlFor="uso">Uso *</label>
            <select id="uso" style={s.select} value={uso} onChange={(e) => setUso(e.target.value as "R" | "NR" | "")} required>
              <option value="">Selecione…</option>
              <option value="R">R — Residencial</option>
              <option value="NR">NR — Não-Residencial</option>
            </select>
          </div>
          <div>
            <label style={s.label} htmlFor="origem">Origem *</label>
            <select id="origem" style={s.select} value={origem} onChange={(e) => setOrigem(e.target.value as "ACA" | "NUVEM" | "")} required>
              <option value="">Selecione…</option>
              <option value="ACA">ACA</option>
              <option value="NUVEM">NUVEM</option>
            </select>
          </div>
        </div>

        <div style={s.secao}>
          <label style={s.label} htmlFor="area">Área total do terreno (m²) *</label>
          <input
            id="area"
            style={{ ...s.input, maxWidth: "220px" }}
            type="number" step="0.01" min="0.01"
            placeholder="Ex: 1000.00"
            value={areaM2}
            onChange={(e) => setAreaM2(e.target.value)}
            required
          />
        </div>

        <div style={s.secao}>
          <label style={s.label} htmlFor="endereco">Endereço do Imóvel</label>
          <textarea
            id="endereco"
            style={{ ...s.textarea, minHeight: "60px" }}
            placeholder="Rua, número, complemento, bairro…"
            value={endereco}
            onChange={(e) => setEndereco(e.target.value)}
          />
        </div>
      </>
    );
  }

  function renderEtapa2() {
    return (
      <>
        <h2 style={{ fontSize: "18px", fontWeight: 700, color: "#003087", marginBottom: "20px" }}>
          Características
        </h2>

        <div style={s.secao}>
          <label style={s.label} htmlFor="data_proposta">Data da Proposta</label>
          <input
            id="data_proposta"
            type="date"
            style={{ ...s.input, maxWidth: "200px" }}
            value={dataProposta}
            onChange={(e) => setDataProposta(e.target.value)}
          />
        </div>

        <div style={s.secao}>
          <fieldset style={{ border: "none", padding: 0, margin: 0 }}>
            <legend style={{ ...s.label, float: "none" as const, width: "100%" }}>Tipo de Interessado *</legend>
            <div style={s.radioGroup}>
              <label style={s.radioItem}>
                <input type="radio" name="tipo_interessado" value="PF" checked={tipoInteressado === "PF"}
                  onChange={() => { setTipoInteressado("PF"); setCnpj(""); }} />
                Pessoa Física
              </label>
              <label style={s.radioItem}>
                <input type="radio" name="tipo_interessado" value="PJ" checked={tipoInteressado === "PJ"}
                  onChange={() => { setTipoInteressado("PJ"); setCpf(""); }} />
                Pessoa Jurídica
              </label>
            </div>
          </fieldset>

          {tipoInteressado === "PJ" && (
            <div style={{ ...s.subsecao, marginTop: "14px" }}>
              <div style={s.linhaDupla}>
                <div>
                  <label style={s.labelSec} htmlFor="razao_social">Razão Social *</label>
                  <input id="razao_social" style={s.input} type="text" placeholder="Ex: Incorporadora XPTO Ltda."
                    value={razaoSocial} onChange={(e) => setRazaoSocial(e.target.value)} />
                </div>
                <div>
                  <label style={s.labelSec} htmlFor="cnpj">CNPJ *</label>
                  <input id="cnpj" style={s.input} type="text" inputMode="numeric"
                    placeholder="XX.XXX.XXX/XXXX-XX" value={cnpj}
                    onChange={(e) => setCnpj(mascaraCNPJ(e.target.value))} maxLength={18} />
                </div>
              </div>
            </div>
          )}

          {tipoInteressado === "PF" && (
            <div style={{ ...s.subsecao, marginTop: "14px" }}>
              <div style={s.linhaDupla}>
                <div>
                  <label style={s.labelSec} htmlFor="nome_pf">Nome *</label>
                  <input id="nome_pf" style={s.input} type="text" placeholder="Ex: João da Silva"
                    value={razaoSocial} onChange={(e) => setRazaoSocial(e.target.value)} />
                </div>
                <div>
                  <label style={s.labelSec} htmlFor="cpf">CPF *</label>
                  <input id="cpf" style={s.input} type="text" inputMode="numeric"
                    placeholder="XXX.XXX.XXX-XX" value={cpf}
                    onChange={(e) => setCpf(mascaraCPF(e.target.value))} maxLength={14} />
                </div>
              </div>
            </div>
          )}
        </div>

        <div style={s.secao}>
          <label style={s.label} htmlFor="uso_aca">Uso (ACA)</label>
          <select
            id="uso_aca"
            style={{ ...s.select, maxWidth: "240px" }}
            value={usoAca}
            onChange={(e) => {
              setUsoAca(e.target.value as "R" | "NR" | "MISTO" | "");
              if (e.target.value !== "MISTO") { setAcaRm2(""); setAcaNrm2(""); }
            }}
          >
            <option value="">Selecione…</option>
            <option value="R">R — Residencial</option>
            <option value="NR">NR — Não-Residencial</option>
            <option value="MISTO">MISTO</option>
          </select>

          {usoAca === "MISTO" && (
            <div style={{ ...s.subsecao, marginTop: "14px" }}>
              <div style={s.linhaDupla}>
                <div>
                  <label style={s.labelSec} htmlFor="aca_r_m2">Área R (m²) *</label>
                  <input id="aca_r_m2" style={s.input} type="number" step="0.01" min="0"
                    placeholder="0.00" value={acaRm2} onChange={(e) => setAcaRm2(e.target.value)} />
                </div>
                <div>
                  <label style={s.labelSec} htmlFor="aca_nr_m2">Área NR (m²) *</label>
                  <input id="aca_nr_m2" style={s.input} type="number" step="0.01" min="0"
                    placeholder="0.00" value={acaNrm2} onChange={(e) => setAcaNrm2(e.target.value)} />
                </div>
              </div>
            </div>
          )}
        </div>
      </>
    );
  }

  function renderEtapa3() {
    return (
      <>
        <h2 style={{ fontSize: "18px", fontWeight: 700, color: "#003087", marginBottom: "20px" }}>
          CEPACs
        </h2>

        <div style={s.secao}>
          <label style={s.label} htmlFor="tipo_contrapartida">Tipo de Contrapartida</label>
          <input
            id="tipo_contrapartida"
            style={{ ...s.input, ...s.inputDis, maxWidth: "240px" }}
            type="text"
            value={tipoContrapartida}
            readOnly
            disabled
            aria-readonly="true"
          />
          <p style={s.hint}>Preenchido automaticamente.</p>
        </div>

        <div style={s.secao}>
          <p style={{ ...s.label, marginBottom: "10px" }}>Quantidades</p>
          <div style={s.linhaDupla}>
            <div>
              <label style={s.labelSec} htmlFor="cepac_aca">CEPAC ACA</label>
              <input id="cepac_aca" style={{ ...s.input, maxWidth: "180px" }}
                type="number" min="0" step="1" placeholder="0"
                value={cepacAca} onChange={(e) => setCepacAca(e.target.value)} />
            </div>
            <div>
              <label style={s.labelSec} htmlFor="cepac_parametros">CEPAC Parâmetros</label>
              <input id="cepac_parametros" style={{ ...s.input, maxWidth: "180px" }}
                type="number" min="0" step="1" placeholder="0"
                value={cepacParametros} onChange={(e) => setCepacParametros(e.target.value)} />
            </div>
          </div>
        </div>

        <div style={s.secao}>
          <label style={s.label}>Títulos disponíveis *</label>
          <p style={{ ...s.hint, marginBottom: "8px" }}>
            Filtro: {setor} / {uso} / {origem}
          </p>
          {carregandoTitulos ? (
            <p style={{ color: "#666", fontStyle: "italic", fontSize: "13px" }}>Carregando títulos…</p>
          ) : titulos.length === 0 ? (
            <p style={{ color: "#888", fontSize: "13px", padding: "8px" }}>
              Nenhum título disponível para os critérios selecionados.
            </p>
          ) : (
            <>
              <p style={s.hint}>{titulos.length} título(s) disponível(is) — selecione um ou mais:</p>
              <div style={s.listaTitulos} role="group" aria-label="Títulos CEPAC disponíveis">
                {titulos.map((t) => (
                  <div key={t.id} style={s.itemTitulo}>
                    <input
                      type="checkbox"
                      id={`titulo-${t.id}`}
                      checked={titulosSelecionados.has(t.id)}
                      onChange={() => toggleTitulo(t.id)}
                    />
                    <label htmlFor={`titulo-${t.id}`} style={s.checkboxLabel}>
                      <strong>{t.codigo}</strong> — {t.setor} / {t.uso} / {t.origem} — R$ {Number(t.valor_m2).toLocaleString("pt-BR", { minimumFractionDigits: 2 })}/m²
                    </label>
                  </div>
                ))}
              </div>
              <p style={s.hint}>{titulosSelecionados.size} selecionado(s)</p>
            </>
          )}
        </div>
      </>
    );
  }

  function renderEtapa4() {
    return (
      <>
        <h2 style={{ fontSize: "18px", fontWeight: 700, color: "#003087", marginBottom: "20px" }}>
          Documentação
        </h2>

        <div style={s.secao}>
          <label style={s.label} htmlFor="sei">Número do Processo SEI *</label>
          <input
            id="sei"
            style={{ ...s.input, ...(seiInvalido ? s.inputErr : {}) }}
            placeholder="Ex: 7810.2024/0001234-5 ou 2005-0.060.565-0"
            value={sei}
            onChange={(e) => setSei(e.target.value)}
            onBlur={() => setSeiTocado(true)}
            aria-invalid={seiInvalido}
            aria-describedby={seiInvalido ? "sei-erro" : undefined}
            required
          />
          {seiInvalido && (
            <p id="sei-erro" style={{ color: "#cc0000", fontSize: "12px", marginTop: "4px" }} role="alert">
              Formato inválido. Use SEI (ex: 7810.2024/0001234-5) ou SIMPROC (ex: 2005-0.060.565-0).
            </p>
          )}
          {!seiInvalido && seiTocado && sei && (
            <p style={{ ...s.hint, color: "#007700" }}>Formato válido.</p>
          )}
        </div>

        <div style={s.secao}>
          <label style={s.label} htmlFor="proposta">Código da Proposta (opcional)</label>
          <input
            id="proposta"
            style={{ ...s.input, maxWidth: "240px" }}
            placeholder="Ex: AE-0183"
            value={proposta}
            onChange={(e) => setProposta(e.target.value)}
          />
        </div>

        <div style={s.secao}>
          <label style={s.label} htmlFor="obs">Observação (opcional)</label>
          <textarea
            id="obs"
            style={s.textarea}
            placeholder="Observação livre do técnico (máx. 1000 caracteres)"
            maxLength={1000}
            value={observacao}
            onChange={(e) => setObservacao(e.target.value)}
          />
          <p style={s.hint}>{observacao.length}/1000 caracteres</p>
        </div>

        {sei && validarSEI(sei) && (
          <div style={s.secao}>
            <UploadDocumento
              numeroProcessoSei={sei}
              propostaId={proposta || undefined}
              disabled={enviando}
            />
          </div>
        )}

        {erroEnvio && (
          <p role="alert" style={s.errBox}>{erroEnvio}</p>
        )}
      </>
    );
  }

  // ---------------------------------------------------------------------------
  // Render principal
  // ---------------------------------------------------------------------------
  return (
    <div style={{ fontFamily: "system-ui, -apple-system, sans-serif", minHeight: "100vh", background: "#f5f7fa" }}>

      {/* Cabeçalho */}
      <div style={{ background: "linear-gradient(90deg, #0B2A4A 0%, #0F3A6D 55%, #145DA0 85%, #1C6ED5 100%)" }}>
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "0 28px", height: 88 }}>
          <div style={{ display: "flex", flexDirection: "row", alignItems: "center", gap: 16 }}>
            <img src="/imagens/logobranco.svg" alt="ZENITE" style={{ height: 82, width: "auto", display: "block" }} />
            <div style={{ width: 1, height: 40, background: "rgba(255,255,255,0.25)", flexShrink: 0 }} />
            <span style={{ fontSize: 15, color: "rgba(255,255,255,0.9)", fontWeight: 700, letterSpacing: "0.03em", whiteSpace: "nowrap" }}>
              Nova Proposta de CEPAC
            </span>
          </div>
          <button
            style={{
              background: hoveredVoltar ? "rgba(255,255,255,0.12)" : "transparent",
              border: "1px solid rgba(255,255,255,0.3)",
              color: "#fff", borderRadius: 5, cursor: "pointer",
              fontSize: 15, fontWeight: 600, padding: "7px 16px", transition: "background 0.15s",
            }}
            onMouseEnter={() => setHoveredVoltar(true)}
            onMouseLeave={() => setHoveredVoltar(false)}
            onClick={() => navigate("/propostas")}
          >
            ← Voltar
          </button>
        </div>
      </div>

      {/* Indicador de etapas */}
      <StepIndicator atual={etapa} />

      {/* Conteúdo da etapa */}
      <div style={{ maxWidth: "760px", margin: "0 auto", padding: "32px 16px" }}>
        <div style={{
          background: "#fff",
          borderRadius: "10px",
          boxShadow: "0 2px 12px rgba(0,0,0,0.08)",
          padding: "32px",
        }}>

          {erroEtapa && (
            <p role="alert" style={s.errBox}>{erroEtapa}</p>
          )}

          {etapa === 1 && renderEtapa1()}
          {etapa === 2 && renderEtapa2()}
          {etapa === 3 && renderEtapa3()}
          {etapa === 4 && renderEtapa4()}

          {/* Navegação */}
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginTop: "32px", paddingTop: "20px", borderTop: "1px solid #eee" }}>
            <button
              type="button"
              onClick={voltar}
              disabled={etapa === 1}
              style={{
                padding: "10px 24px",
                background: etapa === 1 ? "#f0f0f0" : "#fff",
                color: etapa === 1 ? "#aaa" : "#333",
                border: "1px solid #ccc",
                borderRadius: "5px",
                cursor: etapa === 1 ? "not-allowed" : "pointer",
                fontSize: "14px",
                fontWeight: 500,
              }}
            >
              ← Anterior
            </button>

            <span style={{ fontSize: "13px", color: "#888" }}>
              Etapa {etapa} de {STEPS.length}
            </span>

            {etapa < 4 ? (
              <button
                type="button"
                onClick={avancar}
                style={{
                  padding: "10px 28px",
                  background: "#003087",
                  color: "#fff",
                  border: "none",
                  borderRadius: "5px",
                  cursor: "pointer",
                  fontSize: "14px",
                  fontWeight: 600,
                }}
              >
                Próxima →
              </button>
            ) : (
              <button
                type="button"
                onClick={handleEnviar}
                disabled={enviando}
                style={{
                  padding: "10px 28px",
                  background: enviando ? "#7a97c7" : "#003087",
                  color: "#fff",
                  border: "none",
                  borderRadius: "5px",
                  cursor: enviando ? "not-allowed" : "pointer",
                  fontSize: "14px",
                  fontWeight: 700,
                }}
              >
                {enviando ? "Enviando…" : "Enviar Proposta"}
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
