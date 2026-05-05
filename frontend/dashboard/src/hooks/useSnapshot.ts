/**
 * useSnapshot — polling 60s ou fetch único para snapshot histórico.
 *
 * - Sem data histórica: polling a cada 60s com setInterval
 * - Com data histórica: fetch único, sem polling
 * - oucId null → aguarda seleção (não busca dados)
 * - Limpa o intervalo no cleanup (sem memory leak)
 * - Retorna { data, loading, error }
 */
import { useState, useEffect, useCallback } from "react";
import { fetchSnapshot } from "../api/dashboard";
import type { DashboardSnapshot } from "../types/api";

const POLL_INTERVAL_MS = 60_000;

interface UseSnapshotResult {
  data: DashboardSnapshot | null;
  loading: boolean;
  error: string | null;
}

export function useSnapshot(dataHistorica?: string, oucId?: number | null): UseSnapshotResult {
  const [data, setData] = useState<DashboardSnapshot | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    if (oucId === null) return; // aguarda seleção de OUC
    try {
      setError(null);
      const snapshot = await fetchSnapshot(dataHistorica, oucId ?? undefined);
      if (snapshot && Array.isArray(snapshot.setores)) {
        setData(snapshot);
      } else {
        setError("Resposta inválida do servidor.");
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : "Erro ao carregar snapshot.";
      setError(message);
    } finally {
      setLoading(false);
    }
  }, [dataHistorica, oucId]);

  useEffect(() => {
    if (oucId === null) {
      setLoading(false);
      setData(null);
      return;
    }
    setLoading(true);
    void load();

    // Snapshot histórico: sem polling
    if (dataHistorica) {
      return;
    }

    // Tempo real: polling a cada 60s
    const intervalId = setInterval(() => {
      void load();
    }, POLL_INTERVAL_MS);

    return () => {
      clearInterval(intervalId);
    };
  }, [load, dataHistorica, oucId]);

  return { data, loading, error };
}
