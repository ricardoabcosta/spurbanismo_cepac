/**
 * Funções tipadas para os endpoints do Dashboard Executivo.
 */
import apiClient from "./client";
import type { AlertaSetorial, DashboardSnapshot, MedicaoObra } from "../types/api";

/**
 * GET /dashboard/snapshot
 * Com `data` faz snapshot histórico (DIRETOR apenas).
 */
export async function fetchSnapshot(data?: string): Promise<DashboardSnapshot> {
  const params = data ? { data } : {};
  const response = await apiClient.get<DashboardSnapshot>("/dashboard/snapshot", { params });
  return response.data;
}

/**
 * GET /dashboard/alertas
 */
export async function fetchAlertas(): Promise<AlertaSetorial[]> {
  const response = await apiClient.get<AlertaSetorial[]>("/dashboard/alertas");
  return response.data;
}

/**
 * GET /dashboard/medicoes  — DIRETOR apenas
 */
export async function fetchMedicoes(): Promise<MedicaoObra[]> {
  const response = await apiClient.get<MedicaoObra[]>("/dashboard/medicoes");
  return response.data;
}
