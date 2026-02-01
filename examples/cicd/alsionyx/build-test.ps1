#!/usr/bin/env pwsh
$ErrorActionPreference = 'Stop'

$config = Get-Content './build-configuration.json' -Raw | ConvertFrom-Json

function Invoke-ValidateProjectReferences {
    param([PSCustomObject]$Config, [string]$SolutionFile)
    
    Write-Host "Validating project references..."
    $solutionContent = Get-Content -Path $SolutionFile -Raw
    $missingProjects = @()
    
    Get-ChildItem -Filter '*.csproj' -Recurse | ForEach-Object {
        if ($solutionContent -notmatch [regex]::Escape($_.Name)) {
            $missingProjects += $_.Name
        }
    }
    
    if ($missingProjects.Count -gt 0) {
        Write-Host "ERROR: Missing projects in solution:"
        $missingProjects | ForEach-Object { Write-Host "  $_" }
        throw "Validation failed"
    }
}

function Invoke-RestoreDependencies {
    param([PSCustomObject]$Config, [string]$SolutionFile)
    
    Write-Host "Restoring dependencies..."
    dotnet restore $SolutionFile
}

function Invoke-CodeFormatCheck {
    param([PSCustomObject]$Config, [string]$SolutionFile)
    
    Write-Host "Checking code format..."
    dotnet format $SolutionFile --verify-no-changes
}

function Invoke-BuildSolution {
    param([PSCustomObject]$Config, [string]$SolutionFile)
    
    Write-Host "Building solution..."
    dotnet build $SolutionFile
}

function Invoke-RunTests {
    param([PSCustomObject]$Config, [string]$SolutionFile)
    
    Write-Host "Running tests..."
    dotnet test $SolutionFile
}

function Invoke-StartApiServer {
    param([string]$APIProjectPath)
    
    Write-Host "Starting API server for Playwright tests..."
    $apiProcess = Start-Process -FilePath "dotnet" `
        -ArgumentList "run --project $APIProjectPath --urls http://127.0.0.1:5014" `
        -NoNewWindow `
        -PassThru `
        -RedirectStandardOutput "$PSScriptRoot\api.log" `
        -RedirectStandardError "$PSScriptRoot\api-error.log"
    
    # Wait for API to be ready
    Write-Host "Waiting for API server to start (up to 60 seconds)..."
    $maxWait = 60
    $elapsed = 0
    $ready = $false
    $wait = 500
    
    while ($elapsed -lt $maxWait) {
        try {
            $response = Invoke-WebRequest -Uri "http://127.0.0.1:5014/api/health" -TimeoutSec 3 -ErrorAction SilentlyContinue
            if ($response.StatusCode -eq 200) {
                $ready = $true
                Write-Host "✓ API server is ready"
                Start-Sleep -Milliseconds 500
                break
            }
        }
        catch {
            # Still starting up
        }
        
        Start-Sleep -Milliseconds $wait
        $elapsed += ($wait / 1000)
        $wait = [Math]::Min($wait * 1.5, 5000)
    }
    
    if (-not $ready) {
        Write-Host "✗ API server failed to start within ${maxWait}s"
        Get-Content "$PSScriptRoot\api-error.log" -ErrorAction SilentlyContinue | Write-Host
        Stop-Process -Id $apiProcess.Id -Force -ErrorAction SilentlyContinue
        throw "API server startup timeout"
    }
    
    return $apiProcess
}

function Invoke-StartBlazorUI {
    param([string]$UIProjectPath)
    
    Write-Host "Starting Blazor UI for Playwright tests..."
    $blazorProcess = Start-Process -FilePath "dotnet" `
        -ArgumentList "run --project $UIProjectPath --urls http://127.0.0.1:5002" `
        -NoNewWindow `
        -PassThru `
        -RedirectStandardOutput "$PSScriptRoot\blazor-ui.log" `
        -RedirectStandardError "$PSScriptRoot\blazor-ui-error.log"
    
    # Wait for Blazor UI to be ready with exponential backoff
    Write-Host "Waiting for Blazor UI to start (up to 90 seconds)..."
    $maxWait = 90
    $elapsed = 0
    $ready = $false
    $wait = 500  # Start with 500ms wait, increase exponentially
    
    while ($elapsed -lt $maxWait) {
        try {
            $response = Invoke-WebRequest -Uri "http://127.0.0.1:5002" -TimeoutSec 3 -ErrorAction SilentlyContinue
            if ($response.StatusCode -eq 200) {
                $ready = $true
                Write-Host "✓ Blazor UI is ready"
                Start-Sleep -Milliseconds 1000  # Extra delay to ensure full initialization
                break
            }
        }
        catch {
            # Still starting up
        }
        
        Start-Sleep -Milliseconds $wait
        $elapsed += ($wait / 1000)
        $wait = [Math]::Min($wait * 1.5, 5000)  # Exponential backoff, max 5 seconds
    }
    
    if (-not $ready) {
        Write-Host "✗ Blazor UI failed to start within ${maxWait}s"
        Get-Content "$PSScriptRoot\blazor-ui-error.log" -ErrorAction SilentlyContinue | Write-Host
        Stop-Process -Id $blazorProcess.Id -Force -ErrorAction SilentlyContinue
        throw "Blazor UI startup timeout"
    }
    
    return $blazorProcess
}

