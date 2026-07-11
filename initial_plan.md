# Lantern Infrastructure Project

## 1. Project Overview

**Project name:** Lantern
**Repository name:** `lantern-infra`

Lantern is a local-network infrastructure platform for managing access to services and devices hosted primarily on a Windows machine.

The user normally works from a Mac and connects to the Windows machine through SSH. The Windows machine also hosts local applications and infrastructure services.

Lantern must provide:

* Local-only remote desktop access to Windows
* Internal DNS for devices and services
* Friendly local domain names
* Reverse proxying for HTTP applications
* Elimination of remembered IP addresses and application ports
* A dashboard listing available services
* Local uptime and health monitoring
* Reproducible, version-controlled configuration
* Backup and restore procedures
* A foundation that can later support secure remote access without redesigning the local network

The initial implementation must remain accessible only from the trusted local network.

---

# 2. Target User Experience

Instead of accessing services like this:

```text
http://192.168.1.50:2283
http://192.168.1.50:3001
http://192.168.1.50:9000
ssh ahmed@192.168.1.50
```

the user should access them like this:

```text
https://photos.home.arpa
https://status.home.arpa
https://dashboard.home.arpa
https://containers.home.arpa
ssh ahmed@windows.home.arpa
```

Remote desktop access should work from the Mac to Windows through either:

```text
RustDesk
```

or, when available:

```text
Microsoft Remote Desktop
```

No service should be exposed to the public Internet during the initial implementation.

---

# 3. Core Architecture

```text
                         Local Network
                              │
             ┌────────────────┴────────────────┐
             │                                 │
          MacBook                         Other Devices
             │                            Phone / Tablet
             │                                 │
             └───────────────┬─────────────────┘
                             │
                      Lantern DNS
                             │
                  Resolves *.home.arpa
                             │
                             ▼
                    Windows Host Machine
                  windows.home.arpa
                             │
             ┌───────────────┴────────────────┐
             │                                │
      Lantern Core                     Windows Services
      Linux VM/container host          Native applications
             │                                │
    ┌────────┼─────────┬──────────┐           │
    │        │         │          │           │
 DNS       Caddy    Dashboard   Monitoring    │
    │        │         │          │           │
    └────────┴─────────┴──────────┴───────────┘
                             │
                    Friendly local domains
```

---

# 4. Important Hosting Decision

## Recommended model: a small Linux virtual machine on Windows

Run the core Lantern infrastructure inside a dedicated Linux virtual machine hosted by the Windows machine.

Recommended guest operating system:

```text
Ubuntu Server LTS
```

Suggested VM name:

```text
lantern-core
```

Suggested hostname:

```text
lantern-core.home.arpa
```

The VM should receive a stable LAN IP address.

This VM should host:

* Pi-hole
* Caddy
* Homepage
* Uptime Kuma
* RustDesk Server OSS
* Optional Portainer
* Supporting automation scripts

## Why use a Linux VM?

Running the network foundation directly inside Docker Desktop or WSL can create unnecessary complications around:

* Port 53 DNS binding
* Stable LAN IP addressing
* Container startup before interactive login
* WSL networking
* Docker Desktop lifecycle
* Firewall routing
* Service availability after Windows restarts

The Linux VM provides a predictable environment and clean separation between:

* Windows desktop usage
* Existing Windows-hosted services
* Local network infrastructure

## Hypervisor choice

The implementation agent must detect the Windows edition and available virtualization features.

Preferred order:

1. Hyper-V, when supported
2. VMware Workstation
3. VirtualBox
4. Docker Desktop or WSL2 only as a fallback

The agent must not silently enable virtualization features or reboot Windows without documenting the action first.

---

# 5. Technology Choices

## 5.1 Internal DNS: Pi-hole

Pi-hole will provide:

* Local DNS resolution
* Local DNS records
* Optional network-wide filtering
* DNS query visibility
* A management interface
* Optional DHCP integration later

Pi-hole supports local DNS configuration and a purely local DNS domain.

Initial records:

```text
lantern-core.home.arpa  -> <LANTERN_CORE_IP>
windows.home.arpa       -> <WINDOWS_LAN_IP>
photos.home.arpa        -> <LANTERN_CORE_IP>
status.home.arpa        -> <LANTERN_CORE_IP>
dashboard.home.arpa     -> <LANTERN_CORE_IP>
containers.home.arpa    -> <LANTERN_CORE_IP>
remote.home.arpa        -> <LANTERN_CORE_IP>
```

