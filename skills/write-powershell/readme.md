---
name: write-powershell-scripts
description: Write high-quality, readable PowerShell scripts following company conventions
---

# How to write good PowerShell scripts

## Banned patterns

### Path / file resolution

| Banned | Reason | Use instead |
|---|---|---|
| `$PSScriptRoot` outside `Set-Location` | Breaks when dot-sourced | `(Get-Item "...").FullName` in `Get-Configuration` |
| `Join-Path` inside functions | Ad-hoc path construction in the wrong layer | `"$base\$sub"` string interpolation |
| `Split-Path <var> -Parent` | Tree navigation at call time; fragile | Pre-resolve in `Get-Configuration` |
| `Split-Path <var> -Leaf` | Requires file to exist or is string-splitting | `Get-FileNameFromUrl` helper or `(Get-Item $f).Name` |
| `Split-Path (Split-Path ...)` nested | Unreadable; breaks on depth changes | `(Get-Item "..\..\..\").FullName` in `Get-Configuration` |
| Multi-level `..\..\..` inline in a function | Hardcodes tree depth inside logic | Define root in `Get-Configuration`, pass via `$configuration` |
| `[System.IO.Path]::GetFileName` | .NET class; discouraged | `Get-FileNameFromUrl` regex helper |
| `[System.IO.Path]::GetRelativePath` | .NET class | Pre-resolve absolute paths in `Get-Configuration` |
| `[System.IO.Path]::GetFullPath` | .NET class | `(Get-Item "..").FullName` |
| `($path -split '[\\]')[-1]` | String-splitting a path | `Get-FileNameFromUrl` or `(Get-Item $f).Name` |

### Error handling

| Banned | Reason |
|---|---|
| `try { } catch { return $false }` | Converts exceptions into silent success-looking returns |
| `try { } catch { return $null }` | Same - caller cannot distinguish success from failure |
| `-ErrorAction SilentlyContinue` on writes/mutations | Silently swallows failures that must surface |
| `Get-Command` guard before calling a required cmdlet | Hides missing-cmdlet errors; use `Invoke-PreflightCheck` instead |
| `exit 1` | Use `throw` - let `$ErrorActionPreference = 'Stop'` propagate the failure |
| `try/catch` blocks (except cleanup) | Masks failures; let errors surface naturally |
| `if (-not $?)` | Use `throw` - let `$ErrorActionPreference` propagate the failure |

`-ErrorAction SilentlyContinue` is valid only when the absence of a result is an expected, fully handled outcome (checking whether a file or an optional resource exists). Never use it on writes, API calls, tag operations, or any call whose success an external process or polling loop relies on.

### Control flow and structure

| Banned | Reason |
|---|---|
| `foreach ($x in $list)` | Use `$list |% { $x = $_ }` pipeline form |
| `if ($x -match "...")` for regex branching | Use `switch -Regex` instead |
| Magic strings inline in functions | Constants belong in `Get-Configuration` |
| Path arithmetic inside `Invoke-*` functions | All paths come from `$configuration` |
| Backtick line continuation | Use splatting or string concatenation |
| `return Invoke-SomeFunction $configuration` | Assign to a named variable, then return it |
| `Array index access `$array[0]`` | Use `Select-Object -First 1` - does not throw on empty |
| Script-level / global variables | Add runtime values onto `$configuration` via `Add-Member` |
| Generating scripts/executables at runtime then executing them | Place scripts in `assets` or `static` folders and execute them directly |
| `| Out-Null` to suppress output | Use `$null = command` - pipes are banned |
| `\`?` or `\%` at the start of a new line after a bare `\`` | Empty pipe element syntax error - `\`?` and `\%` must stay on the same line as the preceding pipe |
| `-notimatch` | Does not exist. Use `-notmatch` (case-insensitive by default on Windows) or `-inotmatch` (explicit) |
| `Set-Location (Split-Path $PSScriptRoot)` | Moves to the PARENT directory - `Get-Configuration` then looks for `configs\` in the wrong place. Always `Set-Location $PSScriptRoot` and adjust the `..\Init` depth. |
| `if/else` branches in the main execution block | Idempotency and gating belongs inside functions. The execution block must be a flat sequence of calls. |
| `if`/`elseif`/`elseif` ... chain testing unrelated conditions | Multiple unrelated conditions chained in one `if/elseif` is a code smell - each branch is really a different named state. Use a `Get-*` function that returns a single state value via early-exit guard clauses, then `switch` on it. |
| Nested functions | The inner copy shadows the outer function and cannot be called elsewhere. Keep functions flat; return early instead of nesting |

### Execution environment detection (exit-gate + switch)

Detecting which environment a script is running under (`gha` / `octopus` / `local`) is a common source of the banned `if/elseif` chain. Use an exit-gate `Get-` function - each check is an early `return`, not a condition chained onto the next - then `switch` on the result:

```powershell
# BANNED - unrelated conditions chained in one if/elseif
if (![string]::IsNullOrEmpty($env:GITHUB_ACTIONS))
{
    $hostEnvironment = 'gha'
}
elseif ($hostEnvironment -eq 'octopus' -and [string]::IsNullOrEmpty($env:OctopusEnvironmentName))
{
    Push-Location
    & ensure-aws-session-device-flow.ps1 -targetEnvironment $targetEnvironment
    Pop-Location
    $hostEnvironment = 'local'
}

