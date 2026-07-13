# Phase 6: monitoring

Status: accepted on 2026-07-13.

Uptime Kuma 2.3.2 stores monitor definitions and history in the persistent
`uptime_kuma_data` Docker volume. The UI is stateful, so this document is the
declarative record of the intended monitor set until a stable supported import
or provisioning API is adopted.

Use a 60-second heartbeat and 3 retries unless noted otherwise.

| Name | Type | Target | Expected |
| --- | --- | --- | --- |
| Lantern Dashboard | HTTP(s) | `http://homepage:3000` | HTTP 200–299 |
| Pi-hole UI | HTTP(s) | `http://pihole/admin/` | HTTP 200–399 |
| Immich | HTTP(s) | `http://192.168.102.40:2283` | HTTP 200–299 |
| Windows SSH | TCP Port | `192.168.102.40:22` | connection succeeds |
| Pi-hole DNS | TCP Port | `pihole:53` | DNS listener accepts connections |
| Caddy HTTPS | TCP Port | `caddy:443` | HTTPS listener accepts connections |

Create the monitors in the order shown. For HTTP monitors, leave the accepted
status-code range at its default unless the table explicitly permits redirects.
Use Docker service names for Caddy and Pi-hole because Kuma runs on the same
Compose network. Monitoring the VM's published LAN address from a sibling
container can fail at the Docker/UFW hairpin boundary even while LAN clients
reach the service normally. Exact DNS answers remain covered by
`scripts/test-dns.sh` and direct client `nslookup` checks.

Internal Docker URLs deliberately avoid bypassing certificate validation. Add
HTTPS content and certificate-expiry monitors only after the Lantern CA trust
issue is resolved for the monitoring container.

## Persistence test

After all monitors are green, deliberately stop Homepage from Lantern Core:

```sh
cd /opt/lantern
sudo docker compose --env-file .env -f compose/compose.yaml stop homepage
```

Confirm Kuma marks `Lantern Dashboard` down, then restore it:

```sh
sudo docker compose --env-file .env -f compose/compose.yaml start homepage
```

Confirm the monitor returns to green. Finally restart Kuma and verify monitors
and history persist:

```sh
sudo docker compose --env-file .env -f compose/compose.yaml restart uptime-kuma
```

The Kuma volume must be included in encrypted Phase 8 backups.

## Acceptance result

All six monitors reached green after the Caddy and Pi-hole listener checks were
changed to Docker-internal targets. The initial LAN-address checks produced
false failures because a sibling container could not traverse the host's
Docker/UFW hairpin path; normal LAN access remained healthy.

Homepage was deliberately stopped and Kuma detected the outage. Homepage then
returned to green after restoration. Restarting Uptime Kuma preserved all
monitor definitions and event history, satisfying the Phase 6 acceptance
criteria.

After any uplink change, edit the two Windows-target monitors to the current
`WINDOWS_LAN_IP`. Docker-internal monitors do not require changes.
