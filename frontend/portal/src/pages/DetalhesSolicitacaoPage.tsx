/**
 * Página /solicitacoes/:id — detalhes completos da solicitação + lote de títulos.
 */
import { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { buscarSolicitacao, cancelarSolicitacao, isErroNegocioError } from "../api/portal";
import type { SolicitacaoDetalhe } from "../types/api";

const styles: Record<string, React.CSSProperties> = {
  pagina: { fontFamily: "system-ui, sans-serif", maxWidth: "900px", margin: "0 auto", padding: "24px 16px" },
  voltar: {
    display: "inline-block", marginBottom: "16px",
    color: "#0066cc", cursor: "pointer", fontSize: "14px",
    background: "none", border: "none", padding: 0,
  },
  titulo: { fontSize: "22px", fontWeight: 700, color: "#003087", marginBottom: "20px" },
  grade: {
    display: "grid", gridTemplateColumns: "1fr 1fr",
    gap: "12px 24px", marginBottom: "24px",
  },
  campo: { display: "flex", flexDirection: "column" as const, gap: "2px" },
  campoLabel: { fontSize: "12px", color: "#666", textTransform: "uppercase" as const, letterSpacing: "0.05em" },
  campoValor: { fontSize: "15px", fontWeight: 500, color: "#222" },
  statusBadge: {
    display: "inline-block", padding: "3px 10px",
    borderRadius: "12px", fontSize: "13px", fontWeight: 600,
  },
  secaoTitulos: { marginTop: "24px" },
  secaoTitulosTitulo: { fontSize: "16px", fontWeight: 600, marginBottom: "12px", color: "#333" },
  tabela: { width: "100%", borderCollapse: "collapse" as const, fontSize: "13px" },
  th: { borderBottom: "2px solid #ccc", padding: "8px 10px", textAlign: "left" as const, background: "#f5f7fa" },
  td: { borderBottom: "1px solid #eee", padding: "8px 10px" },
  obs: { background: "#f9f9f9", padding: "12px", borderRadius: "4px", fontSize: "14px", marginTop: "12px", borderLeft: "3px solid #ccc" },
  motivo: { background: "#fff0f0", padding: "12px", borderRadius: "4px", fontSize: "14px", marginTop: "12px", borderLeft: "3px solid #cc0000", color: "#cc0000" },
  botaoCancelar: {
    marginTop: "24px", padding: "9px 18px", background: "#cc0000", color: "#fff",
    border: "none", borderRadius: "5px", cursor: "pointer", fontSize: "14px",
  },
  erro: { color: "#cc0000", background: "#fff0f0", padding: "12px", borderRadius: "4px", marginBottom: "16px" },
  carregando: { padding: "40px", textAlign: "center" as const, color: "#666" },
  naoEncontrado: { padding: "40px", textAlign: "center" as const, color: "#888" },
};

function corStatus(status: string): { background: string; color: string } {
  switch (status) {
    case "PENDENTE": return { background: "#fff3cd", color: "#856404" };
    case "APROVADA": return { background: "#d4edda", color: "#155724" };
    case "REJEITADA": return { background: "#f8d7da", color: "#721c24" };
    case "CANCELADA": return { background: "#e2e3e5", color: "#555" };
    case "EM_ANALISE": return { background: "#cce5ff", color: "#004085" };
    default: return { background: "#eee", color: "#333" };
  }
}

function formatarData(iso: string) {
  return new Date(iso).toLocaleString("pt-BR", { dateStyle: "long", timeStyle: "short" });
}

function formatarDecimal(v: string) {
  return Number(v).toLocaleString("pt-BR", { minimumFractionDigits: 2 });
}

export default function DetalhesSolicitacaoPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();

  const [solicitacao, setSolicitacao] = useState<SolicitacaoDetalhe | null>(null);
  const [carregando, setCarregando] = useState(true);
  const [erro, setErro] = useState("");
  const [cancelando, setCancelando] = useState(false);
  const [erroCancelamento, setErroCancelamento] = useState("");

  useEffect(() => {
    if (!id) return;
    void (async () => {
      setCarregando(true);
      try {
        const dados = await buscarSolicitacao(id);
        setSolicitacao(dados);
      } catch {
        setErro("Não foi possível carregar a solicitação.");
      } finally {
        setCarregando(false);
      }
    })();
  }, [id]);

  async function handleCancelar() {
    if (!solicitacao || !confirm("Confirma o cancelamento desta solicitação?")) return;
    setCancelando(true);
    setErroCancelamento("");
    try {
      const atualizada = await cancelarSolicitacao(solicitacao.id);
      setSolicitacao((prev) => prev ? { ...prev, status: atualizada.status } : null);
    } catch (e) {
      const msg = isErroNegocioError(e) ? e.erroNegocio.mensagem : "Erro ao cancelar a solicitação.";
      setErroCancelamento(msg);
    } finally {
      setCancelando(false);
    }
  }

  if (carregando) return <div style={styles.carregando}>Carregando…</div>;
  if (erro) return <div style={styles.naoEncontrado}>{erro}</div>;
  if (!solicitacao) return <div style={styles.naoEncontrado}>Solicitação não encontrada.</div>;

  const statusCores = corStatus(solicitacao.status);

  return (
    <div style={styles.pagina}>
      <button style={styles.voltar} onClick={() => navigate("/solicitacoes")}>
        ← Voltar à listagem
      </button>

      <h1 style={styles.titulo}>Detalhes da Solicitação</h1>

      {erroCancelamento && (
        <p role="alert" style={styles.erro}>{erroCancelamento}</p>
      )}

      {/* Grade de dados */}
      <div style={styles.grade}>
        <div style={styles.campo}>
          <span style={styles.campoLabel}>Status</span>
          <span>
            <span style={{ ...styles.statusBadge, ...statusCores }}>{solicitacao.status}</span>
          </span>
        </div>
        <div style={styles.campo}>
          <span style={styles.campoLabel}>Número SEI</span>
          <span style={styles.campoValor}>{solicitacao.numero_processo_sei}</span>
        </div>
        <div style={styles.campo}>
          <span style={styles.campoLabel}>Setor</span>
          <span style={styles.campoValor}>{solicitacao.setor}</span>
        </div>
        <div style={styles.campo}>
          <span style={styles.campoLabel}>Uso</span>
          <span style={styles.campoValor}>{solicitacao.uso === "R" ? "R — Residencial" : "NR — Não-Residencial"}</span>
        </div>
        <div style={styles.campo}>
          <span style={styles.campoLabel}>Origem</span>
          <span style={styles.campoValor}>{solicitacao.origem}</span>
        </div>
        <div style={styles.campo}>
          <span style={styles.campoLabel}>Área (m²)</span>
          <span style={styles.campoValor}>{formatarDecimal(solicitacao.area_m2)}</span>
        </div>
        <div style={styles.campo}>
          <span style={styles.campoLabel}>Quantidade de CEPACs</span>
          <span style={styles.campoValor}>{solicitacao.quantidade_cepacs}</span>
        </div>
        <div style={styles.campo}>
          <span style={styles.campoLabel}>Data de criação</span>
          <span style={styles.campoValor}>{formatarData(solicitacao.created_at)}</span>
        </div>
        {solicitacao.proposta_codigo && (
          <div style={styles.campo}>
            <span style={styles.campoLabel}>Proposta</span>
            <span style={styles.campoValor}>{solicitacao.proposta_codigo}</span>
          </div>
        )}
      </div>

      {solicitacao.observacao && (
        <div style={styles.obs}>
          <strong>Observação:</strong> {solicitacao.observacao}
        </div>
      )}

      {solicitacao.motivo_rejeicao && (
        <div style={styles.motivo}>
          <strong>Motivo da rejeição:</strong> {solicitacao.motivo_rejeicao}
        </div>
      )}

      {/* Lote de títulos */}
      <div style={styles.secaoTitulos}>
        <h2 style={styles.secaoTitulosTitulo}>
          Lote de Títulos ({solicitacao.titulos.length})
        </h2>

        {solicitacao.titulos.length === 0 ? (
          <p style={{ color: "#888", fontSize: "14px" }}>Nenhum título vinculado.</p>
        ) : (
          <table style={styles.tabela}>
            <thead>
              <tr>
                <th style={styles.th}>Código</th>
                <th style={styles.th}>Setor</th>
                <th style={styles.th}>Uso</th>
                <th style={styles.th}>Origem</th>
                <th style={styles.th}>Estado</th>
                <th style={styles.th}>Valor (R$/m²)</th>
                <th style={styles.th}>Área Contribuição (m²)</th>
              </tr>
            </thead>
            <tbody>
              {solicitacao.titulos.map((t) => (
                <tr key={t.id}>
                  <td style={styles.td}>{t.codigo}</td>
                  <td style={styles.td}>{t.setor}</td>
                  <td style={styles.td}>{t.uso}</td>
                  <td style={styles.td}>{t.origem}</td>
                  <td style={styles.td}>{t.estado}</td>
                  <td style={styles.td}>{formatarDecimal(t.valor_m2)}</td>
                  <td style={styles.td}>{formatarDecimal(t.area_m2_contribuicao)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {/* Botão cancelar (só para PENDENTE) */}
      {solicitacao.status === "PENDENTE" && (
        <button
          style={styles.botaoCancelar}
          onClick={handleCancelar}
          disabled={cancelando}
          aria-label="Cancelar esta solicitação"
        >
          {cancelando ? "Cancelando…" : "Cancelar Solicitação"}
        </button>
      )}
    </div>
  );
}
