/**
 * Upload de documentos via SAS URL (Azure Blob Storage).
 *
 * Fluxo:
 * 1. POST /documentos/upload-url → obtém SAS URL e documento_id
 * 2. PUT sas_url_upload com o arquivo (Content-Type do arquivo)
 * 3. Retorna documento_id para vínculo com a solicitação
 */
import axios from "axios";
import apiClient from "./client";
import type { UploadUrlRequest, UploadUrlResponse } from "../types/api";

export const TIPOS_PERMITIDOS = [
  "application/pdf",
  "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
  "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
  "image/jpeg",
  "image/png",
];

export const EXTENSOES_PERMITIDAS = [".pdf", ".docx", ".xlsx", ".jpg", ".jpeg", ".png"];

export const LIMITE_BYTES = 50 * 1024 * 1024; // 50 MB

export function validarArquivo(arquivo: File): string | null {
  if (arquivo.size > LIMITE_BYTES) {
    return `Arquivo muito grande. Limite: 50 MB. Tamanho: ${(arquivo.size / 1024 / 1024).toFixed(1)} MB.`;
  }
  if (!TIPOS_PERMITIDOS.includes(arquivo.type)) {
    return `Tipo de arquivo não permitido. Use: PDF, DOCX, XLSX, JPG ou PNG.`;
  }
  return null;
}

export type ProgressoCallback = (percentual: number) => void;

export async function uploadDocumento(
  arquivo: File,
  numeroProcessoSei: string,
  propostaId?: string,
  onProgresso?: ProgressoCallback
): Promise<UploadUrlResponse> {
  const req: UploadUrlRequest = {
    numero_processo_sei: numeroProcessoSei,
    nome_arquivo: arquivo.name,
    content_type: arquivo.type,
    tamanho_bytes: arquivo.size,
  };
  if (propostaId) req.proposta_id = propostaId;

  // Passo 1: obter SAS URL
  const { data: urlResp } = await apiClient.post<UploadUrlResponse>(
    "/documentos/upload-url",
    req
  );

  // Passo 2: PUT direto para o Azure Blob (sem Bearer token — SAS já autentica)
  await axios.put(urlResp.sas_url_upload, arquivo, {
    headers: {
      "Content-Type": arquivo.type,
      "x-ms-blob-type": "BlockBlob",
    },
    onUploadProgress: (progressEvent) => {
      if (onProgresso && progressEvent.total) {
        const pct = Math.round((progressEvent.loaded / progressEvent.total) * 100);
        onProgresso(pct);
      }
    },
  });

  return urlResp;
}
