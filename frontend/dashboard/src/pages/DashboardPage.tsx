/**
 * DashboardPage — página principal que monta todos os componentes.
 * Lê role do token MSAL para determinar se é DIRETOR.
 */
import React, { useState } from "react";
import { useMsal } from "@azure/msal-react";
import { useSnapshot } from "../hooks/useSnapshot";
import BigNumbers from "../components/BigNumbers";
import GraficoOcupacao from "../components/GraficoOcupacao";
import VelocimetroProzo from "../components/VelocimetroProzo";
import MapaAlertas from "../components/MapaAlertas";
import SeletorData from "../components/SeletorData";

/**
 * Extrai o papel do usuário a partir das claims do token MSAL.
 * A claim "roles" vem do App Role definido no Azure AD.
 */
function useUserRole(): { isDiretor: boolean; nome: string } {
  const { accounts } = useMsal();
  const account = accounts[0];

  if (!account) return { isDiretor: false, nome: "" };

  // idTokenClaims pode conter roles do App Role
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

const DashboardPage: React.FC = () => {
  const [dataHistorica, setDataHistorica] = useState<string | undefined>(undefined);
  const { isDiretor, nome } = useUserRole();
  const { instance } = useMsal();

  const { data, loading, error } = useSnapshot(dataHistorica);

  const handleLogout = () => {
    instance.logoutRedirect().catch(console.error);
  };

  return (
    <div style={{ minHeight: "100vh", background: "#f4f5f7" }}>
      {/* Header */}
      <header
        style={{
          background: "#1a1a2e",
          color: "#fff",
          padding: "0 24px",
          height: 56,
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          boxShadow: "0 2px 4px rgba(0,0,0,.2)",
          position: "sticky",
          top: 0,
          zIndex: 100,
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
          <h1 style={{ margin: 0, fontSize: 18, fontWeight: 700, letterSpacing: ".3px" }}>
            CEPAC — Dashboard Executivo
          </h1>
          {isDiretor && (
            <span
              style={{
                fontSize: 11,
                background: "#1a73e8",
                color: "#fff",
                padding: "2px 8px",
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
            <span style={{ fontSize: 13, color: "#ccc" }}>{nome}</span>
          )}
          <button
            onClick={handleLogout}
            style={{
              background: "transparent",
              border: "1px solid rgba(255,255,255,.3)",
              color: "#fff",
              borderRadius: 4,
              padding: "4px 12px",
              fontSize: 13,
              cursor: "pointer",
            }}
          >
            Sair
          </button>
        </div>
      </header>

      {/* Main content */}
      <main style={{ padding: "24px", maxWidth: 1440, margin: "0 auto" }}>
        {/* Seletor de data (DIRETOR ou mensagem de acesso) */}
        <SeletorData
          isDiretor={isDiretor}
          dataHistorica={dataHistorica}
          onDataChange={setDataHistorica}
        />

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
              {!dataHistorica && (
                <span style={{ marginLeft: 8, color: "#34a853" }}>
                  • Atualização automática a cada 60s
                </span>
              )}
            </div>

            {/* Big Numbers */}
            <BigNumbers snapshot={data} />

            {/* Gráfico de Ocupação (largura total) */}
            <GraficoOcupacao setores={data.setores} />

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
      </main>
    </div>
  );
};

export default DashboardPage;