# CORRECT - exit-gate Get- function, then switch
function Get-ExecutionEnvironment
{
    if (![string]::IsNullOrEmpty($env:GITHUB_ACTIONS)) { return 'gha' }
    if ($OctopusParameters -ne $null) { return 'octopus' }
    return 'local'
}

switch (Get-ExecutionEnvironment)
{
    'local'
    {
        & ensure-aws-session-device-flow.ps1 -targetEnvironment $targetEnvironment
    }
    default
    {
        # gha / octopus - credentials already available, nothing to do.
    }
}
```

Put this environment-detection logic in a shared `Init\main.ps1`, dot-sourced from each top-level script as `. ..\Init\main.ps1` (adjust `..\` depth to the script's location) - do not re-implement it per script. This matches the existing `Init\main.ps1` convention used by `Company.Stack.AWS.Windows\assets\remote\bootstrap\*\Invoke-Deployment.ps1`.

### .NET classes

Prefer PowerShell-native equivalents. Only use .NET classes when there is no clean native alternative.

| .NET class | Prefer instead |
|---|---|
| `[System.IO.Path]::*` (most methods) | String interpolation, `Get-Item`, regex helpers |
| `[System.IO.File]::*` | `Get-Content`, `Set-Content`, `Test-Path` |
| `[System.IO.Directory]::*` | `Get-ChildItem`, `New-Item -ItemType Directory`, `Test-Path` |
| `[System.Uri]::*` for filename extraction | Simple regex `'/([^/]+)$'` |

### Parameters

Runtime flags that select behaviour may be passed (eg `-resetadminpassword`). Configuration must not be passed between scripts. Accept only the parameters a script expects - a delete-stack script takes 0 or 1. Do not accept extra script-level parameters.

| Banned | Reason | Use instead |
|---|---|---|
| `param()` used to pass configuration from one script to another | Couples the callee to the caller, which must know the callee's config layout | `Get-Configuration` - each script independently loads its own configuration |
| `-ConfigurationFolder` (or any config path) as a parameter | Where the config lives is a concern of the script, not the caller | `Get-Configuration`, which resolves its own config path |
| `Add-Member` with a calculated `-NotePropertyValue` (eg `Get-SomeValue $someVariable`) | Calculated values are runtime values and do not belong in `Get-Configuration` | Pass only a plain value to `Add-Member`; put calculated values in `Add-RuntimeConfiguration` |

## General rules
- Don't do wildcard/partial matches on resources. Check that we get the expected count of matches - eg 0 or 1. Fail/exit the script immediately upon error. This prevents actions on unintended resources.
- Assume PowerShell 7+ only unless told otherwise. No compatibility shims for PowerShell 5.
- Only use ASCII characters in `.ps1` files. No em dashes, curly quotes, or non-ASCII characters.
- Only use approved PowerShell verbs for function names.
- Prefer PowerShell modules over command-line tools. If a suitable module does not exist, install it rather than shelling out.
- Do not use `Select-String`, `head`, `tail`, `grep`, or shell redirections (`2>&1`) in scripts.
- Do not write files to disk for debugging purposes. Use a PowerShell transcript (`Start-Transcript`/`Stop-Transcript`) when a record of what happened is needed; it captures errors too.
- Do not scan for invalid items, collect them into a list, and then report the problem items. Fail on the first one.
- Do not add a check for something essential to the function (eg that a log directory exists). `$ErrorActionPreference = 'Stop'` makes the next line fail with the real path.
- A hex literal above `[int32]::MaxValue` parses as a negative int32, so `0xC4403D78` is not the value written and comparisons against it silently match nothing. Write `0xC4403D78L`. Any hex literal with the top bit set needs the `L` suffix.
- A script with a `$hostEnvironment` parameter defaults it to `"gha"`, never `"local"`, and overrides it to `"local"` only when `GITHUB_ACTIONS` is empty.
- Do not add comments unless specifically asked.
- Do not create an orchestrator function that wraps all steps - call each step explicitly in the main execution block.
- If a script parameter has a default value, add a short inline comment explaining why.
- Repeated statement sequences in the main execution block should be extracted into a helper function.
- Do not add fallbacks, workarounds, or graceful error handling. It is ok if things fail.
- Keep code lightweight and free of logic unrelated to the task at hand.

## Script structure

Every script has this exact top-level structure, in order:

1. Script-level preferences (`$ErrorActionPreference`, `$VerbosePreference`)
2. `Set-Location $PSScriptRoot` - anchors working directory
3. `$baseName = Split-Path -Leaf "."` - captures current folder name if needed
4. Dot-source includes (if an includes folder exists)
5. All function definitions
6. Main execution block at the bottom - a flat sequence of function calls

```powershell
$ErrorActionPreference = 'Stop'
$VerbosePreference     = 'SilentlyContinue'
Set-Location $PSScriptRoot
$baseName = Split-Path -Leaf "."

