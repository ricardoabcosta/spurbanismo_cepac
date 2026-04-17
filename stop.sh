#!/usr/bin/env bash
set -euo pipefail

COMPOSE="docker compose -f infra/docker-compose.yml"

echo "Parando CEPAC..."
$COMPOSE down

echo "Sistema encerrado."
