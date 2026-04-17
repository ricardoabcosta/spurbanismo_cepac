/**
 * GraficoOcupacao — BarChart empilhado com Recharts.
 * 3 barras: Consumido (R+NR), Em Análise (R+NR), Disponível.
 * ReferenceLine tracejada para o teto NR de cada setor.
 * Setores com bloqueado_nr=true ficam destacados em vermelho no eixo X.
 */
import React from "react";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  ReferenceLine,
  Cell,
} from "recharts";
import type { OcupacaoSetor } from "../types/api";

interface ChartDatum {
  nome: string;
  consumido: number;
  em_analise: number;
  disponivel: number;
  teto_nr: number | null;
  bloqueado_nr: boolean;
  consumido_r: number;
  consumido_nr: number;
  em_analise_r: number;
  em_analise_nr: number;
}

interface TooltipPayloadItem {
  name: string;
  value: number;
  payload: ChartDatum;
}

interface CustomTooltipProps {
  active?: boolean;
  payload?: TooltipPayloadItem[];
  label?: string;
}

const CustomTooltip: React.FC<CustomTooltipProps> = ({ active, payload, label }) => {
  if (!active || !payload || payload.length === 0) return null;
  const d = payload[0].payload;

  const fmt = (v: number) =>
    new Intl.NumberFormat("pt-BR", { maximumFractionDigits: 2 }).format(v);

  return (
    <div
      style={{
        background: "#fff",
        border: "1px solid #ddd",
        borderRadius: 6,
        padding: "10px 14px",
        fontSize: 13,
        minWidth: 200,
      }}
    >
      <p style={{ margin: "0 0 8px", fontWeight: 700 }}>{label}</p>
      <p style={{ margin: "2px 0", color: "#1a73e8" }}>
        Consumido R: {fmt(d.consumido_r)} m²
      </p>
      <p style={{ margin: "2px 0", color: "#1a73e8" }}>
        Consumido NR: {fmt(d.consumido_nr)} m²
      </p>
      <p style={{ margin: "2px 0", color: "#f57c00" }}>
        Em Análise R: {fmt(d.em_analise_r)} m²
      </p>
      <p style={{ margin: "2px 0", color: "#f57c00" }}>
        Em Análise NR: {fmt(d.em_analise_nr)} m²
      </p>
      <p style={{ margin: "2px 0", color: "#34a853" }}>
        Disponível: {fmt(d.disponivel)} m²
      </p>
      {d.teto_nr !== null && (
        <p style={{ margin: "6px 0 0", color: "#c62828", fontWeight: 600 }}>
          Teto NR: {fmt(d.teto_nr)} m²
          {d.bloqueado_nr && " ⚠ BLOQUEADO"}
        </p>
      )}
    </div>
  );
};

interface XAxisTickProps {
  x?: number;
  y?: number;
  payload?: { value: string };
  bloqueados: Set<string>;
}

const CustomXAxisTick: React.FC<XAxisTickProps> = ({ x = 0, y = 0, payload, bloqueados }) => {
  const nome = payload?.value ?? "";
  const bloqueado = bloqueados.has(nome);
  return (
    <text
      x={x}
      y={y + 10}
      textAnchor="middle"
      fontSize={12}
      fill={bloqueado ? "#c62828" : "#444"}
      fontWeight={bloqueado ? 700 : 400}
    >
      {nome}
    </text>
  );
};

interface Props {
  setores: OcupacaoSetor[];
}

const GraficoOcupacao: React.FC<Props> = ({ setores }) => {
  const data: ChartDatum[] = setores.map((s) => ({
    nome: s.nome,
    consumido: Number(s.consumido_r) + Number(s.consumido_nr),
    em_analise: Number(s.em_analise_r) + Number(s.em_analise_nr),
    disponivel: Number(s.disponivel),
    teto_nr: s.teto_nr !== null ? Number(s.teto_nr) : null,
    bloqueado_nr: s.bloqueado_nr,
    consumido_r: Number(s.consumido_r),
    consumido_nr: Number(s.consumido_nr),
    em_analise_r: Number(s.em_analise_r),
    em_analise_nr: Number(s.em_analise_nr),
  }));

  const bloqueados = new Set(data.filter((d) => d.bloqueado_nr).map((d) => d.nome));
  const tetoNRValues = data.filter((d) => d.teto_nr !== null);

  return (
    <div
      style={{
        background: "#fff",
        borderRadius: 8,
        padding: "20px 16px 8px",
        boxShadow: "0 1px 4px rgba(0,0,0,.10)",
        marginBottom: 24,
      }}
    >
      <h3 style={{ margin: "0 0 16px", fontSize: 16, color: "#1a1a2e" }}>
        Ocupação por Setor (m²)
      </h3>
      <ResponsiveContainer width="100%" height={360}>
        <BarChart data={data} margin={{ top: 10, right: 30, left: 20, bottom: 5 }}>
          <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
          <XAxis
            dataKey="nome"
            tick={(props: XAxisTickProps) => (
              <CustomXAxisTick {...props} bloqueados={bloqueados} />
            )}
            interval={0}
          />
          <YAxis
            tickFormatter={(v: number) =>
              new Intl.NumberFormat("pt-BR", { notation: "compact" }).format(v)
            }
            fontSize={12}
          />
          <Tooltip content={<CustomTooltip />} />
          <Legend
            wrapperStyle={{ fontSize: 13 }}
            formatter={(value: string) => {
              const map: Record<string, string> = {
                consumido: "Consumido (R+NR)",
                em_analise: "Em Análise (R+NR)",
                disponivel: "Disponível",
              };
              return map[value] ?? value;
            }}
          />

          <Bar dataKey="consumido" stackId="a" fill="#1a73e8" name="consumido">
            {data.map((entry, index) => (
              <Cell
                key={`consumido-${index}`}
                fill={entry.bloqueado_nr ? "#b71c1c" : "#1a73e8"}
              />
            ))}
          </Bar>
          <Bar dataKey="em_analise" stackId="a" fill="#f57c00" name="em_analise" />
          <Bar dataKey="disponivel" stackId="a" fill="#34a853" name="disponivel" radius={[3, 3, 0, 0]} />

          {tetoNRValues.map((d) => (
            <ReferenceLine
              key={`teto-${d.nome}`}
              y={d.teto_nr ?? 0}
              stroke="#c62828"
              strokeDasharray="6 3"
              label={{ value: `Teto NR ${d.nome}`, fill: "#c62828", fontSize: 10, position: "right" }}
            />
          ))}
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
};

export default GraficoOcupacao;
