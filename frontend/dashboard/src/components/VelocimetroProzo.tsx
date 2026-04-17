/**
 * VelocimetroProzo — Gauge semicircular com Recharts PieChart.
 * Exibe percentual decorrido, dias restantes e zona colorida (VERDE/AMARELO/VERMELHO).
 */
import React from "react";
import { PieChart, Pie, Cell } from "recharts";
import type { PrazoZona } from "../types/api";

const ZONA_COR: Record<PrazoZona, string> = {
  VERDE: "#34a853",
  AMARELO: "#fbbc04",
  VERMELHO: "#ea4335",
};

const ZONA_LABEL: Record<PrazoZona, string> = {
  VERDE: "Dentro do prazo",
  AMARELO: "Atenção ao prazo",
  VERMELHO: "Prazo crítico",
};

interface Props {
  percentual: number;
  diasRestantes: number;
  zona: PrazoZona;
}

const VelocimetroProzo: React.FC<Props> = ({ percentual, diasRestantes, zona }) => {
  const cor = ZONA_COR[zona];
  const label = ZONA_LABEL[zona];

  // Dados para gauge semicircular: preenchido + restante
  const preenchido = Math.min(Math.max(percentual, 0), 100);
  const vazio = 100 - preenchido;

  const pieData = [
    { name: "decorrido", value: preenchido },
    { name: "restante", value: vazio },
    // Metade inferior "morta" — hack para semicírculo
    { name: "morto", value: 100 },
  ];

  const formatPct = (v: number) =>
    new Intl.NumberFormat("pt-BR", { maximumFractionDigits: 1 }).format(v);

  const formatDias = (d: number) =>
    new Intl.NumberFormat("pt-BR").format(d);

  return (
    <div
      style={{
        background: "#fff",
        borderRadius: 8,
        padding: "20px 16px",
        boxShadow: "0 1px 4px rgba(0,0,0,.10)",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        minWidth: 260,
        flex: "0 0 auto",
      }}
    >
      <h3 style={{ margin: "0 0 8px", fontSize: 16, color: "#1a1a2e" }}>
        Velocímetro de Prazo OUCAE
      </h3>

      <div style={{ position: "relative", width: 220, height: 120, overflow: "hidden" }}>
        <PieChart width={220} height={220} style={{ marginTop: -10 }}>
          <Pie
            data={pieData}
            cx={110}
            cy={110}
            startAngle={180}
            endAngle={0}
            innerRadius={65}
            outerRadius={100}
            dataKey="value"
            stroke="none"
          >
            <Cell fill={cor} />
            <Cell fill="#e8eaed" />
            <Cell fill="transparent" />
          </Pie>
        </PieChart>
        {/* Texto central sobreposto */}
        <div
          style={{
            position: "absolute",
            bottom: 0,
            left: 0,
            right: 0,
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            paddingBottom: 4,
          }}
        >
          <span style={{ fontSize: 28, fontWeight: 700, color: cor, lineHeight: 1 }}>
            {formatPct(percentual)}%
          </span>
        </div>
      </div>

      <p style={{ margin: "8px 0 4px", fontSize: 14, color: "#555" }}>
        Prazo decorrido
      </p>
      <p style={{ margin: "0 0 8px", fontSize: 14, color: "#333", fontWeight: 600 }}>
        {formatDias(diasRestantes)} dias restantes
      </p>
      <span
        style={{
          display: "inline-block",
          padding: "4px 14px",
          borderRadius: 20,
          background: cor,
          color: "#fff",
          fontSize: 13,
          fontWeight: 700,
        }}
      >
        {label}
      </span>
    </div>
  );
};

export default VelocimetroProzo;
