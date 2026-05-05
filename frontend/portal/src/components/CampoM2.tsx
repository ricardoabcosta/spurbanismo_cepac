import { useState } from "react";

const inputBase: React.CSSProperties = {
  padding: "8px 10px",
  border: "1px solid #ccc",
  borderRadius: "4px",
  fontSize: "13px",
  width: "100%",
  boxSizing: "border-box",
};

/**
 * Input m² com formatação pt-BR ao sair do campo.
 * Estado interno sempre usa ponto como separador decimal.
 */
export default function CampoM2({
  id,
  value,
  onChange,
  placeholder,
  required,
  readOnly,
  extraStyle,
}: {
  id: string;
  value: string;
  onChange?: (v: string) => void;
  placeholder?: string;
  required?: boolean;
  readOnly?: boolean;
  extraStyle?: React.CSSProperties;
}) {
  const [focused, setFocused] = useState(false);

  const display =
    !focused && value !== "" && !isNaN(Number(value))
      ? Number(value).toLocaleString("pt-BR", {
          minimumFractionDigits: 2,
          maximumFractionDigits: 2,
        })
      : value;

  return (
    <input
      id={id}
      style={{
        ...inputBase,
        ...(readOnly ? { background: "#f5f7fa", color: "#555", cursor: "not-allowed" } : {}),
        ...extraStyle,
      }}
      type="text"
      inputMode="decimal"
      value={display}
      readOnly={readOnly}
      required={required}
      placeholder={placeholder}
      onChange={(e) => onChange?.(e.target.value.replace(/\./g, "").replace(",", "."))}
      onFocus={() => setFocused(true)}
      onBlur={() => setFocused(false)}
    />
  );
}
