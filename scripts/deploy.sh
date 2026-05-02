#!/usr/bin/env bash
# =============================================================================
# deploy.sh — Deploy CEPAC para Azure Container Apps
#
# Uso:
#   ./scripts/deploy.sh            → deploy da HEAD atual (git sha)
#   ./scripts/deploy.sh sha-abc1234 → deploy de uma tag específica do ACR
#   ./scripts/deploy.sh --status   → mostra o que está rodando em cada app
#
# Pré-requisitos: az CLI autenticado (az login)
# =============================================================================

set -euo pipefail

RG="rg_spurbanismo_cepac"
REGISTRY="cepacregistry.azurecr.io"
APPS=("cepac-api" "cepac-portal" "cepac-dashboard")
REPOS=("cepac-api" "cepac-portal" "cepac-dashboard")

# ---------------------------------------------------------------------------
# --status: mostra o que está rodando vs o que existe no ACR
# ---------------------------------------------------------------------------
if [[ "${1:-}" == "--status" ]]; then
  echo ""
  echo "════════════════════════════════════════════════════════"
  echo "  CEPAC — Estado atual dos Container Apps"
  echo "════════════════════════════════════════════════════════"
  for i in "${!APPS[@]}"; do
    app="${APPS[$i]}"
    repo="${REPOS[$i]}"
    running=$(az containerapp show --name "$app" --resource-group "$RG" \
      --query "properties.template.containers[0].image" --output tsv 2>/dev/null)
    sha_running=$(echo "$running" | grep -oP 'sha-\w+' || echo "?")
    latest_acr=$(az acr repository show-tags --name cepacregistry \
      --repository "$repo" --orderby time_desc --top 1 --output tsv 2>/dev/null)
    status_icon="✅"
    [[ "$sha_running" != "$latest_acr" ]] && status_icon="⚠️  DESATUALIZADO"
    printf "  %-20s rodando: %-14s  acr-latest: %-14s  %s\n" \
      "$app" "$sha_running" "$latest_acr" "$status_icon"
  done
  echo ""
  exit 0
fi

# ---------------------------------------------------------------------------
# Determina a tag de deploy
# ---------------------------------------------------------------------------
if [[ -n "${1:-}" ]]; then
  TAG="$1"
else
  # Usa o sha do commit atual no repositório local
  SHORT_SHA=$(git rev-parse --short HEAD)
  TAG="sha-${SHORT_SHA}"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "  CEPAC — Deploy: $TAG"
echo "════════════════════════════════════════════════════════"

# Verifica se a tag existe no ACR antes de tentar deployar
for i in "${!APPS[@]}"; do
  repo="${REPOS[$i]}"
  if ! az acr repository show-tags --name cepacregistry --repository "$repo" \
      --output tsv 2>/dev/null | grep -q "^${TAG}$"; then
    echo ""
    echo "❌ ERRO: tag '$TAG' não encontrada no ACR para $repo"
    echo "   Verifique se o CI já fez o push desta imagem."
    echo "   Tags disponíveis:"
    az acr repository show-tags --name cepacregistry --repository "$repo" \
      --orderby time_desc --top 5 --output tsv 2>/dev/null | sed 's/^/     /'
    exit 1
  fi
done

# ---------------------------------------------------------------------------
# Atualiza os 3 apps em paralelo
# ---------------------------------------------------------------------------
echo ""
pids=()
for i in "${!APPS[@]}"; do
  app="${APPS[$i]}"
  repo="${REPOS[$i]}"
  image="${REGISTRY}/${repo}:${TAG}"
  echo "  → $app  ($image)"
  az containerapp update --name "$app" --resource-group "$RG" \
    --image "$image" --output none &
  pids+=($!)
done

# Aguarda todos terminarem
failed=0
for pid in "${pids[@]}"; do
  if ! wait "$pid"; then
    failed=1
  fi
done

if [[ $failed -eq 1 ]]; then
  echo ""
  echo "❌ Um ou mais updates falharam. Verifique com: az containerapp revision list"
  exit 1
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "  Verificando saúde das revisões…"
echo "════════════════════════════════════════════════════════"
sleep 15

all_healthy=true
for app in "${APPS[@]}"; do
  revision=$(az containerapp show --name "$app" --resource-group "$RG" \
    --query "properties.latestRevisionName" --output tsv 2>/dev/null)
  health=$(az containerapp revision show --name "$app" --resource-group "$RG" \
    --revision "$revision" --query "properties.healthState" --output tsv 2>/dev/null)
  icon="✅"
  [[ "$health" != "Healthy" ]] && { icon="⚠️ "; all_healthy=false; }
  printf "  %-22s  %-30s  %s %s\n" "$app" "$revision" "$icon" "$health"
done

echo ""
if $all_healthy; then
  echo "  Deploy concluído com sucesso!"
else
  echo "  ⚠️  Algumas revisões ainda não estão Healthy — aguarde mais alguns segundos"
  echo "  e verifique com: ./scripts/deploy.sh --status"
fi
echo ""
