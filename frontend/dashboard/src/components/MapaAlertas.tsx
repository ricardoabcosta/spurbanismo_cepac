/**
 * MapaAlertas — lista de alertas com ícones por tipo.
 * Vazio: exibe "Nenhuma trava ativa".
 */
import React from "react";
import type { AlertaSetorial } from "../types/api";

const ICONE: Record<string, string> = {
  TETO_NR_EXCEDIDO: "🔴",
  RESERVA_R_VIOLADA: "🟡",
};

interface Props {
  alertas: AlertaSetorial[];
}

const MapaAlertas: React.FC<Props> = ({ alertas }) => (
  <div
    style={{
      background: "#fff",
      borderRadius: 8,
      padding: "20px 16px",
      boxShadow: "0 1px 4px rgba(0,0,0,.10)",
      flex: "1 1 300px",
      minWidth: 280,
    }}
  >
    <h3 style={{ margin: "0 0 12px", fontSize: 16, color: "#1a1a2e" }}>
      Travas Ativas
    </h3>

    {alertas.length === 0 ? (
      <p style={{ margin: 0, color: "#34a853", fontWeight: 600, fontSize: 14 }}>
        ✅ Nenhuma trava ativa
      </p>
    ) : (
      <ul style={{ margin: 0, padding: 0, listStyle: "none" }}>
        {alertas.map((alerta, idx) => (
          <li
            key={idx}
            style={{
              padding: "10px 0",
              borderBottom: idx < alertas.length - 1 ? "1px solid #f0f0f0" : "none",
              display: "flex",
              gap: 10,
              alignItems: "flex-start",
            }}
          >
            <span style={{ fontSize: 18, lineHeight: 1.2 }}>
              {ICONE[alerta.tipo] ?? "⚠️"}
            </span>
            <div>
              <p style={{ margin: "0 0 2px", fontWeight: 600, fontSize: 14, color: "#1a1a2e" }}>
                {alerta.setor}
              </p>
              <p style={{ margin: 0, fontSize: 13, color: "#555" }}>
                {alerta.mensagem}
              </p>
              <span
                style={{
                  display: "inline-block",
                  marginTop: 4,
                  fontSize: 11,
                  color: alerta.tipo === "TETO_NR_EXCEDIDO" ? "#c62828" : "#e65100",
                  fontWeight: 600,
                  textTransform: "uppercase",
                  letterSpacing: ".4px",
                }}
              >
                {alerta.tipo.replace(/_/g, " ")}
              </span>
            </div>
          </li>
        ))}
      </ul>
    )}
  </div>
);

export default MapaAlertas;
