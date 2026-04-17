/**
 * Instância Axios com interceptor MSAL.
 *
 * - Injeta o Bearer token em cada requisição autenticada.
 * - Em caso de 401 redireciona para loginRedirect.
 */
import axios, { type AxiosInstance } from "axios";
import { PublicClientApplication } from "@azure/msal-browser";
import { msalConfig, loginRequest } from "../authConfig";

// Instância singleton do MSAL — criada uma vez e exportada para uso no App.tsx
export const msalInstance = new PublicClientApplication(msalConfig);

// Inicializa o MSAL antes de qualquer outra coisa
await msalInstance.initialize();

function buildAxiosInstance(): AxiosInstance {
  const instance = axios.create({
    baseURL: (import.meta.env.VITE_API_BASE_URL as string | undefined) ?? "",
    timeout: 30_000,
  });

  // Interceptor de REQUEST — injeta Bearer token
  instance.interceptors.request.use(async (config) => {
    const accounts = msalInstance.getAllAccounts();
    if (accounts.length === 0) {
      // Não autenticado — deixa passar sem token (ProtectedRoute vai redirecionar)
      return config;
    }

    try {
      const result = await msalInstance.acquireTokenSilent({
        ...loginRequest,
        account: accounts[0],
      });
      config.headers["Authorization"] = `Bearer ${result.accessToken}`;
    } catch {
      // Token expirado ou erro silencioso → redireciona para login
      await msalInstance.loginRedirect(loginRequest);
    }

    return config;
  });

  // Interceptor de RESPONSE — trata 401
  instance.interceptors.response.use(
    (response) => response,
    async (error: unknown) => {
      if (
        axios.isAxiosError(error) &&
        error.response?.status === 401
      ) {
        await msalInstance.loginRedirect(loginRequest);
        // Promise pendente enquanto redireciona
        return new Promise(() => undefined);
      }
      return Promise.reject(error);
    }
  );

  return instance;
}

const apiClient = buildAxiosInstance();
export default apiClient;
