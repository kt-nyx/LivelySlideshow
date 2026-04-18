Set-StrictMode -Version 3.0

function Start-LivelySlideshowTrayApp {
    [CmdletBinding()]
    param()

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    [System.Windows.Forms.Application]::EnableVisualStyles()
    [System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

    $script:warnedMissingLively = $false
    $script:warnedMissingCommandUtility = $false
    $script:isChangingWallpaper = $false
    $script:intervalOptions = [ordered]@{
        '30 minutes' = 0.5
        '1 hour' = 1.0
        '6 hours' = 6.0
        '12 hours' = 12.0
        '24 hours' = 24.0
    }

    function Show-FirstRunTipIfNeeded {
        $config = Get-LivelyConfig
        if (-not [string]::IsNullOrWhiteSpace([string]$config.WallFolder)) {
            return
        }

        if ([bool]$config.WelcomeTipShown) {
            return
        }

        $script:tray.BalloonTipTitle = 'LivelySlideshow installed'
        $script:tray.BalloonTipText = 'Right-click the tray icon and choose Folder > Choose folder... to get started.'
        $script:tray.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
        $script:tray.ShowBalloonTip(12000)

        $config.WelcomeTipShown = $true
        Save-LivelyConfig -Config $config
    }

    function Get-CurrentConfigState {
        return [PSCustomObject]@{
            Config = Get-LivelyConfig
            State = Get-LivelyState
        }
    }

    function Get-LastChangedDate($State) {
        if ($null -eq $State -or [string]::IsNullOrWhiteSpace([string]$State.LastChanged)) {
            return $null
        }

        try {
            return [datetime]::Parse($State.LastChanged, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::RoundtripKind)
        } catch {
            Write-LivelyLogError -Context 'Failed to parse LastChanged value' -ErrorRecord $_
            return $null
        }
    }

    function Test-FolderHasSupportedFiles {
        param(
            [string]$Folder,
            [bool]$Recursive
        )

        return (@(Get-LivelyWallpaperFiles -Folder $Folder -Recursive $Recursive)).Count -gt 0
    }

    function Show-DependencyWarning {
        if (-not (Test-Path -LiteralPath (Get-LivelySlideshowPaths).LivelyCUPath)) {
            if (-not $script:warnedMissingCommandUtility) {
                $script:warnedMissingCommandUtility = $true
                $message = Get-LivelyMissingDependencyMessage -CommandUtilityOnly
                Write-LivelyLog -Level ERROR -Message $message
                Show-LivelyUserMessage -Message $message -Icon Error
            }

            return
        }

        if (-not (Test-LivelyInstalled) -and -not $script:warnedMissingLively) {
            $script:warnedMissingLively = $true
            $message = Get-LivelyMissingDependencyMessage
            Write-LivelyLog -Level WARN -Message $message
            Show-LivelyUserMessage -Message $message -Icon Warning
        }
    }

    function Update-MenuText {
        $snapshot = Get-CurrentConfigState
        $config = $snapshot.Config
        $state = $snapshot.State
        $fileCount = (@(Get-LivelyWallpaperFiles -Folder $config.WallFolder -Recursive $config.Recursive)).Count

        $folderName = if ([string]::IsNullOrWhiteSpace($config.WallFolder)) { 'Not set' } else { Split-Path -Leaf $config.WallFolder }
        if ([string]::IsNullOrWhiteSpace($folderName)) {
            $folderName = $config.WallFolder
        }

        $script:miFolder.Text = 'Folder: {0}{1}' -f $folderName, $(if ($config.Recursive) { ' [+subs]' } else { '' })
        $script:miRecursive.Checked = [bool]$config.Recursive
        $script:miShuffle.Checked = [bool]$config.ShuffleEnabled
        $script:miShuffle.Text = if ($config.ShuffleEnabled) { 'Shuffle: On' } else { 'Shuffle: Off' }
        $script:miFileCount.Text = 'Files found: {0}' -f $fileCount
        $script:miCurrentFolder.Text = if ([string]::IsNullOrWhiteSpace([string]$config.WallFolder)) { 'No folder selected' } else { $config.WallFolder }

        foreach ($item in $script:miInterval.DropDownItems) {
            if ($item -is [System.Windows.Forms.ToolStripMenuItem]) {
                $item.Checked = ([double]$item.Tag -eq [double]$config.IntervalHours)
            }
        }

        $script:miInterval.Text = 'Interval: {0}' -f (Get-IntervalLabel -Hours ([double]$config.IntervalHours))

        if ($state.LastWallpaper) {
            $trayText = 'LivelySlideshow - {0}' -f (Split-Path -Leaf ([string]$state.LastWallpaper))
            if ($trayText.Length -gt 63) {
                $trayText = $trayText.Substring(0, 63)
            }
            $script:tray.Text = $trayText
        } else {
            $script:tray.Text = 'LivelySlideshow'
        }
    }

    function Get-IntervalLabel {
        param([double]$Hours)

        foreach ($item in $script:intervalOptions.GetEnumerator()) {
            if ([double]$item.Value -eq $Hours) {
                return $item.Key
            }
        }

        return ('{0} hours' -f $Hours)
    }

    function Update-CountdownText {
        $snapshot = Get-CurrentConfigState
        $config = $snapshot.Config
        $state = $snapshot.State
        $lastChanged = Get-LastChangedDate -State $state

        if ([string]::IsNullOrWhiteSpace([string]$config.WallFolder)) {
            $script:miCountdown.Text = 'Next change: choose a folder to start'
            return
        }

        if ($null -eq $lastChanged) {
            $script:miCountdown.Text = 'Next change: waiting for first wallpaper'
            return
        }

        $nextChange = $lastChanged.AddHours([double]$config.IntervalHours)
        $remaining = $nextChange - (Get-Date)

        if ($remaining.TotalSeconds -le 0) {
            $script:miCountdown.Text = 'Next change: due now'
            return
        }

        $script:miCountdown.Text = 'Next change in {0:D2}:{1:D2}:{2:D2}' -f `
            [int][math]::Floor($remaining.TotalHours), `
            [int]$remaining.Minutes, `
            [int]$remaining.Seconds
    }

    function Test-ChangeDue {
        $snapshot = Get-CurrentConfigState
        $config = $snapshot.Config
        $state = $snapshot.State
        $lastChanged = Get-LastChangedDate -State $state

        if ([string]::IsNullOrWhiteSpace([string]$config.WallFolder)) {
            return $false
        }

        if ($null -eq $lastChanged) {
            return $true
        }

        return (Get-Date) -ge $lastChanged.AddHours([double]$config.IntervalHours)
    }

    function Try-AdvanceWallpaper {
        param(
            [switch]$ForceShuffle,
            [switch]$UserInitiated
        )

        if ($script:isChangingWallpaper) {
            return $false
        }

        $script:isChangingWallpaper = $true
        try {
            $config = Get-LivelyConfig
            if ([string]::IsNullOrWhiteSpace([string]$config.WallFolder)) {
                $message = 'Choose a wallpaper folder to get started.'
                if ($UserInitiated) {
                    Show-LivelyUserMessage -Message $message -Icon Info
                }

                Update-MenuText
                Update-CountdownText
                return $false
            }

            $files = @(Get-LivelyWallpaperFiles -Folder $config.WallFolder -Recursive ([bool]$config.Recursive))
            if ($files.Count -eq 0) {
                $message = 'No supported images were found in the selected folder.'
                Write-LivelyLog -Level WARN -Message $message
                if ($UserInitiated) {
                    Show-LivelyUserMessage -Message $message -Icon Warning
                }

                Update-MenuText
                Update-CountdownText
                return $false
            }

            $currentState = Get-LivelyState
            $nextItem = Get-LivelyNextWallpaperState -AvailableFiles $files -CurrentState $currentState -ShuffleEnabled ([bool]$config.ShuffleEnabled) -ForceShuffle:$ForceShuffle
            if ($null -eq $nextItem) {
                return $false
            }

            try {
                [void](Set-LivelyWallpaper -FilePath $nextItem.Wallpaper)
                Save-LivelyState -State $nextItem.State
                Write-LivelyLog -Message ('Wallpaper changed to {0}' -f (Split-Path -Leaf $nextItem.Wallpaper))
                return $true
            } catch {
                Write-LivelyLogError -Context 'Failed to change wallpaper' -ErrorRecord $_
                if ($UserInitiated) {
                    Show-LivelyUserMessage -Message $_.Exception.Message -Icon Error
                } else {
                    Show-DependencyWarning
                }

                return $false
            }
        } finally {
            $script:isChangingWallpaper = $false
            Update-MenuText
            Update-CountdownText
        }
    }

    function Set-WallpaperFolder {
        param([string]$Folder)

        $config = Get-LivelyConfig
        $config.WallFolder = $Folder
        $config.WelcomeTipShown = $true
        Save-LivelyConfig -Config $config
        [void](Reset-LivelyState)
        Write-LivelyLog -Message ('Wallpaper folder updated to {0}' -f $Folder)
        [void](Try-AdvanceWallpaper -ForceShuffle -UserInitiated)
    }

    function Set-RecursiveMode {
        param([bool]$Enabled)

        $config = Get-LivelyConfig
        $config.Recursive = $Enabled
        Save-LivelyConfig -Config $config
        [void](Reset-LivelyState)
        Write-LivelyLog -Message ('Recursive mode set to {0}' -f $Enabled)
        [void](Try-AdvanceWallpaper -ForceShuffle -UserInitiated)
    }

    function Set-ShuffleMode {
        param([bool]$Enabled)

        $config = Get-LivelyConfig
        $currentState = Get-LivelyState
        $config.ShuffleEnabled = $Enabled
        Save-LivelyConfig -Config $config

        if (-not [string]::IsNullOrWhiteSpace([string]$config.WallFolder)) {
            $files = @(Get-LivelyWallpaperFiles -Folder $config.WallFolder -Recursive ([bool]$config.Recursive))
            if ($files.Count -gt 0) {
                $newState = Get-LivelyResyncedState -AvailableFiles $files -CurrentState $currentState -ShuffleEnabled $Enabled -KeepCurrentWallpaper
                Save-LivelyState -State $newState
            }
        }

        Write-LivelyLog -Message ('Shuffle mode set to {0}' -f $Enabled)
        Update-MenuText
        Update-CountdownText
    }

    function Set-IntervalHours {
        param([double]$Hours)

        $config = Get-LivelyConfig
        $config.IntervalHours = $Hours
        Save-LivelyConfig -Config $config
        Write-LivelyLog -Message ('Interval updated to {0} hours' -f $Hours)
        Update-MenuText
        Update-CountdownText
    }

    $paths = Get-LivelySlideshowPaths
    $icon = $null
    if (Test-Path -LiteralPath $paths.IconPath) {
        try {
            $icon = New-Object System.Drawing.Icon($paths.IconPath)
        } catch {
            Write-LivelyLogError -Context 'Failed to load tray icon' -ErrorRecord $_
        }
    }

    if ($null -eq $icon) {
        $icon = [System.Drawing.SystemIcons]::Application
    }

    $script:tray = New-Object System.Windows.Forms.NotifyIcon
    $script:tray.Icon = $icon
    $script:tray.Text = 'LivelySlideshow'
    $script:tray.Visible = $true

    $menu = New-Object System.Windows.Forms.ContextMenuStrip
    $script:miCountdown = New-Object System.Windows.Forms.ToolStripMenuItem('Next change: --:--:--')
    $script:miCountdown.Enabled = $false
    [void]$menu.Items.Add($script:miCountdown)

    $miNext = New-Object System.Windows.Forms.ToolStripMenuItem('Next wallpaper')
    $miNext.Add_Click({ [void](Try-AdvanceWallpaper -UserInitiated) })
    [void]$menu.Items.Add($miNext)

    $script:miShuffle = New-Object System.Windows.Forms.ToolStripMenuItem('Shuffle: On')
    $script:miShuffle.CheckOnClick = $false
    $script:miShuffle.Add_Click({
        $config = Get-LivelyConfig
        Set-ShuffleMode -Enabled (-not [bool]$config.ShuffleEnabled)
    })
    [void]$menu.Items.Add($script:miShuffle)

    [void]$menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))

    $script:miInterval = New-Object System.Windows.Forms.ToolStripMenuItem('Interval')
    foreach ($item in $script:intervalOptions.GetEnumerator()) {
        $mi = New-Object System.Windows.Forms.ToolStripMenuItem($item.Key)
        $mi.Tag = [double]$item.Value
        $mi.Add_Click({
            param($sender)
            Set-IntervalHours -Hours ([double]$sender.Tag)
        })
        [void]$script:miInterval.DropDownItems.Add($mi)
    }
    [void]$menu.Items.Add($script:miInterval)

    $script:miFolder = New-Object System.Windows.Forms.ToolStripMenuItem('Folder')
    $miBrowse = New-Object System.Windows.Forms.ToolStripMenuItem('Choose folder...')
    $miBrowse.Add_Click({
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = 'Choose the folder that contains your wallpapers.'
        $dialog.ShowNewFolderButton = $false
        $selectedPath = (Get-LivelyConfig).WallFolder
        if (-not [string]::IsNullOrWhiteSpace([string]$selectedPath) -and (Test-Path -LiteralPath $selectedPath)) {
            $dialog.SelectedPath = $selectedPath
        }
        try {
            if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                if (Test-FolderHasSupportedFiles -Folder $dialog.SelectedPath -Recursive ((Get-LivelyConfig).Recursive)) {
                    Set-WallpaperFolder -Folder $dialog.SelectedPath
                } else {
                    Show-LivelyUserMessage -Message 'That folder does not contain any supported wallpapers.' -Icon Warning
                }
            }
        } finally {
            $dialog.Dispose()
        }
    })
    [void]$script:miFolder.DropDownItems.Add($miBrowse)

    $script:miRecursive = New-Object System.Windows.Forms.ToolStripMenuItem('Include subfolders')
    $script:miRecursive.Add_Click({
        $config = Get-LivelyConfig
        $newValue = -not [bool]$config.Recursive
        if (Test-FolderHasSupportedFiles -Folder $config.WallFolder -Recursive $newValue) {
            Set-RecursiveMode -Enabled $newValue
        } else {
            Show-LivelyUserMessage -Message 'No supported wallpapers were found with that setting.' -Icon Warning
        }
    })
    [void]$script:miFolder.DropDownItems.Add($script:miRecursive)
    [void]$menu.Items.Add($script:miFolder)

    $script:miCurrentFolder = New-Object System.Windows.Forms.ToolStripMenuItem('')
    $script:miCurrentFolder.Enabled = $false
    [void]$menu.Items.Add($script:miCurrentFolder)

    $script:miFileCount = New-Object System.Windows.Forms.ToolStripMenuItem('Files found: 0')
    $script:miFileCount.Enabled = $false
    [void]$menu.Items.Add($script:miFileCount)

    [void]$menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))

    $miOpenLogs = New-Object System.Windows.Forms.ToolStripMenuItem('Open logs folder')
    $miOpenLogs.Add_Click({
        $paths = Get-LivelySlideshowPaths
        Start-Process -FilePath 'explorer.exe' -ArgumentList @($paths.LogDir)
    })
    [void]$menu.Items.Add($miOpenLogs)

    $miOpenData = New-Object System.Windows.Forms.ToolStripMenuItem('Open app data folder')
    $miOpenData.Add_Click({
        $paths = Get-LivelySlideshowPaths
        Start-Process -FilePath 'explorer.exe' -ArgumentList @($paths.DataDir)
    })
    [void]$menu.Items.Add($miOpenData)

    [void]$menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))

    $miExit = New-Object System.Windows.Forms.ToolStripMenuItem('Exit')
    $miExit.Add_Click({
        $script:tray.Visible = $false
        $timer.Stop()
        $timer.Dispose()
        $script:tray.Dispose()
        [System.Windows.Forms.Application]::Exit()
    })
    [void]$menu.Items.Add($miExit)

    $script:tray.ContextMenuStrip = $menu
    $script:tray.Add_MouseClick({
        param($sender, $eventArgs)
        if ($eventArgs.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
            [void](Try-AdvanceWallpaper -UserInitiated)
        }
    })

    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 1000
    $timer.Add_Tick({
        Update-CountdownText
        if (Test-ChangeDue) {
            [void](Try-AdvanceWallpaper)
        }
    })

    Show-DependencyWarning
    Update-MenuText
    Update-CountdownText
    Show-FirstRunTipIfNeeded
    if (Test-ChangeDue) {
        [void](Try-AdvanceWallpaper)
    }

    $timer.Start()
    [System.Windows.Forms.Application]::Run()
}

Export-ModuleMember -Function Start-LivelySlideshowTrayApp
