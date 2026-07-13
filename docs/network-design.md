# Network design

Use `home.arpa`, never `.local`. Device records point to device addresses;
browser service records point to the Lantern Core address where Caddy listens.

The current `192.168.202.0/24` hotspot is the available Lantern LAN. The VM uses
DHCP because the hotspot does not expose reservations. Record its lease and
update `.env`, inventory, and Pi-hole records together whenever it changes.
The hotspot moved from `192.168.215.0/24` to `192.168.202.0/24` after a
reconnect, while Lantern Core moved from `192.168.215.253` to
`192.168.202.253`. UFW trusts only the private `192.168.0.0/16` range so subnet
changes do not lock out SSH or the LAN services; Compose still binds services
to the explicitly recorded VM address.

No router port forwarding is permitted in version one. Initially configure only
the Mac to use Pi-hole. Move router DHCP DNS to Lantern only after DNS restart
and recovery tests succeed.

## Hotspot reconnect recovery

If Lantern disappears after the hotspot reconnects, first verify in elevated
Windows PowerShell that `lantern-core` is attached to `Lantern External Wi-Fi`,
not Hyper-V's Default Switch:

```powershell
Get-VMNetworkAdapter -VMName lantern-core |
  Format-Table Name, SwitchName, MacAddress, Status
Connect-VMNetworkAdapter -VMName lantern-core -Name "Network Adapter" `
  -SwitchName "Lantern External Wi-Fi"
```

In the Ubuntu console, renew DHCP with `sudo networkctl renew eth0`, then record
`hostname -I` and `ip route`. Update `LANTERN_CORE_IP`, `WINDOWS_LAN_IP`, and
`UPSTREAM_DNS` in `/opt/lantern/.env`, then recreate the stack:

```sh
sudo docker compose --env-file .env -f compose/compose.yaml up -d --force-recreate
```

Validate direct DNS queries before pointing Windows back to Lantern DNS. The
Hyper-V console remains the recovery path when the VM's new address is unknown.
