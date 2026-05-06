/**
 * DashboardPage — página principal que monta todos os componentes.
 * Lê role do token MSAL para determinar se é DIRETOR.
 */
import React, { useState, useEffect } from "react";
import { useMsal } from "@azure/msal-react";
import { useSnapshot } from "../hooks/useSnapshot";
import { fetchOperacoesUrbanas } from "../api/dashboard";
import BigNumbers from "../components/BigNumbers";
import GraficoEstoqueSetores from "../components/GraficoEstoqueSetores";
import GraficoComposicaoACA from "../components/GraficoComposicaoACA";
import GraficoComposicaoNuvem from "../components/GraficoComposicaoNuvem";
import MapaAlertas from "../components/MapaAlertas";
import PainelCepac from "../components/PainelCepac";
import GraficosAnaliticos from "../components/GraficosAnaliticos";
import type { OperacaoUrbanaResumo } from "../types/api";

const DEV_BYPASS = import.meta.env.VITE_DEV_BYPASS_AUTH === "true";
const OUC_STORAGE_KEY = "cepac_ouc_dashboard";

function useUserRole(): { isDiretor: boolean; nome: string } {
  const { accounts } = useMsal();

  if (DEV_BYPASS) return { isDiretor: true, nome: "Dev Bypass (local)" };

  const account = accounts[0];
  if (!account) return { isDiretor: false, nome: "" };

  const claims = account.idTokenClaims as Record<string, unknown> | undefined;
  const roles = (claims?.roles as string[] | undefined) ?? [];
  const isDiretor = roles.includes("DIRETOR");
  const nome = (account.name ?? account.username) || "";

  return { isDiretor, nome };
}

const formatTimestamp = (iso: string): string => {
  try {
    return new Date(iso).toLocaleString("pt-BR");
  } catch {
    return iso;
  }
};

type Painel = "estoque" | "cepacs";

