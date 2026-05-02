/**
 * Funções tipadas para os endpoints administrativos (/admin).
 */
import apiClient from "./client";
import type { ConfiguracaoIn, ConfiguracaoOperacao, PapelUsuario, SetorIn, SetorOut, UsuarioOut } from "../types/api";

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

export async function getMeuPerfil(): Promise<UsuarioOut> {
  const { data } = await apiClient.get<UsuarioOut>("/admin/me");
  return data;
}

export async function listarUsuarios(): Promise<UsuarioOut[]> {
  const { data } = await apiClient.get<UsuarioOut[]>("/admin/usuarios");
  return data;
}

export async function alterarPapel(id: string, papel: PapelUsuario): Promise<UsuarioOut> {
  const { data } = await apiClient.patch<UsuarioOut>(`/admin/usuarios/${id}/papel`, { papel });
  return data;
}

export async function alterarAtivo(id: string, ativo: boolean): Promise<UsuarioOut> {
  const { data } = await apiClient.patch<UsuarioOut>(`/admin/usuarios/${id}/ativo`, { ativo });
  return data;
}
