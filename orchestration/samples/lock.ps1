# A lock helper for serialising a shared resource

Wrap the whole operation in the lock rather than locking inside callers, so no caller has to reason about it.

```powershell
function Invoke-Exclusive {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][scriptblock]$Action,
        [int]$TimeoutSeconds = 600,
        [int]$PollSeconds = 5
    )

    $directory = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $directory)) {
        $null = New-Item -ItemType Directory -Path $directory -Force
    }

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    $stream = $null

    while ($null -eq $stream) {
        try {
            $stream = [System.IO.File]::Open(
                $Path,
                [System.IO.FileMode]::OpenOrCreate,
                [System.IO.FileAccess]::ReadWrite,
                [System.IO.FileShare]::None)
        }
        catch [System.IO.IOException] {
            if ((Get-Date) -gt $deadline) {
                throw "Could not acquire '$Path' within $TimeoutSeconds seconds."
            }
            Start-Sleep -Seconds $PollSeconds
        }
    }

    $writer = New-Object System.IO.StreamWriter($stream)
    $writer.WriteLine("$PID $(Get-Date -Format o)")
    $writer.Flush()

    try {
        & $Action
    }
    finally {
        $writer.Dispose()
        $stream.Dispose()
    }
}
```

Usage:

```powershell
Invoke-Exclusive -Path "$PSScriptRoot/ci-build.lock" -Action {
    dotnet build -p:ArtifactsPath="$PSScriptRoot/../artifacts"
}
```

Notes that matter in practice:

- **The lock is a file handle, not a marker file.** A marker left behind by a killed process is a stale lock
  forever; an open handle is released when the process dies.
- **Set a timeout and throw.** Waiting indefinitely turns a collision into a hang, and a hang is harder to
  diagnose than an error.
- **Do not use this for a rate-limited service.** That needs backoff with a growing interval and a bounded
  attempt count, not a fixed poll.
- **Record the wait in the report.** If a lane spent most of its time waiting for the lock, the orchestrator
  needs to know that the build lane is the bottleneck.

## Backoff variant for a rate-limited resource

```powershell
function Invoke-WithBackoff {
    param(
        [Parameter(Mandatory)][scriptblock]$Action,
        [int]$MaxAttempts = 6,
        [int]$InitialDelaySeconds = 10
    )

    $delay = $InitialDelaySeconds
    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        try {
            return & $Action
        }
        catch {
            if ($attempt -eq $MaxAttempts) { throw }
            Write-Output "attempt $attempt failed; waiting $delay seconds"
            Start-Sleep -Seconds $delay
            $delay = $delay * 2
        }
    }
}
```

If the increase is small, write it down: `"attempt 1: 10 s, attempt 2: 20 s, ..."` is what makes a rate limit
visible in a report rather than mysterious. **Stop and report on a rate limit rather than hammering it** - a
bounded number of attempts is the whole point.
