[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$VmName = 'lantern-core',
    [string]$SwitchName = 'Lantern External Wi-Fi',
    [string]$AdapterName = 'Wi-Fi',
    [string]$IsoPath,
    [string]$VmRoot = 'C:\ProgramData\Lantern\Hyper-V',
    [uint64]$StartupMemoryBytes = 1GB,
    [uint64]$MinimumMemoryBytes = 768MB,
    [uint64]$MaximumMemoryBytes = 4GB
)

$ErrorActionPreference = 'Stop'
$IsoPath = if ($IsoPath) { $IsoPath } else {
    Join-Path $PSScriptRoot '..\state\iso\ubuntu-24.04.4-live-server-amd64.iso'
}

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Run this script from PowerShell as Administrator.'
}

$IsoPath = [IO.Path]::GetFullPath($IsoPath)
if (-not (Test-Path -LiteralPath $IsoPath -PathType Leaf)) {
    throw "Ubuntu ISO not found: $IsoPath"
}

$expectedSha256 = 'e907d92eeec9df64163a7e454cbc8d7755e8ddc7ed42f99dbc80c40f1a138433'
$actualSha256 = (Get-FileHash -LiteralPath $IsoPath -Algorithm SHA256).Hash.ToLowerInvariant()
if ($actualSha256 -ne $expectedSha256) {
    throw "Ubuntu ISO checksum mismatch. Expected $expectedSha256, got $actualSha256"
}

Import-Module Hyper-V
$adapter = Get-NetAdapter -Name $AdapterName -ErrorAction Stop
if ($adapter.Status -ne 'Up') {
    throw "Network adapter '$AdapterName' is not up."
}

$switch = Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue
if (-not $switch) {
    Write-Warning 'Creating an external switch may briefly interrupt Wi-Fi connectivity.'
    if ($PSCmdlet.ShouldProcess($AdapterName, "Create external Hyper-V switch '$SwitchName'")) {
        $switch = New-VMSwitch -Name $SwitchName -NetAdapterName $AdapterName -AllowManagementOS $true
    }
} elseif ($switch.SwitchType -ne 'External') {
    throw "A non-external switch named '$SwitchName' already exists."
}

$vm = Get-VM -Name $VmName -ErrorAction SilentlyContinue
if (-not $vm) {
    $vmPath = Join-Path $VmRoot $VmName
    $vhdPath = Join-Path $vmPath "$VmName.vhdx"
    if ($PSCmdlet.ShouldProcess($vmPath, "Create Generation 2 VM '$VmName'")) {
        New-Item -ItemType Directory -Force -Path $vmPath | Out-Null
        $vm = New-VM -Name $VmName -Generation 2 -MemoryStartupBytes $StartupMemoryBytes `
            -NewVHDPath $vhdPath -NewVHDSizeBytes 40GB -Path $VmRoot `
            -SwitchName $SwitchName
        Add-VMDvdDrive -VMName $VmName -Path $IsoPath
        $dvd = Get-VMDvdDrive -VMName $VmName
        Set-VMFirmware -VMName $VmName -FirstBootDevice $dvd
    }
} else {
    Write-Host "VM '$VmName' already exists; preserving it."
}

if ((Get-VM -Name $VmName).State -eq 'Off') {
    Set-VMProcessor -VMName $VmName -Count 2
    Set-VMMemory -VMName $VmName -DynamicMemoryEnabled $true `
        -StartupBytes $StartupMemoryBytes -MinimumBytes $MinimumMemoryBytes `
        -MaximumBytes $MaximumMemoryBytes
    Set-VMFirmware -VMName $VmName -EnableSecureBoot On `
        -SecureBootTemplate MicrosoftUEFICertificateAuthority
    Set-VM -Name $VmName -AutomaticStartAction Start -AutomaticStartDelay 30 `
        -AutomaticStopAction ShutDown -CheckpointType ProductionOnly
} else {
    Write-Host "VM '$VmName' is running; preserving its active hardware settings."
}

Get-VM -Name $VmName | Select-Object Name, State, Generation, ProcessorCount,
    DynamicMemoryEnabled,
    @{Name='StartupMemoryGiB';Expression={[math]::Round($_.MemoryStartup/1GB, 1)}},
    @{Name='MinimumMemoryGiB';Expression={[math]::Round($_.MemoryMinimum/1GB, 1)}},
    @{Name='MaximumMemoryGiB';Expression={[math]::Round($_.MemoryMaximum/1GB, 1)}},
    AutomaticStartAction, Path | Format-List
Get-VMNetworkAdapter -VMName $VmName | Select-Object VMName, SwitchName, MacAddress,
    Status, IPAddresses | Format-List

if ((Get-VM -Name $VmName).State -eq 'Off' -and
    $PSCmdlet.ShouldProcess($VmName, 'Start VM')) {
    try {
        Start-VM -Name $VmName | Out-Null
    } catch {
        throw "VM configuration is complete but startup failed: $($_.Exception.Message) Close memory-heavy applications and rerun this script."
    }
}

Write-Host "Lantern VM is ready. Open it with: vmconnect.exe localhost $VmName"
