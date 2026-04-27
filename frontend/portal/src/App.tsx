/**
 * App — raiz do Portal de Operações Técnicas.
 * MsalProvider envolve tudo; react-router gerencia as páginas.
 */
import React from "react";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { MsalProvider } from "@azure/msal-react";
import { msalInstance } from "./api/client";
import ProtectedRoute from "./components/ProtectedRoute";
import LoginPage from "./pages/LoginPage";
import PropostasPage from "./pages/PropostasPage";
import NovaPropostaPage from "./pages/NovaPropostaPage";
import DetalhesPropostaPage from "./pages/DetalhesPropostaPage";
import SetoresAdminPage from "./pages/SetoresAdminPage";
import DashboardPage from "./pages/DashboardPage";

const App: React.FC = () => (
  <MsalProvider instance={msalInstance}>
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<LoginPage />} />

        <Route
          path="/propostas"
          element={
            <ProtectedRoute>
              <PropostasPage />
            </ProtectedRoute>
          }
        />
        <Route
          path="/propostas/nova"
          element={
            <ProtectedRoute>
              <NovaPropostaPage />
            </ProtectedRoute>
          }
        />
        <Route
          path="/propostas/:codigo"
          element={
            <ProtectedRoute>
              <DetalhesPropostaPage />
            </ProtectedRoute>
          }
        />

        <Route
          path="/admin/setores"
          element={
            <ProtectedRoute>
              <SetoresAdminPage />
            </ProtectedRoute>
          }
        />

        <Route
          path="/dashboard"
          element={
            <ProtectedRoute>
              <DashboardPage />
            </ProtectedRoute>
          }
        />

        {/* Rota padrão → lista de propostas */}
        <Route path="*" element={<Navigate to="/propostas" replace />} />
      </Routes>
    </BrowserRouter>
  </MsalProvider>
);

export default App;
