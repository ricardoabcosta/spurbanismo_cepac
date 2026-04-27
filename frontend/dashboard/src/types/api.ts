/**
 * Tipos TypeScript espelhando os schemas Pydantic do backend (T16 / dashboard.py).
 */

export type PrazoZona = "VERDE" | "AMARELO" | "VERMELHO";
export type AlertaTipo = "TETO_NR_EXCEDIDO" | "RESERVA_R_VIOLADA";

export interface AlertaSetorial {
  setor: string;
  tipo: AlertaTipo;
  mensagem: string;
}

export interface OcupacaoSetor {
  nome: string;
  /** Decimal serializado como string pelo FastAPI */
  estoque_total: string;
  consumido_r: string;
  consumido_nr: string;
  consumido_r_aca: string;
  consumido_nr_aca: string;
  consumido_r_nuvem: string;
  consumido_nr_nuvem: string;
  em_analise_r: string;
  em_analise_nr: string;
  disponivel: string;
  percentual_ocupado: number;
  teto_nr: string | null;
  saldo_nr_liquido: string | null;
  bloqueado_nr: boolean;
}

export interface DashboardSnapshot {
  gerado_em: string;
  custo_total_incorrido: string;
  capacidade_total_operacao: string;
  saldo_geral_disponivel: string;
  total_consumido_m2: string;
  total_em_analise_m2: string;
  cepacs_em_circulacao: number;
  prazo_percentual_decorrido: number;
  prazo_dias_restantes: number;
  prazo_zona: PrazoZona;
  alertas: AlertaSetorial[];
  setores: OcupacaoSetor[];
}

export interface MedicaoObra {
  id: string;
  data_referencia: string;
  valor_medicao: string;
  valor_acumulado: string;
  descricao: string | null;
  numero_processo_sei: string;
  created_at: string;
}

export interface CepacSetor {
  nome: string;
  cepacs_convertidos_aca: number;
  cepacs_convertidos_parametros: number;
  cepacs_desvinculados_aca: number;
  cepacs_desvinculados_parametros: number;
}

export interface CepacSnapshot {
  cepacs_totais: number;
  cepacs_leiloados: number;
  cepacs_colocacao_privada: number;
  setores: CepacSetor[];
}
