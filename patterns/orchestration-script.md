## orchestration script:

There are 2 patterns of orchestration script but they both follow a similar path.

1. scripts that are used to execute tooling. 
2. scripts that are designed to compile software. these follow the gh.ps1 -> run.ps1 as we need the build process to work locally during development and then also when we run the build process under a github actions runner. 

Examples of these patterns can be found the examples folder.

tooling. Example scripts can be found under the examples\tooling folder.
build. Example scripts can be found under the examples\build folder.

## common - run.ps1

This function adds any general configuration required - eg build numbers where it is not appropriate to putting that into the configuration.json file. it is essential that we only pass a $configuration object to each function so we can do that by adding any required properties to the $configuration like this - 

function Add-RequiredValuesToConfiguration($configuration)
{
    $configuration | Add-Member # $script:buildNumber
    #other parameters here.
}

general function pattern - 
1. only pass $configuration. this mandatory.
2. have a write-host at the start of the function to indicate what the function will do/is for.
3. collect variables used by the function at the start of the function. 
4. don't use $configuration.someProperty at any point.
5. use powershell parameter splatting where possible. 
6. check for a non zero exit code and exit. 

example:

function Invoke-RestoreDependencies($configuration) {
    Write-Host "Restoring dependencies..."
    $solutionFile = $configuration.SolutionFile
    $suppressWarnings = $configuration.build.suppressWarnings

    $restoreArgs = @($solutionFile)
    
    if ($suppressWarnings -and $suppressWarnings.Count -gt 0) {
        $suppressList = $suppressWarnings -join ";"
        $restoreArgs += @("/p:NoWarn=$suppressList")
    }
    
    dotnet restore @restoreArgs
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ERROR: Dependency restore failed. Exit code $LASTEXITCODE."
        exit $LASTEXITCODE
    }
}

## build - run.ps1.

include a gh.ps1. this is override the nuget package source to LocalRepo so that push nuget packages to the LocalRepo instead of the github packages repo when running locally. this is so that we can test the entire pipeline before commiting/publishing packages to the github packages feed. 
run.ps1 should only have 1 script parameter -nugetPackageSourceName. It should have a default name of github in run.ps1.
run.ps1 should live in git repository root under the ci folder.  
run.ps1 should generate a BuildNumber-based version which is then passed to build.xml as a parameter. BuildNumber uses ticks: $([System.DateTime]::UtcNow.Ticks.ToString('D').Substring(0, 9)). NugetVersion=$(MajorVersion).$(MinorVersion).$(BuildNumber). Do not append -Debug or -Release suffixes to package names. Clean version numbers only.
when calling any command lines tools such as dotnet or nuget - use logging level minimum but make the logging level a script level variable so that if additional logging is required it is a 1 line change. 
By default the logging level should be minimal. 
After editing any C# source files run dotnet format <solution> before finishing. The CI pipeline runs dotnet format --verify-no-changes and will fail on whitespace errors.
only run integration tests if not running under github action. the RunIntegrationTests property in the configuration.json should default to false. we will set it to true if we are not running under GHA.

## tooling - run.ps1 .

all of the requirements that apply to the build version of run.ps1 apply to the tooling version of the run.ps1 except that we should create a tooling.ps1 that calls the 