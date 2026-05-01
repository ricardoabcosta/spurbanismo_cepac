/**
 * App — raiz do Dashboard Executivo.
 * MsalProvider envolve tudo; react-router gerencia as páginas.
 */
import React from "react";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { MsalProvider } from "@azure/msal-react";
import { msalInstance } from "./api/client";
import ProtectedRoute from "./components/ProtectedRoute";
import LoginPage from "./pages/LoginPage";
import DashboardPage from "./pages/DashboardPage";

const App: React.FC = () => (
  <MsalProvider instance={msalInstance}>
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<LoginPage />} />

        <Route
          path="/dashboard"
          element={
            <ProtectedRoute>
              <DashboardPage />
            </ProtectedRoute>
          }
        />

        {/* Rota padrão → dashboard */}
        <Route path="*" element={<Navigate to="/dashboard" replace />} />
      </Routes>
    </BrowserRouter>
  </MsalProvider>
);

export default App;
