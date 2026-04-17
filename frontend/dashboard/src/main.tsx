import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";

// Inicializa o MSAL antes de renderizar (necessário para handleRedirectPromise)
import { msalInstance } from "./api/client";

msalInstance.initialize().then(() => {
  msalInstance.handleRedirectPromise().catch(console.error);

  const rootEl = document.getElementById("root");
  if (!rootEl) throw new Error("Root element not found");

  ReactDOM.createRoot(rootEl).render(
    <React.StrictMode>
      <App />
    </React.StrictMode>
  );
});
