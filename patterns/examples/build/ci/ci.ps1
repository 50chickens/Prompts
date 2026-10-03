$ErrorActionPreference = 'Stop'
$VerbosePreference = 'SilentlyContinue'
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
    $configuration | Add-Member -NotePropertyName 'nugetPackageSourceName' -NotePropertyValue 'LocalRepo' -Force

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

function Invoke-BuildTest($configuration)
{
    $nugetPackageSourceName = $configuration.nugetPackageSourceName
    & .\build-test.ps1 -nugetPackageSourceName $nugetPackageSourceName
}

$configuration = Get-Configuration
$configuration = Add-RuntimeConfiguration $configuration
Invoke-PreflightCheck $configuration
Invoke-BuildTest $configuration
