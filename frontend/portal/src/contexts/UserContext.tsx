import React, { createContext, useContext, useEffect, useState } from "react";
import { useIsAuthenticated } from "@azure/msal-react";
import { getMeuPerfil } from "../api/admin";
import type { UsuarioOut } from "../types/api";

interface UserContextValue {
  usuario: UsuarioOut | null;
  isDiretor: boolean;
  carregando: boolean;
}

const UserContext = createContext<UserContextValue>({
  usuario: null,
  isDiretor: false,
  carregando: true,
});

export function UserProvider({ children }: { children: React.ReactNode }) {
  const isAuthenticated = useIsAuthenticated();
  const [usuario, setUsuario] = useState<UsuarioOut | null>(null);
  const [carregando, setCarregando] = useState(true);

  useEffect(() => {
    if (!isAuthenticated) {
      setCarregando(false);
      return;
    }
    getMeuPerfil()
      .then(setUsuario)
      .catch(() => { /* silencioso — não bloqueia a UI */ })
      .finally(() => setCarregando(false));
  }, [isAuthenticated]);

  return (
    <UserContext.Provider value={{ usuario, isDiretor: usuario?.papel === "DIRETOR", carregando }}>
      {children}
    </UserContext.Provider>
  );
}

export function useUser(): UserContextValue {
  return useContext(UserContext);
}
