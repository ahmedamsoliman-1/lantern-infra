[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^192\.168\.(?:\d{1,3})\.(?:\d{1,3})$')]
    [string]$CoreAddress,

    [string]$User = 'ahmed',

    [string]$RemoteArchive = '/tmp/lantern-update.tar.gz'
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$archive = Join-Path $env:TEMP 'lantern-update.tar.gz'

Push-Location $repoRoot
try {
    & tar.exe -czf $archive `
        --exclude=.git `
        --exclude=.env `
        --exclude=secrets `
        --exclude=state `
        --exclude=temp `
        --exclude=services/homepage/logs `
        --exclude=services/rustdesk/data `
        .
    if ($LASTEXITCODE -ne 0) {
        throw "tar.exe failed with exit code $LASTEXITCODE"
    }

    & scp.exe $archive "${User}@${CoreAddress}:$RemoteArchive"
    if ($LASTEXITCODE -ne 0) {
        throw "scp.exe failed with exit code $LASTEXITCODE"
    }
}
finally {
    Pop-Location
}

$hash = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash
Write-Host "Transferred validated snapshot to ${User}@${CoreAddress}:$RemoteArchive"
Write-Host "Local archive SHA-256: $hash"
Write-Host
Write-Host 'Apply it on Lantern Core with:'
Write-Host "  sudo tar -xzf $RemoteArchive -C /opt/lantern"
Write-Host '  cd /opt/lantern'
Write-Host '  sudo chmod +x scripts/*.sh'
