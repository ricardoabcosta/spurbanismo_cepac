/**
 * BigNumbers — 4 cartões com indicadores principais do snapshot.
 */
import React from "react";
import type { DashboardSnapshot } from "../types/api";

const formatBRL = (v: string | number): string =>
  new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" }).format(Number(v));

const formatM2 = (v: string | number): string =>
  new Intl.NumberFormat("pt-BR", { maximumFractionDigits: 2 }).format(Number(v)) + " m²";

const formatUnidades = (v: number): string =>
  new Intl.NumberFormat("pt-BR").format(v);

interface CardProps {
  titulo: string;
  valor: string;
  subtitulo: string;
  corDestaque?: string;
}

const Card: React.FC<CardProps> = ({ titulo, valor, subtitulo, corDestaque = "#1a73e8" }) => (
  <div
    style={{
      background: "#fff",
      borderRadius: 8,
      padding: "24px 20px",
      boxShadow: "0 1px 4px rgba(0,0,0,.10)",
      flex: "1 1 220px",
      minWidth: 200,
      borderTop: `4px solid ${corDestaque}`,
    }}
  >
    <p style={{ margin: "0 0 8px", fontSize: 13, color: "#666", fontWeight: 600, textTransform: "uppercase", letterSpacing: ".5px" }}>
      {titulo}
    </p>
    <p style={{ margin: "0 0 6px", fontSize: 26, fontWeight: 700, color: "#1a1a2e", lineHeight: 1.2 }}>
      {valor}
    </p>
    <p style={{ margin: 0, fontSize: 12, color: "#888" }}>{subtitulo}</p>
  </div>
);

interface Props {
  snapshot: DashboardSnapshot;
}

const BigNumbers: React.FC<Props> = ({ snapshot }) => (
  <div
    style={{
      display: "flex",
      flexWrap: "wrap",
      gap: 16,
      marginBottom: 24,
    }}
  >
    <Card
      titulo="Custo Total Incorrido"
      valor={formatBRL(snapshot.custo_total_incorrido)}
      subtitulo="Obras e intervenções acumuladas"
      corDestaque="#1a73e8"
    />
    <Card
      titulo="Capacidade da Operação"
      valor={formatM2(snapshot.capacidade_total_operacao)}
      subtitulo="Teto máximo legal OUCAE"
      corDestaque="#34a853"
    />
    <Card
      titulo="Saldo Geral Disponível"
      valor={formatM2(snapshot.saldo_geral_disponivel)}
      subtitulo="Exclui em análise"
      corDestaque="#fbbc04"
    />
    <Card
      titulo="CEPACs em Circulação"
      valor={`${formatUnidades(snapshot.cepacs_em_circulacao)} títulos`}
      subtitulo="Estoque disponível para negociação"
      corDestaque="#ea4335"
    />
  </div>
);

export default BigNumbers;
