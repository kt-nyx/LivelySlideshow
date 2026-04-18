Set-StrictMode -Version 3.0

function Initialize-LivelySlideshowData {
    [CmdletBinding()]
    param()

    $paths = Get-LivelySlideshowPaths
    foreach ($directory in @($paths.DataDir, $paths.LogDir)) {
        if (-not (Test-Path -LiteralPath $directory)) {
            [void](New-Item -ItemType Directory -Path $directory -Force)
        }
    }

    Initialize-LivelyLogger
    Initialize-LivelyConfig
    Initialize-LivelyState
}

function Show-LivelyUserMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [string]$Title = 'LivelySlideshow',

        [ValidateSet('Info', 'Warning', 'Error')]
        [string]$Icon = 'Info'
    )

    Add-Type -AssemblyName System.Windows.Forms
    $iconValue = switch ($Icon) {
        'Error' { [System.Windows.Forms.MessageBoxIcon]::Error; break }
        'Warning' { [System.Windows.Forms.MessageBoxIcon]::Warning; break }
        default { [System.Windows.Forms.MessageBoxIcon]::Information }
    }

    [void][System.Windows.Forms.MessageBox]::Show(
        $Message,
        $Title,
        [System.Windows.Forms.MessageBoxButtons]::OK,
        $iconValue
    )
}

function Acquire-LivelySingleton {
    [CmdletBinding()]
    param(
        [string]$Name = 'Tray'
    )

    $mutexName = 'Local\LivelySlideshow.Instance.{0}' -f $Name
    $createdNew = $false
    $mutex = New-Object System.Threading.Mutex($true, $mutexName, [ref]$createdNew)

    if (-not $createdNew) {
        $mutex.Dispose()
        return $null
    }

    return $mutex
}

Export-ModuleMember -Function Initialize-LivelySlideshowData, Show-LivelyUserMessage, Acquire-LivelySingleton
