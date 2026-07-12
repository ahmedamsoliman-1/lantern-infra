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
if ! hostname -I | tr ' ' '\n' | grep -Fxq "$LANTERN_CORE_IP"; then
  echo "Configured LANTERN_CORE_IP=$LANTERN_CORE_IP is not assigned to this VM." >&2
  echo "Current addresses: $(hostname -I)" >&2
  exit 1
fi

COMPOSE=(docker compose --env-file .env -f compose/compose.yaml)
"${COMPOSE[@]}" up -d --force-recreate caddy

certificate_dir="$ROOT/state/certificates"
certificate_path="$certificate_dir/lantern-root-ca.crt"
install -d -m 0755 "$certificate_dir"

for attempt in {1..30}; do
  if "${COMPOSE[@]}" cp \
    caddy:/data/caddy/pki/authorities/local/root.crt "$certificate_path" \
    >/dev/null 2>&1; then
    break
  fi
  if (( attempt == 30 )); then
    "${COMPOSE[@]}" logs --tail=150 caddy >&2
    echo 'Caddy did not generate its local root CA.' >&2
    exit 1
  fi
  sleep 2
done

chmod 0644 "$certificate_path"
if [[ -n "${SUDO_USER:-}" ]]; then
  chown "$SUDO_USER":"$SUDO_USER" "$certificate_path"
fi

check_https() {
  local hostname="$1"
  local path="${2:-/}"
  for attempt in {1..30}; do
    if curl --fail --silent --show-error --max-time 5 --output /dev/null \
      --cacert "$certificate_path" \
      --resolve "$hostname:443:$LANTERN_CORE_IP" \
      "https://$hostname$path"; then
      printf 'PASS: https://%s%s\n' "$hostname" "$path"
      return 0
    fi
    sleep 2
  done
  printf 'FAIL: https://%s%s\n' "$hostname" "$path" >&2
  return 1
}

failed=0
check_https dashboard.home.arpa / || failed=1
check_https status.home.arpa / || failed=1
check_https dns.home.arpa /admin/ || failed=1
check_https photos.home.arpa / || failed=1

redirect_code="$(curl --silent --output /dev/null --write-out '%{http_code}' \
  --resolve "dashboard.home.arpa:80:$LANTERN_CORE_IP" \
  http://dashboard.home.arpa/)"
if [[ ! "$redirect_code" =~ ^30[1278]$ ]]; then
  echo "FAIL: HTTP redirect returned $redirect_code" >&2
  failed=1
else
  echo "PASS: HTTP redirects to HTTPS ($redirect_code)"
fi

if (( failed )); then
  "${COMPOSE[@]}" logs --tail=150 caddy >&2
  echo 'HTTPS validation failed; UFW port 443 was not opened.' >&2
  exit 1
fi

ufw allow from 192.168.215.0/24 to "$LANTERN_CORE_IP" port 443 proto tcp comment 'Lantern HTTPS from LAN'

echo "Root CA certificate: $certificate_path"
echo 'Root CA SHA-256:'
openssl x509 -in "$certificate_path" -outform DER | sha256sum | awk '{print $1}'
echo 'HTTPS is healthy. Install only this public root certificate on trusted clients.'
