$ErrorActionPreference = 'Stop'

$solutionName = "PlayWrightDemo"
$srcDirectory = Join-Path $PSScriptRoot "../src"
$solutionFile = Join-Path $srcDirectory "$solutionName.sln"

# Load build configuration - single source of truth for all settings
$configPath = Join-Path $PSScriptRoot "../src/build-configuration.json"
$config = Get-Content $configPath | ConvertFrom-Json

function Invoke-RestoreDependencies {
    param([object]$Config, [string]$SolutionFile)
    
    Write-Host "Restoring dependencies..."
    $restoreArgs = @($SolutionFile)
    
    if ($Config.build.suppressWarnings.Count -gt 0) {
        $suppressList = $Config.build.suppressWarnings -join ";"
        $restoreArgs += @("/p:NoWarn=$suppressList")
    }
    
    dotnet restore @restoreArgs
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ERROR: Dependency restore failed. Exit code $LASTEXITCODE."
        exit $LASTEXITCODE
    }
}

function Invoke-CodeFormatCheck {
    param([object]$Config, [string]$SolutionFile)
    
    Write-Host "Checking code format..."
    dotnet format $SolutionFile --verify-no-changes
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ERROR: Code formatting issues detected. Exit code $LASTEXITCODE."
        exit $LASTEXITCODE
    }
}

function Invoke-BuildSolution {
    param([object]$Config, [string]$SolutionFile)
    
    Write-Host "Building solution..."
    $buildArgs = @($SolutionFile, "--verbosity", $Config.build.verbosity, "--nologo")
    
    if ($Config.build.suppressWarnings.Count -gt 0) {
        $suppressList = $Config.build.suppressWarnings -join ";"
        $buildArgs += @("/p:NoWarn=$suppressList")
    }
    
    dotnet build @buildArgs
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ERROR: Build failed. Exit code $LASTEXITCODE."
        exit $LASTEXITCODE
    }
}

function Invoke-RunTests {
    param([object]$Config, [string]$SolutionFile)
    
    Write-Host "Running tests..."
    dotnet test $SolutionFile --verbosity $Config.test.verbosity
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ERROR: Tests failed. Exit code $LASTEXITCODE."
        exit $LASTEXITCODE
    }
}

# Main execution
Write-Host "=== $solutionName Build & Test ==="

Invoke-RestoreDependencies -Config $config -SolutionFile $solutionFile
Invoke-CodeFormatCheck -Config $config -SolutionFile $solutionFile
Invoke-BuildSolution -Config $config -SolutionFile $solutionFile
Invoke-RunTests -Config $config -SolutionFile $solutionFile
Write-Host "=== $solutionName Build & Test Complete ==="
exit 0
