/**
 * Controles de paginação: Anterior / Próxima + indicador "Página X de Y".
 */

interface PaginacaoControleProps {
  page: number;
  totalPages: number;
  onAnterior: () => void;
  onProxima: () => void;
  disabled?: boolean;
}

const styles: Record<string, React.CSSProperties> = {
  container: {
    display: "flex",
    alignItems: "center",
    gap: "12px",
    marginTop: "16px",
  },
  botao: {
    padding: "6px 14px",
    border: "1px solid #ccc",
    borderRadius: "4px",
    background: "#fff",
    cursor: "pointer",
    fontSize: "14px",
  },
  botaoDesabilitado: {
    opacity: 0.4,
    cursor: "not-allowed",
  },
  indicador: {
    fontSize: "14px",
    color: "#444",
  },
};

export default function PaginacaoControle({
  page,
  totalPages,
  onAnterior,
  onProxima,
  disabled = false,
}: PaginacaoControleProps) {
  const anteriorDesabilitado = disabled || page <= 1;
  const proximaDesabilitada = disabled || page >= totalPages;

  return (
    <div style={styles.container}>
      <button
        style={{
          ...styles.botao,
          ...(anteriorDesabilitado ? styles.botaoDesabilitado : {}),
        }}
        onClick={onAnterior}
        disabled={anteriorDesabilitado}
        aria-label="Página anterior"
      >
        ← Anterior
      </button>

      <span style={styles.indicador}>
        Página {page} de {totalPages || 1}
      </span>

      <button
        style={{
          ...styles.botao,
          ...(proximaDesabilitada ? styles.botaoDesabilitado : {}),
        }}
        onClick={onProxima}
        disabled={proximaDesabilitada}
        aria-label="Próxima página"
      >
        Próxima →
      </button>
    </div>
  );
}
