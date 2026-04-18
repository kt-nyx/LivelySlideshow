Set-StrictMode -Version 3.0

function Get-LivelySlideshowPaths {
    [CmdletBinding()]
    param()

    $modulesDir = $PSScriptRoot
    $scriptsDir = Split-Path -Parent $modulesDir
    $appDir = Split-Path -Parent $scriptsDir
    $installRoot = Split-Path -Parent $appDir
    $dataDir = Join-Path $installRoot 'data'
    $logDir = Join-Path $dataDir 'logs'

    return [PSCustomObject]@{
        InstallRoot = $installRoot
        AppDir = $appDir
        ScriptsDir = $scriptsDir
        ModulesDir = $modulesDir
        DataDir = $dataDir
        LogDir = $logDir
        ConfigFile = Join-Path $dataDir 'config.json'
        StateFile = Join-Path $dataDir 'state.json'
        LogFile = Join-Path $logDir 'LivelySlideshow.log'
        LivelyCUPath = Join-Path $appDir 'livelycu.exe'
        HiddenLauncher = Join-Path $scriptsDir 'LaunchHidden.vbs'
        IconPath = Join-Path $installRoot 'tray.ico'
        TaskName = 'LivelySlideshow'
        ProductName = 'LivelySlideshow'
        SupportUrl = 'https://github.com/rocksdanister/lively'
    }
}

function Get-LivelyDefaultWallpaperFolder {
    [CmdletBinding()]
    param()

    return [Environment]::GetFolderPath('MyPictures')
}

Export-ModuleMember -Function Get-LivelySlideshowPaths, Get-LivelyDefaultWallpaperFolder