Get-ChildItem -Path "includes" -Filter "*.ps1" -Recurse |% {
    Write-Verbose "Dot-sourcing $($_.FullName)"
    . $_.FullName
}

# --- functions above ---

$configuration = Get-Configuration
$configuration = Add-RuntimeConfiguration $configuration
Invoke-PreflightCheck $configuration
Invoke-StepOne $configuration
Invoke-StepTwo $configuration
```

Do not wrap the main execution block in a function or try/catch. Call each step explicitly so the execution path is transparent.

### Get-Configuration

Reads a JSON config file (or constructs static values) and returns a PSObject. This is the only place where path navigation with `..` and `.FullName` is allowed.

```powershell
function Get-Configuration
{
    $configFileName = [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.ScriptName)
    $roleRoot       = (Get-Item "..\..\..").FullName
    $configDir      = "$roleRoot\configs\$hostEnvironment\$targetEnvironment"
    $configPath     = "$configDir\$configFileName.json"
    $configuration  = Get-Content -Path $configPath -Raw | ConvertFrom-Json
    $configuration | Add-Member -NotePropertyName 'RoleRoot'   -NotePropertyValue $roleRoot   -Force
    $configuration | Add-Member -NotePropertyName 'ConfigPath' -NotePropertyValue $configPath -Force
    return $configuration
}
```

All major folder paths are added to `$configuration` here using string interpolation:

```powershell
$bootstrapRoot = "$roleRoot\assets\remote\bootstrap"
$packagesDir   = "$bootstrapRoot\packages"
$configuration | Add-Member -NotePropertyName 'BootstrapRoot' -NotePropertyValue $bootstrapRoot -Force
$configuration | Add-Member -NotePropertyName 'PackagesDir'   -NotePropertyValue $packagesDir   -Force
```

### Configuration sources

`$configuration` values come from `Get-Configuration` (static values, like constants) and `Add-RuntimeConfiguration` (values knowable only at runtime). Nothing else may add to it.

- Values known before start that the user may change per run (eg verbosity), and values unlikely to change (eg solution names), go in the json file loaded by `Get-Configuration`.
- Values unknown at script start (eg process ids, user profile folders) go in `Add-RuntimeConfiguration`.
- Pass `$configuration` untyped. Do not put script-level preference values (eg `$VerbosePreference`) into it.
- Json configuration holds relative paths. Do not resolve them with `Resolve-Path`, `Join-Path` or `$PSScriptRoot`.
- Prefer a `SkipSomeOperation` flag over an `EnableSomeOperation` flag: a missing `$configuration.SkipSomeOperation` resolves to false and the operation still runs, with no boilerplate in the json or `Get-Configuration`.
- The `config` folder consumed by code under `src` is checked in; `ci` configuration generally is not. They serve different purposes and keep separate configuration of the same shape.
- Do not verify a json config file in the terminal. A malformed file or a missing key fails inside the script that loads it, and that failure is the check.
- When a list of objects is needed, put them in json as a list of objects with an `enabled` property instead of separate property names.

```powershell
"scriptsToExecute": [{
    "enabled": true,
    "filePath": ".\\some-script.ps1"
}]

