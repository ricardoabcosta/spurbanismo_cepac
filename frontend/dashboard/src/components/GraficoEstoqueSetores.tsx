/**
 * GraficoEstoqueSetores — Visão comparativa R vs NR por setor.
 * Parte 1: BarChart agrupado R/NR com consumo, disponível e estouro.
 * Parte 2: Cards detalhados por setor com gauges de progresso.
 * Clique numa barra ou card para destacar/des-destacar o setor.
 */
import React, { useState } from "react";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Cell,
} from "recharts";
import type { OcupacaoSetor } from "../types/api";

interface Props {
  setores: OcupacaoSetor[];
}

interface Derivados {
  maxNR: number;
  maxR: number;
  consR: number;
  consNR: number;
  analR: number;
  analNR: number;
  dispR: number;
  dispNR: number;
  overNR: number;
  pctR: number;
  pctNR: number;
}

function calcDerivados(s: OcupacaoSetor): Derivados {
  const maxNR = parseFloat(s.teto_nr ?? "0");
  const maxR = parseFloat(s.estoque_total) - maxNR;
  const consR = parseFloat(s.consumido_r);
  const consNR = parseFloat(s.consumido_nr);
  const analR = parseFloat(s.em_analise_r);
  const analNR = parseFloat(s.em_analise_nr);
  const dispR = Math.max(0, maxR - consR);
  const dispNR = Math.max(0, maxNR - consNR);
  const overNR = Math.max(0, consNR - maxNR);
  const pctR = maxR > 0 ? (consR / maxR) * 100 : 0;
  const pctNR = maxNR > 0 ? (consNR / maxNR) * 100 : 0;
  return { maxNR, maxR, consR, consNR, analR, analNR, dispR, dispNR, overNR, pctR, pctNR };
}

const fmt = (v: number) =>
  new Intl.NumberFormat("pt-BR", { maximumFractionDigits: 0 }).format(v);

function consumeColor(pct: number, isR: boolean): string {
  if (isR) {
    // R = piso (mínimo): baixo consumo é o problema, alto é bom
    if (pct < 30) return "#E24B4A";  // crítico: muito abaixo do mínimo
    if (pct < 60) return "#EF9F27";  // alerta: abaixo do esperado
    return "#185FA5";                 // saudável (inclui >100%)
  } else {
    // NR = teto (máximo): alto consumo é o problema
    if (pct >= 100) return "#E24B4A"; // crítico: excedeu o limite
    if (pct >= 80) return "#EF9F27";  // alerta: próximo do limite
    return "#1D9E75";                  // seguro
  }
}

interface ChartEntry {
  nome: string;
  setorIdx: number;
  consR: number;
  dispR: number;
  consNR: number;
  dispNR: number;
  overNR: number;
  _pctR: number;
  _pctNR: number;
  _setorNome: string;
}

interface TooltipPayloadItem {
  name: string;
  value: number;
  payload: ChartEntry;
}

interface CustomTooltipProps {
  active?: boolean;
  payload?: TooltipPayloadItem[];
}

const CustomTooltip: React.FC<CustomTooltipProps> = ({ active, payload }) => {
  if (!active || !payload || payload.length === 0) return null;
  const e = payload[0].payload;
  return (
    <div style={{ background: "#fff", border: "1px solid #ddd", borderRadius: 6, padding: "10px 14px", fontSize: 13, minWidth: 200 }}>
      <p style={{ margin: "0 0 8px", fontWeight: 700 }}>{e._setorNome}</p>
      <p style={{ margin: "2px 0", color: "#185FA5" }}>Consumido R: {fmt(e.consR)} m² ({e._pctR.toFixed(1)}%)</p>
      <p style={{ margin: "2px 0", color: "#B5D4F4" }}>Disponível R: {fmt(e.dispR)} m²</p>
      <p style={{ margin: "6px 0 2px", color: "#1D9E75" }}>Consumido NR: {fmt(e.consNR)} m² ({e._pctNR.toFixed(1)}%)</p>
      <p style={{ margin: "2px 0", color: "#9FE1CB" }}>Disponível NR: {fmt(e.dispNR)} m²</p>
      {e.overNR > 0 && (
        <p style={{ margin: "2px 0", color: "#E24B4A", fontWeight: 600 }}>Estouro NR: {fmt(e.overNR)} m²</p>
      )}
    </div>
  );
};

