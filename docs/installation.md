# Installation

## Current phase

Repository bootstrap is complete, but deployment is intentionally blocked until
the permanent LAN and DHCP reservations are confirmed.

## Lantern Core prerequisites

1. Create a Generation 2 Ubuntu Server LTS Hyper-V VM: 2 vCPU, 4 GiB RAM, 40
   GiB dynamic VHDX.
2. Attach it to an external Hyper-V switch on the trusted LAN.
3. Reserve its address in the router and configure hostname `lantern-core`.
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

