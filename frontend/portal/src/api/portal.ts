/**
 * Funções tipadas para os endpoints do Portal de Operações Técnicas.
 */
import type { AxiosError } from "axios";
import apiClient from "./client";
import type {
  TituloDisponivel,
  PropostaIn,
  PropostaOut,
  PropostaDetalhe,
  PaginacaoProposta,
  PropostaAEOut,
  FiltrosPropostas,
  FiltrosTitulos,
  ErroNegocio,
  PaginacaoPropostaList,
  SetorBasico,
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
// Propostas
// ---------------------------------------------------------------------------

export interface ErroNegocioError extends Error {
  erroNegocio: ErroNegocio;
}

function isErroNegocioError(e: unknown): e is ErroNegocioError {
  return e instanceof Error && "erroNegocio" in e;
}

export { isErroNegocioError };

export async function criarProposta(
  payload: PropostaIn
): Promise<PropostaOut> {
  try {
    const { data } = await apiClient.post<PropostaOut>(
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

export async function listarPropostas(
  filtros: FiltrosPropostas = {}
): Promise<PaginacaoProposta> {
  const params = new URLSearchParams();
  params.set("page", String(filtros.page ?? 1));
  params.set("page_size", String(filtros.page_size ?? 20));
  if (filtros.setor) params.set("setor", filtros.setor);
  if (filtros.status) params.set("status", filtros.status);
  if (filtros.uso) params.set("uso", filtros.uso);
  if (filtros.origem) params.set("origem", filtros.origem);

  const { data } = await apiClient.get<PaginacaoProposta>(
    `/portal/solicitacoes?${params.toString()}`
  );
  return data;
}

export async function buscarProposta(id: string): Promise<PropostaDetalhe> {
  const { data } = await apiClient.get<PropostaDetalhe>(
    `/portal/solicitacoes/${id}`
  );
  return data;
}

export async function cancelarProposta(id: string): Promise<PropostaOut> {
  try {
    const { data } = await apiClient.patch<PropostaOut>(
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
// Proposta AE-XXXX
// ---------------------------------------------------------------------------

export async function buscarPropostaAE(codigo: string): Promise<PropostaAEOut> {
  const { data } = await apiClient.get<PropostaAEOut>(
    `/portal/propostas/${encodeURIComponent(codigo)}`
  );
  return data;
}

// ---------------------------------------------------------------------------
// Listagem paginada de propostas AE-XXXX
// ---------------------------------------------------------------------------

export async function listarPropostasAE(params: {
  page?: number;
  page_size?: number;
  setor_id?: string;
  status_pa?: string;
  situacao_certidao?: string;
}): Promise<PaginacaoPropostaList> {
  const qs = new URLSearchParams();
  qs.set("page", String(params.page ?? 1));
  qs.set("page_size", String(params.page_size ?? 20));
  if (params.setor_id) qs.set("setor_id", params.setor_id);
  if (params.status_pa) qs.set("status_pa", params.status_pa);
  if (params.situacao_certidao) qs.set("situacao_certidao", params.situacao_certidao);

  const { data } = await apiClient.get<PaginacaoPropostaList>(
    `/portal/propostas?${qs.toString()}`
  );
  return data;
}

export async function listarSetores(): Promise<SetorBasico[]> {
  const { data } = await apiClient.get<SetorBasico[]>("/admin/setores");
  return data;
}
