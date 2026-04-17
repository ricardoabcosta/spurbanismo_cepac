/**
 * Componente de upload de documento via SAS URL.
 *
 * Expõe resultado através de onUploadConcluido.
 * Limite: 50 MB. Tipos: PDF, DOCX, XLSX, JPG, PNG.
 */
import { useRef, useState } from "react";
import {
  validarArquivo,
  uploadDocumento,
  EXTENSOES_PERMITIDAS,
} from "../api/documentos";
import type { UploadUrlResponse } from "../types/api";

interface UploadDocumentoProps {
  numeroProcessoSei: string;
  propostaId?: string;
  onUploadConcluido?: (resultado: UploadUrlResponse) => void;
  disabled?: boolean;
}

const styles: Record<string, React.CSSProperties> = {
  container: {
    border: "1px dashed #aaa",
    borderRadius: "6px",
    padding: "16px",
    background: "#fafafa",
    marginTop: "8px",
  },
  label: {
    display: "block",
    marginBottom: "6px",
    fontSize: "14px",
    fontWeight: 500,
  },
  hint: {
    fontSize: "12px",
    color: "#666",
    marginTop: "4px",
  },
  progresso: {
    marginTop: "10px",
    fontSize: "14px",
    color: "#0066cc",
  },
  erro: {
    marginTop: "8px",
    fontSize: "13px",
    color: "#cc0000",
  },
  sucesso: {
    marginTop: "8px",
    fontSize: "13px",
    color: "#007700",
  },
  barraContainer: {
    marginTop: "8px",
    height: "8px",
    background: "#ddd",
    borderRadius: "4px",
    overflow: "hidden",
  },
  barra: {
    height: "100%",
    background: "#0066cc",
    transition: "width 0.2s ease",
  },
};

type Estado = "ocioso" | "enviando" | "concluido" | "erro";

export default function UploadDocumento({
  numeroProcessoSei,
  propostaId,
  onUploadConcluido,
  disabled = false,
}: UploadDocumentoProps) {
  const inputRef = useRef<HTMLInputElement>(null);
  const [estado, setEstado] = useState<Estado>("ocioso");
  const [percentual, setPercentual] = useState(0);
  const [mensagem, setMensagem] = useState("");
  const [nomeArquivo, setNomeArquivo] = useState("");

  async function handleArquivoSelecionado(e: React.ChangeEvent<HTMLInputElement>) {
    const arquivo = e.target.files?.[0];
    if (!arquivo) return;

    const erroValidacao = validarArquivo(arquivo);
    if (erroValidacao) {
      setEstado("erro");
      setMensagem(erroValidacao);
      setNomeArquivo(arquivo.name);
      return;
    }

    setNomeArquivo(arquivo.name);
    setEstado("enviando");
    setPercentual(0);
    setMensagem("");

    try {
      const resultado = await uploadDocumento(
        arquivo,
        numeroProcessoSei,
        propostaId,
        (pct) => setPercentual(pct)
      );
      setEstado("concluido");
      setMensagem("Documento enviado com sucesso.");
      onUploadConcluido?.(resultado);
    } catch {
      setEstado("erro");
      setMensagem("Falha ao enviar o documento. Tente novamente.");
    }

    // Limpa o input para permitir re-upload do mesmo arquivo
    if (inputRef.current) inputRef.current.value = "";
  }

  return (
    <div style={styles.container}>
      <label style={styles.label} htmlFor="upload-doc">
        Documento (opcional)
      </label>

      <input
        id="upload-doc"
        ref={inputRef}
        type="file"
        accept={EXTENSOES_PERMITIDAS.join(",")}
        onChange={handleArquivoSelecionado}
        disabled={disabled || estado === "enviando"}
        aria-describedby="upload-hint"
      />

      <p id="upload-hint" style={styles.hint}>
        Formatos aceitos: PDF, DOCX, XLSX, JPG, PNG — máximo 50 MB
      </p>

      {nomeArquivo && estado === "enviando" && (
        <>
          <p style={styles.progresso}>
            Enviando {nomeArquivo}… {percentual}%
          </p>
          <div style={styles.barraContainer}>
            <div style={{ ...styles.barra, width: `${percentual}%` }} />
          </div>
        </>
      )}

      {estado === "erro" && (
        <p role="alert" style={styles.erro}>
          {mensagem}
        </p>
      )}

      {estado === "concluido" && (
        <p role="status" style={styles.sucesso}>
          {mensagem}
        </p>
      )}
    </div>
  );
}