All browser-facing service names point to the Caddy reverse proxy.

Device names point directly to the corresponding device IP.

---

## 5.2 Reverse Proxy: Caddy

Caddy will be the HTTP and HTTPS entry point.

Caddy officially supports reverse proxying to local backend services and supports load balancing, health checks, WebSockets, and modern HTTP protocols.

Example routing:

```text
photos.home.arpa
    -> Windows host or container service on port 2283

status.home.arpa
    -> Uptime Kuma on port 3001

dashboard.home.arpa
    -> Homepage

containers.home.arpa
    -> Portainer
```

Only Caddy should normally expose ports `80` and `443` to the LAN.

Application ports should be:

* bound to localhost;
* bound to a private Docker network; or
* restricted by the Windows/Linux firewall to the Lantern Core VM.

Non-HTTP protocols such as SSH, Redis and Elasticsearch transport traffic must not be treated as ordinary HTTP reverse-proxy targets.

---

## 5.3 Remote Desktop: RustDesk Server OSS

RustDesk will provide self-hosted remote desktop access between the Mac and Windows machine.

RustDesk supports Windows and macOS clients, and its server can be self-hosted. Its documentation recommends Docker for reproducible RustDesk Server OSS deployments.

Lantern should deploy the RustDesk coordination and relay components:

```text
hbbs
hbbr
```

The clients must be configured to use the local Lantern RustDesk server.

The deployment must remain LAN-only initially.

The Windows RustDesk client should be configured for unattended access, protected with a strong password and restricted permissions.

Microsoft Remote Desktop may also be retained as a faster secondary access method when the Windows edition supports acting as an RDP host.

---

## 5.4 Dashboard: Homepage

Homepage will provide a single local page listing:

* Windows
* Immich
* Elasticsearch
* Redis Commander
* Portainer
* Uptime Kuma
* RustDesk
* Other future projects

Target URL:

```text
https://dashboard.home.arpa
```

The dashboard configuration must live in Git.

Do not place passwords, tokens or API keys directly in dashboard YAML files.

---

## 5.5 Monitoring: Uptime Kuma

Uptime Kuma will monitor:

* HTTP endpoints
* TCP services
* DNS
* Windows host reachability
* Lantern Core reachability
* SSH
* Existing applications
* Certificate expiry
* Docker-hosted services where practical

Uptime Kuma supports a self-hosted Docker Compose deployment and stores its state in a persistent local volume.

Target URL:

```text
https://status.home.arpa
```

Initial monitors:

```text
Lantern DNS
Lantern Caddy
Lantern Dashboard
Windows Ping
Windows SSH
Immich
Elasticsearch HTTP
Redis TCP
Portainer
RustDesk ID Server
RustDesk Relay
```

---

## 5.6 Container Management: Portainer

Portainer is optional but recommended for visibility.

Target URL:

```text
https://containers.home.arpa
```

Git and Docker Compose remain the source of truth. Changes made through Portainer must not become the only record of infrastructure configuration.

---

# 6. Domain Naming Standard

Use:

```text
home.arpa
```

Do not use:

```text
.local
```

The `.local` suffix is commonly used by multicast DNS and can conflict with Apple devices.

Naming rules:

```text
<device>.home.arpa
<service>.home.arpa
```

Examples:

```text
windows.home.arpa
macbook.home.arpa
tablet.home.arpa
lantern-core.home.arpa

photos.home.arpa
status.home.arpa
dashboard.home.arpa
containers.home.arpa
elastic.home.arpa
redis-ui.home.arpa
```

Use short, stable names that describe the service rather than the current implementation.

For example:

```text
photos.home.arpa
```

is better than:

```text
immich-container-1.home.arpa
```

---

# 7. HTTPS Strategy

Lantern should support two stages.

## Stage 1: HTTP during initial validation

Bring up services using HTTP first:

```text
http://dashboard.home.arpa
http://status.home.arpa
```

This confirms:

* DNS resolution
* reverse proxy routing
* firewall access
* application availability

## Stage 2: Local HTTPS

Configure Caddy with its internal certificate authority:

```caddyfile
tls internal
```

Each client device must trust Lantern's local root CA before browser warnings disappear.

Install the root CA only on trusted devices:

* Mac
* Windows
* Samsung tablet
* Phone, when needed

The CA private key must:

