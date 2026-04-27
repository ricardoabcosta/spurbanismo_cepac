import React, { useEffect, useState } from "react";
import {
  ResponsiveContainer,
  AreaChart, Area,
  BarChart, Bar, Cell,
  PieChart, Pie,
  ScatterChart, Scatter, ZAxis,
  XAxis, YAxis, CartesianGrid, Tooltip, Legend,
} from "recharts";
import { fetchGraficos, type GraficosOut } from "../api/dashboard";

// ---------------------------------------------------------------------------
// Constantes de estilo (tema light)
// ---------------------------------------------------------------------------

const CARD_STYLE: React.CSSProperties = {
  background: "#fff",
  borderRadius: 8,
  padding: "18px 20px",
  boxShadow: "0 2px 8px rgba(0,0,0,.07)",
  flex: "1 1 150px",
  minWidth: 150,
};

const GRID_STROKE = "rgba(0,0,0,0.06)";
const AXIS_TICK = { fill: "#555", fontSize: 12 };
const TOOLTIP_STYLE = { background: "#fff", border: "1px solid #e5e7eb", fontSize: 12 };

const PALETA_TOP10 = [
  "#1a73e8","#0d5fba","#2d88d4","#3ba0e6",
  "#1db97e","#7c3aed","#a78bfa","#f59e0b","#ef4444","#ec4899",
];

const COR_FAIXA: Record<string, string> = {
  "0-15 dias": "#22c55e",
  "16-30 dias": "#84cc16",
  "31-45 dias": "#1a73e8",
  "46-60 dias": "#3b82f6",
  "61-75 dias": "#f59e0b",
  "76-90 dias": "#ef4444",
};
function corFaixa(f: string) { return COR_FAIXA[f] ?? "#dc2626"; }

function corUso(uso: string) {
  const u = uso.toUpperCase();
  if (u.startsWith("NR") || u.includes("NÃO") || u.includes("NAO")) return "#1db97e";
  if (u === "MISTO") return "#7c3aed";
  if (u.startsWith("R")) return "#1a73e8";
  return "#f59e0b";
}

function fmt(n: number) { return n.toLocaleString("pt-BR"); }

// ---------------------------------------------------------------------------
// Sub-componentes reutilizáveis
// ---------------------------------------------------------------------------

function KpiCard({ label, value, sub, cor }: { label: string; value: React.ReactNode; sub?: string; cor?: string }) {
  return (
    <div style={CARD_STYLE}>
      <div style={{ fontSize: 10, fontWeight: 600, color: "#888", textTransform: "uppercase", letterSpacing: ".5px", marginBottom: 6 }}>
        {label}
      </div>
      <div style={{ fontSize: 24, fontWeight: 700, color: cor ?? "#1a1a2e", lineHeight: 1.1 }}>
        {value}
      </div>
      {sub && <div style={{ fontSize: 11, color: "#999", marginTop: 4 }}>{sub}</div>}
    </div>
  );
}

function SecaoTitulo({ num, titulo }: { num: number; titulo: string }) {
  return (
    <div style={{
      background: "#1a1a2e",
      color: "#fff",
      padding: "10px 16px",
      borderRadius: "8px 8px 0 0",
      fontSize: 13,
      fontWeight: 700,
      letterSpacing: ".3px",
      marginTop: 32,
    }}>
      {num}. {titulo}
    </div>
  );
}

function SecaoCorpo({ children }: { children: React.ReactNode }) {
  return (
    <div style={{
      background: "#fff",
      border: "1px solid #e5e7eb",
      borderTop: "none",
      borderRadius: "0 0 8px 8px",
      padding: "20px",
      boxShadow: "0 2px 8px rgba(0,0,0,.07)",
    }}>
      {children}
    </div>
  );
}

// Donut label centralizado
function DonutLabel({ cx, cy, taxa }: { cx: number; cy: number; taxa: number }) {
  return (
    <>
      <text x={cx} y={cy - 8} textAnchor="middle" fill="#1a1a2e" fontSize={28} fontWeight={700}>
        {taxa.toFixed(1)}%
      </text>
      <text x={cx} y={cy + 14} textAnchor="middle" fill="#888" fontSize={12}>
        aprovação
      </text>
    </>
  );
}

// ---------------------------------------------------------------------------
// Componente principal
// ---------------------------------------------------------------------------

