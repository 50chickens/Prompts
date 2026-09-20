Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "     DOCKER WINDOWS CONTAINER BLOCKER AUDIT       " -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan

# 1. Check Windows Edition Compatibility
$osInfo = Get-CimInstance Win32_OperatingSystem
Write-Host "`n[1/5] Checking OS Version Compatibility..." -ForegroundColor Yellow
if ($osInfo.Caption -like "*Home*") {
    Write-Host "❌ BLOCKER FOUND: You are running Windows Home ($($osInfo.Caption)). Windows Home structurally lacks the architecture required for native Windows Containers and locks Docker to Linux containers only." -ForegroundColor Red
} else {
    Write-Host "✅ PASS: OS ($($osInfo.Caption)) supports Windows Containers." -ForegroundColor Green
}

# 2. Check Corporate / Admin Docker Policies
Write-Host "`n[2/5] Checking Registry Group Policies for Docker..." -ForegroundColor Yellow
$policyPaths = @(
    "HKLM:\SOFTWARE\Policies\Docker\Docker Desktop",
    "HKCU:\SOFTWARE\Policies\Docker\Docker Desktop"
)

$policyBlockerFound = $false
foreach ($path in $policyPaths) {
    if (Test-Path $path) {
        $props = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
        if ($props.EnableWindowsContainers -eq 0) {
            Write-Host "❌ BLOCKER FOUND: Registry Policy at '$path' explicitly sets 'EnableWindowsContainers' to 0." -ForegroundColor Red
            $policyBlockerFound = $true
        }
    }
}
if (-not $policyBlockerFound) {
    Write-Host "✅ PASS: No corporate registry policies are forcing Windows containers off." -ForegroundColor Green
}

# 3. Check Windows BitLocker Drive Blockers (FDVDenyWriteAccess Bug)
Write-Host "`n[3/5] Checking BitLocker Storage Policies (Known Docker Volume Blocker)..." -ForegroundColor Yellow
$fvePath = "HKLM:\SYSTEM\CurrentControlSet\Policies\Microsoft\FVE"
if (Test-Path $fvePath) {
    $fveProps = Get-ItemProperty -Path $fvePath -ErrorAction SilentlyContinue
    if ($fveProps.FDVDenyWriteAccess -eq 1) {
        Write-Host "❌ BLOCKER FOUND: 'FDVDenyWriteAccess' is enabled. This corporate policy blocks Docker from writing to internal virtual hard drives, crashing the Windows container engine." -ForegroundColor Red
    } else {
        Write-Host "✅ PASS: 'FDVDenyWriteAccess' policy is clean or not present." -ForegroundColor Green
    }
} else {
    Write-Host "✅ PASS: No restrictive BitLocker group policies found." -ForegroundColor Green
}

# 4. Check Mandatory Admin Hardening Files
Write-Host "`n[4/5] Checking Central Admin-Settings Hardening Files..." -ForegroundColor Yellow
$adminJsonPath = "C:\ProgramData\DockerDesktop\admin-settings.json"
if (Test-Path $adminJsonPath) {
    try {
        $json = Get-Content $adminJsonPath | ConvertFrom-Json
        if ($json.windowsContainersDisabled -eq $true) {
            Write-Host "❌ BLOCKER FOUND: The centralized file at '$adminJsonPath' contains a rule blocking Windows containers." -ForegroundColor Red
        } else {
            Write-Host "⚠️ WARNING: An 'admin-settings.json' file exists. Though not explicitly blocking right now, your device is restricted by an IT administrator configuration." -ForegroundColor Cyan
        }
    } catch {
        Write-Host "⚠️ An admin-settings file exists but could not be parsed." -ForegroundColor Cyan
    }
} else {
    Write-Host "✅ PASS: No centralized admin restrictions found." -ForegroundColor Green
}

# 5. Check Required Windows Features Status
Write-Host "`n[5/5] Checking Underlying Windows OS Subsystems..." -ForegroundColor Yellow
$containersFeature = Get-WindowsOptionalFeature -Online -FeatureName "Containers" -ErrorAction SilentlyContinue
$hypervFeature = Get-WindowsOptionalFeature -Online -FeatureName "Microsoft-Hyper-V" -ErrorAction SilentlyContinue

if ($containersFeature.State -ne "Enabled") {
    Write-Host "❌ BLOCKER FOUND: The Windows OS 'Containers' feature is currently DISABLED or missing." -ForegroundColor Red
}
if ($hypervFeature.State -ne "Enabled") {
    Write-Host "❌ BLOCKER FOUND: The Windows OS 'Hyper-V' feature is currently DISABLED or missing." -ForegroundColor Red
}
if ($containersFeature.State -eq "Enabled" -and $hypervFeature.State -eq "Enabled") {
    Write-Host "✅ PASS: Subsystems (Containers & Hyper-V) are fully active." -ForegroundColor Green
}

Write-Host "`n====================================================" -ForegroundColor Cyan
Write-Host "                 AUDIT COMPLETE                    " -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
