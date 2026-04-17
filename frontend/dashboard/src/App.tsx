/**
 * App — raiz da aplicação.
 * MsalProvider envolve tudo; ProtectedRoute bloqueia não autenticados.
 */
import React from "react";
import { MsalProvider } from "@azure/msal-react";
import { msalInstance } from "./api/client";
import ProtectedRoute from "./components/ProtectedRoute";
import DashboardPage from "./pages/DashboardPage";

const App: React.FC = () => (
  <MsalProvider instance={msalInstance}>
    <ProtectedRoute>
      <DashboardPage />
    </ProtectedRoute>
  </MsalProvider>
);

export default App;
