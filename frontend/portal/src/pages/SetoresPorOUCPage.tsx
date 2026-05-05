/**
 * Página /admin/operacoes-urbanas/:oucId/setores — Setores de uma OUC específica.
 * Leitura: TECNICO ou DIRETOR. Criação/edição: DIRETOR.
 */
import { useState, useEffect, useCallback } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { buscarOUC, listarSetoresPorOUC, criarSetor, atualizarSetor } from "../api/admin";
import type { OperacaoUrbanaOut, SetorOut, SetorIn } from "../types/api";

const estilos: Record<string, React.CSSProperties> = {
  pagina: { fontFamily: "system-ui, sans-serif", minHeight: "100vh", background: "#f5f7fa" },
  conteudo: { maxWidth: "1200px", margin: "0 auto", padding: "28px 16px" },
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
  modal: { background: "#fff", borderRadius: "8px", padding: "28px", width: "580px", maxWidth: "90vw", maxHeight: "90vh", overflowY: "auto" as const },
  modalTitulo: { fontSize: "18px", fontWeight: 700, color: "#003087", marginBottom: "20px" },
  grupo: { marginBottom: "16px" },
  label: { display: "block", fontSize: "13px", fontWeight: 500, marginBottom: "5px" },
  input: { padding: "8px 10px", border: "1px solid #ccc", borderRadius: "4px", fontSize: "13px", width: "100%", boxSizing: "border-box" as const },
  hint: { fontSize: "11px", color: "#666", marginTop: "3px" },
  checkboxLinha: { display: "flex", alignItems: "center", gap: "8px", fontSize: "13px", cursor: "pointer" },
  botoes: { display: "flex", gap: "10px", marginTop: "20px", justifyContent: "flex-end" },
  carregando: { color: "#666", fontStyle: "italic" },
};

function numOuNull(v: string): number | null {
  const s = v.replace(/\./g, "").replace(",", ".").trim();
  if (s === "") return null;
  const n = parseFloat(s);
  return isNaN(n) ? null : n;
}

