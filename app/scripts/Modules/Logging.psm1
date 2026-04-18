Set-StrictMode -Version 3.0

function Initialize-LivelyLogger {
    [CmdletBinding()]
    param()

    $paths = Get-LivelySlideshowPaths
    if (-not (Test-Path -LiteralPath $paths.LogDir)) {
        [void](New-Item -ItemType Directory -Path $paths.LogDir -Force)
    }
}

function Write-LivelyLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO'
    )

    Initialize-LivelyLogger
    $paths = Get-LivelySlideshowPaths
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = '[{0}] [{1}] {2}' -f $timestamp, $Level, $Message
    [System.IO.File]::AppendAllText(
        $paths.LogFile,
        $line + [Environment]::NewLine,
        [System.Text.UTF8Encoding]::new($false)
    )

    try {
        $fileInfo = Get-Item -LiteralPath $paths.LogFile -ErrorAction Stop
        if ($fileInfo.Length -gt 1048576) {
            $tail = Get-Content -LiteralPath $paths.LogFile -Tail 500
            [System.IO.File]::WriteAllLines($paths.LogFile, $tail, [System.Text.UTF8Encoding]::new($false))
        }
    } catch {
        # Avoid recursive logging failures.
    }
}

function Write-LivelyLogError {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Context,

        [Parameter(Mandatory = $true)]
        $ErrorRecord
    )

    $detail = if ($ErrorRecord.Exception) {
        $ErrorRecord.Exception.Message
    } else {
        [string]$ErrorRecord
    }

    Write-LivelyLog -Level ERROR -Message ('{0}: {1}' -f $Context, $detail)
}

Export-ModuleMember -Function Initialize-LivelyLogger, Write-LivelyLog, Write-LivelyLogError