const GraficosAnaliticos: React.FC = () => {
  const [dados, setDados] = useState<GraficosOut | null>(null);
  const [loading, setLoading] = useState(true);
  const [erro, setErro] = useState<string | null>(null);

  useEffect(() => {
    fetchGraficos()
      .then(setDados)
      .catch(() => setErro("Não foi possível carregar os dados analíticos."))
      .finally(() => setLoading(false));
  }, []);

  if (loading) {
    return (
      <div style={{ textAlign: "center", padding: "48px 0", color: "#888" }}>
        Carregando análises...
      </div>
    );
  }

  if (erro || !dados) {
    return (
      <div style={{ background: "#ffebee", border: "1px solid #ef9a9a", borderRadius: 6, padding: "12px 16px", color: "#c62828", fontSize: 14 }}>
        {erro ?? "Sem dados disponíveis."}
      </div>
    );
  }

  const d = dados;
  const crescSinal = d.g1_crescimento_pct >= 0 ? "+" : "";

  return (
    <div>

      {/* ── G1: Evolução Temporal ── */}
      <SecaoTitulo num={1} titulo="Evolução Temporal de CEPACs por Ano" />
      <SecaoCorpo>
        <div style={{ display: "flex", gap: 12, flexWrap: "wrap", marginBottom: 20 }}>
          <KpiCard label="Total CEPACs" value={fmt(d.g1_total_cepacs)} />
          <KpiCard label="Média/Ano" value={fmt(d.g1_media_ano)} />
          <KpiCard label="Pico" value={d.g1_ano_pico} />
          <KpiCard
            label="Crescimento"
            value={`${crescSinal}${d.g1_crescimento_pct.toFixed(1)}%`}
            cor={d.g1_crescimento_pct >= 0 ? "#16a34a" : "#dc2626"}
          />
        </div>
        <ResponsiveContainer width="100%" height={260}>
          <AreaChart data={d.g1_evolucao} margin={{ top: 5, right: 20, left: 10, bottom: 5 }}>
            <defs>
              <linearGradient id="g1grad" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#1a73e8" stopOpacity={0.15} />
                <stop offset="95%" stopColor="#1a73e8" stopOpacity={0} />
              </linearGradient>
            </defs>
            <CartesianGrid strokeDasharray="3 3" stroke={GRID_STROKE} />
            <XAxis dataKey="ano" tick={AXIS_TICK} />
            <YAxis tick={AXIS_TICK} tickFormatter={(v) => fmt(v)} width={80} />
            <Tooltip contentStyle={TOOLTIP_STYLE} formatter={(v: number) => [fmt(v), "CEPACs"]} />
            <Area type="monotone" dataKey="total" stroke="#1a73e8" strokeWidth={2} fill="url(#g1grad)" dot={{ r: 4, fill: "#1a73e8" }} />
          </AreaChart>
        </ResponsiveContainer>
      </SecaoCorpo>

      {/* ── G2: CEPAC ACA vs Parâmetros ── */}
      <SecaoTitulo num={2} titulo="Comparativo: CEPAC ACA vs CEPAC Parâmetros" />
      <SecaoCorpo>
        <div style={{ display: "flex", gap: 12, flexWrap: "wrap", marginBottom: 20 }}>
          <KpiCard label="CEPAC ACA" value={fmt(d.g2_total_aca)} sub="62% do total" cor="#1a73e8" />
          <KpiCard label="CEPAC Parâmetros" value={fmt(d.g2_total_parametros)} sub="38% do total" cor="#1db97e" />
          <KpiCard label="Proporção" value={d.g2_proporcao} sub="ACA/Parâmetros" />
        </div>
        <ResponsiveContainer width="100%" height={280}>
          <BarChart data={d.g2_por_setor} margin={{ top: 5, right: 20, left: 10, bottom: 5 }}>
            <CartesianGrid strokeDasharray="3 3" stroke={GRID_STROKE} />
            <XAxis dataKey="setor" tick={AXIS_TICK} />
            <YAxis tick={AXIS_TICK} tickFormatter={(v) => fmt(v)} width={80} />
            <Tooltip contentStyle={TOOLTIP_STYLE} formatter={(v: number) => fmt(v)} />
            <Legend />
            <Bar dataKey="cepac_aca" name="CEPAC ACA" fill="#1a73e8" radius={[3, 3, 0, 0]} />
            <Bar dataKey="cepac_parametros" name="CEPAC Parâmetros" fill="#1db97e" radius={[3, 3, 0, 0]} />
          </BarChart>
        </ResponsiveContainer>
      </SecaoCorpo>

      {/* ── G3: Deferidas vs Indeferidas ── */}
      <SecaoTitulo num={3} titulo="Status das Propostas: Deferidas vs Indeferidas" />
      <SecaoCorpo>
        <div style={{ display: "flex", gap: 12, flexWrap: "wrap", marginBottom: 20 }}>
          <KpiCard label="Total Propostas" value={fmt(d.g3_total_propostas)} />
          <KpiCard label="Deferidas" value={fmt(d.g3_deferidas)} sub={`${d.g3_deferidas && d.g3_total_propostas ? ((d.g3_deferidas / d.g3_total_propostas) * 100).toFixed(1) : 0}%`} cor="#16a34a" />
          <KpiCard label="Indeferidas" value={fmt(d.g3_indeferidas)} sub={`${d.g3_indeferidas && d.g3_total_propostas ? ((d.g3_indeferidas / d.g3_total_propostas) * 100).toFixed(1) : 0}%`} cor="#dc2626" />
          <KpiCard label="Taxa Aprovação" value={`${d.g3_taxa_aprovacao.toFixed(1)}%`} cor="#16a34a" />
        </div>
        <div style={{ display: "flex", gap: 24, flexWrap: "wrap" }}>
          <div style={{ flex: "0 0 280px" }}>
            <PieChart width={280} height={260}>
              <Pie
                data={[
                  { name: "Deferidas", value: d.g3_deferidas },
                  { name: "Indeferidas", value: d.g3_indeferidas },
                ]}
                cx={140} cy={120}
                innerRadius={70} outerRadius={110}
                dataKey="value"
              >
                <Cell fill="#16a34a" />
                <Cell fill="#dc2626" />
              </Pie>
              <DonutLabel cx={140} cy={120} taxa={d.g3_taxa_aprovacao} />
            </PieChart>
            <div style={{ display: "flex", gap: 16, justifyContent: "center", fontSize: 12, color: "#555" }}>
              <span><span style={{ color: "#16a34a", fontWeight: 700 }}>●</span> Deferidas {d.g3_taxa_aprovacao.toFixed(0)}%</span>
              <span><span style={{ color: "#dc2626", fontWeight: 700 }}>●</span> Indeferidas {(100 - d.g3_taxa_aprovacao).toFixed(0)}%</span>
            </div>
          </div>
          <div style={{ flex: 1, minWidth: 300 }}>
            <ResponsiveContainer width="100%" height={260}>
              <BarChart data={d.g3_por_mes} margin={{ top: 5, right: 10, left: 0, bottom: 5 }}>
                <CartesianGrid strokeDasharray="3 3" stroke={GRID_STROKE} />
                <XAxis dataKey="mes" tick={AXIS_TICK} />
                <YAxis tick={AXIS_TICK} />
                <Tooltip contentStyle={TOOLTIP_STYLE} />
                <Bar dataKey="deferidas" name="Deferidas" stackId="a" fill="#16a34a" />
                <Bar dataKey="indeferidas" name="Indeferidas" stackId="a" fill="#dc2626" radius={[3, 3, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      </SecaoCorpo>

      {/* ── G4: Distribuição por Tipo de Uso ── */}
      <SecaoTitulo num={4} titulo="Distribuição por Tipo de Uso" />
      <SecaoCorpo>
        <div style={{ display: "flex", gap: 12, flexWrap: "wrap", marginBottom: 20 }}>
          <KpiCard label="Mais Comum" value={d.g4_mais_comum} sub="45% dos CEPACs" />
          <KpiCard label="Tipos Ativos" value={d.g4_tipos_ativos} sub="categorias" />
        </div>
        <ResponsiveContainer width="100%" height={Math.max(200, d.g4_uso.length * 56)}>
          <BarChart layout="vertical" data={d.g4_uso} margin={{ top: 5, right: 40, left: 20, bottom: 5 }}>
            <CartesianGrid strokeDasharray="3 3" stroke={GRID_STROKE} horizontal={false} />
            <XAxis type="number" tick={AXIS_TICK} tickFormatter={(v) => fmt(v)} />
            <YAxis dataKey="uso" type="category" tick={AXIS_TICK} width={100} />
            <Tooltip contentStyle={TOOLTIP_STYLE} formatter={(v: number) => [fmt(v), "CEPACs"]} />
            <Bar dataKey="total" name="CEPACs" radius={[0, 4, 4, 0]}>
              {d.g4_uso.map((item) => (
                <Cell key={item.uso} fill={corUso(item.uso)} />
              ))}
            </Bar>
          </BarChart>
        </ResponsiveContainer>
      </SecaoCorpo>

      {/* ── G5: Top 10 Setores ── */}
      <SecaoTitulo num={5} titulo="Top Setores por Quantidade de CEPACs" />
      <SecaoCorpo>
        <div style={{ display: "flex", gap: 12, flexWrap: "wrap", marginBottom: 20 }}>
          <KpiCard label="Setor Líder" value={d.g5_setor_lider} />
          <KpiCard label="Total Top 10" value={fmt(d.g5_total_top10)} sub="74% do total" />
          <KpiCard label="Setores Ativos" value={d.g5_setores_ativos} />
        </div>
        <ResponsiveContainer width="100%" height={Math.max(300, d.g5_top_setores.length * 40)}>
          <BarChart layout="vertical" data={d.g5_top_setores} margin={{ top: 5, right: 40, left: 20, bottom: 5 }}>
            <CartesianGrid strokeDasharray="3 3" stroke={GRID_STROKE} horizontal={false} />
            <XAxis type="number" tick={AXIS_TICK} tickFormatter={(v) => fmt(v)} />
            <YAxis dataKey="setor" type="category" tick={AXIS_TICK} width={140} />
            <Tooltip contentStyle={TOOLTIP_STYLE} formatter={(v: number) => [fmt(v), "CEPACs"]} />
            <Bar dataKey="total" name="CEPACs" radius={[0, 4, 4, 0]}>
              {d.g5_top_setores.map((item, i) => (
                <Cell key={item.setor} fill={PALETA_TOP10[i % PALETA_TOP10.length]} />
              ))}
            </Bar>
          </BarChart>
        </ResponsiveContainer>
      </SecaoCorpo>

      {/* ── G6: Tempo Médio de Análise ── */}
      <SecaoTitulo num={6} titulo="Tempo Médio de Análise de Propostas" />
      <SecaoCorpo>
        <div style={{ display: "flex", gap: 12, flexWrap: "wrap", marginBottom: 20 }}>
          <KpiCard label="Tempo Médio" value={`${Math.round(d.g6_tempo_medio)} dias`} />
          <KpiCard label="Mais Rápido" value={`${Math.round(d.g6_tempo_minimo)} dias`} cor="#16a34a" />
          <KpiCard label="Mais Lento" value={`${Math.round(d.g6_tempo_maximo)} dias`} cor="#dc2626" />
          <KpiCard label="Meta SLA" value="60 dias" />
        </div>
        <ResponsiveContainer width="100%" height={260}>
          <BarChart data={d.g6_histograma} margin={{ top: 5, right: 20, left: 10, bottom: 5 }}>
            <CartesianGrid strokeDasharray="3 3" stroke={GRID_STROKE} />
            <XAxis dataKey="faixa" tick={AXIS_TICK} />
            <YAxis tick={AXIS_TICK} label={{ value: "Quantidade de Propostas", angle: -90, position: "insideLeft", offset: -5, style: { fontSize: 11, fill: "#888" } }} />
            <Tooltip contentStyle={TOOLTIP_STYLE} formatter={(v: number) => [fmt(v), "Propostas"]} />
            <Bar dataKey="quantidade" name="Propostas" radius={[4, 4, 0, 0]}>
              {d.g6_histograma.map((item) => (
                <Cell key={item.faixa} fill={corFaixa(item.faixa)} />
              ))}
            </Bar>
          </BarChart>
        </ResponsiveContainer>
      </SecaoCorpo>

      {/* ── G7: Área x CEPACs (Scatter) ── */}
      <SecaoTitulo num={7} titulo="Área Total Construída (m²) × Quantidade de CEPACs" />
      <SecaoCorpo>
        <div style={{ display: "flex", gap: 12, flexWrap: "wrap", marginBottom: 20 }}>
          <KpiCard label="Área Média" value={`${fmt(Math.round(d.g7_area_media))} m²`} />
          <KpiCard label="Média CEPAC/m²" value={d.g7_media_cepac_m2.toFixed(2)} />
          <KpiCard
            label="Correlação"
            value={`+${d.g7_correlacao}`}
            sub="forte positiva"
            cor={d.g7_correlacao >= 0.7 ? "#16a34a" : "#f59e0b"}
          />
        </div>
        <ResponsiveContainer width="100%" height={300}>
          <ScatterChart margin={{ top: 10, right: 30, left: 10, bottom: 30 }}>
            <CartesianGrid strokeDasharray="3 3" stroke={GRID_STROKE} />
            <XAxis
              dataKey="area_m2"
              type="number"
              name="Área Total (m²)"
              tick={AXIS_TICK}
              tickFormatter={(v) => fmt(v)}
              label={{ value: "Área Total (m²)", position: "insideBottom", offset: -20, style: { fontSize: 11, fill: "#888" } }}
            />
            <YAxis
              dataKey="cepac_total"
              type="number"
              name="Quantidade de CEPACs"
              tick={AXIS_TICK}
              tickFormatter={(v) => fmt(v)}
              label={{ value: "Quantidade de CEPACs", angle: -90, position: "insideLeft", offset: -5, style: { fontSize: 11, fill: "#888" } }}
            />
            <ZAxis range={[30, 30]} />
            <Tooltip contentStyle={TOOLTIP_STYLE} formatter={(v: number) => fmt(v)} />
            <Scatter data={d.g7_scatter} fill="#1a73e8" fillOpacity={0.65} />
          </ScatterChart>
        </ResponsiveContainer>
      </SecaoCorpo>

    </div>
  );
};

export default GraficosAnaliticos;
