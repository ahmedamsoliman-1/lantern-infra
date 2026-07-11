# Operations

Run commands from `/opt/lantern` on Lantern Core.

| Command | Purpose |
| --- | --- |
| `make validate` | Static policy, Compose, and Caddy checks |
| `make deploy` | Validate and reconcile containers |
| `make status` | Show container state |
| `make logs` | Follow recent service logs |
| `make update` | Pull explicitly pinned images and reconcile |
| `make test` | Test DNS and HTTP endpoints |
| `make stop` | Stop the stack without deleting volumes |

For DNS failure recovery, temporarily restore the client DNS server to the
router or a trusted resolver. Do not change the router DHCP DNS setting until a
single-client trial has passed.

