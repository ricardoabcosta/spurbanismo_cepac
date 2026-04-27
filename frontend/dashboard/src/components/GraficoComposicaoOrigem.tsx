/**
 * GraficoComposicaoOrigem — grid de cards com donut R vs NR por setor + card Total Geral.
 * Usado para ACA e NUVEM passando diferentes getores e labels.
 * Percentuais derivados em runtime, nunca armazenados.
 */
import React from "react";
import { PieChart, Pie, Cell, Tooltip, ResponsiveContainer } from "recharts";
import type { OcupacaoSetor } from "../types/api";

const COR_R = "#185FA5";
const COR_NR = "#1D9E75";
const COR_VAZIO = "#e0e0e0";

const fmtM2 = (v: number): string =>
  new Intl.NumberFormat("pt-BR", { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(v) + " m²";

const fmtM2Compact = (v: number): string =>
  new Intl.NumberFormat("pt-BR", { maximumFractionDigits: 0 }).format(v) + " m²";

interface TooltipPayload {
  name: string;
  value: number;
  payload: { pct: number };
}

interface CustomTooltipProps {
  active?: boolean;
  payload?: TooltipPayload[];
  rotulo: string;
}

const CustomTooltip: React.FC<CustomTooltipProps> = ({ active, payload, rotulo }) => {
  if (!active || !payload?.length) return null;
  const { name, value, payload: inner } = payload[0];
  return (
    <div style={{ background: "#fff", border: "1px solid #ddd", borderRadius: 6, padding: "8px 12px", fontSize: 12 }}>
      <p style={{ margin: "0 0 4px", fontWeight: 700 }}>{name}</p>
      <p style={{ margin: "1px 0" }}>{fmtM2(value)}</p>
      <p style={{ margin: 0, color: "#888" }}>{inner.pct.toFixed(1)}% do total {rotulo}</p>
    </div>
  );
};

interface DonutCardProps {
  nome: string;
  valR: number;
  valNR: number;
  labelR: string;
  labelNR: string;
  rotuloTotal: string;
  isTotal?: boolean;
}

const DonutCard: React.FC<DonutCardProps> = ({ nome, valR, valNR, labelR, labelNR, rotuloTotal, isTotal }) => {
  const total = valR + valNR;
  const vazio = total === 0;

  const fatias = vazio
    ? [{ name: "Sem consumo", value: 1, cor: COR_VAZIO, pct: 0 }]
    : [
        { name: labelR, value: valR, cor: COR_R, pct: (valR / total) * 100 },
        { name: labelNR, value: valNR, cor: COR_NR, pct: (valNR / total) * 100 },
      ];

  return (
    <div
      style={{
        background: isTotal ? "#f8f9fa" : "#fff",
        borderRadius: 8,
        padding: "16px 16px 14px",
        boxShadow: isTotal ? "0 1px 6px rgba(0,0,0,.12)" : "0 1px 4px rgba(0,0,0,.08)",
        border: isTotal ? "2px solid #1a1a2e" : "1px solid transparent",
        flex: "1 1 180px",
        minWidth: 170,
        display: "flex",
        flexDirection: "column",
      }}
    >
      {/* Nome */}
      <p style={{ margin: "0 0 8px", fontSize: 13, fontWeight: 700, color: isTotal ? "#003087" : "#1a1a2e" }}>
        {nome}
      </p>

      {/* Donut */}
      <div style={{ width: "100%", height: 120 }}>
        <ResponsiveContainer width="100%" height="100%">
          <PieChart>
            <Pie
              data={fatias}
              cx="50%"
              cy="50%"
              innerRadius={32}
              outerRadius={52}
              dataKey="value"
              strokeWidth={vazio ? 0 : 1}
            >
              {fatias.map((f, i) => (
                <Cell key={i} fill={f.cor} />
              ))}
            </Pie>
            {!vazio && (
              <Tooltip content={<CustomTooltip rotulo={rotuloTotal} />} />
            )}
          </PieChart>
        </ResponsiveContainer>
      </div>

      {/* Legenda ou mensagem vazia */}
      {vazio ? (
        <p style={{ margin: "4px 0 0", fontSize: 11, color: "#aaa", textAlign: "center" }}>
          Sem consumo registrado
        </p>
      ) : (
        <div style={{ display: "flex", flexDirection: "column", gap: 3, marginTop: 4 }}>
          {[
            { cor: COR_R, label: labelR, valor: valR },
            { cor: COR_NR, label: labelNR, valor: valNR },
          ].map(({ cor, label, valor }) => (
            <div key={label} style={{ display: "flex", alignItems: "center", gap: 6, fontSize: 11 }}>
              <div style={{ width: 10, height: 10, borderRadius: 2, background: cor, flexShrink: 0 }} />
              <span style={{ color: "#555", minWidth: 54 }}>{label}</span>
              <span style={{ fontWeight: 600, color: "#1a1a2e", marginLeft: "auto" }}>
                {fmtM2Compact(valor)}
              </span>
            </div>
          ))}
        </div>
      )}

      {/* Separador */}
      <div style={{ borderTop: "1px solid #e8e8e8", margin: "10px 0 8px" }} />

      {/* Total */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline" }}>
        <span style={{ fontSize: 11, color: "#888" }}>Total {rotuloTotal}</span>
        <span style={{ fontSize: 13, fontWeight: 700, color: isTotal ? "#003087" : "#1a1a2e" }}>
          {fmtM2Compact(total)}
        </span>
      </div>
    </div>
  );
};

export interface ComposicaoOrigemProps {
  titulo: string;
  descricao: string;
  rotulo: string;           // "ACA" ou "NUVEM"
  setores: OcupacaoSetor[];
  getCampos: (s: OcupacaoSetor) => { r: number; nr: number };
}

const GraficoComposicaoOrigem: React.FC<ComposicaoOrigemProps> = ({
  titulo, descricao, rotulo, setores, getCampos,
}) => {
  const totalR = setores.reduce((acc, s) => acc + getCampos(s).r, 0);
  const totalNR = setores.reduce((acc, s) => acc + getCampos(s).nr, 0);

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
        {titulo}
      </h3>
      <p style={{ margin: "0 0 16px", fontSize: 12, color: "#888" }}>{descricao}</p>

      <div style={{ display: "flex", gap: 12, flexWrap: "wrap" }}>
        {/* Cards por setor */}
        {setores.map((s) => {
          const { r, nr } = getCampos(s);
          return (
            <DonutCard
              key={s.nome}
              nome={s.nome}
              valR={r}
              valNR={nr}
              labelR={`${rotulo}-R`}
              labelNR={`${rotulo}-NR`}
              rotuloTotal={rotulo}
            />
          );
        })}

        {/* Card Total Geral */}
        <DonutCard
          nome="Total Geral"
          valR={totalR}
          valNR={totalNR}
          labelR={`${rotulo}-R`}
          labelNR={`${rotulo}-NR`}
          rotuloTotal={rotulo}
          isTotal
        />
      </div>
    </div>
  );
};

export default GraficoComposicaoOrigem;
