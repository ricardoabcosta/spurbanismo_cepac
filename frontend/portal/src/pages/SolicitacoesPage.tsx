/**
 * Página /solicitacoes — listagem paginada com filtros e ações.
 */
import { useState, useEffect, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import { listarSolicitacoes, cancelarSolicitacao, isErroNegocioError } from "../api/portal";
import PaginacaoControle from "../components/PaginacaoControle";
import type { SolicitacaoOut, FiltrosSolicitacao } from "../types/api";

const STATUS_OPCOES = ["", "PENDENTE", "APROVADA", "REJEITADA", "CANCELADA", "EM_ANALISE"];
const USO_OPCOES = ["", "R", "NR"];
const ORIGEM_OPCOES = ["", "ACA", "NUVEM"];

const styles: Record<string, React.CSSProperties> = {
  pagina: { fontFamily: "system-ui, sans-serif", maxWidth: "1100px", margin: "0 auto", padding: "24px 16px" },
  cabecalho: { display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: "20px" },
  titulo: { fontSize: "22px", fontWeight: 700, color: "#003087" },
  botaoNovo: {
    padding: "9px 18px", background: "#003087", color: "#fff",
    border: "none", borderRadius: "5px", cursor: "pointer", fontSize: "14px",
  },
  filtros: {
    display: "flex", gap: "10px", flexWrap: "wrap" as const,
    marginBottom: "18px", alignItems: "flex-end",
  },
  grupo: { display: "flex", flexDirection: "column" as const, gap: "4px" },
  label: { fontSize: "12px", color: "#555" },
  select: { padding: "6px 10px", border: "1px solid #ccc", borderRadius: "4px", fontSize: "14px" },
  input: { padding: "6px 10px", border: "1px solid #ccc", borderRadius: "4px", fontSize: "14px", minWidth: "160px" },
  botaoFiltrar: {
    padding: "7px 14px", background: "#555", color: "#fff",
    border: "none", borderRadius: "4px", cursor: "pointer", fontSize: "14px",
  },
  tabela: { width: "100%", borderCollapse: "collapse" as const, fontSize: "14px" },
  th: { borderBottom: "2px solid #ccc", padding: "8px 10px", textAlign: "left" as const, background: "#f5f7fa", fontSize: "13px" },
  td: { borderBottom: "1px solid #eee", padding: "8px 10px", verticalAlign: "top" as const },
  status: { fontWeight: 600 },
  botaoCancelar: {
    padding: "4px 10px", background: "#cc0000", color: "#fff",
    border: "none", borderRadius: "4px", cursor: "pointer", fontSize: "12px",
  },
  botaoDetalhe: {
    padding: "4px 10px", background: "#0066cc", color: "#fff",
    border: "none", borderRadius: "4px", cursor: "pointer", fontSize: "12px",
  },
  mensagemErro: { color: "#cc0000", padding: "12px", background: "#fff0f0", borderRadius: "4px", marginBottom: "12px" },
  mensagemInfo: { color: "#555", padding: "20px", textAlign: "center" as const },
  acoes: { display: "flex", gap: "6px" },
  total: { fontSize: "13px", color: "#666", marginTop: "6px" },
};

function corStatus(status: string): string {
  switch (status) {
    case "PENDENTE": return "#b07d00";
    case "APROVADA": return "#007700";
    case "REJEITADA": return "#cc0000";
    case "CANCELADA": return "#888";
    case "EM_ANALISE": return "#0066cc";
    default: return "#333";
  }
}

export default function SolicitacoesPage() {
  const navigate = useNavigate();

  const [filtros, setFiltros] = useState<FiltrosSolicitacao>({ page: 1, page_size: 20 });
  const [filtrosTemp, setFiltrosTemp] = useState<FiltrosSolicitacao>({ page: 1, page_size: 20 });
  const [items, setItems] = useState<SolicitacaoOut[]>([]);
  const [total, setTotal] = useState(0);
  const [totalPages, setTotalPages] = useState(1);
  const [carregando, setCarregando] = useState(false);
  const [erro, setErro] = useState("");
  const [cancelando, setCancelando] = useState<string | null>(null);

  const carregar = useCallback(async (f: FiltrosSolicitacao) => {
    setCarregando(true);
    setErro("");
    try {
      const resp = await listarSolicitacoes(f);
      setItems(resp.items);
      setTotal(resp.total);
      setTotalPages(resp.total_pages);
    } catch {
      setErro("Falha ao carregar solicitações. Tente novamente.");
    } finally {
      setCarregando(false);
    }
  }, []);

  useEffect(() => {
    void carregar(filtros);
  }, [filtros, carregar]);

  function handleFiltrar(e: React.FormEvent) {
    e.preventDefault();
    const novos = { ...filtrosTemp, page: 1 };
    setFiltros(novos);
  }

  async function handleCancelar(id: string) {
    if (!confirm("Confirma o cancelamento desta solicitação?")) return;
    setCancelando(id);
    try {
      await cancelarSolicitacao(id);
      void carregar(filtros);
    } catch (e) {
      const msg = isErroNegocioError(e) ? e.erroNegocio.mensagem : "Erro ao cancelar solicitação.";
      alert(msg);
    } finally {
      setCancelando(null);
    }
  }

  function formatarData(iso: string) {
    return new Date(iso).toLocaleString("pt-BR", { dateStyle: "short", timeStyle: "short" });
  }

  return (
    <div style={styles.pagina}>
      <div style={styles.cabecalho}>
        <h1 style={styles.titulo}>Solicitações CEPAC</h1>
        <button style={styles.botaoNovo} onClick={() => navigate("/solicitacoes/nova")}>
          + Nova Solicitação
        </button>
      </div>

      {/* Filtros */}
      <form onSubmit={handleFiltrar} style={styles.filtros}>
        <div style={styles.grupo}>
          <label style={styles.label} htmlFor="f-setor">Setor</label>
          <input
            id="f-setor"
            style={styles.input}
            placeholder="Todos os setores"
            value={filtrosTemp.setor ?? ""}
            onChange={(e) => setFiltrosTemp({ ...filtrosTemp, setor: e.target.value || undefined })}
          />
        </div>
        <div style={styles.grupo}>
          <label style={styles.label} htmlFor="f-status">Status</label>
          <select
            id="f-status"
            style={styles.select}
            value={filtrosTemp.status ?? ""}
            onChange={(e) => setFiltrosTemp({ ...filtrosTemp, status: e.target.value || undefined })}
          >
            {STATUS_OPCOES.map((s) => (
              <option key={s} value={s}>{s || "Todos"}</option>
            ))}
          </select>
        </div>
        <div style={styles.grupo}>
          <label style={styles.label} htmlFor="f-uso">Uso</label>
          <select
            id="f-uso"
            style={styles.select}
            value={filtrosTemp.uso ?? ""}
            onChange={(e) => setFiltrosTemp({ ...filtrosTemp, uso: e.target.value || undefined })}
          >
            {USO_OPCOES.map((u) => (
              <option key={u} value={u}>{u || "Todos"}</option>
            ))}
          </select>
        </div>
        <div style={styles.grupo}>
          <label style={styles.label} htmlFor="f-origem">Origem</label>
          <select
            id="f-origem"
            style={styles.select}
            value={filtrosTemp.origem ?? ""}
            onChange={(e) => setFiltrosTemp({ ...filtrosTemp, origem: e.target.value || undefined })}
          >
            {ORIGEM_OPCOES.map((o) => (
              <option key={o} value={o}>{o || "Todas"}</option>
            ))}
          </select>
        </div>
        <button type="submit" style={styles.botaoFiltrar}>
          Filtrar
        </button>
      </form>

      {erro && <p style={styles.mensagemErro} role="alert">{erro}</p>}

      {carregando ? (
        <p style={styles.mensagemInfo}>Carregando…</p>
      ) : items.length === 0 ? (
        <p style={styles.mensagemInfo}>Nenhuma solicitação encontrada.</p>
      ) : (
        <>
          <p style={styles.total}>{total} solicitação(ões) encontrada(s)</p>
          <table style={styles.tabela}>
            <thead>
              <tr>
                <th style={styles.th}>SEI</th>
                <th style={styles.th}>Setor</th>
                <th style={styles.th}>Uso</th>
                <th style={styles.th}>Origem</th>
                <th style={styles.th}>Área m²</th>
                <th style={styles.th}>CEPACs</th>
                <th style={styles.th}>Status</th>
                <th style={styles.th}>Data</th>
                <th style={styles.th}>Ações</th>
              </tr>
            </thead>
            <tbody>
              {items.map((sol) => (
                <tr key={sol.id}>
                  <td style={styles.td}>{sol.numero_processo_sei}</td>
                  <td style={styles.td}>{sol.setor}</td>
                  <td style={styles.td}>{sol.uso}</td>
                  <td style={styles.td}>{sol.origem}</td>
                  <td style={styles.td}>{Number(sol.area_m2).toLocaleString("pt-BR", { minimumFractionDigits: 2 })}</td>
                  <td style={styles.td}>{sol.quantidade_cepacs}</td>
                  <td style={{ ...styles.td, ...styles.status, color: corStatus(sol.status) }}>
                    {sol.status}
                  </td>
                  <td style={styles.td}>{formatarData(sol.created_at)}</td>
                  <td style={styles.td}>
                    <div style={styles.acoes}>
                      <button
                        style={styles.botaoDetalhe}
                        onClick={() => navigate(`/solicitacoes/${sol.id}`)}
                      >
                        Detalhes
                      </button>
                      {sol.status === "PENDENTE" && (
                        <button
                          style={styles.botaoCancelar}
                          onClick={() => handleCancelar(sol.id)}
                          disabled={cancelando === sol.id}
                          aria-label={`Cancelar solicitação ${sol.numero_processo_sei}`}
                        >
                          {cancelando === sol.id ? "Cancelando…" : "Cancelar"}
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>

          <PaginacaoControle
            page={filtros.page ?? 1}
            totalPages={totalPages}
            disabled={carregando}
            onAnterior={() => setFiltros((f) => ({ ...f, page: (f.page ?? 1) - 1 }))}
            onProxima={() => setFiltros((f) => ({ ...f, page: (f.page ?? 1) + 1 }))}
          />
        </>
      )}
    </div>
  );
}
