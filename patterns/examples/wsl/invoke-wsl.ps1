param(
    [Parameter(Mandatory)][string]$Script,
    [string]$Distro
)

$ErrorActionPreference = 'Stop'
$VerbosePreference = 'SilentlyContinue'
$PSNativeCommandUseErrorActionPreference = $true
Set-Location $PSScriptRoot
$baseName = (Get-Item '.').Name

function Write-Log($message)
{
    Write-Host "[$baseName] $message"
}

function Get-Configuration
{
    $configuration = [pscustomobject]@{}
    $configuration | Add-Member -NotePropertyName 'MountPoint' -NotePropertyValue '/mnt/c' -Force
    $configuration | Add-Member -NotePropertyName 'TargetUid' -NotePropertyValue 1000 -Force
    $configuration | Add-Member -NotePropertyName 'TargetScriptPath' -NotePropertyValue $Script -Force
    $configuration | Add-Member -NotePropertyName 'Distro' -NotePropertyValue $Distro -Force

    return $configuration
}

function Add-RuntimeConfiguration($configuration)
{
    $wslArguments = Get-WslArguments $configuration
    $configuration | Add-Member -NotePropertyName 'WslArguments' -NotePropertyValue $wslArguments -Force

    $terminateArguments = Get-TerminateArguments $configuration
    $configuration | Add-Member -NotePropertyName 'TerminateArguments' -NotePropertyValue $terminateArguments -Force

    $mountOwnerUid = Get-MountOwnerUid $configuration
    $configuration | Add-Member -NotePropertyName 'MountOwnerUid' -NotePropertyValue $mountOwnerUid -Force

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

function Get-TerminateArguments($configuration)
{
    $terminateArguments = @('--terminate')
    if ($configuration.Distro)
    {
        $terminateArguments = @('--terminate', $configuration.Distro)
    }
    return $terminateArguments
}

function Invoke-Wsl($configuration, $arguments)
{
    $wslArguments = @($configuration.WslArguments) + @($arguments)
    return & wsl @wslArguments
}

function Get-MountOwnerUid($configuration)
{
    return [int](Invoke-Wsl $configuration @('-e', 'stat', '-c', '%u', $configuration.MountPoint))
}

function Test-ShouldRestartDistribution($configuration)
{
    return $configuration.MountOwnerUid -ne $configuration.TargetUid
}

function Invoke-RestartDistribution($configuration)
{
    if (-not (Test-ShouldRestartDistribution $configuration))
    {
        Write-Log "$($configuration.MountPoint) is owned by uid $($configuration.MountOwnerUid)."
        return
    }
    Write-Log "$($configuration.MountPoint) is owned by uid $($configuration.MountOwnerUid), not uid $($configuration.TargetUid). Restarting the distribution."
    Invoke-Wsl $configuration $configuration.TerminateArguments
    Invoke-Wsl $configuration @('-e', 'true')
    $mountOwnerUid = Get-MountOwnerUid $configuration
    if ($mountOwnerUid -ne $configuration.TargetUid)
    {
        throw "$($configuration.MountPoint) is still owned by uid $mountOwnerUid. Run wsl --shutdown and retry."
    }
}

function Invoke-TargetScript($configuration)
{
    Write-Log "Running $($configuration.TargetScriptPath)"
    $wslArguments = @($configuration.WslArguments) + @('-u', 'root', '-e', $configuration.TargetScriptPath)
    & wsl @wslArguments
}

$configuration = Get-Configuration
$configuration = Add-RuntimeConfiguration $configuration
Invoke-PreflightCheck $configuration
Invoke-RestartDistribution $configuration
Invoke-TargetScript $configuration
