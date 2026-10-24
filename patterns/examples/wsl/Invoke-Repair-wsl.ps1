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
    $distroRegex = [regex]'Ubuntu-(?<Version>\d+\.\d+)'
    $configuration = [pscustomobject]@{}
    $configuration | Add-Member -NotePropertyName 'MountPoint' -NotePropertyValue '/mnt/c' -Force
    $configuration | Add-Member -NotePropertyName 'TargetUid' -NotePropertyValue 1000 -Force
    $configuration | Add-Member -NotePropertyName 'DistroRegex' -NotePropertyValue $distroRegex -Force
    return $configuration
}

function Add-RuntimeConfiguration($configuration)
{
    $distro = Get-LatestDistro $configuration
    $configuration | Add-Member -NotePropertyName 'Distro' -NotePropertyValue $distro -Force

    $wslArguments = @('-d', $distro)
    $configuration | Add-Member -NotePropertyName 'WslArguments' -NotePropertyValue $wslArguments -Force

    $terminateArguments = @('--terminate', $distro)
    $configuration | Add-Member -NotePropertyName 'TerminateArguments' -NotePropertyValue $terminateArguments -Force

    $mountOwnerUid = Get-MountOwnerUid $configuration
    $configuration | Add-Member -NotePropertyName 'MountOwnerUid' -NotePropertyValue $mountOwnerUid -Force

    return $configuration
}

function Invoke-PreflightCheck($configuration)
{
    if (-not $configuration.MountPoint.StartsWith('/mnt/'))
    {
        throw "MountPoint must be a WSL path under /mnt, not $($configuration.MountPoint)"
    }
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
    Write-Log "Repairing $latestDistro (version $latestVersion)."
    return $latestDistro
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
    $mountOwnerUid = $configuration.MountOwnerUid
    if ($mountOwnerUid -eq $configuration.TargetUid)
    {
        Write-Log "$($configuration.MountPoint) is owned by uid $mountOwnerUid."
        return $false
    }
    return $true
}

function Invoke-RestartDistribution($configuration)
{
    if (-not (Test-ShouldRestartDistribution $configuration))
    {
        return
    }
    $mountPoint = $configuration.MountPoint
    $distro = $configuration.Distro
    Write-Log "$mountPoint is owned by uid $($configuration.MountOwnerUid), not uid $($configuration.TargetUid). Restarting $distro."
    $null = & wsl @($configuration.TerminateArguments)
    $null = Invoke-Wsl $configuration @('-e', 'true')
    $mountOwnerUid = Get-MountOwnerUid $configuration
    $configuration | Add-Member -NotePropertyName 'MountOwnerUid' -NotePropertyValue $mountOwnerUid -Force
    if ($mountOwnerUid -ne $configuration.TargetUid)
    {
        throw "$mountPoint is still owned by uid $mountOwnerUid. Run wsl --shutdown and retry."
    }
    Write-Log "$mountPoint is now owned by uid $mountOwnerUid."
}

$configuration = Get-Configuration
Invoke-PreflightCheck $configuration
$configuration = Add-RuntimeConfiguration $configuration
Invoke-RestartDistribution $configuration