const DashboardPage: React.FC = () => {
  const [painel, setPainel] = useState<Painel>("estoque");
  const [modalTravasAberto, setModalTravasAberto] = useState(false);
  const { isDiretor, nome } = useUserRole();
  const { instance } = useMsal();

  // Operações Urbanas disponíveis
  const [oucs, setOucs] = useState<OperacaoUrbanaResumo[]>([]);
  // null = ainda não inicializado (aguardando lista de OUCs)
  const [selectedOucId, setSelectedOucId] = useState<number | null>(null);

  useEffect(() => {
    fetchOperacoesUrbanas()
      .then((lista) => {
        setOucs(lista);
        // Restaura a última OUC salva, ou usa a primeira da lista
        const saved = localStorage.getItem(OUC_STORAGE_KEY);
        const savedId = saved ? parseInt(saved, 10) : NaN;
        const valid = lista.find((o) => o.id === savedId);
        setSelectedOucId(valid ? valid.id : (lista[0]?.id ?? null));
      })
      .catch(console.error);
  }, []);

  const handleOucChange = (id: number) => {
    setSelectedOucId(id);
    localStorage.setItem(OUC_STORAGE_KEY, String(id));
  };

  const { data, loading, error } = useSnapshot(undefined, selectedOucId);

  const handleLogout = () => {
    instance.logoutRedirect().catch(console.error);
  };

  return (
    <div style={{ minHeight: "100vh", background: "#f4f5f7" }}>
      {/* Cabeçalho */}
      <header
        style={{
          background: "linear-gradient(90deg, #0B2A4A 0%, #0F3A6D 55%, #145DA0 85%, #1C6ED5 100%)",
          color: "#fff",
          padding: "0 28px",
          height: 88,
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          boxShadow: "0 2px 8px rgba(0,0,0,.3)",
          position: "sticky",
          top: 0,
          zIndex: 100,
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
          <img
            src="/imagens/logobranco.svg"
            alt="ZENITE"
            style={{ height: 82, width: "auto", display: "block" }}
          />
          <div style={{ width: 1, height: 40, background: "rgba(255,255,255,0.25)", flexShrink: 0 }} />
          <span style={{ fontSize: 15, color: "rgba(255,255,255,0.9)", fontWeight: 700, letterSpacing: "0.03em", whiteSpace: "nowrap" }}>
            Dashboard Executivo
          </span>
          {isDiretor && (
            <span
              style={{
                fontSize: 11,
                background: "rgba(26,115,232,0.85)",
                color: "#fff",
                padding: "3px 10px",
                borderRadius: 10,
                fontWeight: 700,
                letterSpacing: ".4px",
              }}
            >
              DIRETOR
            </span>
          )}
        </div>

        {/* Centro: Seletor de OUC */}
        {oucs.length > 0 && (
          <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
            <span style={{ fontSize: 12, color: "rgba(255,255,255,0.65)", fontWeight: 600, whiteSpace: "nowrap" }}>
              Operação Urbana:
            </span>
            <div style={{ display: "flex", gap: 6 }}>
              {oucs.map((ouc) => (
                <button
                  key={ouc.id}
                  onClick={() => handleOucChange(ouc.id)}
                  title={ouc.nome}
                  style={{
                    padding: "6px 14px",
                    borderRadius: 6,
                    border: selectedOucId === ouc.id
                      ? "2px solid rgba(255,255,255,0.9)"
                      : "1px solid rgba(255,255,255,0.3)",
                    background: selectedOucId === ouc.id
                      ? "rgba(255,255,255,0.18)"
                      : "transparent",
                    color: "#fff",
                    fontWeight: selectedOucId === ouc.id ? 700 : 400,
                    fontSize: 13,
                    cursor: "pointer",
                    transition: "all .15s",
                    whiteSpace: "nowrap",
                  }}
                  onMouseEnter={(e) => {
                    if (selectedOucId !== ouc.id)
                      e.currentTarget.style.background = "rgba(255,255,255,0.1)";
                  }}
                  onMouseLeave={(e) => {
                    if (selectedOucId !== ouc.id)
                      e.currentTarget.style.background = "transparent";
                  }}
                >
                  {ouc.sigla}
                </button>
              ))}
            </div>
          </div>
        )}

        <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
          {nome && (
            <span style={{ fontSize: 15, color: "rgba(255,255,255,0.85)", fontWeight: 600 }}>{nome}</span>
          )}
          <button
            onClick={handleLogout}
            style={{
              background: "transparent",
              border: "1px solid rgba(255,255,255,.3)",
              color: "#fff",
              borderRadius: 5,
              padding: "7px 16px",
              fontSize: 15,
              fontWeight: 600,
              cursor: "pointer",
              transition: "background 0.15s",
            }}
            onMouseEnter={(e) => { e.currentTarget.style.background = "rgba(255,255,255,0.12)"; }}
            onMouseLeave={(e) => { e.currentTarget.style.background = "transparent"; }}
          >
            Sair
          </button>
        </div>
      </header>

      {/* Main content */}
      <main style={{ padding: "24px", maxWidth: 1440, margin: "0 auto" }}>

        {/* Toggle de navegação entre painéis + sino de travas */}
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 20 }}>
          <div style={{ display: "flex", gap: 8 }}>
            {(["estoque", "cepacs"] as Painel[]).map((p) => (
              <button
                key={p}
                onClick={() => setPainel(p)}
                style={{
                  padding: "7px 20px",
                  borderRadius: 6,
                  border: painel === p ? "none" : "1px solid #ccc",
                  background: painel === p ? "#1a1a2e" : "#fff",
                  color: painel === p ? "#fff" : "#555",
                  fontWeight: painel === p ? 700 : 400,
                  fontSize: 13,
                  cursor: "pointer",
                  transition: "all .15s",
                }}
              >
                {p === "estoque" ? "Estoque de Área" : "CEPACs"}
              </button>
            ))}
          </div>

          {/* Sino de Travas Ativas */}
          {(() => {
            const alertas = data?.alertas ?? [];
            const hasRed = alertas.some(a => a.tipo === "TETO_NR_EXCEDIDO" || a.tipo === "RESERVA_R_VIOLADA");
            const sinoCor = alertas.length === 0 ? "#555" : hasRed ? "#E24B4A" : "#EF9F27";
            return (
              <button
                onClick={() => setModalTravasAberto(true)}
                title="Travas Ativas"
                style={{
                  position: "relative",
                  background: "transparent",
                  border: "none",
                  cursor: "pointer",
                  padding: 6,
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  borderRadius: 6,
                }}
                onMouseEnter={(e) => { e.currentTarget.style.background = "rgba(0,0,0,0.06)"; }}
                onMouseLeave={(e) => { e.currentTarget.style.background = "transparent"; }}
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  width="22"
                  height="22"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke={sinoCor}
                  strokeWidth="2"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                >
                  <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" />
                  <path d="M13.73 21a2 2 0 0 1-3.46 0" />
                </svg>
                {alertas.length > 0 && (
                  <span
                    style={{
                      position: "absolute",
                      top: 2,
                      right: 2,
                      background: sinoCor,
                      color: "#fff",
                      borderRadius: "50%",
                      fontSize: 10,
                      minWidth: 16,
                      height: 16,
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      fontWeight: 700,
                      lineHeight: 1,
                      padding: "0 3px",
                    }}
                  >
                    {alertas.length}
                  </span>
                )}
              </button>
            );
          })()}
        </div>

        {/* Modal de Travas Ativas */}
        {modalTravasAberto && (
          <div
            style={{
              position: "fixed",
              inset: 0,
              background: "rgba(0,0,0,0.4)",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              zIndex: 1000,
            }}
            onClick={(e) => { if (e.target === e.currentTarget) setModalTravasAberto(false); }}
          >
            <div
              style={{
                background: "#fff",
                borderRadius: 8,
                padding: "28px",
                width: 480,
                maxWidth: "90vw",
                maxHeight: "80vh",
                overflowY: "auto",
                position: "relative",
                boxShadow: "0 8px 32px rgba(0,0,0,0.18)",
              }}
            >
              <button
                onClick={() => setModalTravasAberto(false)}
                style={{
                  position: "absolute",
                  top: 12,
                  right: 14,
                  background: "transparent",
                  border: "none",
                  fontSize: 22,
                  lineHeight: 1,
                  cursor: "pointer",
                  color: "#888",
                  fontWeight: 300,
                }}
                onMouseEnter={(e) => { e.currentTarget.style.color = "#333"; }}
                onMouseLeave={(e) => { e.currentTarget.style.color = "#888"; }}
              >
                ×
              </button>
              {data ? (
                <MapaAlertas alertas={data.alertas} />
              ) : (
                <p style={{ color: "#888", fontSize: 14, margin: 0 }}>Carregando dados…</p>
              )}
            </div>
          </div>
        )}

        {/* Painel CEPAC + Análises */}
        {painel === "cepacs" && (
          <>
            <PainelCepac oucId={selectedOucId ?? undefined} />
            <GraficosAnaliticos oucId={selectedOucId ?? undefined} />
          </>
        )}

        {/* Painel Estoque de Área */}
        {painel === "estoque" && (
          <>
            {/* Aguardando seleção de OUC */}
            {selectedOucId === null && (
              <div
                style={{
                  display: "flex",
                  justifyContent: "center",
                  padding: "48px 0",
                  color: "#666",
                }}
              >
                <p>Carregando lista de Operações Urbanas…</p>
              </div>
            )}

            {/* Estado de carregamento */}
            {selectedOucId !== null && loading && (
              <div
                style={{
                  display: "flex",
                  justifyContent: "center",
                  padding: "48px 0",
                  color: "#666",
                }}
              >
                <p>Carregando dados do dashboard...</p>
              </div>
            )}

            {/* Erro */}
            {error && (
              <div
                style={{
                  background: "#ffebee",
                  border: "1px solid #ef9a9a",
                  borderRadius: 6,
                  padding: "12px 16px",
                  marginBottom: 16,
                  color: "#c62828",
                  fontSize: 14,
                }}
              >
                {error}
              </div>
            )}

            {/* Dados carregados */}
            {data && (
              <>
                {/* Timestamp */}
                <div style={{ marginBottom: 16, fontSize: 12, color: "#888" }}>
                  Atualizado em {formatTimestamp(data.gerado_em)}
                  <span style={{ marginLeft: 8, color: "#34a853" }}>
                    • Atualização automática a cada 60s
                  </span>
                </div>

                {/* Big Numbers */}
                <BigNumbers snapshot={data} />

                {/* Gráfico de Estoque por Setor (largura total) */}
                <GraficoEstoqueSetores setores={data.setores} />

                {/* Composição ACA por setor */}
                <GraficoComposicaoACA setores={data.setores} />

                {/* Composição NUVEM por setor */}
                <GraficoComposicaoNuvem setores={data.setores} />

              </>
            )}
          </>
        )}
      </main>
    </div>
  );
};

export default DashboardPage;
