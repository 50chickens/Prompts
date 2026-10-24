## ci scripts

There are 2 patterns of ci script, and they follow a similar path. They always include the same scripts, but each file can be a noop if it is not required for that scenario.

1. Scripts used to execute tooling: the ci.ps1 -> invoke-*.ps1 pattern.
2. Scripts that compile software: the ci.ps1 -> build-test.ps1 -> invoke-*.ps1 pattern, because the build process must work locally during development and again under a github actions runner.

High level:

1. The main entry hook is always ci.ps1.
2. ci.ps1 calls build-test.ps1, which can be a noop. build-test.ps1 is used exclusively for compiling software.
3. ci.ps1 calls invoke-*.ps1 - see the pattern below.

## invoke-*.ps1

invoke-* is a sequence of scripts with these scopes. Each of these files is under SOLUTION_FOLDER\scripts, eg SOLUTION_FOLDER1\scripts. They run in this order:

invoke-application-tests.ps1 runs tests of the output from build-test.ps1 or ci.ps1, for tests that are neither unit nor integration tests - eg running a console app to verify connectivity, such as fm3 connectivity tests or chatgpt hello-world tests.
invoke-docker.ps1 creates a docker container from the current SOLUTION_FOLDER. Files needed in the image at build time (eg compiled binaries) or at container run time (eg configuration files) are copied into the docker folder by this script; see docker.md. Only files required to create the image or to run it go there. It does not push to an external registry.
invoke-deployment.ps1 takes the artifacts from the previous steps and deploys them somewhere external - dockerhub, aws, an install on the local machine. Artifacts are ready to deploy at this point and need no further change.
invoke-deployment-test.ps1 only tests that the deployed application works as designed. It does not deploy or change anything.

Examples of the build pattern are in the examples folder. The tooling pattern is the same except build-test.ps1 is a noop script.

## Pipeline logging

Add timestamps to the log so the duration of each step is visible. Use Write-Log instead of write-host.

## Include files

Include files are .ps1 files dot-sourced to keep ci.ps1, build-test.ps1 and invoke-*.ps1 small, or to share code. If an includes folder exists under the working directory, dot-source every file in it.

Includes are split into sections with no overlap: swapping raspberry pi arm64 for redhat x64 removes the raspberry pi section and replaces it. A function in an include represents the platform it belongs to, so do not reuse a name from the section being replaced.

## Configuration files

The configs folder holds one .json file per folder under src, providing run-time configuration to the script. One json file contains all the configuration that script needs, except mutable values - build numbers, timestamps and other values that are random or indeterminate ahead of time.

Values that are consistent across scripts - log verbosity, error action - are script-level values added to the $configuration object. A value specific to one script, such as $script:osListUrl = "https://downloads.raspberrypi.com/os_list_imagingutility_v4.json", stays a script-level variable.

Where values are related - public and private key filenames - do not create one configuration value per file. Configure the shared value and derive from it in the function that uses it.

```powershell
"keyPairFileName": "ssh-keys"
```

```powershell
function Invoke-CreateSshKeyPair($configuration)
{
    $keyPairFileName = $configuration.keyPairFileName
    $privateKeyFileName = "$keyPairFileName.key"
    $publicKeyFileName = "$keyPairFileName.pub"
}
```

Collect a value in the function that uses it rather than in a global configuration step.

```powershell
function Add-AdditionalConfiguration()
{
    $configuration | Add-Member -NotePropertyName 'imgPath' -NotePropertyValue ("$baseDir\$($configuration.vmName).img")
    $configuration | Add-Member -NotePropertyName 'firstRunPath' -NotePropertyValue (Join-Path $script:tempDir "$($configuration.vmName)-firstrun.sh")
}
```

```powershell
$baseDir = (Join-Path $script:tempDir)
$vmName = $configuration.vmName
$imgPath = "$baseDir\$vmName.img"
$firstRunPath = "$baseDir\$vmName-firstrun.sh"
```

## Common invoke-*.ps1 rules

1. Only pass $configuration. This is mandatory.
2. Write a Write-Log line at the start of the function stating what it does.
3. Collect the variables the function uses at the start of the function; do not reach into $configuration.someProperty after that.

```powershell
function Invoke-GenerateSshKeypair($configuration)
{
    $sshKeyPath = $configuration.sshKeyPath
    #Do something with $sshKeyPath
}
```

In linux do not use the /tmp folder for any reason. Temporary files, and generated content such as ssh keys, go into the temporary_assets folder.
Use powershell parameter splatting where possible.
Check for a non zero exit code and exit.
Do not use invoke-*.ps1 scripts to write executable code or scripts to disk - eg firstrun.sh. The purpose of ci.ps1 and invoke-*.ps1 is orchestrating tasks, not writing dependencies at runtime.

Each function does one thing. Common violations:

- A function that fetches remote data AND transforms it AND updates $configuration - split into a Get- function (fetch/transform) and an Invoke- function (update $configuration).
- A function that resolves a URL AND derives cache file paths from it - split. URL resolution is one concern, path derivation another.

Helper functions (Get-, Search-, Test-) may take whatever parameters make sense.
When a function needs data produced by a previous step (eg an SSH key generated by Invoke-GenerateSshKeypair), create a dedicated Get- function to read it rather than reading the file inline.
Use -replace with [regex]::Escape() for literal placeholder substitution, not .NET .Replace().
Where a recursive search meets items whose children come in two forms (inline vs remote), put child retrieval in its own function rather than inside the search loop.

## Build: ci.ps1 -> build-test.ps1 -> invoke-*.ps1

ci.ps1 overrides the nuget package source to LocalRepo so packages push to LocalRepo instead of the github packages feed when running locally, which tests the whole pipeline before publishing.
invoke-*.ps1 lives in the git repository root under the ci folder.
invoke-*.ps1 generates a BuildNumber-based version and passes it to build.xml. BuildNumber uses ticks: $([System.DateTime]::UtcNow.Ticks.ToString('D').Substring(0, 9)). NugetVersion=$(MajorVersion).$(MinorVersion).$(BuildNumber).
When calling command line tools such as dotnet or nuget, use the minimum logging level, held in a script-level variable so raising it is a one line change.
After editing any C# source file run dotnet format <solution>. The CI pipeline runs dotnet format --verify-no-changes and fails on whitespace errors.
Run integration tests only when not running under github actions. The RunIntegrationTests property in configuration.json defaults to false and is set true when not running under GHA.

## Tooling: ci.ps1 -> invoke-*.ps1

Every requirement of the build version applies to the tooling version, except that ci.ps1 calls invoke-*.ps1 directly.

## Workflow file

A workflow file carries no inline code: no shell snippets, no expressions that compute a value, no parameters. It names a repository script, in the form `run: ./ci/ci.ps1`, and every decision lives in that script.

## Build script

A build script takes no parameters. Every input is derived at run time from a configuration file the script reads itself. Build and release scripts contain no git actions and no lock or mutex taking: a repository drives those decisions, and a lock in a build script leaves a stale file when the run crashes.

## Release layout

`release` holds no files of its own. Artefacts go in `release\<version>\`, one sub folder per kind: `bin`, `snapshots`, `stage`, `metadata`, `logs`. The version comes from one place, the `version` in `ci\config\config.json`.
