#requires -Version 5.1
[CmdletBinding()]
param()

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$modulesPath = Join-Path $PSScriptRoot 'Modules'
foreach ($moduleName in @('Paths', 'Logging', 'Scheduler')) {
    Import-Module (Join-Path $modulesPath ($moduleName + '.psm1')) -Force
}

Unregister-LivelySlideshowTask
Write-LivelyLog -Message 'Startup task unregistered.'
