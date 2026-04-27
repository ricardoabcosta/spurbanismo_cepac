/**
 * Página /propostas — Portal OUC Água Espraiada.
 * Lista a tabela `proposta` (AE-XXXX) via GET /portal/propostas.
 */
import { useState, useEffect, useCallback, useRef } from "react";
import { useNavigate } from "react-router-dom";
import { useMsal } from "@azure/msal-react";
import { listarPropostasAE, listarSetores } from "../api/portal";
import PaginacaoControle from "../components/PaginacaoControle";
import type { PropostaListItem, SetorBasico } from "../types/api";

// ---------------------------------------------------------------------------
// Constantes
// ---------------------------------------------------------------------------

type StatusPA = "ANALISE" | "DEFERIDO" | "INDEFERIDO";
type SituacaoCert = "ANALISE" | "VALIDA" | "CANCELADA";

const STATUS_OPCOES: { value: string; label: string }[] = [
  { value: "", label: "Todos" },
  { value: "ANALISE", label: "Em Análise" },
  { value: "DEFERIDO", label: "Deferido" },
  { value: "INDEFERIDO", label: "Indeferido" },
];

const CERT_OPCOES: { value: string; label: string }[] = [
  { value: "", label: "Todas" },
  { value: "ANALISE", label: "Em Análise" },
  { value: "VALIDA", label: "Válida" },
  { value: "CANCELADA", label: "Cancelada" },
];

// Cores semânticas para fundo branco (pills na tabela — status_pa)
const STATUS_PILL_BG: Record<StatusPA, string> = {
  ANALISE: "rgba(100,140,200,0.12)",
  DEFERIDO: "rgba(52,168,83,0.12)",
  INDEFERIDO: "rgba(234,67,53,0.12)",
};

const STATUS_PILL_COLOR: Record<StatusPA, string> = {
  ANALISE: "#2a5298",
  DEFERIDO: "#1e7e34",
  INDEFERIDO: "#990000",
};

const STATUS_LABEL: Record<StatusPA, string> = {
  ANALISE: "Em Análise",
  DEFERIDO: "Deferido",
  INDEFERIDO: "Indeferido",
};

// Certidão — cores para pills na tabela
const CERT_PILL_BG: Record<SituacaoCert, string> = {
  ANALISE: "rgba(239,159,39,0.12)",
  VALIDA: "rgba(52,168,83,0.12)",
  CANCELADA: "rgba(234,67,53,0.12)",
};

const CERT_PILL_COLOR: Record<SituacaoCert, string> = {
  ANALISE: "#EF9F27",
  VALIDA: "#34a853",
  CANCELADA: "#ea4335",
};

const CERT_LABEL: Record<SituacaoCert, string> = {
  ANALISE: "Em Análise",
  VALIDA: "Válida",
  CANCELADA: "Cancelada",
};

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function formatarData(iso: string | null): string {
  if (!iso) return "—";
  return new Date(iso).toLocaleDateString("pt-BR");
}

// ---------------------------------------------------------------------------
// Ícones SVG inline
// ---------------------------------------------------------------------------

function IconeLupa() {
  return (
    <svg
      width="14" height="14" viewBox="0 0 16 16" fill="none"
      xmlns="http://www.w3.org/2000/svg" style={{ display: "block" }}
      aria-hidden="true"
    >
      <circle cx="6.5" cy="6.5" r="4.5" stroke="#fff" strokeWidth="1.8" />
      <line x1="10" y1="10" x2="14" y2="14" stroke="#fff" strokeWidth="1.8" strokeLinecap="round" />
    </svg>
  );
}

function IconeOlho() {
  return (
    <svg
      width="16" height="16" viewBox="0 0 16 16" fill="none"
      xmlns="http://www.w3.org/2000/svg" style={{ display: "block" }}
      aria-hidden="true"
    >
      <path
        d="M1 8s2.5-5 7-5 7 5 7 5-2.5 5-7 5-7-5-7-5z"
        stroke="#0066cc" strokeWidth="1.5" fill="none"
      />
      <circle cx="8" cy="8" r="2" fill="#0066cc" />
    </svg>
  );
}

