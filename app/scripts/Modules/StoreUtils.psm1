Set-StrictMode -Version 3.0

function Invoke-WithLivelyMutex {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [int]$TimeoutMs = 15000
    )

    $mutexName = 'Local\LivelySlideshow.{0}' -f $Name
    $mutex = New-Object System.Threading.Mutex($false, $mutexName)
    $lockTaken = $false

    try {
        $lockTaken = $mutex.WaitOne($TimeoutMs, $false)
        if (-not $lockTaken) {
            throw "Timed out waiting for lock '$mutexName'."
        }

        return & $ScriptBlock
    } finally {
        if ($lockTaken) {
            [void]$mutex.ReleaseMutex()
        }

        $mutex.Dispose()
    }
}

function Read-LivelyJsonFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    $raw = [System.IO.File]::ReadAllText($Path, [System.Text.UTF8Encoding]::new($false))
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return $null
    }

    return $raw | ConvertFrom-Json
}

function Write-LivelyJsonFileAtomic {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        $InputObject
    )

    $directory = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $directory)) {
        [void](New-Item -ItemType Directory -Path $directory -Force)
    }

    $tempPath = Join-Path $directory ([System.IO.Path]::GetRandomFileName())
    $json = $InputObject | ConvertTo-Json -Depth 8
    [System.IO.File]::WriteAllText($tempPath, $json, [System.Text.UTF8Encoding]::new($false))
    Move-Item -LiteralPath $tempPath -Destination $Path -Force
}

Export-ModuleMember -Function Invoke-WithLivelyMutex, Read-LivelyJsonFile, Write-LivelyJsonFileAtomic
