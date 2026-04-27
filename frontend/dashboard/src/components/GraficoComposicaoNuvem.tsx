import React from "react";
import GraficoComposicaoOrigem from "./GraficoComposicaoOrigem";
import type { OcupacaoSetor } from "../types/api";

const GraficoComposicaoNuvem: React.FC<{ setores: OcupacaoSetor[] }> = ({ setores }) => (
  <GraficoComposicaoOrigem
    titulo="COMPOSIÇÃO DO CONSUMO NUVEM POR SETOR"
    descricao="Apenas consumo originado via NUVEM (exclui ACA). Passe o mouse no donut para detalhes."
    rotulo="NUVEM"
    setores={setores}
    getCampos={(s) => ({
      r: parseFloat(s.consumido_r_nuvem),
      nr: parseFloat(s.consumido_nr_nuvem),
    })}
  />
);

export default GraficoComposicaoNuvem;
