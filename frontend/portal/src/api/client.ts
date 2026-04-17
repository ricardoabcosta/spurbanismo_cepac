/**
 * Instância Axios com interceptor MSAL.
 *
 * - Injeta o Bearer token em cada requisição autenticada.
 * - Em caso de 401 redireciona para loginRedirect.
 */
import axios, { type AxiosInstance } from "axios";
import { PublicClientApplication } from "@azure/msal-browser";
import { msalConfig, loginRequest } from "../authConfig";

const DEV_BYPASS = import.meta.env.VITE_DEV_BYPASS_AUTH === "true";

// Instância singleton do MSAL — criada uma vez e exportada para uso no App.tsx
export const msalInstance = new PublicClientApplication(msalConfig);

if (!DEV_BYPASS) {
  await msalInstance.initialize();
}

function buildAxiosInstance(): AxiosInstance {
  const instance = axios.create({
    baseURL: (import.meta.env.VITE_API_BASE_URL as string | undefined) ?? "",
    timeout: 30_000,
  });

  if (DEV_BYPASS) {
    return instance;
  }

  // Interceptor de REQUEST — injeta Bearer token
  instance.interceptors.request.use(async (config) => {
    const accounts = msalInstance.getAllAccounts();
    if (accounts.length === 0) {
      return config;
    }

    try {
      const result = await msalInstance.acquireTokenSilent({
        ...loginRequest,
        account: accounts[0],
      });
      config.headers["Authorization"] = `Bearer ${result.accessToken}`;
    } catch {
      await msalInstance.loginRedirect(loginRequest);
    }

    return config;
  });

  // Interceptor de RESPONSE — trata 401
  instance.interceptors.response.use(
    (response) => response,
    async (error: unknown) => {
      if (axios.isAxiosError(error) && error.response?.status === 401) {
        await msalInstance.loginRedirect(loginRequest);
        return new Promise(() => undefined);
      }
      return Promise.reject(error);
    }
  );

  return instance;
}

const apiClient = buildAxiosInstance();
export default apiClient;
