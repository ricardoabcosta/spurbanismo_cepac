import { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { buscarPropostaAE } from "../api/portal";
import type { PropostaAEOut, CertidaoItem } from "../types/api";

// ---------------------------------------------------------------------------
// Tipos locais
// ---------------------------------------------------------------------------

type SituacaoCert = "ANALISE" | "VALIDA" | "CANCELADA";
type StatusPA = "ANALISE" | "DEFERIDO" | "INDEFERIDO";

// ---------------------------------------------------------------------------
// Helpers de cor
// ---------------------------------------------------------------------------

const STATUS_PA_CONFIG: Record<StatusPA, { bg: string; color: string; label: string }> = {
  ANALISE:    { bg: "#2a5298", color: "#fff", label: "Em Análise" },
  DEFERIDO:   { bg: "#34a853", color: "#fff", label: "Deferido" },
  INDEFERIDO: { bg: "#ea4335", color: "#fff", label: "Indeferido" },
};

const CERT_CONFIG: Record<SituacaoCert, { bg: string; color: string; label: string }> = {
  ANALISE:   { bg: "#2a5298", color: "#fff", label: "Em Análise" },
  VALIDA:    { bg: "#34a853", color: "#fff", label: "Válida" },
  CANCELADA: { bg: "#ea4335", color: "#fff", label: "Cancelada" },
};

// ---------------------------------------------------------------------------
// Formatadores
// ---------------------------------------------------------------------------

function fmt_data(iso: string | null | undefined): string {
  if (!iso) return "—";
  const [y, m, d] = iso.slice(0, 10).split("-");
  return `${d}/${m}/${y}`;
}

function fmt_dec(v: string | number | null | undefined): string {
  if (v === null || v === undefined || v === "") return "—";
  return Number(v).toLocaleString("pt-BR", { minimumFractionDigits: 2 });
}

function fmt_int(v: number | null | undefined): string {
  if (v === null || v === undefined) return "—";
  return v.toLocaleString("pt-BR");
}

function val(v: string | null | undefined): string {
  if (v === null || v === undefined || v === "") return "—";
  return v;
}

// ---------------------------------------------------------------------------
// Sub-componentes
// ---------------------------------------------------------------------------

function Badge({ label, bg, color, size = "sm" }: { label: string; bg: string; color: string; size?: "sm" | "lg" }) {
  return (
    <span
      style={{
        display: "inline-block",
        borderRadius: "20px",
        padding: size === "lg" ? "7px 20px" : "3px 12px",
        background: bg,
        color: color,
        fontSize: size === "lg" ? "15px" : "12px",
        fontWeight: 700,
        whiteSpace: "nowrap" as const,
        letterSpacing: "0.03em",
      }}
    >
      {label}
    </span>
  );
}

function Campo({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div style={{ display: "flex", flexDirection: "column" as const, gap: "4px" }}>
      <span style={{ fontSize: "11px", fontWeight: 600, color: "#8896a8", textTransform: "uppercase" as const, letterSpacing: "0.07em" }}>
        {label}
      </span>
      <span style={{ fontSize: "14px", fontWeight: 500, color: "#1a2533" }}>
        {children}
      </span>
    </div>
  );
}

function Card({ titulo, children, cols = 3 }: { titulo: string; children: React.ReactNode; cols?: number }) {
  return (
    <div
      style={{
        background: "#fff",
        borderRadius: "8px",
        boxShadow: "0 2px 12px rgba(0,0,0,0.08)",
        padding: "24px",
        marginBottom: "20px",
      }}
    >
      <h2
        style={{
          fontSize: "13px",
          fontWeight: 700,
          color: "#003087",
          textTransform: "uppercase" as const,
          letterSpacing: "0.1em",
          margin: "0 0 20px 0",
          paddingBottom: "12px",
          borderBottom: "2px solid #eef1f6",
        }}
      >
        {titulo}
      </h2>
      <div
        style={{
          display: "grid",
          gridTemplateColumns: `repeat(${cols}, 1fr)`,
          gap: "20px 28px",
        }}
      >
        {children}
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Skeleton de carregamento
// ---------------------------------------------------------------------------

function SkeletonCard({ rows = 3, cols = 3 }: { rows?: number; cols?: number }) {
  return (
    <div
      style={{
        background: "#fff",
        borderRadius: "8px",
        boxShadow: "0 2px 12px rgba(0,0,0,0.08)",
        padding: "24px",
        marginBottom: "20px",
      }}
    >
      <style>{`
        @keyframes shimmer {
          0%   { background-position: -600px 0; }
          100% { background-position: 600px 0; }
        }
      `}</style>
      <div
        style={{
          height: "14px",
          width: "140px",
          borderRadius: "4px",
          marginBottom: "20px",
          backgroundImage: "linear-gradient(90deg, #eef1f6 25%, #dde3ec 50%, #eef1f6 75%)",
          backgroundSize: "600px 100%",
          animation: "shimmer 1.4s infinite linear",
        }}
      />
      <div style={{ display: "grid", gridTemplateColumns: `repeat(${cols}, 1fr)`, gap: "20px 28px" }}>
        {Array.from({ length: rows * cols }).map((_, i) => (
          <div key={i}>
            <div
              style={{
                height: "10px",
                width: "70%",
                borderRadius: "3px",
                marginBottom: "8px",
                backgroundImage: "linear-gradient(90deg, #eef1f6 25%, #dde3ec 50%, #eef1f6 75%)",
                backgroundSize: "600px 100%",
                animation: "shimmer 1.4s infinite linear",
              }}
            />
            <div
              style={{
                height: "16px",
                width: "90%",
                borderRadius: "3px",
                backgroundImage: "linear-gradient(90deg, #eef1f6 25%, #dde3ec 50%, #eef1f6 75%)",
                backgroundSize: "600px 100%",
                animation: "shimmer 1.4s infinite linear",
              }}
            />
          </div>
        ))}
      </div>
    </div>
  );
}

function LoadingSkeleton() {
  return (
    <div style={{ fontFamily: "system-ui, -apple-system, sans-serif", background: "#f5f7fa", minHeight: "100vh" }}>
      <style>{`
        @keyframes shimmer {
          0%   { background-position: -600px 0; }
          100% { background-position: 600px 0; }
        }
      `}</style>
      {/* Hero placeholder */}
      <div style={{ height: "160px", background: "#003087", marginBottom: "0" }} />
      {/* Status bar placeholder */}
      <div style={{ height: "56px", background: "#002470" }} />
      <div style={{ maxWidth: "1100px", margin: "0 auto", padding: "24px" }}>
        <SkeletonCard rows={2} cols={3} />
        <SkeletonCard rows={2} cols={2} />
        <SkeletonCard rows={1} cols={3} />
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Histórico de certidões
// ---------------------------------------------------------------------------

function HistoricoCertidoes({ certidoes }: { certidoes: CertidaoItem[] }) {
  const [hoveredRow, setHoveredRow] = useState<string | null>(null);

  if (certidoes.length === 0) {
    return (
      <p style={{ color: "#8896a8", fontSize: "14px", fontStyle: "italic", margin: 0, padding: "8px 0" }}>
        Nenhuma certidão registrada para esta proposta.
      </p>
    );
  }

  const ordenadas = [...certidoes].sort((a, b) => {
    if (!a.data_emissao && !b.data_emissao) return 0;
    if (!a.data_emissao) return 1;
    if (!b.data_emissao) return -1;
    return new Date(b.data_emissao).getTime() - new Date(a.data_emissao).getTime();
  });

  const thStyle: React.CSSProperties = {
    background: "#003087",
    color: "#fff",
    padding: "11px 12px",
    textAlign: "left" as const,
    fontSize: "11px",
    fontWeight: 700,
    textTransform: "uppercase" as const,
    letterSpacing: "0.06em",
    whiteSpace: "nowrap" as const,
  };

  const thRight: React.CSSProperties = { ...thStyle, textAlign: "right" as const };

  const tdStyle: React.CSSProperties = {
    padding: "11px 12px",
    borderBottom: "1px solid #eef1f6",
    fontSize: "13px",
    color: "#1a2533",
    verticalAlign: "middle" as const,
  };

  return (
    <div style={{ overflowX: "auto" }}>
      <table style={{ width: "100%", borderCollapse: "collapse" as const, fontSize: "13px" }}>
        <thead>
          <tr>
            <th style={thStyle}>Nº Certidão</th>
            <th style={thStyle}>Tipo</th>
            <th style={thStyle}>Data Emissão</th>
            <th style={thStyle}>Situação</th>
            <th style={thStyle}>Uso ACA</th>
            <th style={thRight}>ACA Total m²</th>
            <th style={thRight}>CEPAC Total</th>
            <th style={thRight}>NUVEM Total m²</th>
            <th style={thStyle}>Obs</th>
          </tr>
        </thead>
        <tbody>
          {ordenadas.map((cert, idx) => {
            const sit = cert.situacao as SituacaoCert;
            const cfg = CERT_CONFIG[sit] ?? { bg: "#8896a8", color: "#fff", label: cert.situacao };
            const isHovered = hoveredRow === cert.id;
            const isEven = idx % 2 === 1;
            const rowBg = isHovered ? "#e8eef8" : isEven ? "#f8fafc" : "#fff";
            return (
              <tr
                key={cert.id}
                onMouseEnter={() => setHoveredRow(cert.id)}
                onMouseLeave={() => setHoveredRow(null)}
                style={{ background: rowBg, transition: "background 0.15s" }}
              >
                <td style={{ ...tdStyle, fontWeight: 700, color: "#003087", whiteSpace: "nowrap" as const }}>
                  {cert.numero_certidao}
                </td>
                <td style={{ ...tdStyle, whiteSpace: "nowrap" as const }}>{cert.tipo}</td>
                <td style={{ ...tdStyle, whiteSpace: "nowrap" as const }}>{fmt_data(cert.data_emissao)}</td>
                <td style={tdStyle}>
                  <Badge label={cfg.label} bg={cfg.bg} color={cfg.color} />
                </td>
                <td style={tdStyle}>{cert.uso_aca ?? "—"}</td>
                <td style={{ ...tdStyle, textAlign: "right" as const }}>{fmt_dec(cert.aca_total_m2)}</td>
                <td style={{ ...tdStyle, textAlign: "right" as const, fontWeight: 600 }}>{fmt_int(cert.cepac_total)}</td>
                <td style={{ ...tdStyle, textAlign: "right" as const }}>{fmt_dec(cert.nuvem_total_m2)}</td>
                <td style={{ ...tdStyle, color: "#8896a8", fontSize: "12px", maxWidth: "200px" }}>
                  {cert.obs ?? "—"}
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Componente principal
// ---------------------------------------------------------------------------

export default function DetalhesPropostaPage() {
  const { codigo } = useParams<{ codigo: string }>();
  const navigate = useNavigate();

  const [proposta, setProposta] = useState<PropostaAEOut | null>(null);
  const [carregando, setCarregando] = useState(true);
  const [erro, setErro] = useState("");

  const carregar = () => {
    if (!codigo) return;
    setCarregando(true);
    setErro("");
    void (async () => {
      try {
        const dados = await buscarPropostaAE(codigo);
        setProposta(dados);
      } catch {
        setErro("Não foi possível carregar os dados desta proposta. Verifique sua conexão ou tente novamente.");
      } finally {
        setCarregando(false);
      }
    })();
  };

  useEffect(carregar, [codigo]);

  if (carregando) return <LoadingSkeleton />;

  if (erro) {
    return (
      <div
        style={{
          fontFamily: "system-ui, -apple-system, sans-serif",
          background: "#f5f7fa",
          minHeight: "100vh",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
        }}
      >
        <div
          style={{
            background: "#fff",
            borderRadius: "8px",
            boxShadow: "0 2px 12px rgba(0,0,0,0.08)",
            padding: "40px 48px",
            textAlign: "center" as const,
            maxWidth: "460px",
          }}
        >
          <div style={{ fontSize: "40px", marginBottom: "16px" }}>⚠</div>
          <p style={{ color: "#1a2533", fontSize: "15px", marginBottom: "24px", lineHeight: "1.6" }}>
            {erro}
          </p>
          <button
            onClick={carregar}
            style={{
              background: "#003087",
              color: "#fff",
              border: "none",
              borderRadius: "6px",
              padding: "10px 24px",
              fontSize: "14px",
              fontWeight: 600,
              cursor: "pointer",
            }}
          >
            Tentar novamente
          </button>
        </div>
      </div>
    );
  }

  if (!proposta) return null;

  const certidoes: CertidaoItem[] = proposta.certidoes ?? [];

  const statusPACfg =
    STATUS_PA_CONFIG[proposta.status_pa as StatusPA] ??
    { bg: "#8896a8", color: "#fff", label: proposta.status_pa };

  const situacaoCertCfg = proposta.situacao_certidao
    ? (CERT_CONFIG[proposta.situacao_certidao as SituacaoCert] ?? {
        bg: "#8896a8",
        color: "#fff",
        label: proposta.situacao_certidao,
      })
    : null;

  const temNuvem =
    proposta.nuvem_r_m2 != null ||
    proposta.nuvem_nr_m2 != null ||
    proposta.nuvem_total_m2 != null ||
    proposta.nuvem_cepac != null;

  const temObs =
    proposta.obs != null ||
    proposta.resp_data != null ||
    proposta.cross_check != null ||
    proposta.observacao_alteracao != null;

  return (
    <div style={{ fontFamily: "system-ui, -apple-system, sans-serif", background: "#f5f7fa", minHeight: "100vh" }}>

      {/* -------------------------------------------------------------------- */}
      {/* Cabeçalho                                                              */}
      {/* -------------------------------------------------------------------- */}
      <div style={{ background: "linear-gradient(90deg, #0B2A4A 0%, #0F3A6D 55%, #145DA0 85%, #1C6ED5 100%)" }}>
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "0 28px", height: 88 }}>
          <div style={{ display: "flex", flexDirection: "row", alignItems: "center", gap: 16 }}>
            <img src="/imagens/logobranco.svg" alt="ZENITE" style={{ height: 82, width: "auto", display: "block" }} />
            <div style={{ width: 1, height: 40, background: "rgba(255,255,255,0.25)", flexShrink: 0 }} />
            <div>
              <div style={{ fontSize: 20, fontWeight: 800, color: "#fff", letterSpacing: "-0.3px", lineHeight: 1.1 }}>
                {proposta.codigo}
              </div>
              <div style={{ fontSize: 13, color: "rgba(255,255,255,0.7)", fontWeight: 500, marginTop: 3 }}>
                {proposta.setor} — {proposta.requerimento}
              </div>
            </div>
          </div>
          <button
            onClick={() => navigate("/propostas")}
            style={{ background: "rgba(255,255,255,0.1)", color: "#fff", border: "1px solid rgba(255,255,255,0.3)", borderRadius: 5, padding: "7px 16px", fontSize: 15, fontWeight: 600, cursor: "pointer", transition: "background 0.15s" }}
            onMouseEnter={(e) => { e.currentTarget.style.background = "rgba(255,255,255,0.18)"; }}
            onMouseLeave={(e) => { e.currentTarget.style.background = "rgba(255,255,255,0.1)"; }}
          >
            ← Voltar
          </button>
        </div>
      </div>

      {/* -------------------------------------------------------------------- */}
      {/* Barra de status                                                        */}
      {/* -------------------------------------------------------------------- */}
      <div
        style={{
          background: "#003087",
          padding: "0 32px",
          display: "flex",
          alignItems: "center",
          gap: "12px",
          height: "56px",
        }}
      >
        <span style={{ fontSize: "11px", color: "rgba(255,255,255,0.6)", fontWeight: 600, textTransform: "uppercase" as const, letterSpacing: "0.08em", marginRight: "4px" }}>
          Processo
        </span>
        <Badge label={statusPACfg.label} bg={statusPACfg.bg} color={statusPACfg.color} size="lg" />

        {situacaoCertCfg && (
          <>
            <span style={{ color: "rgba(255,255,255,0.3)", fontSize: "18px", margin: "0 4px" }}>|</span>
            <span style={{ fontSize: "11px", color: "rgba(255,255,255,0.6)", fontWeight: 600, textTransform: "uppercase" as const, letterSpacing: "0.08em", marginRight: "4px" }}>
              Certidão
            </span>
            <Badge label={situacaoCertCfg.label} bg={situacaoCertCfg.bg} color={situacaoCertCfg.color} size="lg" />
          </>
        )}
      </div>

      {/* -------------------------------------------------------------------- */}
      {/* Conteúdo                                                               */}
      {/* -------------------------------------------------------------------- */}
      <div style={{ maxWidth: "1100px", margin: "0 auto", padding: "28px 24px" }}>

        {/* Card: Processo Administrativo */}
        <Card titulo="Processo Administrativo" cols={3}>
          <Campo label="Tipo de Processo">{val(proposta.tipo_processo)}</Campo>
          <Campo label="Número PA">{val(proposta.numero_pa)}</Campo>
          <Campo label="Data de Autuação">{fmt_data(proposta.data_autuacao)}</Campo>
          <Campo label="Data da Proposta">{fmt_data(proposta.data_proposta)}</Campo>
          <Campo label="Requerimento">{val(proposta.requerimento)}</Campo>
          <Campo label="Setor">{val(proposta.setor)}</Campo>
          <Campo label="Área do Terreno (m²)">{fmt_dec(proposta.area_terreno_m2)}</Campo>
        </Card>

        {/* Card: Interessado */}
        <Card titulo="Interessado" cols={2}>
          <Campo label="Tipo">{val(proposta.tipo_interessado)}</Campo>
          <Campo label="Nome / Razão Social">{val(proposta.interessado)}</Campo>
          <Campo label={proposta.tipo_interessado === "PF" ? "CPF" : "CNPJ"}>
            {val(proposta.tipo_interessado === "PF" ? proposta.cpf : proposta.cnpj) !== "—"
              ? val(proposta.tipo_interessado === "PF" ? proposta.cpf : proposta.cnpj)
              : val(proposta.cnpj_cpf)}
          </Campo>
          <div style={{ display: "flex", flexDirection: "column" as const, gap: "4px", gridColumn: "span 2" as const }}>
            <span style={{ fontSize: "11px", fontWeight: 600, color: "#8896a8", textTransform: "uppercase" as const, letterSpacing: "0.07em" }}>
              Endereço
            </span>
            <span style={{ fontSize: "14px", fontWeight: 500, color: "#1a2533" }}>
              {val(proposta.endereco)}
            </span>
          </div>
          <Campo label="Contribuinte SQ">{val(proposta.contribuinte_sq)}</Campo>
          <Campo label="Contribuinte Lote">{val(proposta.contribuinte_lote)}</Campo>
        </Card>

        {/* Card: Uso e Áreas ACA */}
        <Card titulo="Uso e Áreas ACA" cols={3}>
          <Campo label="Uso ACA">{val(proposta.uso_aca)}</Campo>
          <Campo label="ACA Residencial (m²)">{fmt_dec(proposta.aca_r_m2)}</Campo>
          <Campo label="ACA Não-Residencial (m²)">{fmt_dec(proposta.aca_nr_m2)}</Campo>
          <Campo label="ACA Total (m²)">{fmt_dec(proposta.aca_total_m2)}</Campo>
        </Card>

        {/* Card: CEPACs */}
        <div
          style={{
            background: "#fff",
            borderRadius: "8px",
            boxShadow: "0 2px 12px rgba(0,0,0,0.08)",
            padding: "24px",
            marginBottom: "20px",
          }}
        >
          <h2
            style={{
              fontSize: "13px",
              fontWeight: 700,
              color: "#003087",
              textTransform: "uppercase" as const,
              letterSpacing: "0.1em",
              margin: "0 0 20px 0",
              paddingBottom: "12px",
              borderBottom: "2px solid #eef1f6",
            }}
          >
            CEPACs
          </h2>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: "20px 28px", marginBottom: "20px" }}>
            <Campo label="CEPAC ACA">{fmt_int(proposta.cepac_aca)}</Campo>
            <Campo label="CEPAC Parâmetros">{fmt_int(proposta.cepac_parametros)}</Campo>
            <div style={{ display: "flex", flexDirection: "column" as const, gap: "4px" }}>
              <span style={{ fontSize: "11px", fontWeight: 600, color: "#8896a8", textTransform: "uppercase" as const, letterSpacing: "0.07em" }}>
                CEPAC Total
              </span>
              <span
                style={{
                  fontSize: "28px",
                  fontWeight: 800,
                  color: "#003087",
                  letterSpacing: "-0.5px",
                  lineHeight: 1.1,
                }}
              >
                {fmt_int(proposta.cepac_total)}
              </span>
            </div>
          </div>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: "20px 28px", paddingTop: "16px", borderTop: "1px solid #eef1f6" }}>
            <Campo label="Tipo de Contrapartida">{val(proposta.tipo_contrapartida)}</Campo>
            <Campo label="Valor OODC (R$)">{fmt_dec(proposta.valor_oodc_rs)}</Campo>
          </div>
        </div>

        {/* Card: NUVEM (condicional) */}
        {temNuvem && (
          <Card titulo="NUVEM" cols={4}>
            <Campo label="NUVEM Residencial (m²)">{fmt_dec(proposta.nuvem_r_m2)}</Campo>
            <Campo label="NUVEM Não-Residencial (m²)">{fmt_dec(proposta.nuvem_nr_m2)}</Campo>
            <Campo label="NUVEM Total (m²)">{fmt_dec(proposta.nuvem_total_m2)}</Campo>
            <Campo label="NUVEM CEPAC">{fmt_int(proposta.nuvem_cepac)}</Campo>
          </Card>
        )}

        {/* Card: Certidão Representativa */}
        <Card titulo="Certidão Representativa" cols={3}>
          <Campo label="Nº Certidão">{val(proposta.certidao)}</Campo>
          <div style={{ display: "flex", flexDirection: "column" as const, gap: "4px" }}>
            <span style={{ fontSize: "11px", fontWeight: 600, color: "#8896a8", textTransform: "uppercase" as const, letterSpacing: "0.07em" }}>
              Situação
            </span>
            {situacaoCertCfg ? (
              <Badge label={situacaoCertCfg.label} bg={situacaoCertCfg.bg} color={situacaoCertCfg.color} />
            ) : (
              <span style={{ fontSize: "14px", fontWeight: 500, color: "#1a2533" }}>—</span>
            )}
          </div>
          <Campo label="Data da Certidão">{fmt_data(proposta.data_certidao)}</Campo>
        </Card>

        {/* Card: Histórico de Certidões */}
        <div
          style={{
            background: "#fff",
            borderRadius: "8px",
            boxShadow: "0 2px 12px rgba(0,0,0,0.08)",
            padding: "24px",
            marginBottom: "20px",
          }}
        >
          <h2
            style={{
              fontSize: "13px",
              fontWeight: 700,
              color: "#003087",
              textTransform: "uppercase" as const,
              letterSpacing: "0.1em",
              margin: "0 0 20px 0",
              paddingBottom: "12px",
              borderBottom: "2px solid #eef1f6",
              display: "flex",
              alignItems: "center",
              gap: "10px",
            }}
          >
            Histórico de Certidões
            {certidoes.length > 0 && (
              <span
                style={{
                  background: "#eef1f6",
                  color: "#003087",
                  borderRadius: "20px",
                  padding: "1px 9px",
                  fontSize: "11px",
                  fontWeight: 700,
                }}
              >
                {certidoes.length}
              </span>
            )}
          </h2>
          <HistoricoCertidoes certidoes={certidoes} />
        </div>

        {/* Card: Observações (condicional) */}
        {temObs && (
          <Card titulo="Observações" cols={1}>
            {proposta.obs && (
              <div style={{ gridColumn: "1 / -1" as const }}>
                <Campo label="Observação">
                  <span style={{ lineHeight: "1.6", whiteSpace: "pre-wrap" as const }}>{proposta.obs}</span>
                </Campo>
              </div>
            )}
            {proposta.resp_data && (
              <div style={{ gridColumn: "1 / -1" as const }}>
                <Campo label="Resp / Data">{proposta.resp_data}</Campo>
              </div>
            )}
            {proposta.cross_check && (
              <div style={{ gridColumn: "1 / -1" as const }}>
                <Campo label="Cross-Check">{proposta.cross_check}</Campo>
              </div>
            )}
            {proposta.observacao_alteracao && (
              <div style={{ gridColumn: "1 / -1" as const }}>
                <Campo label="Observação de Alteração">
                  <span style={{ lineHeight: "1.6", whiteSpace: "pre-wrap" as const }}>{proposta.observacao_alteracao}</span>
                </Campo>
              </div>
            )}
          </Card>
        )}

      </div>
    </div>
  );
}