* remain on Lantern Core;
* never be committed to Git;
* be included in encrypted backups;
* have restrictive filesystem permissions.

Public certificate authorities should not be required for the initial LAN-only deployment.

---

# 8. Repository Structure

```text
lantern-infra/
├── README.md
├── LICENSE
├── .gitignore
├── .editorconfig
├── .env.example
├── Makefile
│
├── docs/
│   ├── architecture.md
│   ├── network-design.md
│   ├── installation.md
│   ├── operations.md
│   ├── backup-restore.md
│   ├── adding-a-service.md
│   ├── remote-desktop.md
│   ├── certificates.md
│   ├── troubleshooting.md
│   └── disaster-recovery.md
│
├── inventory/
│   ├── devices.example.yaml
│   ├── services.example.yaml
│   └── ports.md
│
├── compose/
│   ├── compose.yaml
│   ├── compose.override.example.yaml
│   └── networks.yaml
│
├── services/
│   ├── caddy/
│   │   ├── Caddyfile
│   │   └── snippets/
│   ├── pihole/
│   │   ├── config/
│   │   └── dns-records.example.conf
│   ├── homepage/
│   │   ├── settings.yaml
│   │   ├── services.yaml
│   │   ├── widgets.yaml
│   │   └── bookmarks.yaml
│   ├── uptime-kuma/
│   │   └── README.md
│   ├── rustdesk/
│   │   ├── compose.yaml
│   │   └── client-configuration.md
│   └── portainer/
│       └── README.md
│
├── scripts/
│   ├── bootstrap.sh
│   ├── validate.sh
│   ├── deploy.sh
│   ├── update.sh
│   ├── backup.sh
│   ├── restore.sh
│   ├── status.sh
│   ├── generate-dns.sh
│   ├── generate-caddy.sh
│   ├── test-dns.sh
│   └── test-services.sh
│
├── backups/
│   └── README.md
│
└── state/
    └── .gitkeep
```

Runtime state must not be committed.

---

# 9. Source-of-Truth Model

The Git repository is the source of truth for:

* Docker Compose configuration
* Service definitions
* DNS declarations
* Caddy routes
* Dashboard links
* Network inventory
* Firewall documentation
* Installation procedures
* Backup procedures
* Health-check definitions where automation supports them

Git must not contain:

* passwords;
* private keys;
* local CA private material;
* RustDesk private keys;
* session databases;
* Pi-hole runtime databases;
* Uptime Kuma databases;
* raw backups;
* tokens;
* personal access keys.

---

# 10. Declarative Inventory

Create a central service inventory file:

```yaml
domain: home.arpa

devices:
  lantern-core:
    hostname: lantern-core
    ip: 192.168.1.10
    role: infrastructure

  windows:
    hostname: windows
    ip: 192.168.1.20
    role: application-host
    ssh_port: 22

services:
  dashboard:
    hostname: dashboard
    protocol: http
    upstream: homepage:3000
    health_path: /
    public_on_lan: true

  status:
    hostname: status
    protocol: http
    upstream: uptime-kuma:3001
    health_path: /
    public_on_lan: true

  photos:
    hostname: photos
    protocol: http
    upstream: 192.168.1.20:2283
    health_path: /
    public_on_lan: true
```

The implementation may either use one inventory file or separate device and service files.

The agent should generate or validate:

* DNS records
* Caddy entries
* Homepage entries
* monitor definitions
* documentation tables

from the shared inventory where practical.

Avoid building a complicated custom platform in version one. Small deterministic scripts are preferred.

---

# 11. Example Docker Compose Design

Use one shared proxy network:

```yaml
networks:
  lantern:
    name: lantern
```

Example services:

```yaml
services:
  caddy:
    image: caddy:<PINNED_VERSION>
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ../services/caddy/Caddyfile:/etc/caddy/Caddyfile:ro
      - caddy_data:/data
      - caddy_config:/config
    networks:
      - lantern

  homepage:
    image: ghcr.io/gethomepage/homepage:<PINNED_VERSION>
    restart: unless-stopped
    volumes:
      - ../services/homepage:/app/config
    networks:
      - lantern

  uptime-kuma:
    image: louislam/uptime-kuma:<PINNED_VERSION>
    restart: unless-stopped
    volumes:
      - uptime_kuma_data:/app/data
    networks:
      - lantern
```

Pi-hole and RustDesk may require additional ports and networking configuration.

