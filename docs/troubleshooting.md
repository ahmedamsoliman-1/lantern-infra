# Troubleshooting

1. Run `make status` and `make logs`.
2. Query Pi-hole directly: `dig @<LANTERN_CORE_IP> dashboard.home.arpa`.
3. Confirm the client is on the trusted LAN and using Lantern DNS.
4. Test Caddy and the upstream independently from Lantern Core.
5. Verify Windows and Ubuntu firewall scopes before changing rules.

If Lantern DNS is unavailable, temporarily configure the client to use the
router DNS. Do not disable either host firewall as a diagnostic shortcut.

