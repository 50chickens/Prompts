$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

$configDir = Join-Path $PSScriptRoot "configs"

& .\build-test.ps1 -ConfigurationFolder $configDir -NugetSourceName 'LocalRepo'
