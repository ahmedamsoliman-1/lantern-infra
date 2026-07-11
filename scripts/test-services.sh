#!/usr/bin/env bash
set -Eeuo pipefail
for url in http://dashboard.home.arpa http://status.home.arpa http://photos.home.arpa; do
  curl --fail --show-error --silent --location --output /dev/null "$url"
  printf 'PASS: %s\n' "$url"
done

