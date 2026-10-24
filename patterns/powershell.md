## PowerShell patterns.

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
| try { } catch { return $false } | Converts exceptions into silent success-looking returns | |
| try { } catch { return $null } | Same - caller cannot distinguish success from failure | |
| -ErrorAction SilentlyContinue on writes/mutations | Silently swallows failures that must surface | |
| Get-Command guard before calling a required cmdlet | Hides missing-cmdlet errors; use `Invoke-PreflightCheck` instead | |
| if (-not $?) | Use `throw` - let `$ErrorActionPreference` propagate the failure | |
| `exit 1` (or any `exit` outside a top-level guard) | Terminates the whole process from inside a function, so later steps never run | `throw` - let `$ErrorActionPreference` propagate the failure |
| try/catch blocks (except cleanup) | Masks failures; let errors surface naturally | |

### Control flow and structure

| Banned | Reason | Use instead |
|--------|---------|-------------|
| Multiple inline conditionals | Use `switch` form | |
| Backtick line continuation | Unreadable, and breaks on a trailing space | Splatting or string interpolation |
| Nested functions | The inner copy shadows the outer function and cannot be called elsewhere | Keep functions flat; return early instead of nesting |
| `if`/`elseif`/`else` chain testing unrelated conditions | Each branch is really a different named state | A `Get-*` function returning one state value via early exits, then `switch` on it |
| `if`/`else` in the main execution block | Idempotency and gating belong inside the function that performs the step | A flat sequence of calls, each gated inside its own function |
| Return twice -> Communication lost | Assign to variable, then return it | |
| Array index access `$array[i]` | Use `Select-Object -Index i` | |
| Script-level global variables | Use `Set-Variable -Scope Script` | |
| Inline scripts/executables | Place scripts in `assets` or `static` folders and execute them directly | |
| `Set-Location` | Path risk; scripts must not change working directory | `Set-Location $PSScriptRoot` and adjust the `..\Init` depth |
| More than usage or appearance of $PSScriptRoot in the entire script | Any further usage is redundant | `"..\somefolder\somefile.json"`, not `(Get-Item "$PSScriptRoot\..\somefolder\somefile.json").FullName` |

### Parameters

Runtime flags that select behaviour may be passed (e.g. `-resetadminpassword`). Configuration must not be passed between scripts.

| Banned | Reason | Use instead |
|--------|---------|-------------|
| `param()` used to pass configuration from one script to another | Couples the callee to the caller, which must know the callee's config layout | `Get-Configuration` - each script independently loads its own configuration |
| `-ConfigurationFolder` (or any config path) as a parameter | Where the config lives is a concern of the script, not the caller | `Get-Configuration`, which resolves its own config path |
| Add-Member with a calculated -NotePropertyValue (Some-CalculatedValue $someVariable) | Calculated values are runtime variables and do not go into Get-Configuration | Only pass $someValue to Add-Member |

Accept only the parameters a script expects - for example a delete-stack script takes 0 or 1. Do not accept extra script-level parameters.

### .NET classes

Prefer PowerShell-native equivalents. Only use .NET classes when there is no clean native alternative.

| .NET class | Prefer instead |
|---|---|
| [System.IO.Path]::* (most methods) | String interpolation, `Get-Item`, regex helpers |
| [System.IO.File]::* | `Get-Content`, `Set-Content`, `Test-Path` |
| [System.IO.Directory]::* | `Get-ChildItem`, `New-Item -ItemType Directory`, `Test-Path` |
| [System.Uri]::* for filename extraction | Simple regex `([^/]+)$` |

## General rules

* Don't do wildcard/partial matches on resources. Check that you get the expected count of matches - eg 0 or 1. Fail/exit the script immediately upon error. This prevents actions on unintended resources.
* Assume PowerShell 7 only unless told otherwise. No compatibility shims for PowerShell 5.
* Only use ASCII characters in `.ps1` files. No em dashes, curly quotes, or non-ASCII characters.
* Only adopt approved PowerShell style and function names.
* Prefer PowerShell modules over command-line tools. If a suitable module does not exist, install it rather than shelling out.
* Read the examples in the `examples` folder beside this document.
* Do not use `Select-Object`, `Select-String`, `head`, `tail`, `grep`, or shell redirections (`2>&1`), and do not pipe command output into filters - when running command lines and in `.ps1` scripts alike. Iterating collections with `|%` is still expected.
* Keep logging minimal by default. `Write-Host` surfaces only information relevant to the task at hand. Extra detail should come from errors or from raising log verbosity.
* Do not scan for invalid items, collect them into a list, and then report the problematic items.
* Do not write files to disk for debugging purposes. Use a PowerShell transcript when you need a record of what happened.
* Do not add comments unless specifically asked.
* If a script parameter has a default value, add a short comment on that line explaining why it has a default.
* Do not add fallbacks, workarounds, or graceful error handling. It is ok if things fail.
* Keep code lightweight and free of logic unrelated to the task at hand.
* In PowerShell, a hex literal above int32::MaxValue parses as a negative int32, so 0xC4403D78 is not the value you wrote and comparisons against it silently match nothing. Write 0xC4403D78L. Treat any hex literal with the top bit set as needing the L suffix.

