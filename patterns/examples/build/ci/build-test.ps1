param(
    [string]$nugetPackageSourceName = 'github' # runtime flag; defaults to the shared github feed
)

$ErrorActionPreference = 'Stop'
$VerbosePreference = 'SilentlyContinue'
$PSNativeCommandUseErrorActionPreference = $true
Set-Location $PSScriptRoot
$baseName = (Get-Item $PSScriptRoot).Name

Get-ChildItem -Path "includes" -Filter '*.ps1' -Recurse |% {
    Write-Verbose "Dot-sourcing $($_.FullName)"
    . $_.FullName
}

function Get-Configuration
{
    # $PSScriptRoot is permitted in Get-Configuration only; it is banned in every other function in this script.
    $configFileName = 'config.json'
    $configDir = "$PSScriptRoot/config"
    $configPath = "$configDir/$configFileName"

    $configuration = Get-Content $configPath | ConvertFrom-Json
    $configuration | Add-Member -NotePropertyName 'ConfigPath' -NotePropertyValue $configPath -Force
    $configuration | Add-Member -NotePropertyName 'SolutionPath' -NotePropertyValue "$PSScriptRoot/$($configuration.solutionFolder)/$($configuration.solutionFile)" -Force
    $configuration | Add-Member -NotePropertyName 'BuildFilePath' -NotePropertyValue "$PSScriptRoot/$($configuration.buildFile)" -Force
    $configuration | Add-Member -NotePropertyName 'NupkgOutFolder' -NotePropertyValue "$PSScriptRoot/$($configuration.nupkgOutFolder)" -Force
    $configuration | Add-Member -NotePropertyName 'nugetPackageSourceName' -NotePropertyValue $nugetPackageSourceName -Force

    return $configuration
}

function Add-RuntimeConfiguration($configuration)
{
    return $configuration
}

function Invoke-PreflightCheck($configuration)
{
    if (-not (Test-Path $configuration.ConfigPath))
    {
        throw "Config not found: $($configuration.ConfigPath)"
    }
}

function Invoke-RestoreDependencies($configuration)
{
    $solutionPath = $configuration.SolutionPath
    Write-Log "Restoring $solutionPath"
    dotnet restore $solutionPath
}

function Invoke-BuildSolution($configuration)
{
    $solutionPath = $configuration.SolutionPath
    $buildConfiguration = $configuration.build.configuration
    $verbosity = $configuration.build.verbosity
    Write-Log "Building $solutionPath"
    dotnet build $solutionPath --configuration $buildConfiguration --verbosity $verbosity --nologo
}

function Invoke-RunTests($configuration)
{
    $solutionPath = $configuration.SolutionPath
    $buildConfiguration = $configuration.build.configuration
    $verbosity = $configuration.test.verbosity
    Write-Log "Testing $solutionPath"
    dotnet test $solutionPath --configuration $buildConfiguration --verbosity $verbosity --nologo
}

function Invoke-NugetPack($configuration)
{
    $buildFilePath = $configuration.BuildFilePath
    $buildConfiguration = $configuration.build.configuration
    Write-Log "Packing $buildFilePath for $buildConfiguration"
    dotnet build $buildFilePath -t:CreateNugetPackages -p:Configuration=$buildConfiguration -p:PackageTags=$buildConfiguration
}

function Invoke-NugetPush($configuration)
{
    $nugetPackageSourceName = $configuration.nugetPackageSourceName
    $nupkgOutFolder = $configuration.NupkgOutFolder
    Get-ChildItem -Path $nupkgOutFolder -Filter '*.nupkg' |% {
        $package = $_
        Write-Log "Pushing $($package.Name) to $nugetPackageSourceName"
        dotnet nuget push $package.FullName --source $nugetPackageSourceName
    }
}

$configuration = Get-Configuration
$configuration = Add-RuntimeConfiguration $configuration
Invoke-PreflightCheck $configuration
Invoke-RestoreDependencies $configuration
Invoke-BuildSolution $configuration
Invoke-RunTests $configuration
Invoke-NugetPack $configuration
Invoke-NugetPush $configuration