const GraficoEstoqueSetores: React.FC<Props> = ({ setores }) => {
  const [selecionado, setSelecionado] = useState<number | null>(null);

  function selectSetor(idx: number) {
    setSelecionado((prev) => (prev === idx ? null : idx));
  }

  const derivadosPorSetor = setores.map(calcDerivados);

  // 5 pontos — um por setor. Recharts agrupa stackId="r" e stackId="nr"
  // lado a lado automaticamente, com o nome centralizado entre as duas barras.
  const chartData: ChartEntry[] = setores.map((s, i) => {
    const d = derivadosPorSetor[i];
    const nomeAbrev = s.nome.replace("Marginal Pinheiros", "Marg. Pinheiros");
    return {
      nome: nomeAbrev,
      setorIdx: i,
      consR: d.consR,
      dispR: d.dispR,
      consNR: d.consNR > d.maxNR ? d.maxNR : d.consNR,
      dispNR: d.dispNR,
      overNR: d.overNR,
      _pctR: d.pctR,
      _pctNR: d.pctNR,
      _setorNome: s.nome,
    };
  });

  return (
    <div
      style={{
        background: "#fff",
        borderRadius: 8,
        padding: "20px 24px",
        marginBottom: 24,
        boxShadow: "0 2px 8px rgba(0,0,0,0.06)",
      }}
    >
      <h3
        style={{
          margin: "0 0 4px",
          fontSize: 14,
          fontWeight: 600,
          color: "#555",
          textTransform: "uppercase",
          letterSpacing: "0.5px",
        }}
      >
        VISAO COMPARATIVA POR SETOR
      </h3>
      <p style={{ margin: "0 0 16px", fontSize: 12, color: "#888" }}>
        Clique numa barra ou card para destacar o setor
      </p>

      {/* Gráfico Recharts */}
      <ResponsiveContainer width="100%" height={320}>
        <BarChart data={chartData} barCategoryGap="30%" barGap={2}>
          <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
          <XAxis dataKey="nome" fontSize={12} tick={{ fill: "#555" }} />
          <YAxis
            tickFormatter={(v: number) =>
              new Intl.NumberFormat("pt-BR", { notation: "compact" }).format(v)
            }
            fontSize={11}
          />
          <Tooltip content={<CustomTooltip />} />

          {/* Stack R — índice = setorIdx diretamente */}
          <Bar dataKey="consR" stackId="r" fill="#185FA5" onClick={(data) => selectSetor(data.setorIdx)} cursor="pointer">
            {chartData.map((e, i) => (
              <Cell key={`consR-${i}`} fill={consumeColor(e._pctR, true)} fillOpacity={selecionado === null || selecionado === i ? 1 : 0.2} />
            ))}
          </Bar>
          <Bar dataKey="dispR" stackId="r" fill="#B5D4F4" onClick={(data) => selectSetor(data.setorIdx)} cursor="pointer">
            {chartData.map((_, i) => (
              <Cell key={`dispR-${i}`} fill="#B5D4F4" fillOpacity={selecionado === null || selecionado === i ? 1 : 0.2} />
            ))}
          </Bar>

          {/* Stack NR */}
          <Bar dataKey="consNR" stackId="nr" fill="#1D9E75" onClick={(data) => selectSetor(data.setorIdx)} cursor="pointer">
            {chartData.map((e, i) => (
              <Cell key={`consNR-${i}`} fill={consumeColor(e._pctNR, false)} fillOpacity={selecionado === null || selecionado === i ? 1 : 0.2} />
            ))}
          </Bar>
          <Bar dataKey="dispNR" stackId="nr" fill="#9FE1CB" onClick={(data) => selectSetor(data.setorIdx)} cursor="pointer">
            {chartData.map((_, i) => (
              <Cell key={`dispNR-${i}`} fill="#9FE1CB" fillOpacity={selecionado === null || selecionado === i ? 1 : 0.2} />
            ))}
          </Bar>
          <Bar dataKey="overNR" stackId="nr" fill="#E24B4A" onClick={(data) => selectSetor(data.setorIdx)} cursor="pointer">
            {chartData.map((_, i) => (
              <Cell key={`overNR-${i}`} fill="#E24B4A" fillOpacity={selecionado === null || selecionado === i ? 1 : 0.2} />
            ))}
          </Bar>
        </BarChart>
      </ResponsiveContainer>

      {/* Legenda HTML customizada */}
      <div style={{ display: "flex", gap: 16, flexWrap: "wrap", marginTop: 8, fontSize: 12 }}>
        {[
          { color: "#185FA5", label: "Consumido R" },
          { color: "#B5D4F4", label: "Disponivel R" },
          { color: "#1D9E75", label: "Consumido NR" },
          { color: "#9FE1CB", label: "Disponivel NR" },
          { color: "#E24B4A", label: "NR Estourado" },
        ].map(({ color, label }) => (
          <div key={label} style={{ display: "flex", alignItems: "center", gap: 4 }}>
            <div style={{ width: 12, height: 12, background: color, borderRadius: 2 }} />
            <span>{label}</span>
          </div>
        ))}
      </div>

      {/* Separador */}
      <div style={{ borderTop: "1px solid #f0f0f0", margin: "20px 0 16px" }} />

      <h3
        style={{
          margin: "0 0 12px",
          fontSize: 14,
          fontWeight: 600,
          color: "#555",
          textTransform: "uppercase",
          letterSpacing: "0.5px",
        }}
      >
        DETALHE POR SETOR — CLIQUE NUM CARD PARA DESTACAR
      </h3>

      {/* Cards flex */}
      <div style={{ display: "flex", gap: 12, flexWrap: "wrap" }}>
        {setores.map((s, i) => {
          const d = derivadosPorSetor[i];
          const isSelected = selecionado === i;
          const isActive = selecionado === null || isSelected;
          const borderColor =
            d.pctR >= 100 || d.pctNR >= 100 ? "#E24B4A" : "#185FA5";

          return (
            <div
              key={s.nome}
              style={{
                background: "#fff",
                borderRadius: 8,
                padding: "14px 16px",
                border: isSelected
                  ? `2px solid ${borderColor}`
                  : "1px solid #e0e4ea",
                opacity: isActive ? 1 : 0.4,
                cursor: "pointer",
                transition: "opacity 0.2s, border 0.2s",
                boxShadow: isSelected
                  ? "0 2px 12px rgba(24,95,165,0.15)"
                  : "none",
                minWidth: 180,
                flex: "1 1 180px",
              }}
              onClick={() => selectSetor(i)}
            >
              {/* Nome */}
              <p
                style={{
                  margin: "0 0 10px",
                  fontWeight: 700,
                  fontSize: 13,
                  color: "#1a1a2e",
                }}
              >
                {s.nome}
              </p>

              {/* Gauge R */}
              <div style={{ marginBottom: 8 }}>
                <div
                  style={{
                    display: "flex",
                    justifyContent: "space-between",
                    fontSize: 11,
                    color: "#555",
                    marginBottom: 3,
                  }}
                >
                  <span>R</span>
                  <span style={{ fontWeight: 600, color: consumeColor(d.pctR, true) }}>
                    {d.pctR.toFixed(1)}%
                  </span>
                </div>
                <div
                  style={{
                    background: "#e9ecef",
                    borderRadius: 4,
                    height: 6,
                    overflow: "hidden",
                  }}
                >
                  <div
                    style={{
                      width: `${Math.min(100, d.pctR)}%`,
                      height: "100%",
                      background: consumeColor(d.pctR, true),
                      borderRadius: 4,
                      transition: "width 0.3s",
                    }}
                  />
                </div>
                <p style={{ margin: "2px 0 0", fontSize: 10, color: "#888" }}>
                  {fmt(d.consR)} / {fmt(d.maxR)} m²
                </p>
              </div>

              {/* Gauge NR */}
              <div style={{ marginBottom: 8 }}>
                <div
                  style={{
                    display: "flex",
                    justifyContent: "space-between",
                    fontSize: 11,
                    color: "#555",
                    marginBottom: 3,
                  }}
                >
                  <span>NR</span>
                  <span style={{ fontWeight: 600, color: consumeColor(d.pctNR, false) }}>
                    {d.pctNR.toFixed(1)}%
                  </span>
                </div>
                <div
                  style={{
                    background: "#e9ecef",
                    borderRadius: 4,
                    height: 6,
                    overflow: "hidden",
                  }}
                >
                  <div
                    style={{
                      width: `${Math.min(100, d.pctNR)}%`,
                      height: "100%",
                      background: consumeColor(d.pctNR, false),
                      borderRadius: 4,
                      transition: "width 0.3s",
                    }}
                  />
                </div>
                <p style={{ margin: "2px 0 0", fontSize: 10, color: "#888" }}>
                  {fmt(d.consNR)} / {fmt(d.maxNR)} m²
                </p>
              </div>

              {/* Disponíveis */}
              <div style={{ fontSize: 11, color: "#555", marginTop: 6 }}>
                <p style={{ margin: "1px 0" }}>Disponivel R: {fmt(d.dispR)} m²</p>
                <p style={{ margin: "1px 0" }}>Disponivel NR: {fmt(d.dispNR)} m²</p>
              </div>

              {/* Em análise */}
              {d.analR + d.analNR > 0 && (
                <div style={{ margin: "6px 0 0", fontSize: 11, color: "#EF9F27", fontWeight: 600 }}>
                  {d.analR > 0 && d.analNR > 0 ? (
                    <>
                      <p style={{ margin: "1px 0" }}>Em analise R: {fmt(d.analR)} m²</p>
                      <p style={{ margin: "1px 0" }}>Em analise NR: {fmt(d.analNR)} m²</p>
                    </>
                  ) : d.analR > 0 ? (
                    <p style={{ margin: "1px 0" }}>Em analise R: {fmt(d.analR)} m²</p>
                  ) : (
                    <p style={{ margin: "1px 0" }}>Em analise NR: {fmt(d.analNR)} m²</p>
                  )}
                </div>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
};

export default GraficoEstoqueSetores;
