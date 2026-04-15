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

# Load .env.production into the calling shell so ${POSTGRES_USER} etc.
# are available when constructing DATABASE_URL below.
# --env-file in `docker run` only passes vars to the container, not here.
if [[ -f .env.production ]]; then
  # shellcheck disable=SC1091
  set -o allexport
  source .env.production
  set +o allexport
else
  log "ERROR: .env.production not found. Cannot construct DATABASE_URL."
  exit 1
fi

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

# Helper: run a one-shot Rails command in the app image connected to the DB.
run_rails() {
  docker run --rm \
    --network "${APP_NAME}_internal" \
    --env-file .env.production \
    -e DATABASE_URL="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB}" \
    -e RAILS_ENV=production \
    "$IMAGE" \
    "$@"
}

# 2. Run schema migrations
log "Running schema migrations (db:migrate)..."
run_rails bundle exec rails db:migrate

# 3. Run data migrations (data_migrate gem — documented in CLAUDE.md)
log "Running data migrations (db:migrate:data)..."
run_rails bundle exec rails db:migrate:data

log "Migrations complete."

# 4. Rolling update of web replicas (one at a time)
log "Updating web service (rolling)..."
docker service update \
  --image "$IMAGE" \
  --update-parallelism 1 \
  --update-delay 15s \
  --update-order start-first \
  --update-failure-action rollback \
  "${APP_NAME}_web"

# 5. Update worker service
log "Updating worker service..."
docker service update \
  --image "$IMAGE" \
  "${APP_NAME}_worker"

log "=== Deploy complete: ${IMAGE} ==="
log "Replicas: $(docker service ls --filter name=${APP_NAME}_web --format '{{.Replicas}}')"
