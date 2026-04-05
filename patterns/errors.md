
## Error handling.
DO NOT create empty or low-value try-catch blocks. Let exceptions propagate unless specifically handling expected conditions.
Use ArgumentNullException.ThrowIfNull(x) for null checks.
Use string.IsNullOrWhiteSpace(x) for strings.
Guard early. Avoid blanket !.
Choose precise exception types: ArgumentException, InvalidOperationException.
No silent catches. Don't swallow errors. Log and rethrow or bubble up.

keep powershell & c# methods short.

this is good:

function Invoke-Test-Open-WebUI($configuration) {
    $openwebuiUrl = $configuration.openWebUIUrl
    Write-Host "Testing Open Web UI is accessible at $openwebuiUrl..."
    $response = Invoke-WebRequest -Uri $openwebuiUrl -Method GET -TimeoutSec 5
    Write-host "Open Web UI response status code: $($response.StatusCode) $($response.StatusDescription)."
}

this is bad:

function Invoke-Test-Open-WebUI($configuration) {
    $openwebuiUrl = $configuration.openWebUIUrl
    Write-Host "Testing Open Web UI is accessible at $openwebuiUrl..."
    try {
        $response = Invoke-WebRequest -Uri $openwebuiUrl -Method GET -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            Write-Host "Open Web UI is accessible."
        } else {
            Write-Error "Open Web UI returned unexpected status code: $($response.StatusCode)"
            exit 1
        }
    } catch {
        Write-Error "Failed to access Open Web UI: $_"
        exit 1
    }
}

this is bad as due to our orchestration script already has $ErrorActionPreference="stop".
it does not anything over and above what we would have gotten in the good example.
The script would have stopped already and the exception would have already been written to the console/logs. 
