/**
 * LoginPage — exibida quando o usuário não está autenticado.
 */
import React from "react";
import { useMsal } from "@azure/msal-react";
import { loginRequest } from "../authConfig";

const LoginPage: React.FC = () => {
  const { instance } = useMsal();

  const handleLogin = () => {
    instance.loginRedirect(loginRequest).catch(console.error);
  };

  return (
    <div
      style={{
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        height: "100vh",
        gap: 24,
        background: "#f4f5f7",
      }}
    >
      <div
        style={{
          background: "#fff",
          borderRadius: 12,
          padding: "48px 40px",
          boxShadow: "0 4px 16px rgba(0,0,0,.12)",
          textAlign: "center",
          maxWidth: 380,
          width: "100%",
        }}
      >
        <h1 style={{ margin: "0 0 8px", fontSize: 22, color: "#1a1a2e" }}>
          CEPAC Dashboard Executivo
        </h1>
        <p style={{ margin: "0 0 32px", fontSize: 14, color: "#666" }}>
          SP Urbanismo / Prodam — OUCAE
        </p>

        <div
          style={{
            background: "#fff8e1",
            border: "1px solid #ffe082",
            borderRadius: 6,
            padding: "12px 16px",
            marginBottom: 28,
            fontSize: 13,
            color: "#795548",
          }}
        >
          Acesso restrito a usuários autorizados da SP Urbanismo.
        </div>

        <button
          onClick={handleLogin}
          style={{
            width: "100%",
            padding: "12px 0",
            background: "#1a73e8",
            color: "#fff",
            border: "none",
            borderRadius: 6,
            fontSize: 15,
            fontWeight: 700,
            cursor: "pointer",
            letterSpacing: ".3px",
          }}
        >
          Entrar com conta Microsoft
        </button>
      </div>
    </div>
  );
};

export default LoginPage;
