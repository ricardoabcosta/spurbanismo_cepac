/**
 * Funções tipadas para os endpoints administrativos (/admin).
 */
import apiClient from "./client";
import type { ConfiguracaoIn, ConfiguracaoOperacao, SetorIn, SetorOut } from "../types/api";

export async function listarSetores(): Promise<SetorOut[]> {
  const { data } = await apiClient.get<SetorOut[]>("/admin/setores");
  return data;
}

export async function criarSetor(payload: SetorIn): Promise<SetorOut> {
  const { data } = await apiClient.post<SetorOut>("/admin/setores", payload);
  return data;
}

export async function atualizarSetor(id: string, payload: SetorIn): Promise<SetorOut> {
  const { data } = await apiClient.put<SetorOut>(`/admin/setores/${id}`, payload);
  return data;
}

export async function lerConfiguracao(): Promise<ConfiguracaoOperacao> {
  const { data } = await apiClient.get<ConfiguracaoOperacao>("/admin/configuracao");
  return data;
}

export async function atualizarConfiguracao(payload: ConfiguracaoIn): Promise<ConfiguracaoOperacao> {
  const { data } = await apiClient.put<ConfiguracaoOperacao>("/admin/configuracao", payload);
  return data;
}
