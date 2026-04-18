Set-StrictMode -Version 3.0

function Get-LivelyInstallCandidates {
    [CmdletBinding()]
    param()

    $localPrograms = Join-Path $env:LOCALAPPDATA 'Programs\Lively Wallpaper'
    $storeBase = Join-Path $env:LOCALAPPDATA 'Packages'

    $candidates = @(
        (Join-Path $localPrograms 'Lively.exe'),
        (Join-Path $localPrograms 'lively.exe'),
        (Join-Path $localPrograms 'Livelywpf.exe'),
        (Join-Path $localPrograms 'livelywpf.exe')
    )

    if (Test-Path -LiteralPath $storeBase) {
        $storeMatches = Get-ChildItem -LiteralPath $storeBase -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like '12030rocksdanister.LivelyWallpaper*' }
        foreach ($match in $storeMatches) {
            $candidates += (Join-Path $match.FullName 'LocalCache\Local\Lively Wallpaper')
        }
    }

    return @($candidates | Select-Object -Unique)
}

function Get-LivelyInstallation {
    [CmdletBinding()]
    param()

    foreach ($candidate in Get-LivelyInstallCandidates) {
        if (Test-Path -LiteralPath $candidate) {
            return [PSCustomObject]@{
                IsInstalled = $true
                Path = $candidate
            }
        }
    }

    return [PSCustomObject]@{
        IsInstalled = $false
        Path = $null
    }
}

function Test-LivelyInstalled {
    [CmdletBinding()]
    param()

    return [bool](Get-LivelyInstallation).IsInstalled
}

function Test-LivelyRunning {
    [CmdletBinding()]
    param()

    $process = Get-Process -Name 'Lively', 'lively', 'Livelywpf', 'livelywpf' -ErrorAction SilentlyContinue |
        Select-Object -First 1
    return $null -ne $process
}

function Get-LivelyMissingDependencyMessage {
    [CmdletBinding()]
    param(
        [switch]$CommandUtilityOnly
    )

    $paths = Get-LivelySlideshowPaths
    if ($CommandUtilityOnly) {
        return "LivelySlideshow could not find livelycu.exe in `"$($paths.AppDir)`". Reinstall LivelySlideshow to restore the command utility."
    }

    return "Lively Wallpaper is required. Install it from $($paths.SupportUrl), then launch Lively Wallpaper and try again."
}

function Set-LivelyWallpaper {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    $paths = Get-LivelySlideshowPaths
    $livelyCU = $paths.LivelyCUPath

    if (-not (Test-Path -LiteralPath $FilePath)) {
        throw "Wallpaper file does not exist: $FilePath"
    }

    if (-not (Test-Path -LiteralPath $livelyCU)) {
        throw (Get-LivelyMissingDependencyMessage -CommandUtilityOnly)
    }

    if (-not (Test-LivelyInstalled)) {
        throw (Get-LivelyMissingDependencyMessage)
    }

    Write-LivelyLog -Message ('Setting wallpaper via livelycu.exe: {0}' -f (Split-Path -Leaf $FilePath))

    $process = Start-Process -FilePath $livelyCU `
        -ArgumentList @('setwp', '--file', $FilePath) `
        -WindowStyle Hidden `
        -PassThru `
        -Wait `
        -ErrorAction Stop

    if ($process.ExitCode -ne 0) {
        throw "livelycu.exe exited with code $($process.ExitCode)."
    }

    return $true
}

Export-ModuleMember -Function Get-LivelyInstallation, Test-LivelyInstalled, Test-LivelyRunning, Get-LivelyMissingDependencyMessage, Set-LivelyWallpaper