## Script structure

Every script follows this top-level order: script-level preferences, `Set-Location $PSScriptRoot`, `$baseName`, dot-sourced includes, then the main execution block at the bottom as a flat sequence of function calls. Script-level variables and constants are defined at the top, above the functions.

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

Do not verify a json config file in the terminal. A malformed file or a missing key fails inside the script that loads it through Get-Configuration, and that failure is the check.

### Configuration sources

`$configuration` values come from `Get-Configuration` (static values, similar to constants) and `Add-RuntimeConfiguration` (values knowable only at runtime). Nothing else may add to `$configuration`.

- Values known before start time that the user may change per run, eg verbosity, and values unlikely to change, eg solution names, go into the json file loaded by `Get-Content $configPath | ConvertFrom-Json`.
- Values unknown at script start time, eg process ids and user profile folders, go into `Add-RuntimeConfiguration`.
- Pass `$configuration` untyped. Do not put script-level preference values (e.g. `VerbosePreference`) into it.
- Configuration JSON holds relative paths; do not resolve them with `Resolve-Path`, `Join-Path` or `$PSScriptRoot`.
- Prefer a SkipSomeOperation flag, so a missing `$configuration.SkipSomeOperation` resolves to false and the operation still runs, with no boilerplate in the json file or `Get-Configuration`.

### Folder path configuration

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
- Takes exactly one parameter: `$configuration`. The only exception is helper functions not called from the main execution block.
- Has exactly one purpose. Creating a launch template version and applying it to an autoscale group are two separate operations, so each is a different function.
- Takes input either from `$configuration` or from a helper function where the input is a runtime value.
- Logs the key value(s) it is working with.
- Does not resolve paths, navigate directories, or do path arithmetic.
- Uses `Test-Should` functions for early exit.

Do not put control flow into `Get-Configuration`, `Add-RuntimeConfiguration` or `Invoke-PreflightCheck`.

When a later step needs a value produced by an earlier step (e.g. a resource Arn), put the identifier on `$configuration` so the later step can look it up. An extra read call is fine.

```powershell
function Invoke-UpdateAutoscaleGroup($configuration)
{
    if (!(Test-ShouldUpdateAutoscaleGroup $configuration))
    {
        return
    }
    $autoscaleGroup = #code to get autoscale group here.
    $launchTemplateVersion = Invoke-CreateLaunchTemplateVersion $configuration
    Invoke-UpdateAutoscaleGroupLaunchTemplate $autoscaleGroup $launchTemplateVersion
}
```

## Variable access

When a list of objects is required, put them in json as a list of objects with an enabled property rather than as separate property names.

```powershell
"scriptsToExecute": [{
    "enabled": true,
    "filePath": ".\\some-script.ps1"
  }]

$scriptsToExecute = $configuration.ScriptsToExecute
$scriptsToExecute |? { $_.Enabled } |% {
    #execute script here.
}
```

Do not do `$scripts = @($configuration.BuildTestStageScript, $configuration.ApplicationTestsStageScript)`. It is a needless round trip of objects and creates a fragile json structure.

## exit vs return

`exit` terminates the entire PowerShell process - not just the function. Only valid inside top-level guard functions. Inside all other functions, use `return`.

```powershell
function Invoke-CheckEnabled($configuration)
{
    $flag = $false
    if (![bool]::TryParse($env:EnableFlag, [ref]$flag) -or !$flag) { exit 0 }
}
```

## Output suppression

Never use `| Out-Null`. Use `$null = ...`.

```powershell
$null = New-Item -ItemType Directory -Path $dir
$null = docker rm -f $name
```

## Path construction

All path construction inside functions uses string interpolation, built stepwise.

```powershell
$bootstrapRoot = "$roleRoot\assets\remote\bootstrap"
$packageDir = "$bootstrapRoot\packages"
$moduleDir = "$packageDir\$moduleName\$version"
$destFile = "$moduleDir\$moduleName.nupkg"
```

Filename from URL:

```powershell
function Get-FilenameFromUrl($url)
{
    if ($url -match "/([^/]+)$") { return $matches[1] }
    throw "Cannot derive filename from url '$url'"
}
```

## Iteration and conditionals

