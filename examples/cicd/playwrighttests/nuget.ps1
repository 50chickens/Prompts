# Manages NuGet package creation for the solution.
# Calls MSBuild target in build.xml to create packages from projects marked for packaging.
# All configuration comes from build-configuration.json (single source of truth).

$ErrorActionPreference = 'Stop'
$nugetRepositoryName = "github"
$nugetConfigFileName = "nuget.config"
$nugetRepoPath = "c:\dev\nuget-local-repo"
$buildConfigFileName = "build-configuration.json"
$nupkgOutFolder = "nupkgOut"
# Get directory paths
$ciDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$srcDir = Join-Path $ciDir ".." "src"

# Load build configuration
function Get-BuildConfig {
    param([string]$ConfigPath)
    
    if (-not (Test-Path $ConfigPath)) {
        throw "build-configuration.json not found at $ConfigPath"
    }
    
    return Get-Content $ConfigPath | ConvertFrom-Json
}

# Function to check if LocalRepo is configured in nuget.config
function Get-LocalRepoPath {
    param([string]$NugetConfigPath)
    
    if (-not (Test-Path $NugetConfigPath)) {
        throw "nuget.config not found at $NugetConfigPath"
    }
    
    [xml]$nugetConfig = Get-Content $NugetConfigPath
    $localRepoNode = $nugetConfig.SelectSingleNode("//packageSources/add[@key='$nugetRepositoryName']")
    
    if ($null -eq $localRepoNode) {
        throw "$nugetRepositoryName package source not found in nuget.config"
    }
    
    return $localRepoNode.GetAttribute('value')
}

# Main execution
$originalLocation = Get-Location

try {
    Set-Location $srcDir
    Write-Host "Current Directory: $(Get-Location)"
    Write-Host "NuGet Package Creation"
    
    
    # Verify build.xml exists
    if (-not (Test-Path "build.xml")) {
        throw "build.xml not found in $srcDir"
    }
    
    # Load configuration
    $configPath = Join-Path $srcDir $buildConfigFileName
    $config = Get-BuildConfig -ConfigPath $configPath
    
    # Get LocalRepo path from nuget.config
    $nugetConfigPath = Join-Path $srcDir $nugetConfigFileName
    $localRepoPath = Get-LocalRepoPath -NugetConfigPath $nugetConfigPath
    
    Write-Host "Configuration: $($config.build.configuration)"
    Write-Host "Local Repository: $localRepoPath"
    
    
    # Verify LocalRepo exists
    if (-not (Test-Path $localRepoPath)) {
        throw "$nugetRepositoryName path not found: $localRepoPath"
    }
    
    # Call dotnet build with the CreateNugetPackages target from build.xml
    Write-Host "Building NuGet packages via MSBuild target..."
    & dotnet build build.xml -t:CreateNugetPackages
    
    if ($LASTEXITCODE -ne 0) {
        throw "NuGet package creation failed with exit code $LASTEXITCODE"
    }
    
    # Report created packages
    $packages = Get-ChildItem -Path $nupkgOutFolder -Filter "*.nupkg" -ErrorAction SilentlyContinue
    
    if ($packages) {
        
        Write-Host "Created $(($packages | Measure-Object).Count) NuGet package(s):"
        foreach ($pkg in $packages) {
            Write-Host "  $($pkg.Name)"
        }
        
        # Push packages to LocalRepo
        
        Write-Host "Pushing packages to $nugetRepositoryName..."
        foreach ($pkg in $packages) {
            Write-Host "  Pushing $($pkg.Name)..."
            & dotnet nuget push "$($pkg.FullName)" --source $nugetRepositoryName
            
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to push package $($pkg.Name)"
            }
        }
        
        
        Write-Host "Packages pushed to: $localRepoPath"
    }
    
    
    Write-Host "NuGet Package Creation Complete"
    Write-Host "Packages location: nupkgOut"
    
    exit 0
}
catch {
    Write-Error "ERROR: $_"
    exit 1
}
finally {
    Set-Location $originalLocation
}