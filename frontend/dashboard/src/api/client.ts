/**
 * Instância Axios com interceptor MSAL.
 * - Injeta Bearer token em cada requisição.
 * - 401 → loginRedirect
 * - 403 → exibe mensagem e rejeita
 */
import axios, { AxiosError, InternalAxiosRequestConfig } from "axios";
import { PublicClientApplication, InteractionRequiredAuthError } from "@azure/msal-browser";
import { msalConfig, loginRequest } from "../authConfig";

const DEV_BYPASS = import.meta.env.VITE_DEV_BYPASS_AUTH === "true";

export const msalInstance = new PublicClientApplication(msalConfig);

const apiClient = axios.create({
  baseURL: (import.meta.env.VITE_API_BASE_URL as string | undefined) ?? "",
  headers: { "Content-Type": "application/json" },
});

if (!DEV_BYPASS) {
  apiClient.interceptors.request.use(async (config: InternalAxiosRequestConfig) => {
    const accounts = msalInstance.getAllAccounts();

    if (accounts.length === 0) {
      await msalInstance.loginRedirect(loginRequest);
      return config;
    }

    try {
      const tokenResponse = await msalInstance.acquireTokenSilent({
        ...loginRequest,
        account: accounts[0],
      });
      config.headers.Authorization = `Bearer ${tokenResponse.accessToken}`;
    } catch (error) {
      if (error instanceof InteractionRequiredAuthError) {
        await msalInstance.loginRedirect(loginRequest);
      }
      throw error;
    }

    return config;
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
