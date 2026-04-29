import { useMsal, useIsAuthenticated } from "@azure/msal-react";
import { useNavigate, useLocation } from "react-router-dom";
import { useEffect } from "react";
import { loginRequest } from "../authConfig";

const DEV_BYPASS = true;

export default function LoginPage() {
  const { instance } = useMsal();
  const isAuthenticated = useIsAuthenticated();
  const navigate = useNavigate();
  const location = useLocation();

  const from = (location.state as { from?: { pathname: string } })?.from?.pathname ?? "/propostas";

  useEffect(() => {
    if (DEV_BYPASS || isAuthenticated) {
      navigate(from, { replace: true });
    }
  }, [isAuthenticated, navigate, from]);

  async function handleLogin() {
    try {
      await instance.loginRedirect(loginRequest);
    } catch (e) {
      console.error("Erro ao iniciar login:", e);
    }
  }

  return (
    <div
      style={{
        minHeight: "100vh",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        background: "#f0f4f8",
        fontFamily: "system-ui, sans-serif",
      }}
    >
      <div
        style={{
          width: "100%",
          maxWidth: 420,
          borderRadius: 10,
          overflow: "hidden",
          boxShadow: "0 4px 24px rgba(0,0,0,0.14)",
        }}
      >
        {/* Cabeçalho com gradiente */}
        <div
          style={{
            background: "linear-gradient(90deg, #0B2A4A 0%, #0F3A6D 55%, #145DA0 85%, #1C6ED5 100%)",
            padding: "28px 32px 24px",
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            gap: 12,
          }}
        >
          <img
            src="/imagens/logobranco.svg"
            alt="ZENITE"
            style={{ height: 72, width: "auto" }}
          />
          <div
            style={{
              width: "100%",
              height: 1,
              background: "rgba(255,255,255,0.2)",
            }}
          />
          <p
            style={{
              margin: 0,
              fontSize: 13,
              color: "rgba(255,255,255,0.8)",
              textAlign: "center",
              letterSpacing: "0.03em",
            }}
          >
            Operação Urbana Consorciada Água Espraiada
          </p>
        </div>

        {/* Corpo do card */}
        <div
          style={{
            background: "#fff",
            padding: "36px 32px 40px",
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            gap: 16,
          }}
        >
          <p
            style={{
              margin: 0,
              fontSize: 15,
              color: "#333",
              textAlign: "center",
              lineHeight: 1.5,
            }}
          >
            Acesso restrito a usuários autorizados da SP Urbanismo.
          </p>

          <button
            onClick={handleLogin}
            style={{
              marginTop: 8,
              width: "100%",
              padding: "13px 0",
              background: "linear-gradient(90deg, #0B2A4A 0%, #145DA0 100%)",
              color: "#fff",
              border: "none",
              borderRadius: 6,
              fontSize: 15,
              fontWeight: 700,
              cursor: "pointer",
              letterSpacing: ".3px",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              gap: 10,
            }}
            onMouseEnter={(e) => { e.currentTarget.style.opacity = "0.9"; }}
            onMouseLeave={(e) => { e.currentTarget.style.opacity = "1"; }}
          >
            <svg width="18" height="18" viewBox="0 0 21 21" fill="none">
              <path d="M10 0H0V10H10V0Z" fill="#F35325"/>
              <path d="M21 0H11V10H21V0Z" fill="#81BC06"/>
              <path d="M10 11H0V21H10V11Z" fill="#05A6F0"/>
              <path d="M21 11H11V21H21V11Z" fill="#FFBA08"/>
            </svg>
            Entrar com conta Microsoft
          </button>

          <p style={{ margin: 0, fontSize: 11, color: "#aaa", textAlign: "center" }}>
            SP Urbanismo · Prodam · OUCAE
          </p>
        </div>
      </div>
    </div>
  );
}
