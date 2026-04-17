/**
 * Página /login — botão de autenticação MSAL.
 */
import { useMsal, useIsAuthenticated } from "@azure/msal-react";
import { useNavigate, useLocation } from "react-router-dom";
import { useEffect } from "react";
import { loginRequest } from "../authConfig";

const styles: Record<string, React.CSSProperties> = {
  wrapper: {
    minHeight: "100vh",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    background: "#f0f4f8",
    fontFamily: "system-ui, sans-serif",
  },
  card: {
    background: "#fff",
    borderRadius: "8px",
    boxShadow: "0 2px 12px rgba(0,0,0,0.12)",
    padding: "48px 40px",
    maxWidth: "400px",
    width: "100%",
    textAlign: "center",
  },
  logo: {
    fontSize: "28px",
    fontWeight: 700,
    color: "#003087",
    marginBottom: "8px",
  },
  subtitulo: {
    fontSize: "15px",
    color: "#555",
    marginBottom: "32px",
  },
  botao: {
    display: "inline-block",
    padding: "12px 24px",
    background: "#003087",
    color: "#fff",
    border: "none",
    borderRadius: "6px",
    fontSize: "15px",
    fontWeight: 500,
    cursor: "pointer",
    width: "100%",
  },
};

export default function LoginPage() {
  const { instance } = useMsal();
  const isAuthenticated = useIsAuthenticated();
  const navigate = useNavigate();
  const location = useLocation();

  const from = (location.state as { from?: { pathname: string } })?.from?.pathname ?? "/solicitacoes";

  useEffect(() => {
    if (isAuthenticated) {
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
    <div style={styles.wrapper}>
      <div style={styles.card}>
        <div style={styles.logo}>CEPAC</div>
        <p style={styles.subtitulo}>Portal de Operações Técnicas — SP Urbanismo</p>
        <button style={styles.botao} onClick={handleLogin}>
          Entrar com conta SP Urbanismo
        </button>
      </div>
    </div>
  );
}
