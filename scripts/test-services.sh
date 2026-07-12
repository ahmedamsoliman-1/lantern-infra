#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CA_CERT="$ROOT/state/certificates/lantern-root-ca.crt"
[[ -s "$CA_CERT" ]] || { echo "Missing Lantern root CA: $CA_CERT" >&2; exit 1; }

for url in https://dashboard.home.arpa https://status.home.arpa https://dns.home.arpa/admin/ https://photos.home.arpa; do
  curl --fail --show-error --silent --location --cacert "$CA_CERT" --output /dev/null "$url"
  printf 'PASS: %s\n' "$url"
done
