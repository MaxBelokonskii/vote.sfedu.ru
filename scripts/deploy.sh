#!/usr/bin/env bash
# =============================================================================
# deploy.sh — Rolling deploy helper for Docker Swarm
#
# Usage:
#   ./scripts/deploy.sh [IMAGE_TAG]
#
# Examples:
#   ./scripts/deploy.sh                  # uses latest git SHA as tag
#   ./scripts/deploy.sh v1.2.3           # specific tag
#   IMAGE_TAG=sha-abc123 ./scripts/deploy.sh
# =============================================================================
set -euo pipefail

APP_NAME="${APP_NAME:-vote}"
REGISTRY="${REGISTRY:-}"  # e.g. registry.example.com/vote
IMAGE_TAG="${1:-${IMAGE_TAG:-$(git rev-parse --short HEAD)}}"
IMAGE="${REGISTRY:+${REGISTRY}/}vote-app:${IMAGE_TAG}"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

log "=== Deploying ${IMAGE} ==="

# 1. Build and push image (skip if CI already did it)
if [[ "${SKIP_BUILD:-false}" != "true" ]]; then
  log "Building image..."
  docker build -t "$IMAGE" .
  if [[ -n "$REGISTRY" ]]; then
    log "Pushing image to registry..."
    docker push "$IMAGE"
  fi
fi

# 2. Run database migrations as a one-shot service
log "Running database migrations..."
docker run --rm \
  --network "${APP_NAME}_internal" \
  --env-file .env.production \
  -e DATABASE_URL="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB}" \
  -e RAILS_ENV=production \
  "$IMAGE" \
  bundle exec rails db:migrate

log "Migrations complete."

# 3. Rolling update of web replicas (one at a time)
log "Updating web service (rolling)..."
docker service update \
  --image "$IMAGE" \
  --update-parallelism 1 \
  --update-delay 15s \
  --update-order start-first \
  --update-failure-action rollback \
  "${APP_NAME}_web"

# 4. Update worker service
log "Updating worker service..."
docker service update \
  --image "$IMAGE" \
  "${APP_NAME}_worker"

log "=== Deploy complete: ${IMAGE} ==="
log "Replicas: $(docker service ls --filter name=${APP_NAME}_web --format '{{.Replicas}}')"
