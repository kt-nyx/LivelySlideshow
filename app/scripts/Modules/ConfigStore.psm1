Set-StrictMode -Version 3.0

function New-LivelyDefaultConfig {
    [CmdletBinding()]
    param()

    return [PSCustomObject]@{
        IntervalHours = 6.0
        WallFolder = Get-LivelyDefaultWallpaperFolder
        Recursive = $false
    }
}

function Initialize-LivelyConfig {
    [CmdletBinding()]
    param()

    $paths = Get-LivelySlideshowPaths
    Invoke-WithLivelyMutex -Name 'Config' -ScriptBlock {
        if (-not (Test-Path -LiteralPath $paths.ConfigFile)) {
            Write-LivelyJsonFileAtomic -Path $paths.ConfigFile -InputObject (New-LivelyDefaultConfig)
        }
    }
}

function Get-LivelyConfig {
    [CmdletBinding()]
    param()

    $paths = Get-LivelySlideshowPaths
    return Invoke-WithLivelyMutex -Name 'Config' -ScriptBlock {
        $config = Read-LivelyJsonFile -Path $paths.ConfigFile
        if ($null -eq $config) {
            $config = New-LivelyDefaultConfig
            Write-LivelyJsonFileAtomic -Path $paths.ConfigFile -InputObject $config
        }

        if (-not $config.PSObject.Properties.Match('IntervalHours')) {
            $config | Add-Member -NotePropertyName IntervalHours -NotePropertyValue 6.0
        }

        if (-not $config.PSObject.Properties.Match('WallFolder')) {
            $config | Add-Member -NotePropertyName WallFolder -NotePropertyValue (Get-LivelyDefaultWallpaperFolder)
        }

        if (-not $config.PSObject.Properties.Match('Recursive')) {
            $config | Add-Member -NotePropertyName Recursive -NotePropertyValue $false
        }

        return $config
    }
}

function Save-LivelyConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Config
    )

    $paths = Get-LivelySlideshowPaths
    Invoke-WithLivelyMutex -Name 'Config' -ScriptBlock {
        Write-LivelyJsonFileAtomic -Path $paths.ConfigFile -InputObject $Config
    }
}

Export-ModuleMember -Function New-LivelyDefaultConfig, Initialize-LivelyConfig, Get-LivelyConfig, Save-LivelyConfig
