Set-StrictMode -Version 3.0

function Test-LivelyValidIntervalHours {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Hours
    )

    try {
        $value = [double]$Hours
    } catch {
        return $false
    }

    return -not ([double]::IsNaN($value) -or [double]::IsInfinity($value) -or $value -le 0)
}

function New-LivelyDefaultConfig {
    [CmdletBinding()]
    param()

    return [PSCustomObject]@{
        IntervalHours = 6.0
        WallFolder = ''
        Recursive = $false
        ShuffleEnabled = $true
        WelcomeTipShown = $false
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
        $needsSave = $false
        $config = Read-LivelyJsonFile -Path $paths.ConfigFile
        if ($null -eq $config) {
            $config = New-LivelyDefaultConfig
            Write-LivelyJsonFileAtomic -Path $paths.ConfigFile -InputObject $config
        }

        if (-not $config.PSObject.Properties.Match('IntervalHours')) {
            $config | Add-Member -NotePropertyName IntervalHours -NotePropertyValue 6.0
            $needsSave = $true
        } elseif (-not (Test-LivelyValidIntervalHours -Hours $config.IntervalHours)) {
            $config.IntervalHours = 6.0
            $needsSave = $true
        }

        if (-not $config.PSObject.Properties.Match('WallFolder')) {
            $config | Add-Member -NotePropertyName WallFolder -NotePropertyValue ''
            $needsSave = $true
        }

        if (-not $config.PSObject.Properties.Match('Recursive')) {
            $config | Add-Member -NotePropertyName Recursive -NotePropertyValue $false
            $needsSave = $true
        }

        if (-not $config.PSObject.Properties.Match('ShuffleEnabled')) {
            $config | Add-Member -NotePropertyName ShuffleEnabled -NotePropertyValue $true
            $needsSave = $true
        }

        if (-not $config.PSObject.Properties.Match('WelcomeTipShown')) {
            $config | Add-Member -NotePropertyName WelcomeTipShown -NotePropertyValue $false
            $needsSave = $true
        }

        if ($needsSave) {
            Write-LivelyJsonFileAtomic -Path $paths.ConfigFile -InputObject $config
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

Export-ModuleMember -Function Test-LivelyValidIntervalHours, New-LivelyDefaultConfig, Initialize-LivelyConfig, Get-LivelyConfig, Save-LivelyConfig
