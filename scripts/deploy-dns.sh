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
: "${UPSTREAM_DNS:?Set UPSTREAM_DNS in .env}"
LAN_SUBNET="${LAN_SUBNET:-192.168.0.0/16}"

actual_ip="$(hostname -I | tr ' ' '\n' | grep -Fx "$LANTERN_CORE_IP" || true)"
if [[ -z "$actual_ip" ]]; then
  echo "Configured LANTERN_CORE_IP=$LANTERN_CORE_IP is not assigned to this VM." >&2
  echo "Current addresses: $(hostname -I)" >&2
  exit 1
fi

install -d -m 0700 secrets
if [[ ! -s secrets/pihole_web_password ]]; then
  umask 077
  openssl rand -base64 32 > secrets/pihole_web_password
  echo 'Generated secrets/pihole_web_password (value not printed).'
fi

if ss -H -lntu | awk '{print $5}' | grep -Eq "^${LANTERN_CORE_IP//./\.}:53$"; then
  echo "$LANTERN_CORE_IP:53 is already occupied." >&2
  exit 1
fi

docker compose --env-file .env -f compose/compose.yaml up -d pihole

for attempt in {1..30}; do
  if dig +short +time=2 +tries=1 "@$LANTERN_CORE_IP" lantern-core.home.arpa | grep -q .; then
    break
  fi
  if (( attempt == 30 )); then
    docker compose --env-file .env -f compose/compose.yaml logs --tail=100 pihole >&2
    echo 'Pi-hole did not become ready; firewall was not opened.' >&2
    exit 1
  fi
  sleep 2
done

ufw allow from "$LAN_SUBNET" to any port 53 proto tcp comment 'Lantern DNS TCP from private LAN'
ufw allow from "$LAN_SUBNET" to any port 53 proto udp comment 'Lantern DNS UDP from private LAN'

./scripts/test-dns.sh
echo 'Pi-hole DNS is healthy. Client DNS settings have not been changed.'
