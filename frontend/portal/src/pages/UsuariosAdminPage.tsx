import { useState, useEffect, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import { listarUsuarios, alterarPapel, alterarAtivo } from "../api/admin";
import { useUser } from "../contexts/UserContext";
import type { PapelUsuario, UsuarioOut } from "../types/api";

const estilos: Record<string, React.CSSProperties> = {
  pagina: { fontFamily: "system-ui, sans-serif", minHeight: "100vh", background: "#f5f7fa" },
  conteudo: { maxWidth: "960px", margin: "0 auto", padding: "28px 16px" },
  tabela: { width: "100%", borderCollapse: "collapse" as const, fontSize: "13px" },
  th: { textAlign: "left" as const, padding: "10px 12px", background: "#003087", color: "#fff", fontWeight: 600 },
  td: { padding: "10px 12px", borderBottom: "1px solid #e8e8e8", verticalAlign: "middle" as const },
  tdInativo: { padding: "10px 12px", borderBottom: "1px solid #e8e8e8", verticalAlign: "middle" as const, color: "#aaa" },
  erro: { color: "#cc0000", background: "#fff0f0", padding: "12px", borderRadius: "4px", marginBottom: "16px" },
  badge: { display: "inline-block", padding: "2px 8px", borderRadius: "10px", fontSize: "11px", fontWeight: 600 },
  badgeDiretor: { background: "#e8f0fe", color: "#1a56db" },
  badgeTecnico: { background: "#f0f4f8", color: "#4a5568" },
  badgeAtivo: { background: "#e6f4ea", color: "#1a7a2e" },
  badgeInativo: { background: "#f5f5f5", color: "#888" },
  select: { padding: "4px 8px", border: "1px solid #ccc", borderRadius: "4px", fontSize: "12px", cursor: "pointer", background: "#fff" },
  selectDisabled: { padding: "4px 8px", border: "1px solid #e0e0e0", borderRadius: "4px", fontSize: "12px", cursor: "not-allowed", background: "#f5f5f5", color: "#aaa" },
  toggle: { position: "relative" as const, display: "inline-block", width: 36, height: 20, flexShrink: 0, cursor: "pointer" },
  toggleDisabled: { position: "relative" as const, display: "inline-block", width: 36, height: 20, flexShrink: 0, cursor: "not-allowed", opacity: 0.4 },
  carregando: { color: "#666", fontStyle: "italic", padding: "24px" },
};

function Toggle({ ativo, disabled, onChange }: { ativo: boolean; disabled: boolean; onChange: () => void }) {
  return (
    <label
      style={disabled ? estilos.toggleDisabled : estilos.toggle}
      title={disabled ? "Não é possível alterar o próprio status" : ativo ? "Desativar" : "Ativar"}
    >
      <input
        type="checkbox"
        checked={ativo}
        disabled={disabled}
        onChange={onChange}
        style={{ opacity: 0, width: 0, height: 0, position: "absolute" }}
      />
      <span
        style={{
          position: "absolute",
          inset: 0,
          borderRadius: 20,
          background: ativo ? "#1a7a2e" : "#ccc",
          transition: "background 0.2s",
        }}
      />
      <span
        style={{
          position: "absolute",
          top: 2,
          left: ativo ? 18 : 2,
          width: 16,
          height: 16,
          borderRadius: "50%",
          background: "#fff",
          transition: "left 0.2s",
          boxShadow: "0 1px 3px rgba(0,0,0,0.25)",
        }}
      />
    </label>
  );
}

function formatarDataHora(iso: string | null): string {
  if (!iso) return "—";
  return new Date(iso).toLocaleString("pt-BR", {
    day: "2-digit", month: "2-digit", year: "numeric",
    hour: "2-digit", minute: "2-digit",
  });
}

export default function UsuariosAdminPage() {
  const navigate = useNavigate();
  const { usuario: euMesmo } = useUser();
  const [usuarios, setUsuarios] = useState<UsuarioOut[]>([]);
  const [carregando, setCarregando] = useState(true);
  const [erro, setErro] = useState("");
  const [salvandoId, setSalvandoId] = useState<string | null>(null);
  const [erroInline, setErroInline] = useState<Record<string, string>>({});
  const [hoveredVoltar, setHoveredVoltar] = useState(false);

  const carregar = useCallback(async () => {
    setCarregando(true);
    setErro("");
    try {
      const data = await listarUsuarios();
      setUsuarios(data);
    } catch {
      setErro("Erro ao carregar usuários. Verifique a conexão com a API.");
    } finally {
      setCarregando(false);
    }
  }, []);

  useEffect(() => { void carregar(); }, [carregar]);

  async function handlePapel(id: string, papel: PapelUsuario) {
    setSalvandoId(id);
    setErroInline((prev) => ({ ...prev, [id]: "" }));
    try {
      const atualizado = await alterarPapel(id, papel);
      setUsuarios((prev) => prev.map((u) => (u.id === id ? atualizado : u)));
    } catch {
      setErroInline((prev) => ({ ...prev, [id]: "Falha ao alterar perfil." }));
    } finally {
      setSalvandoId(null);
    }
  }

  async function handleAtivo(id: string, ativo: boolean) {
    setSalvandoId(id);
    setErroInline((prev) => ({ ...prev, [id]: "" }));
    try {
      const atualizado = await alterarAtivo(id, ativo);
      setUsuarios((prev) => prev.map((u) => (u.id === id ? atualizado : u)));
    } catch {
      setErroInline((prev) => ({ ...prev, [id]: "Falha ao alterar status." }));
    } finally {
      setSalvandoId(null);
    }
  }

  return (
    <div style={estilos.pagina}>
      {/* Cabeçalho */}
      <div style={{ background: "linear-gradient(90deg, #0B2A4A 0%, #0F3A6D 55%, #145DA0 85%, #1C6ED5 100%)" }}>
        <div
          style={{
            display: "flex", alignItems: "center", justifyContent: "space-between",
            padding: "0 28px", height: 88,
          }}
        >
          <div style={{ display: "flex", flexDirection: "row", alignItems: "center", gap: 16 }}>
            <img src="/imagens/logobranco.svg" alt="ZENITE" style={{ height: 82, width: "auto", display: "block" }} />
            <div style={{ width: 1, height: 40, background: "rgba(255,255,255,0.25)", flexShrink: 0 }} />
            <span style={{ fontSize: 15, color: "rgba(255,255,255,0.9)", fontWeight: 700, letterSpacing: "0.03em", whiteSpace: "nowrap" }}>
              Gerenciamento de Usuários
            </span>
          </div>
          <button
            style={{
              background: hoveredVoltar ? "rgba(255,255,255,0.12)" : "transparent",
              border: "1px solid rgba(255,255,255,0.3)",
              color: "#fff", borderRadius: 5, cursor: "pointer",
              fontSize: 15, fontWeight: 600, padding: "7px 16px",
              transition: "background 0.15s",
            }}
            onMouseEnter={() => setHoveredVoltar(true)}
            onMouseLeave={() => setHoveredVoltar(false)}
            onClick={() => navigate("/propostas")}
          >
            ← Voltar
          </button>
        </div>
      </div>

      <div style={estilos.conteudo}>
        {erro && <p role="alert" style={estilos.erro}>{erro}</p>}

        <div style={{ background: "#fff", borderRadius: "8px", boxShadow: "0 2px 12px rgba(0,0,0,0.07)", overflow: "hidden" }}>
          {carregando ? (
            <p style={estilos.carregando}>Carregando usuários…</p>
          ) : (
            <table style={estilos.tabela}>
              <thead>
                <tr>
                  <th style={estilos.th}>Nome</th>
                  <th style={estilos.th}>E-mail (UPN)</th>
                  <th style={estilos.th}>Perfil</th>
                  <th style={estilos.th}>Ativo</th>
                  <th style={estilos.th}>Último acesso</th>
                </tr>
              </thead>
              <tbody>
                {usuarios.length === 0 && (
                  <tr>
                    <td colSpan={5} style={{ ...estilos.td, textAlign: "center", color: "#888", padding: "32px" }}>
                      Nenhum usuário registrado.
                    </td>
                  </tr>
                )}
                {usuarios.map((u) => {
                  const ehEuMesmo = euMesmo?.id === u.id;
                  const salvando = salvandoId === u.id;
                  const tdStyle = u.ativo ? estilos.td : estilos.tdInativo;

                  return (
                    <tr key={u.id}>
                      <td style={tdStyle}>
                        <strong>{u.nome ?? "—"}</strong>
                        {ehEuMesmo && (
                          <span style={{ marginLeft: 6, fontSize: 10, background: "#e8f0fe", color: "#1a56db", borderRadius: 4, padding: "1px 5px", fontWeight: 600 }}>
                            você
                          </span>
                        )}
                      </td>
                      <td style={{ ...tdStyle, fontFamily: "monospace", fontSize: 12 }}>{u.upn}</td>
                      <td style={tdStyle}>
                        <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                          <select
                            value={u.papel}
                            disabled={ehEuMesmo || salvando}
                            style={ehEuMesmo || salvando ? estilos.selectDisabled : estilos.select}
                            title={ehEuMesmo ? "Não é possível alterar o próprio perfil" : undefined}
                            onChange={(e) => void handlePapel(u.id, e.target.value as PapelUsuario)}
                          >
                            <option value="TECNICO">Técnico</option>
                            <option value="DIRETOR">Diretor</option>
                          </select>
                          {salvando && (
                            <span style={{ fontSize: 11, color: "#888" }}>…</span>
                          )}
                        </div>
                        {erroInline[u.id] && (
                          <span style={{ fontSize: 11, color: "#cc0000", display: "block", marginTop: 2 }}>
                            {erroInline[u.id]}
                          </span>
                        )}
                      </td>
                      <td style={tdStyle}>
                        <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                          <Toggle
                            ativo={u.ativo}
                            disabled={ehEuMesmo || salvando}
                            onChange={() => void handleAtivo(u.id, !u.ativo)}
                          />
                          <span style={{ ...estilos.badge, ...(u.ativo ? estilos.badgeAtivo : estilos.badgeInativo) }}>
                            {u.ativo ? "Ativo" : "Inativo"}
                          </span>
                        </div>
                      </td>
                      <td style={{ ...tdStyle, fontSize: 12, color: u.ativo ? "#555" : "#aaa" }}>
                        {formatarDataHora(u.last_login_at)}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          )}
        </div>

        <p style={{ marginTop: 16, fontSize: 12, color: "#888" }}>
          Usuários são criados automaticamente no primeiro login via Azure AD.
          Apenas diretores podem alterar perfis e status.
        </p>
      </div>
    </div>
  );
}