$scriptsToExecute = $configuration.ScriptsToExecute
$scriptsToExecute |? { $_.Enabled } |% {
    $script = $_
    & $script.FilePath
}
```

Do not build `$scripts = @($configuration.BuildTestStageScript, $configuration.ApplicationTestsStageScript)` - it is a needless round trip of objects and a fragile json structure.

### Add-RuntimeConfiguration

Adds values that can only be known at runtime (eg instance IDs, current state of a resource). Must be read-only - it must not create files, import modules, or change machine state.

```powershell
function Add-RuntimeConfiguration($configuration)
{
    $instanceId = Get-InstanceId $configuration
    $configuration | Add-Member -NotePropertyName 'InstanceId' -NotePropertyValue $instanceId -Force
    return $configuration
}
```

Split into single-concern sub-functions when the runtime configuration is large:

```powershell
function Add-RuntimeConfiguration($configuration)
{
    $configuration = Add-ImageRuntimeConfiguration $configuration
    $configuration = Add-RolePathsRuntimeConfiguration $configuration
    return $configuration
}
```

### Compliance check pattern

Split validation checks into single-purpose functions. Store check configuration (regex, file filters) on `$configuration` in an `Add-XxxRuntimeConfiguration` function and consume it as `$configuration.PropertyName`, never as function parameters.

- `Add-XxxRuntimeConfiguration ($configuration)` adds the regex/filter values to `$configuration`.
- `Invoke-TestForXxx ($configuration, $file)` is a single check, a single concern, and throws on failure.
- `Invoke-XxxComplianceCheck ($configuration)` enumerates the files and calls each `Invoke-TestForXxx`.

### Invoke-PreflightCheck

Validates conditions required for the script to succeed. All essential validation lives here and nowhere else. Do not write defensive checks inside other functions.

```powershell
function Invoke-PreflightCheck($configuration)
{
    if (-not (Test-Path $configuration.ConfigPath)) { throw "Config not found: $($configuration.ConfigPath)" }
    if (-not $configuration.TargetEnvironment)    { throw "TargetEnvironment is required." }
}
```

## Function rules

Every function:
- Takes exactly one parameter: `$configuration`. The only exception is helper functions that are not called from the main execution block. eg `Get-FileNameFromUrl($url)`
- Has exactly one purpose.
- Collects all values it needs from `$configuration` at the top
- Logs the key value(s) it is working with
- Does not resolve paths, navigate directories, or do path arithmetic
- Don't put control flow - eg if/then/else logic into Get-Configuration, Add-RuntimeConfiguration or Invoke-PreflightCheck.
- When a later step needs a value produced by an earlier step (eg a resource Arn), put the identifier (eg the resource name) on `$configuration` so the later step can look it up. An extra read call is fine.
- Collects its known values at the top, logs the useful ones, performs the work or calls another function and assigns the result to a variable, logs that result if useful for troubleshooting, then returns the variable.
- Look to `Test-Should` patterns for early exit instead of if/else branching in the main execution block. eg
```powershell
function Invoke-SomeStep($configuration)
{
    if (!(Test-ShouldDoStep $configuration))
    {
        return
    }
    # do the step
}
```

### `exit` vs `return` in functions

`exit` terminates the **entire PowerShell process** - not just the function. It is only valid inside top-level enable/guard functions (`Invoke-CheckEnabled`, `Test-IsEnabled`) where early process termination is the intended outcome.

Inside all other functions (`Invoke-*`, `Test-*`, `Add-*`, `Get-*`), use `return` to exit early. Do not use `exit` in an `Invoke-*` - this causes unexpected behavior where the script exits. We should be using exit-gates or `Test-Should` patterns to skip steps instead of exiting the script.

```powershell
# CORRECT - early exit in a guard function
function Invoke-CheckEnabled($configuration)
{
    $flag = $false
    if (![bool]::TryParse($env:EnableFlag, [ref]$flag) -or !$flag) { exit 0 }
}

# CORRECT - early return in an Invoke- function
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

function Invoke-UpdateBinding($configuration)
{
    if (-not (Test-ShouldUpdateBinding $configuration)) #should not log - we log in Test-ShouldUpdateBinding instead to keep the function small.
    {
        return
    }
    # perform update
}

