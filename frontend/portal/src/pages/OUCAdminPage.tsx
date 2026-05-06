/**
 * Página /admin/operacoes-urbanas — CRUD de Operações Urbanas Consorciadas.
 * Leitura: TECNICO ou DIRETOR. Criação/edição: DIRETOR.
 */
import { useState, useEffect, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import { listarOUCs, criarOUC, atualizarOUC, listarLeis, criarLei, atualizarLei } from "../api/admin";
import type { LeiOucIn, LeiOucOut, OperacaoUrbanaOut, OperacaoUrbanaIn } from "../types/api";
import { useUser } from "../contexts/UserContext";

const estilos: Record<string, React.CSSProperties> = {
  pagina: { fontFamily: "system-ui, sans-serif", minHeight: "100vh", background: "#f5f7fa" },
  conteudo: { maxWidth: "1200px", margin: "0 auto", padding: "28px 16px" },
  cabecalho: { display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px" },
  titulo: { fontSize: "22px", fontWeight: 700, color: "#003087", margin: 0 },
  botaoPrimario: { padding: "9px 18px", background: "#ffd166", color: "#003087", border: "none", borderRadius: "5px", cursor: "pointer", fontSize: "14px", fontWeight: 700, boxShadow: "0 2px 6px rgba(0,0,0,0.25)" },
  botaoSecundario: { padding: "7px 14px", background: "rgba(255,255,255,0.88)", color: "#003087", border: "none", borderRadius: "4px", cursor: "pointer", fontSize: "13px", fontWeight: 600, boxShadow: "0 2px 6px rgba(0,0,0,0.2)" },
  botaoEditar: { padding: "5px 12px", background: "#005cbf", color: "#fff", border: "none", borderRadius: "4px", cursor: "pointer", fontSize: "12px" },
  botaoSetores: { padding: "5px 12px", background: "#003087", color: "#fff", border: "none", borderRadius: "4px", cursor: "pointer", fontSize: "12px" },
  tabela: { width: "100%", borderCollapse: "collapse" as const, fontSize: "13px" },
  th: { textAlign: "left" as const, padding: "10px 12px", background: "#003087", color: "#fff", fontWeight: 600 },
  td: { padding: "9px 12px", borderBottom: "1px solid #e8e8e8", verticalAlign: "top" as const },
  tdInativo: { padding: "9px 12px", borderBottom: "1px solid #e8e8e8", verticalAlign: "top" as const, color: "#aaa" },
  erro: { color: "#cc0000", background: "#fff0f0", padding: "12px", borderRadius: "4px", marginBottom: "16px" },
  badge: { display: "inline-block", padding: "2px 8px", borderRadius: "10px", fontSize: "11px", fontWeight: 600 },
  badgeSim: { background: "#e6f4ea", color: "#1a7a2e" },
  badgeNao: { background: "#f5f5f5", color: "#888" },
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

interface FormOUC {
  sigla: string;
  nome: string;
  lei_vigente: string;
  estoque_maximo_global_r: string;
  estoque_maximo_global_nr: string;
  valor_cepac_ref: string;
  possui_nuvem: boolean;
  ativo: boolean;
  teto_r_nao_incentivado_m2: string;
  reserva_tecnica_m2: string;
  cepacs_totais: string;
  cepacs_leiloados: string;
  cepacs_colocacao_privada: string;
}

const FORM_VAZIO: FormOUC = {
  sigla: "",
  nome: "",
  lei_vigente: "",
  estoque_maximo_global_r: "",
  estoque_maximo_global_nr: "",
  valor_cepac_ref: "",
  possui_nuvem: false,
  ativo: true,
  teto_r_nao_incentivado_m2: "",
  reserva_tecnica_m2: "",
  cepacs_totais: "0",
  cepacs_leiloados: "0",
  cepacs_colocacao_privada: "0",
};

function oucParaForm(o: OperacaoUrbanaOut): FormOUC {
  return {
    sigla: o.sigla,
    nome: o.nome,
    lei_vigente: o.lei_vigente ?? "",
    estoque_maximo_global_r: o.estoque_maximo_global_r ?? "",
    estoque_maximo_global_nr: o.estoque_maximo_global_nr ?? "",
    valor_cepac_ref: o.valor_cepac_ref ?? "",
    possui_nuvem: o.possui_nuvem,
    ativo: o.ativo,
    teto_r_nao_incentivado_m2: o.teto_r_nao_incentivado_m2 ?? "",
    reserva_tecnica_m2: o.reserva_tecnica_m2,
    cepacs_totais: String(o.cepacs_totais ?? 0),
    cepacs_leiloados: String(o.cepacs_leiloados ?? 0),
    cepacs_colocacao_privada: String(o.cepacs_colocacao_privada ?? 0),
  };
}

function formParaPayload(f: FormOUC): OperacaoUrbanaIn {
  return {
    sigla: f.sigla.trim().toUpperCase(),
    nome: f.nome.trim(),
    lei_vigente: f.lei_vigente.trim() || null,
    estoque_maximo_global_r: numOuNull(f.estoque_maximo_global_r),
    estoque_maximo_global_nr: numOuNull(f.estoque_maximo_global_nr),
    valor_cepac_ref: numOuNull(f.valor_cepac_ref),
    possui_nuvem: f.possui_nuvem,
    ativo: f.ativo,
    data_ultima_posicao: null,
    teto_r_nao_incentivado_m2: numOuNull(f.teto_r_nao_incentivado_m2),
    reserva_tecnica_m2: parseFloat(f.reserva_tecnica_m2.replace(/\./g, "").replace(",", ".")) || 0,
    cepacs_totais: parseInt(f.cepacs_totais) || 0,
    cepacs_leiloados: parseInt(f.cepacs_leiloados) || 0,
    cepacs_colocacao_privada: parseInt(f.cepacs_colocacao_privada) || 0,
  };
}

export default function OUCAdminPage() {
  const navigate = useNavigate();
  const { isDiretor } = useUser();

  const [oucs, setOucs] = useState<OperacaoUrbanaOut[]>([]);
  const [carregando, setCarregando] = useState(true);
  const [erroGeral, setErroGeral] = useState("");

  const [modalAberto, setModalAberto] = useState(false);
  const [editando, setEditando] = useState<OperacaoUrbanaOut | null>(null);
  const [form, setForm] = useState<FormOUC>({ ...FORM_VAZIO });
  const [salvando, setSalvando] = useState(false);
  const [erroModal, setErroModal] = useState("");

  const [hoveredVoltar, setHoveredVoltar] = useState(false);
  const [hoveredNovo, setHoveredNovo] = useState(false);

  // --- Modal de leis ---
  const [leisPanelOuc, setLeisPanelOuc] = useState<OperacaoUrbanaOut | null>(null);
  const [leis, setLeis] = useState<LeiOucOut[]>([]);
  const [carregandoLeis, setCarregandoLeis] = useState(false);
  const [erroLeis, setErroLeis] = useState("");
  const [modalLeiAberto, setModalLeiAberto] = useState(false);
  const [editandoLei, setEditandoLei] = useState<LeiOucOut | null>(null);
  const [formLei, setFormLei] = useState<Partial<LeiOucIn>>({});
  const [salvandoLei, setSalvandoLei] = useState(false);
  const [erroModalLei, setErroModalLei] = useState("");

  const carregar = useCallback(async () => {
    setCarregando(true);
    setErroGeral("");
    try {
      const data = await listarOUCs();
      setOucs(data);
    } catch {
      setErroGeral("Erro ao carregar operações urbanas. Verifique a conexão com a API.");
    } finally {
      setCarregando(false);
    }
  }, []);

  useEffect(() => { void carregar(); }, [carregar]);

  function abrirNovo() {
    setEditando(null);
    setForm({ ...FORM_VAZIO });
    setErroModal("");
    setModalAberto(true);
  }

  function abrirEdicao(o: OperacaoUrbanaOut) {
    setEditando(o);
    setForm(oucParaForm(o));
    setErroModal("");
    setModalAberto(true);
  }

  function fecharModal() {
    setModalAberto(false);
    setEditando(null);
    setErroModal("");
  }

  function campo<K extends keyof FormOUC>(field: K, value: FormOUC[K]) {
    setForm((prev) => ({ ...prev, [field]: value }));
  }

  async function handleSalvar(e: React.FormEvent) {
    e.preventDefault();
    setErroModal("");

    if (!form.sigla.trim()) { setErroModal("Sigla é obrigatória."); return; }
    if (!form.nome.trim()) { setErroModal("Nome é obrigatório."); return; }

    const payload = formParaPayload(form);
    setSalvando(true);
    try {
      if (editando) {
        await atualizarOUC(editando.id, payload);
      } else {
        await criarOUC(payload);
      }
      fecharModal();
      await carregar();
    } catch (err: unknown) {
      const axiosErr = err as { response?: { status?: number; data?: { detail?: string } } };
      if (axiosErr?.response?.status === 409) {
        setErroModal("Sigla já existe.");
      } else {
        setErroModal(axiosErr?.response?.data?.detail ?? "Erro ao salvar. Verifique os dados.");
      }
    } finally {
      setSalvando(false);
    }
  }

  async function abrirPainelLeis(o: OperacaoUrbanaOut) {
    setLeisPanelOuc(o);
    setErroLeis("");
    setCarregandoLeis(true);
    try {
      const data = await listarLeis(o.id);
      setLeis(data);
    } catch {
      setErroLeis("Erro ao carregar leis.");
    } finally {
      setCarregandoLeis(false);
    }
  }

  function fecharPainelLeis() {
    setLeisPanelOuc(null);
    setLeis([]);
    setErroLeis("");
    setModalLeiAberto(false);
    setEditandoLei(null);
  }

  function abrirNovaLei() {
    if (!leisPanelOuc) return;
    setEditandoLei(null);
    setFormLei({ operacao_urbana_id: leisPanelOuc.id, vigente: false, ordem: leis.length + 1 });
    setErroModalLei("");
    setModalLeiAberto(true);
  }

  function abrirEdicaoLei(l: LeiOucOut) {
    setEditandoLei(l);
    setFormLei({
      nome: l.nome ?? "",
      identificador: l.identificador,
      data_vigencia_inicio: l.data_vigencia_inicio ?? "",
      data_vigencia_fim: l.data_vigencia_fim ?? "",
      ordem: l.ordem,
      vigente: l.vigente,
      consumo_historico_r_m2: l.consumo_historico_r_m2 ? Number(l.consumo_historico_r_m2) : undefined,
      consumo_historico_nr_m2: l.consumo_historico_nr_m2 ? Number(l.consumo_historico_nr_m2) : undefined,
      estoque_geral_m2: l.estoque_geral_m2 ? Number(l.estoque_geral_m2) : undefined,
    });
    setErroModalLei("");
    setModalLeiAberto(true);
  }

  function fecharModalLei() {
    setModalLeiAberto(false);
    setEditandoLei(null);
    setErroModalLei("");
  }

  async function handleSalvarLei(e: React.FormEvent) {
    e.preventDefault();
    setErroModalLei("");
    if (!formLei.identificador?.trim()) { setErroModalLei("Identificador é obrigatório."); return; }
    if (!formLei.ordem || formLei.ordem < 1) { setErroModalLei("Ordem deve ser maior que zero."); return; }

    setSalvandoLei(true);
    try {
      if (editandoLei) {
        await atualizarLei(editandoLei.id, {
          nome: formLei.nome || null,
          data_vigencia_inicio: formLei.data_vigencia_inicio || null,
          data_vigencia_fim: formLei.data_vigencia_fim || null,
          ordem: formLei.ordem,
          vigente: formLei.vigente,
          consumo_historico_r_m2: formLei.consumo_historico_r_m2 ?? null,
          consumo_historico_nr_m2: formLei.consumo_historico_nr_m2 ?? null,
          estoque_geral_m2: formLei.estoque_geral_m2 ?? null,
        });
      } else {
        await criarLei(formLei as LeiOucIn);
      }
      fecharModalLei();
      if (leisPanelOuc) {
        const data = await listarLeis(leisPanelOuc.id);
        setLeis(data);
      }
    } catch (err: unknown) {
      const axiosErr = err as { response?: { status?: number; data?: { detail?: string } } };
      if (axiosErr?.response?.status === 409) {
        setErroModalLei("Lei com este identificador já existe nesta OUC.");
      } else {
        setErroModalLei(axiosErr?.response?.data?.detail ?? "Erro ao salvar lei.");
      }
    } finally {
      setSalvandoLei(false);
    }
  }

  return (
    <div style={estilos.pagina}>
      {/* Cabeçalho */}
      <div style={{ background: "linear-gradient(90deg, #0B2A4A 0%, #0F3A6D 55%, #145DA0 85%, #1C6ED5 100%)" }}>
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "0 28px", height: 88 }}>
          <div style={{ display: "flex", flexDirection: "row", alignItems: "center", gap: 16 }}>
            <img src="/imagens/logobranco.svg" alt="ZENITE" style={{ height: 82, width: "auto", display: "block" }} />
            <div style={{ width: 1, height: 40, background: "rgba(255,255,255,0.25)", flexShrink: 0 }} />
            <span style={{ fontSize: 15, color: "rgba(255,255,255,0.9)", fontWeight: 700, letterSpacing: "0.03em", whiteSpace: "nowrap" }}>
              Operações Urbanas Consorciadas
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
            {isDiretor && (
              <button
                style={{ background: hoveredNovo ? "#ffe080" : "#ffd166", color: "#003087", border: "none", borderRadius: 5, cursor: "pointer", fontSize: 15, fontWeight: 700, padding: "8px 18px", boxShadow: "0 2px 6px rgba(0,0,0,0.25)", transition: "background 0.15s" }}
                onMouseEnter={() => setHoveredNovo(true)}
                onMouseLeave={() => setHoveredNovo(false)}
                onClick={abrirNovo}
              >
                + Nova OUC
              </button>
            )}
          </div>
        </div>
      </div>

      <div style={estilos.conteudo}>
        {erroGeral && <p role="alert" style={estilos.erro}>{erroGeral}</p>}

        <div style={{ background: "#fff", borderRadius: "8px", boxShadow: "0 2px 12px rgba(0,0,0,0.07)", overflow: "hidden" }}>
          {carregando ? (
            <p style={{ ...estilos.carregando, padding: "24px" }}>Carregando operações urbanas…</p>
          ) : (
            <table style={estilos.tabela}>
              <thead>
                <tr>
                  <th style={estilos.th}>Sigla</th>
                  <th style={estilos.th}>Nome</th>
                  <th style={estilos.th}>Lei Vigente</th>
                  <th style={estilos.th}>Possui Nuvem</th>
                  <th style={estilos.th}>Ativo</th>
                  <th style={estilos.th}>Ações</th>
                </tr>
              </thead>
              <tbody>
                {oucs.map((o) => {
                  const tdStyle = o.ativo ? estilos.td : estilos.tdInativo;
                  return (
                    <tr key={o.id}>
                      <td style={tdStyle}><strong>{o.sigla}</strong></td>
                      <td style={tdStyle}>{o.nome}</td>
                      <td style={tdStyle}>{o.lei_vigente ?? "—"}</td>
                      <td style={tdStyle}>
                        <span style={{ ...estilos.badge, ...(o.possui_nuvem ? estilos.badgeSim : estilos.badgeNao) }}>
                          {o.possui_nuvem ? "Sim" : "Não"}
                        </span>
                      </td>
                      <td style={tdStyle}>
                        <span style={{ ...estilos.badge, ...(o.ativo ? estilos.badgeSim : estilos.badgeNao) }}>
                          {o.ativo ? "Ativo" : "Inativo"}
                        </span>
                      </td>
                      <td style={tdStyle}>
                        <div style={{ display: "flex", gap: "6px" }}>
                          <button
                            style={estilos.botaoSetores}
                            onClick={() => navigate(`/admin/operacoes-urbanas/${o.id}/setores`)}
                          >
                            Setores
                          </button>
                          <button
                            style={{ padding: "5px 12px", background: "#1a7a2e", color: "#fff", border: "none", borderRadius: "4px", cursor: "pointer", fontSize: "12px" }}
                            onClick={() => void abrirPainelLeis(o)}
                          >
                            Leis
                          </button>
                          {isDiretor && (
                            <button style={estilos.botaoEditar} onClick={() => abrirEdicao(o)}>
                              Editar
                            </button>
                          )}
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          )}
        </div>
      </div>

      {/* Painel lateral — Histórico de Leis */}
      {leisPanelOuc && (
        <div style={{ position: "fixed", inset: 0, background: "rgba(0,0,0,0.4)", display: "flex", alignItems: "flex-start", justifyContent: "flex-end", zIndex: 900 }} onClick={(e) => { if (e.target === e.currentTarget) fecharPainelLeis(); }}>
          <div style={{ background: "#fff", width: "640px", maxWidth: "92vw", height: "100vh", overflowY: "auto", padding: "28px 24px", boxShadow: "-4px 0 24px rgba(0,0,0,0.18)" }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px" }}>
              <h2 style={{ fontSize: "18px", fontWeight: 700, color: "#003087", margin: 0 }}>
                Leis — {leisPanelOuc.sigla}
              </h2>
              <div style={{ display: "flex", gap: "8px" }}>
                {isDiretor && (
                  <button
                    style={{ padding: "7px 14px", background: "#ffd166", color: "#003087", border: "none", borderRadius: "4px", cursor: "pointer", fontSize: "13px", fontWeight: 700 }}
                    onClick={abrirNovaLei}
                  >
                    + Nova Lei
                  </button>
                )}
                <button
                  style={{ padding: "7px 14px", background: "#f5f5f5", color: "#333", border: "1px solid #ccc", borderRadius: "4px", cursor: "pointer", fontSize: "13px" }}
                  onClick={fecharPainelLeis}
                >
                  Fechar
                </button>
              </div>
            </div>

            {erroLeis && <p style={estilos.erro}>{erroLeis}</p>}

            {carregandoLeis ? (
              <p style={estilos.carregando}>Carregando leis…</p>
            ) : leis.length === 0 ? (
              <p style={{ color: "#666", fontStyle: "italic", fontSize: "13px" }}>Nenhuma lei cadastrada para esta OUC.</p>
            ) : (
              <table style={{ ...estilos.tabela, fontSize: "12px" }}>
                <thead>
                  <tr>
                    <th style={{ ...estilos.th, padding: "8px 10px" }}>Ordem</th>
                    <th style={{ ...estilos.th, padding: "8px 10px" }}>Identificador</th>
                    <th style={{ ...estilos.th, padding: "8px 10px" }}>Nome</th>
                    <th style={{ ...estilos.th, padding: "8px 10px" }}>Vigência</th>
                    <th style={{ ...estilos.th, padding: "8px 10px" }}>Vigente</th>
                    <th style={{ ...estilos.th, padding: "8px 10px" }}>Consumo R (m²)</th>
                    <th style={{ ...estilos.th, padding: "8px 10px" }}>Consumo NR (m²)</th>
                    {isDiretor && <th style={{ ...estilos.th, padding: "8px 10px" }}></th>}
                  </tr>
                </thead>
                <tbody>
                  {leis.map((l) => (
                    <tr key={l.id}>
                      <td style={{ ...estilos.td, padding: "7px 10px" }}>{l.ordem}</td>
                      <td style={{ ...estilos.td, padding: "7px 10px" }}><strong>{l.identificador}</strong></td>
                      <td style={{ ...estilos.td, padding: "7px 10px" }}>{l.nome ?? "—"}</td>
                      <td style={{ ...estilos.td, padding: "7px 10px", whiteSpace: "nowrap" }}>
                        {l.data_vigencia_inicio ?? "—"}{l.data_vigencia_fim ? ` → ${l.data_vigencia_fim}` : l.data_vigencia_inicio ? " → atual" : ""}
                      </td>
                      <td style={{ ...estilos.td, padding: "7px 10px" }}>
                        <span style={{ ...estilos.badge, ...(l.vigente ? estilos.badgeSim : estilos.badgeNao) }}>
                          {l.vigente ? "Sim" : "Não"}
                        </span>
                      </td>
                      <td style={{ ...estilos.td, padding: "7px 10px" }}>
                        {l.consumo_historico_r_m2 ? Number(l.consumo_historico_r_m2).toLocaleString("pt-BR", { minimumFractionDigits: 2 }) : "—"}
                      </td>
                      <td style={{ ...estilos.td, padding: "7px 10px" }}>
                        {l.consumo_historico_nr_m2 ? Number(l.consumo_historico_nr_m2).toLocaleString("pt-BR", { minimumFractionDigits: 2 }) : "—"}
                      </td>
                      {isDiretor && (
                        <td style={{ ...estilos.td, padding: "7px 10px" }}>
                          <button style={estilos.botaoEditar} onClick={() => abrirEdicaoLei(l)}>Editar</button>
                        </td>
                      )}
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </div>
      )}

      {/* Modal de criação/edição de lei */}
      {modalLeiAberto && (
        <div style={{ ...estilos.overlay, zIndex: 1100 }} onClick={(e) => { if (e.target === e.currentTarget) fecharModalLei(); }}>
          <div style={{ ...estilos.modal, width: "520px" }}>
            <h2 style={estilos.modalTitulo}>{editandoLei ? "Editar Lei" : "Nova Lei"}</h2>
            {erroModalLei && <p role="alert" style={estilos.erro}>{erroModalLei}</p>}
            <form onSubmit={(e) => void handleSalvarLei(e)} noValidate>
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "14px" }}>
                <div style={estilos.grupo}>
                  <label style={estilos.label} htmlFor="lei-id">Identificador *</label>
                  <input
                    id="lei-id"
                    style={estilos.input}
                    value={formLei.identificador ?? ""}
                    onChange={(e) => setFormLei((p) => ({ ...p, identificador: e.target.value }))}
                    placeholder="ex: 18.175/2024"
                    maxLength={30}
                    disabled={!!editandoLei}
                    required
                  />
                </div>
                <div style={estilos.grupo}>
                  <label style={estilos.label} htmlFor="lei-ordem">Ordem *</label>
                  <input
                    id="lei-ordem"
                    style={estilos.input}
                    type="number"
                    min={1}
                    step={1}
                    value={formLei.ordem ?? ""}
                    onChange={(e) => setFormLei((p) => ({ ...p, ordem: parseInt(e.target.value) || 1 }))}
                    required
                  />
                </div>
              </div>

              <div style={estilos.grupo}>
                <label style={estilos.label} htmlFor="lei-nome">Nome</label>
                <input
                  id="lei-nome"
                  style={estilos.input}
                  value={formLei.nome ?? ""}
                  onChange={(e) => setFormLei((p) => ({ ...p, nome: e.target.value }))}
                  placeholder="ex: Lei de Revisão da OUCFL"
                  maxLength={150}
                />
              </div>

              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "14px" }}>
                <div style={estilos.grupo}>
                  <label style={estilos.label} htmlFor="lei-inicio">Início Vigência</label>
                  <input
                    id="lei-inicio"
                    style={estilos.input}
                    type="date"
                    value={formLei.data_vigencia_inicio ?? ""}
                    onChange={(e) => setFormLei((p) => ({ ...p, data_vigencia_inicio: e.target.value || null }))}
                  />
                </div>
                <div style={estilos.grupo}>
                  <label style={estilos.label} htmlFor="lei-fim">Fim Vigência</label>
                  <input
                    id="lei-fim"
                    style={estilos.input}
                    type="date"
                    value={formLei.data_vigencia_fim ?? ""}
                    onChange={(e) => setFormLei((p) => ({ ...p, data_vigencia_fim: e.target.value || null }))}
                  />
                  <p style={estilos.hint}>Deixe em branco para lei atual</p>
                </div>
              </div>

              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "14px" }}>
                <div style={estilos.grupo}>
                  <label style={estilos.label} htmlFor="lei-cons-r">Consumo Histórico R (m²)</label>
                  <input
                    id="lei-cons-r"
                    style={estilos.input}
                    type="number"
                    min={0}
                    step="0.01"
                    value={formLei.consumo_historico_r_m2 ?? ""}
                    onChange={(e) => setFormLei((p) => ({ ...p, consumo_historico_r_m2: e.target.value ? parseFloat(e.target.value) : undefined }))}
                    placeholder="ex: 646099.80"
                  />
                  <p style={estilos.hint}>Apenas leis encerradas</p>
                </div>
                <div style={estilos.grupo}>
                  <label style={estilos.label} htmlFor="lei-cons-nr">Consumo Histórico NR (m²)</label>
                  <input
                    id="lei-cons-nr"
                    style={estilos.input}
                    type="number"
                    min={0}
                    step="0.01"
                    value={formLei.consumo_historico_nr_m2 ?? ""}
                    onChange={(e) => setFormLei((p) => ({ ...p, consumo_historico_nr_m2: e.target.value ? parseFloat(e.target.value) : undefined }))}
                    placeholder="ex: 426934.24"
                  />
                </div>
              </div>

              <div style={estilos.grupo}>
                <label style={estilos.label} htmlFor="lei-estoque-geral">Estoque Geral (m²)</label>
                <input
                  id="lei-estoque-geral"
                  style={estilos.input}
                  type="number"
                  min={0}
                  step="0.01"
                  value={formLei.estoque_geral_m2 ?? ""}
                  onChange={(e) => setFormLei((p) => ({ ...p, estoque_geral_m2: e.target.value ? parseFloat(e.target.value) : undefined }))}
                  placeholder="ex: 1756155.00"
                />
                <p style={estilos.hint}>Capacidade máxima de CEPAC sob esta lei</p>
              </div>

              <label style={{ ...estilos.checkboxLinha, marginBottom: "16px" }}>
                <input
                  type="checkbox"
                  checked={formLei.vigente ?? false}
                  onChange={(e) => setFormLei((p) => ({ ...p, vigente: e.target.checked }))}
                />
                Lei vigente (atual)
              </label>

              <div style={estilos.botoes}>
                <button type="button" style={estilos.botaoSecundario} onClick={fecharModalLei} disabled={salvandoLei}>
                  Cancelar
                </button>
                <button type="submit" style={estilos.botaoPrimario} disabled={salvandoLei}>
                  {salvandoLei ? "Salvando…" : "Salvar"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {modalAberto && (
        <div style={estilos.overlay} onClick={(e) => { if (e.target === e.currentTarget) fecharModal(); }}>
          <div style={estilos.modal}>
            <h2 style={estilos.modalTitulo}>{editando ? "Editar OUC" : "Nova OUC"}</h2>

            {erroModal && <p role="alert" style={estilos.erro}>{erroModal}</p>}

            <form onSubmit={handleSalvar} noValidate>
              <div style={{ display: "grid", gridTemplateColumns: "1fr 2fr", gap: "14px" }}>
                <div style={estilos.grupo}>
                  <label style={estilos.label} htmlFor="ouc-sigla">Sigla *</label>
                  <input
                    id="ouc-sigla"
                    style={estilos.input}
                    value={form.sigla}
                    maxLength={5}
                    onChange={(e) => campo("sigla", e.target.value.toUpperCase())}
                    required
                    placeholder="ex: OUCAE"
                  />
                </div>
                <div style={estilos.grupo}>
                  <label style={estilos.label} htmlFor="ouc-nome">Nome *</label>
                  <input
                    id="ouc-nome"
                    style={estilos.input}
                    value={form.nome}
                    onChange={(e) => campo("nome", e.target.value)}
                    required
                    placeholder="Nome completo da operação urbana"
                  />
                </div>
              </div>

              <div style={estilos.grupo}>
                <label style={estilos.label} htmlFor="ouc-lei">Lei Vigente</label>
                <input
                  id="ouc-lei"
                  style={estilos.input}
                  value={form.lei_vigente}
                  onChange={(e) => campo("lei_vigente", e.target.value)}
                  placeholder="ex: Lei nº 13.769/2004"
                />
              </div>

              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "14px" }}>
                <div style={estilos.grupo}>
                  <label style={estilos.label} htmlFor="ouc-est-r">Estoque Máximo Global R (m²)</label>
                  <CampoM2
                    id="ouc-est-r"
                    value={form.estoque_maximo_global_r}
                    onChange={(v) => campo("estoque_maximo_global_r", v)}
                    placeholder="ex: 1.200.000,00"
                  />
                </div>
                <div style={estilos.grupo}>
                  <label style={estilos.label} htmlFor="ouc-est-nr">Estoque Máximo Global NR (m²)</label>
                  <CampoM2
                    id="ouc-est-nr"
                    value={form.estoque_maximo_global_nr}
                    onChange={(v) => campo("estoque_maximo_global_nr", v)}
                    placeholder="ex: 1.100.000,00"
                  />
                </div>
              </div>

              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "14px" }}>
                <div style={estilos.grupo}>
                  <label style={estilos.label} htmlFor="ouc-valor-cepac">Valor CEPAC Ref. (R$/m²)</label>
                  <input
                    id="ouc-valor-cepac"
                    style={estilos.input}
                    type="number"
                    step="0.01"
                    min="0"
                    value={form.valor_cepac_ref}
                    onChange={(e) => campo("valor_cepac_ref", e.target.value)}
                    placeholder="ex: 3850.00"
                  />
                </div>
                <div style={estilos.grupo}>
                  <label style={estilos.label} htmlFor="ouc-teto-r-ni">Teto R Não Incentivado (m²)</label>
                  <CampoM2
                    id="ouc-teto-r-ni"
                    value={form.teto_r_nao_incentivado_m2}
                    onChange={(v) => campo("teto_r_nao_incentivado_m2", v)}
                    placeholder="ex: 200.000,00"
                  />
                  <p style={estilos.hint}>Apenas OUCAB — limite R Não Incentivado</p>
                </div>
              </div>

              <div style={{ display: "flex", gap: "24px", marginBottom: "16px" }}>
                <label style={estilos.checkboxLinha}>
                  <input
                    type="checkbox"
                    checked={form.possui_nuvem}
                    onChange={(e) => campo("possui_nuvem", e.target.checked)}
                  />
                  Possui Nuvem
                </label>
                <label style={estilos.checkboxLinha}>
                  <input
                    type="checkbox"
                    checked={form.ativo}
                    onChange={(e) => campo("ativo", e.target.checked)}
                  />
                  Operação ativa
                </label>
              </div>

              <hr style={{ border: "none", borderTop: "1px solid #e0e4ea", margin: "20px 0" }} />
              <p style={{ margin: "0 0 14px", fontSize: "12px", fontWeight: 700, color: "#003087", textTransform: "uppercase", letterSpacing: "0.4px" }}>
                Parâmetros da Operação
              </p>

              <div style={estilos.grupo}>
                <label style={estilos.label} htmlFor="ouc-reserva">Reserva Técnica (m²)</label>
                <CampoM2
                  id="ouc-reserva"
                  value={form.reserva_tecnica_m2}
                  onChange={(v) => campo("reserva_tecnica_m2", v)}
                  placeholder="ex: 50.000,00"
                />
              </div>

              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: "14px" }}>
                <div style={estilos.grupo}>
                  <label style={estilos.label} htmlFor="ouc-cepacs-totais">CEPACs Totais</label>
                  <input
                    id="ouc-cepacs-totais"
                    style={estilos.input}
                    type="number"
                    min="0"
                    step="1"
                    value={form.cepacs_totais}
                    onChange={(e) => campo("cepacs_totais", e.target.value)}
                  />
                </div>
                <div style={estilos.grupo}>
                  <label style={estilos.label} htmlFor="ouc-cepacs-leil">CEPACs Leiloados</label>
                  <input
                    id="ouc-cepacs-leil"
                    style={estilos.input}
                    type="number"
                    min="0"
                    step="1"
                    value={form.cepacs_leiloados}
                    onChange={(e) => campo("cepacs_leiloados", e.target.value)}
                  />
                </div>
                <div style={estilos.grupo}>
                  <label style={estilos.label} htmlFor="ouc-cepacs-col">CEPACs Col. Privada</label>
                  <input
                    id="ouc-cepacs-col"
                    style={estilos.input}
                    type="number"
                    min="0"
                    step="1"
                    value={form.cepacs_colocacao_privada}
                    onChange={(e) => campo("cepacs_colocacao_privada", e.target.value)}
                  />
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
