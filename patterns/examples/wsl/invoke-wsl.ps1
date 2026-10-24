param(
    [Parameter(Mandatory)][string]$Script
)

$ErrorActionPreference = 'Stop'
$VerbosePreference = 'SilentlyContinue'
$PSNativeCommandUseErrorActionPreference = $true
$env:WSL_UTF8 = '1'
Set-Location $PSScriptRoot
$baseName = (Get-Item '.').Name

function Write-Log($message)
{
    Write-Host "[$baseName] $message"
}

function Get-Configuration
{
    # Version group orders Ubuntu-26.04 above Ubuntu-24.04 whatever the order wsl lists them in.
    $distroRegex = [regex]'Ubuntu-(?<Version>\d+\.\d+)'
    $shouldSetDistroAsDefault = $true
    $configuration = [pscustomobject]@{}
    $configuration | Add-Member -NotePropertyName 'TargetScriptPath' -NotePropertyValue $Script -Force
    $configuration | Add-Member -NotePropertyName 'DistroRegex' -NotePropertyValue $distroRegex -Force
    $configuration | Add-Member -NotePropertyName 'ShouldSetDistroAsDefault' -NotePropertyValue $shouldSetDistroAsDefault -Force

    return $configuration
}
function Get-LatestDistro($configuration)
{
    $distroRegex = $configuration.DistroRegex
    $distros = wsl --list --quiet
    $latestDistro = $null
    $latestVersion = $null
    foreach ($distro in $distros)
    {
        if ($distro -notmatch $distroRegex)
        {
            continue
        }
        $candidateDistro = $distro.Trim()
        $candidateVersion = [version]$Matches['Version']
        Write-Log "Found $candidateDistro (version $candidateVersion)."
        if ($null -eq $latestVersion -or $candidateVersion -gt $latestVersion)
        {
            $latestDistro = $candidateDistro
            $latestVersion = $candidateVersion
        }
    }
    if (-not $latestDistro)
    {
        throw "No WSL distribution matches $distroRegex. Available: $($distros -join ', ')"
    }
    Write-Log "Latest distribution is $latestDistro (version $latestVersion)."
    return $latestDistro
}

function Get-DefaultDistro($configuration)
{
    $verboseList = wsl --list --verbose
    foreach ($line in $verboseList)
    {
        if ($line -match '^\s*\*\s*(?<Distro>\S+)')
        {
            return $Matches['Distro']
        }
    }
    return $null
}

function Add-RuntimeConfiguration($configuration)
{
    $distro = Get-LatestDistro $configuration
    $configuration | Add-Member -NotePropertyName 'Distro' -NotePropertyValue $distro -Force

    $wslArguments = Get-WslArguments $configuration
    $configuration | Add-Member -NotePropertyName 'WslArguments' -NotePropertyValue $wslArguments -Force

    $defaultDistro = Get-DefaultDistro $configuration
    $configuration | Add-Member -NotePropertyName 'DefaultDistro' -NotePropertyValue $defaultDistro -Force

    return $configuration
}

function Invoke-PreflightCheck($configuration)
{
    if (-not $configuration.TargetScriptPath.StartsWith('/mnt/'))
    {
        throw "TargetScriptPath must be a WSL path under /mnt, not $($configuration.TargetScriptPath)"
    }
}

function Get-WslArguments($configuration)
{
    $wslArguments = @()
    if ($configuration.Distro)
    {
        $wslArguments = @('-d', $configuration.Distro)
    }
    return $wslArguments
}

function Invoke-Wsl($configuration, $arguments)
{
    $wslArguments = @($configuration.WslArguments) + @($arguments)
    return & wsl @wslArguments
}

function Test-ShouldSetDistroAsDefault($configuration)
{
    if (-not $configuration.ShouldSetDistroAsDefault)
    {
        Write-Log "ShouldSetDistroAsDefault is false."
        return $false
    }
    $defaultDistro = $configuration.DefaultDistro
    if ($defaultDistro -eq $configuration.Distro)
    {
        Write-Log "$defaultDistro is already the default WSL distribution."
        return $false
    }
    return $true
}

function Invoke-SetDistroAsDefault($configuration)
{
    if (-not (Test-ShouldSetDistroAsDefault $configuration))
    {
        return
    }
    $distro = $configuration.Distro
    Write-Log "Setting $distro as the default WSL distribution, replacing $($configuration.DefaultDistro)."
    $null = & wsl --set-default $distro
    $defaultDistro = Get-DefaultDistro $configuration
    $configuration | Add-Member -NotePropertyName 'DefaultDistro' -NotePropertyValue $defaultDistro -Force
    if ($defaultDistro -ne $distro)
    {
        throw "Failed to set $distro as the default WSL distribution. The default is $defaultDistro."
    }
    Write-Log "$defaultDistro is the default WSL distribution."
}

function Invoke-TargetScript($configuration)
{
    $targetScriptPath = $configuration.TargetScriptPath
    Write-Log "Running $targetScriptPath on $($configuration.Distro)."
    Invoke-Wsl $configuration @('-e', $targetScriptPath)
}

$configuration = Get-Configuration
Invoke-PreflightCheck $configuration
$configuration = Add-RuntimeConfiguration $configuration
Invoke-SetDistroAsDefault $configuration
Invoke-TargetScript $configuration

