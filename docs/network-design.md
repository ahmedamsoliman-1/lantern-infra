# Network design

Use `home.arpa`, never `.local`. Device records point to device addresses;
browser service records point to the Lantern Core address where Caddy listens.

The current `192.168.215.0/24` discovery network may be temporary. Before VM
creation, repeat discovery on the permanent router, reserve both Windows and VM
addresses, then update `.env`, inventory, and Pi-hole records together.

No router port forwarding is permitted in version one. Initially configure only
the Mac to use Pi-hole. Move router DHCP DNS to Lantern only after DNS restart
and recovery tests succeed.

