## powershell/CI pipeline architecture.

repository layout:

/ (repository root)
/ci
    /ci/gh.ps1 - only run in local development environment. do not reference in github action.
    /ci/build-test.ps1 - called from github action with only -ConfigurationFolder configs
    /ci/configs - contains 1 json file with the same name as the visual studio solution it relates to. only contains configuration that is specific to that solution - eg solution name. 
/src - the top level folder for either the solution or solutions. 

## Github action guidelines.

A github action should have only two steps -
    dotnet source add. 
    built-test.ps1 -configurationFolder $configs.
Create NuGet source in GitHub Actions workflow, not in gh.ps1, to allow -NugetSourceName parameter override. 


