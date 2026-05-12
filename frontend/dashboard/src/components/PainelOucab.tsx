/**
 * PainelOucab — painel dedicado à OUCAB com 6 séries por setor.
 *
 * Big Numbers: R-NI global (consumido / disponível / %)
 * Gráfico: barras empilhadas R-Inc, R-NI, NR (consumido + em_analise) por setor
 * Filtro: oculta setores com todas as 6 séries = 0
 */
import React, { useEffect, useState } from "react";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from "recharts";
import { fetchOucabSnapshot } from "../api/dashboard";
import type { OucabSnapshot, OucabSetor } from "../types/api";

// ---------------------------------------------------------------------------
// Formatação
// ---------------------------------------------------------------------------

const fmtM2 = (v: string | number) =>
  new Intl.NumberFormat("pt-BR", { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(
    Number(v)
  ) + " m²";

const fmtPct = (v: number) => v.toFixed(1) + "%";

// ---------------------------------------------------------------------------
// Função auxiliar: setor tem algum consumo ou analise
// ---------------------------------------------------------------------------

function temDados(s: OucabSetor): boolean {
  return (
    Number(s.r_inc_consumido) > 0 ||
    Number(s.r_inc_em_analise) > 0 ||
    Number(s.r_nao_inc_consumido) > 0 ||
    Number(s.r_nao_inc_em_analise) > 0 ||
    Number(s.nr_consumido) > 0 ||
    Number(s.nr_em_analise) > 0
  );
}

// ---------------------------------------------------------------------------
// Big Number card simples
// ---------------------------------------------------------------------------

interface BNProps {
  titulo: string;
  valor: string;
  subtitulo: string;
  cor: string;
  destaque?: string;
}

const BNCard: React.FC<BNProps> = ({ titulo, valor, subtitulo, cor, destaque }) => (
  <div
    style={{
      background: "#fff",
      borderRadius: 8,
      padding: "18px 20px 14px",
      boxShadow: "0 1px 4px rgba(0,0,0,.10)",
      flex: "1 1 200px",
      minWidth: 180,
      borderTop: `4px solid ${cor}`,
    }}
  >
    <p style={{ margin: "0 0 6px", fontSize: 11, color: "#666", fontWeight: 600, textTransform: "uppercase", letterSpacing: ".5px" }}>
      {titulo}
    </p>
    <p style={{ margin: "0 0 2px", fontSize: 24, fontWeight: 700, color: "#1a1a2e", lineHeight: 1.2 }}>
      {valor}
    </p>
    <p style={{ margin: 0, fontSize: 11, color: "#aaa" }}>{subtitulo}</p>
    {destaque && (
      <p style={{ margin: "4px 0 0", fontSize: 10, color: "#bbb" }}>{destaque}</p>
    )}
  </div>
);

// ---------------------------------------------------------------------------
// Tooltip customizado
// ---------------------------------------------------------------------------

interface TooltipProps {
  active?: boolean;
  payload?: { name: string; value: number; fill: string }[];
  label?: string;
}

const TooltipOucab: React.FC<TooltipProps> = ({ active, payload, label }) => {
  if (!active || !payload?.length) return null;
  const total = payload.reduce((s, p) => s + p.value, 0);
  return (
    <div
      style={{
        background: "#fff",
        border: "1px solid #e0e4ea",
        borderRadius: 6,
        padding: "10px 14px",
        fontSize: 13,
        boxShadow: "0 2px 8px rgba(0,0,0,.12)",
        maxWidth: 260,
      }}
    >
      <p style={{ margin: "0 0 6px", fontWeight: 700, color: "#1a1a2e" }}>{label}</p>
      {payload.map((p) => (
        <p key={p.name} style={{ margin: "2px 0", color: "#333" }}>
          <span
            style={{
              display: "inline-block",
              width: 10,
              height: 10,
              background: p.fill,
              borderRadius: 2,
              marginRight: 6,
              verticalAlign: "middle",
            }}
          />
          {p.name}: {new Intl.NumberFormat("pt-BR", { maximumFractionDigits: 0 }).format(p.value)} m²
        </p>
      ))}
      <p style={{ margin: "6px 0 0", borderTop: "1px solid #eee", paddingTop: 4, color: "#555", fontWeight: 600 }}>
        Total: {new Intl.NumberFormat("pt-BR", { maximumFractionDigits: 0 }).format(total)} m²
      </p>
    </div>
  );
};

// ---------------------------------------------------------------------------
// Componente principal
// ---------------------------------------------------------------------------

const TETO_GLOBAL_R_NI = 675000;

const CORES = {
  rInc:       "#34A853",
  rIncAnal:   "#A8D5B5",
  rNi:        "#1A73E8",
  rNiAnal:    "#A8C7F5",
  nr:         "#E8710A",
  nrAnal:     "#F5C08A",
};

const PainelOucab: React.FC = () => {
  const [data, setData] = useState<OucabSnapshot | null>(null);
  const [loading, setLoading] = useState(true);
  const [erro, setErro] = useState("");

  useEffect(() => {
    setLoading(true);
    fetchOucabSnapshot()
      .then(setData)
      .catch(() => setErro("Erro ao carregar dados OUCAB."))
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <p style={{ color: "#666", padding: "32px 0", textAlign: "center" }}>Carregando OUCAB…</p>;
  if (erro) return <p style={{ color: "#c62828", padding: "16px" }}>{erro}</p>;
  if (!data) return null;

  const setoresComDados = data.setores.filter(temDados);
  const pct = data.pct_r_nao_inc_global;
  const corGlobal = pct >= 90 ? "#E24B4A" : pct >= 70 ? "#EF9F27" : "#1A73E8";

  const chartData = setoresComDados.map((s) => ({
    nome: s.nome.replace("Setor ", ""),
    "R-Inc Consumido":   Number(s.r_inc_consumido),
    "R-Inc Em Análise":  Number(s.r_inc_em_analise),
    "R-NI Consumido":    Number(s.r_nao_inc_consumido),
    "R-NI Em Análise":   Number(s.r_nao_inc_em_analise),
    "NR Consumido":      Number(s.nr_consumido),
    "NR Em Análise":     Number(s.nr_em_analise),
  }));

  return (
    <div>
      {/* Big Numbers */}
      <div style={{ display: "flex", flexWrap: "wrap", gap: 16, marginBottom: 24 }}>
        <BNCard
          titulo="R Não-Incentivado — Global"
          valor={fmtM2(data.r_nao_inc_consumido_global)}
          subtitulo={`${fmtPct(pct)} do teto de 675.000 m² (art. 39 §2)`}
          cor={corGlobal}
          destaque={`Disponível: ${fmtM2(data.r_nao_inc_disponivel_global)}`}
        />
        {data.setores
          .filter((s) => s.nome === "Setor B" && Number(s.r_nao_inc_consumido) > 0)
          .map((s) => (
            <BNCard
              key="b"
              titulo="Setor B — R Não-Incentivado"
              valor={fmtM2(s.r_nao_inc_consumido)}
              subtitulo="Windsor (DEFERIDO)"
              cor="#1A73E8"
              destaque={s.r_disponivel ? `Disponível: ${fmtM2(s.r_disponivel)}` : undefined}
            />
          ))}
        {data.setores
          .filter((s) => s.nome === "Setor H" && Number(s.nr_consumido) > 0)
          .map((s) => (
            <BNCard
              key="h"
              titulo="Setor H — NR Consumido"
              valor={fmtM2(s.nr_consumido)}
              subtitulo="BSP (DEFERIDO)"
              cor="#E8710A"
              destaque={s.nr_disponivel ? `Disponível: ${fmtM2(s.nr_disponivel)}` : undefined}
            />
          ))}
        {data.setores
          .filter((s) => Number(s.r_inc_consumido) > 0)
          .map((s) => (
            <BNCard
              key={`inc-${s.nome}`}
              titulo={`${s.nome} — R Incentivado`}
              valor={fmtM2(s.r_inc_consumido)}
              subtitulo="HIS/EHIS (art. 5º IX)"
              cor="#34A853"
            />
          ))}
      </div>

      {/* Gráfico de barras */}
      {chartData.length > 0 ? (
        <div
          style={{
            background: "#fff",
            borderRadius: 8,
            padding: "20px",
            boxShadow: "0 1px 4px rgba(0,0,0,.10)",
            marginBottom: 24,
          }}
        >
          <h3 style={{ margin: "0 0 16px", fontSize: 14, fontWeight: 700, color: "#1a1a2e" }}>
            Ocupação por Setor — 6 séries (R-Inc / R-NI / NR)
          </h3>
          <ResponsiveContainer width="100%" height={340}>
            <BarChart data={chartData} margin={{ top: 8, right: 24, left: 16, bottom: 8 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
              <XAxis dataKey="nome" tick={{ fontSize: 12 }} />
              <YAxis
                tickFormatter={(v) => new Intl.NumberFormat("pt-BR", { maximumFractionDigits: 0 }).format(v)}
                tick={{ fontSize: 11 }}
                width={80}
              />
              <Tooltip content={<TooltipOucab />} />
              <Legend wrapperStyle={{ fontSize: 12, paddingTop: 12 }} />
              <Bar dataKey="R-Inc Consumido"  stackId="rInc" fill={CORES.rInc}    radius={[0, 0, 0, 0]} />
              <Bar dataKey="R-Inc Em Análise" stackId="rInc" fill={CORES.rIncAnal} radius={[3, 3, 0, 0]} />
              <Bar dataKey="R-NI Consumido"   stackId="rNi"  fill={CORES.rNi}     radius={[0, 0, 0, 0]} />
              <Bar dataKey="R-NI Em Análise"  stackId="rNi"  fill={CORES.rNiAnal}  radius={[3, 3, 0, 0]} />
              <Bar dataKey="NR Consumido"     stackId="nr"   fill={CORES.nr}      radius={[0, 0, 0, 0]} />
              <Bar dataKey="NR Em Análise"    stackId="nr"   fill={CORES.nrAnal}   radius={[3, 3, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      ) : (
        <div
          style={{
            background: "#fff",
            borderRadius: 8,
            padding: "32px 20px",
            textAlign: "center",
            color: "#888",
            boxShadow: "0 1px 4px rgba(0,0,0,.10)",
            marginBottom: 24,
          }}
        >
          <p style={{ margin: 0 }}>Nenhum setor com consumo ou análise registrado.</p>
        </div>
      )}

      {/* Tabela de setores */}
      <div
        style={{
          background: "#fff",
          borderRadius: 8,
          padding: "20px",
          boxShadow: "0 1px 4px rgba(0,0,0,.10)",
          marginBottom: 24,
          overflowX: "auto",
        }}
      >
        <h3 style={{ margin: "0 0 14px", fontSize: 14, fontWeight: 700, color: "#1a1a2e" }}>
          Detalhe por Setor
        </h3>
        <table style={{ width: "100%", borderCollapse: "collapse", fontSize: 13 }}>
          <thead>
            <tr style={{ background: "#f8f9fa" }}>
              <th style={thStyle}>Setor</th>
              <th style={{ ...thStyle, color: CORES.rInc }}>R-Inc Cons.</th>
              <th style={{ ...thStyle, color: CORES.rInc }}>R-Inc Anál.</th>
              <th style={{ ...thStyle, color: CORES.rNi }}>R-NI Cons.</th>
              <th style={{ ...thStyle, color: CORES.rNi }}>R-NI Anál.</th>
              <th style={{ ...thStyle, color: CORES.nr }}>NR Cons.</th>
              <th style={{ ...thStyle, color: CORES.nr }}>NR Anál.</th>
              <th style={thStyle}>Disp. R</th>
              <th style={thStyle}>Disp. NR</th>
            </tr>
          </thead>
          <tbody>
            {data.setores.map((s, i) => {
              const isAtivo = temDados(s);
              return (
                <tr
                  key={s.nome}
                  style={{
                    background: i % 2 === 0 ? "#fff" : "#fafafa",
                    opacity: isAtivo ? 1 : 0.5,
                  }}
                >
                  <td style={{ ...tdStyle, fontWeight: isAtivo ? 600 : 400 }}>{s.nome}</td>
                  <td style={tdNum}>{fmtN(s.r_inc_consumido)}</td>
                  <td style={tdNum}>{fmtN(s.r_inc_em_analise)}</td>
                  <td style={{ ...tdNum, color: Number(s.r_nao_inc_consumido) > 0 ? CORES.rNi : "#aaa" }}>
                    {fmtN(s.r_nao_inc_consumido)}
                  </td>
                  <td style={tdNum}>{fmtN(s.r_nao_inc_em_analise)}</td>
                  <td style={{ ...tdNum, color: Number(s.nr_consumido) > 0 ? CORES.nr : "#aaa" }}>
                    {fmtN(s.nr_consumido)}
                  </td>
                  <td style={tdNum}>{fmtN(s.nr_em_analise)}</td>
                  <td style={tdNum}>{s.r_disponivel !== null ? fmtN(s.r_disponivel) : "—"}</td>
                  <td style={tdNum}>{s.nr_disponivel !== null ? fmtN(s.nr_disponivel) : "—"}</td>
                </tr>
              );
            })}
          </tbody>
          <tfoot>
            <tr style={{ background: "#f0f4ff", fontWeight: 700 }}>
              <td style={{ ...tdStyle }}>TOTAL</td>
              <td style={tdNum}>{fmtN(sum(data.setores, "r_inc_consumido"))}</td>
              <td style={tdNum}>{fmtN(sum(data.setores, "r_inc_em_analise"))}</td>
              <td style={{ ...tdNum, color: CORES.rNi }}>{fmtN(sum(data.setores, "r_nao_inc_consumido"))}</td>
              <td style={tdNum}>{fmtN(sum(data.setores, "r_nao_inc_em_analise"))}</td>
              <td style={{ ...tdNum, color: CORES.nr }}>{fmtN(sum(data.setores, "nr_consumido"))}</td>
              <td style={tdNum}>{fmtN(sum(data.setores, "nr_em_analise"))}</td>
              <td style={tdNum}>—</td>
              <td style={tdNum}>—</td>
            </tr>
          </tfoot>
        </table>
      </div>

      {/* Nota legal */}
      <div
        style={{
          background: "#f0f4ff",
          border: "1px solid #c7d9f8",
          borderRadius: 6,
          padding: "12px 16px",
          fontSize: 12,
          color: "#3c4f7a",
          marginBottom: 16,
        }}
      >
        <strong>Teto cross-setor R Não-Incentivado:</strong> 675.000 m² (art. 39 §2, Lei 15.893/2013) —
        limitação que se aplica ao conjunto de todos os setores. Atual: {fmtM2(data.r_nao_inc_consumido_global)} ({fmtPct(pct)}).
      </div>
    </div>
  );
};

// ---------------------------------------------------------------------------
// Helpers de estilo + formatação
// ---------------------------------------------------------------------------

const thStyle: React.CSSProperties = {
  padding: "8px 10px",
  textAlign: "left",
  fontWeight: 600,
  fontSize: 12,
  color: "#555",
  borderBottom: "2px solid #e0e4ea",
  whiteSpace: "nowrap",
};

const tdStyle: React.CSSProperties = {
  padding: "7px 10px",
  borderBottom: "1px solid #f0f0f0",
  whiteSpace: "nowrap",
};

const tdNum: React.CSSProperties = {
  ...tdStyle,
  textAlign: "right",
  fontVariantNumeric: "tabular-nums",
  color: "#333",
};

const fmtN = (v: string | number | null) => {
  if (v === null || v === undefined) return "—";
  const n = Number(v);
  if (n === 0) return <span style={{ color: "#ccc" }}>—</span>;
  return new Intl.NumberFormat("pt-BR", { maximumFractionDigits: 2 }).format(n);
};

type SetorNumKey = keyof Pick<
  OucabSetor,
  "r_inc_consumido" | "r_inc_em_analise" | "r_nao_inc_consumido" | "r_nao_inc_em_analise" | "nr_consumido" | "nr_em_analise"
>;

const sum = (setores: OucabSetor[], key: SetorNumKey): number =>
  setores.reduce((acc, s) => acc + Number(s[key]), 0);

// Suprime aviso de variável não usada para TETO_GLOBAL_R_NI
void TETO_GLOBAL_R_NI;

export default PainelOucab;
