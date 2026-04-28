import { defineConfig, loadEnv } from "vite";
import react from "@vitejs/plugin-react";

// https://vitejs.dev/config/
export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), "VITE_");
  const apiBase = env.VITE_API_BASE_URL ?? "http://localhost:8000";

  return {
    plugins: [react()],
    build: {
      target: "esnext",
    },
    server: {
      port: 3001,
      proxy: {
        "/dashboard": {
          target: apiBase,
          changeOrigin: true,
        },
      },
    },
  };
});
