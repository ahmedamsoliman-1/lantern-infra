#!/usr/bin/env bash
set -Eeuo pipefail

if [[ ${EUID} -ne 0 ]]; then
  echo 'Run with sudo and provide the Windows LAN address:' >&2
  echo '  sudo make reconcile-network WINDOWS_IP=192.168.x.x' >&2
  exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
[[ -f .env ]] || { echo 'Missing /opt/lantern/.env.' >&2; exit 1; }

windows_ip="${1:-}"

is_ipv4() {
  local ip="$1" octet
  local -a octets
  [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1
  IFS=. read -r -a octets <<<"$ip"
  for octet in "${octets[@]}"; do
    (( octet >= 0 && octet <= 255 )) || return 1
  done
}

is_private_192_168() {
  [[ "$1" == 192.168.* ]]
}

if ! is_ipv4 "$windows_ip" || ! is_private_192_168 "$windows_ip"; then
  echo "Windows address must be a private 192.168.x.x IPv4 address: $windows_ip" >&2
  exit 1
fi

default_route="$(ip -4 route show default | head -n1)"
gateway="$(awk '{print $3}' <<<"$default_route")"
interface="$(awk '{print $5}' <<<"$default_route")"
core_ip="$(ip -4 -o addr show dev "$interface" scope global | awk 'NR==1 {split($4,a,"/"); print a[1]}')"

if ! is_ipv4 "$core_ip" || ! is_private_192_168 "$core_ip"; then
  echo "Lantern Core has no supported private address on $interface: $core_ip" >&2
  exit 1
fi
if ! is_ipv4 "$gateway" || ! is_private_192_168 "$gateway"; then
  echo "Default gateway is not a supported private address: $gateway" >&2
  exit 1
fi

core_prefix="${core_ip%.*}"
if [[ "${windows_ip%.*}" != "$core_prefix" || "${gateway%.*}" != "$core_prefix" ]]; then
  echo 'Lantern Core, Windows, and the gateway are not on the same /24.' >&2
  printf 'Core=%s Windows=%s Gateway=%s\n' "$core_ip" "$windows_ip" "$gateway" >&2
  exit 1
fi

set_env() {
  local key="$1" value="$2"
  if grep -qE "^${key}=" .env; then
    sed -i "s|^${key}=.*|${key}=${value}|" .env
  else
    printf '%s=%s\n' "$key" "$value" >> .env
  fi
}

rustdesk_deployed=0
if [[ -f services/rustdesk/compose.yaml ]] \
  && [[ -n "$(docker compose --env-file .env -f services/rustdesk/compose.yaml ps -aq 2>/dev/null || true)" ]]; then
  rustdesk_deployed=1
fi

set_env LANTERN_CORE_IP "$core_ip"
set_env WINDOWS_LAN_IP "$windows_ip"
set_env UPSTREAM_DNS "$gateway"
set_env LAN_SUBNET '192.168.0.0/16'

echo 'Reconciled network values:'
grep -E '^(LANTERN_CORE_IP|WINDOWS_LAN_IP|UPSTREAM_DNS|LAN_SUBNET)=' .env

CORE_COMPOSE=(docker compose --env-file .env -f compose/compose.yaml)
"${CORE_COMPOSE[@]}" up -d --force-recreate

if (( rustdesk_deployed )); then
  RUSTDESK_COMPOSE=(docker compose --env-file .env -f services/rustdesk/compose.yaml)
  "${RUSTDESK_COMPOSE[@]}" up -d --force-recreate
fi

ufw allow from 192.168.0.0/16 to any port 22 proto tcp comment 'Lantern SSH from private LAN'
ufw allow from 192.168.0.0/16 to any port 53 proto tcp comment 'Lantern DNS TCP from private LAN'
ufw allow from 192.168.0.0/16 to any port 53 proto udp comment 'Lantern DNS UDP from private LAN'
ufw allow from 192.168.0.0/16 to any port 80 proto tcp comment 'Lantern HTTP from private LAN'
ufw allow from 192.168.0.0/16 to any port 443 proto tcp comment 'Lantern HTTPS from private LAN'
if (( rustdesk_deployed )); then
  ufw allow from 192.168.0.0/16 to any port 21115:21117 proto tcp comment 'Lantern RustDesk TCP from private LAN'
  ufw allow from 192.168.0.0/16 to any port 21116 proto udp comment 'Lantern RustDesk UDP from private LAN'
fi

for attempt in {1..30}; do
  if dig +short +time=2 +tries=1 "@$core_ip" dashboard.home.arpa | grep -Fxq "$core_ip"; then
    break
  fi
  if (( attempt == 30 )); then
    "${CORE_COMPOSE[@]}" logs --tail=150 pihole caddy >&2
    echo 'Services were recreated, but DNS readiness verification failed.' >&2
    exit 1
  fi
  sleep 2
done

./scripts/test-dns.sh
"${CORE_COMPOSE[@]}" ps
if (( rustdesk_deployed )); then
  "${RUSTDESK_COMPOSE[@]}" ps
fi

cat <<EOF

Network reconciliation passed.
Use Lantern DNS $core_ip on Windows only after direct nslookup tests pass.
Fallback DNS is the current gateway $gateway.
EOF
