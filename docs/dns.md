# Phase 3: internal DNS

Lantern uses Pi-hole Docker release `2026.07.2`, pinned in `.env.example` and
Compose. It publishes TCP and UDP port 53 only on the VM's current LAN address;
the web interface stays on the private Docker network and is reached through
Caddy at `http://dns.home.arpa/admin/` in Phase 4.

Pi-hole forwards non-local queries to the current hotspot gateway
`192.168.202.188`. Declarative local records resolve Lantern Core and
browser-facing services to the VM, and Windows-hosted services to Windows.

## Verified deployment

Deployed on 2026-07-12 at `192.168.215.253`. The guarded deployment passed:

- Compose and Caddy static validation;
- local records for Lantern Core, Windows, dashboard, status, and DNS;
- upstream resolution for `example.com`;
- direct Windows `nslookup` queries to Pi-hole;
- UFW rules for TCP and UDP port 53 from private `192.168.0.0/16` clients only.

No client or hotspot DNS configuration was changed during deployment. A
container restart test remains before Phase 3 is marked complete.

## Deploy safely

On Lantern Core, update the transferred repository first, then:

```sh
cd /opt/lantern
cp .env.example .env
# Confirm LANTERN_CORE_IP matches `hostname -I`.
make validate
sudo make deploy-dns
```

The deployment script generates an untracked Pi-hole web password, refuses a
stale VM address or occupied DNS port, starts only Pi-hole, tests local and
Internet resolution, and opens UFW port 53 only after the service answers.

## Single-client trial

Do not change hotspot/router DNS. Configure one client manually to use the
current Lantern Core address, then test:

```sh
nslookup windows.home.arpa 192.168.202.253
nslookup dashboard.home.arpa 192.168.202.253
nslookup example.com 192.168.202.253
```

Because the hotspot changes the VM lease, re-run `hostname -I` after every
restart. If it changes, update `.env`, inventory, and records, then reconcile
Pi-hole before using it as client DNS.

## Recovery

If Pi-hole or the VM is unavailable, restore the client's DNS server to
`192.168.202.188` (the hotspot gateway). No router-wide DNS change is part of
this phase.
