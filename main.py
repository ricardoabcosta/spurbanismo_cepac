"""
Entrypoint uvicorn para o sistema CEPAC.

Uso:
    uvicorn main:app --host 0.0.0.0 --port 8000 --reload

Ou via Python diretamente (desenvolvimento):
    python main.py
"""
import uvicorn

from src.api.app import app  # noqa: F401  — exporta `app` para uvicorn

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info",
    )
