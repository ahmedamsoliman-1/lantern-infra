# Local certificates

Phase 1 validates routing over HTTP. Phase 5 will enable `tls internal` in Caddy
and install Lantern's root CA only on trusted clients. The CA private key stays
on Lantern Core, is excluded from Git, and must be encrypted in backups.

