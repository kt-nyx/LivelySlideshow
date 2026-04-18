Set-StrictMode -Version 3.0

function Register-LivelySlideshowTask {
    [CmdletBinding()]
    param()

    $paths = Get-LivelySlideshowPaths
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

    if (-not (Test-Path -LiteralPath $paths.HiddenLauncher)) {
        throw "Hidden launcher was not found: $($paths.HiddenLauncher)"
    }

    $action = New-ScheduledTaskAction -Execute 'wscript.exe' -Argument ('"{0}"' -f $paths.HiddenLauncher)
    $trigger = New-ScheduledTaskTrigger -AtLogOn -User $currentUser
    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -ExecutionTimeLimit ([TimeSpan]::Zero)

    $principal = New-ScheduledTaskPrincipal -UserId $currentUser -LogonType Interactive -RunLevel Limited

    Register-ScheduledTask `
        -TaskName $paths.TaskName `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -Principal $principal `
        -Description 'Starts the LivelySlideshow tray app when you sign in.' `
        -Force | Out-Null
}

function Unregister-LivelySlideshowTask {
    [CmdletBinding()]
    param()

    $paths = Get-LivelySlideshowPaths
    Unregister-ScheduledTask -TaskName $paths.TaskName -Confirm:$false -ErrorAction SilentlyContinue
}

Export-ModuleMember -Function Register-LivelySlideshowTask, Unregister-LivelySlideshowTask