# BANNED - exit inside a non-guard function kills subsequent steps
function Invoke-UpdateBinding($configuration)
{
    if (-not (Test-ShouldUpdateBinding $configuration)) { exit 0 }   # DO NOT DO THIS
}
```

```powershell
function Invoke-DownloadPackages($configuration)
{
    $packagesDir = $configuration.PackagesDir
    $packages    = $configuration.Packages
    Write-Log "Downloading $($packages.Count) package(s) to $packagesDir"
    $packages |% {
        $package = $_
        Invoke-DownloadFile $package.url $packagesDir
    }
}
```

## Grouping repeated near-identical statements

If you write the same shape of statement more than twice with only a name/value changing (validation checks, tag lookups, replacement rules), collapse it into a loop over an array of names or `[pscustomobject]` rules. Do not hand-write one `if`/`throw` per value.

```powershell
# BANNED - same shape repeated with only the name changing
function Invoke-PreflightCheck($configuration)
{
    if ([string]::IsNullOrEmpty($configuration.ResourceBucket)) { throw "ResourceBucket is required." }
    if ([string]::IsNullOrEmpty($configuration.ReleaseVersion)) { throw "ReleaseVersion is required." }
    if ([string]::IsNullOrEmpty($configuration.StackName))      { throw "StackName is required." }
}

# CORRECT - loop over the list of names
function Invoke-PreflightCheck($configuration)
{
    $valuesToCheck = @('ResourceBucket', 'ReleaseVersion', 'StackName')
    $valuesToCheck |% {
        $valueName = $_
        $value = $configuration.$valueName
        if ([string]::IsNullOrEmpty($value))
        {
            throw "$valueName is required."
        }
    }
}
```

The same applies to find/replace rule sets - build an array of `[pscustomobject]` `@{ ReplaceFrom = ...; ReplaceTo = ... }` and iterate it, rather than writing a separate `-replace` statement per rule. See `Invoke-PatchStartupScript` style functions for the full pattern (re-read content on each iteration, check idempotency with an `alreadyPatched`/`needsPatching` guard before replacing).

## Per-item detail objects in loops

When a loop body needs several derived values per item (paths, file names, per-item config), do not inline the derivation calls redundantly inside each step, and do not scatter ad-hoc variables across multiple functions that implicitly share scope. Instead, build a single `Get-XDetails($configuration, $item)` function that returns one `[pscustomobject]` with every derived value the loop needs, computed from its own local variables, then thread that object through a sequence of single-purpose `Invoke-*` functions - the same pattern as `Get-Configuration`/`Add-RuntimeConfiguration`, applied to one loop item instead of the whole script.

```powershell
function Get-PackageDetails($configuration, $package)
{
    $packageFileName   = $package.Package
    $packagesDir       = $configuration.PackagesDir
    $packageFolderName = Get-PackageFolderName $packageFileName
    $packageFolder     = "$packagesDir/$packageFolderName"
    return [pscustomobject]@{
        PackageFileName   = $packageFileName
        PackageZipPath    = "$packagesDir/$packageFileName"
        PackageFolder     = $packageFolder
        PackageObjectPath = "$($configuration.CloudStorageObjectPrefix)/$packageFileName"
    }
}

function Invoke-InstallPackages($configuration)
{
    $manifest = $configuration.Manifest
    $manifest |% {
        $package = $_
        $packageDetails = Get-PackageDetails $configuration $package
        Invoke-DownloadPackage $packageDetails
        Invoke-ExpandPackage $packageDetails
        Invoke-InstallPackage $packageDetails
    }
}
```

Rules for `Get-XDetails` functions:
- Always take `$configuration` explicitly as a parameter, even though it is a helper called from inside a loop and not from the main execution block. Never read `$configuration` (or any other value) as an ambient/outer-scope variable - PowerShell will silently resolve it from the enclosing scope if you forget the parameter, which is fragile and breaks if the function is ever called from a different scope.
- Every value referenced inside the returned `[pscustomobject]@{ ... }` literal must be assigned to a local variable first. Referencing a variable name inside the hashtable literal that was never locally assigned (eg reusing a property name like `$packageFolderName` as if it were a variable) silently evaluates to an empty string instead of failing - this is a common source of "path is just `/`" style bugs.
- Double-check property names against every place that reads them (`$packageDetails.PackageZipPath` etc.) - a typo in the property name (eg `$PpackageZipPath`) is not caught by the parser and silently returns `$null` at every call site.

## Path rules

`$PSScriptRoot` is only used in `Set-Location $PSScriptRoot` at the top of the script. Never reference it again.

---

## Output suppression

Never use `| Out-Null` to suppress output. Use `$null = ...` assignment instead.

```powershell
# banned
New-Item -ItemType Directory -Path $dir | Out-Null
docker rm -f $name | Out-Null