Do not use floating `latest` tags in the final committed deployment.

Pin tested versions and document the upgrade process.

---

# 12. Example Caddy Configuration

```caddyfile
{
    admin off
}

(common) {
    encode zstd gzip

    header {
        X-Content-Type-Options nosniff
        X-Frame-Options SAMEORIGIN
        Referrer-Policy no-referrer
    }

    tls internal
}

dashboard.home.arpa {
    import common
    reverse_proxy homepage:3000
}

status.home.arpa {
    import common
    reverse_proxy uptime-kuma:3001
}

containers.home.arpa {
    import common
    reverse_proxy portainer:9000
}

photos.home.arpa {
    import common
    reverse_proxy 192.168.1.20:2283
}
```

The agent must verify application-specific proxy requirements, including:

* WebSockets
* forwarded headers
* request body sizes
* timeouts
* streaming
* trusted proxy settings

before declaring a service complete.

---

# 13. Network Requirements

## Static addresses

Reserve stable addresses in the router's DHCP configuration.

Example:

```text
Router                  192.168.1.1
Lantern Core            192.168.1.10
Windows Host            192.168.1.20
MacBook                 DHCP reservation recommended
```

Prefer DHCP reservations over manually configured static addresses where possible.

## DNS assignment

Preferred option:

```text
Router DHCP advertises Lantern Core as the LAN DNS server.
```

Fallback during testing:

```text
Configure only the Mac to use Lantern Core DNS.
```

Do not change the entire network's DNS configuration until Pi-hole is confirmed stable.

## DNS failure behavior

Because Pi-hole becomes important infrastructure, document what happens when the Windows host or Lantern Core is offline.

Initial recovery procedure:

```text
Temporarily set client DNS to the router or a trusted public resolver.
```

A later milestone may add a second DNS instance for redundancy.

---

# 14. Firewall Policy

The system must use a deny-by-default mindset.

## Expose to the LAN

Normally permitted:

```text
53/tcp and 53/udp      DNS
80/tcp                 HTTP redirect/bootstrap
443/tcp                HTTPS
RustDesk required ports
22/tcp                 SSH, restricted to LAN
```

## Do not expose unnecessarily

Avoid direct LAN exposure of:

```text
Redis
Elasticsearch administrative APIs
Docker daemon socket
Application databases
Internal container ports
Caddy admin API
Pi-hole database files
```

For each opened port, document:

* service;
* protocol;
* source network;
* destination;
* reason;
* whether authentication is required.

The Windows firewall should restrict Lantern-related access to the private LAN subnet.

No router port forwarding must be configured in phase one.

---

# 15. Secrets Management

Use:

```text
.env
```

only for non-versioned local deployment variables.

Commit:

```text
.env.example
```

with placeholders.

For more sensitive values, prefer Docker secrets or files stored under:

```text
/secrets
```

with restrictive permissions.

Example:

```text
secrets/
├── pihole_admin_password
├── rustdesk_private_key
└── backup_encryption_password
```

The `secrets/` directory must be ignored by Git.

A secrets manifest should explain how each secret is generated and restored without containing the secret itself.

---

# 16. Backup Design

Backups must cover:

* Git repository
* Pi-hole configuration
* Caddy data
* Caddy local CA
* Homepage configuration
* Uptime Kuma data
* RustDesk keys and configuration
* Portainer data, when used
* Service inventory
* VM configuration documentation

Backups should be written to a staging directory and then copied to the external SSD.

Example destination:

```text
<SSD>/lantern-backups/
```

Backup naming:

```text
lantern-YYYY-MM-DD-HHMMSS.tar.age
```

Backups containing secrets or private keys must be encrypted.

The repository must include:

```text
scripts/backup.sh
scripts/restore.sh
docs/backup-restore.md
```

A backup is not considered complete until a restore test has been documented.

---

# 17. Operational Commands

Provide a simple operator interface through a `Makefile`.

Required commands:

```bash
make bootstrap
make validate
make deploy
make status
make logs
make update
make backup
make test
make stop
```

Expected behavior:

```bash
make validate
```

should check:

* required environment variables;
* valid YAML;
* Docker Compose syntax;
* Caddy configuration;
* duplicate domains;
* duplicate ports;
* invalid IP addresses;
* missing service references;
* accidental committed secrets.

```bash
make test
```

should test:

* DNS lookup;
* HTTP and HTTPS access;
* certificate trust where possible;
* expected redirects;
* backend reachability;
* required TCP ports;
* container health.

