# RustDesk client configuration

Use stable RustDesk client `1.4.9` or newer on both Windows and macOS. Versions
through 1.4.8 are within the affected range of CVE-2026-30789.

Configure both the Windows host and Mac controller with:

| Field | Value |
| --- | --- |
| ID Server | current Lantern Core address, currently `192.168.102.253` |
| Relay Server | leave blank; RustDesk derives port `21117` from the ID server |
| API Server | leave blank; this is an OSS deployment |
| Key | exact `id_ed25519.pub` value printed by `make deploy-rustdesk` |

On Windows, enable unattended access only after setting a unique random
password of at least 24 characters. Restrict permissions to the minimum needed.
Do not store the password in Git, screenshots, shell history, or this document.

The Mac and Windows clients must both use the same self-hosted ID server and
public key. Test clipboard and multi-monitor behavior after the first successful
connection. Re-test after restarting `hbbs`, `hbbr`, and the Windows client.
