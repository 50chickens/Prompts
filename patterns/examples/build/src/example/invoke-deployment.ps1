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

function Invoke-Deployment($configuration)
{
    $deploymentTarget = $configuration.deploymentTarget
    Write-Log "Deploying to $deploymentTarget"
}

$configuration = Get-Configuration
$configuration = Add-RuntimeConfiguration $configuration
Invoke-PreflightCheck $configuration
Invoke-Deployment $configuration
