#!/usr/bin/env pwsh
param(
    [string]$ConfigurationFolder,  # Path to folder containing JSON configuration files
    [string]$NugetSourceName = "github"  # NuGet source for package publishing
)

$ErrorActionPreference = 'Stop'

function Get-BuildConfiguration {
    $branchName = git rev-parse --abbrev-ref HEAD
    switch -Wildcard ($branchName) {
        "main" { return "Release" }
        "master" { return "Release" }
        "develop" { return "Debug" }
        "feature/*" { return "Debug" }
        default { throw "Unknown branch name: $branchName" }
    }
}

function Invoke-ValidateProjectReferences {
    param([object]$Configuration)
    
    $solutionFile = $Configuration.solutionFile
    Write-Host "Validating project references..."
    $solutionContent = Get-Content -Path $solutionFile -Raw
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
    param([object]$Configuration)
    
    $solutionFile = $Configuration.solutionFile
    Write-Host "Restoring dependencies..."
    dotnet restore $solutionFile
    Write-Host "Restore completed"
}

function Invoke-CodeFormatCheck {
    param([object]$Configuration)
    
    $solutionFile = $Configuration.solutionFile
    Write-Host "Checking code format..."
    dotnet format $solutionFile --verify-no-changes
}

function Invoke-BuildSolution {
    param([object]$Configuration)
    
    $solutionFile = $Configuration.solutionFile
    $buildConfig = $Configuration.buildConfiguration  # Extract from config
    Write-Host "Building solution in $buildConfig mode..."
    dotnet build $solutionFile -c $buildConfig --no-restore
    Write-Host "Build completed"
}

function Invoke-RunTests {
    param([object]$Configuration)
    
    $solutionFile = $Configuration.solutionFile
    Write-Host "Running tests..."
    dotnet test $solutionFile --no-build
    Write-Host "Tests completed"
}

function Invoke-CodeCoverage {
    param([object]$Configuration)
    
    $solutionFile = $Configuration.solutionFile
    Write-Host "Collecting code coverage..."
    dotnet test $solutionFile `
        /p:CollectCoverage=true `
        /p:CoverageFormat=json `
        /p:CoverageFileName=coverage.json
}

function Invoke-PublishPackages {
    param([object]$Configuration)
    
    $packageOutputFolder = $Configuration.packageOutputFolder
    $nugetSource = $Configuration.nugetSource
    Write-Host "Publishing packages to $nugetSource..."
    Get-ChildItem -Path $packageOutputFolder -Filter '*.nupkg' -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Host "Pushing package: $($_.Name)"
        dotnet nuget push $_.FullName --source $nugetSource --skip-duplicate
    }
}

function Invoke-ValidateAndLoadConfigurations {
    param([string]$ConfigurationFolder)
    
    if (-not (Test-Path $ConfigurationFolder)) {
        Write-Error "Configuration folder not found: $ConfigurationFolder"
        exit 1
    }
    
    $configFiles = @(Get-ChildItem -Path $ConfigurationFolder -Filter '*.json' -ErrorAction SilentlyContinue | Sort-Object Name)
    
    if ($configFiles.Count -eq 0) {
        Write-Error "No JSON configuration files found in $ConfigurationFolder"
        exit 1
    }
    
    return $configFiles
}

function Invoke-ProcessConfiguration {
    param(
        [System.IO.FileInfo]$ConfigFile,
        [PSCustomObject]$Config
    )
    
    $configPath = Split-Path -Path $ConfigFile.FullName
    Set-Location $configPath
    Write-Host "Processing configuration: $($ConfigFile.Name) from $configPath"
    
    Invoke-ValidateProjectReferences -Configuration $Config
    Invoke-RestoreDependencies -Configuration $Config
    Invoke-CodeFormatCheck -Configuration $Config
    Invoke-BuildSolution -Configuration $Config
    Invoke-RunTests -Configuration $Config
    Invoke-CodeCoverage -Configuration $Config
    Invoke-PublishPackages -Configuration $Config
    
    Write-Host "Configuration $($ConfigFile.Name) completed successfully`n"
}

#validate parameters and load configurations
$configFiles = Invoke-ValidateAndLoadConfigurations -ConfigurationFolder $ConfigurationFolder

Write-Host "=== Alsionyx Build & Test ==="

foreach ($configFile in $configFiles) {
    $config = Get-Content -Path $configFile.FullName -Raw | ConvertFrom-Json
    Invoke-ProcessConfiguration -ConfigFile $configFile -Config $config
}

Write-Host "=== Build Complete ==="
exit 0

