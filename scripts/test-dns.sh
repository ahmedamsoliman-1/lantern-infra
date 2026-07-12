#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -f "$ROOT/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$ROOT/.env"
  set +a
fi
: "${LANTERN_CORE_IP:?Set LANTERN_CORE_IP or source .env first}"
for name in lantern-core.home.arpa windows.home.arpa dashboard.home.arpa status.home.arpa dns.home.arpa; do
  if command -v dig >/dev/null; then
    answer="$(dig +short +time=2 +tries=1 "@$LANTERN_CORE_IP" "$name")"
    [[ -n "$answer" ]] || { echo "FAIL: no DNS answer for $name" >&2; exit 1; }
    printf 'PASS: %s -> %s\n' "$name" "$answer"
  else
    nslookup "$name" "$LANTERN_CORE_IP"
  fi
done

if command -v dig >/dev/null; then
  internet_answer="$(dig +short +time=3 +tries=1 "@$LANTERN_CORE_IP" example.com A)"
  [[ -n "$internet_answer" ]] || { echo 'FAIL: upstream Internet DNS failed' >&2; exit 1; }
  printf 'PASS: upstream DNS -> %s\n' "$internet_answer"
fi
