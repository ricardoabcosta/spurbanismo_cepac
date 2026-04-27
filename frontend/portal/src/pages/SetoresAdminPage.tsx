/**
 * Página /admin/setores — CRUD de setores da OUCAE.
 * Leitura: TECNICO ou DIRETOR. Criação/edição: DIRETOR.
 */
import { useState, useEffect, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import { listarSetores, criarSetor, atualizarSetor, lerConfiguracao, atualizarConfiguracao } from "../api/admin";
import type { SetorOut, SetorIn, ConfiguracaoOperacao } from "../types/api";

const estilos: Record<string, React.CSSProperties> = {
  pagina: { fontFamily: "system-ui, sans-serif", minHeight: "100vh", background: "#f5f7fa" },
  conteudo: { maxWidth: "1040px", margin: "0 auto", padding: "28px 16px" },
  cabecalho: { display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px" },
  titulo: { fontSize: "22px", fontWeight: 700, color: "#003087", margin: 0 },
  botaoPrimario: { padding: "9px 18px", background: "#ffd166", color: "#003087", border: "none", borderRadius: "5px", cursor: "pointer", fontSize: "14px", fontWeight: 700, boxShadow: "0 2px 6px rgba(0,0,0,0.25)" },
  botaoSecundario: { padding: "7px 14px", background: "rgba(255,255,255,0.88)", color: "#003087", border: "none", borderRadius: "4px", cursor: "pointer", fontSize: "13px", fontWeight: 600, boxShadow: "0 2px 6px rgba(0,0,0,0.2)" },
  botaoEditar: { padding: "5px 12px", background: "#005cbf", color: "#fff", border: "none", borderRadius: "4px", cursor: "pointer", fontSize: "12px" },
  tabela: { width: "100%", borderCollapse: "collapse" as const, fontSize: "13px" },
  th: { textAlign: "left" as const, padding: "10px 12px", background: "#003087", color: "#fff", fontWeight: 600 },
  td: { padding: "9px 12px", borderBottom: "1px solid #e8e8e8", verticalAlign: "top" as const },
  tdInativo: { padding: "9px 12px", borderBottom: "1px solid #e8e8e8", verticalAlign: "top" as const, color: "#aaa" },
  erro: { color: "#cc0000", background: "#fff0f0", padding: "12px", borderRadius: "4px", marginBottom: "16px" },
  badge: { display: "inline-block", padding: "2px 8px", borderRadius: "10px", fontSize: "11px", fontWeight: 600 },
  badgeSim: { background: "#e6f4ea", color: "#1a7a2e" },
  badgeNao: { background: "#f5f5f5", color: "#888" },
  badgeBloq: { background: "#fdecea", color: "#c62828" },
  overlay: { position: "fixed" as const, inset: 0, background: "rgba(0,0,0,0.4)", display: "flex", alignItems: "center", justifyContent: "center", zIndex: 1000 },
  modal: { background: "#fff", borderRadius: "8px", padding: "28px", width: "540px", maxWidth: "90vw", maxHeight: "90vh", overflowY: "auto" as const },
  modalTitulo: { fontSize: "18px", fontWeight: 700, color: "#003087", marginBottom: "20px" },
  grupo: { marginBottom: "16px" },
  label: { display: "block", fontSize: "13px", fontWeight: 500, marginBottom: "5px" },
  input: { padding: "8px 10px", border: "1px solid #ccc", borderRadius: "4px", fontSize: "13px", width: "100%", boxSizing: "border-box" as const },
  hint: { fontSize: "11px", color: "#666", marginTop: "3px" },
  checkboxLinha: { display: "flex", alignItems: "center", gap: "8px", fontSize: "13px", cursor: "pointer" },
  botoes: { display: "flex", gap: "10px", marginTop: "20px", justifyContent: "flex-end" },
  carregando: { color: "#666", fontStyle: "italic" },
};

const SETOR_VAZIO: SetorIn = {
  nome: "",
  estoque_total_m2: 0,
  teto_nr_m2: 0,
  reserva_r_m2: null,
  piso_r_percentual: null,
  bloqueio_nr: false,
  ativo: true,
  cepacs_convertidos_aca: 0,
  cepacs_convertidos_parametros: 0,
  cepacs_desvinculados_aca: 0,
  cepacs_desvinculados_parametros: 0,
};

function numOuNull(v: string): number | null {
  const n = parseFloat(v.replace(",", "."));
  return isNaN(n) || v.trim() === "" ? null : n;
}

function fmt(v: string | null | undefined): string {
  if (v == null) return "—";
  return Number(v).toLocaleString("pt-BR", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

/** Input m² com formatação brasileira ao sair do campo. Estado interno sempre usa ponto como separador decimal. */
function CampoM2({ id, value, onChange, placeholder, required, readOnly, extraStyle }: {
  id: string;
  value: string;
  onChange?: (v: string) => void;
  placeholder?: string;
  required?: boolean;
  readOnly?: boolean;
  extraStyle?: React.CSSProperties;
}) {
  const [focused, setFocused] = useState(false);

  const display = !focused && value !== "" && !isNaN(Number(value))
    ? Number(value).toLocaleString("pt-BR", { minimumFractionDigits: 2, maximumFractionDigits: 2 })
    : value;

  return (
    <input
      id={id}
      style={{ ...estilos.input, ...(readOnly ? { background: "#f5f7fa", color: "#555", cursor: "not-allowed" } : {}), ...extraStyle }}
      type="text"
      inputMode="decimal"
      value={display}
      readOnly={readOnly}
      required={required}
      placeholder={placeholder}
      onChange={(e) => onChange?.(e.target.value.replace(/\./g, "").replace(",", "."))}
      onFocus={() => setFocused(true)}
      onBlur={() => setFocused(false)}
    />
  );
}

interface FormState {
  nome: string;
  estoque_total_m2: string;
  teto_nr_m2: string;
  reserva_r_m2: string;
  piso_r_percentual: string;
  bloqueio_nr: boolean;
  ativo: boolean;
  cepacs_convertidos_aca: string;
  cepacs_convertidos_parametros: string;
  cepacs_desvinculados_aca: string;
  cepacs_desvinculados_parametros: string;
}

function setorParaForm(s: SetorOut): FormState {
  return {
    nome: s.nome,
    estoque_total_m2: s.estoque_total_m2,
    teto_nr_m2: s.teto_nr_m2,
    reserva_r_m2: s.reserva_r_m2 ?? "",
    piso_r_percentual: s.piso_r_percentual ?? "",
    bloqueio_nr: s.bloqueio_nr,
    ativo: s.ativo,
    cepacs_convertidos_aca: String(s.cepacs_convertidos_aca ?? 0),
    cepacs_convertidos_parametros: String(s.cepacs_convertidos_parametros ?? 0),
    cepacs_desvinculados_aca: String(s.cepacs_desvinculados_aca ?? 0),
    cepacs_desvinculados_parametros: String(s.cepacs_desvinculados_parametros ?? 0),
  };
}

function formParaPayload(f: FormState): SetorIn {
  return {
    nome: f.nome.trim(),
    estoque_total_m2: parseFloat(f.estoque_total_m2) || 0,
    teto_nr_m2: parseFloat(f.teto_nr_m2) || 0,
    reserva_r_m2: numOuNull(f.reserva_r_m2),
    piso_r_percentual: numOuNull(f.piso_r_percentual),
    bloqueio_nr: f.bloqueio_nr,
    ativo: f.ativo,
    cepacs_convertidos_aca: parseInt(f.cepacs_convertidos_aca) || 0,
    cepacs_convertidos_parametros: parseInt(f.cepacs_convertidos_parametros) || 0,
    cepacs_desvinculados_aca: parseInt(f.cepacs_desvinculados_aca) || 0,
    cepacs_desvinculados_parametros: parseInt(f.cepacs_desvinculados_parametros) || 0,
  };
}

export default function SetoresAdminPage() {
  const navigate = useNavigate();
  const [setores, setSetores] = useState<SetorOut[]>([]);
  const [carregando, setCarregando] = useState(true);
  const [erroGeral, setErroGeral] = useState("");

  // Configuração global
  const [config, setConfig] = useState<ConfiguracaoOperacao | null>(null);
  const [reservaInput, setReservaInput] = useState("");
  const [cepacsTotais, setCepacsTotais] = useState("0");
  const [cepacsLeiloados, setCepacsLeiloados] = useState("0");
  const [cepacsColocacao, setCepacsColocacao] = useState("0");
  const [salvandoConfig, setSalvandoConfig] = useState(false);
  const [erroConfig, setErroConfig] = useState("");
  const [sucessoConfig, setSucessoConfig] = useState(false);

  const [modalAberto, setModalAberto] = useState(false);
  const [editando, setEditando] = useState<SetorOut | null>(null);
  const [form, setForm] = useState<FormState>({ ...SETOR_VAZIO, estoque_total_m2: "", teto_nr_m2: "", reserva_r_m2: "", piso_r_percentual: "", cepacs_convertidos_aca: "0", cepacs_convertidos_parametros: "0", cepacs_desvinculados_aca: "0", cepacs_desvinculados_parametros: "0" });
  const [salvando, setSalvando] = useState(false);
  const [erroModal, setErroModal] = useState("");

  const carregar = useCallback(async () => {
    setCarregando(true);
    setErroGeral("");
    try {
      const [setoresData, configData] = await Promise.all([listarSetores(), lerConfiguracao()]);
      setSetores(setoresData);
      setConfig(configData);
      setReservaInput(configData.reserva_tecnica_m2);
      setCepacsTotais(String(configData.cepacs_totais ?? 0));
      setCepacsLeiloados(String(configData.cepacs_leiloados ?? 0));
      setCepacsColocacao(String(configData.cepacs_colocacao_privada ?? 0));
    } catch {
      setErroGeral("Erro ao carregar dados. Verifique a conexão com a API.");
    } finally {
      setCarregando(false);
    }
  }, []);

  async function handleSalvarConfig(e: React.FormEvent) {
    e.preventDefault();
    setErroConfig("");
    setSucessoConfig(false);
    const valor = parseFloat(reservaInput.replace(/\./g, "").replace(",", "."));
    if (isNaN(valor) || valor < 0) { setErroConfig("Informe um valor em m² maior ou igual a zero."); return; }
    setSalvandoConfig(true);
    try {
      const novo = await atualizarConfiguracao({
        reserva_tecnica_m2: valor,
        cepacs_totais: parseInt(cepacsTotais) || 0,
        cepacs_leiloados: parseInt(cepacsLeiloados) || 0,
        cepacs_colocacao_privada: parseInt(cepacsColocacao) || 0,
      });
      setConfig(novo);
      setReservaInput(novo.reserva_tecnica_m2);
      setCepacsTotais(String(novo.cepacs_totais ?? 0));
      setCepacsLeiloados(String(novo.cepacs_leiloados ?? 0));
      setCepacsColocacao(String(novo.cepacs_colocacao_privada ?? 0));
      setSucessoConfig(true);
      setTimeout(() => setSucessoConfig(false), 3000);
    } catch {
      setErroConfig("Erro ao salvar. Tente novamente.");
    } finally {
      setSalvandoConfig(false);
    }
  }

  useEffect(() => { void carregar(); }, [carregar]);

  function abrirNovo() {
    setEditando(null);
    setForm({ nome: "", estoque_total_m2: "", teto_nr_m2: "", reserva_r_m2: "", piso_r_percentual: "", bloqueio_nr: false, ativo: true, cepacs_convertidos_aca: "0", cepacs_convertidos_parametros: "0", cepacs_desvinculados_aca: "0", cepacs_desvinculados_parametros: "0" });
    setErroModal("");
    setModalAberto(true);
  }

  function abrirEdicao(s: SetorOut) {
    setEditando(s);
    setForm(setorParaForm(s));
    setErroModal("");
    setModalAberto(true);
  }

  function fecharModal() {
    setModalAberto(false);
    setEditando(null);
    setErroModal("");
  }

  function campo(field: keyof FormState, value: string | boolean) {
    setForm((prev) => ({ ...prev, [field]: value }));
  }

  async function handleSalvar(e: React.FormEvent) {
    e.preventDefault();
    setErroModal("");

    const payload = formParaPayload(form);

    if (!payload.nome) { setErroModal("Nome é obrigatório."); return; }
    if (payload.estoque_total_m2 <= 0) { setErroModal("Estoque total deve ser maior que zero."); return; }
    if (payload.teto_nr_m2 <= 0) { setErroModal("Teto NR deve ser maior que zero."); return; }
    if (payload.teto_nr_m2 > payload.estoque_total_m2) { setErroModal("Teto NR não pode exceder o Estoque Total."); return; }
    if (payload.reserva_r_m2 != null && payload.reserva_r_m2 <= 0) { setErroModal("Reserva R deve ser maior que zero (ou deixe em branco)."); return; }
    if (payload.piso_r_percentual != null && (payload.piso_r_percentual < 0 || payload.piso_r_percentual > 100)) { setErroModal("Piso R (%) deve ser entre 0 e 100."); return; }

    setSalvando(true);
    try {
      if (editando) {
        await atualizarSetor(editando.id, payload);
      } else {
        await criarSetor(payload);
      }
      fecharModal();
      await carregar();
    } catch (err: unknown) {
      const axiosErr = err as { response?: { data?: { detail?: string } } };
      setErroModal(axiosErr?.response?.data?.detail ?? "Erro ao salvar. Verifique os dados.");
    } finally {
      setSalvando(false);
    }
  }

  const [hoveredVoltar, setHoveredVoltar] = useState(false);
  const [hoveredNovo, setHoveredNovo] = useState(false);

  return (
    <div style={estilos.pagina}>
      {/* Cabeçalho */}
      <div style={{ background: "linear-gradient(90deg, #0B2A4A 0%, #0F3A6D 55%, #145DA0 85%, #1C6ED5 100%)" }}>
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "0 28px", height: 88 }}>
          <div style={{ display: "flex", flexDirection: "row", alignItems: "center", gap: 16 }}>
            <img src="/imagens/logobranco.svg" alt="ZENITE" style={{ height: 82, width: "auto", display: "block" }} />
            <div style={{ width: 1, height: 40, background: "rgba(255,255,255,0.25)", flexShrink: 0 }} />
            <span style={{ fontSize: 15, color: "rgba(255,255,255,0.9)", fontWeight: 700, letterSpacing: "0.03em", whiteSpace: "nowrap" }}>
              Administração de Setores
            </span>
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
            <button
              style={{ background: hoveredVoltar ? "rgba(255,255,255,0.12)" : "transparent", border: "1px solid rgba(255,255,255,0.3)", color: "#fff", borderRadius: 5, cursor: "pointer", fontSize: 15, fontWeight: 600, padding: "7px 16px", transition: "background 0.15s" }}
              onMouseEnter={() => setHoveredVoltar(true)}
              onMouseLeave={() => setHoveredVoltar(false)}
              onClick={() => navigate("/propostas")}
            >
              ← Voltar
            </button>
            <button
              style={{ background: hoveredNovo ? "#ffe080" : "#ffd166", color: "#003087", border: "none", borderRadius: 5, cursor: "pointer", fontSize: 15, fontWeight: 700, padding: "8px 18px", boxShadow: "0 2px 6px rgba(0,0,0,0.25)", transition: "background 0.15s" }}
              onMouseEnter={() => setHoveredNovo(true)}
              onMouseLeave={() => setHoveredNovo(false)}
              onClick={abrirNovo}
            >
              + Novo Setor
            </button>
          </div>
        </div>
      </div>

      <div style={estilos.conteudo}>
      {erroGeral && <p role="alert" style={estilos.erro}>{erroGeral}</p>}

      {/* Card Configuração da Operação */}
      <div style={{ background: "#fff", borderRadius: "8px", boxShadow: "0 2px 12px rgba(0,0,0,0.07)", padding: "20px 24px", marginBottom: "20px" }}>
        <h2 style={{ margin: "0 0 4px", fontSize: "15px", fontWeight: 700, color: "#003087" }}>
          Reserva Técnica da Operação
        </h2>
        <p style={{ margin: "0 0 16px", fontSize: "12px", color: "#666" }}>
          Área (m²) reservada para uso técnico da Prefeitura. Somada ao estoque setorial para compor a
          <strong> Capacidade Total da Operação</strong> exibida no Dashboard.
        </p>
        {erroConfig && <p role="alert" style={{ ...estilos.erro, marginBottom: "12px" }}>{erroConfig}</p>}
        {sucessoConfig && (
          <p style={{ background: "#e6f4ea", color: "#1a7a2e", padding: "8px 12px", borderRadius: "4px", fontSize: "13px", marginBottom: "12px" }}>
            Configuração salva com sucesso.
          </p>
        )}
        <form onSubmit={handleSalvarConfig} noValidate>
          <div style={{ display: "flex", alignItems: "flex-end", gap: "12px", flexWrap: "wrap", marginBottom: "24px" }}>
            <div>
              <label style={{ ...estilos.label, marginBottom: "5px" }} htmlFor="reserva_tecnica">
                Reserva Técnica (m²)
              </label>
              <CampoM2
                id="reserva_tecnica"
                value={reservaInput}
                onChange={setReservaInput}
                placeholder="ex: 50.000,00"
                extraStyle={{ width: "220px" }}
              />
            </div>
            {config && (
              <p style={{ fontSize: "11px", color: "#888", marginBottom: "0", alignSelf: "flex-end", paddingBottom: "2px" }}>
                Atual: {Number(config.reserva_tecnica_m2).toLocaleString("pt-BR", { minimumFractionDigits: 2 })} m²
                &nbsp;·&nbsp;
                atualizado em {new Date(config.updated_at).toLocaleString("pt-BR")}
              </p>
            )}
          </div>

          {/* Parâmetros Globais de CEPAC */}
          <div style={{ borderTop: "1px solid #e8ecf0", paddingTop: "16px", marginBottom: "16px" }}>
            <p style={{ margin: "0 0 14px", fontSize: "12px", fontWeight: 700, color: "#003087", textTransform: "uppercase", letterSpacing: "0.4px" }}>
              Parâmetros Globais de CEPAC
            </p>
            <div style={{ display: "flex", gap: "14px", flexWrap: "wrap" }}>
              <div style={estilos.grupo}>
                <label style={estilos.label} htmlFor="cepacs_totais">CEPACs Totais</label>
                <input id="cepacs_totais" style={{ ...estilos.input, width: "160px" }} type="number" min="0" step="1"
                  value={cepacsTotais} onChange={(e) => setCepacsTotais(e.target.value)} />
              </div>
              <div style={estilos.grupo}>
                <label style={estilos.label} htmlFor="cepacs_leiloados">CEPACs Leiloados</label>
                <input id="cepacs_leiloados" style={{ ...estilos.input, width: "160px" }} type="number" min="0" step="1"
                  value={cepacsLeiloados} onChange={(e) => setCepacsLeiloados(e.target.value)} />
              </div>
              <div style={estilos.grupo}>
                <label style={estilos.label} htmlFor="cepacs_colocacao">CEPACs Colocação Privada</label>
                <input id="cepacs_colocacao" style={{ ...estilos.input, width: "160px" }} type="number" min="0" step="1"
                  value={cepacsColocacao} onChange={(e) => setCepacsColocacao(e.target.value)} />
              </div>
            </div>
          </div>

          <button type="submit" style={estilos.botaoPrimario} disabled={salvandoConfig}>
            {salvandoConfig ? "Salvando…" : "Salvar"}
          </button>
        </form>
      </div>

      {/* Tabela de Setores */}
      <div style={{ background: "#fff", borderRadius: "8px", boxShadow: "0 2px 12px rgba(0,0,0,0.07)", overflow: "hidden" }}>
      {carregando ? (
        <p style={{ ...estilos.carregando, padding: "24px" }}>Carregando setores…</p>
      ) : (
        <table style={estilos.tabela}>
          <thead>
            <tr>
              <th style={estilos.th}>Nome</th>
              <th style={estilos.th}>Estoque Total (m²)</th>
              <th style={estilos.th}>Teto NR (m²)</th>
              <th style={estilos.th}>Piso R</th>
              <th style={estilos.th}>Reserva R (m²)</th>
              <th style={estilos.th}>Bloqueio NR</th>
              <th style={estilos.th}>Ativo</th>
              <th style={estilos.th}></th>
            </tr>
          </thead>
          <tbody>
            {setores.map((s) => {
              const tdStyle = s.ativo ? estilos.td : estilos.tdInativo;
              return (
                <tr key={s.id}>
                  <td style={tdStyle}><strong>{s.nome}</strong></td>
                  <td style={tdStyle}>{fmt(s.estoque_total_m2)}</td>
                  <td style={tdStyle}>{fmt(s.teto_nr_m2)}</td>
                  <td style={tdStyle}>
                    {s.piso_r_percentual ? (
                      <>
                        <span style={{ fontWeight: 600 }}>{fmt(s.piso_r_percentual)}%</span>
                        <br />
                        <span style={{ fontSize: "11px", color: "#666" }}>
                          {fmt(String((parseFloat(s.piso_r_percentual) / 100) * parseFloat(s.estoque_total_m2)))} m²
                        </span>
                      </>
                    ) : "—"}
                  </td>
                  <td style={tdStyle}>{s.reserva_r_m2 ? fmt(s.reserva_r_m2) : "—"}</td>
                  <td style={tdStyle}>
                    <span style={{ ...estilos.badge, ...(s.bloqueio_nr ? estilos.badgeBloq : estilos.badgeNao) }}>
                      {s.bloqueio_nr ? "SIM" : "Não"}
                    </span>
                  </td>
                  <td style={tdStyle}>
                    <span style={{ ...estilos.badge, ...(s.ativo ? estilos.badgeSim : estilos.badgeNao) }}>
                      {s.ativo ? "Ativo" : "Inativo"}
                    </span>
                  </td>
                  <td style={tdStyle}>
                    <button style={estilos.botaoEditar} onClick={() => abrirEdicao(s)}>Editar</button>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      )}
      </div>{/* card branco */}
      </div>{/* conteudo */}

      {modalAberto && (
        <div style={estilos.overlay} onClick={(e) => { if (e.target === e.currentTarget) fecharModal(); }}>
          <div style={estilos.modal}>
            <h2 style={estilos.modalTitulo}>{editando ? "Editar Setor" : "Novo Setor"}</h2>

            {erroModal && <p role="alert" style={estilos.erro}>{erroModal}</p>}

            <form onSubmit={handleSalvar} noValidate>
              <div style={estilos.grupo}>
                <label style={estilos.label} htmlFor="nome">Nome *</label>
                <input id="nome" style={estilos.input} value={form.nome} onChange={(e) => campo("nome", e.target.value)} required />
              </div>

              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "14px" }}>
                <div style={estilos.grupo}>
                  <label style={estilos.label} htmlFor="estoque">Estoque Total (m²) *</label>
                  <CampoM2 id="estoque" value={form.estoque_total_m2} onChange={(v) => campo("estoque_total_m2", v)} required placeholder="ex: 1.200.000,00" />
                </div>
                <div style={estilos.grupo}>
                  <label style={estilos.label} htmlFor="teto_nr">Teto NR (m²) *</label>
                  <CampoM2 id="teto_nr" value={form.teto_nr_m2} onChange={(v) => campo("teto_nr_m2", v)} required placeholder="ex: 900.000,00" />
                </div>
                <div style={estilos.grupo}>
                  <label style={estilos.label} htmlFor="reserva_r">Reserva R (m²)</label>
                  <CampoM2 id="reserva_r" value={form.reserva_r_m2} onChange={(v) => campo("reserva_r_m2", v)} placeholder="ex: 216.442,47" />
                  <p style={estilos.hint}>Apenas Chucri Zaidan possui reserva R fixa.</p>
                </div>
              </div>

              {/* Par vinculado Piso R */}
              <div style={{ border: "1px solid #e0e4ea", borderRadius: "6px", padding: "14px 16px", marginBottom: "16px" }}>
                <p style={{ margin: "0 0 12px", fontSize: "12px", fontWeight: 600, color: "#555", textTransform: "uppercase", letterSpacing: "0.4px" }}>
                  Piso R — percentual mínimo de área residencial
                </p>
                <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "14px" }}>
                  <div style={estilos.grupo}>
                    <label style={estilos.label} htmlFor="piso_r_pct">Piso R (%)</label>
                    <input id="piso_r_pct" style={estilos.input} type="number" step="0.01" min="0" max="100"
                      value={form.piso_r_percentual} onChange={(e) => campo("piso_r_percentual", e.target.value)}
                      placeholder="ex: 30" />
                    <p style={estilos.hint}>% mínimo de R no consumo total do setor.</p>
                  </div>
                  <div style={estilos.grupo}>
                    <label style={estilos.label} htmlFor="piso_r_m2">Piso R (m²)</label>
                    <CampoM2
                      id="piso_r_m2"
                      readOnly
                      value={(() => {
                        const pct = parseFloat(form.piso_r_percentual);
                        const est = parseFloat(form.estoque_total_m2);
                        if (isNaN(pct) || isNaN(est) || pct <= 0 || est <= 0) return "";
                        return String((pct / 100) * est);
                      })()}
                      placeholder="Calculado automaticamente"
                    />
                    <p style={estilos.hint}>Derivado: Piso R% × Estoque Total. Somente leitura.</p>
                  </div>
                </div>
              </div>

              <div style={estilos.grupo}>
                <label style={estilos.checkboxLinha}>
                  <input type="checkbox" checked={form.bloqueio_nr} onChange={(e) => campo("bloqueio_nr", e.target.checked)} />
                  Bloquear novas solicitações NR (incondicional)
                </label>
                <p style={estilos.hint}>Marque quando o estoque NR do setor estiver esgotado.</p>
              </div>

              <div style={estilos.grupo}>
                <label style={estilos.checkboxLinha}>
                  <input type="checkbox" checked={form.ativo} onChange={(e) => campo("ativo", e.target.checked)} />
                  Setor ativo
                </label>
              </div>

              {/* CEPACs do setor */}
              <div style={{ border: "1px solid #e0e4ea", borderRadius: "6px", padding: "14px 16px", marginBottom: "16px" }}>
                <p style={{ margin: "0 0 12px", fontSize: "12px", fontWeight: 600, color: "#555", textTransform: "uppercase", letterSpacing: "0.4px" }}>
                  CEPACs do Setor
                </p>
                <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "14px" }}>
                  <div style={estilos.grupo}>
                    <label style={estilos.label} htmlFor="conv_aca">Convertido — ACA</label>
                    <input id="conv_aca" style={estilos.input} type="number" min="0" step="1"
                      value={form.cepacs_convertidos_aca}
                      onChange={(e) => campo("cepacs_convertidos_aca", e.target.value)} />
                  </div>
                  <div style={estilos.grupo}>
                    <label style={estilos.label} htmlFor="conv_param">Convertido — Uso e Parâmetros</label>
                    <input id="conv_param" style={estilos.input} type="number" min="0" step="1"
                      value={form.cepacs_convertidos_parametros}
                      onChange={(e) => campo("cepacs_convertidos_parametros", e.target.value)} />
                  </div>
                  <div style={estilos.grupo}>
                    <label style={estilos.label} htmlFor="desv_aca">Desvinculado — ACA</label>
                    <input id="desv_aca" style={estilos.input} type="number" min="0" step="1"
                      value={form.cepacs_desvinculados_aca}
                      onChange={(e) => campo("cepacs_desvinculados_aca", e.target.value)} />
                  </div>
                  <div style={estilos.grupo}>
                    <label style={estilos.label} htmlFor="desv_param">Desvinculado — Uso e Parâmetros</label>
                    <input id="desv_param" style={estilos.input} type="number" min="0" step="1"
                      value={form.cepacs_desvinculados_parametros}
                      onChange={(e) => campo("cepacs_desvinculados_parametros", e.target.value)} />
                  </div>
                </div>
              </div>

              <div style={estilos.botoes}>
                <button type="button" style={estilos.botaoSecundario} onClick={fecharModal} disabled={salvando}>
                  Cancelar
                </button>
                <button type="submit" style={estilos.botaoPrimario} disabled={salvando}>
                  {salvando ? "Salvando…" : "Salvar"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
