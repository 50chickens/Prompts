Prefer powershell modules over invoking any command line tools.
If there are powershell modules that can be used to invoke them in powershell and they do not exist they can be installed.
read the examples from the powershell-examples repo in the same folder as this document.
Don’t do wildcard/partial matches on AWS resources. check that matches. fail/exit the script immediately upon error.
Do not add additional parameters at the script level if the number we’re expecting. eg delete-stack should always equal 1 or 0.
Do not add additional metrics unless they are part of either Get-AdditionalConfiguration or Get-Configuration.
Get definitions for Get-AdditionalConfiguration eg Get-AdditionalConfiguration ($configuration).
Add additional configuration as static method that reads -json file to create a $configuration object, or constructs a $configuration object from static values. note should not add script level values here - eg verbosepreference.
Get-AdditionalConfiguration this method returns additional configuration.
$configuration = Get-Configuration #static configuration values which are not script level.
Get-Configuration $configuration #static configuration values.
Use untyped $configuration input to functions.

Use inline pipeline functions use filter out objects that don’t match the required criteria.
common configuration like: $iPort = “0.0.0.0:443” should not go into the function. this should be part of get-configuration because it more of a constant which could be used in multiple places and is not a run time value.
do not use ForEach-Object or Where-Object. use this for for each: eg

|%{

}

except when there is runtime content - eg netsh http show urlacl. use this pattern:
$netshurlacls = (netsh http show urlacl)
$line = $_
switch -Regex ($line)
{
}

use this for where object - | ?
do not use foreach to loop through a list of items in a collection. eg foreach ($line in $lines). use $lines | %{
$line = $_
write-host “doing some operation with $line”
#do some operation here.
}

don’t use if statements & matching on regexs together. eg
if ($line -match “Reserved URLs:\s+(.*.+)”) {
use switch statements for regex matching.
$line = $_
switch ($line)
{
$_ -imatch “Reserved URLs:\s+(.*.+)”
#do some operation
default
#do some default operation
}
}

Any values which are constants should get into get-configuration. eg
Cert:'LocalMachine' ): This is similar to no magic strings in code concept.
Use these patterns :
function Get-configuration () #generates static configuration (similar to c# constants).
{
# create static configuration values.
}

function Invoke-PreflightCheck()
{
# used to check for conditions that would stop the script from executing successfully.
# should not contain control logic - ie certificate needs updating.
}

function Get-RuntimeConfiguration($configuration) #adds runtime values to configuration objects. this function should not change the state of the environment or machine where it being run. eg creating files, importing things. it should be read only.
{
# can contain values that can only be known at runtime (ie when we switch it off)
$runtimeValue1 = Get-RuntimeValue1 -config $configuration #Get-Runtime can only use $configuration
$configuration | Add-Member #this is for runtime configuration. you can add to $configuration
}

Don't put control logic into Get-AdditionalConfiguration or Invoke-PreflightCheck. eg this check should be in Invoke-UpdateReportingServicesBinding like this:
Any methods that perform writes, updates, or changes to the environment or machine state state should clean early-exit guard if they are not required. eg we test if things need updating first, and then if not we exit. Function exit-guards (also can be called Test-Should pattern) looks like:

function Test-ShouldFunctionRun() #this should not return any value.
{
#test for some condition. eg
#check to see if some resource exists, or need updating.
Write-Log a message that tells the user why we don't need to run Function1.
}

function Invoke-ShouldFunction1()
{
if (!(Test-ShouldFunctionRun $configuration)
{
return
}
#complete function 1.
}

if there are 2 methods where the second one depends on some value/variable from the first one it is ok to make additional calls to get the information required. eg an Arn or some other value that we can only know once resource 1 is created.
$configuration should have the name of resource1 so that we can look it up when creating resource2.
Invoke-EnsureResource1 $configuration
Do not add checks for something that is essential to the function. since we are using $erroraction = stop this function should fail if $logDir does not exist. it adds unnecessary lines to the code without any value here.
function Get-ReportingServicesLog ($configuration)
{
$logDir = Join-Path $configuration.ssrsRoot 'LogFiles'
$logFile = Get-ChildItem "$logDir\$($configuration.hostingAppName)" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (!$logFile) {Write-Log No $HostingService log found [WARN]} #do not do this - since $logDir is essential to the function this adds no value and the script should fail at this point.
# instead add an object for the purposes of printing it if you need to do this - use powershell transcripts. this way you capture the entire conversations including any errors in the script itself. eg don't do this. the script should turn
Start-Transcript
$logFile = Select-Object -Last $configuration.hostingTagTailLines | Add-Member
Stop-Transcript
Join-Path
SPScriptRoot
[System.IO.Path]::GetFullPath
}

When referencing filenames. All of the file paths in the json files that contain configuration should be relative paths and so Resolve-Path, Join-Path and SPScriptRoot should not be necessary. eg we should be resolving filenames relative to current folder unnecessarily. eg
use paths which are relative to module in the current folder unnecessarily. eg "...includes..." this should be "...\includes"
