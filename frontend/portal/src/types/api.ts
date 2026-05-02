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
  uso: "R" | "NR" | "MISTO";
  origem: "ACA" | "NUVEM";
  valor_m2: string; // Decimal serializado como string pelo backend
}

// ---------------------------------------------------------------------------
// Propostas — criação  (antiga SolicitacaoIn)
// ---------------------------------------------------------------------------

export interface PropostaIn {
  setor: string;
  uso?: "R" | "NR" | "MISTO";
  origem: "ACA" | "NUVEM";
  area_m2: number;
  numero_processo_sei: string;
  titulo_ids: string[];
  proposta_codigo?: string;
  observacao?: string;
  // Campos novos do formulário
  area_total_r?: number | null;       // obrigatório se uso=MISTO
  area_total_nr?: number | null;      // obrigatório se uso=MISTO
  tipo_contrapartida?: string;        // default: 'CEPAC (título)'
  cepac_aca?: number | null;
  cepac_parametros?: number | null;
}

// ---------------------------------------------------------------------------
// Propostas — saída resumida  (antiga SolicitacaoOut)
// ---------------------------------------------------------------------------

export type StatusProposta =
  | "PENDENTE"
  | "APROVADA"
  | "REJEITADA"
  | "CANCELADA"
  | "EM_ANALISE";

export interface PropostaOut {
  id: string;
  status: StatusProposta;
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
// Propostas — detalhe com títulos  (antiga SolicitacaoDetalhe)
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

export interface PropostaDetalhe extends PropostaOut {
  titulos: TituloNoLote[];
}

// ---------------------------------------------------------------------------
// Paginação  (antiga PaginacaoSolicitacao)
// ---------------------------------------------------------------------------

export interface PaginacaoProposta {
  items: PropostaOut[];
  total: number;
  page: number;
  page_size: number;
  total_pages: number;
}

// ---------------------------------------------------------------------------
// Proposta AE-XXXX  (antiga PropostaPortal)
// ---------------------------------------------------------------------------

export interface PropostaAEOut {
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
  // Dados de identificação (migration 012)
  data_proposta?: string | null;
  tipo_interessado?: string | null;   // 'PF' | 'PJ'
  cnpj?: string | null;
  cpf?: string | null;
  contribuinte_sq?: string | null;
  contribuinte_lote?: string | null;
  // ACA
  uso_aca?: string | null;            // 'R' | 'NR' | 'MISTO'
  aca_r_m2?: string | null;
  aca_nr_m2?: string | null;
  aca_total_m2?: string | null;
  tipo_contrapartida?: string | null;
  valor_oodc_rs?: string | null;
  // CEPACs
  cepac_aca?: number | null;
  cepac_parametros?: number | null;
  cepac_total?: number | null;
  // Certidão
  certidao?: string | null;
  situacao_certidao?: string | null;
  data_certidao?: string | null;
  // NUVEM
  nuvem_r_m2?: string | null;
  nuvem_nr_m2?: string | null;
  nuvem_total_m2?: string | null;
  nuvem_cepac?: number | null;
  // Controle
  obs?: string | null;
  resp_data?: string | null;
  cross_check?: string | null;
  // Histórico de certidões
  certidoes?: CertidaoItem[];
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
// Setor (admin)
// ---------------------------------------------------------------------------

export interface SetorOut {
  id: string;
  nome: string;
  estoque_total_m2: string;
  teto_nr_m2: string;
  teto_r_m2: string | null;
  reserva_r_m2: string | null;
  piso_r_percentual: string | null;
  bloqueio_nr: boolean;
  ativo: boolean;
  created_at: string;
  cepacs_convertidos_aca: number;
  cepacs_convertidos_parametros: number;
  cepacs_desvinculados_aca: number;
  cepacs_desvinculados_parametros: number;
}

export interface ConfiguracaoOperacao {
  reserva_tecnica_m2: string;
  cepacs_totais: number;
  cepacs_leiloados: number;
  cepacs_colocacao_privada: number;
  updated_at: string;
}

export interface ConfiguracaoIn {
  reserva_tecnica_m2: number;
  cepacs_totais: number;
  cepacs_leiloados: number;
  cepacs_colocacao_privada: number;
}

export interface SetorIn {
  nome: string;
  estoque_total_m2: number;
  teto_nr_m2: number;
  reserva_r_m2: number | null;
  piso_r_percentual: number | null;
  bloqueio_nr: boolean;
  ativo: boolean;
  cepacs_convertidos_aca: number;
  cepacs_convertidos_parametros: number;
  cepacs_desvinculados_aca: number;
  cepacs_desvinculados_parametros: number;
}

// ---------------------------------------------------------------------------
// Filtros de listagem
// ---------------------------------------------------------------------------

export interface FiltrosPropostas {
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

// ---------------------------------------------------------------------------
// Proposta AE-XXXX — listagem paginada
// ---------------------------------------------------------------------------

export interface CertidaoItem {
  id: string;
  numero_certidao: string;
  tipo: string;
  data_emissao: string | null;
  situacao: "ANALISE" | "VALIDA" | "CANCELADA";
  numero_processo_sei: string | null;
  uso_aca: string | null;
  aca_r_m2: number | null;
  aca_nr_m2: number | null;
  aca_total_m2: number | null;
  cepac_aca: number | null;
  cepac_parametros: number | null;
  cepac_total: number | null;
  nuvem_r_m2: number | null;
  nuvem_nr_m2: number | null;
  nuvem_total_m2: number | null;
  nuvem_cepac: number | null;
  obs: string | null;
}

export interface PropostaListItem {
  id: string;
  codigo: string;
  setor: string;
  interessado: string | null;
  uso_aca: string | null;
  cepac_total: number | null;
  status_pa: "ANALISE" | "DEFERIDO" | "INDEFERIDO";
  situacao_certidao: "ANALISE" | "VALIDA" | "CANCELADA" | null;
  data_proposta: string | null;
  requerimento: string;
}

export interface PaginacaoPropostaList {
  items: PropostaListItem[];
  total: number;
  page: number;
  page_size: number;
  total_pages: number;
}

export interface SetorBasico {
  id: string;
  nome: string;
}

// ---------------------------------------------------------------------------
// Usuários (admin)
// ---------------------------------------------------------------------------

export type PapelUsuario = "TECNICO" | "DIRETOR";

export interface UsuarioOut {
  id: string;
  upn: string;
  nome: string | null;
  papel: PapelUsuario;
  ativo: boolean;
  created_at: string;
  last_login_at: string | null;
}
