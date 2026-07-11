# Port Inventory

Read-only listener snapshot captured on 2026-07-11. `0.0.0.0` and `::` mean a
listener accepts traffic on all addresses in that address family; Windows
Firewall still determines whether remote traffic can reach it.

## Lantern and application-relevant TCP ports

| Port | Bind | Owner/workload | State and action |
| --- | --- | --- | --- |
| 22 | `0.0.0.0`, `::` | Windows OpenSSH (`sshd`) | In use; preserve. Later restrict firewall source to trusted LAN. |
| 53 | — | — | No TCP listener observed on Windows. |
| 80 | — | — | Free on Windows at discovery time. |
| 443 | — | — | Free on Windows at discovery time. |
| 2283 | `::` plus WSL loopback relay | Docker Desktop / Immich | In use and published to LAN. Future `photos.home.arpa` upstream. |
| 5601 | `::` plus WSL loopback relay | Docker Desktop / Kibana | In use and published to LAN; review authentication before proxying. |
| 9200 | `::` plus WSL loopback relay | Docker Desktop / Elasticsearch | In use and published to LAN; restrict during hardening. |
| 6379 | container network only | Immich Valkey | Not published to Windows; keep private. |
| 5432 | container network only | Immich PostgreSQL | Not published to Windows; keep private. |
| 3389 | — | Windows RDP | No listener; RDP is disabled. |

## Other observed TCP listeners

| Ports | Bind/owner | Notes |
| --- | --- | --- |
| 135 | all IPv4/IPv6, `svchost` | Windows RPC endpoint mapper. |
| 139 | each active IPv4 interface, System | NetBIOS session service. |
| 445 | all IPv6 (dual-stack behavior may apply), System | SMB. |
| 2179 | all IPv4/IPv6, `vmms` | Hyper-V VM console service. |
| 2222 | all IPv4, `svchost` | Windows service; exact service mapping requires elevated inspection. |
| 5040 | all IPv4, `svchost` | Windows service. |
| 7680 | all IPv6, `svchost` | Windows Delivery Optimization. |
| 49664–49670 | all/loopback, Windows core services | Dynamic RPC/service listeners. |
| 42050, 54431, 55345, 56328, 56335 | loopback | OneDrive, VS Code, and Codex-related local listeners. |
| 55622 | all IPv4, Logi Options+ | Vendor utility listener. |
| 7679 | IPv6 loopback, Google Drive | Local-only listener. |

## Observed UDP listeners

| Ports | Bind/owner | Notes |
| --- | --- | --- |
| 53 | all IPv4, `svchost` | Occupied by Windows host networking/ICS behavior. Pi-hole should use the VM's distinct LAN IP. |
| 67–68 | Hyper-V Default Switch address, `svchost` | DHCP for the Hyper-V NAT network. |
| 123 | all IPv4/IPv6, `svchost` | Windows time. |
| 137–138 | active IPv4 interfaces, System | NetBIOS name/datagram services. |
| 500, 4500 | all IPv4/IPv6, `svchost` | IPsec/IKE. |
| 1900 | loopback and active interfaces, `svchost` | SSDP discovery. |
| 5050 | all IPv4, `svchost` | Windows service. |
| 5353 | all IPv4/IPv6, Edge | mDNS. This reinforces avoiding the `.local` suffix. |
| 5355 | all IPv4/IPv6, `svchost` | LLMNR. |
| 49664, 49884, 55950–55952, 57302–57309, 63752–63753 | mixed | Dynamic Windows discovery/service endpoints. |
| 59870–59871 | all IPv4, Logi Options+ | Vendor utility. |

## Planned Lantern Core LAN exposure

These are planned on the VM, not currently opened by this phase:

| Port | Protocol | Purpose | Intended source |
| --- | --- | --- | --- |
| 22 | TCP | Lantern Core SSH | trusted LAN only |
| 53 | TCP/UDP | Pi-hole DNS | trusted LAN only |
| 80 | TCP | Caddy HTTP validation/redirect | trusted LAN only |
| 443 | TCP | Caddy HTTPS | trusted LAN only |
| 21115–21117 | TCP | RustDesk signal/NAT/relay | trusted LAN only |
| 21116 | UDP | RustDesk ID/heartbeat | trusted LAN only |
| 21118–21119 | TCP | RustDesk web clients, only if required | trusted LAN only |

Verify the RustDesk version's required ports immediately before Phase 7. No
router port forwarding is part of version one.
