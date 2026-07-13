#!/usr/bin/env bash
set -Eeuo pipefail

if [[ ${EUID} -ne 0 ]]; then
  echo 'Run with sudo: sudo ./scripts/bootstrap-core.sh' >&2
  exit 1
fi

LAN_SUBNET="${LAN_SUBNET:-192.168.0.0/16}"
OPERATOR_USER="${SUDO_USER:-ahmed}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Archives created on Windows can broaden mode bits. Normalize the deployed
# repository without making configuration files executable.
find "$ROOT" -type d -exec chmod 0755 {} +
find "$ROOT" -type f -exec chmod 0644 {} +
find "$ROOT/scripts" -type f -name '*.sh' -exec chmod 0755 {} +

hostnamectl set-hostname lantern-core
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  ca-certificates curl dnsutils docker.io docker-compose-v2 git make \
  openssh-server chrony unattended-upgrades ufw

systemctl enable --now docker ssh chrony
usermod -aG docker "$OPERATOR_USER"

ufw default deny incoming
ufw default allow outgoing
ufw allow from "$LAN_SUBNET" to any port 22 proto tcp comment 'Lantern SSH from LAN'
ufw --force enable

install -d -o "$OPERATOR_USER" -g "$OPERATOR_USER" /opt/lantern
install -d -m 0750 /srv/lantern

cat <<EOF
Lantern Core bootstrap complete.

Next:
  1. Sign out and back in so Docker group membership applies.
  2. Clone this repository into /opt/lantern.
  3. Record the DHCP address: hostname -I
  4. Run: make validate

Only SSH is allowed through UFW. DNS/HTTP/HTTPS rules are added in later phases.
EOF
