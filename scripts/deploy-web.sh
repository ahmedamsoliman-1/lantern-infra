#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

[[ -f .env ]] || { echo 'Missing .env; run make bootstrap and review it.' >&2; exit 1; }
set -a
# shellcheck disable=SC1091
source .env
set +a

: "${LANTERN_CORE_IP:?Set LANTERN_CORE_IP in .env}"
: "${WINDOWS_LAN_IP:?Set WINDOWS_LAN_IP in .env}"
LAN_SUBNET="${LAN_SUBNET:-192.168.0.0/16}"

if ! hostname -I | tr ' ' '\n' | grep -Fxq "$LANTERN_CORE_IP"; then
  echo "Configured LANTERN_CORE_IP=$LANTERN_CORE_IP is not assigned to this VM." >&2
  echo "Current addresses: $(hostname -I)" >&2
  exit 1
fi

if ! curl --fail --silent --show-error --max-time 10 \
  --output /dev/null "http://$WINDOWS_LAN_IP:2283/"; then
  echo "Immich is not reachable from Lantern Core at $WINDOWS_LAN_IP:2283." >&2
  exit 1
fi
echo "PASS: Immich backend is reachable at $WINDOWS_LAN_IP:2283"

existing_caddy="$(docker compose --env-file .env -f compose/compose.yaml ps -q caddy)"
if ss -H -lnt | awk '{print $4}' | grep -Eq "^(${LANTERN_CORE_IP//./\.}|0\.0\.0\.0|\[::\]):80$" \
  && [[ -z "$existing_caddy" ]]; then
  echo "$LANTERN_CORE_IP:80 is already occupied." >&2
  exit 1
fi

docker compose --env-file .env -f compose/compose.yaml up -d \
  homepage uptime-kuma caddy

check_route() {
  local hostname="$1"
  local path="${2:-/}"
  for attempt in {1..30}; do
    if curl --fail --silent --show-error --max-time 5 --output /dev/null \
      --resolve "$hostname:80:$LANTERN_CORE_IP" "http://$hostname$path"; then
      printf 'PASS: http://%s%s\n' "$hostname" "$path"
      return 0
    fi
    sleep 2
  done
  printf 'FAIL: http://%s%s\n' "$hostname" "$path" >&2
  return 1
}

failed=0
check_route dashboard.home.arpa / || failed=1
check_route status.home.arpa / || failed=1
check_route dns.home.arpa /admin/ || failed=1
check_route photos.home.arpa / || failed=1
check_route "$LANTERN_CORE_IP" / || failed=1

if (( failed )); then
  docker compose --env-file .env -f compose/compose.yaml logs --tail=150 \
    caddy homepage uptime-kuma >&2
  echo 'One or more routes failed; UFW port 80 was not opened.' >&2
  exit 1
fi

ufw allow from "$LAN_SUBNET" to any port 80 proto tcp comment 'Lantern HTTP from private LAN'

docker compose --env-file .env -f compose/compose.yaml ps \
  caddy homepage uptime-kuma
echo "Dashboard is available immediately at http://$LANTERN_CORE_IP"
echo 'Friendly names require the client to query Lantern DNS.'
