Set-StrictMode -Version 3.0

function Get-LivelySupportedExtensions {
    [CmdletBinding()]
    param()

    return @('.jpg', '.jpeg', '.png', '.bmp', '.gif', '.webp')
}

function Get-LivelyWallpaperFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
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

function Get-LivelyNextWallpaperState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$AvailableFiles,

        [Parameter(Mandatory = $true)]
        $CurrentState,

        [switch]$ForceShuffle
    )

    if ($AvailableFiles.Count -eq 0) {
        return $null
    }

    $state = $CurrentState
    if ($null -eq $state) {
        $state = New-LivelyDefaultState
    }

    $availableSet = New-Object 'System.Collections.Generic.HashSet[string]' ([string[]]$AvailableFiles)
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
        $state = [PSCustomObject]@{
            Playlist = (Get-LivelyShuffledList -Items $AvailableFiles)
            Index = 0
            LastChanged = $state.LastChanged
            LastWallpaper = $state.LastWallpaper
        }
    }

    $nextIndex = [int]$state.Index
    if ($nextIndex -ge $state.Playlist.Count) {
        $state = [PSCustomObject]@{
            Playlist = (Get-LivelyShuffledList -Items $AvailableFiles)
            Index = 0
            LastChanged = $state.LastChanged
            LastWallpaper = $state.LastWallpaper
        }
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

Export-ModuleMember -Function Get-LivelySupportedExtensions, Get-LivelyWallpaperFiles, Get-LivelyShuffledList, Get-LivelyNextWallpaperState
