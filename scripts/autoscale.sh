#!/usr/bin/env bash
# =============================================================================
# autoscale.sh — Docker Swarm horizontal autoscaler for the web service
#
# Monitors CPU utilisation of vote_web tasks and adjusts replica count
# automatically:
#   - If avg CPU > SCALE_UP_THRESHOLD   → add one replica (up to MAX_REPLICAS)
#   - If avg CPU < SCALE_DOWN_THRESHOLD → remove one replica (down to MIN_REPLICAS)
#   - Otherwise keep current count
#
# Usage (run as a daemon, e.g. via systemd or cron every 30 seconds):
#   ./scripts/autoscale.sh
#
# Cron example (every minute):
#   * * * * * /opt/vote/scripts/autoscale.sh >> /var/log/vote-autoscale.log 2>&1
# =============================================================================
set -euo pipefail

SERVICE_NAME="${AUTOSCALE_SERVICE:-vote_web}"
MIN_REPLICAS="${MIN_REPLICAS:-2}"
MAX_REPLICAS="${MAX_REPLICAS:-8}"
SCALE_UP_THRESHOLD="${SCALE_UP_THRESHOLD:-70}"    # percent CPU
SCALE_DOWN_THRESHOLD="${SCALE_DOWN_THRESHOLD:-20}" # percent CPU
COOLDOWN_SECONDS="${COOLDOWN_SECONDS:-120}"
COOLDOWN_FILE="/tmp/autoscale_cooldown_${SERVICE_NAME}"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

# ---- Cooldown check --------------------------------------------------------
if [[ -f "$COOLDOWN_FILE" ]]; then
  last_scale=$(cat "$COOLDOWN_FILE")
  now=$(date +%s)
  elapsed=$(( now - last_scale ))
  if (( elapsed < COOLDOWN_SECONDS )); then
    log "Cooldown active (${elapsed}s / ${COOLDOWN_SECONDS}s). Skipping."
    exit 0
  fi
fi

# ---- Current replica count -------------------------------------------------
current_replicas=$(docker service inspect "$SERVICE_NAME" \
  --format '{{.Spec.Mode.Replicated.Replicas}}' 2>/dev/null || echo "0")

if [[ "$current_replicas" -eq 0 ]]; then
  log "Service $SERVICE_NAME not found or has 0 replicas. Skipping."
  exit 0
fi

# ---- Collect CPU usage from all tasks ------------------------------------
# docker stats outputs CPU% for each running task of the service.
mapfile -t cpu_values < <(
  docker stats --no-stream --format "{{.Name}} {{.CPUPerc}}" \
  | grep "$SERVICE_NAME" \
  | awk '{gsub(/%/,"",$2); print $2}'
)

if [[ ${#cpu_values[@]} -eq 0 ]]; then
  log "No running tasks found for $SERVICE_NAME. Skipping."
  exit 0
fi

# Calculate average CPU across all replicas
total_cpu=0
for cpu in "${cpu_values[@]}"; do
  total_cpu=$(echo "$total_cpu + $cpu" | bc)
done
avg_cpu=$(echo "scale=1; $total_cpu / ${#cpu_values[@]}" | bc)

log "Service: $SERVICE_NAME | Replicas: $current_replicas | Avg CPU: ${avg_cpu}%"

# ---- Scaling decision ------------------------------------------------------
if (( $(echo "$avg_cpu > $SCALE_UP_THRESHOLD" | bc -l) )); then
  new_replicas=$(( current_replicas + 1 ))
  if (( new_replicas > MAX_REPLICAS )); then
    log "Already at max replicas ($MAX_REPLICAS). No scale-up."
    exit 0
  fi
  log "SCALE UP: ${current_replicas} → ${new_replicas} (CPU ${avg_cpu}% > ${SCALE_UP_THRESHOLD}%)"
  docker service scale "${SERVICE_NAME}=${new_replicas}"
  date +%s > "$COOLDOWN_FILE"

elif (( $(echo "$avg_cpu < $SCALE_DOWN_THRESHOLD" | bc -l) )); then
  new_replicas=$(( current_replicas - 1 ))
  if (( new_replicas < MIN_REPLICAS )); then
    log "Already at min replicas ($MIN_REPLICAS). No scale-down."
    exit 0
  fi
  log "SCALE DOWN: ${current_replicas} → ${new_replicas} (CPU ${avg_cpu}% < ${SCALE_DOWN_THRESHOLD}%)"
  docker service scale "${SERVICE_NAME}=${new_replicas}"
  date +%s > "$COOLDOWN_FILE"

else
  log "CPU within thresholds [${SCALE_DOWN_THRESHOLD}%–${SCALE_UP_THRESHOLD}%]. No change."
fi
