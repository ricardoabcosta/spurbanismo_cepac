/**
 * Redireciona usuários não autenticados para /login.
 * Aguarda a inicialização do MSAL antes de decidir o redirecionamento.
 */
import { useIsAuthenticated, useMsal } from "@azure/msal-react";
import { Navigate, useLocation } from "react-router-dom";

interface ProtectedRouteProps {
  children: React.ReactNode;
}

const DEV_BYPASS = import.meta.env.VITE_DEV_BYPASS_AUTH === "true";

export default function ProtectedRoute({ children }: ProtectedRouteProps) {
  const { inProgress } = useMsal();
  const isAuthenticated = useIsAuthenticated();
  const location = useLocation();

  if (DEV_BYPASS) return <>{children}</>;

  // MSAL ainda está inicializando — não redireciona ainda
  if (inProgress !== "none") {
    return <div style={{ padding: "2rem", textAlign: "center", fontFamily: "system-ui, sans-serif" }}>Carregando...</div>;
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  return <>{children}</>;
}
