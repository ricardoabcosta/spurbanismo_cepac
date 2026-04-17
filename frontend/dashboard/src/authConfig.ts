import { Configuration, PopupRequest } from "@azure/msal-browser";

export const msalConfig: Configuration = {
  auth: {
    clientId: (import.meta.env.VITE_AZURE_CLIENT_ID as string) || "00000000-0000-0000-0000-000000000000",
    authority: `https://login.microsoftonline.com/${import.meta.env.VITE_AZURE_TENANT_ID as string}`,
    redirectUri: (import.meta.env.VITE_REDIRECT_URI as string | undefined) ?? window.location.origin,
  },
  cache: {
    cacheLocation: "sessionStorage",
    storeAuthStateInCookie: false,
  },
};

export const loginRequest: PopupRequest = {
  scopes: [`api://${import.meta.env.VITE_AZURE_CLIENT_ID as string}/CEPAC.Access`],
};
