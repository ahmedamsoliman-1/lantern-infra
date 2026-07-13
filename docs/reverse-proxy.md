# Phase 4: HTTP reverse proxy

Caddy is Lantern's only browser-facing LAN entry point. Phase 4 deliberately
uses HTTP; internal TLS and trusted client certificates are Phase 5.

Routes:

| URL | Upstream |
| --- | --- |
| `http://dashboard.home.arpa` | Homepage on the Lantern Docker network |
| `http://status.home.arpa` | Uptime Kuma on the Lantern Docker network |
| `http://dns.home.arpa/admin/` | Pi-hole on the Lantern Docker network |
| `http://photos.home.arpa` | Immich on Windows at port 2283 |
| `http://<LANTERN_CORE_IP>` | HTTP-only Homepage fallback when client DNS is unavailable |

## Verified deployment

Deployed and verified on 2026-07-12. Caddy successfully reached Homepage,
Uptime Kuma, Pi-hole, and Windows-hosted Immich. The direct-IP Homepage fallback
also passed. UFW opened TCP port 80 from private `192.168.0.0/16` clients only after all route
checks completed. An initial Homepage `502` occurred during container startup;
the guarded retry passed once Homepage became ready.

## Guarded deployment

Run on Lantern Core after transferring the current repository snapshot:

```sh
cd /opt/lantern
chmod +x scripts/*.sh
sudo make deploy-web
```

The deployment refuses a stale VM address, requires the Windows Immich backend
to be reachable, validates every proxy route locally, and opens UFW port 80 only
after all routes pass.

Homepage uses its officially supported writable `/app/config` bind because it
writes runtime logs under that directory. `services/homepage/logs/` is excluded
from Git; declarative YAML remains the source of truth.

## Client trial

The dashboard is immediately visible at the current VM IP. Friendly names work
when a client uses Lantern Core as DNS. During the trial, preserve this rollback:

```text
Lantern DNS: 192.168.102.253
Fallback DNS: 192.168.102.124
```

Because the hotspot lease may change, do not treat the current address as a
permanent client configuration.
