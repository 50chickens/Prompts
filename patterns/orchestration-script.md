## orchestration script:

There are 2 patterns of orchestration script but they both follow a similar path. they always include the same scripts but each file can be a noop if it is not required for that scenario. 

1. scripts that are used to execute tooling. these follow the ci.ps1 -> invoke-*.ps1 pattern.
2. scripts that are designed to compile software. these follow the ci.ps1 -> build-test.ps1 -> invoke-*.ps1 pattern as we need the build process to work locally during development and then also when we run the build process under a github actions runner. 

high level. 

1. the main entry hook is always ci.ps1. 
2. ci.ps1 calls build-test.ps1 which can be a noop. build-test.ps1 is used exclusively for compiling software. 
3. ci.ps1 calls invoke-*.ps1 see the invoke-*.ps1 pattern.

invoke-*.ps1 pattern:

invoke-* is a sequence of scripts that have the following scopes. each of these files are under SOLUTION_FOLDER*\scripts - eg SOLUTION_FOLDER1\scripts. They should be run in the following order:

invoke-application-tests.ps1 - this file is for running tests of the output from the build-test.ps1, or ci.ps1. eg if we need to run tests that are not in either unit or integration tests - eg running a console app to verify connectivity. eg fm3 connectivity tests, or chatgpt hello world tests. we are running tests before deployment if neccessary. 
invoke-docker.ps1. #this creates a docker container from the current SOLUTION_FOLDER. if there are files that are either needed to include in the container image at build time (eg compiled binaries) , or are required at container run time (eg configuration files) they should be copied into the docker folder by this script. see the docker.md patterns file for futher information. only files that are required to create the docker image, or at docker runtime should go into this folder. this script does not do docker push to external sites etc. 
invoke-deployment.ps1 #this takes the artifacts from the previous steps and deploys them to some external place. eg dockerhub, aws, installs them on the local machine. artifacts should be in a read to deploy state at this time and not need any additional work/changes. 
invoke-deployment-test.ps1 #this script tests the artifacts were deployed & working correctly. this script does nothing other than test that the application is working as designed once it is deployed. it does not deploy/change anything at this point. artifacts/applications should have already been deployed at this and point and we are testing if that is the case. 

Examples of the build pattern can be found the examples folder. The tooling pattern is the same except build-test.ps1 is a noop script.

## Pipeline logging

Add timestamps to the log so we can see how long things have taken. 
Wse Write-Log instead of write-host. 

## include files. 

include files are .ps1 files which are dot sourced as a way to keep ci.ps1, build-test.ps1 and invoke-*.ps1 sizes down or to use DRY principals.
If there is the includes folder under the working directory. we dot source all of the files in there. 
they are categorized into sections where there is no overlap. eg if we swapped out repeating these script from raspberry pi arm64 to redhat x64 for example the changes would be isolated to removing the rasperry pi section and replacing it appropriately. you do not need to match function names here - eg if we switch from raspberry pi arm64 to redhat x64 don't give functions in the redhat.ps1 an incorrect name just to make them work. they should really represent the redhat equivalents. 

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


Each script independently loads its own configuration in the Get-Configuration method. Do not pass a $configurationFolder or a configuration file name between scripts - the config location is resolved by Get-Configuration and returned on the single $configuration object.

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


## common - invoke-*.ps1

general function pattern - 
1. only pass $configuration. This is mandatory.
2. have a write-host at the start of the function to indicate what the function will do/is for.
3. collect variables used by the function at the start of the function. don't use $configuration.somepropery except at the start of the function to collect the variables used by the function.
4. in linux don't use the /tmp folder for any reason. temporary files should go into the temporary_assets folder. 

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
do not use invoke-*.ps1 scripts to write executable code/scripts to disk. The primary purpose of ci.ps1 or invoke-*.ps1 is for orchestrating tasks - not writing dependencies at runtime. 
Do not inline write files to disk - eg firstrun.sh. eg do not do this:

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

## build - ci.ps1 -> build-test.ps1 => invoke-*.ps1 pattern:

include a ci.ps1. this is override the nuget package source to LocalRepo so that push nuget packages to the LocalRepo instead of the github packages repo when running locally. this is so that we can test the entire pipeline before commiting/publishing packages to the github packages feed. 
invoke-*.ps1 should only have 1 script parameter -nugetPackageSourceName. It should have a default name of github in invoke-*.ps1.
invoke-*.ps1 should live in git repository root under the ci folder.  
invoke-*.ps1 should generate a BuildNumber-based version which is then passed to build.xml as a parameter. BuildNumber uses ticks: $([System.DateTime]::UtcNow.Ticks.ToString('D').Substring(0, 9)). NugetVersion=$(MajorVersion).$(MinorVersion).$(BuildNumber). Do not append -Debug or -Release suffixes to package names. Clean version numbers only.
when calling any command lines tools such as dotnet or nuget - use logging level minimum but make the logging level a script level variable so that if additional logging is required it is a 1 line change. 
By default the logging level should be minimal. 
After editing any C# source files run dotnet format <solution> before finishing. The CI pipeline runs dotnet format --verify-no-changes and will fail on whitespace errors.
only run integration tests if not running under github action. the RunIntegrationTests property in the configuration.json should default to false. we will set it to true if we are not running under GHA.

## tooling - invoke-*.ps1 .

all of the requirements that apply to the build version of invoke-*.ps1 apply to the tooling version of the invoke-*.ps1 except that we should create a ci.ps1 that calls invoke-*.ps1 directly.