# correct
$null = New-Item -ItemType Directory -Path $dir
$null = docker rm -f $name
```

## Variable evaluation.

When we need to need to evaluate a variable value as a bool and we don't know the content of the variable ahead of time use this pattern. It is allowed to use a .net class here since it's intent is clear.

```powershell
function Invoke-CheckEnabled
{
    $result = $false
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

All path construction inside functions uses string interpolation. No `Join-Path`, no `Split-Path`, no `.FullName` outside of `Get-Configuration`.

```powershell
# CORRECT inside a function
$outputDir = "$($configuration.BootstrapRoot)\$($packageList.OutputDir)"
$destFile  = "$outputDir\$moduleName.nupkg"

# BANNED inside a function
$outputDir = Join-Path $configuration.BootstrapRoot $packageList.OutputDir
$destFile  = Split-Path $configuration.ConfigPath -Parent
```

Build paths stepwise - each segment on its own variable:

```powershell
$bootstrapRoot = "$roleRoot\assets\remote\bootstrap"
$packagesDir   = "$bootstrapRoot\packages"
$moduleDir     = "$packagesDir\$moduleName\$version"
```

To extract a filename from a URL, use a helper - not `[System.IO.Path]::GetFileName`:

```powershell
function Get-FileNameFromUrl($url)
{
    if ($url -match '/([^/]+)$') { return $Matches[1] }
    throw "Cannot derive filename from url '$url'."
}
```

Deriving a filename from a URL is a separate concern from downloading, so keep it out of `Invoke-DownloadFile` and call the helper from it. If the caller already has a specific destination filename (eg a module name plus version from config), pass the full destination path explicitly instead.

Get the current folder name with `Split-Path -Leaf "."` at the top of the script. Do not use `(Get-Item ".").Name` or `$PSScriptRoot` for this.

Collect the major folder roots for each section of a script (zip creation, S3 upload, secrets, compliance) in `Get-Configuration`, each as its own named property, so functions only use those roots and no path is resolved inside a function body. Explode nested path expressions into stepwise variables.

When reviewing a script, search function bodies for `Join-Path`, `Split-Path`, `.FullName` and multi-level `..\..\` references. None belong outside `Get-Configuration` or `Add-RuntimeConfiguration`; work out which files and folders the function uses and whether they are relative to a root that should be defined there.

## Error handling

`$ErrorActionPreference = 'Stop'` is set at the top. Let it do the work.

Do not wrap code in try/catch.
Do not use `exit 1`.
Do not use `return $false` or `return $null` from a catch block. These patterns convert real failures into silent or misleading returns.

### External process exit codes

PowerShell does not throw on a non-zero `$LASTEXITCODE`. Check it after each external command.

```powershell
docker build -t $imageName $contextDir
if ($LASTEXITCODE -ne 0) { throw "docker build failed (exit $LASTEXITCODE)" }
```

On PowerShell 7.3 and later, `$PSNativeCommandUseErrorActionPreference = $true` makes native commands honour `$ErrorActionPreference`.

### Deployment preconditions

Only guard state that is genuinely unknown when the script runs: whether a binding is already configured, whether a service is running, whether a certificate is present.

Do not add `if`/`throw` guards for what the deployment pipeline guarantees: a package folder exists, a config file exists on a pipeline-built server, an installer exists inside an extracted package, web or machine config is pre-deployed. Those guards test deployment correctness at runtime and fail with a message that hides the real cause. Let the next line throw with the real path.

The same rule removes dead branches: when every entry in a config collection supplies a property, do not add an `else` branch for the absent case.

```powershell
# CORRECT
function Invoke-TestOpenWebUI($configuration)
{
    $openwebuiUrl = $configuration.OpenWebUIUrl
    Write-Log "Testing Open Web UI is accessible at $openwebuiUrl"
    $response = Invoke-WebRequest -Uri $openwebuiUrl -Method GET -TimeoutSec 5
    Write-Log "Open Web UI response: $($response.StatusCode) $($response.StatusDescription)"
}

# BANNED
function Invoke-TestOpenWebUI($configuration)
{
    try {
        $response = Invoke-WebRequest -Uri $openwebuiUrl -Method GET -TimeoutSec 5
        if (!($response.StatusCode -eq 200) { Write-Host "OK" }
        else { Write-Error "Bad status"; exit 1 }
    } catch {
        Write-Error "Failed: $_"; exit 1
    }
}
```

## Iteration and conditionals

Use `|% {` for iteration over collections. Do not use `foreach ($x in $list)` or `ForEach-Object`. A loop that must stop early or index positionally is the exception.

```powershell
$packages |% {
    $package = $_
    Write-Log "Processing $($package.Name)"
    Invoke-InstallPackage $package $configuration
}
```

Use `|? {` for filtering:

```powershell
$files |? { $_.Extension -eq '.pfx' } |% {
    $file = $_
    Invoke-ImportCertificate $file $configuration
}
```

Use `switch -Regex` instead of `if ($x -match ...)`:

```powershell
$line = $_
switch -Regex ($line)
{
    'Reserved URLs:\s+(.+)'  { $reservedUrls = $Matches[1] }
    'Listening:\s+(.+)'     { $listeningOn  = $Matches[1] }
    default                 { }
}
```

## Test-Should pattern

Functions that write, update, or change machine state must have an early-exit guard. Test whether the operation is needed first. If not needed, log a message and return.

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

function Invoke-UpdateBinding($configuration)
{
    if (-not (Test-ShouldUpdateBinding $configuration)) { return }
    # perform the update
}
```

Use this pattern instead of `-ErrorAction SilentlyContinue` on mutation calls.

Test the real desired state, not a proxy for it. Whether SQL needs its certificate updated is whether the thumbprint in the registry matches the thumbprint in the store, not whether the certificate is near expiry: a certificate may be renewed in the store and not yet deployed.

```powershell
# WRONG - checks whether the cert needs renewal, not whether SQL has it
$needsDeploy = $cert.NotAfter -lt (Get-Date).AddDays($configuration.RenewalThresholdDays)

# CORRECT
$registryThumbprint = (Get-ItemProperty $registryPath).Certificate
$needsDeploy = $registryThumbprint -ne $configuration.NewThumbprint
```

When iterating a list of folders that may not all exist on every host, test the folder before `Get-ChildItem`: with `$ErrorActionPreference = 'Stop'` it throws on a missing path.

```powershell
if (!(Test-Path $folderPath))
{
    Write-Log "Folder '$folderPath' not found, skipping."
    return
}
$scripts = Get-ChildItem -Path $folderPath -Filter '*.ps1'
```

## Wait/retry pattern

Test the condition before entering the loop so the loop body is never processed unnecessarily:

```powershell
function Wait-UntilDeploymentComplete($configuration)
{
    $timeoutSeconds = $configuration.DeploymentTimeoutSeconds
    $retryInterval  = $configuration.RetryIntervalSeconds
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

Use `Write-Log` (not `Write-Host`) for all output. Keep logging minimal by default. Log the key values at the start of a function so failures are diagnosable without adding extra instrumentation.

```powershell
function Invoke-UploadPackage($configuration)
{
    $packagePath = $configuration.PackagePath
    $s3Bucket    = $configuration.S3Bucket
    Write-Log "Uploading $packagePath to s3://$s3Bucket"
    Write-S3Object -BucketName $s3Bucket -File $packagePath
    Write-Log "Upload complete."
}
```

Do not write debug output to disk files. Increase verbosity via `$VerbosePreference` when needed, or use a transcript.

Keep log lines short: log paths relative to the folder being processed, not full absolute paths.

## Constants and magic strings

Any value used more than once, or which reads like a constant (ports, certificate store paths, URL fragments, environment names), belongs in `Get-Configuration` - not inline in a function.

```powershell
# CORRECT - in Get-Configuration
$configuration | Add-Member -NotePropertyName 'CertStore'   -NotePropertyValue 'Cert:\LocalMachine\My' -Force
$configuration | Add-Member -NotePropertyName 'BindingPort' -NotePropertyValue '0.0.0.0:443'               -Force

# BANNED - magic string inside function
function Invoke-ImportCert($configuration)
{
    Import-PfxCertificate -CertStoreLocation 'Cert:\LocalMachine\My' ...
}
```

## CI and deployment script lessons

- Establish the iteration pipeline before writing complex scripts: a local run that completes in seconds, then the CI run, then the instance's own output (SSM or CloudWatch). Debug on an instance through SSM Session Manager, not WinRM. WinRM was removed from bootstrap because certificate, listener and endpoint setup add their own failure modes; scripts or configs referencing `CreateWinRMMListener`, `WinRMHttpsPort`, `WinRMCertificateThumbprint`, `winrm-*.ps1` or `Register-PS7WinRMEndpoint.ps1` are legacy and are removed.
- Merge deployment steps that depend on each other's computed state (import certificate, deploy to SQL, update the SSRS binding) into one script with a flat execution block, each step reading values the previous step put on `$configuration`. Separate scripts force every script to re-check state the previous one already computed.
- Keep separate concerns in separate scripts and separate config files: S3 upload (runs on every push, no stack changes) and stack deployment (runs only when enabled). Do not mix upload steps into the deployment script or stack parameters into the upload config.
- When config overlay directories are split by `$hostEnvironment` (`local` and `gha`), both directories must hold complete contents. A file added under one is added under the other, otherwise the zip is built without it and the failure appears later as a missing configuration file on the instance.
- GHA boolean inputs arrive as the strings `"true"`/`"false"`, and as an empty string on a `push` trigger. `[bool]::Parse("")` throws; use `[bool]::TryParse`.
- Every `workflow_dispatch` input must be passed to the script explicitly, and where a value varies per run it is a `choice` input rather than a hard-coded default.
- Do not add `|| vars.FallbackValue` to GHA env expressions. A missing variable should fail the script.
- Setting `working-directory` changes what relative `run:` paths resolve against. Use an absolute path in `run:` or leave `working-directory` alone.
- Use `127.0.0.1`, not `localhost`, for TCP clients in CI tests on Windows: `localhost` resolves to `::1` and a server bound only to IPv4 refuses the connection.
- Retry for a service that is still starting in the test, not in the container start-up script. Test first, then loop with a bounded count and delay, and throw after the budget is spent.

## IMDSv2 pattern (AWS instance metadata)

Always use the token-based IMDSv2 protocol. IMDSv1 (no token) is disabled on hardened instances.

```powershell
function Get-ImdsToken ()
{
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
        -Headers @{ 'X-aws-ec2-metadata-token' = $token } `
        -TimeoutSec 5
}
```

Usage: `$instanceId = Get-ImdsValue 'instance-id'`, `$region = Get-ImdsValue 'placement/region'`.

---

## External process exit codes

`$ErrorActionPreference = 'Stop'` does **not** throw on a non-zero `$LASTEXITCODE` from external executables (docker, kubectl, git, etc.). Check explicitly after every external call that must succeed:

```powershell
docker build -t $imageName $contextDir
if ($LASTEXITCODE -ne 0) { throw "docker build failed (exit $LASTEXITCODE)" }
```

Alternatively, enable native command error propagation (PS 7.3+):

```powershell
$PSNativeCommandUseErrorActionPreference = 'Stop'
```

Do not use `$PSNativeCommandUseErrorActionPreference` if the script runs on earlier PS versions.

---

## Do not guard against deployment preconditions

`if` checks are only valid when the state of the environment is genuinely unknown at runtime - e.g. whether an IIS setting is already configured, whether a service is running, whether a certificate is already present.

**Do not** add `if` / `throw` guards for things that are guaranteed by the deployment pipeline:
- Packages folder exists -> always pre-deployed before the script runs
- A specific `.nupkg` is present -> always pre-deployed
- `machine.config` / `web.config` exist -> always present on a .NET-installed Windows Server
- An installer executable exists inside an extracted package -> always true if the package version is correct

These guards look like safety checks but they are actually false positives waiting to happen - they test deployment correctness at runtime and fail with cryptic messages instead of preventing the root cause (a bad deployment). The correct fix for a missing package is to fix the deployment, not to add a runtime guard.

**Banned pattern:**
```powershell
$nupkg = Get-ChildItem -Path $configuration.PackagesFolder -Filter "$packageFileName.*.nupkg" | Select-Object -First 1
if (-not $nupkg) { throw "Package '$packageFileName' not found." }   # banned - deployment guarantee
```

**Correct pattern:**
```powershell
$nupkg = Get-ChildItem -Path $configuration.PackagesFolder -Filter "$packageFileName.*.nupkg" | Select-Object -First 1
# no guard - if it's missing, the next line throws with the real file path
[System.IO.Compression.ZipFile]::ExtractToDirectory($nupkg.FullName, $extractDir)
```

**Legitimate `if` checks (unknown runtime state):**
```powershell
# OK - we don't know whether Default Web Site has been removed yet
if ($site) { $site.Delete(); $iis.CommitChanges() }

# OK - we don't know whether the mime type is already registered
if ($configuration.ExistingStaticTypes -notcontains $mimeType) { ... }

# OK - we don't know whether IIS is currently running
if ($svc -and $svc.Status -eq 'Running') { Stop-Service w3svc }
```

---

## Dead code branches caused by always-set config properties

When every entry in a config collection always provides a property (e.g. `Executable` on every `PackagesToInstall` entry), do not add an `else` branch that handles the absent case. The branch is dead code and adds noise.

**Banned:**
```powershell
if ($package.Executable)
{
    $executablePath = "$extractDir\$($package.Executable)"
}
else
{
    # this branch never runs - all packages always have Executable set
    $found = Get-ChildItem -Path $extractDir -Include @('*.exe', '*.msi') -Recurse | Select-Object -First 1
    $executablePath = $found.FullName
}
```

**Correct:**
```powershell
$executablePath = "$extractDir\$($package.Executable)"
```

---
