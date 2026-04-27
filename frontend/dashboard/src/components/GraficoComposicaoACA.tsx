import React from "react";
import GraficoComposicaoOrigem from "./GraficoComposicaoOrigem";
import type { OcupacaoSetor } from "../types/api";

const GraficoComposicaoACA: React.FC<{ setores: OcupacaoSetor[] }> = ({ setores }) => (
  <GraficoComposicaoOrigem
    titulo="COMPOSIÇÃO DO CONSUMO ACA POR SETOR"
    descricao="Apenas consumo originado via ACA (exclui NUVEM). Passe o mouse no donut para detalhes."
    rotulo="ACA"
    setores={setores}
    getCampos={(s) => ({
      r: parseFloat(s.consumido_r_aca),
      nr: parseFloat(s.consumido_nr_aca),
    })}
  />
);

export default GraficoComposicaoACA;
