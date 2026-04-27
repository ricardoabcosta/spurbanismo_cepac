import React, { useEffect, useState } from "react";
import { fetchCepacSnapshot } from "../api/dashboard";
import type { CepacSetor, CepacSnapshot } from "../types/api";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function fmtInt(n: number): string {
  return n.toLocaleString("pt-BR");
}

function dash(n: number): string {
  return n === 0 ? "—" : fmtInt(n);
}

// ---------------------------------------------------------------------------
// KPI Card
// ---------------------------------------------------------------------------

interface KpiProps {
  label: string;
  value: number;
  sub?: string;
}

function KpiCard({ label, value, sub }: KpiProps) {
  return (
    <div
      style={{
        background: "#fff",
        borderRadius: 8,
        padding: "18px 20px",
        boxShadow: "0 2px 8px rgba(0,0,0,.07)",
        flex: "1 1 160px",
        minWidth: 160,
      }}
    >
      <div style={{ fontSize: 11, fontWeight: 600, color: "#888", textTransform: "uppercase", letterSpacing: ".5px", marginBottom: 6 }}>
        {label}
      </div>
      <div style={{ fontSize: 26, fontWeight: 700, color: "#1a1a2e", lineHeight: 1.1 }}>
        {fmtInt(value)}
      </div>
      {sub && (
        <div style={{ fontSize: 11, color: "#999", marginTop: 4 }}>{sub}</div>
      )}
    </div>
  );
}

// ---------------------------------------------------------------------------
// Table
// ---------------------------------------------------------------------------

interface TabelaCepacProps {
  titulo: string;
  cor: string;
  setores: CepacSetor[];
  getAca: (s: CepacSetor) => number;
  getParametros: (s: CepacSetor) => number;
}

function TabelaCepac({ titulo, cor, setores, getAca, getParametros }: TabelaCepacProps) {
  const totalAca = setores.reduce((acc, s) => acc + getAca(s), 0);
  const totalParam = setores.reduce((acc, s) => acc + getParametros(s), 0);

  const thStyle: React.CSSProperties = {
    padding: "8px 12px",
    background: cor,
    color: "#fff",
    fontWeight: 600,
    fontSize: 12,
    textAlign: "left",
    whiteSpace: "nowrap",
  };
  const tdStyle: React.CSSProperties = {
    padding: "8px 12px",
    borderBottom: "1px solid #f0f0f0",
    fontSize: 13,
    color: "#333",
  };
  const tdNum: React.CSSProperties = { ...tdStyle, textAlign: "right", fontVariantNumeric: "tabular-nums" };
  const tfStyle: React.CSSProperties = {
    padding: "8px 12px",
    background: "#f5f7fa",
    fontSize: 12,
    fontWeight: 700,
    color: "#333",
    textAlign: "right",
    fontVariantNumeric: "tabular-nums",
  };

  return (
    <div style={{ flex: "1 1 400px", background: "#fff", borderRadius: 8, boxShadow: "0 2px 8px rgba(0,0,0,.07)", overflow: "hidden" }}>
      <div style={{ background: cor, padding: "12px 16px" }}>
        <span style={{ color: "#fff", fontWeight: 700, fontSize: 13, textTransform: "uppercase", letterSpacing: ".5px" }}>
          {titulo}
        </span>
      </div>
      <table style={{ width: "100%", borderCollapse: "collapse" }}>
        <thead>
          <tr>
            <th style={{ ...thStyle, background: "#f0f2f5", color: "#555" }}>Setor</th>
            <th style={{ ...thStyle, background: "#f0f2f5", color: "#555", textAlign: "right" }}>ACA</th>
            <th style={{ ...thStyle, background: "#f0f2f5", color: "#555", textAlign: "right" }}>Uso e Parâmetros</th>
          </tr>
        </thead>
        <tbody>
          {setores.map((s) => (
            <tr key={s.nome}>
              <td style={tdStyle}>{s.nome}</td>
              <td style={tdNum}>{dash(getAca(s))}</td>
              <td style={tdNum}>{dash(getParametros(s))}</td>
            </tr>
          ))}
        </tbody>
        <tfoot>
          <tr>
            <td style={{ ...tfStyle, textAlign: "left" }}>Total</td>
            <td style={tfStyle}>{fmtInt(totalAca)}</td>
            <td style={tfStyle}>{fmtInt(totalParam)}</td>
          </tr>
        </tfoot>
      </table>
    </div>
  );
}

// ---------------------------------------------------------------------------
// PainelCepac
// ---------------------------------------------------------------------------

const PainelCepac: React.FC = () => {
  const [data, setData] = useState<CepacSnapshot | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    setLoading(true);
    fetchCepacSnapshot()
      .then(setData)
      .catch(() => setError("Erro ao carregar dados de CEPACs."))
      .finally(() => setLoading(false));
  }, []);

  if (loading) {
    return (
      <div style={{ display: "flex", justifyContent: "center", padding: "48px 0", color: "#666" }}>
        <p>Carregando dados de CEPACs...</p>
      </div>
    );
  }

  if (error) {
    return (
      <div style={{ background: "#ffebee", border: "1px solid #ef9a9a", borderRadius: 6, padding: "12px 16px", color: "#c62828", fontSize: 14 }}>
        {error}
      </div>
    );
  }

  if (!data) return null;

  const allZero =
    data.cepacs_totais === 0 &&
    data.cepacs_leiloados === 0 &&
    data.cepacs_colocacao_privada === 0;

  const totalConvertido = data.setores.reduce(
    (acc, s) => acc + s.cepacs_convertidos_aca + s.cepacs_convertidos_parametros,
    0
  );

  return (
    <div>
      {allZero && (
        <div style={{ background: "#fff8e1", border: "1px solid #ffe082", borderRadius: 6, padding: "10px 16px", marginBottom: 20, fontSize: 13, color: "#795548" }}>
          Parâmetros globais de CEPAC ainda não configurados. Acesse <strong>Administração</strong> para definir os valores.
        </div>
      )}

      {/* KPIs */}
      <div style={{ display: "flex", gap: 12, flexWrap: "wrap", marginBottom: 24 }}>
        <KpiCard label="CEPACs Totais" value={data.cepacs_totais} />
        <KpiCard label="Leiloados" value={data.cepacs_leiloados} />
        <KpiCard
          label="CEPACs em Circulação"
          value={data.cepacs_leiloados + data.cepacs_colocacao_privada - totalConvertido}
          sub="Leiloados + Col. Privada − Convertidos"
        />
        <KpiCard label="Colocação Privada" value={data.cepacs_colocacao_privada} />
        <KpiCard
          label="CEPAC Saldo"
          value={data.cepacs_totais - data.cepacs_leiloados - data.cepacs_colocacao_privada}
          sub="Totais − Leiloados − Col. Privada"
        />
      </div>

      {/* Tables */}
      <div style={{ display: "flex", gap: 16, flexWrap: "wrap", alignItems: "flex-start" }}>
        <TabelaCepac
          titulo="CEPAC Convertido"
          cor="#185FA5"
          setores={data.setores}
          getAca={(s) => s.cepacs_convertidos_aca}
          getParametros={(s) => s.cepacs_convertidos_parametros}
        />
        <TabelaCepac
          titulo="CEPAC Desvinculado"
          cor="#1D9E75"
          setores={data.setores}
          getAca={(s) => s.cepacs_desvinculados_aca}
          getParametros={(s) => s.cepacs_desvinculados_parametros}
        />
      </div>
    </div>
  );
};

export default PainelCepac;