function fmt(v: string | null | undefined): string {
  if (v == null) return "—";
  return Number(v).toLocaleString("pt-BR", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

function fmtF(v: string | null | undefined): string {
  if (v == null) return "—";
  return Number(v).toLocaleString("pt-BR", { minimumFractionDigits: 6, maximumFractionDigits: 6 });
}

/** Input m² com formatação brasileira ao sair do campo. */
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

/** Ordena setores com hierarquia: raízes em ordem alfabética, filhos logo abaixo de cada raiz. */
function ordenarComHierarquia(setores: SetorOut[]): SetorOut[] {
  const raizes = setores
    .filter((s) => s.setor_pai_id == null)
    .sort((a, b) => a.nome.localeCompare(b.nome, "pt-BR"));

  const filhosPor: Record<string, SetorOut[]> = {};
  for (const s of setores) {
    if (s.setor_pai_id != null) {
      if (!filhosPor[s.setor_pai_id]) filhosPor[s.setor_pai_id] = [];
      filhosPor[s.setor_pai_id].push(s);
    }
  }
  for (const key of Object.keys(filhosPor)) {
    filhosPor[key].sort((a, b) => a.nome.localeCompare(b.nome, "pt-BR"));
  }

  const resultado: SetorOut[] = [];
  for (const raiz of raizes) {
    resultado.push(raiz);
    if (filhosPor[raiz.id]) {
      resultado.push(...filhosPor[raiz.id]);
    }
  }
  return resultado;
}

interface FormSetor {
  nome: string;
  estoque_total_m2: string;
  teto_nr_m2: string;
  teto_r_m2: string;
  reserva_r_m2: string;
  piso_r_percentual: string;
  fator_equivalencia_f1: string;
  fator_equivalencia_f2: string;
  setor_pai_id: string;
  bloqueio_nr: boolean;
  ativo: boolean;
  cepacs_convertidos_aca: string;
  cepacs_convertidos_parametros: string;
  cepacs_desvinculados_aca: string;
  cepacs_desvinculados_parametros: string;
}

const FORM_VAZIO: FormSetor = {
  nome: "",
  estoque_total_m2: "",
  teto_nr_m2: "",
  teto_r_m2: "",
  reserva_r_m2: "",
  piso_r_percentual: "",
  fator_equivalencia_f1: "",
  fator_equivalencia_f2: "",
  setor_pai_id: "",
  bloqueio_nr: false,
  ativo: true,
  cepacs_convertidos_aca: "0",
  cepacs_convertidos_parametros: "0",
  cepacs_desvinculados_aca: "0",
  cepacs_desvinculados_parametros: "0",
};

function setorParaForm(s: SetorOut): FormSetor {
  return {
    nome: s.nome,
    estoque_total_m2: s.estoque_total_m2,
    teto_nr_m2: s.teto_nr_m2,
    teto_r_m2: s.teto_r_m2 ?? "",
    reserva_r_m2: s.reserva_r_m2 ?? "",
    piso_r_percentual: s.piso_r_percentual ?? "",
    fator_equivalencia_f1: s.fator_equivalencia_f1 ?? "",
    fator_equivalencia_f2: s.fator_equivalencia_f2 ?? "",
    setor_pai_id: s.setor_pai_id ?? "",
    bloqueio_nr: s.bloqueio_nr,
    ativo: s.ativo,
    cepacs_convertidos_aca: String(s.cepacs_convertidos_aca ?? 0),
    cepacs_convertidos_parametros: String(s.cepacs_convertidos_parametros ?? 0),
    cepacs_desvinculados_aca: String(s.cepacs_desvinculados_aca ?? 0),
    cepacs_desvinculados_parametros: String(s.cepacs_desvinculados_parametros ?? 0),
  };
}

function formParaPayload(f: FormSetor, oucId: number): SetorIn {
  return {
    nome: f.nome.trim(),
    estoque_total_m2: parseFloat(f.estoque_total_m2.replace(/\./g, "").replace(",", ".")) || 0,
    teto_nr_m2: parseFloat(f.teto_nr_m2.replace(/\./g, "").replace(",", ".")) || 0,
    teto_r_m2: numOuNull(f.teto_r_m2),
    reserva_r_m2: numOuNull(f.reserva_r_m2),
    piso_r_percentual: numOuNull(f.piso_r_percentual),
    fator_equivalencia_f1: numOuNull(f.fator_equivalencia_f1),
    fator_equivalencia_f2: numOuNull(f.fator_equivalencia_f2),
    setor_pai_id: f.setor_pai_id || null,
    bloqueio_nr: f.bloqueio_nr,
    ativo: f.ativo,
    operacao_urbana_id: oucId,
    cepacs_convertidos_aca: parseInt(f.cepacs_convertidos_aca) || 0,
    cepacs_convertidos_parametros: parseInt(f.cepacs_convertidos_parametros) || 0,
    cepacs_desvinculados_aca: parseInt(f.cepacs_desvinculados_aca) || 0,
    cepacs_desvinculados_parametros: parseInt(f.cepacs_desvinculados_parametros) || 0,
  };
}

export default function SetoresPorOUCPage() {
  const navigate = useNavigate();
  const { oucId: oucIdStr } = useParams<{ oucId: string }>();
  const oucId = parseInt(oucIdStr ?? "0");

  const [ouc, setOuc] = useState<OperacaoUrbanaOut | null>(null);
  const [setores, setSetores] = useState<SetorOut[]>([]);
  const [carregando, setCarregando] = useState(true);
  const [erroGeral, setErroGeral] = useState("");

  const [modalAberto, setModalAberto] = useState(false);
  const [editando, setEditando] = useState<SetorOut | null>(null);
  const [form, setForm] = useState<FormSetor>({ ...FORM_VAZIO });
  const [salvando, setSalvando] = useState(false);
  const [erroModal, setErroModal] = useState("");

  const [hoveredVoltar, setHoveredVoltar] = useState(false);
  const [hoveredNovo, setHoveredNovo] = useState(false);

  const carregarSetores = useCallback(async () => {
    try {
      const data = await listarSetoresPorOUC(oucId);
      setSetores(data);
    } catch {
      setErroGeral("Erro ao recarregar setores.");
    }
  }, [oucId]);

  const carregar = useCallback(async () => {
    setCarregando(true);
    setErroGeral("");
    try {
      const [oucData, setoresData] = await Promise.all([
        buscarOUC(oucId),
        listarSetoresPorOUC(oucId),
      ]);
      setOuc(oucData);
      setSetores(setoresData);
    } catch {
      setErroGeral("Erro ao carregar dados. Verifique a conexão com a API.");
    } finally {
      setCarregando(false);
    }
  }, [oucId]);

  useEffect(() => { void carregar(); }, [carregar]);

  function abrirNovo() {
    setEditando(null);
    setForm({ ...FORM_VAZIO });
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

  function campo<K extends keyof FormSetor>(field: K, value: FormSetor[K]) {
    setForm((prev) => ({ ...prev, [field]: value }));
  }

  async function handleSalvar(e: React.FormEvent) {
    e.preventDefault();
    setErroModal("");

    if (!form.nome.trim()) { setErroModal("Nome é obrigatório."); return; }

    const payload = formParaPayload(form, oucId);

    if (payload.estoque_total_m2 <= 0) { setErroModal("Estoque total deve ser maior que zero."); return; }
    if (payload.teto_nr_m2 <= 0) { setErroModal("Teto NR deve ser maior que zero."); return; }

    setSalvando(true);
    try {
      if (editando) {
        await atualizarSetor(editando.id, payload);
      } else {
        await criarSetor(payload);
      }
      fecharModal();
      await carregarSetores();
    } catch (err: unknown) {
      const axiosErr = err as { response?: { status?: number; data?: { detail?: string } } };
      if (axiosErr?.response?.status === 409) {
        setErroModal("Setor com este nome já existe.");
      } else if (axiosErr?.response?.status === 422) {
        setErroModal(axiosErr?.response?.data?.detail ?? "Dados inválidos (422).");
      } else {
        setErroModal(axiosErr?.response?.data?.detail ?? "Erro ao salvar. Verifique os dados.");
      }
    } finally {
      setSalvando(false);
    }
  }

  // Raízes disponíveis para o select de setor_pai (excluindo o setor em edição)
  const raizesParaSelect = setores.filter(
    (s) => s.setor_pai_id == null && (!editando || s.id !== editando.id)
  );

  // Lookup nome do setor pelo id
  const nomePorId: Record<string, string> = {};
  for (const s of setores) { nomePorId[s.id] = s.nome; }

  const setoresOrdenados = ordenarComHierarquia(setores);

  return (
    <div style={estilos.pagina}>
      {/* Cabeçalho */}
      <div style={{ background: "linear-gradient(90deg, #0B2A4A 0%, #0F3A6D 55%, #145DA0 85%, #1C6ED5 100%)" }}>
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "0 28px", height: 88 }}>
          <div style={{ display: "flex", flexDirection: "row", alignItems: "center", gap: 16 }}>
            <img src="/imagens/logobranco.svg" alt="ZENITE" style={{ height: 82, width: "auto", display: "block" }} />
            <div style={{ width: 1, height: 40, background: "rgba(255,255,255,0.25)", flexShrink: 0 }} />
            <span style={{ fontSize: 15, color: "rgba(255,255,255,0.9)", fontWeight: 700, letterSpacing: "0.03em", whiteSpace: "nowrap" }}>
              {ouc ? `${ouc.sigla} — ${ouc.nome}` : "Setores da Operação"}
            </span>
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
            <button
              style={{ background: hoveredVoltar ? "rgba(255,255,255,0.12)" : "transparent", border: "1px solid rgba(255,255,255,0.3)", color: "#fff", borderRadius: 5, cursor: "pointer", fontSize: 15, fontWeight: 600, padding: "7px 16px", transition: "background 0.15s" }}
              onMouseEnter={() => setHoveredVoltar(true)}
              onMouseLeave={() => setHoveredVoltar(false)}
              onClick={() => navigate("/admin/operacoes-urbanas")}
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

        <div style={{ background: "#fff", borderRadius: "8px", boxShadow: "0 2px 12px rgba(0,0,0,0.07)", overflow: "hidden" }}>
          {carregando ? (
            <p style={{ ...estilos.carregando, padding: "24px" }}>Carregando setores…</p>
          ) : (
            <table style={estilos.tabela}>
              <thead>
                <tr>
                  <th style={estilos.th}>Nome</th>
                  <th style={estilos.th}>Estoque Total (m²)</th>
                  <th style={estilos.th}>Teto R (m²)</th>
                  <th style={estilos.th}>Teto NR (m²)</th>
                  <th style={estilos.th}>F1</th>
                  <th style={estilos.th}>F2</th>
                  <th style={estilos.th}>Setor Pai</th>
                  <th style={estilos.th}>Bloqueio NR</th>
                  <th style={estilos.th}>Ativo</th>
                  <th style={estilos.th}></th>
                </tr>
              </thead>
              <tbody>
                {setoresOrdenados.map((s) => {
                  const ehFilho = s.setor_pai_id != null;
                  const tdStyle = s.ativo ? estilos.td : estilos.tdInativo;
                  return (
                    <tr key={s.id}>
                      <td style={{ ...tdStyle, paddingLeft: ehFilho ? "36px" : "12px" }}>
                        {ehFilho && <span style={{ color: "#888", marginRight: "4px" }}>└</span>}
                        <strong>{s.nome}</strong>
                      </td>
                      <td style={tdStyle}>{fmt(s.estoque_total_m2)}</td>
                      <td style={tdStyle}>{fmt(s.teto_r_m2)}</td>
                      <td style={tdStyle}>{fmt(s.teto_nr_m2)}</td>
                      <td style={tdStyle}>{fmtF(s.fator_equivalencia_f1)}</td>
                      <td style={tdStyle}>{fmtF(s.fator_equivalencia_f2)}</td>
                      <td style={tdStyle}>
                        {s.setor_pai_id ? (nomePorId[s.setor_pai_id] ?? s.setor_pai_id) : "—"}
                      </td>
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
        </div>
      </div>

      {modalAberto && (
        <div style={estilos.overlay} onClick={(e) => { if (e.target === e.currentTarget) fecharModal(); }}>
          <div style={estilos.modal}>
            <h2 style={estilos.modalTitulo}>{editando ? "Editar Setor" : "Novo Setor"}</h2>

            {erroModal && <p role="alert" style={estilos.erro}>{erroModal}</p>}

            <form onSubmit={handleSalvar} noValidate>
              <div style={estilos.grupo}>
                <label style={estilos.label} htmlFor="s-nome">Nome *</label>
                <input
                  id="s-nome"
                  style={estilos.input}
                  value={form.nome}
                  onChange={(e) => campo("nome", e.target.value)}
                  required
                />
              </div>

              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "14px" }}>
                <div style={estilos.grupo}>
                  <label style={estilos.label} htmlFor="s-estoque">Estoque Total (m²) *</label>
                  <CampoM2
                    id="s-estoque"
                    value={form.estoque_total_m2}
                    onChange={(v) => campo("estoque_total_m2", v)}
                    required
                    placeholder="ex: 1.200.000,00"
                  />
                </div>
                <div style={estilos.grupo}>
                  <label style={estilos.label} htmlFor="s-teto-nr">Teto NR (m²) *</label>
                  <CampoM2
                    id="s-teto-nr"
                    value={form.teto_nr_m2}
                    onChange={(v) => campo("teto_nr_m2", v)}
                    required
                    placeholder="ex: 900.000,00"
                  />
                </div>
                <div style={estilos.grupo}>
                  <label style={estilos.label} htmlFor="s-teto-r">Teto R (m²)</label>
                  <CampoM2
                    id="s-teto-r"
                    value={form.teto_r_m2}
                    onChange={(v) => campo("teto_r_m2", v)}
                    placeholder="ex: 600.000,00"
                  />
                </div>
                <div style={estilos.grupo}>
                  <label style={estilos.label} htmlFor="s-reserva-r">Reserva R (m²)</label>
                  <CampoM2
                    id="s-reserva-r"
                    value={form.reserva_r_m2}
                    onChange={(v) => campo("reserva_r_m2", v)}
                    placeholder="ex: 216.442,47"
                  />
                </div>
              </div>

              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "14px" }}>
                <div style={estilos.grupo}>
                  <label style={estilos.label} htmlFor="s-piso-r">Piso R (%)</label>
                  <input
                    id="s-piso-r"
                    style={estilos.input}
                    type="number"
                    step="0.01"
                    min="0"
                    max="100"
                    value={form.piso_r_percentual}
                    onChange={(e) => campo("piso_r_percentual", e.target.value)}
                    placeholder="ex: 30"
                  />
                  <p style={estilos.hint}>% mínimo de área R</p>
                </div>
                <div style={estilos.grupo}>
                  <label style={estilos.label} htmlFor="s-pai">Setor Pai</label>
                  <select
                    id="s-pai"
                    style={estilos.input}
                    value={form.setor_pai_id}
                    onChange={(e) => campo("setor_pai_id", e.target.value)}
                  >
                    <option value="">Nenhum (setor raiz)</option>
                    {raizesParaSelect.map((r) => (
                      <option key={r.id} value={r.id}>{r.nome}</option>
                    ))}
                  </select>
                </div>
              </div>

              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "14px" }}>
                <div style={estilos.grupo}>
                  <label style={estilos.label} htmlFor="s-f1">Fator Equivalência F1</label>
                  <input
                    id="s-f1"
                    style={estilos.input}
                    type="number"
                    step="0.000001"
                    value={form.fator_equivalencia_f1}
                    onChange={(e) => campo("fator_equivalencia_f1", e.target.value)}
                    placeholder="ex: 1.000000"
                  />
                </div>
                <div style={estilos.grupo}>
                  <label style={estilos.label} htmlFor="s-f2">Fator Equivalência F2</label>
                  <input
                    id="s-f2"
                    style={estilos.input}
                    type="number"
                    step="0.000001"
                    value={form.fator_equivalencia_f2}
                    onChange={(e) => campo("fator_equivalencia_f2", e.target.value)}
                    placeholder="ex: 0.750000"
                  />
                </div>
              </div>

              <div style={estilos.grupo}>
                <label style={estilos.checkboxLinha}>
                  <input type="checkbox" checked={form.bloqueio_nr} onChange={(e) => campo("bloqueio_nr", e.target.checked)} />
                  Bloquear novas solicitações NR (incondicional)
                </label>
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
                    <label style={estilos.label} htmlFor="s-conv-aca">Convertido — ACA</label>
                    <input id="s-conv-aca" style={estilos.input} type="number" min="0" step="1"
                      value={form.cepacs_convertidos_aca}
                      onChange={(e) => campo("cepacs_convertidos_aca", e.target.value)} />
                  </div>
                  <div style={estilos.grupo}>
                    <label style={estilos.label} htmlFor="s-conv-param">Convertido — Uso e Parâmetros</label>
                    <input id="s-conv-param" style={estilos.input} type="number" min="0" step="1"
                      value={form.cepacs_convertidos_parametros}
                      onChange={(e) => campo("cepacs_convertidos_parametros", e.target.value)} />
                  </div>
                  <div style={estilos.grupo}>
                    <label style={estilos.label} htmlFor="s-desv-aca">Desvinculado — ACA</label>
                    <input id="s-desv-aca" style={estilos.input} type="number" min="0" step="1"
                      value={form.cepacs_desvinculados_aca}
                      onChange={(e) => campo("cepacs_desvinculados_aca", e.target.value)} />
                  </div>
                  <div style={estilos.grupo}>
                    <label style={estilos.label} htmlFor="s-desv-param">Desvinculado — Uso e Parâmetros</label>
                    <input id="s-desv-param" style={estilos.input} type="number" min="0" step="1"
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
