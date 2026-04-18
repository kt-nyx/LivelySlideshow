Set-StrictMode -Version 3.0

function New-LivelyDefaultState {
    [CmdletBinding()]
    param()

    return [PSCustomObject]@{
        Playlist = @()
        Index = 0
        LastChanged = $null
        LastWallpaper = $null
    }
}

function Initialize-LivelyState {
    [CmdletBinding()]
    param()

    $paths = Get-LivelySlideshowPaths
    Invoke-WithLivelyMutex -Name 'State' -ScriptBlock {
        if (-not (Test-Path -LiteralPath $paths.StateFile)) {
            Write-LivelyJsonFileAtomic -Path $paths.StateFile -InputObject (New-LivelyDefaultState)
        }
    }
}

function Get-LivelyState {
    [CmdletBinding()]
    param()

    $paths = Get-LivelySlideshowPaths
    return Invoke-WithLivelyMutex -Name 'State' -ScriptBlock {
        $state = Read-LivelyJsonFile -Path $paths.StateFile
        if ($null -eq $state) {
            $state = New-LivelyDefaultState
            Write-LivelyJsonFileAtomic -Path $paths.StateFile -InputObject $state
        }

        if (-not $state.PSObject.Properties.Match('Playlist')) {
            $state | Add-Member -NotePropertyName Playlist -NotePropertyValue @()
        }

        if (-not $state.PSObject.Properties.Match('Index')) {
            $state | Add-Member -NotePropertyName Index -NotePropertyValue 0
        }

        if (-not $state.PSObject.Properties.Match('LastChanged')) {
            $state | Add-Member -NotePropertyName LastChanged -NotePropertyValue $null
        }

        if (-not $state.PSObject.Properties.Match('LastWallpaper')) {
            $state | Add-Member -NotePropertyName LastWallpaper -NotePropertyValue $null
        }

        return $state
    }
}

function Save-LivelyState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $State
    )

    $paths = Get-LivelySlideshowPaths
    Invoke-WithLivelyMutex -Name 'State' -ScriptBlock {
        Write-LivelyJsonFileAtomic -Path $paths.StateFile -InputObject $State
    }
}

function Reset-LivelyState {
    [CmdletBinding()]
    param()

    $state = New-LivelyDefaultState
    Save-LivelyState -State $state
    return $state
}

Export-ModuleMember -Function New-LivelyDefaultState, Initialize-LivelyState, Get-LivelyState, Save-LivelyState, Reset-LivelyState
