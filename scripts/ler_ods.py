"""
Script de leitura e validação da planilha estudo_cepac.ods.

Uso:
    python3 scripts/ler_ods.py

Saída:
    - Primeiras 3 linhas como tabela legível
    - Primeiras 5 linhas como JSON (para validar o parser)
    - Contagem total de registros

Requer: odfpy  (pip install odfpy)
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

from odf.opendocument import load
from odf.table import Table, TableRow, TableCell
from odf.text import P

ODS_PATH = Path(__file__).parent.parent / "docs" / "estudo_cepac.ods"

# Colunas válidas (índices 0-32); colunas 33-35 são vazias/auxiliares
HEADER_COUNT = 33


def get_cell_value(cell) -> str:
    parts = []
    for p in cell.getElementsByType(P):
        text = str(p)
        if text:
            parts.append(text)
    return " ".join(parts).strip()


def read_sheet(doc, sheet_name: str, max_rows: int | None = None) -> list[list[str]]:
    """Lê todas as linhas de uma aba, expandindo células com repeat."""
    for sheet in doc.spreadsheet.getElementsByType(Table):
        if sheet.getAttribute("name") == sheet_name:
            rows: list[list[str]] = []
            for i, row in enumerate(sheet.getElementsByType(TableRow)):
                if max_rows is not None and i >= max_rows:
                    break
                cells: list[str] = []
                for cell in row.getElementsByType(TableCell):
                    repeat = cell.getAttribute("numbercolumnsrepeated")
                    repeat = int(repeat) if repeat else 1
                    val = get_cell_value(cell)
                    # Padding gigante de células vazias no final — comprime para 1
                    if repeat > 20 and val == "":
                        cells.append(val)
                    else:
                        for _ in range(repeat):
                            cells.append(val)
                rows.append(cells)
            return rows
    print(f"ERRO: aba '{sheet_name}' não encontrada.", file=sys.stderr)
    return []


def main() -> None:
    if not ODS_PATH.exists():
        print(f"ERRO: arquivo não encontrado em {ODS_PATH}", file=sys.stderr)
        sys.exit(1)

    doc = load(str(ODS_PATH))
    dados = read_sheet(doc, "Dados")

    if not dados:
        print("ERRO: aba Dados vazia.", file=sys.stderr)
        sys.exit(1)

    header = dados[0][:HEADER_COUNT]
    data_rows = [row for row in dados[1:] if any(c.strip() for c in row[:HEADER_COUNT])]

    print(f"Arquivo : {ODS_PATH}")
    print(f"Header  : {HEADER_COUNT} colunas")
    print(f"Registros não-vazios: {len(data_rows)}\n")

    # --- Primeiras 3 linhas legíveis ---
    print("=" * 70)
    print("PRIMEIRAS 3 LINHAS — VISÃO TABULAR")
    print("=" * 70)
    for n, row in enumerate(data_rows[:3], start=1):
        print(f"\n  Linha {n}:")
        for i, col in enumerate(header):
            val = row[i] if i < len(row) else ""
            if val:
                print(f"    {col!r:30s} => {val!r}")

    # --- Primeiras 5 linhas como JSON ---
    print("\n" + "=" * 70)
    print("PRIMEIRAS 5 LINHAS — JSON")
    print("=" * 70)
    result = []
    for row in data_rows[:5]:
        record = {header[i]: row[i] if i < len(row) else "" for i in range(len(header))}
        result.append(record)
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
