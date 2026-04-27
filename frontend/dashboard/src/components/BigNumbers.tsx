/**
 * BigNumbers — 4 indicadores principais do snapshot.
 * Ordem: Capacidade | Saldo Disponível | Total Consumido | Em Análise
 * Itens 2-4 exibem % em relação à Capacidade Total de forma discreta.
 */
import React from "react";
import type { DashboardSnapshot } from "../types/api";

const formatM2 = (v: string | number): string =>
  new Intl.NumberFormat("pt-BR", { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(Number(v)) + " m²";

const pct = (valor: string | number, total: string | number): string => {
  const t = Number(total);
  if (!t) return "—";
  return ((Number(valor) / t) * 100).toFixed(1) + "%";
};

interface CardProps {
  titulo: string;
  valor: string;
  subtitulo: string;
  porcentagem?: string;
  corDestaque: string;
  corPct?: string;
  extra?: string;
}

const Card: React.FC<CardProps> = ({ titulo, valor, subtitulo, porcentagem, corDestaque, corPct = "#888", extra }) => (
  <div
    style={{
      background: "#fff",
      borderRadius: 8,
      padding: "20px 20px 16px",
      boxShadow: "0 1px 4px rgba(0,0,0,.10)",
      flex: "1 1 220px",
      minWidth: 200,
      borderTop: `4px solid ${corDestaque}`,
    }}
  >
    <p style={{ margin: "0 0 8px", fontSize: 12, color: "#666", fontWeight: 600, textTransform: "uppercase", letterSpacing: ".5px" }}>
      {titulo}
    </p>
    <div style={{ display: "flex", alignItems: "baseline", gap: 8, flexWrap: "wrap", marginBottom: 2 }}>
      <p style={{ margin: 0, fontSize: 26, fontWeight: 700, color: "#1a1a2e", lineHeight: 1.2 }}>
        {valor}
      </p>
      {porcentagem && (
        <span style={{ fontSize: 12, fontWeight: 500, color: corPct, whiteSpace: "nowrap" }}>
          {porcentagem} da cap.
        </span>
      )}
    </div>
    <p style={{ margin: 0, fontSize: 11, color: "#aaa" }}>{subtitulo}</p>
    {extra && <p style={{ margin: "4px 0 0", fontSize: 10, color: "#bbb" }}>{extra}</p>}
  </div>
);

interface Props {
  snapshot: DashboardSnapshot;
}

const BigNumbers: React.FC<Props> = ({ snapshot }) => {
  const cap = snapshot.capacidade_total_operacao;
  const saldoComReserva = Number(cap) - Number(snapshot.total_consumido_m2) - Number(snapshot.total_em_analise_m2);
  const reservaTecnica = saldoComReserva - Number(snapshot.saldo_geral_disponivel);
  const estoqueSetorial = Number(cap) - reservaTecnica;
  return (
    <div style={{ display: "flex", flexWrap: "wrap", gap: 16, marginBottom: 24 }}>
      <Card
        titulo="Capacidade da Operação"
        valor={formatM2(estoqueSetorial)}
        subtitulo="Estoque setorial (sem reserva técnica)"
        corDestaque="#34a853"
        extra={`c/ reserva técnica: ${formatM2(cap)}`}
      />
      <Card
        titulo="Saldo Geral Disponível"
        valor={formatM2(snapshot.saldo_geral_disponivel)}
        subtitulo="Livre para novas vinculações"
        porcentagem={pct(snapshot.saldo_geral_disponivel, cap)}
        corPct="#34a853"
        corDestaque="#1a73e8"
        extra={`c/ reserva técnica: ${formatM2(saldoComReserva)}`}
      />
      <Card
        titulo="Total Consumido"
        valor={formatM2(snapshot.total_consumido_m2)}
        subtitulo="ACA + NUVEM, todos os setores"
        porcentagem={pct(snapshot.total_consumido_m2, cap)}
        corPct="#ea4335"
        corDestaque="#ea4335"
      />
      <Card
        titulo="Em Análise"
        valor={formatM2(snapshot.total_em_analise_m2)}
        subtitulo="Pedidos aguardando aprovação"
        porcentagem={pct(snapshot.total_em_analise_m2, cap)}
        corPct="#fbbc04"
        corDestaque="#fbbc04"
      />
    </div>
  );
};

export default BigNumbers;