---

# 18. Implementation Phases

## Phase 0: Discovery

The agent must inspect and document:

* Windows version and edition
* Available virtualization support
* Existing Docker installation
* Existing WSL installation
* Current LAN subnet
* Router IP
* Windows LAN IP
* Whether the IP is reserved
* Existing services and ports
* Existing firewall rules
* Whether ports 53, 80 and 443 are already occupied
* Current DNS configuration
* Whether RDP hosting is supported
* Current SSH configuration

Deliverable:

```text
docs/discovery.md
```

No destructive changes should occur during discovery.

---

## Phase 1: Repository Bootstrap

Create:

* repository structure;
* README;
* architecture document;
* `.env.example`;
* Makefile;
* validation scripts;
* Compose skeleton;
* inventory templates.

Acceptance criteria:

* repository contains no secrets;
* `make validate` works;
* Compose configuration renders successfully;
* architecture is understandable without inspecting every file.

---

## Phase 2: Lantern Core VM

Create the Linux VM.

Suggested initial resources:

```text
2 virtual CPUs
4 GB RAM
40 GB virtual disk
Bridged/external virtual network
```

Configure:

* stable hostname;
* DHCP reservation;
* SSH key access;
* automatic security updates;
* time synchronization;
* Docker Engine;
* Docker Compose plugin;
* firewall;
* Git checkout directory.

Suggested repository location:

```text
/opt/lantern
```

Suggested persistent data location:

```text
/srv/lantern
```

Acceptance criteria:

* Mac can SSH into Lantern Core;
* VM restarts cleanly;
* Docker starts automatically;
* VM receives the expected LAN IP;
* Windows reboot does not require manual container startup.

---

## Phase 3: DNS

Deploy Pi-hole.

Initially configure only the Mac to use Lantern DNS.

Create records for:

```text
lantern-core.home.arpa
windows.home.arpa
dashboard.home.arpa
status.home.arpa
```

Test using:

```bash
dig windows.home.arpa
dig dashboard.home.arpa
nslookup windows.home.arpa
```

After successful testing, configure the router DHCP DNS option to distribute Lantern Core as the DNS server.

Acceptance criteria:

* Mac resolves device names;
* Mac resolves service names;
* Internet DNS still works;
* DNS survives container restart;
* recovery procedure is documented.

---

## Phase 4: Reverse Proxy

Deploy Caddy over HTTP first.

Add:

```text
dashboard.home.arpa
status.home.arpa
```

Then proxy one existing Windows-hosted application.

Acceptance criteria:

* service names resolve correctly;
* Caddy can reach local Docker services;
* Caddy can reach a service hosted on Windows;
* direct application ports are no longer required for normal browser access;
* application logs preserve useful client information.

---

## Phase 5: Local HTTPS

Enable Caddy internal TLS.

Export the Lantern root certificate.

Install it on:

* Mac;
* Windows;
* other trusted clients as required.

Acceptance criteria:

* browser shows a trusted HTTPS connection;
* HTTP redirects to HTTPS;
* certificate lifecycle is documented;
* root CA private key is excluded from Git;
* encrypted backup includes the CA material.

---

## Phase 6: Dashboard and Monitoring

Deploy Homepage and Uptime Kuma.

Populate the dashboard from the service inventory.

Configure monitors for infrastructure and existing services.

Acceptance criteria:

* dashboard lists all active services;
* links use friendly domains;
* Uptime Kuma detects a deliberately stopped test service;
* monitoring state persists after restart.

---

## Phase 7: Remote Desktop

Deploy RustDesk Server OSS.

Install and configure RustDesk clients on:

* Mac;
* Windows.

Keep connectivity restricted to the LAN.

Acceptance criteria:

* Mac connects to Windows through the self-hosted RustDesk server;
* unattended access works;
* clipboard behavior is tested;
* multi-monitor behavior is documented;
* RustDesk server keys are backed up securely;
* access still works after service restart.

---

## Phase 8: Backup and Recovery

Implement encrypted backups to the external SSD.

Perform a test restore into a temporary directory or disposable environment.

Acceptance criteria:

* backup command is repeatable;
* secrets are encrypted;
* backup does not silently skip failed services;
* restore procedure is documented;
* a test restore has been completed.

---

## Phase 9: Hardening

Review:

