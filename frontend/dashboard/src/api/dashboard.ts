/**
 * Funções tipadas para os endpoints do Dashboard Executivo.
 */
import apiClient from "./client";
import type { AlertaSetorial, CepacSnapshot, DashboardSnapshot, MedicaoObra, OperacaoUrbanaResumo } from "../types/api";

/**
 * GET /dashboard/snapshot
 * Com `data` faz snapshot histórico (DIRETOR apenas).
 */
export async function fetchSnapshot(data?: string, oucId?: number): Promise<DashboardSnapshot> {
  const params: Record<string, unknown> = {};
  if (data) params.data = data;
  if (oucId !== undefined) params.operacao_urbana_id = oucId;
  const response = await apiClient.get<DashboardSnapshot>("/dashboard/snapshot", { params });
  return response.data;
}

/**
 * GET /dashboard/alertas
 */
export async function fetchAlertas(oucId?: number): Promise<AlertaSetorial[]> {
  const params = oucId !== undefined ? { operacao_urbana_id: oucId } : {};
  const response = await apiClient.get<AlertaSetorial[]>("/dashboard/alertas", { params });
  return response.data;
}

/**
 * GET /dashboard/medicoes  — DIRETOR apenas
 */
export async function fetchMedicoes(): Promise<MedicaoObra[]> {
  const response = await apiClient.get<MedicaoObra[]>("/dashboard/medicoes");
  return response.data;
}

/**
 * GET /dashboard/cepac
 */
export async function fetchCepacSnapshot(oucId?: number): Promise<CepacSnapshot> {
  const params = oucId !== undefined ? { operacao_urbana_id: oucId } : {};
  const response = await apiClient.get<CepacSnapshot>("/dashboard/cepac", { params });
  return response.data;
}

/**
 * GET /admin/operacoes-urbanas?ativo=true  — lista OUCs ativas para o seletor
 */
export async function fetchOperacoesUrbanas(): Promise<OperacaoUrbanaResumo[]> {
  const response = await apiClient.get<OperacaoUrbanaResumo[]>("/admin/operacoes-urbanas", {
    params: { ativo: true },
  });
  return response.data;
}

/**
 * GET /dashboard/graficos
 */
export interface GraficosOut {
  g1_evolucao: { ano: number; total: number }[];
  g1_total_cepacs: number;
  g1_media_ano: number;
  g1_ano_pico: number;
  g1_crescimento_pct: number;

  g2_por_setor: { setor: string; cepac_aca: number; cepac_parametros: number }[];
  g2_total_aca: number;
  g2_total_parametros: number;
  g2_proporcao: string;

  g3_total_propostas: number;
  g3_deferidas: number;
  g3_indeferidas: number;
  g3_taxa_aprovacao: number;
  g3_por_mes: { mes: string; deferidas: number; indeferidas: number }[];

  g4_uso: { uso: string; total: number }[];
  g4_mais_comum: string;
  g4_tipos_ativos: number;

  g5_top_setores: { setor: string; total: number }[];
  g5_setor_lider: string;
  g5_total_top10: number;
  g5_setores_ativos: number;

  g6_histograma: { faixa: string; quantidade: number }[];
  g6_tempo_medio: number;
  g6_tempo_minimo: number;
  g6_tempo_maximo: number;

  g7_scatter: { area_m2: number; cepac_total: number }[];
  g7_area_media: number;
  g7_media_cepac_m2: number;
  g7_correlacao: number;
}

export async function fetchGraficos(oucId?: number): Promise<GraficosOut> {
  const params = oucId !== undefined ? { operacao_urbana_id: oucId } : {};
  const response = await apiClient.get<GraficosOut>("/dashboard/graficos", { params });
  return response.data;
}
