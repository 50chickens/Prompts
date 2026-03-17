## orchestration script:

There are 2 patterns of orchestration script but they both follow a similar path.

1. scripts that are used to execute tooling. 
2. scripts that are designed to compile software. these follow the gh.ps1 -> run.ps1 as we need the build process to work locally during development and then also when we run the build process under a github actions runner. 

Examples of these patterns can be found the examples folder.

tooling. Example scripts can be found under the examples\tooling folder.
build. Example scripts can be found under the examples\build folder.

## configuration files. 

in the configs folder there is a list of .json files and each of the .json files matches a folder under the src folder. 
the intent here is that each of these .json files provides configuration at run time to the script using a repeatable pattern. 
as there are potentially multiple independent folders under the src folder there should be 1 json file that contains all of the configuration that is required for that script to complete. 
the only exception for this is mutable values - eg build numbers, timestamps, and other values which are either random or indeterminate ahead of time. 

for values which are likely to be consistant across scripts - eg log verbosity, erroraction, etc. these can be set as $script level values but should be added to the $configuration object. values that are specific to the script - eg this download link does not qualify - $script:osListUrl   = "https://downloads.raspberrypi.com/os_list_imagingutility_v4.json"
If there are related values - eg public & private key filenames, don't create multiple configuration values in the .json file. create a property that represents some value - keyPairFileName and then in the method that uses it append/use those values.

eg "keyPairFileName": "ssh-keys"

function Invoke-CreateSshKeyPair($configuration){
    $keyPairFileName = $configuration
    $privateKeyFileName = "$($keyPairfileName).key"
    $publickeyFileName = "$($keyPairfileName).pub"
    #do some command with $publickeyFileName and $privateKeyFileName
}
examples of values that should be set as $script:variables:

$configuration | Add-Member -NotePropertyName 'tempDir'              -NotePropertyValue $script:tempDir
$configuration | Add-Member -NotePropertyName 'cacheDir'             -NotePropertyValue $script:cacheDir


We should not need the $configurationFolder variable except in the Get-Configuration method. it should return a single $configuration from the $configurationFolder & configurationFileName
$configuration | Add-Member -NotePropertyName 'configurationFolder'  -NotePropertyValue $ConfigurationFolder

If a variable value is used in a function then that is where we should collect the values in that function - not in the Add-AdditionalConfiguration function and set it globally on the $configuration object.  eg. 

bad:
function Add-AdditionalConfiguration()
{
    $configuration | Add-Member -NotePropertyName 'imgPath'              -NotePropertyValue ("$($baseDir)\$($configuration.vmName).img")
    $configuration | Add-Member -NotePropertyName 'sshKeyPath'           -NotePropertyValue (Join-Path $script:tempDir "$($configuration.vmName)-key")
    $configuration | Add-Member -NotePropertyName 'firstRunPath'         -NotePropertyValue (Join-Path $script:tempDir "$($configuration.vmName)-firstrun.sh")
    $configuration | Add-Member -NotePropertyName 'firstRunTemplatePath' -NotePropertyValue (Join-Path $script:assetsDir "firstrun.sh")
}

good:

$basedir = (Join-Path $script:tempDir)
$vmName = $configuration.vmName 
$imgPath = "$basedir\$($vmName).img" 
$sshKeyPath = "$baseDir\$($vmName)-key"
$privateKeyPath = "$($sshKeyPath).key" 
$publicKeyPath = "$($sshKeyPath).pub" 

It is essential that we pass only a $configuration object to each function so we can do that by adding any required properties to the $configuration like this - 

function Add-RequiredValuesToConfiguration($configuration)
{
    $configuration | Add-Member # $script:buildNumber
    #other parameters here.
}


## common - run.ps1

general function pattern - 
1. only pass $configuration. this mandatory.
2. have a write-host at the start of the function to indicate what the function will do/is for.
3. collect variables used by the function at the start of the function. don't use $configuration.somepropery except at the start of the function to collect the variables used by the function.
good:

function Invoke-GenerateSshKeypair($configuration) {
    $sshKeyPath = $configuration.sshKeyPath
    #Do something with $sshkeyPath
}

bad:
function Invoke-GenerateSshKeypair($configuration) {
    #Do something with $configuration.sshkeypath
}


Use powershell parameter splatting where possible. 
Check for a non zero exit code and exit. 
Write assets to disk outside of the run.ps1. run.ps1 for orchestrating the task - not writing dependencies at runtime. do not inline write files to disk - eg firstrun.sh. eg do not do this:

function Invoke-CreateFirstRunScript($configuration) {
    Write-Host "Creating firstrun.sh..."
    #create firstrun.sh in memory.
    Set-Content -Path $configuration.firstRunPath -Value ($lines -join "`n") -NoNewline
}


Each function must do one thing. Common violations:

- A function that fetches remote data AND transforms that data AND updates $configuration — split into a helper Get- function (fetch/transform) and an Invoke- function (update $configuration).
- A function that resolves a URL AND derives cache file paths from it — split. URL resolution is one concern; path derivation is another.

Helper functions (Get-, Search-, Test-) are exempt from the $configuration-only rule and may take whatever parameters make sense.
When a function needs to read data that was produced by a previous step (e.g. an SSH key generated by Invoke-GenerateSshKeypair), create a dedicated Get- function to read it. Do not read the file inline.
Use PowerShell's -replace operator with [regex]::Escape() for literal placeholder substitution. Do not use .NET instance methods (.Replace()).
When a recursive search function encounters items that may have child items in two different forms (inline vs remote), extract the child-item retrieval into a separate function. Do not mix fetching logic inside the search loop.
If you need temporary but generated content - eg ssh keys these also go into the TEMPORARY_ASSETS folder. 

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

all of the requirements that apply to the build version of run.ps1 apply to the tooling version of the run.ps1 except that we should create a ci.ps1 that calls run.ps1