# Network design

Use `home.arpa`, never `.local`. Device records point to device addresses;
browser service records point to the Lantern Core address where Caddy listens.

The current `192.168.102.0/24` Samsung USB tether is the available Lantern LAN.
The VM uses DHCP because the tether does not expose reservations. Record its lease and
update `.env`, inventory, and Pi-hole records together whenever it changes.
The hotspot moved from `192.168.215.0/24` to `192.168.202.0/24` after a
reconnect, while Lantern Core moved from `192.168.215.253` to
`192.168.202.253`, then to `192.168.102.253` when the uplink changed to USB.
UFW trusts only the private `192.168.0.0/16` range so subnet
changes do not lock out SSH or the LAN services; Compose still binds services
to the explicitly recorded VM address.

No router port forwarding is permitted in version one. Initially configure only
the Mac to use Pi-hole. Move router DHCP DNS to Lantern only after DNS restart
and recovery tests succeed.

## Hotspot reconnect recovery

If Lantern disappears after the uplink reconnects, first verify in elevated
Windows PowerShell that `lantern-core` is attached to the external switch for
the active Wi-Fi or USB adapter, not Hyper-V's Default Switch:

```powershell
Get-VMNetworkAdapter -VMName lantern-core |
  Format-Table Name, SwitchName, MacAddress, Status
Connect-VMNetworkAdapter -VMName lantern-core -Name "Network Adapter" `
  -SwitchName "<active Lantern external switch>"
```

In the Ubuntu console, renew DHCP with `sudo networkctl renew eth0`, then record
`hostname -I` and `ip route`. Once Windows and Lantern Core have addresses on
the same `192.168.x.0/24`, reconcile the runtime with one guarded command:

```sh
cd /opt/lantern
sudo make reconcile-network WINDOWS_IP=<current-Windows-LAN-IP>
```

The command detects Lantern Core's current address and gateway, updates `.env`,
recreates the core stack and RustDesk when deployed, reapplies idempotent
private-LAN UFW rules, and verifies exact local and upstream DNS answers.

To transfer the newest Windows working copy without overwriting runtime state:

```powershell
.\scripts\sync-to-core.ps1 -CoreAddress <current-Lantern-Core-IP>
```

The helper excludes `.env`, secrets, certificates, state databases, logs, and
RustDesk keys, then prints the exact extraction commands.

Validate direct DNS queries before pointing Windows back to Lantern DNS. The
Hyper-V console remains the recovery path when the VM's new address is unknown.