function Invoke-CodeCoverage {
    param([PSCustomObject]$Config, [string]$SolutionFile)
    
    Write-Host "Collecting code coverage..."
    dotnet test $SolutionFile `
        /p:CollectCoverage=true `
        /p:CoverageFormat=json `
        /p:CoverageFileName=coverage.json
}

# Playwright tests have been moved to run-playwright-tests.ps1

# Main execution
Write-Host "=== Alsionyx Build & Test ==="

Invoke-ValidateProjectReferences -Config $config.validate -SolutionFile $config.solutionFile
Invoke-RestoreDependencies -Config $config.restore -SolutionFile $config.solutionFile
Invoke-CodeFormatCheck -Config $config.codeFormat -SolutionFile $config.solutionFile
Invoke-BuildSolution -Config $config.build -SolutionFile $config.solutionFile
Invoke-RunTests -Config $config.test -SolutionFile $config.solutionFile

# Start API and Blazor UI for Playwright tests
$apiProcess = $null
$blazorProcess = $null
try {
    if (Test-Path './run-playwright-tests.ps1') {
        $apiProjectPath = "Alsionyx.Api/Alsionyx.Api.csproj"
        $uiProjectPath = "Alsionyx.BlazorUI/Alsionyx.BlazorUI.csproj"
        
        # Start API first
        $apiProcess = Invoke-StartApiServer -APIProjectPath $apiProjectPath
        Write-Host "API server process ID: $($apiProcess.Id)"
        
        # Then start Blazor UI
        $blazorProcess = Invoke-StartBlazorUI -UIProjectPath $uiProjectPath
        Write-Host "Blazor UI process ID: $($blazorProcess.Id)"
        
        Write-Host "Running Playwright tests with both API and Blazor UI running..."
        $env:BLAZOR_BASE_URL = "http://127.0.0.1:5002"
        $env:API_BASE_URL = "http://127.0.0.1:5014"
        
        # Find and run the Playwright tests directly
        $playwrightTests = Get-ChildItem -Path './Alsionyx.PlaywrightTests/bin/Debug/net9.0/Alsionyx.PlaywrightTests.dll' -ErrorAction SilentlyContinue
        if ($playwrightTests) {
            Write-Host "Running Playwright tests..."
            dotnet test $playwrightTests.FullName
        } else {
            Write-Host "Playwright tests DLL not found at expected location"
            # Try to build first
            Write-Host "Building Playwright tests..."
            dotnet build ./Alsionyx.PlaywrightTests/Alsionyx.PlaywrightTests.csproj
            $playwrightTests = Get-ChildItem -Path './Alsionyx.PlaywrightTests/bin/Debug/net9.0/Alsionyx.PlaywrightTests.dll' -ErrorAction SilentlyContinue
            if ($playwrightTests) {
                Write-Host "Running Playwright tests..."
                dotnet test $playwrightTests.FullName
            }
        }
    } else {
        Write-Host "Playwright runner script not found; skipping Playwright step."
    }
}
finally {
    if ($blazorProcess) {
        Write-Host "Checking if Blazor UI process is still running..."
        $procCheck = Get-Process -Id $blazorProcess.Id -ErrorAction SilentlyContinue
        if ($procCheck) {
            Write-Host "Stopping Blazor UI (PID: $($blazorProcess.Id))..."
            Stop-Process -Id $blazorProcess.Id -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 1
            Write-Host "✓ Blazor UI stopped"
        }
    }
    
    if ($apiProcess) {
        Write-Host "Checking if API process is still running..."
        $procCheck = Get-Process -Id $apiProcess.Id -ErrorAction SilentlyContinue
        if ($procCheck) {
            Write-Host "Stopping API server (PID: $($apiProcess.Id))..."
            Stop-Process -Id $apiProcess.Id -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 1
            Write-Host "✓ API server stopped"
        }
    }
}

Invoke-CodeCoverage -Config $config.coverage -SolutionFile $config.solutionFile

Write-Host "=== Build Complete ==="
exit 0

