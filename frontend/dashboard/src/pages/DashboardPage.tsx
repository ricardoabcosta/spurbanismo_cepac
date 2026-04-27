/**
 * DashboardPage — página principal que monta todos os componentes.
 * Lê role do token MSAL para determinar se é DIRETOR.
 */
import React, { useState } from "react";
import { useMsal } from "@azure/msal-react";
import { useSnapshot } from "../hooks/useSnapshot";
import BigNumbers from "../components/BigNumbers";
import GraficoEstoqueSetores from "../components/GraficoEstoqueSetores";
import GraficoComposicaoACA from "../components/GraficoComposicaoACA";
import GraficoComposicaoNuvem from "../components/GraficoComposicaoNuvem";
import VelocimetroProzo from "../components/VelocimetroProzo";
import MapaAlertas from "../components/MapaAlertas";
import PainelCepac from "../components/PainelCepac";
import GraficosAnaliticos from "../components/GraficosAnaliticos";

/**
 * Extrai o papel do usuário a partir das claims do token MSAL.
 * A claim "roles" vem do App Role definido no Azure AD.
 */
const DEV_BYPASS = import.meta.env.VITE_DEV_BYPASS_AUTH === "true";

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
  const { isDiretor, nome } = useUserRole();
  const { instance } = useMsal();

  const { data, loading, error } = useSnapshot();

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

        {/* Toggle de navegação entre painéis */}
        <div style={{ display: "flex", gap: 8, marginBottom: 20 }}>
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

        {/* Painel CEPAC + Análises */}
        {painel === "cepacs" && (
          <>
            <PainelCepac />
            <GraficosAnaliticos />
          </>
        )}

        {/* Painel Estoque de Área */}
        {painel === "estoque" && (
          <>
            {/* Estado de carregamento */}
            {loading && (
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

                {/* Velocímetro + Alertas lado a lado */}
                <div style={{ display: "flex", gap: 16, flexWrap: "wrap", alignItems: "flex-start" }}>
                  <VelocimetroProzo
                    percentual={data.prazo_percentual_decorrido}
                    diasRestantes={data.prazo_dias_restantes}
                    zona={data.prazo_zona}
                  />
                  <MapaAlertas alertas={data.alertas} />
                </div>
              </>
            )}
          </>
        )}
      </main>
    </div>
  );
};

export default DashboardPage;
