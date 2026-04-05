## Github action guidelines.

A github action should have only two steps -
    dotnet source add. 
    built-test.ps1 -configurationFolder $configs.
    Create NuGet source in GitHub Actions workflow, not in ci.ps1, to allow -NugetSourceName parameter override. 