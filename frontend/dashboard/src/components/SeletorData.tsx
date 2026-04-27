/**
 * SeletorData — date picker com banner de dados históricos.
 * TECNICO não pode usar snapshot histórico.
 */
import React from "react";

interface Props {
  isDiretor: boolean;
  dataHistorica: string | undefined;
  onDataChange: (data: string | undefined) => void;
}

const SeletorData: React.FC<Props> = ({ isDiretor, dataHistorica, onDataChange }) => {
  const hoje = new Date().toISOString().slice(0, 10);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const valor = e.target.value;
    onDataChange(valor || undefined);
  };

  const handleVoltar = () => {
    onDataChange(undefined);
  };

  if (!isDiretor) {
    return (
      <div
        style={{
          background: "#fff8e1",
          border: "1px solid #ffe082",
          borderRadius: 6,
          padding: "10px 16px",
          marginBottom: 16,
          fontSize: 13,
          color: "#795548",
        }}
      >
        Snapshot histórico disponível apenas para Diretores.
      </div>
    );
  }

  return (
    <div style={{ marginBottom: 16 }}>
      <div style={{ display: "flex", alignItems: "center", gap: 12, flexWrap: "wrap" }}>
        <input
          id="data-historica"
          type="date"
          max={hoje}
          value={dataHistorica ?? ""}
          onChange={handleChange}
          style={{
            padding: "6px 10px",
            border: "1px solid #ccc",
            borderRadius: 4,
            fontSize: 13,
            color: "#333",
          }}
        />
        {dataHistorica && (
          <button
            onClick={handleVoltar}
            style={{
              padding: "6px 14px",
              background: "#1a73e8",
              color: "#fff",
              border: "none",
              borderRadius: 4,
              fontSize: 13,
              cursor: "pointer",
              fontWeight: 600,
            }}
          >
            Voltar ao tempo real
          </button>
        )}
      </div>

      {dataHistorica && (
        <div
          style={{
            marginTop: 10,
            background: "#e8f0fe",
            border: "1px solid #b3c7f7",
            borderRadius: 6,
            padding: "10px 16px",
            fontSize: 13,
            color: "#1a47a0",
            display: "flex",
            alignItems: "center",
            gap: 8,
          }}
        >
          <span>🕐</span>
          <span>
            Visualizando estado de{" "}
            <strong>
              {new Date(dataHistorica + "T00:00:00").toLocaleDateString("pt-BR")}
            </strong>{" "}
            — dados históricos, não tempo real.
          </span>
        </div>
      )}
    </div>
  );
};

export default SeletorData;
