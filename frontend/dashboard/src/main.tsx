import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";

import { msalInstance } from "./api/client";

const DEV_BYPASS = true;

function render() {
  const rootEl = document.getElementById("root");
  if (!rootEl) throw new Error("Root element not found");
  ReactDOM.createRoot(rootEl).render(
    <React.StrictMode>
      <App />
    </React.StrictMode>
  );
}

if (DEV_BYPASS) {
  render();
} else {
  msalInstance.initialize().then(() => {
    msalInstance.handleRedirectPromise().catch(console.error);
    render();
  });
}