Iterate with the pipeline, not the foreach statement. Banned is the `foreach (` keyword. Use `$collection |% { ... }`. A loop that must stop early or index positionally is the exception.

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

Use `switch -Regex` instead of `if ($x -match ...)`. When iterating output that only exists at runtime (e.g. `netsh http show urlacl`), capture it first, then match with `switch -Regex`:

```powershell
$urlAcls = netsh http show urlacl
$line = $_
switch -Regex ($line)
{
    # match something here
}
```

## Grouping repeated near-identical statements

When the same statement shape appears more than twice with only a name or value changing (validation checks, tag lookups, find/replace rules), loop over an array of names or `[pscustomobject]` rules instead of hand-writing one `if`/`throw` per value.
```powershell
function Invoke-PreflightCheck($configuration)
{
    @('ResourceBucket', 'ReleaseVersion', 'StackName') |% {
        if ([string]::IsNullOrWhiteSpace($configuration.$_))
        {
            throw "$_ is required."
        }
    }
}
```

The same applies to replacements - build `[pscustomobject]@{ ReplaceFrom = ...; ReplaceTo = ... }` rules and iterate, checking idempotency before each replacement.

## Per-item detail objects in loops

When a loop body needs several derived values per item, derive them once into a single `[pscustomobject]` from a dedicated `Get-*Details` function and pass that object through the `Invoke-` steps. Do not re-derive the same value in each step, and do not leak the values into implicit shared scope.

```powershell
function Get-PackageDetails($configuration, $package)
{
    $packageFileName = Get-FilenameFromUrl $package.Url
    return [pscustomobject]@{
        Package = $package
        PackageFilePath = "$($configuration.PackageDir)\$packageFileName"
        PackageFolderDir = "$($configuration.PackageDir)\$($package.Name)"
    }
}

function Invoke-InstallPackages($configuration)
{
    $configuration.Manifest |% {
        $packageDetails = Get-PackageDetails $configuration $_
        Invoke-DownloadPackage $packageDetails
        Invoke-InstallPackage $packageDetails
    }
}
```

Assign every value the loop body uses to a local variable first. A mistyped property in a template string resolves to `$null` silently and an unqualified name reads the outer scope, so check each property name against the object definition.

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

Use `Write-Log` for all output.

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

## Constants and magic strings

Values used more than once belong in `Get-Configuration`.

```powershell
$configuration | Add-Member -NotePropertyName 'CertStore' -NotePropertyValue 'Cert:\LocalMachine\My' -Force
$configuration | Add-Member -NotePropertyName 'BindingPort' -NotePropertyValue '0.0.0.0:443' -Force
```

## IMDSv2 pattern (AWS instance metadata)

```powershell
function Get-ImdsToken {
    return Invoke-RestMethod -Uri 'http://169.254.169.254/latest/api/token' `
        -Method PUT `
        -Headers @{ 'X-aws-ec2-metadata-token-ttl-seconds' = '21600' } `
        -TimeoutSec 5
}

function Get-ImdsValue ([string]$path)
{
    $token = Get-ImdsToken
    return Invoke-RestMethod -Uri "http://169.254.169.254/latest/meta-data/$path" `
        -Method GET `
        -Headers @{ 'x-aws-ec2-metadata-token' = $token } `
        -TimeoutSec 5
}

$instanceId = Get-ImdsValue 'instance-id'
$region = Get-ImdsValue 'placement/region'
```

## External process exit codes

PowerShell does not throw on non-zero `$LASTEXITCODE`.

```powershell
docker build -t $imageName $contextDir
if ($LASTEXITCODE -ne 0) { throw "docker build failed (exit $LASTEXITCODE)" }
```

PS 7.3+:

```powershell
$PSNativeCommandUseErrorActionPreference = $true
```

Do not use this on earlier PS versions.

## Deployment preconditions

Only guard state that is genuinely unknown when the script runs - whether a binding is already configured, whether a service is running, whether a certificate is present.

Do not add `if`/`throw` guards for what the deployment pipeline guarantees: a package folder exists, a config file exists on a pipeline-built server, an installer exists inside an extracted package, web or machine config is pre-deployed. Those guards test deployment correctness at runtime and fail with a message that hides the real cause. Let the next line throw with the real path instead.

The same rule removes dead branches: when every entry in a config collection supplies a property, do not add an `else` branch for the absent case.

## Execution context

A command that crosses into another operating system is covered by [wsl.md](./wsl.md).

## Choosing the weight of the tool

PowerShell first. If the algorithm belongs in a typed library or PowerShell is measurably too slow, use a .NET package from NuGet, or C# for the hot path. `dotnet run measure.cs` runs a single file with no project and leaves no bin or obj in a source folder.
