import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import {
  ResponsiveContainer,
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  BarChart,
  Bar,
  Cell,
  Legend,
  PieChart,
  Pie,
  ScatterChart,
  Scatter,
  ZAxis,
} from "recharts";
import { buscarGraficos, type GraficosOut } from "../api/dashboard";

// ---------------------------------------------------------------------------
// Constantes
// ---------------------------------------------------------------------------

const BG = "#0A1628";
const CARD_BG = "rgba(255,255,255,0.06)";
const CARD_BORDER = "1px solid rgba(255,255,255,0.1)";
const GRID_STROKE = "rgba(255,255,255,0.1)";
const AXIS_STROKE = "rgba(255,255,255,0.4)";
const TICK_STYLE = { fill: "rgba(255,255,255,0.6)", fontSize: 12 };
const TOOLTIP_STYLE = { background: "#1a2744", border: "1px solid rgba(255,255,255,0.1)", color: "#fff", fontSize: 12 };

const PALETA_TOP10 = [
  "#0057B8", "#1d6fba", "#2d88d4", "#3ba0e6",
  "#10b981", "#7c3aed", "#a78bfa", "#f59e0b", "#ef4444", "#ec4899",
];

const COR_FAIXA: Record<string, string> = {
  "0-15 dias": "#22c55e",
  "16-30 dias": "#84cc16",
  "31-45 dias": "#0057B8",
  "46-60 dias": "#3b82f6",
  "61-75 dias": "#f59e0b",
  "76-90 dias": "#ef4444",
};

function corFaixa(faixa: string): string {
  return COR_FAIXA[faixa] ?? "#dc2626";
}

function corUso(uso: string): string {
  const u = uso.toUpperCase();
  if (u.startsWith("NR") || u.includes("NÃO") || u.includes("NAO") || u.includes("COMERCIAL")) return "#10b981";
  if (u === "MISTO") return "#7c3aed";
  if (u.startsWith("R") && !u.startsWith("NR")) return "#0057B8";
  return "#f59e0b";
}

// ---------------------------------------------------------------------------
// Sub-componentes
// ---------------------------------------------------------------------------

function KpiCard({
  label,
  valor,
  sub,
  valorCor,
}: {
  label: string;
  valor: string | number;
  sub?: string;
  valorCor?: string;
}) {
  return (
    <div
      style={{
        background: CARD_BG,
        border: CARD_BORDER,
        borderRadius: "8px",
        padding: "16px 20px",
        flex: 1,
        minWidth: "120px",
      }}
    >
      <div style={{ fontSize: "11px", color: "rgba(255,255,255,0.5)", marginBottom: "4px", textTransform: "uppercase", letterSpacing: "0.8px" }}>
        {label}
      </div>
      <div style={{ fontSize: "28px", fontWeight: 700, color: valorCor ?? "#fff" }}>
        {valor}
      </div>
      {sub && (
        <div style={{ fontSize: "12px", color: "rgba(255,255,255,0.4)" }}>{sub}</div>
      )}
    </div>
  );
}

function SecaoTitulo({ numero, titulo }: { numero: number; titulo: string }) {
  return (
    <h2
      style={{
        margin: "0 0 16px 0",
        fontSize: "16px",
        fontWeight: 600,
        color: "#fff",
        borderLeft: "3px solid #0057B8",
        paddingLeft: "12px",
      }}
    >
      {numero}. {titulo}
    </h2>
  );
}

function Secao({ children }: { children: React.ReactNode }) {
  return (
    <div
      style={{
        background: "rgba(255,255,255,0.03)",
        border: CARD_BORDER,
        borderRadius: "10px",
        padding: "24px",
        marginBottom: "28px",
      }}
    >
      {children}
    </div>
  );
}

function KpiRow({ children }: { children: React.ReactNode }) {
  return (
    <div style={{ display: "flex", gap: "12px", marginBottom: "24px", flexWrap: "wrap" }}>
      {children}
    </div>
  );
}

// ---------------------------------------------------------------------------
// Label central do Donut
// ---------------------------------------------------------------------------

interface DonutLabelProps {
  cx?: number;
  cy?: number;
  taxa: number;
}

