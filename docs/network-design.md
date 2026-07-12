# Network design

Use `home.arpa`, never `.local`. Device records point to device addresses;
browser service records point to the Lantern Core address where Caddy listens.

The current `192.168.215.0/24` hotspot is the available Lantern LAN. The VM uses
DHCP because the hotspot may not expose reservations. Record its lease after
creation and update `.env`, inventory, and Pi-hole records together whenever it
changes. Confirmed leases have already changed from `192.168.215.252` to
`192.168.215.253`, demonstrating that these are observed addresses rather than
reservations.

No router port forwarding is permitted in version one. Initially configure only
the Mac to use Pi-hole. Move router DHCP DNS to Lantern only after DNS restart
and recovery tests succeed.
