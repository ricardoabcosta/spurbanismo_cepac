/**
 * Página /solicitacoes/nova — formulário de criação de solicitação.
 *
 * Fluxo:
 * 1. Seleciona setor → uso → origem
 * 2. Carrega títulos DISPONIVEL com esses filtros
 * 3. Checkboxes múltiplos dos títulos
 * 4. Campo SEI (validado)
 * 5. Campos opcionais: proposta_codigo, observacao
 * 6. Upload de documento (opcional)
 * 7. Enviar → POST /portal/solicitacoes
 */
import { useState, useEffect, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import { listarTitulosDisponiveis, criarSolicitacao, isErroNegocioError } from "../api/portal";
import UploadDocumento from "../components/UploadDocumento";
import type { TituloDisponivel } from "../types/api";
import type { ErroNegocio } from "../types/api";

const SEI_NOVO = /^\d{4}\.\d{4}\/\d{7}-\d$/;
const SEI_SIMPROC = /^\d{4}-\d\.\d{3}\.\d{3}-\d$/;
const validarSEI = (v: string) => SEI_NOVO.test(v) || SEI_SIMPROC.test(v);

const MENSAGENS_ERRO: Record<string, (erro: ErroNegocio) => string> = {
  TETO_NR_EXCEDIDO: () => "Setor Berrini: estoque NR esgotado. Pedidos NR não podem ser processados.",
  RESERVA_R_VIOLADA: () => "Setor Chucri Zaidan: pedido NR invadiria a reserva residencial protegida.",
  QUARENTENA_ATIVA: (e) => `Título em quarentena — disponível em ${e.dias_restantes ?? "?"} dias.`,
  NUMERO_SEI_OBRIGATORIO: () => "Informe o número do processo SEI antes de enviar.",
  SOLICITACAO_NAO_CANCELAVEL: (e) => e.mensagem,
};

function traduzirErroNegocio(erro: ErroNegocio): string {
  const fn = MENSAGENS_ERRO[erro.codigo_erro];
  return fn ? fn(erro) : erro.mensagem;
}

const styles: Record<string, React.CSSProperties> = {
  pagina: { fontFamily: "system-ui, sans-serif", maxWidth: "800px", margin: "0 auto", padding: "24px 16px" },
  titulo: { fontSize: "22px", fontWeight: 700, color: "#003087", marginBottom: "24px" },
  secao: { marginBottom: "20px" },
  label: { display: "block", marginBottom: "5px", fontSize: "14px", fontWeight: 500 },
  input: { padding: "8px 10px", border: "1px solid #ccc", borderRadius: "4px", fontSize: "14px", width: "100%", boxSizing: "border-box" as const },
  inputErro: { borderColor: "#cc0000" },
  select: { padding: "8px 10px", border: "1px solid #ccc", borderRadius: "4px", fontSize: "14px", width: "100%", boxSizing: "border-box" as const },
  mensagemErroSei: { color: "#cc0000", fontSize: "12px", marginTop: "4px" },
  textarea: { padding: "8px 10px", border: "1px solid #ccc", borderRadius: "4px", fontSize: "14px", width: "100%", boxSizing: "border-box" as const, minHeight: "80px", resize: "vertical" as const },
  listaTitulos: { maxHeight: "280px", overflowY: "auto" as const, border: "1px solid #ccc", borderRadius: "4px", padding: "8px" },
  itemTitulo: { display: "flex", alignItems: "flex-start", gap: "8px", padding: "6px 0", borderBottom: "1px solid #f0f0f0" },
  checkboxLabel: { fontSize: "13px", cursor: "pointer", flex: 1 },
  botoes: { display: "flex", gap: "10px", marginTop: "24px" },
  botaoEnviar: { padding: "10px 22px", background: "#003087", color: "#fff", border: "none", borderRadius: "5px", cursor: "pointer", fontSize: "15px" },
  botaoCancelar: { padding: "10px 22px", background: "#888", color: "#fff", border: "none", borderRadius: "5px", cursor: "pointer", fontSize: "15px" },
  erro: { color: "#cc0000", background: "#fff0f0", padding: "12px", borderRadius: "4px", marginBottom: "16px" },
  hint: { fontSize: "12px", color: "#666", marginTop: "3px" },
  carregando: { color: "#666", fontStyle: "italic", fontSize: "13px" },
  nenhum: { color: "#888", fontSize: "13px", padding: "8px" },
  linha: { display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: "14px" },
};

export default function NovaSolicitacaoPage() {
  const navigate = useNavigate();

  const [setor, setSetor] = useState("");
  const [uso, setUso] = useState<"R" | "NR" | "">("");
  const [origem, setOrigem] = useState<"ACA" | "NUVEM" | "">("");
  const [areaM2, setAreaM2] = useState("");
  const [sei, setSei] = useState("");
  const [seiTocado, setSeiTocado] = useState(false);
  const [proposta, setProposta] = useState("");
  const [observacao, setObservacao] = useState("");
  const [titulos, setTitulos] = useState<TituloDisponivel[]>([]);
  const [titulosSelecionados, setTitulosSelecionados] = useState<Set<string>>(new Set());
  const [carregandoTitulos, setCarregandoTitulos] = useState(false);
  const [enviando, setEnviando] = useState(false);
  const [erroGeral, setErroGeral] = useState("");

  const seiValido = sei === "" || validarSEI(sei);
  const seiInvalido = seiTocado && sei !== "" && !validarSEI(sei);

  // Carrega títulos quando setor/uso/origem estão selecionados
  const carregarTitulos = useCallback(async () => {
    if (!setor || !uso || !origem) {
      setTitulos([]);
      setTitulosSelecionados(new Set());
      return;
    }
    setCarregandoTitulos(true);
    try {
      const dados = await listarTitulosDisponiveis({ setor, uso, origem });
      setTitulos(dados);
      setTitulosSelecionados(new Set());
    } catch {
      setTitulos([]);
    } finally {
      setCarregandoTitulos(false);
    }
  }, [setor, uso, origem]);

  useEffect(() => {
    void carregarTitulos();
  }, [carregarTitulos]);

  // Persiste rascunho em sessionStorage (para token expirado)
  useEffect(() => {
    const rascunho = { setor, uso, origem, areaM2, sei, proposta, observacao };
    sessionStorage.setItem("cepac_nova_solicitacao_rascunho", JSON.stringify(rascunho));
  }, [setor, uso, origem, areaM2, sei, proposta, observacao]);

  // Restaura rascunho ao montar
  useEffect(() => {
    const raw = sessionStorage.getItem("cepac_nova_solicitacao_rascunho");
    if (!raw) return;
    try {
      const r = JSON.parse(raw) as {
        setor?: string; uso?: "R" | "NR" | ""; origem?: "ACA" | "NUVEM" | "";
        areaM2?: string; sei?: string; proposta?: string; observacao?: string;
      };
      if (r.setor) setSetor(r.setor);
      if (r.uso) setUso(r.uso);
      if (r.origem) setOrigem(r.origem);
      if (r.areaM2) setAreaM2(r.areaM2);
      if (r.sei) setSei(r.sei);
      if (r.proposta) setProposta(r.proposta);
      if (r.observacao) setObservacao(r.observacao);
    } catch {
      // ignora rascunho corrompido
    }
  }, []);

  function toggleTitulo(id: string) {
    setTitulosSelecionados((prev) => {
      const novo = new Set(prev);
      if (novo.has(id)) novo.delete(id);
      else novo.add(id);
      return novo;
    });
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setErroGeral("");

    // Validações client-side
    if (!setor || !uso || !origem) {
      setErroGeral("Preencha setor, uso e origem.");
      return;
    }
    if (!areaM2 || isNaN(parseFloat(areaM2)) || parseFloat(areaM2) <= 0) {
      setErroGeral("Informe uma área em m² válida (maior que zero).");
      return;
    }
    if (!sei || !validarSEI(sei)) {
      setSeiTocado(true);
      setErroGeral("Informe o número do processo SEI antes de enviar.");
      return;
    }
    if (titulosSelecionados.size === 0) {
      setErroGeral("Selecione ao menos um título CEPAC.");
      return;
    }

    setEnviando(true);
    try {
      const sol = await criarSolicitacao({
        setor,
        uso: uso as "R" | "NR",
        origem: origem as "ACA" | "NUVEM",
        area_m2: parseFloat(areaM2),
        numero_processo_sei: sei,
        titulo_ids: Array.from(titulosSelecionados),
        proposta_codigo: proposta || undefined,
        observacao: observacao || undefined,
      });
      sessionStorage.removeItem("cepac_nova_solicitacao_rascunho");
      navigate(`/solicitacoes/${sol.id}`);
    } catch (e) {
      if (isErroNegocioError(e)) {
        setErroGeral(traduzirErroNegocio(e.erroNegocio));
      } else {
        setErroGeral("Erro inesperado ao criar a solicitação. Tente novamente.");
      }
    } finally {
      setEnviando(false);
    }
  }

  return (
    <div style={styles.pagina}>
      <h1 style={styles.titulo}>Nova Solicitação CEPAC</h1>

      {erroGeral && (
        <p role="alert" style={styles.erro}>{erroGeral}</p>
      )}

      <form onSubmit={handleSubmit} noValidate>
        {/* Linha 1: Setor / Uso / Origem */}
        <div style={{ ...styles.secao, ...styles.linha }}>
          <div>
            <label style={styles.label} htmlFor="setor">Setor *</label>
            <input
              id="setor"
              style={styles.input}
              placeholder="Ex: Brooklin"
              value={setor}
              onChange={(e) => setSetor(e.target.value)}
              required
            />
          </div>
          <div>
            <label style={styles.label} htmlFor="uso">Uso *</label>
            <select
              id="uso"
              style={styles.select}
              value={uso}
              onChange={(e) => setUso(e.target.value as "R" | "NR" | "")}
              required
            >
              <option value="">Selecione…</option>
              <option value="R">R — Residencial</option>
              <option value="NR">NR — Não-Residencial</option>
            </select>
          </div>
          <div>
            <label style={styles.label} htmlFor="origem">Origem *</label>
            <select
              id="origem"
              style={styles.select}
              value={origem}
              onChange={(e) => setOrigem(e.target.value as "ACA" | "NUVEM" | "")}
              required
            >
              <option value="">Selecione…</option>
              <option value="ACA">ACA</option>
              <option value="NUVEM">NUVEM</option>
            </select>
          </div>
        </div>

        {/* Área m² */}
        <div style={styles.secao}>
          <label style={styles.label} htmlFor="area">Área total (m²) *</label>
          <input
            id="area"
            style={{ ...styles.input, maxWidth: "200px" }}
            type="number"
            step="0.01"
            min="0.01"
            placeholder="Ex: 1000.00"
            value={areaM2}
            onChange={(e) => setAreaM2(e.target.value)}
            required
          />
        </div>

        {/* Títulos disponíveis */}
        <div style={styles.secao}>
          <label style={styles.label}>Títulos disponíveis *</label>
          {!setor || !uso || !origem ? (
            <p style={styles.hint}>Selecione setor, uso e origem para ver os títulos disponíveis.</p>
          ) : carregandoTitulos ? (
            <p style={styles.carregando}>Carregando títulos…</p>
          ) : titulos.length === 0 ? (
            <p style={styles.nenhum}>Nenhum título disponível para os critérios selecionados.</p>
          ) : (
            <>
              <p style={styles.hint}>{titulos.length} título(s) disponível(is) — selecione um ou mais:</p>
              <div style={styles.listaTitulos} role="group" aria-label="Títulos CEPAC disponíveis">
                {titulos.map((t) => (
                  <div key={t.id} style={styles.itemTitulo}>
                    <input
                      type="checkbox"
                      id={`titulo-${t.id}`}
                      checked={titulosSelecionados.has(t.id)}
                      onChange={() => toggleTitulo(t.id)}
                    />
                    <label htmlFor={`titulo-${t.id}`} style={styles.checkboxLabel}>
                      <strong>{t.codigo}</strong> — {t.setor} / {t.uso} / {t.origem} — R$ {Number(t.valor_m2).toLocaleString("pt-BR", { minimumFractionDigits: 2 })}/m²
                    </label>
                  </div>
                ))}
              </div>
              <p style={styles.hint}>{titulosSelecionados.size} selecionado(s)</p>
            </>
          )}
        </div>

        {/* Número SEI */}
        <div style={styles.secao}>
          <label style={styles.label} htmlFor="sei">Número do Processo SEI *</label>
          <input
            id="sei"
            style={{ ...styles.input, ...(seiInvalido ? styles.inputErro : {}) }}
            placeholder="Ex: 7810.2024/0001234-5 ou 2005-0.060.565-0"
            value={sei}
            onChange={(e) => setSei(e.target.value)}
            onBlur={() => setSeiTocado(true)}
            aria-invalid={seiInvalido}
            aria-describedby={seiInvalido ? "sei-erro" : undefined}
            required
          />
          {seiInvalido && (
            <p id="sei-erro" style={styles.mensagemErroSei} role="alert">
              Formato inválido. Use SEI (ex: 7810.2024/0001234-5) ou SIMPROC (ex: 2005-0.060.565-0).
            </p>
          )}
          {!seiInvalido && seiTocado && sei && (
            <p style={{ ...styles.hint, color: "#007700" }}>Formato válido.</p>
          )}
        </div>

        {/* Proposta (opcional) */}
        <div style={styles.secao}>
          <label style={styles.label} htmlFor="proposta">Código da Proposta (opcional)</label>
          <input
            id="proposta"
            style={{ ...styles.input, maxWidth: "240px" }}
            placeholder="Ex: AE-0183"
            value={proposta}
            onChange={(e) => setProposta(e.target.value)}
          />
        </div>

        {/* Observação */}
        <div style={styles.secao}>
          <label style={styles.label} htmlFor="obs">Observação (opcional)</label>
          <textarea
            id="obs"
            style={styles.textarea}
            placeholder="Observação livre do técnico (máx. 1000 caracteres)"
            maxLength={1000}
            value={observacao}
            onChange={(e) => setObservacao(e.target.value)}
          />
          <p style={styles.hint}>{observacao.length}/1000 caracteres</p>
        </div>

        {/* Upload de documento */}
        {sei && validarSEI(sei) && (
          <div style={styles.secao}>
            <UploadDocumento
              numeroProcessoSei={sei}
              propostaId={proposta || undefined}
              disabled={enviando}
            />
          </div>
        )}

        {/* Botões */}
        <div style={styles.botoes}>
          <button
            type="submit"
            style={styles.botaoEnviar}
            disabled={enviando || seiInvalido || !seiValido}
          >
            {enviando ? "Enviando…" : "Enviar Solicitação"}
          </button>
          <button
            type="button"
            style={styles.botaoCancelar}
            onClick={() => navigate("/solicitacoes")}
            disabled={enviando}
          >
            Voltar
          </button>
        </div>
      </form>
    </div>
  );
}
