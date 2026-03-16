param(
    [string]$ConfigurationFolder  # path to folder containing JSON configuration files
)

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

function Invoke-PreflightCheck($configurationFolder) {
    if ([string]::IsNullOrWhiteSpace($configurationFolder) -or -not (Test-Path $configurationFolder)) {
        Write-Error "ConfigurationFolder not specified or not found: $configurationFolder"
        exit 1
    }
}

function Get-Configurations($configurationFolder) {
    $configFiles = Get-ChildItem -Path $configurationFolder -Filter '*.json' | Sort-Object Name
    $configs = @()
    foreach ($file in $configFiles) {
        $configs += Get-Content $file.FullName -Raw | ConvertFrom-Json
    }
    return $configs | Sort-Object { if ($_.executionOrder) { $_.executionOrder } else { 99 } }
}

function Add-AdditionalConfiguration($configuration) {
    $deployDir = Join-Path $PSScriptRoot "fs-resize/deploy"
    $configuration | Add-Member -NotePropertyName 'deployDir' -NotePropertyValue $deployDir
    return $configuration
}

function Invoke-InstallBuildDependencies($configuration) {
    Write-Host "Installing build dependencies..."
    sudo apt-get update -qq
    sudo apt-get install -y --no-install-recommends quilt parted coreutils debootstrap zerofree dosfstools `
        libcap2-bin libarchive-tools rsync xz-utils curl xxd file bc gpg
}

function Invoke-BuildDistribution($configuration) {
    $imgFiles = Get-ChildItem -Path $configuration.deployDir -Filter '*.img' -ErrorAction SilentlyContinue
    if ($imgFiles) {
        Write-Host "Distribution image already exists, skipping build"
        return
    }

    Write-Host "Building distribution image (this takes several minutes)..."
    $buildScript = Join-Path $PSScriptRoot "fs-resize/build.sh"

    $env:TARGET_HOSTNAME = $configuration.hostname
    $env:FIRST_USER_NAME = $configuration.firstUserName
    $env:FIRST_USER_PASS = $configuration.firstUserPass
    $env:ENABLE_SSH = "1"
    $env:DEPLOY_DIR = $configuration.deployDir

    sudo --preserve-env=TARGET_HOSTNAME,FIRST_USER_NAME,FIRST_USER_PASS,ENABLE_SSH,DEPLOY_DIR bash $buildScript
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Distribution build failed"
        exit 1
    }
    Write-Host "Distribution build complete"
}

function Invoke-VerifyDistribution($configuration) {
    Write-Host "Verifying distribution image..."
    $imgFiles = Get-ChildItem -Path $configuration.deployDir -Filter '*.img' -ErrorAction SilentlyContinue
    if (-not $imgFiles) {
        Write-Error "No disk image found in $($configuration.deployDir) after build"
        exit 1
    }
    $img = $imgFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    Write-Host "Distribution image verified: $($img.Name) ($([math]::Round($img.Length / 1MB, 1)) MB)"
}

Invoke-PreflightCheck $ConfigurationFolder
$configurations = Get-Configurations $ConfigurationFolder

$configurations | Where-Object { $_.enabled } | ForEach-Object {
    $configuration = Add-AdditionalConfiguration $_
    Write-Host "=== $($configuration.vmName) ==="
    Invoke-InstallBuildDependencies $configuration
    Invoke-BuildDistribution $configuration
    Invoke-VerifyDistribution $configuration
}

