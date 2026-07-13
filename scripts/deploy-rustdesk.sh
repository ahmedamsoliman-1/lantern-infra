#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

[[ -f .env ]] || { echo 'Missing .env; copy and review .env.example first.' >&2; exit 1; }
set -a
# shellcheck disable=SC1091
source .env
set +a

: "${LANTERN_CORE_IP:?Set LANTERN_CORE_IP in .env}"
LAN_SUBNET="${LAN_SUBNET:-192.168.0.0/16}"
COMPOSE=(docker compose --env-file .env -f services/rustdesk/compose.yaml)

if ! hostname -I | tr ' ' '\n' | grep -Fxq "$LANTERN_CORE_IP"; then
  echo "Configured LANTERN_CORE_IP=$LANTERN_CORE_IP is not assigned to this VM." >&2
  echo "Current addresses: $(hostname -I)" >&2
  exit 1
fi

existing_hbbs="$("${COMPOSE[@]}" ps -q hbbs)"
existing_hbbr="$("${COMPOSE[@]}" ps -q hbbr)"
if [[ -z "$existing_hbbs$existing_hbbr" ]] && \
  ss -H -lnt | awk '{print $4}' | grep -Eq ':(21115|21116|21117)$'; then
  echo 'A required RustDesk TCP port (21115-21117) is already occupied.' >&2
  exit 1
fi

install -d -m 0700 services/rustdesk/data
"${COMPOSE[@]}" up -d

ready=0
for attempt in {1..30}; do
  tcp_listeners="$(ss -H -lnt | awk '{print $4}')"
  udp_listeners="$(ss -H -lnu | awk '{print $4}')"
  if grep -Eq ':21115$' <<<"$tcp_listeners" \
    && grep -Eq ':21116$' <<<"$tcp_listeners" \
    && grep -Eq ':21117$' <<<"$tcp_listeners" \
    && grep -Eq ':21116$' <<<"$udp_listeners" \
    && [[ -s services/rustdesk/data/id_ed25519.pub ]]; then
    ready=1
    break
  fi
  sleep 2
done

if (( ! ready )); then
  "${COMPOSE[@]}" logs --tail=150 >&2
  echo 'RustDesk did not become ready; firewall ports were not opened.' >&2
  exit 1
fi

ufw allow from "$LAN_SUBNET" to any port 21115:21117 proto tcp comment 'Lantern RustDesk TCP from private LAN'
ufw allow from "$LAN_SUBNET" to any port 21116 proto udp comment 'Lantern RustDesk UDP from private LAN'

"${COMPOSE[@]}" ps
echo
echo "RustDesk ID server: $LANTERN_CORE_IP"
echo 'RustDesk public key (safe to copy into trusted clients):'
cat services/rustdesk/data/id_ed25519.pub
echo
echo 'No router port forwarding or web-client ports were enabled.'
