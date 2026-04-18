Set-StrictMode -Version 3.0

function Get-LivelySupportedExtensions {
    [CmdletBinding()]
    param()

    return @('.jpg', '.jpeg', '.png', '.bmp', '.gif', '.webp')
}

function Get-LivelyWallpaperFiles {
    [CmdletBinding()]
    param(
        [AllowEmptyString()]
        [string]$Folder,

        [bool]$Recursive = $false
    )

    if ([string]::IsNullOrWhiteSpace($Folder) -or -not (Test-Path -LiteralPath $Folder)) {
        return @()
    }

    $params = @{
        LiteralPath = $Folder
        File = $true
        ErrorAction = 'SilentlyContinue'
    }

    if ($Recursive) {
        $params.Recurse = $true
    }

    $extensions = Get-LivelySupportedExtensions
    $items = Get-ChildItem @params | Where-Object { $extensions -contains $_.Extension.ToLowerInvariant() }
    return @($items | ForEach-Object { $_.FullName })
}

function Get-LivelyShuffledList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Items
    )

    if ($Items.Count -le 1) {
        return @($Items)
    }

    $shuffled = [string[]]$Items.Clone()
    for ($i = $shuffled.Count - 1; $i -gt 0; $i--) {
        $swapIndex = Get-Random -Minimum 0 -Maximum ($i + 1)
        $temp = $shuffled[$i]
        $shuffled[$i] = $shuffled[$swapIndex]
        $shuffled[$swapIndex] = $temp
    }

    return $shuffled
}

function Get-LivelyOrderedList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Items
    )

    return @($Items | Sort-Object)
}

function Get-LivelyPlaylist {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Items,

        [bool]$ShuffleEnabled = $true
    )

    if ($ShuffleEnabled) {
        return Get-LivelyShuffledList -Items $Items
    }

    return Get-LivelyOrderedList -Items $Items
}

function Get-LivelyResyncedState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$AvailableFiles,

        [Parameter(Mandatory = $true)]
        $CurrentState,

        [bool]$ShuffleEnabled = $true,

        [switch]$KeepCurrentWallpaper
    )

    $playlist = @(Get-LivelyPlaylist -Items $AvailableFiles -ShuffleEnabled $ShuffleEnabled)
    $lastWallpaper = if ($null -ne $CurrentState) { [string]$CurrentState.LastWallpaper } else { $null }
    $lastChanged = if ($null -ne $CurrentState) { $CurrentState.LastChanged } else { $null }

    if ($KeepCurrentWallpaper -and -not [string]::IsNullOrWhiteSpace($lastWallpaper) -and ($playlist -contains $lastWallpaper)) {
        $remaining = @($playlist | Where-Object { $_ -ne $lastWallpaper })
        return [PSCustomObject]@{
            Playlist = @($lastWallpaper) + $remaining
            Index = 1
            LastChanged = $lastChanged
            LastWallpaper = $lastWallpaper
        }
    }

    return [PSCustomObject]@{
        Playlist = $playlist
        Index = 0
        LastChanged = $lastChanged
        LastWallpaper = $lastWallpaper
    }
}

function Get-LivelyNextWallpaperState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$AvailableFiles,

        [Parameter(Mandatory = $true)]
        $CurrentState,

        [bool]$ShuffleEnabled = $true,

        [switch]$ForceShuffle
    )

    if ($AvailableFiles.Count -eq 0) {
        return $null
    }

    $state = $CurrentState
    if ($null -eq $state) {
        $state = New-LivelyDefaultState
    }

    $availableSet = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($availableFile in $AvailableFiles) {
        [void]$availableSet.Add([string]$availableFile)
    }
    $needShuffle = $ForceShuffle.IsPresent

    if (-not $needShuffle) {
        if (-not $state.Playlist -or $state.Index -ge $state.Playlist.Count) {
            $needShuffle = $true
        } elseif ($state.Playlist.Count -ne $availableSet.Count) {
            $needShuffle = $true
        } else {
            foreach ($entry in $state.Playlist) {
                if (-not $availableSet.Contains([string]$entry)) {
                    $needShuffle = $true
                    break
                }
            }
        }
    }

    if ($needShuffle) {
        $state = Get-LivelyResyncedState -AvailableFiles $AvailableFiles -CurrentState $state -ShuffleEnabled $ShuffleEnabled
    }

    $nextIndex = [int]$state.Index
    if ($nextIndex -ge $state.Playlist.Count) {
        $state = Get-LivelyResyncedState -AvailableFiles $AvailableFiles -CurrentState $state -ShuffleEnabled $ShuffleEnabled
        $nextIndex = 0
    }

    $wallpaper = [string]$state.Playlist[$nextIndex]
    $newState = [PSCustomObject]@{
        Playlist = @($state.Playlist)
        Index = ($nextIndex + 1)
        LastChanged = (Get-Date).ToString('o')
        LastWallpaper = $wallpaper
    }

    return [PSCustomObject]@{
        Wallpaper = $wallpaper
        State = $newState
        Total = $state.Playlist.Count
    }
}

Export-ModuleMember -Function Get-LivelySupportedExtensions, Get-LivelyWallpaperFiles, Get-LivelyShuffledList, Get-LivelyOrderedList, Get-LivelyPlaylist, Get-LivelyResyncedState, Get-LivelyNextWallpaperState
