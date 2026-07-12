# Phase 2 status — Lantern Core VM

Last updated: 2026-07-12.

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
- UFW is enabled with deny-by-default inbound policy and SSH permitted only
  from `192.168.215.0/24`.
- `make validate` passed on Lantern Core, including Compose rendering and native
  validation with the pinned Caddy 2.11.4 image.

## Pending acceptance checks

- Inspect the LVM layout: the virtual disk is 40 GiB, but `/` currently reports
  about 18 GiB usable. Expand the root logical volume if the remaining space is
  free in the volume group.
- Reboot after bootstrap and confirm SSH and Docker return automatically.
- Confirm OpenSSH is reachable from the Mac when it is available.

Ubuntu initially received `192.168.215.252/24` and received
`192.168.215.253/24` after a later restart, confirming that the hotspot lease is
not stable. The default gateway remains `192.168.215.63`. OpenSSH is enabled and
active, and key-based SSH from Windows was confirmed by the operator. The
address must be rechecked after VM or hotspot restarts until Phase 3 provides a
more durable discovery/update mechanism.

## Source-of-truth boundary

Git tracks VM sizing, network intent, bootstrap scripts, service definitions,
and rebuild/operations documentation. The VHDX and Hyper-V runtime metadata are
host state, not Git content. They will eventually be covered by documented
rebuild procedures and encrypted state backups rather than committed binaries.
