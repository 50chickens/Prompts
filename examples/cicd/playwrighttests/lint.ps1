$ErrorActionPreference = 'Stop'

$solutionName = "PlayWrightDemo"
$solutionFile = "$solutionName.sln"

function Invoke-LintCode {
    param([string]$SolutionFile)
    
    Write-Host "Linting code..."
    dotnet format $SolutionFile --verify-no-changes --verbosity diagnostic
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ERROR: Code formatting issues detected. Exit code $LASTEXITCODE."
        exit $LASTEXITCODE
    }
}

# Main execution
Write-Host "=== $solutionName Lint ==="

Invoke-LintCode -SolutionFile $solutionFile

Write-Host "=== $solutionName Lint Complete ==="
exit 0
