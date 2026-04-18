#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$DestinationPath
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$logPath = Join-Path $env:TEMP 'LivelySlideshow-Download-LivelyCU.log'

function Write-DownloadLog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    $line = '[{0}] {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    Add-Content -LiteralPath $logPath -Value $line -Encoding UTF8
}

$pinnedVersion = 'v2.0.4.0'
$downloadUrl = 'https://github.com/rocksdanister/lively/releases/download/v2.0.4.0/lively_command_utility.zip'
$scratchDir = Join-Path $env:TEMP ('LivelySlideshow-' + [guid]::NewGuid().ToString('N'))
$zipPath = Join-Path $scratchDir 'lively_command_utility.zip'

try {
    try {
        New-Item -ItemType Directory -Path $scratchDir -Force | Out-Null
        Write-DownloadLog "Starting livelycu.exe install to $DestinationPath"

        if (Test-Path -LiteralPath $DestinationPath) {
            Write-DownloadLog 'Destination already contains livelycu.exe; skipping download.'
            Write-Host "livelycu.exe already present at $DestinationPath"
            exit 0
        }

        Write-DownloadLog "Downloading package from $downloadUrl"
        Write-Host "Downloading livelycu.exe package ($pinnedVersion)..."
        Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath

        Write-DownloadLog "Extracting archive $zipPath"
        Write-Host 'Extracting livelycu.exe...'
        Expand-Archive -LiteralPath $zipPath -DestinationPath $scratchDir -Force

        $binaryPath = Join-Path $scratchDir 'Livelycu.exe'
        if (-not (Test-Path -LiteralPath $binaryPath)) {
            throw 'The lively command utility archive did not contain Livelycu.exe.'
        }

        $destinationDir = Split-Path -Parent $DestinationPath
        New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
        Copy-Item -LiteralPath $binaryPath -Destination $DestinationPath -Force
        Write-DownloadLog "Installed livelycu.exe to $DestinationPath"
        Write-Host "Installed livelycu.exe to $DestinationPath"
        exit 0
    } catch {
        Write-DownloadLog ("ERROR: {0}" -f $_.Exception.ToString())
        Write-Error ("Failed to download or install livelycu.exe: {0}" -f $_.Exception.Message)
        exit 1
    }
} finally {
    Write-DownloadLog 'Cleaning up temporary download directory.'
    Remove-Item -LiteralPath $scratchDir -Recurse -Force -ErrorAction SilentlyContinue
}
