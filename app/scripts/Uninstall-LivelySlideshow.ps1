#requires -Version 5.1
[CmdletBinding()]
param()

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$modulesPath = Join-Path $PSScriptRoot 'Modules'
foreach ($moduleName in @('Paths', 'Logging', 'Scheduler')) {
    Import-Module (Join-Path $modulesPath ($moduleName + '.psm1')) -Force
}

function Stop-LivelySlideshowProcesses {
    [CmdletBinding()]
    param()

    $paths = Get-LivelySlideshowPaths
    $escapedRoot = [Regex]::Escape($paths.InstallRoot)

    $processes = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
        Where-Object {
            $_.ProcessId -ne $PID -and
            $_.Name -match '^(powershell|pwsh|wscript)\.exe$' -and
            $_.CommandLine -match $escapedRoot
        }

    foreach ($process in $processes) {
        try {
            Stop-Process -Id $process.ProcessId -Force -ErrorAction Stop
            Write-LivelyLog -Message ("Stopped process {0} ({1})." -f $process.Name, $process.ProcessId)
        } catch {
            Write-LivelyLogError -Context ("Failed to stop process {0} ({1})" -f $process.Name, $process.ProcessId) -ErrorRecord $_
        }
    }
}

$paths = Get-LivelySlideshowPaths

try {
    Stop-ScheduledTask -TaskName $paths.TaskName -ErrorAction SilentlyContinue
} catch {
    Write-LivelyLogError -Context 'Failed to stop scheduled task during uninstall' -ErrorRecord $_
}

Stop-LivelySlideshowProcesses
Unregister-LivelySlideshowTask
Write-LivelyLog -Message 'LivelySlideshow uninstall cleanup completed.'
