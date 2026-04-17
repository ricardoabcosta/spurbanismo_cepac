/**
 * Funções tipadas para os endpoints do Portal de Operações Técnicas.
 */
import type { AxiosError } from "axios";
import apiClient from "./client";
import type {
  TituloDisponivel,
  SolicitacaoIn,
  SolicitacaoOut,
  SolicitacaoDetalhe,
  PaginacaoSolicitacao,
  PropostaPortal,
  FiltrosSolicitacao,
  FiltrosTitulos,
  ErroNegocio,
} from "../types/api";

// ---------------------------------------------------------------------------
// Títulos disponíveis
// ---------------------------------------------------------------------------

export async function listarTitulosDisponiveis(
  filtros: FiltrosTitulos = {}
): Promise<TituloDisponivel[]> {
  const params = new URLSearchParams();
  if (filtros.setor) params.set("setor", filtros.setor);
  if (filtros.uso) params.set("uso", filtros.uso);
  if (filtros.origem) params.set("origem", filtros.origem);

  const { data } = await apiClient.get<TituloDisponivel[]>(
    `/portal/titulos?${params.toString()}`
  );
  return data;
}

// ---------------------------------------------------------------------------
// Solicitações
// ---------------------------------------------------------------------------

export interface ErroNegocioError extends Error {
  erroNegocio: ErroNegocio;
}

function isErroNegocioError(e: unknown): e is ErroNegocioError {
  return e instanceof Error && "erroNegocio" in e;
}

export { isErroNegocioError };

export async function criarSolicitacao(
  payload: SolicitacaoIn
): Promise<SolicitacaoOut> {
  try {
    const { data } = await apiClient.post<SolicitacaoOut>(
      "/portal/solicitacoes",
      payload
    );
    return data;
  } catch (e) {
    const axiosErr = e as AxiosError<ErroNegocio>;
    if (axiosErr.response?.status === 422 && axiosErr.response.data?.codigo_erro) {
      const err = new Error(axiosErr.response.data.mensagem) as ErroNegocioError;
      err.erroNegocio = axiosErr.response.data;
      throw err;
    }
    throw e;
  }
}

export async function listarSolicitacoes(
  filtros: FiltrosSolicitacao = {}
): Promise<PaginacaoSolicitacao> {
  const params = new URLSearchParams();
  params.set("page", String(filtros.page ?? 1));
  params.set("page_size", String(filtros.page_size ?? 20));
  if (filtros.setor) params.set("setor", filtros.setor);
  if (filtros.status) params.set("status", filtros.status);
  if (filtros.uso) params.set("uso", filtros.uso);
  if (filtros.origem) params.set("origem", filtros.origem);

  const { data } = await apiClient.get<PaginacaoSolicitacao>(
    `/portal/solicitacoes?${params.toString()}`
  );
  return data;
}

export async function buscarSolicitacao(id: string): Promise<SolicitacaoDetalhe> {
  const { data } = await apiClient.get<SolicitacaoDetalhe>(
    `/portal/solicitacoes/${id}`
  );
  return data;
}

export async function cancelarSolicitacao(id: string): Promise<SolicitacaoOut> {
  try {
    const { data } = await apiClient.patch<SolicitacaoOut>(
      `/portal/solicitacoes/${id}/cancelar`
    );
    return data;
  } catch (e) {
    const axiosErr = e as AxiosError<ErroNegocio>;
    if (axiosErr.response?.status === 422 && axiosErr.response.data?.codigo_erro) {
      const err = new Error(axiosErr.response.data.mensagem) as ErroNegocioError;
      err.erroNegocio = axiosErr.response.data;
      throw err;
    }
    throw e;
  }
}

// ---------------------------------------------------------------------------
// Proposta
// ---------------------------------------------------------------------------

export async function buscarProposta(codigo: string): Promise<PropostaPortal> {
  const { data } = await apiClient.get<PropostaPortal>(
    `/portal/propostas/${encodeURIComponent(codigo)}`
  );
  return data;
}
