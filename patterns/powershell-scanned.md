```
description: Write high-quality, readable PowerShell scripts following these conventions

# How to write good PowerShell scripts

## Banned patterns

### Path / file resolution

| Banned | Reason | Use instead |
|--------|---------|-------------|
| $PSScriptRoot outside `Set-Location` | Breaks when dot-sourced | `(Get-Item "...").FullName` in `Get-Configuration` |
| Join-Path inside functions | Adds path on top of wrong layer | `$base\$sub` string interpolation |
| Split-Path <var> -Parent | Tree navigation not agile | Pre-resolve in `Get-Configuration` |
| Split-Path <var> -Leaf | Requires ad-hoc path-splitting | `Get-FileNameFromUrl` helper or `(Get-Item $f).Name` |
| Split-Path (split-Path ...) nested | Unreadable, breaks depth changes | `(Get-Item "...").FullName` in `Get-Configuration` |
| Multi-level `..\..` inline in a function | Hardcodes depth inside logic | Define root in `Get-Configuration`, pass via `$configuration` |
| [System.IO.Path]::GetRelativePath | .NET class; discouraged | regex helper |
| [System.IO.Path]::GetFullPath | .NET class; discouraged | Pre-resolve absolute paths in `Get-Configuration` |
| ${path -split '[\\/]'}[-1] | String-splitting a path | `Get-FileNameFromUrl` or `(Get-Item $f).Name` |

### Error handling

| Banned | Reason | Use instead |
|--------|---------|-------------|
| try { } catch { return $false } | Converts exceptions into silent success-looking returns |
| try { } catch { return $null } | Same – caller cannot distinguish success from failure |
| -ErrorAction SilentlyContinue on writes/mutations | Silently swallows failures that must surface |
| Get-Command guard before calling a required cmdlet | Hides missing-cmdlet errors; use `Invoke-PreflightCheck` instead |
| if (-not $?) | Use `throw` – let `$ErrorActionPreference` propagate the failure |
| try/catch blocks (except cleanup) | Masks failures; let errors surface naturally |

### Control flow and structure

| Banned | Reason | Use instead |
|--------|---------|-------------|
| foreach ($x in $list) | Use `$list | % { $x = $_ }` pipeline form |
| if ($var -match ...) | For regex branching use `$var -replace` instead |
| Magic strings inline functions | All come from `$configuration` |
| Path arithmetic inside `Invoke-` functions | All come from `$configuration` |
| Multiple inline conditionals | Use `switch` form |
| Return twice -> Communication lost | Assign to variable, then return it |
| Array index access `$array[i]` | Use `Select-Object -Index i` |
| Script-level global variables | Use `Set-Variable -Scope Script` |
| Inline scripts/executables | Place scripts in `assets` or `static` folders and execute them directly |
| `Out-Null` | Do not use; pipeline form is default on Windows; or `-inotmatch` (explicit) |
| `Set-Location` | Path risk; scripts must not change working directory; `Set-Location $PSScriptRoot` and adjust the `..\Init` depth. |
| More than usage or appearance of $PSScriptRoot in the entire script. | In the script header we use `Set-Location $PSScriptRoot`. Any further usage is redundant. Relative paths can be used to resolve any folder locations after this. | use "..\somefolder\somefile.json" not (Get-Item "$PSScriptRoot\..\somefolder\somefile.json").FullName. 
### Parameters

Runtime flags that select behaviour may be passed (e.g. `-resetadminpassword`). Configuration must not be passed between scripts.

| Banned | Reason | Use instead |
|--------|---------|-------------|
| `param()` used to pass configuration from one script to another | Couples the callee to the caller, which must know the callee's config layout | `Get-Configuration` - each script independently loads its own configuration |
| `-ConfigurationFolder` (or any config path) as a parameter | Where the config lives is a concern of the script, not the caller | `Get-Configuration`, which resolves its own config path |
| Add-Member -NotePropertyName 'ApplicationTestsScript' -NotePropertyValue (Some-CalculatedValue $someVariable) -Force. | Calculated variables are another type of runtime variable and do not go into Get-Configuration. | Only pass $someValue to Add-Member. eg $configuration | Add-Member -Value $someValue. 
Accept only the parameters a script expects - for example a delete-stack script takes 0 or 1. Do not accept extra script-level parameters.

### .NET classes

Prefer PowerShell-native equivalents. Only use .NET classes when there is no clean native alternative.

| Banned | Reason | Use instead |
|--------|---------|-------------|
| [System.IO.Path]:: (most methods) | String interpolation, regex helpers |

## .NET classes

Prefer PowerShell-native equivalents. Only use .NET classes when there is no clean native alternative.

.NET class | Prefer instead
|---|---
[System.IO.Path]::* (most methods) | String interpolation, `Get-Item`, regex helpers |
[System.IO.File]::* | `Get-Content`, `Set-Content`, `Test-Path` |
[System.IO.Directory]::* | `Get-ChildItem`, `New-Item -ItemType Directory`, `Test-Path` |
[System.Uri]::* for filename extraction | Simple regex `([^/]+)$` |

## General rules
* Don’t do wildcard/partial matches on resources. Check that you get the expected count of matches - eg 0 or 1. Fail/exit the script immediately upon error. This prevents actions on unintended resources.
* Assume PowerShell 7 only unless told otherwise. No compatibility shims for PowerShell 5.
* Only use ASCII characters in `.ps1` files. No em dashes, curly quotes, or non-ASCII characters.
* Only adopt approved PowerShell style and function names.
* Prefer PowerShell modules over command-line tools. If a suitable module does not exist, install it rather than shelling out.
* Read the examples in the `examples` folder that sits alongside this document.
* Use as few global or script-level variables as possible.
* Do not use `Select-Object`, `Select-String`, `head`, `tail`, `grep`, or shell redirections (`2>&1`), and do not pipe command output into filters - when running command lines and in `.ps1` scripts alike. Iterating collections with `|%` is still expected.
* Keep logging minimal by default. `Write-Host` surfaces only information relevant to the task at hand. Extra detail should come from errors or from raising log verbosity.
* Do not scan for invalid items, collect them into a list, and then report the problematic items.
* Do not write files to disk for debugging purposes. Use a PowerShell transcript when you need a record of what happened.
* Do not add comments unless specifically asked.
* If a script parameter has a default function that always runs - call each step explicitly in the main execution block.
* If a script parameter has a default value, add a short comment on that line explaining why it has a default.
* Repeated statement sequences in the main execution block should be extracted into a helper function.
* Do not add fallbacks, workarounds, or graceful error handling. It is ok if things fail.
* Keep code lightweight and free of logic unrelated to the task at hand.

## Script structure

Every script has this exact top-level structure, in order:

1. Script-level preferences (`$ErrorActionPreference`, `$VerbosePreference`)
2. Set location `$PSScriptRoot` - anchors working directory name if needed
3. `$baseName = Split-Path -Leaf`
4. Dot-source includes (if an includes folder exists)
5. Main execution block at the bottom - a flat sequence of function calls

Script-level variables and constants are defined at the top of the script, above the functions.

```powershell
$ErrorActionPreference = 'Stop'
$VerbosePreference = 'SilentlyContinue'
Set-Location $PSScriptRoot
$baseName = Split-Path -Leaf

