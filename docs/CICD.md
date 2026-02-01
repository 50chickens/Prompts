# GitHub Actions CI/CD Pipeline Requirements

## build-and-test.yml Workflow

Trigger on push only.
Run on ubuntu-latest.
Setup .NET 9.0.x.
Run build-test.ps1 from src directory. 
Upload TestResults artifacts on always. 
Upload code-coverage artifacts on always.
No matrix jobs. Single job: BuildAndTest.
Set shell to pwsh for all steps.
Use actions/checkout@v4.
Use actions/setup-dotnet@v4.
Use actions/upload-artifact@v4.
Set 1 week expiry on artifacts if possible. 


## gh.ps1 Script

The intent is to simulate the build process in github locally. 
The order is: checkout, build-test.ps1, nuget. 

## build-test.ps1

Load build-configuration.json at start.
Set-Location to script directory.
Each build phase is a function with parameter [PSCustomObject]$configuration.
Extract configuration values to local variables at function start.
Use $LASTEXITCODE to check command success. Exit with code 1 on failure.
Do not use try/catch blocks.
Don't use colour or decorations in script.
don't hardcode magic strings, or variables into strings in functions eg dotnet build "solution1.sln". 
use $configuration for variables that are specific to the application that is being built - eg solution1.sln for solution name. 
for build-test.ps1 variables we might want to change from build to build (eg changing log verbosity) should have a script parameter - eg -LogLevel normal. these values should override the values of the $configuration object.
for magic strings/constants etc append the $configuration object with them using a function like:

Add-BuildConfigurationConstants($configuration)
{
    $additionalBuildParameters = @()
    $additionalBuildParameters += [PSCustomObject]@{
                $ApiMaxWaitTime = 60
    }
    $additionalBuildParameters |%{
        //add the pipeline objects property and value to the $configuration object here. 
    }
    return $configuration.
}
$configuration = Add-BuildConfigurationConstants

Configuration variable pattern:
```powershell
$enabled = $configuration.section.enabled
$value = $configuration.section.property
$solutionFile = $configuration.solutionFile
```

All functions follow this pattern - 
```powershell

function Invoke-BuildPhase($configuration) {
    $enabled = $configuration.phase.enabled
    if (-not $enabled) { return }
    write-host "---- Invoke-function1 started ----" 
    dotnet command
    if ($LASTEXITCODE -ne 0) { exit 1 }
    write-host "---- Invoke-function1 completed ----"
}

```

don't wrap main orchestration in try/catch. eg 

Invoke-Function1(){

}
Invoke-Function2(){
    
}
Invoke-Function1
Invoke-Function2

Main execution calls functions sequentially. Check solution file exists before starting.
Exit 0 on success, exit 1 on any failure.

## nuget.ps1


## build-configuration.json

Root level: solutionFile property.
Verbosity values: minimal, normal. default is minimal.
Don't ever specify build configuration - eg Debug/Release.
don't use failOnError type conditional.


Phases: lint, validate, restore, build, test including generating coverage.
Test section: include collectCoverage flag as default (dont include in build-configuration.json).

## Build Phases (Execution Order)
These should all cause github actions to fail/stop processing if any errors. 
Invoke-CodeLint: dotnet format --verify-no-changes. Fails build if formatting issues.
Invoke-ValidateProjectReferences: dotnet sln list. Validates project structure.
Invoke-RestoreDependencies: dotnet restore. Fail if restore fails.
Invoke-BuildSolution: dotnet build. 
Invoke-RunTests: dotnet test with trx logger. Collect coverage for c# projects.

## Artifact Collection

TestResults: **/**/TestResults/**/*
Coverage: **/**/coverage.json
Output format: trx for test results, json for coverage.

## Exit Codes

0: All steps succeeded.
1: Any step failed. Script stops immediately.
No partial success. All-or-nothing execution.
