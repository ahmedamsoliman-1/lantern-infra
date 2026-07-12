# Lantern Phase 0 Discovery

Discovery captured on 2026-07-11 (Asia/Dubai). This phase was read-only: no
packages, Windows features, firewall rules, adapters, or services were changed.

## Executive recommendation

Use a Generation 2 Ubuntu Server LTS VM on Hyper-V with 2 vCPUs, 4 GiB RAM,
and a 40 GiB dynamically expanding VHDX. Hyper-V is installed and its
hypervisor and management service are running. Create an **external** virtual
switch attached to the physical LAN adapter so `lantern-core` receives its own
LAN address; do not use the Hyper-V Default Switch or the WSL virtual network
for production DNS.

The active connection during discovery was the `AAMSNote20Ultra5G` Wi-Fi
network, with a short one-hour DHCP lease. It may not be the intended permanent
home LAN. The address proposal below is therefore a validation layout, not an
authorization to configure static addresses:

| Role | Proposed address on the currently observed LAN |
| --- | --- |
| Network | `192.168.215.0/24` |
| Gateway and current DNS | `192.168.215.63` |
| Windows (`windows.home.arpa`) | reserve current lease `192.168.215.218` for MAC `44:E5:17:99:4D:B4` |
| Lantern Core (`lantern-core.home.arpa`) | use the DHCP address assigned by the current hotspot and record it after first boot |

The current hotspot is the available Lantern LAN. It may not support DHCP
reservations, so Phase 2 begins with DHCP and records the observed VM address.
Do not deploy Pi-hole to every client until address-change behavior is tested.

## Host

| Item | Observed value |
| --- | --- |
| Computer name | `AAMSTHINKPADX1` |
| Windows | Windows 11 Pro, 64-bit, build `26200` |
| Hardware | Lenovo ThinkPad model `20XW000SAD` |
| CPU | Intel Core i7-1165G7 |
| Internal disk | 476.9 GiB NVMe; `C:` has 174.7 GiB free |
| External disk | 931.5 GiB SanDisk Portable SSD over USB |
| External volumes | `E:` 477.4 GiB (reported as 0 bytes available/mounted); `H:` label `Ahmed454GB`, exFAT, 454.1 GiB free |

The VM's 40 GiB VHDX fits on `C:`. The external SSD is suitable as a future
encrypted backup destination, but `E:` must be diagnosed and the intended
backup volume confirmed before Phase 8.

## Network

| Item | Observed value |
| --- | --- |
| Active physical interface | `Wi-Fi` — Intel Wi-Fi 6 AX201 160MHz |
| SSID/profile | `AAMSNote20Ultra5G` |
| Windows firewall network category | Public |
| IPv4 address | `192.168.215.218/24` via DHCP |
| Default gateway | `192.168.215.63` |
| DHCP server | `192.168.215.63` |
| DNS server | `192.168.215.63` |
| DHCP lease seen | 2026-07-11 23:05:50 through 2026-07-12 00:05:49 |
| Physical MAC | `44:E5:17:99:4D:B4` |
| Hyper-V Default Switch | host address `172.17.240.1` |
| WSL virtual network | host address `192.168.176.1` |

Whether the Windows lease is reserved cannot be determined from the client.
Router access is needed to verify it. There was no external Hyper-V switch
visible to the non-elevated discovery session.

## Virtualization and containers

- Windows edition supports Hyper-V and acting as an RDP host.
- Hyper-V, its hypervisor, services, management clients, and PowerShell tools
  report as installed. A hypervisor is active; `vmms` is running automatically.
- VM enumeration and virtual-switch enumeration returned no objects to the
  non-elevated session. Confirm in an elevated Hyper-V Manager before creating
  the VM.
- WSL and Virtual Machine Platform are installed. WSL 2 is the default.
- WSL distributions `Ubuntu-24.04` and `docker-desktop` were running.
- Docker Desktop 4.43.2 was active with Engine 28.3.2 on the `desktop-linux`
  context. Its Windows service is manual and was stopped; the backend was
  nevertheless running in the interactive user session.
- No VMware, VirtualBox, or Podman command was found.

Existing Docker workloads must be preserved:

| Workload | Image | Published LAN port |
| --- | --- | --- |
| Immich server | `ghcr.io/immich-app/immich-server:v2.7.5` | `2283/tcp` |
| Immich machine learning | `ghcr.io/immich-app/immich-machine-learning:v2.7.5` | none |
| Immich PostgreSQL | `ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0` | none |
| Immich Valkey | `valkey/valkey:9` | none |
| Kibana | `docker.elastic.co/kibana/kibana:8.17.3` | `5601/tcp` |
| Elasticsearch | `docker.elastic.co/elasticsearch/elasticsearch:8.17.3` | `9200/tcp` |

## Remote access

- OpenSSH Server (`sshd`) is running, starts automatically, and listens on
  `22/tcp` on IPv4 and IPv6. Enabled inbound firewall rules include rules for
  all profiles as well as a Private-only rule. This should be narrowed to the
  trusted LAN during hardening.
- Windows 11 Pro supports an RDP host, but RDP connections are currently
  disabled (`fDenyTSConnections=1`); Remote Desktop Services was stopped.
- No RustDesk service or listener was observed.

## Firewall and listener findings

All Domain, Private, and Public Windows Defender Firewall profiles are enabled.
The active Wi-Fi profile is Public. Profile default actions were reported as
`NotConfigured`, which means effective policy inherits Windows defaults and/or
policy; it should be checked explicitly before Phase 2 firewall work.

Important findings from the listener snapshot are detailed in
`inventory/ports.md`:

- `80/tcp` and `443/tcp` were free.
- `53/udp` was already held by a Windows `svchost` process, consistent with
  host networking/Internet Connection Sharing. A VM with its own LAN IP avoids
  binding Pi-hole to this Windows address.
- `2283`, `5601`, and `9200` were published on all host interfaces by Docker
  Desktop. They are existing LAN exposures and must not be disrupted during
  Phase 0; later firewall/proxy hardening should restrict them.
- SMB/RPC listeners (`135`, `139`, `445`) and several Windows dynamic ports are
  present. They are outside Lantern's application scope but relevant to LAN
  hardening.

## Phase 2 prerequisites and open checks

1. Record the address assigned to the VM by the current hotspot and test
   Windows-to-VM and Mac-to-VM communication.
2. Check whether the hotspot offers DHCP reservation or client-isolation
   controls; use DHCP without inventing a static address if it does not.
3. Run Hyper-V inventory from an elevated session and record existing VMs and
   switches before creating an external switch.
4. Confirm whether the external switch will use Wi-Fi or a more stable Ethernet
   adapter. Ethernet is preferred for DNS infrastructure when available.
5. Confirm `H:` is the intended backup volume and diagnose the inaccessible or
   zero-sized `E:` volume.
6. Inventory application authentication and proxy requirements for Immich,
   Kibana, and Elasticsearch before exposing friendly hostnames.
7. Decide whether RDP should be enabled later as the secondary remote desktop
   path; it remains disabled for now.
