# CI/CD Pipeline Requirements

## Script Initialization

Set param block at top, then `$ErrorActionPreference = 'Stop'`.
Load build-configuration.json with `-Raw` flag then pipe to `ConvertFrom-Json`.
No try/catch blocks except nuget.ps1 (for cleanup via finally).
```powershell
param([string]$ConfigurationFile)
$ErrorActionPreference = 'Stop'
$config = Get-Content $ConfigurationFile -Raw | ConvertFrom-Json
```

## Function Pattern

All build functions use consistent signature with single Configuration parameter:
```powershell
//Extract config values from $Configuration object.
function Invoke-BuildPhase {
    param([object]$Configuration)
    
    Write-Host "Phase starting..."
    $suppressWarnings = $Configuration.build.suppressWarnings
    dotnet command $solutionFile
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ERROR: Phase failed."
        exit $LASTEXITCODE
    }
}
```

Parameter handling:
- Use `param([object]$Configuration)` signature only. Access solution file from script scope.
- Extract configuration values to local variables at function start.
- Use splatting for command arguments: `dotnet build @buildArgs`.
- Check `$LASTEXITCODE` after every external command.
- Exit with `$LASTEXITCODE` on failure (preserves exit code).
- Use `Write-Error` for error messages.

## Main Execution

Call functions sequentially in order with no try/catch block.
```powershell
Invoke-ValidateProjectReferences -Configuration $config
Invoke-RestoreDependencies -Configuration $config
Invoke-CodeFormatCheck -Configuration $config
Invoke-BuildSolution -Configuration $config
Invoke-RunTests -Configuration $config
exit 0
```

Exit 0 on success. Exit 1 on any failure (no partial success).

## Shell Utilities

Do not use head, tail, grep, or stdout redirection in CI scripts.
Run orchestration scripts directly: `.\gh.ps1` without piping output.

## Build Phases

Invoke-ValidateProjectReferences: Verify all .csproj files listed in .sln.
Invoke-RestoreDependencies: `dotnet restore`. Apply suppressWarnings from config.
Invoke-CodeFormatCheck: `dotnet format --verify-no-changes`.
Invoke-BuildSolution: `dotnet build`. Apply config verbosity and suppressWarnings.
Invoke-RunTests: `dotnet test`. Apply config verbosity.

## nuget.ps1

Windows only. Do not run on GitHub Actions.

Verify build.xml exists in src directory.

Verify nuget source using `nuget source list`. Check for LocalRepo source.
If missing or points to wrong path, create or update with `nuget source add/update`.
```powershell
//Check nuget source and update if needed.
$nugetRepositoryName = "LocalRepo"
$nugetRepoPath = "c:\dev\nuget-local-repo"
& nuget source list
& nuget source add -Name $nugetRepositoryName -Source $nugetRepoPath
```

Build NuGet packages:
```powershell
//build.xml MSBuild target creates packages.
//Define ProjectsForNugetPackaging item group in build.xml.
//<ProjectsForNugetPackaging Include="Project.csproj" />
//<Exec Command="dotnet pack %(ProjectsForNugetPackaging.Identity) --output $(NugetOutputPath) /p:PackageVersion=$(NugetVersion)" />
//Version format: 1.0.yyMMddHHmmss (timestamp).
& dotnet build build.xml -t:CreateNugetPackages -p:Configuration=$($config.build.configuration)
```

Check `$LASTEXITCODE` after build. Throw on failure.
Collect created .nupkg files from nupkgOut folder.
Push packages to LocalRepo: `dotnet nuget push $pkgPath --source $nugetRepositoryName`.
Use try/catch at top level with finally block for cleanup and location restoration.
Exit 0 on success, exit 1 on failure.

## gh.ps1 Script

Simulate GitHub Actions locally.
Load configuration from ../src/build-configuration.json.
Navigate to src directory with `Push-Location`.
Execute build phases and nuget operations.
`Pop-Location` on completion.

## Test Results & Coverage

Test results: JSON format with metadata (not CSV).
Coverage: JSON format.
Datestamp test results files with execution metadata.
