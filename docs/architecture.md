# Architecture

Lantern separates always-on network infrastructure from interactive Windows
desktop workloads. A Generation 2 Ubuntu Server VM named `lantern-core` runs on
Hyper-V and attaches to the trusted LAN through an external virtual switch.

```text
Trusted LAN clients
        |
        | DNS: *.home.arpa
        v
lantern-core VM
  Pi-hole :53  -> internal and upstream DNS
  Caddy :80/:443
    |-- Homepage
    |-- Uptime Kuma
    `-- Windows-hosted HTTP applications
        |
        v
Windows host: SSH, Immich, selected application backends
```

Only Caddy exposes browser-facing entry points. Pi-hole exposes DNS. Native
protocols such as SSH and RustDesk use their own LAN-restricted ports. Runtime
state lives in Docker volumes under the VM; declarative configuration lives in
Git; secrets and private keys live outside Git.

Phase 1 uses HTTP intentionally. Internal HTTPS and client CA trust are Phase 5.