function DonutLabel({ cx = 0, cy = 0, taxa }: DonutLabelProps) {
  return (
    <>
      <text x={cx} y={cy - 8} textAnchor="middle" fill="#fff" fontSize={28} fontWeight={700}>
        {taxa.toFixed(1)}%
      </text>
      <text x={cx} y={cy + 16} textAnchor="middle" fill="rgba(255,255,255,0.5)" fontSize={12}>
        aprovação
      </text>
    </>
  );
}

// ---------------------------------------------------------------------------
// Spinner
// ---------------------------------------------------------------------------

function Spinner() {
  return (
    <div
      style={{
        display: "flex",
        justifyContent: "center",
        alignItems: "center",
        minHeight: "60vh",
      }}
    >
      <style>{`
        @keyframes spin { to { transform: rotate(360deg); } }
      `}</style>
      <div
        style={{
          width: "48px",
          height: "48px",
          border: "4px solid rgba(255,255,255,0.12)",
          borderTopColor: "#0057B8",
          borderRadius: "50%",
          animation: "spin 0.8s linear infinite",
        }}
      />
    </div>
  );
}

// ---------------------------------------------------------------------------
// Componente principal
// ---------------------------------------------------------------------------

export default function DashboardPage() {
  const navigate = useNavigate();
  const [dados, setDados] = useState<GraficosOut | null>(null);
  const [carregando, setCarregando] = useState(true);
  const [erro, setErro] = useState("");

  useEffect(() => {
    buscarGraficos()
      .then(setDados)
      .catch(() => setErro("Falha ao carregar dados do dashboard. Tente novamente."))
      .finally(() => setCarregando(false));
  }, []);

  return (
    <div style={{ background: BG, minHeight: "100vh", fontFamily: "system-ui, -apple-system, sans-serif", color: "#fff" }}>

      {/* Cabeçalho */}
      <div style={{ background: "linear-gradient(90deg, #0B2A4A 0%, #0F3A6D 55%, #145DA0 85%, #1C6ED5 100%)" }}>
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "0 28px", height: 88 }}>
          <div style={{ display: "flex", flexDirection: "row", alignItems: "center", gap: 16 }}>
            <img src="/imagens/logobranco.svg" alt="ZENITE" style={{ height: 82, width: "auto", display: "block" }} />
            <div style={{ width: 1, height: 40, background: "rgba(255,255,255,0.25)", flexShrink: 0 }} />
            <span style={{ fontSize: 15, color: "rgba(255,255,255,0.9)", fontWeight: 700, letterSpacing: "0.03em", whiteSpace: "nowrap" }}>
              Dashboard Analítico
            </span>
          </div>
          <button
            onClick={() => navigate("/propostas")}
            style={{ background: "rgba(255,255,255,0.1)", border: "1px solid rgba(255,255,255,0.3)", color: "#fff", padding: "7px 16px", borderRadius: 5, cursor: "pointer", fontSize: 15, fontWeight: 600, transition: "background 0.15s" }}
            onMouseEnter={(e) => { e.currentTarget.style.background = "rgba(255,255,255,0.18)"; }}
            onMouseLeave={(e) => { e.currentTarget.style.background = "rgba(255,255,255,0.1)"; }}
          >
            ← Voltar às Propostas
          </button>
        </div>
      </div>

      {/* Conteúdo */}
      <div style={{ padding: "24px 32px" }}>

      {carregando && <Spinner />}

      {erro && (
        <div
          role="alert"
          style={{
            background: "rgba(220,38,38,0.15)",
            border: "1px solid rgba(220,38,38,0.4)",
            borderRadius: "8px",
            padding: "16px 20px",
            color: "#fca5a5",
            fontSize: "14px",
          }}
        >
          {erro}
        </div>
      )}

      {dados && (
        <>
          {/* ---------------------------------------------------------------- */}
          {/* Gráfico 1 — Evolução Temporal                                    */}
          {/* ---------------------------------------------------------------- */}
          <Secao>
            <SecaoTitulo numero={1} titulo="Evolução Temporal de CEPACs por Ano" />
            <KpiRow>
              <KpiCard
                label="Total CEPACs"
                valor={dados.g1_total_cepacs.toLocaleString("pt-BR")}
                sub="soma acumulada"
              />
              <KpiCard
                label="Média/Ano"
                valor={dados.g1_media_ano.toLocaleString("pt-BR")}
                sub="média anual"
              />
              <KpiCard
                label="Ano Pico"
                valor={dados.g1_ano_pico}
                sub="maior volume"
              />
              <KpiCard
                label="Crescimento"
                valor={`+${dados.g1_crescimento_pct}%`}
                valorCor="#22c55e"
                sub="variação período"
              />
            </KpiRow>
            <ResponsiveContainer width="100%" height={280}>
              <AreaChart data={dados.g1_evolucao}>
                <defs>
                  <linearGradient id="grad1" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#0057B8" stopOpacity={0.3} />
                    <stop offset="95%" stopColor="#0057B8" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke={GRID_STROKE} />
                <XAxis dataKey="ano" stroke={AXIS_STROKE} tick={TICK_STYLE} />
                <YAxis stroke={AXIS_STROKE} tick={TICK_STYLE} />
                <Tooltip contentStyle={TOOLTIP_STYLE} />
                <Area
                  type="monotone"
                  dataKey="total"
                  stroke="#0057B8"
                  strokeWidth={2}
                  fill="url(#grad1)"
                  dot={{ r: 4, fill: "#0057B8" }}
                  activeDot={{ r: 6 }}
                />
              </AreaChart>
            </ResponsiveContainer>
          </Secao>

          {/* ---------------------------------------------------------------- */}
          {/* Gráfico 2 — CEPAC ACA vs Parâmetros                             */}
          {/* ---------------------------------------------------------------- */}
          <Secao>
            <SecaoTitulo numero={2} titulo="Comparativo CEPAC ACA vs Parâmetros por Setor" />
            <KpiRow>
              <KpiCard
                label="CEPAC ACA"
                valor={dados.g2_total_aca.toLocaleString("pt-BR")}
                valorCor="#10b981"
                sub="total adquirido"
              />
              <KpiCard
                label="CEPAC Parâmetros"
                valor={dados.g2_total_parametros.toLocaleString("pt-BR")}
                valorCor="#059669"
                sub="total referência"
              />
              <KpiCard
                label="Proporção"
                valor={dados.g2_proporcao}
                sub="ACA / Parâmetros"
              />
            </KpiRow>
            <ResponsiveContainer width="100%" height={300}>
              <BarChart data={dados.g2_por_setor}>
                <CartesianGrid strokeDasharray="3 3" stroke={GRID_STROKE} />
                <XAxis dataKey="setor" stroke={AXIS_STROKE} tick={TICK_STYLE} />
                <YAxis stroke={AXIS_STROKE} tick={TICK_STYLE} />
                <Tooltip contentStyle={TOOLTIP_STYLE} />
                <Legend wrapperStyle={{ color: "rgba(255,255,255,0.6)", fontSize: 12 }} />
                <Bar dataKey="cepac_aca" name="CEPAC ACA" fill="#0057B8" radius={[3, 3, 0, 0]} />
                <Bar dataKey="cepac_parametros" name="CEPAC Parâmetros" fill="#10b981" radius={[3, 3, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </Secao>

          {/* ---------------------------------------------------------------- */}
          {/* Gráfico 3 — Deferidas vs Indeferidas                            */}
          {/* ---------------------------------------------------------------- */}
          <Secao>
            <SecaoTitulo numero={3} titulo="Status: Deferidas vs Indeferidas" />
            <KpiRow>
              <KpiCard
                label="Total Propostas"
                valor={dados.g3_total_propostas.toLocaleString("pt-BR")}
                sub="total analisadas"
              />
              <KpiCard
                label="Deferidas"
                valor={dados.g3_deferidas.toLocaleString("pt-BR")}
                valorCor="#16a34a"
                sub={`${((dados.g3_deferidas / dados.g3_total_propostas) * 100).toFixed(1)}% do total`}
              />
              <KpiCard
                label="Indeferidas"
                valor={dados.g3_indeferidas.toLocaleString("pt-BR")}
                valorCor="#dc2626"
                sub={`${((dados.g3_indeferidas / dados.g3_total_propostas) * 100).toFixed(1)}% do total`}
              />
              <KpiCard
                label="Taxa Aprovação"
                valor={`${dados.g3_taxa_aprovacao.toFixed(1)}%`}
                valorCor="#16a34a"
                sub="propostas deferidas"
              />
            </KpiRow>
            <div style={{ display: "flex", gap: "24px", alignItems: "center" }}>
              {/* Donut */}
              <div style={{ flex: "0 0 40%" }}>
                <ResponsiveContainer width="100%" height={280}>
                  <PieChart>
                    <Pie
                      data={[
                        { name: "Deferidas", value: dados.g3_deferidas },
                        { name: "Indeferidas", value: dados.g3_indeferidas },
                      ]}
                      cx="50%"
                      cy="50%"
                      innerRadius={70}
                      outerRadius={120}
                      dataKey="value"
                      labelLine={false}
                    >
                      <Cell fill="#16a34a" />
                      <Cell fill="#dc2626" />
                    </Pie>
                    <Tooltip contentStyle={TOOLTIP_STYLE} />
                    <Legend wrapperStyle={{ color: "rgba(255,255,255,0.6)", fontSize: 12 }} />
                    <DonutLabel cx={undefined} cy={undefined} taxa={dados.g3_taxa_aprovacao} />
                  </PieChart>
                </ResponsiveContainer>
              </div>
              {/* Stacked BarChart */}
              <div style={{ flex: "0 0 58%" }}>
                <ResponsiveContainer width="100%" height={280}>
                  <BarChart data={dados.g3_por_mes}>
                    <CartesianGrid strokeDasharray="3 3" stroke={GRID_STROKE} />
                    <XAxis dataKey="mes" stroke={AXIS_STROKE} tick={TICK_STYLE} />
                    <YAxis stroke={AXIS_STROKE} tick={TICK_STYLE} />
                    <Tooltip contentStyle={TOOLTIP_STYLE} />
                    <Legend wrapperStyle={{ color: "rgba(255,255,255,0.6)", fontSize: 12 }} />
                    <Bar dataKey="deferidas" name="Deferidas" stackId="a" fill="#16a34a" />
                    <Bar dataKey="indeferidas" name="Indeferidas" stackId="a" fill="#dc2626" radius={[3, 3, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>
          </Secao>

          {/* ---------------------------------------------------------------- */}
          {/* Gráfico 4 — Distribuição por Tipo de Uso                        */}
          {/* ---------------------------------------------------------------- */}
          <Secao>
            <SecaoTitulo numero={4} titulo="Distribuição por Tipo de Uso" />
            <KpiRow>
              <KpiCard
                label="Mais Comum"
                valor={dados.g4_mais_comum}
                sub="tipo predominante"
              />
              <KpiCard
                label="Tipos Ativos"
                valor={dados.g4_tipos_ativos}
                sub="categorias distintas"
              />
            </KpiRow>
            <ResponsiveContainer width="100%" height={Math.max(300, dados.g4_uso.length * 48)}>
              <BarChart layout="vertical" data={dados.g4_uso}>
                <CartesianGrid strokeDasharray="3 3" stroke={GRID_STROKE} />
                <XAxis type="number" stroke={AXIS_STROKE} tick={TICK_STYLE} />
                <YAxis type="category" dataKey="uso" stroke={AXIS_STROKE} tick={TICK_STYLE} width={100} />
                <Tooltip contentStyle={TOOLTIP_STYLE} />
                <Bar dataKey="total" name="Total" radius={[0, 3, 3, 0]}>
                  {dados.g4_uso.map((entry) => (
                    <Cell key={entry.uso} fill={corUso(entry.uso)} />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          </Secao>

          {/* ---------------------------------------------------------------- */}
          {/* Gráfico 5 — Top 10 Setores                                       */}
          {/* ---------------------------------------------------------------- */}
          <Secao>
            <SecaoTitulo numero={5} titulo="Top 10 Setores por CEPACs" />
            <KpiRow>
              <KpiCard
                label="Setor Líder"
                valor={dados.g5_setor_lider}
                sub="maior volume"
              />
              <KpiCard
                label="Total Top 10"
                valor={dados.g5_total_top10.toLocaleString("pt-BR")}
                sub="soma dos 10 maiores"
              />
              <KpiCard
                label="Setores Ativos"
                valor={dados.g5_setores_ativos}
                sub="com propostas"
              />
            </KpiRow>
            <ResponsiveContainer width="100%" height={380}>
              <BarChart layout="vertical" data={dados.g5_top_setores}>
                <CartesianGrid strokeDasharray="3 3" stroke={GRID_STROKE} />
                <XAxis type="number" stroke={AXIS_STROKE} tick={TICK_STYLE} />
                <YAxis type="category" dataKey="setor" stroke={AXIS_STROKE} tick={TICK_STYLE} width={120} />
                <Tooltip contentStyle={TOOLTIP_STYLE} />
                <Bar dataKey="total" name="Total CEPACs" radius={[0, 3, 3, 0]}>
                  {dados.g5_top_setores.map((entry, idx) => (
                    <Cell key={entry.setor} fill={PALETA_TOP10[idx % PALETA_TOP10.length]} />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          </Secao>

          {/* ---------------------------------------------------------------- */}
          {/* Gráfico 6 — Histograma Tempo de Análise                         */}
          {/* ---------------------------------------------------------------- */}
          <Secao>
            <SecaoTitulo numero={6} titulo="Tempo Médio de Análise de Propostas" />
            <KpiRow>
              <KpiCard
                label="Tempo Médio"
                valor={`${dados.g6_tempo_medio} dias`}
                sub="média geral"
              />
              <KpiCard
                label="Mais Rápido"
                valor={`${dados.g6_tempo_minimo} dias`}
                valorCor="#22c55e"
                sub="mínimo registrado"
              />
              <KpiCard
                label="Mais Lento"
                valor={`${dados.g6_tempo_maximo} dias`}
                valorCor="#ef4444"
                sub="máximo registrado"
              />
              <KpiCard
                label="Meta SLA"
                valor="60 dias"
                sub="prazo regulatório"
              />
            </KpiRow>
            <ResponsiveContainer width="100%" height={280}>
              <BarChart data={dados.g6_histograma}>
                <CartesianGrid strokeDasharray="3 3" stroke={GRID_STROKE} />
                <XAxis dataKey="faixa" stroke={AXIS_STROKE} tick={TICK_STYLE} />
                <YAxis stroke={AXIS_STROKE} tick={TICK_STYLE} />
                <Tooltip contentStyle={TOOLTIP_STYLE} />
                <Bar dataKey="quantidade" name="Quantidade" radius={[3, 3, 0, 0]}>
                  {dados.g6_histograma.map((entry) => (
                    <Cell key={entry.faixa} fill={corFaixa(entry.faixa)} />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          </Secao>

          {/* ---------------------------------------------------------------- */}
          {/* Gráfico 7 — Scatter Área x CEPACs                               */}
          {/* ---------------------------------------------------------------- */}
          <Secao>
            <SecaoTitulo numero={7} titulo="Área Total Construída × CEPACs" />
            <KpiRow>
              <KpiCard
                label="Área Média"
                valor={`${dados.g7_area_media.toFixed(0)} m²`}
                sub="média das propostas"
              />
              <KpiCard
                label="Média CEPAC/m²"
                valor={dados.g7_media_cepac_m2.toFixed(2)}
                sub="intensidade média"
              />
              <KpiCard
                label="Correlação"
                valor={`+${dados.g7_correlacao}`}
                valorCor={dados.g7_correlacao > 0.7 ? "#22c55e" : "#f59e0b"}
                sub="forte positiva"
              />
            </KpiRow>
            <ResponsiveContainer width="100%" height={320}>
              <ScatterChart>
                <CartesianGrid strokeDasharray="3 3" stroke={GRID_STROKE} />
                <XAxis
                  type="number"
                  dataKey="area_m2"
                  name="Área Total (m²)"
                  stroke={AXIS_STROKE}
                  tick={TICK_STYLE}
                  label={{ value: "Área Total (m²)", position: "insideBottom", offset: -4, fill: "rgba(255,255,255,0.5)", fontSize: 12 }}
                />
                <YAxis
                  type="number"
                  dataKey="cepac_total"
                  name="Quantidade de CEPACs"
                  stroke={AXIS_STROKE}
                  tick={TICK_STYLE}
                  label={{ value: "Qtd CEPACs", angle: -90, position: "insideLeft", fill: "rgba(255,255,255,0.5)", fontSize: 12 }}
                />
                <ZAxis range={[40, 40]} />
                <Tooltip contentStyle={TOOLTIP_STYLE} cursor={{ strokeDasharray: "3 3" }} />
                <Scatter data={dados.g7_scatter} fill="#0057B8" fillOpacity={0.7} />
              </ScatterChart>
            </ResponsiveContainer>
          </Secao>
        </>
      )}
      </div>
    </div>
  );
}
