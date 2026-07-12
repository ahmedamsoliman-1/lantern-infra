[CmdletBinding()]
param(
    [switch]$Watch,
    [switch]$Finalize
)

$ErrorActionPreference = 'Stop'
$jobName = 'Lantern Ubuntu ISO'
$isoPath = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\state\iso\ubuntu-24.04.4-live-server-amd64.iso'))
$expectedSha256 = 'e907d92eeec9df64163a7e454cbc8d7755e8ddc7ed42f99dbc80c40f1a138433'

do {
    $job = Get-BitsTransfer -Name $jobName -ErrorAction SilentlyContinue
    if (-not $job) {
        if (Test-Path -LiteralPath $isoPath) {
            $actual = (Get-FileHash -LiteralPath $isoPath -Algorithm SHA256).Hash.ToLowerInvariant()
            [pscustomobject]@{
                State = if ($actual -eq $expectedSha256) { 'Verified' } else { 'ChecksumFailed' }
                File = $isoPath
                SizeGiB = [math]::Round((Get-Item $isoPath).Length / 1GB, 2)
                Sha256 = $actual
            } | Format-List
            exit $(if ($actual -eq $expectedSha256) { 0 } else { 1 })
        }
        throw "No BITS job named '$jobName' and no completed ISO were found."
    }

    $percent = if ($job.BytesTotal -gt 0 -and $job.BytesTotal -lt [uint64]::MaxValue) {
        [math]::Round(100 * $job.BytesTransferred / $job.BytesTotal, 1)
    } else { 0 }

    [pscustomobject]@{
        State = $job.JobState
        Progress = "$percent%"
        TransferredGiB = [math]::Round($job.BytesTransferred / 1GB, 2)
        TotalGiB = if ($job.BytesTotal -lt [uint64]::MaxValue) { [math]::Round($job.BytesTotal / 1GB, 2) } else { 'unknown' }
        Error = $job.ErrorDescription
    } | Format-List

    if ($Finalize) {
        if ($job.JobState -ne 'Transferred') {
            throw "Download is '$($job.JobState)', not ready to finalize."
        }
        Complete-BitsTransfer -BitsJob $job
        $actual = (Get-FileHash -LiteralPath $isoPath -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($actual -ne $expectedSha256) {
            throw "Checksum failed. Expected $expectedSha256, received $actual."
        }
        Write-Host "Verified ISO: $isoPath"
        exit 0
    }

    if ($Watch -and $job.JobState -notin @('Transferred', 'Error', 'Cancelled')) {
        Start-Sleep -Seconds 10
    }
} while ($Watch -and $job.JobState -notin @('Transferred', 'Error', 'Cancelled'))

if ($job.JobState -eq 'Transferred') {
    Write-Host 'Download finished. Finalize and verify with:'
    Write-Host '  .\scripts\ubuntu-download-status.ps1 -Finalize'
}
