import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";

import { msalInstance } from "./api/client";

const DEV_BYPASS = import.meta.env.VITE_DEV_BYPASS_AUTH === "true";

function render() {
  const rootEl = document.getElementById("root");
  if (!rootEl) throw new Error("Root element not found");
  ReactDOM.createRoot(rootEl).render(
    <React.StrictMode>
      <App />
    </React.StrictMode>
  );
}

async function bootstrap() {
  await msalInstance.initialize();
  await msalInstance.handleRedirectPromise();
  render();
}

if (DEV_BYPASS) {
  render();
} else {
  bootstrap().catch((err) => {
    console.error("Falha na inicialização MSAL:", err);
    // Renderiza mesmo com erro para mostrar a tela de login
    render();
  });
}
