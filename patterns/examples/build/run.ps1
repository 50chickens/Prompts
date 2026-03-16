param(
    [string]$ConfigurationFolder, # Folder containing configuration files
    [string]$NugetSourceName = 'github' # NuGet source for package push
)

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
$nupkgOutFolder = "nupkgOut"
$script:BuildNumber = [System.DateTime]::UtcNow.Ticks.ToString().Substring(0, 9)

function Invoke-PreflightCheck {
    if (-not $ConfigurationFolder) {
        Write-Error "ConfigurationFolder parameter is required"
        exit 1
    }

    if (-not (Test-Path $ConfigurationFolder)) {
        Write-Error "ERROR: Configuration folder not found: $ConfigurationFolder"
        exit 1
    }
}

function Get-BuildConfiguration {
    $branchName = git rev-parse --abbrev-ref HEAD
    switch -Wildcard ($branchName) {
        "main" { return "Release" }
        "master" { return "Release" }
        "develop" { return "Debug" }
        "feature/*" { return "Debug" }
        "copilot/*" { return "Debug" }
        default { throw "Unknown branch name: $branchName" }
    }
}

function Get-BuildConfigurations {
    param([string]$ConfigurationFolder)
    
    $configurations = @()
    $configFiles = Get-ChildItem -Path $ConfigurationFolder -Filter '*.json' -ErrorAction SilentlyContinue | Sort-Object Name
    
    foreach ($configFile in $configFiles) 
    {
        $configurations += Get-Content $configFile.FullName -Raw | ConvertFrom-Json
    }
    
    return $configurations | Sort-Object { if ($_.buildOrder) { $_.buildOrder } else { 99 } }
}

function Invoke-ValidateProjectReferences($configuration) {
    Write-Host "Validating project references..."
    $solutionFile = $configuration.SolutionFile
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

function Invoke-RestoreDependencies($configuration) {
    Write-Host "Restoring dependencies..."
    $solutionFile = $configuration.SolutionFile
    $restoreArgs = @($solutionFile)
    
    if ($configuration.build.suppressWarnings -and $configuration.build.suppressWarnings.Count -gt 0) {
        $suppressList = $configuration.build.suppressWarnings -join ";"
        $restoreArgs += @("/p:NoWarn=$suppressList")
    }
    
    dotnet restore @restoreArgs
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ERROR: Dependency restore failed. Exit code $LASTEXITCODE."
        exit $LASTEXITCODE
    }
}

function Invoke-CodeFormatCheck($configuration) {
    Write-Host "Checking code format..."
    $solutionFile = $configuration.SolutionFile
    dotnet format $solutionFile --verify-no-changes
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ERROR: Code formatting issues detected. Exit code $LASTEXITCODE."
        exit $LASTEXITCODE
    }
}

function Invoke-BuildSolution($configuration) {
    Write-Host "Building solution..."
    $solutionFile = $configuration.SolutionFile
    $buildArgs = @($solutionFile, "--verbosity", $configuration.build.verbosity, "--nologo")
    
    if ($configuration.build.suppressWarnings -and $configuration.build.suppressWarnings.Count -gt 0) {
        $suppressList = $configuration.build.suppressWarnings -join ";"
        $buildArgs += @("/p:NoWarn=$suppressList")
    }
    
    dotnet build @buildArgs
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ERROR: Build failed. Exit code $LASTEXITCODE."
        exit $LASTEXITCODE
    }
}

function Invoke-RunTests($configuration) {
    Write-Host "Running tests..."
    $solutionFile = $configuration.SolutionFile
    $testArgs = @($solutionFile, "--verbosity", $configuration.test.verbosity)
    if ($configuration.test.excludeCategories -and $configuration.test.excludeCategories.Count -gt 0) {
        $filter = ($configuration.test.excludeCategories | ForEach-Object { "Category!=$_" }) -join "&"
        $testArgs += @("--filter", $filter)
    }
    dotnet test @testArgs
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ERROR: Tests failed. Exit code $LASTEXITCODE."
        exit $LASTEXITCODE
    }
}

function Invoke-NugetPackage($configuration) {
    if (!(Test-Path -Path build.xml)) {
        Write-Host "Skipping NuGet package creation (build.xml not found)"
        return
    }
    Write-Host "Creating NuGet packages..."
    $buildconfiguration = Get-BuildConfiguration 
    & dotnet build build.xml -t:CreateNugetPackages -p:Configuration=$buildconfiguration -p:PackageTags=$buildconfiguration -p:BuildNumber=$script:BuildNumber
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ERROR: dotnet nuget pack failed. Exit code $LASTEXITCODE."
        exit $LASTEXITCODE
    }
    Write-Host "NuGet packages created successfully with tag: $buildconfiguration"
}

function Invoke-NugetPush($configuration) {
    Write-Host "Pushing NuGet packages..."
    $nupkgOutFolderPath = Join-Path (Get-Location) $nupkgOutFolder
    $packages = Get-ChildItem -Path $nupkgOutFolderPath -Filter "*.nupkg" -ErrorAction SilentlyContinue
    
    foreach ($pkg in $packages) {
        Write-Host "Pushing $($pkg.Name)..."
        & dotnet nuget push "$($pkg.FullName)" --source $NugetSourceName
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "ERROR: Failed to push package $($pkg.Name). Exit code $LASTEXITCODE."
            exit $LASTEXITCODE
        }
    }
    Write-Host "NuGet packages pushed successfully."
}

function Invoke-RunBuild($configuration) {
    Invoke-ValidateProjectReferences $configuration
    Invoke-RestoreDependencies $configuration
    Invoke-CodeFormatCheck $configuration
    Invoke-BuildSolution $configuration
    #if running under github actions invoke-runtests
    if ([string]::IsNullOrEmpty($env:GITHUB_ACTIONS)) 
    {
        $configuration.runIntegrationTests = $true #nables running integration tests for local runs only. if we're under github actions we don't run integration tests. 
    }
    Invoke-RunTestPhase $configuration
    Invoke-NugetPackage $configuration
    Invoke-NugetPush $configuration
}

function Invoke-RunTestPhase($configuration) 
{
    Invoke-RunTests $configuration    
}
Invoke-PreflightCheck
$buildConfigurations = Get-BuildConfigurations -ConfigurationFolder $ConfigurationFolder

Write-Host "=== Build & Test ==="

$buildConfigurations |? { $_.enabled } |%{
    Push-Location (Join-Path (Get-Location) $_.solutionFolder)
    Invoke-RunBuild $_
    Pop-Location
}
Write-Host "=== Build & Test Complete ===" -ForegroundColor Cyan
exit 0
