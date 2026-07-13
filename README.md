# Lantern Infrastructure

Lantern provides friendly local names, reverse proxying, service discovery,
monitoring, and eventually LAN-only remote desktop for services hosted on a
Windows machine. The infrastructure runs in a dedicated Ubuntu Server VM on
Hyper-V and remains private to the trusted LAN.

## Current status

- Phase 0 host discovery: complete
- Phase 1 repository bootstrap: complete
- Phase 2 VM: operational; root filesystem expanded to 37 GiB
- Phase 3 DNS: Pi-hole deployed and verified with direct Windows queries
- Phase 4 HTTP: Caddy, Homepage, Uptime Kuma, Pi-hole UI, and Immich routes verified
- Phase 5 HTTPS: deployed; named routes work, Windows browser trust remains unresolved
- Phase 6 monitoring: complete; six monitors and outage persistence verified
- Phase 7 remote desktop: RustDesk server operational; client acceptance pending
- Network addresses: hotspot DHCP; current Lantern Core lease is provisional

Start with [the architecture](docs/architecture.md), then follow
[installation](docs/installation.md). Current VM acceptance status is recorded
in [Phase 2 status](docs/phase2-status.md). The original scope and phase plan
remain in `initial_plan.md`.

## Operator commands

Run these on the future Ubuntu `lantern-core` VM:

```sh
cp .env.example .env
make validate
make deploy
make status
make test
```

`make validate` is safe to run before deployment. It checks repository policy,
inventory structure, Compose rendering, and the Caddy configuration.

## Security boundary

Lantern version one is LAN-only. Do not add router port forwarding. Never
commit `.env`, credentials, local CA material, runtime databases, RustDesk
keys, or backups.
