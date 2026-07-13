# Phase 2 status — Lantern Core VM

Last updated: 2026-07-13.

## Completed

- Hyper-V external switch `Lantern External Wi-Fi` created on the active Wi-Fi
  adapter.
- Generation 2 VM `lantern-core` created under
  `C:\ProgramData\Lantern\Hyper-V`.
- VM configured with 2 vCPUs, dynamic memory (1 GiB startup, 768 MiB minimum,
  4 GiB maximum), and a 40 GiB dynamically expanding VHDX. The startup value
  was reduced after repeat host memory pressure prevented a 2 GiB allocation.
- Ubuntu Server 24.04.4 LTS installed from a SHA-256-verified ISO.
- Ubuntu rebooted successfully and local console login as `ahmed` works.
- VM is configured to start automatically with Windows.
- OpenSSH is enabled and active; key-based access from Windows works.
- Guest bootstrap completed: Docker Engine 29.1.3, Docker Compose 2.40.3,
  Chrony, unattended upgrades, Git, Make, DNS tools, and UFW are installed.
- Docker is enabled and active, and the operator can access its socket after a
  fresh login.
- UFW is enabled with deny-by-default inbound policy and SSH permitted from
  the private `192.168.0.0/16` range.
- `make validate` passed on Lantern Core, including Compose rendering and native
  validation with the pinned Caddy 2.11.4 image.

## Pending acceptance checks

- Reboot after bootstrap and confirm SSH and Docker return automatically.
- Confirm OpenSSH is reachable from the Mac when it is available.

## Storage expansion

On 2026-07-12, `/dev/ubuntu-vg/ubuntu-lv` was expanded online from 18.47 GiB to
36.95 GiB using all free volume-group extents. `resize2fs` expanded the mounted
ext4 filesystem successfully. The resulting root filesystem reports 37 GiB
total, 26 GiB available, and 27% usage. No reboot or service interruption was
required.

Ubuntu initially received `192.168.215.252/24`, then `192.168.215.253/24`.
After a hotspot reconnect on 2026-07-13, the LAN changed to
`192.168.202.0/24`; Windows received `192.168.202.218`, Lantern Core received
`192.168.202.253`, and the gateway became `192.168.202.188`. During recovery,
the VM was found temporarily attached to Hyper-V's Default Switch and was
reconnected live to `Lantern External Wi-Fi`. Key-based SSH and all Lantern
services were restored without rebooting the VM.

Later on 2026-07-13, the uplink changed to Samsung USB tethering. A second
external switch, `Lantern External Samsung USB`, restored the VM at
`192.168.102.253`; Windows received `192.168.102.40` and the gateway became
`192.168.102.124`. Core DNS, HTTP(S), SSH, and RustDesk listeners were verified
from Windows after the runtime addresses were reconciled.

## Source-of-truth boundary

Git tracks VM sizing, network intent, bootstrap scripts, service definitions,
and rebuild/operations documentation. The VHDX and Hyper-V runtime metadata are
host state, not Git content. They will eventually be covered by documented
rebuild procedures and encrypted state backups rather than committed binaries.
