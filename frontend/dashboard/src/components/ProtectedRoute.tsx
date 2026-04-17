/**
 * ProtectedRoute — redireciona para LoginPage quando não autenticado.
 */
import React from "react";
import { useMsal, useIsAuthenticated } from "@azure/msal-react";
import LoginPage from "../pages/LoginPage";

interface Props {
  children: React.ReactNode;
}

const DEV_BYPASS = import.meta.env.VITE_DEV_BYPASS_AUTH === "true";

const ProtectedRoute: React.FC<Props> = ({ children }) => {
  const { inProgress } = useMsal();
  const isAuthenticated = useIsAuthenticated();

  if (DEV_BYPASS) return <>{children}</>;

  if (inProgress !== "none") {
    return (
      <div style={{ display: "flex", justifyContent: "center", alignItems: "center", height: "100vh" }}>
        <p>Autenticando...</p>
      </div>
    );
  }

  if (!isAuthenticated) {
    return <LoginPage />;
  }

  return <>{children}</>;
};

export default ProtectedRoute;
