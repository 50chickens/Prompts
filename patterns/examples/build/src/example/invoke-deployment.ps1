param(
    [string]$ConfigurationFolder, # Folder containing configuration files
    [string]$ConfigurationfileName # Configuration file name
)

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

$includesDir = Join-Path $PSScriptRoot "includes"

get-childitem -Path $includesDir -Filter '*.ps1' |%{
    Write-Log "Sourcing $($_.Name)"
    . $_.FullName 
}

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

$configuration = Get-Configuration -ConfigurationFolder $ConfigurationFolder -configurationFileName $configurationfileName
Invoke-Function1($configuration)
{
    # Placeholder for the actual function implementation
}

Invoke-Function1 -Configuration $configuration