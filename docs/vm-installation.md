# Lantern Core VM installation

This runbook uses the currently available `192.168.215.0/24` hotspot network.
The VM starts with DHCP; its observed address becomes the inventory value.

## 1. Download and verify Ubuntu

The approved installer is Ubuntu Server 24.04.4 LTS amd64. Store it at:

```text
state/iso/ubuntu-24.04.4-live-server-amd64.iso
```

Expected SHA-256:

```text
e907d92eeec9df64163a7e454cbc8d7755e8ddc7ed42f99dbc80c40f1a138433
```

`state/` is ignored by Git. The VM creation script refuses a checksum mismatch.

## 2. Create and start the VM

Open PowerShell **as Administrator** in the repository and run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\create-lantern-vm.ps1
```

The script preserves existing objects, creates an external switch on `Wi-Fi`
only if missing, and creates `lantern-core` with 2 vCPU, dynamic memory (1 GiB
startup, 768 MiB minimum, 4 GiB maximum), a dynamic 40 GiB disk, Secure Boot for
Ubuntu, and automatic host-start behavior.

The external switch can briefly disconnect Wi-Fi. If the hotspot refuses the
VM's second DHCP client or isolates clients, record the failure before changing
the design.

## 3. Install Ubuntu

Open the console:

```powershell
vmconnect.exe localhost lantern-core
```

Use the whole virtual disk, hostname `lantern-core`, username `ahmed`, install
OpenSSH Server, and import or paste the existing Ed25519 public key when offered.
Choose a strong installer password; it is local state and must not be committed.
After the first reboot, eject the installer ISO if the VM returns to setup.

## 4. Bootstrap the guest

Copy or clone the repository, then run inside Ubuntu:

```sh
cd /opt/lantern
sudo env LAN_SUBNET=192.168.215.0/24 bash ./scripts/bootstrap-core.sh
hostname -I
make validate
```

Update `inventory/devices.yaml` and `.env.example` with the DHCP address only
after Windows and the Mac can reach it. A future address change requires
updating DNS; the hotspot may not support reservations.
