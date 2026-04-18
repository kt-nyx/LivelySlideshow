#requires -Version 5.1
[CmdletBinding()]
param()

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$modulesPath = Join-Path $PSScriptRoot 'Modules'
foreach ($moduleName in @('Paths', 'StoreUtils', 'Logging', 'ConfigStore', 'StateStore', 'Startup', 'Scheduler')) {
    Import-Module (Join-Path $modulesPath ($moduleName + '.psm1')) -Force
}

Initialize-LivelySlideshowData
Register-LivelySlideshowTask
Write-LivelyLog -Message 'Startup task registered.'
