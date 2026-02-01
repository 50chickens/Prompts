#simulates the github actions environment for local testing
$ErrorActionPreference = 'Stop'

# Get directory paths
$ciDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$srcDir = Join-Path $ciDir "..\src"

# Load configuration
$configuration = Get-Content "$srcDir/build-configuration.json" -Raw | ConvertFrom-Json

#functions go here

# Main execution
Write-Host "=== CI Simulation Environment ==="
Write-Host "CI Directory: $ciDir"
Write-Host "Source Directory: $srcDir"

# Navigate to src directory for all operations
Push-Location $srcDir

Invoke-LintCheck -Configuration $configuration
Invoke-BuildAndTest -Configuration $configuration
Invoke-NugetPackage -Configuration $configuration

Write-Host "=== CI Simulation Complete ==="

Pop-Location
