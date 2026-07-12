# Lantern Infrastructure

Lantern provides friendly local names, reverse proxying, service discovery,
monitoring, and eventually LAN-only remote desktop for services hosted on a
Windows machine. The infrastructure runs in a dedicated Ubuntu Server VM on
Hyper-V and remains private to the trusted LAN.

## Current status

- Phase 0 host discovery: complete
- Phase 1 repository bootstrap: complete
- Phase 2 VM: Ubuntu installed; guest bootstrap and SSH acceptance checks pending
- Services: not deployed
- Network addresses: provisional until discovery is repeated on the permanent
  home network

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
