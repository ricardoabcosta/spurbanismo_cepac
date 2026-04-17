/**
 * Interfaces TypeScript mapeadas para os schemas Pydantic do backend CEPAC.
 */

// ---------------------------------------------------------------------------
// Títulos
// ---------------------------------------------------------------------------

export interface TituloDisponivel {
  id: string;
  codigo: string;
  setor: string;
  uso: "R" | "NR";
  origem: "ACA" | "NUVEM";
  valor_m2: string; // Decimal serializado como string pelo backend
}

// ---------------------------------------------------------------------------
// Solicitações — criação
// ---------------------------------------------------------------------------

export interface SolicitacaoIn {
  setor: string;
  uso: "R" | "NR";
  origem: "ACA" | "NUVEM";
  area_m2: number;
  numero_processo_sei: string;
  titulo_ids: string[];
  proposta_codigo?: string;
  observacao?: string;
}

// ---------------------------------------------------------------------------
// Solicitações — saída resumida (listagem / criação)
// ---------------------------------------------------------------------------

export type StatusSolicitacao =
  | "PENDENTE"
  | "APROVADA"
  | "REJEITADA"
  | "CANCELADA"
  | "EM_ANALISE";

export interface SolicitacaoOut {
  id: string;
  status: StatusSolicitacao;
  setor: string;
  uso: string;
  origem: string;
  area_m2: string;
  quantidade_cepacs: number;
  numero_processo_sei: string;
  proposta_codigo?: string;
  observacao?: string;
  motivo_rejeicao?: string;
  created_at: string;
}

// ---------------------------------------------------------------------------
// Solicitações — detalhe com títulos
// ---------------------------------------------------------------------------

export interface TituloNoLote {
  id: string;
  codigo: string;
  setor: string;
  uso: string;
  origem: string;
  estado: string;
  valor_m2: string;
  area_m2_contribuicao: string;
}

export interface SolicitacaoDetalhe extends SolicitacaoOut {
  titulos: TituloNoLote[];
}

// ---------------------------------------------------------------------------
// Paginação
// ---------------------------------------------------------------------------

export interface PaginacaoSolicitacao {
  items: SolicitacaoOut[];
  total: number;
  page: number;
  page_size: number;
  total_pages: number;
}

// ---------------------------------------------------------------------------
// Proposta
// ---------------------------------------------------------------------------

export interface PropostaPortal {
  id: string;
  codigo: string;
  numero_pa?: string;
  tipo_processo?: string;
  data_autuacao?: string;
  status_pa: string;
  interessado?: string;
  cnpj_cpf?: string;
  endereco?: string;
  setor: string;
  requerimento: string;
  area_terreno_m2?: string;
  observacao_alteracao?: string;
  created_at: string;
  updated_at: string;
}

// ---------------------------------------------------------------------------
// Documentos / Upload SAS
// ---------------------------------------------------------------------------

export interface UploadUrlRequest {
  proposta_id?: string;
  numero_processo_sei: string;
  nome_arquivo: string;
  content_type: string;
  tamanho_bytes: number;
}

export interface UploadUrlResponse {
  documento_id: string;
  sas_url_upload: string;
  blob_path: string;
  expira_em: string;
}

// ---------------------------------------------------------------------------
// Erros de negócio (HTTP 422)
// ---------------------------------------------------------------------------

export interface ErroNegocio {
  codigo_erro: string;
  mensagem: string;
  setor?: string;
  saldo_atual?: string;
  limite?: string;
  dias_restantes?: number;
}

// ---------------------------------------------------------------------------
// Filtros de listagem
// ---------------------------------------------------------------------------

export interface FiltrosSolicitacao {
  page?: number;
  page_size?: number;
  setor?: string;
  status?: string;
  uso?: string;
  origem?: string;
}

export interface FiltrosTitulos {
  setor?: string;
  uso?: string;
  origem?: string;
}
