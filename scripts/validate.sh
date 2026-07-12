#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

failures=0
pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1" >&2; failures=$((failures + 1)); }

for command in docker awk grep sed; do
  command -v "$command" >/dev/null 2>&1 || fail "required command missing: $command"
done

for file in \
  compose/compose.yaml services/caddy/Caddyfile \
  inventory/devices.yaml inventory/services.yaml; do
  [[ -s "$file" ]] || fail "required file is missing or empty: $file"
done

if grep -RIn $'\t' --include='*.yaml' --include='*.yml' . >/dev/null; then
  fail "YAML contains tab indentation"
else
  pass "YAML uses spaces"
fi

if grep -RInE 'image:[[:space:]]*[^#[:space:]]+:latest([[:space:]]|$)' \
  compose services >/dev/null; then
  fail "floating latest image tag found"
else
  pass "container image tags are pinned"
fi

tracked_sensitive="$(git ls-files 2>/dev/null | grep -E '(^|/)\.env$|(^|/)secrets/|\.(key|pem|pfx|age|db|sqlite[0-9-]*)$' || true)"
if [[ -n "$tracked_sensitive" ]]; then
  printf '%s\n' "$tracked_sensitive" >&2
  fail "sensitive or runtime files are tracked"
else
  pass "no sensitive/runtime filenames are tracked"
fi

secret_hits="$(grep -RInE --exclude='.env.example' --exclude='validate.sh' \
  '(password|passwd|token|secret|private_key)[[:space:]]*[:=][[:space:]]*[^<{[:space:]][^[:space:]]+' \
  compose docs inventory services scripts 2>/dev/null || true)"
if [[ -n "$secret_hits" ]]; then
  printf '%s\n' "$secret_hits" >&2
  fail "possible committed secret assignment found"
else
  pass "no obvious secret assignments found"
fi

domains="$(grep -RhoE '[a-z0-9-]+\.home\.arpa' services/caddy/Caddyfile | sort)"
duplicates="$(printf '%s\n' "$domains" | uniq -d)"
if [[ -n "$duplicates" ]]; then
  printf '%s\n' "$duplicates" >&2
  fail "duplicate Caddy domains found"
else
  pass "Caddy domains are unique"
fi

bad_ips=0
while IFS= read -r ip; do
  [[ -z "$ip" ]] && continue
  IFS=. read -r a b c d <<< "$ip"
  if (( a > 255 || b > 255 || c > 255 || d > 255 )); then
    printf 'Invalid IPv4 address: %s\n' "$ip" >&2
    bad_ips=1
  fi
done < <(grep -RhoE '([0-9]{1,3}\.){3}[0-9]{1,3}' inventory services/caddy/Caddyfile | sort -u)
if (( bad_ips )); then fail "invalid IPv4 address found"; else pass "IPv4 syntax is valid"; fi

if docker compose -f compose/compose.yaml config --quiet; then
  pass "Docker Compose renders"
else
  fail "Docker Compose configuration is invalid"
fi

if docker run --rm \
  --env WINDOWS_LAN_IP=127.0.0.1 \
  --volume "$ROOT/services/caddy/Caddyfile:/etc/caddy/Caddyfile:ro" \
  "${CADDY_IMAGE:-caddy:2.11.4}" \
  caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile; then
  pass "Caddy configuration validates"
else
  fail "Caddy configuration is invalid"
fi

if (( failures > 0 )); then
  printf '\nValidation failed with %d error(s).\n' "$failures" >&2
  exit 1
fi
printf '\nLantern validation passed.\n'
