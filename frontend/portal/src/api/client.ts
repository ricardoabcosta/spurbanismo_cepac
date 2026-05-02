/**
 * Instância Axios com interceptor MSAL.
 * - Injeta Bearer token em cada requisição.
 * - 401 → loginRedirect
 * - 403 → rejeita com erro tipado
 */
import axios, { AxiosError, InternalAxiosRequestConfig } from "axios";
import { PublicClientApplication, InteractionRequiredAuthError } from "@azure/msal-browser";
import { msalConfig, loginRequest } from "../authConfig";

const DEV_BYPASS = import.meta.env.VITE_DEV_BYPASS_AUTH === "true";

// NOTA: initialize() NÃO é chamado aqui — é responsabilidade do main.tsx
export const msalInstance = new PublicClientApplication(msalConfig);

const apiClient = axios.create({
  baseURL: (import.meta.env.VITE_API_BASE_URL as string | undefined) ?? "",
  headers: { "Content-Type": "application/json" },
  timeout: 30_000,
});

if (!DEV_BYPASS) {
  apiClient.interceptors.request.use(async (config: InternalAxiosRequestConfig) => {
    const accounts = msalInstance.getAllAccounts();

    if (accounts.length === 0) {
      await msalInstance.loginRedirect(loginRequest);
      return new Promise(() => undefined);
    }

    try {
      const tokenResponse = await msalInstance.acquireTokenSilent({
        ...loginRequest,
        account: accounts[0],
      });
      config.headers.Authorization = `Bearer ${tokenResponse.accessToken}`;
      return config;
    } catch (error) {
      if (error instanceof InteractionRequiredAuthError) {
        await msalInstance.loginRedirect(loginRequest);
      }
      return new Promise(() => undefined);
    }
  });

  apiClient.interceptors.response.use(
    (response) => response,
    (error: AxiosError) => {
      if (error.response?.status === 401) {
        msalInstance.loginRedirect(loginRequest).catch(console.error);
      }
      if (error.response?.status === 403) {
        const customError = new Error("Acesso negado — permissão insuficiente");
        customError.name = "AccessDeniedError";
        return Promise.reject(customError);
      }
      return Promise.reject(error);
    }
  );
}

export default apiClient;