* exposed ports;
* weak passwords;
* default credentials;
* container image versions;
* container privileges;
* Docker socket mounts;
* firewall rules;
* log retention;
* backup encryption;
* HTTPS trust;
* service authentication.

Acceptance criteria:

* no default credentials remain;
* no public router forwarding exists;
* administrative interfaces require authentication;
* sensitive backend ports are not unnecessarily exposed;
* all container versions are pinned.

---

# 19. Definition of Done

Lantern version one is complete when:

1. The Mac resolves `windows.home.arpa`.
2. SSH works using the hostname instead of the Windows IP.
3. At least one Windows-hosted web service is available through a friendly domain.
4. Browser-facing services no longer require remembered port numbers.
5. Caddy provides trusted local HTTPS.
6. Homepage lists the available local services.
7. Uptime Kuma monitors the core infrastructure.
8. RustDesk provides LAN-only remote desktop access from Mac to Windows.
9. Configuration is stored in Git.
10. Secrets and runtime state are excluded from Git.
11. Infrastructure survives Windows and VM restarts.
12. An encrypted backup can be created and restored.
13. No Lantern service is intentionally exposed to the public Internet.

---

# 20. Initial Service Naming

Use these initial names:

```text
lantern-core.home.arpa   Core infrastructure VM
windows.home.arpa        Windows host
dashboard.home.arpa      Homepage
status.home.arpa         Uptime Kuma
dns.home.arpa            Pi-hole administration
containers.home.arpa     Portainer
photos.home.arpa         Immich
elastic.home.arpa        Elasticsearch HTTP endpoint, only if needed
redis-ui.home.arpa       Redis Commander
remote.home.arpa         RustDesk-related UI, if deployed
```

Do not expose raw Redis through a web hostname.

Elasticsearch should require authentication and should not be broadly exposed merely because it has an HTTP interface.

---

# 21. Agent Execution Rules

The implementation agent must:

* inspect before modifying;
* preserve existing Windows services;
* avoid conflicting with occupied ports;
* never commit secrets;
* pin container versions;
* validate configuration before restarting services;
* create backups before modifying existing configuration;
* document every firewall rule;
* keep all initial access LAN-only;
* avoid router port forwarding;
* avoid introducing Kubernetes;
* prefer Docker Compose and small scripts;
* keep Git as the source of truth;
* make commits by implementation phase;
* update documentation whenever behavior changes.

The agent must not:

* expose services publicly;
* disable the Windows firewall;
* use `.local`;
* store credentials in Compose files;
* use `latest` image tags in the completed setup;
* overwrite existing services without discovery;
* move existing applications during version one unless necessary;
* introduce a custom web application for tasks already handled by the selected open-source tools.

---

# 22. Suggested Commit Sequence

```text
chore: initialize Lantern infrastructure repository
docs: record Windows and network discovery
feat: add Lantern Core VM bootstrap
feat: deploy local DNS with Pi-hole
feat: add Caddy reverse proxy
feat: enable local HTTPS
feat: add Homepage service dashboard
feat: add Uptime Kuma monitoring
feat: deploy self-hosted RustDesk server
feat: add encrypted backup and restore workflow
docs: complete operations and disaster recovery guides
chore: perform security hardening review
```

---

# 23. Future Scope

Do not implement these in version one, but preserve the ability to add them later:

* Tailscale, Headscale or WireGuard remote access
* Secondary DNS server
* Central log collection
* Prometheus and Grafana
* Automated certificate deployment
* Infrastructure configuration through Ansible
* UPS monitoring and graceful shutdown
* Network segmentation or VLANs
* Additional Linux hosts
* NAS migration
* Public domain with split-horizon DNS
* Identity-aware authentication gateway

The next major extension should be secure remote access through a VPN rather than exposing Caddy or RustDesk directly through router port forwarding.

---

# 24. First Agent Task

Start with Phase 0 only.

Inspect the Windows host and create:

```text
docs/discovery.md
inventory/devices.yaml
inventory/services.yaml
inventory/ports.md
```

Record:

* Windows edition;
* Windows hostname;
* current LAN IP;
* subnet and gateway;
* virtualization options;
* Docker and WSL status;
* running services;
* listening TCP and UDP ports;
* firewall status;
* current DNS;
* available disk locations;
* external SSD mount;
* SSH service status;
* RDP availability.

After discovery, propose the exact Lantern Core hosting method and network addresses.

Do not install or change anything during this first task.
