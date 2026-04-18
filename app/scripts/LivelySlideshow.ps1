#requires -Version 5.1
[CmdletBinding()]
param()

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$modulesPath = Join-Path $PSScriptRoot 'Modules'
$moduleNames = @(
    'Paths',
    'StoreUtils',
    'Logging',
    'ConfigStore',
    'StateStore',
    'PlaylistService',
    'LivelyClient',
    'Startup',
    'TrayApp'
)

foreach ($moduleName in $moduleNames) {
    Import-Module (Join-Path $modulesPath ($moduleName + '.psm1')) -Force
}

Initialize-LivelySlideshowData
$mutex = Acquire-LivelySingleton
if ($null -eq $mutex) {
    Show-LivelyUserMessage -Message 'LivelySlideshow is already running.' -Icon Info
    exit 0
}

try {
    Write-LivelyLog -Message 'Starting tray application.'
    Start-LivelySlideshowTrayApp
} catch {
    Write-LivelyLogError -Context 'Fatal application error' -ErrorRecord $_
    Show-LivelyUserMessage -Message $_.Exception.Message -Icon Error
    exit 1
} finally {
    if ($mutex) {
        try {
            [void]$mutex.ReleaseMutex()
        } catch {
        }

        $mutex.Dispose()
    }
}