Get-ChildItem Path "includes" -Filter "*.ps1" -Recurse | % {
    Write-Verbose "Dot-sourcing ${_.FullName}"
    . $_.FullName
}

# --- functions above ---

$configuration = Get-Configuration
Invoke-PreflightCheck $configuration
Invoke-StepOne $configuration
Invoke-StepTwo $configuration
```

Do not wrap the main execution block in a function or try/catch. Call each step explicitly so the execution path is transparent.

---

## Get-Configuration

```powershell
function Get-Configuration
{
    $configFileName = 'config.json'
    $roleRoot = Split-Path -Parent $PSScriptRoot
    $configDir = "$roleRoot\config"
    $configPath = "$configDir\$configFileName"

    $configuration = Get-Content $configPath | ConvertFrom-Json
    $configuration | Add-Member -NotePropertyName 'RoleRoot' -NotePropertyValue $roleRoot -Force
    $configuration | Add-Member -NotePropertyName 'ConfigPath' -NotePropertyValue $configPath -Force
}
```

The `config` folder consumed by things under `src` is checked in; `ci` configuration is generally not checked in. `ci` and `src` therefore serve different purposes and keep separate configuration of the same shape.

### Configuration sources


- Variables that are constants in the sense that they do not change for the entire period of the script execution, but are known before start script time. But these are variables the user is likely to change from run to run - eg Verbosity leve.  These go into Get-Configuration.
- Variables that are unlikely to change from run to run - eg dotnet solution names. These go into a json file that is loaded by: $configuration = Get-Content $configPath | ConvertFrom-Json. 
- Variables that are unknown at script start time - eg process id's, user profile folders. These go into Add-RuntimeConfiguration. If there are more than one category of runtime variables - 
`$configuration` values come from `Get-Configuration` (static values, similar to constants) and `Add-RuntimeConfiguration` (values knowable only at runtime). Nothing else may add to `$configuration`.
- Pass `$configuration` untyped.
- Do not put script-level preference values (e.g. `VerbosePreference`) into `$configuration`.
- Configuration JSON holds relative paths; do not resolve them with `Resolve-Path`, `Join-Path` or `$PSScriptRoot`.
- When creating feature flags prefer SkipSomeOperation so that if the variable is missing - eg $configuration.SkipSomeOperation is missing it results to false and the operation would still run. We can then avoid adding unneccessary boilerplate to either the .json file or get-configuration. 
### Folder Path Configuration

```powershell
$bootstrapRoot = "$roleRoot\assets\remote\bootstrap"
$packagesDir = "$bootstrapRoot\packages"

