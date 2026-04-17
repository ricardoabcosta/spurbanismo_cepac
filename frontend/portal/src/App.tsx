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
import SolicitacoesPage from "./pages/SolicitacoesPage";
import NovaSolicitacaoPage from "./pages/NovaSolicitacaoPage";
import DetalhesSolicitacaoPage from "./pages/DetalhesSolicitacaoPage";

const App: React.FC = () => (
  <MsalProvider instance={msalInstance}>
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<LoginPage />} />

        <Route
          path="/solicitacoes"
          element={
            <ProtectedRoute>
              <SolicitacoesPage />
            </ProtectedRoute>
          }
        />
        <Route
          path="/solicitacoes/nova"
          element={
            <ProtectedRoute>
              <NovaSolicitacaoPage />
            </ProtectedRoute>
          }
        />
        <Route
          path="/solicitacoes/:id"
          element={
            <ProtectedRoute>
              <DetalhesSolicitacaoPage />
            </ProtectedRoute>
          }
        />

        {/* Rota padrão → lista de solicitações */}
        <Route path="*" element={<Navigate to="/solicitacoes" replace />} />
      </Routes>
    </BrowserRouter>
  </MsalProvider>
);

export default App;