function IconePastaVazia() {
  return (
    <svg
      width="64" height="56" viewBox="0 0 64 56" fill="none"
      xmlns="http://www.w3.org/2000/svg"
      aria-hidden="true"
    >
      {/* pasta base */}
      <rect x="4" y="16" width="56" height="36" rx="4" fill="#e8ecf0" stroke="#ccc" strokeWidth="1.5" />
      {/* aba */}
      <path d="M4 16 L4 12 Q4 10 6 10 L22 10 L26 16 Z" fill="#d8dde4" stroke="#ccc" strokeWidth="1.5" />
      {/* linhas internas */}
      <line x1="14" y1="28" x2="50" y2="28" stroke="#ccc" strokeWidth="1.5" strokeLinecap="round" />
      <line x1="14" y1="35" x2="44" y2="35" stroke="#ccc" strokeWidth="1.5" strokeLinecap="round" />
      <line x1="14" y1="42" x2="38" y2="42" stroke="#ccc" strokeWidth="1.5" strokeLinecap="round" />
    </svg>
  );
}

// ---------------------------------------------------------------------------
// Skeleton row
// ---------------------------------------------------------------------------

function SkeletonRow() {
  const cellWidths = ["90px", "80px", "120px", "60px", "70px", "60px", "80px", "70px"];
  return (
    <tr>
      {cellWidths.map((w, i) => (
        <td key={i} style={{ padding: "12px 14px", borderBottom: "1px solid #eee" }}>
          <div
            style={{
              background: "linear-gradient(90deg, #e8ecf0 25%, #f5f7fa 50%, #e8ecf0 75%)",
              backgroundSize: "200% 100%",
              borderRadius: 4,
              height: 16,
              width: w,
              animation: "shimmer 1.5s infinite",
            }}
          />
        </td>
      ))}
    </tr>
  );
}

// ---------------------------------------------------------------------------
// Filtros locais
// ---------------------------------------------------------------------------

interface FiltrosAE {
  page?: number;
  page_size?: number;
  setor_id?: string;
  status_pa?: string;
  situacao_certidao?: string;
}

// ---------------------------------------------------------------------------
// Componente principal
// ---------------------------------------------------------------------------