$configuration | Add-Member -NotePropertyName 'BootstrapRoot' -NotePropertyValue $bootstrapRoot -Force
$configuration | Add-Member -NotePropertyName 'PackagesDir' -NotePropertyValue $packagesDir -Force
```

## Add-RuntimeConfiguration

```powershell
function Add-RuntimeConfiguration($configuration)
{
    $instanceId = Get-InstanceId
    $configuration | Add-Member -NotePropertyName 'InstanceId' -NotePropertyValue $instanceId -Force
}
```

---

## Invoke-PreflightCheck

Validates conditions required for the script to succeed. All essential validation lives here and nowhere else. Do not write defensive checks inside other functions.

```powershell
function Invoke-PreflightCheck($configuration)
{
    if (-not (Test-Path $configuration.ConfigPath)) { throw "Config not found: $($configuration.ConfigPath)" }
    if (-not $configuration.TargetEnvironment) { throw "TargetEnvironment is required." }
}
```

## Function rules

Every function:
- Takes exactly one parameter: `$configuration`. The only exception is helper functions not called from main execution block.
- Has exactly one purpose. eg create new launch template version and apply it to an autoscale group are two seperate operatation. each of these operations should be a different function.
- Function input should either from $configuration from Get-Configuration, or from a helper function where the input data is a runtime value. 
- Logs the key value(s) it is working with.
- Does not resolve paths, navigate directories, or do path arithmetic.
- Don’t put control flow into Get-Configuration, Add-RuntimeConfiguration or Invoke-PreflightCheck.
- Use Test-Should patterns for early exit.
- When a later step needs a value produced by an earlier step (e.g. a resource Arn), put the identifier on `$configuration` so the later step can look it up. An extra read call is fine.

```powershell
function Invoke-CreateLaunchTemplateVersion($configuration)
{
    if (!(Test-ShouldCreateLaunchTemplateVersion $configuration))
    {
        $launchTemplateVersion = #get launchtemplate version to be used.     
        return
    }
    $launchTemplateVersion = #code to create launch template version here. 
    return $launchTemplateVersion
    # do the step
}
function Invoke-UpdateAutoscaleGroupLaunchTemplate($autoscaleGroup, $launchTemplateVersion)
{
    if (!(Test-ShouldUpdateAutoscaleGroupVersion $autoscaleGroup, $launchTemplateVersion))
    {
        return
    }
    #code to update autoscale group here. 
    # do the step
    return
}
function Invoke-UpdateAutoscaleGroup($configuration)
{
    $autoscaleGroup = #code to get autoscale group here. 
    $launchTemplateVersion = Invoke-CreateLaunchTemplateVersion $configuration
    Invoke-UpdateAutoscaleGroupLaunchTemplate $autoscaleGroup $launchTemplateVersion
}
```

### `exit` vs `return` in functions

`exit` terminates the **entire PowerShell process** — not just the function. Only valid inside top-level guard functions.

Inside all other functions, use `return`.

```powershell
function Invoke-CheckEnabled($configuration)
{
    $flag = $false
    if (![bool]::TryParse($env:EnableFlag, [ref]$flag) -or !$flag) { exit 0 }
}
```

```powershell
function Test-ShouldUpdateBinding($configuration)
{
    $currentBinding = Get-CurrentBinding $configuration
    if ($currentBinding -eq $configuration.RequiredBinding)
    {
        Write-Log "Binding is already correct. Skipping update."
        return $false
    }
    return $true
}
```

```powershell
function Invoke-UpdateBinding($configuration)
{
    if (-not (Test-ShouldUpdateBinding $configuration))
    {
        return
    }
    # perform update
}
```

---

## Output suppression

Never use `| Out-Null`. Use `$null = ...`.

```
$null = New-Item -ItemType Directory -Path $dir
$null = docker rm -f $name
```

## Variable evaluation

```powershell
function Invoke-CheckEnabled
{
    $flag = $false
    if ([string]::IsNullOrEmpty($env:EnableFlag))
    {
        Write-Log "Not enabled (EnableFlag is null or empty)."
        return $false
    }
    if (![bool]::TryParse($env:EnableFlag, [ref]$result))
    {
        Write-Log "Not enabled (EnableFlag is not a valid boolean)."
        return $false
    }
    return $result
}
```

All path construction inside functions uses string interpolation.

```powershell
$outputDir = "${configuration.BootstrapRoot}\${packageList.outputDir}"
$destFile = "$outputDir\$moduleName.nupkg"
```

Build paths stepwise:

```powershell
$bootstrapRoot = "$roleRoot\assets\remote\bootstrap"
$packageDir = "$bootstrapRoot\packages"
$moduleDir = "$packageDir\$moduleName\$version"
```

Filename from URL:

```powershell
function Get-FilenameFromUrl($url)
{
    if ($url -match "/([^/]+)$") { return $matches[1] }
    throw "Cannot derive filename from url '$url'"
}
```

---

## Iteration and conditionals

Use `|%` for iteration:

```powershell
$packages |% {
    $package = $_
    Write-Log "Processing ${package.Name}"
    Invoke-InstallPackage $package $configuration
}
```

Use `|?` for filtering:

```powershell
$files |? { $_.Extension -eq '.pfx' } |% {
    $file = $_
    Invoke-ImportCertificate $file $configuration
}
```

Use `switch -Regex` instead of `if ($x -match ...)`.

When iterating output that only exists at runtime (e.g. `netsh http show urlacl`), capture it first, then match with `switch -Regex`:

```powershell
$urlAcls = netsh http show urlacl
$line = $_
switch -Regex ($line)
{
    # match something here
}
```

---

## Test-Should pattern

```powershell
function Test-ShouldUpdateBinding($configuration)
{
    $currentBinding = Get-CurrentBinding $configuration
    if ($currentBinding -eq $configuration.RequiredBinding)
    {
        Write-Log "Binding is already correct. Skipping update."
        return $false
    }
    return $true
}
```

---

## Wait/retry pattern

```powershell
function Wait-UntilDeploymentComplete($configuration)
{
    $timeoutSeconds = $configuration.DeploymentTimeoutSeconds
    $retryInterval = $configuration.RetryIntervalSeconds
    Write-Log "Waiting up to $timeoutSeconds seconds for deployment. Retry every $retryInterval seconds."
    $isComplete = Test-DeploymentComplete $configuration
    $timeout = (Get-Date).AddSeconds($timeoutSeconds)
    while (-not $isComplete)
    {
        if ((Get-Date) -gt $timeout)
        {
            throw "Timed out after $timeoutSeconds seconds waiting for deployment."
        }
        Start-Sleep $retryInterval
        $isComplete = Test-DeploymentComplete $configuration
    }
}
```

## Logging

Use `Write-Log` for all output. See also the logging pattern in `component_prompts/solutions/ipscm/skils.md`.

```powershell
function Invoke-UploadPackage($configuration)
{
    $packagePath = $configuration.PackagePath
    $s3Bucket = $configuration.S3Bucket
    Write-Log "Uploading $packagePath to s3://$s3Bucket"
    Write-S3Object -BucketName $s3Bucket -File $packagePath
    Write-Log "Upload complete."
}
```

---

## Constants and magic strings

Values used more than once belong in `Get-Configuration`.

```powershell
$configuration | Add-Member -NotePropertyName 'CertStore' -NotePropertyValue 'Cert:\LocalMachine\My' -Force
$configuration | Add-Member -NotePropertyName 'BindingPort' -NotePropertyValue '0.0.0.0:443' -Force
```

---

## IMDSv2 pattern (AWS instance metadata)

```powershell
function Get-ImdsToken {
    return Invoke-RestMethod -Uri 'http://169.254.169.254/latest/api/token' `
        -Method PUT `
        -Headers @{ 'X-aws-ec2-metadata-token-ttl-seconds' = '21600' }
        -TimeoutSec 5
}

function Get-ImdsValue ([string]$path)
{
    $token = Get-ImdsToken
    return Invoke-RestMethod -Uri "http://169.254/latest/meta-data/$path" `
        -Method GET `
        -Headers @{ 'x-aws-ec2-metadata-token' = $token } `
        -TimeoutSec 5
}
```

Usage:
```
$instanceId = Get-ImdsValue 'instance-id'
$region = Get-ImdsValue 'placement/region'
```

---

## External process exit codes

PowerShell does **not** throw on non-zero `$LASTEXITCODE`.

```powershell
docker build -t $imageName $contextDir
if ($LASTEXITCODE -ne 0) { throw "docker build failed (exit $LASTEXITCODE)" }
```

PS 7.3+:

```powershell
$PSNativeCommandUseErrorActionPreference = $true
```

Do not use this on earlier PS versions.