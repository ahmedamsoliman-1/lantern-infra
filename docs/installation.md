# Installation

## Current phase

Repository bootstrap is complete. The current hotspot network is the supported
initial LAN; DHCP is used because the hotspot may not offer reservations. Follow
the detailed [VM installation runbook](vm-installation.md).

## Lantern Core prerequisites

1. Create a Generation 2 Ubuntu Server LTS Hyper-V VM: 2 vCPU, dynamic memory
   from 768 MiB–4 GiB with 1 GiB startup, and a 40 GiB dynamic VHDX.
2. Attach it to an external Hyper-V switch on the current Wi-Fi network.
3. Use DHCP initially and configure hostname `lantern-core`.
4. Install Docker Engine, the Compose plugin, Git, Make, curl, and DNS tools.
5. Clone this repository to `/opt/lantern`.

Then run:

```sh
cp .env.example .env
# Review every value in .env.
make validate
make deploy
```

Do not run `make deploy` on the Windows Docker Desktop host.
