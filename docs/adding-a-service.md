# Adding a service

1. Add the service to `inventory/services.yaml`.
2. Add or generate its Pi-hole record pointing to Lantern Core.
3. Add a Caddy route only for HTTP-capable services.
4. Add its Homepage link and Uptime Kuma monitor.
5. Run `make validate` and `make test`.
6. Document any new LAN port, authentication, WebSocket, upload, timeout, or
   trusted-proxy requirement.

Never proxy raw Redis, database protocols, SSH, or Elasticsearch transport as
ordinary HTTP.

