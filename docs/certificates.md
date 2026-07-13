# Local certificates

Phase 5 enables Caddy's internal certificate authority for every browser-facing
Lantern hostname. Named HTTP requests redirect to HTTPS. The changing hotspot
IP remains an HTTP-only emergency dashboard fallback and is not issued a local
certificate.

## Current status

Named HTTPS routes and HTTP redirects were deployed successfully on 2026-07-12.
The Caddy root CA was exported and installed in both the Windows user and machine
root stores. Windows Schannel validates the chain when invoked with
`--ssl-no-revoke`, but Chromium continues to show a local-authority warning.
Phase 5 therefore remains operational but not fully accepted; users should not
normalize bypassing the warning. This trust issue is deferred while LAN-only
monitoring work continues.

The guarded deployment exports only the public root certificate to:

```text
/opt/lantern/state/certificates/lantern-root-ca.crt
```

The CA private key stays in Caddy's persistent data volume, is excluded from
Git, and must be included only in encrypted backups.

## Deploy

After transferring the current repository snapshot to Lantern Core:

```sh
cd /opt/lantern
chmod +x scripts/*.sh
sudo make deploy-https
```

The script validates every HTTPS route with the exported CA, verifies the HTTP
redirect, and opens UFW TCP port 443 only after all tests pass.

## Trust on Windows

Copy the public certificate from Lantern Core:

```powershell
scp ahmed@192.168.202.253:/opt/lantern/state/certificates/lantern-root-ca.crt $env:TEMP\lantern-root-ca.crt
certutil -hashfile $env:TEMP\lantern-root-ca.crt SHA256
Import-Certificate -FilePath $env:TEMP\lantern-root-ca.crt -CertStoreLocation Cert:\CurrentUser\Root
```

Compare the SHA-256 output with the value printed by `make deploy-https` before
trusting the certificate. Install it only on trusted devices.

To remove trust later:

```powershell
Get-ChildItem Cert:\CurrentUser\Root |
  Where-Object Subject -Like '*Caddy Local Authority*' |
  Remove-Item
```
