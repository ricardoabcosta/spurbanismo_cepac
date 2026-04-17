#!/usr/bin/env bash
set -euo pipefail

COMPOSE="docker compose -f infra/docker-compose.yml"

echo "Iniciando CEPAC..."
$COMPOSE up --build -d

echo ""
echo "Aguardando API ficar saudável..."
until docker inspect --format='{{.State.Health.Status}}' cepac_api 2>/dev/null | grep -q "healthy"; do
  sleep 2
done

echo ""
echo "Sistema disponível:"
echo "  API       → http://localhost:8000/docs"
echo "  Portal    → http://localhost:3000"
echo "  Dashboard → http://localhost:3001"
echo ""
echo "Logs: docker compose -f infra/docker-compose.yml logs -f"
