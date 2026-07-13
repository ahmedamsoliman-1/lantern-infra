# Phase 7: remote desktop

Status: RustDesk server deployed and verified on 2026-07-13; Windows and macOS
client acceptance remains pending.

Lantern uses RustDesk Server OSS `1.1.15`, with the official amd64 container
image pinned by digest. `hbbs` provides ID/rendezvous/signaling and `hbbr`
provides relay traffic. Both use Linux host networking as recommended by the
official deployment guide.

Only TCP `21115-21117` and UDP `21116` are required. Web-client ports `21118`
and `21119`, the Pro console port `21114`, router forwarding, and public ingress
are deliberately excluded. UFW permits the required ports only from
`LAN_SUBNET`, currently private `192.168.0.0/16` clients.

## Deploy the server

On Lantern Core, after transferring the current repository snapshot:

```sh
cd /opt/lantern
chmod +x scripts/*.sh
sudo make deploy-rustdesk
```

The guarded deployment verifies the configured VM address and free ports,
creates a mode-`0700` untracked data directory, starts both services, waits for
all required listeners and the generated public key, then opens UFW. The public
key is printed for trusted-client configuration; the private key is never
printed or committed.

Runtime keys and state live in `services/rustdesk/data/`, which is ignored by
Git and must be included in the encrypted Phase 8 backup.

## Server deployment result

The pinned `hbbs` and `hbbr` containers started successfully on Lantern Core.
TCP `21115-21117` were reachable from Windows, the `21116/udp` listener was
verified during guarded deployment, and the server generated its Ed25519 key
pair in the ignored data directory. No web-client, Pro-console, router-forward,
or public-ingress ports were enabled. The server survived the later move to the
Samsung USB network and was reconciled at `192.168.102.253` without losing its
keys.

## Security note

As of 2026-07-13, CVE-2026-30789 affects RustDesk clients through 1.4.8. A rogue
or on-path server can capture a login proof for offline password guessing; the
earlier session-replay claim was withdrawn. Install stable client `1.4.9` or
newer, keep Lantern LAN-only, pin the self-hosted server public key, and use a
randomly generated unattended-access password of at least 24 characters. Do
not reuse that password anywhere else.

Windows 11 Pro can also host RDP, but RDP remains disabled.