export default function PropostasPage() {
  const navigate = useNavigate();

  const [filtros, setFiltros] = useState<FiltrosAE>({ page: 1, page_size: 20 });
  const [filtrosTemp, setFiltrosTemp] = useState<FiltrosAE>({ page: 1, page_size: 20 });
  const [items, setItems] = useState<PropostaListItem[]>([]);
  const [total, setTotal] = useState(0);
  const [totalPages, setTotalPages] = useState(1);
  const [carregando, setCarregando] = useState(false);
  const [erro, setErro] = useState("");

  // Counts por status_pa (3 chamadas paralelas)
  const [counts, setCounts] = useState<Record<string, number>>({ ANALISE: 0, DEFERIDO: 0, INDEFERIDO: 0 });

  // Setores para o select
  const [setores, setSetores] = useState<SetorBasico[]>([]);

  // UI states
  const [hoveredRow, setHoveredRow] = useState<string | null>(null);
  const [hoveredAdm, setHoveredAdm] = useState(false);
  const [hoveredNova, setHoveredNova] = useState(false);
  const [hoveredDash, setHoveredDash] = useState(false);
  const [hoveredCard, setHoveredCard] = useState<string | null>(null);
  const [dropdownAberto, setDropdownAberto] = useState(false);
  const avatarRef = useRef<HTMLDivElement>(null);

  const DEV_BYPASS = import.meta.env.VITE_DEV_BYPASS_AUTH === "true";
  const { instance, accounts } = useMsal();
  const nomeUsuario = DEV_BYPASS ? "Administrador" : (accounts[0]?.name ?? "Usuário");
  const iniciais = nomeUsuario
    .split(" ")
    .filter(Boolean)
    .slice(0, 2)
    .map((p) => p[0])
    .join("")
    .toUpperCase();

  // ---------------------------------------------------------------------------
  // Carregar setores uma vez
  // ---------------------------------------------------------------------------

  useEffect(() => {
    listarSetores()
      .then(setSetores)
      .catch(() => {/* silencioso — select fica vazio */});
  }, []);

  // ---------------------------------------------------------------------------
  // Carregar counts por status em paralelo (independente da paginação)
  // ---------------------------------------------------------------------------

  const carregarCounts = useCallback(async (f: FiltrosAE) => {
    try {
      const [rAnalise, rDeferido, rIndeferido] = await Promise.all([
        listarPropostasAE({ ...f, page: 1, page_size: 1, status_pa: "ANALISE" }),
        listarPropostasAE({ ...f, page: 1, page_size: 1, status_pa: "DEFERIDO" }),
        listarPropostasAE({ ...f, page: 1, page_size: 1, status_pa: "INDEFERIDO" }),
      ]);
      setCounts({
        ANALISE: rAnalise.total,
        DEFERIDO: rDeferido.total,
        INDEFERIDO: rIndeferido.total,
      });
    } catch {
      /* silencioso */
    }
  }, []);

  // ---------------------------------------------------------------------------
  // Carregar lista paginada
  // ---------------------------------------------------------------------------

  const carregar = useCallback(async (f: FiltrosAE) => {
    setCarregando(true);
    setErro("");
    try {
      const resp = await listarPropostasAE(f);
      setItems(resp.items);
      setTotal(resp.total);
      setTotalPages(resp.total_pages);
    } catch {
      setErro("Falha ao carregar propostas. Tente novamente.");
    } finally {
      setCarregando(false);
    }
  }, []);

  useEffect(() => {
    void carregar(filtros);
    // Recalcula counts sempre que os filtros de setor mudam (sem status_pa fixo)
    void carregarCounts({ setor_id: filtros.setor_id });
  }, [filtros, carregar, carregarCounts]);

  useEffect(() => {
    function fecharFora(e: MouseEvent) {
      if (avatarRef.current && !avatarRef.current.contains(e.target as Node)) {
        setDropdownAberto(false);
      }
    }
    if (dropdownAberto) document.addEventListener("mousedown", fecharFora);
    return () => document.removeEventListener("mousedown", fecharFora);
  }, [dropdownAberto]);

  function handleLogout() {
    void instance.logoutRedirect();
  }

  function handleFiltrar(e: React.FormEvent) {
    e.preventDefault();
    const novos = { ...filtrosTemp, page: 1 };
    setFiltros(novos);
  }

  function handleCardStatus(status: StatusPA) {
    const statusAtual = filtros.status_pa;
    const novoStatus = statusAtual === status ? undefined : status;
    const novos = { ...filtros, status_pa: novoStatus, page: 1 };
    setFiltros(novos);
    setFiltrosTemp((ft) => ({ ...ft, status_pa: novoStatus }));
  }

  // ---------------------------------------------------------------------------
  // Render
  // ---------------------------------------------------------------------------

  const totalGeral = counts.ANALISE + counts.DEFERIDO + counts.INDEFERIDO;

  return (
    <>
      {/* Bloco de estilos para animações */}
      <style>{`
        @keyframes shimmer {
          0%   { background-position: 200% 0; }
          100% { background-position: -200% 0; }
        }
      `}</style>

      <div style={{ fontFamily: "system-ui, -apple-system, sans-serif", minHeight: "100vh", background: "#f5f7fa" }}>

        {/* ------------------------------------------------------------------ */}
        {/* CABEÇALHO — Top bar + KPI strip                                    */}
        {/* ------------------------------------------------------------------ */}
        <div style={{ background: "linear-gradient(90deg, #0B2A4A 0%, #0F3A6D 55%, #145DA0 85%, #1C6ED5 100%)" }}>

          {/* Top bar */}
          <div
            style={{
              display: "flex",
              alignItems: "center",
              justifyContent: "space-between",
              padding: "0 28px",
              height: 88,
            }}
          >
            {/* Esquerda: logo + separador + subtítulo */}
            <div style={{ display: "flex", flexDirection: "row", alignItems: "center", gap: 16 }}>
              <img
                src="/imagens/logobranco.svg"
                alt="ZENITE"
                style={{ height: 82, width: "auto", display: "block" }}
              />
              <div style={{ width: 1, height: 40, background: "rgba(255,255,255,0.25)", flexShrink: 0 }} />
              <span
                style={{
                  fontSize: 15,
                  color: "rgba(255,255,255,0.9)",
                  fontWeight: 700,
                  letterSpacing: "0.03em",
                  whiteSpace: "nowrap",
                }}
              >
                Operação Urbana Consorciada Água Espraiada
              </span>
            </div>

            {/* Direita: nav + avatar + nova proposta */}
            <div style={{ display: "flex", alignItems: "center", gap: 4 }}>
              {/* Dashboard */}
              <button
                style={{
                  background: hoveredDash ? "rgba(255,255,255,0.12)" : "transparent",
                  border: "none",
                  color: "rgba(255,255,255,0.95)",
                  padding: "7px 16px",
                  borderRadius: 5,
                  cursor: "pointer",
                  fontSize: 15,
                  fontWeight: 600,
                  transition: "background 0.15s",
                }}
                onMouseEnter={() => setHoveredDash(true)}
                onMouseLeave={() => setHoveredDash(false)}
                onClick={() => window.open("http://localhost:3001/", "_blank", "noopener,noreferrer")}
              >
                Dashboard
              </button>

              {/* Administração */}
              <button
                style={{
                  background: hoveredAdm ? "rgba(255,255,255,0.12)" : "transparent",
                  border: "none",
                  color: "rgba(255,255,255,0.95)",
                  padding: "7px 16px",
                  borderRadius: 5,
                  cursor: "pointer",
                  fontSize: 15,
                  fontWeight: 600,
                  transition: "background 0.15s",
                }}
                onMouseEnter={() => setHoveredAdm(true)}
                onMouseLeave={() => setHoveredAdm(false)}
                onClick={() => navigate("/admin/setores")}
              >
                Administração
              </button>

              {/* Separador */}
              <div style={{ width: 1, height: 26, background: "rgba(255,255,255,0.2)", margin: "0 6px" }} />

              {/* Avatar com dropdown */}
              <div ref={avatarRef} style={{ position: "relative" }}>
                <button
                  onClick={() => setDropdownAberto((v) => !v)}
                  aria-label={`Menu do usuário ${nomeUsuario}`}
                  aria-expanded={dropdownAberto}
                  style={{
                    display: "flex",
                    alignItems: "center",
                    gap: 8,
                    background: dropdownAberto ? "rgba(255,255,255,0.15)" : "transparent",
                    border: "none",
                    cursor: "pointer",
                    borderRadius: 6,
                    padding: "5px 10px 5px 5px",
                    transition: "background 0.15s",
                  }}
                >
                  <div
                    style={{
                      width: 32,
                      height: 32,
                      borderRadius: "50%",
                      background: "#1a73e8",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      fontSize: 12,
                      fontWeight: 700,
                      color: "#fff",
                      flexShrink: 0,
                      letterSpacing: "0.05em",
                    }}
                  >
                    {iniciais}
                  </div>
                  <span style={{ fontSize: 15, color: "rgba(255,255,255,0.95)", fontWeight: 600 }}>
                    {nomeUsuario.split(" ")[0]}
                  </span>
                  <svg
                    width="10" height="10" viewBox="0 0 10 10" fill="none" aria-hidden="true"
                    style={{ transform: dropdownAberto ? "rotate(180deg)" : "none", transition: "transform 0.15s" }}
                  >
                    <path d="M1.5 3.5l3.5 3.5 3.5-3.5" stroke="rgba(255,255,255,0.6)" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
                  </svg>
                </button>

                {dropdownAberto && (
                  <div
                    style={{
                      position: "absolute",
                      top: "calc(100% + 10px)",
                      right: 0,
                      background: "#fff",
                      borderRadius: 8,
                      boxShadow: "0 4px 20px rgba(0,0,0,0.18)",
                      minWidth: 210,
                      zIndex: 200,
                      overflow: "hidden",
                    }}
                  >
                    <div style={{ padding: "14px 16px 10px", borderBottom: "1px solid #eee" }}>
                      <div style={{ fontSize: 13, fontWeight: 600, color: "#1a2533" }}>{nomeUsuario}</div>
                    </div>
                    <button
                      onClick={handleLogout}
                      style={{
                        display: "block",
                        width: "100%",
                        padding: "11px 16px",
                        background: "none",
                        border: "none",
                        textAlign: "left" as const,
                        fontSize: 13,
                        color: "#cc0000",
                        cursor: "pointer",
                        fontWeight: 500,
                      }}
                      onMouseEnter={(e) => { (e.currentTarget).style.background = "#fff0f0"; }}
                      onMouseLeave={(e) => { (e.currentTarget).style.background = "none"; }}
                    >
                      Sair
                    </button>
                  </div>
                )}
              </div>

              {/* Separador */}
              <div style={{ width: 1, height: 26, background: "rgba(255,255,255,0.2)", margin: "0 6px" }} />

              {/* + Nova Proposta */}
              <button
                style={{
                  padding: "8px 18px",
                  background: hoveredNova ? "#ffe080" : "#ffd166",
                  color: "#003087",
                  border: "none",
                  borderRadius: 5,
                  cursor: "pointer",
                  fontSize: 13,
                  fontWeight: 700,
                  transition: "background 0.15s",
                  boxShadow: "0 2px 6px rgba(0,0,0,0.25)",
                }}
                onMouseEnter={() => setHoveredNova(true)}
                onMouseLeave={() => setHoveredNova(false)}
                onClick={() => navigate("/propostas/nova")}
              >
                + Nova Proposta
              </button>
            </div>
          </div>

          {/* KPI strip */}
          <div
            style={{
              borderTop: "1px solid rgba(255,255,255,0.1)",
              padding: "12px 28px 16px",
              display: "flex",
              gap: 12,
            }}
          >
            {/* Total */}
            {[
              {
                key: "TOTAL",
                count: totalGeral,
                label: "Total de Propostas",
                pct: null,
                iconColor: "rgba(255,255,255,0.55)",
                iconBg: "rgba(255,255,255,0.12)",
                labelColor: "rgba(255,255,255,0.7)",
                icon: (
                  <svg width="18" height="18" viewBox="0 0 18 18" fill="none" aria-hidden="true">
                    <rect x="2" y="9" width="3" height="7" rx="1" fill="rgba(255,255,255,0.85)" />
                    <rect x="7" y="5" width="3" height="11" rx="1" fill="rgba(255,255,255,0.85)" />
                    <rect x="12" y="2" width="3" height="14" rx="1" fill="rgba(255,255,255,0.85)" />
                  </svg>
                ),
                ativo: !filtros.status_pa,
                isHov: hoveredCard === "TOTAL",
                onClick: () => {
                  setFiltros((f) => ({ ...f, status_pa: undefined, page: 1 }));
                  setFiltrosTemp((ft) => ({ ...ft, status_pa: undefined }));
                },
                onEnter: () => setHoveredCard("TOTAL"),
              },
              {
                key: "ANALISE",
                count: counts.ANALISE,
                label: "Em Análise",
                pct: totalGeral > 0 ? Math.round((counts.ANALISE / totalGeral) * 100) : 0,
                iconColor: "#EF9F27",
                iconBg: "rgba(239,159,39,0.22)",
                labelColor: "#ffd9a0",
                icon: (
                  <svg width="18" height="18" viewBox="0 0 18 18" fill="none" aria-hidden="true">
                    <circle cx="9" cy="9" r="7" stroke="#EF9F27" strokeWidth="1.8" />
                    <line x1="9" y1="5.5" x2="9" y2="10" stroke="#EF9F27" strokeWidth="2" strokeLinecap="round" />
                    <circle cx="9" cy="12.5" r="1" fill="#EF9F27" />
                  </svg>
                ),
                ativo: filtros.status_pa === "ANALISE",
                isHov: hoveredCard === "ANALISE",
                onClick: () => handleCardStatus("ANALISE"),
                onEnter: () => setHoveredCard("ANALISE"),
              },
              {
                key: "DEFERIDO",
                count: counts.DEFERIDO,
                label: "Deferidas",
                pct: totalGeral > 0 ? Math.round((counts.DEFERIDO / totalGeral) * 100) : 0,
                iconColor: "#6ee07f",
                iconBg: "rgba(110,224,127,0.18)",
                labelColor: "#6ee07f",
                icon: (
                  <svg width="18" height="18" viewBox="0 0 18 18" fill="none" aria-hidden="true">
                    <circle cx="9" cy="9" r="7" stroke="#6ee07f" strokeWidth="1.8" />
                    <path d="M5.5 9l2.5 2.5 4.5-4.5" stroke="#6ee07f" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
                  </svg>
                ),
                ativo: filtros.status_pa === "DEFERIDO",
                isHov: hoveredCard === "DEFERIDO",
                onClick: () => handleCardStatus("DEFERIDO"),
                onEnter: () => setHoveredCard("DEFERIDO"),
              },
              {
                key: "INDEFERIDO",
                count: counts.INDEFERIDO,
                label: "Indeferidas",
                pct: totalGeral > 0 ? Math.round((counts.INDEFERIDO / totalGeral) * 100) : 0,
                iconColor: "#ff7b7b",
                iconBg: "rgba(255,123,123,0.18)",
                labelColor: "#ff7b7b",
                icon: (
                  <svg width="18" height="18" viewBox="0 0 18 18" fill="none" aria-hidden="true">
                    <circle cx="9" cy="9" r="7" stroke="#ff7b7b" strokeWidth="1.8" />
                    <path d="M6 6l6 6M12 6l-6 6" stroke="#ff7b7b" strokeWidth="2" strokeLinecap="round" />
                  </svg>
                ),
                ativo: filtros.status_pa === "INDEFERIDO",
                isHov: hoveredCard === "INDEFERIDO",
                onClick: () => handleCardStatus("INDEFERIDO"),
                onEnter: () => setHoveredCard("INDEFERIDO"),
              },
            ].map(({ key, count, label, pct, iconBg, labelColor, icon, ativo, isHov, onClick, onEnter }) => (
              <button
                key={key}
                onClick={onClick}
                onMouseEnter={onEnter}
                onMouseLeave={() => setHoveredCard(null)}
                style={{
                  flex: 1,
                  padding: "10px 16px",
                  background: ativo || isHov ? "rgba(255,255,255,0.18)" : "rgba(255,255,255,0.08)",
                  border: ativo ? "1px solid rgba(255,255,255,0.4)" : "1px solid rgba(255,255,255,0.1)",
                  borderRadius: 8,
                  cursor: "pointer",
                  textAlign: "left",
                  transition: "background 0.15s, border 0.15s",
                  display: "flex",
                  alignItems: "center",
                  gap: 12,
                }}
                aria-pressed={ativo}
                aria-label={`${label}: ${count}`}
              >
                <div
                  style={{
                    width: 38,
                    height: 38,
                    borderRadius: "50%",
                    background: iconBg,
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    flexShrink: 0,
                  }}
                >
                  {icon}
                </div>
                <div>
                  <div style={{ fontSize: 24, fontWeight: 700, color: "#fff", lineHeight: 1, marginBottom: 2 }}>
                    {count}
                  </div>
                  <div style={{ fontSize: 11, color: labelColor, fontWeight: 600, textTransform: "uppercase", letterSpacing: "0.7px" }}>
                    {label}
                  </div>
                  {pct !== null && (
                    <div style={{ fontSize: 10, color: "rgba(255,255,255,0.4)", marginTop: 1 }}>
                      {pct}% do total
                    </div>
                  )}
                </div>
              </button>
            ))}
          </div>
        </div>

        {/* ------------------------------------------------------------------ */}
        {/* ZONA 3 — Filtros + tabela                                           */}
        {/* ------------------------------------------------------------------ */}
        <div style={{ background: "#f5f7fa", padding: "24px" }}>

          {/* Filtros integrados */}
          <form
            onSubmit={handleFiltrar}
            style={{
              display: "flex",
              gap: "16px",
              flexWrap: "wrap",
              alignItems: "flex-end",
              marginBottom: "20px",
            }}
          >
            {/* Setor — select */}
            <div style={{ display: "flex", flexDirection: "column", gap: "5px" }}>
              <label
                htmlFor="f-setor"
                style={{ fontSize: "12px", color: "#555", fontWeight: 500 }}
              >
                Setor
              </label>
              <select
                id="f-setor"
                style={{
                  padding: "7px 10px",
                  border: "1px solid #ccc",
                  borderRadius: "5px",
                  fontSize: "14px",
                  minWidth: "180px",
                  background: "#fff",
                }}
                value={filtrosTemp.setor_id ?? ""}
                onChange={(e) =>
                  setFiltrosTemp({ ...filtrosTemp, setor_id: e.target.value || undefined })
                }
              >
                <option value="">Todos os setores</option>
                {setores.map((s) => (
                  <option key={s.id} value={s.id}>{s.nome}</option>
                ))}
              </select>
            </div>

            {/* Status */}
            <div style={{ display: "flex", flexDirection: "column", gap: "5px" }}>
              <label
                htmlFor="f-status"
                style={{ fontSize: "12px", color: "#555", fontWeight: 500 }}
              >
                Status
              </label>
              <select
                id="f-status"
                style={{
                  padding: "7px 10px",
                  border: "1px solid #ccc",
                  borderRadius: "5px",
                  fontSize: "14px",
                  background: "#fff",
                }}
                value={filtrosTemp.status_pa ?? ""}
                onChange={(e) =>
                  setFiltrosTemp({ ...filtrosTemp, status_pa: e.target.value || undefined })
                }
              >
                {STATUS_OPCOES.map(({ value, label }) => (
                  <option key={value} value={value}>{label}</option>
                ))}
              </select>
            </div>

            {/* Situação Certidão */}
            <div style={{ display: "flex", flexDirection: "column", gap: "5px" }}>
              <label
                htmlFor="f-cert"
                style={{ fontSize: "12px", color: "#555", fontWeight: 500 }}
              >
                Situação Certidão
              </label>
              <select
                id="f-cert"
                style={{
                  padding: "7px 10px",
                  border: "1px solid #ccc",
                  borderRadius: "5px",
                  fontSize: "14px",
                  background: "#fff",
                }}
                value={filtrosTemp.situacao_certidao ?? ""}
                onChange={(e) =>
                  setFiltrosTemp({ ...filtrosTemp, situacao_certidao: e.target.value || undefined })
                }
              >
                {CERT_OPCOES.map(({ value, label }) => (
                  <option key={value} value={value}>{label}</option>
                ))}
              </select>
            </div>

            <button
              type="submit"
              style={{
                display: "flex",
                alignItems: "center",
                gap: "7px",
                padding: "8px 18px",
                background: "#003087",
                color: "#fff",
                border: "none",
                borderRadius: "5px",
                cursor: "pointer",
                fontSize: "14px",
                fontWeight: 500,
              }}
            >
              <IconeLupa />
              Filtrar
            </button>
          </form>

          {/* Mensagem de erro */}
          {erro && (
            <p
              role="alert"
              style={{
                color: "#cc0000",
                padding: "12px 16px",
                background: "#fff0f0",
                borderRadius: "6px",
                marginBottom: "16px",
                border: "1px solid #ffcccc",
                fontSize: "14px",
              }}
            >
              {erro}
            </p>
          )}

          {/* Tabela */}
          <div
            style={{
              background: "#fff",
              borderRadius: "8px",
              boxShadow: "0 2px 12px rgba(0,0,0,0.08)",
              overflow: "hidden",
            }}
          >
            <table
              style={{
                width: "100%",
                borderCollapse: "collapse",
                fontSize: "14px",
              }}
            >
              <thead>
                <tr>
                  {["Código", "Setor", "Interessado", "Uso ACA", "CEPAC Total", "Status", "Situação Cert.", "Data", "Detalhes"].map(
                    (col) => (
                      <th
                        key={col}
                        style={{
                          background: "#003087",
                          color: "#fff",
                          fontSize: "12px",
                          fontWeight: 600,
                          letterSpacing: "0.5px",
                          textTransform: "uppercase",
                          padding: "12px 14px",
                          textAlign: "left",
                          whiteSpace: "nowrap",
                        }}
                      >
                        {col}
                      </th>
                    )
                  )}
                </tr>
              </thead>
              <tbody>
                {carregando ? (
                  <>
                    <SkeletonRow />
                    <SkeletonRow />
                    <SkeletonRow />
                    <SkeletonRow />
                    <SkeletonRow />
                  </>
                ) : items.length === 0 ? (
                  <tr>
                    <td colSpan={9}>
                      <div
                        style={{
                          display: "flex",
                          flexDirection: "column",
                          alignItems: "center",
                          padding: "48px 24px",
                          gap: "12px",
                        }}
                      >
                        <IconePastaVazia />
                        <span style={{ color: "#888", fontSize: "15px", fontWeight: 500 }}>
                          Nenhuma proposta encontrada
                        </span>
                        <span style={{ color: "#aaa", fontSize: "13px" }}>
                          Tente ajustar os filtros
                        </span>
                      </div>
                    </td>
                  </tr>
                ) : (
                  items.map((proposta) => {
                    const statusPA = proposta.status_pa as StatusPA;
                    return (
                      <tr
                        key={proposta.id}
                        style={{
                          background: hoveredRow === proposta.id ? "#f0f4ff" : "#fff",
                          transition: "background 0.1s",
                          cursor: "pointer",
                        }}
                        onMouseEnter={() => setHoveredRow(proposta.id)}
                        onMouseLeave={() => setHoveredRow(null)}
                        onClick={() => navigate(`/propostas/${proposta.codigo}`)}
                      >
                        {/* CÓDIGO */}
                        <td
                          style={{
                            padding: "11px 14px",
                            borderBottom: "1px solid #eee",
                            fontSize: "13px",
                            color: "#0066cc",
                            fontWeight: 600,
                            whiteSpace: "nowrap",
                          }}
                          onClick={(e) => {
                            e.stopPropagation();
                            navigate(`/propostas/${proposta.codigo}`);
                          }}
                        >
                          {proposta.codigo}
                        </td>
                        {/* SETOR */}
                        <td style={{ padding: "11px 14px", borderBottom: "1px solid #eee", fontSize: "13px", color: "#333" }}>
                          {proposta.setor}
                        </td>
                        {/* INTERESSADO */}
                        <td style={{ padding: "11px 14px", borderBottom: "1px solid #eee", fontSize: "13px", color: "#333" }}>
                          {proposta.interessado ?? "—"}
                        </td>
                        {/* USO ACA */}
                        <td style={{ padding: "11px 14px", borderBottom: "1px solid #eee", fontSize: "13px", color: "#333" }}>
                          {proposta.uso_aca ?? "—"}
                        </td>
                        {/* CEPAC TOTAL */}
                        <td style={{ padding: "11px 14px", borderBottom: "1px solid #eee", fontSize: "13px", color: "#333", textAlign: "right" }}>
                          {proposta.cepac_total !== null && proposta.cepac_total !== undefined
                            ? proposta.cepac_total.toLocaleString("pt-BR")
                            : "—"}
                        </td>
                        {/* STATUS */}
                        <td style={{ padding: "11px 14px", borderBottom: "1px solid #eee" }}>
                          <span
                            style={{
                              display: "inline-block",
                              borderRadius: "20px",
                              padding: "3px 10px",
                              background: STATUS_PILL_BG[statusPA] ?? "rgba(0,0,0,0.06)",
                              color: STATUS_PILL_COLOR[statusPA] ?? "#333",
                              fontSize: "12px",
                              fontWeight: 600,
                              whiteSpace: "nowrap",
                            }}
                          >
                            {STATUS_LABEL[statusPA] ?? proposta.status_pa}
                          </span>
                        </td>
                        {/* SITUAÇÃO CERT. */}
                        <td style={{ padding: "11px 14px", borderBottom: "1px solid #eee" }}>
                          {proposta.situacao_certidao ? (
                            <span
                              style={{
                                display: "inline-block",
                                borderRadius: "20px",
                                padding: "3px 10px",
                                background: CERT_PILL_BG[proposta.situacao_certidao as SituacaoCert] ?? "rgba(0,0,0,0.06)",
                                color: CERT_PILL_COLOR[proposta.situacao_certidao as SituacaoCert] ?? "#333",
                                fontSize: "12px",
                                fontWeight: 600,
                                whiteSpace: "nowrap",
                              }}
                            >
                              {CERT_LABEL[proposta.situacao_certidao as SituacaoCert] ?? proposta.situacao_certidao}
                            </span>
                          ) : (
                            <span style={{ color: "#aaa", fontSize: "12px" }}>—</span>
                          )}
                        </td>
                        {/* DATA */}
                        <td style={{ padding: "11px 14px", borderBottom: "1px solid #eee", fontSize: "13px", color: "#555", whiteSpace: "nowrap" }}>
                          {formatarData(proposta.data_proposta)}
                        </td>
                        {/* DETALHES */}
                        <td
                          style={{ padding: "11px 14px", borderBottom: "1px solid #eee" }}
                          onClick={(e) => e.stopPropagation()}
                        >
                          <button
                            title="Ver detalhes"
                            aria-label={`Ver detalhes da proposta ${proposta.codigo}`}
                            onClick={() => navigate(`/propostas/${proposta.codigo}`)}
                            style={{
                              background: "none",
                              border: "none",
                              cursor: "pointer",
                              padding: "4px",
                              display: "flex",
                              alignItems: "center",
                              borderRadius: "4px",
                            }}
                          >
                            <IconeOlho />
                          </button>
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>
        </div>

        {/* ------------------------------------------------------------------ */}
        {/* ZONA 4 — Rodapé com contagem e paginação                           */}
        {/* ------------------------------------------------------------------ */}
        <div
          style={{
            background: "#fff",
            borderTop: "2px solid #003087",
            padding: "12px 24px",
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
          }}
        >
          <span style={{ fontSize: "13px", color: "#555" }}>
            {total} proposta{total === 1 ? "" : "s"} encontrada{total === 1 ? "" : "s"}
          </span>
          <PaginacaoControle
            page={filtros.page ?? 1}
            totalPages={totalPages}
            disabled={carregando}
            onAnterior={() => setFiltros((f) => ({ ...f, page: (f.page ?? 1) - 1 }))}
            onProxima={() => setFiltros((f) => ({ ...f, page: (f.page ?? 1) + 1 }))}
          />
        </div>

      </div>
    </>
  );
}
