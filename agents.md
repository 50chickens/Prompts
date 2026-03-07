# information for agents.

##  General instructions.
Do not write comments. Don't write documentation files, or any *.md unless it is asked for. Do not write summaries at the end of a task unless i ask you.
Keep summaries after a task is finished to 50 words or less. 
Mention if you have referenced this doc in the summary but keep it very brief. 
Dont add fallbacks, work arounds, graceful handling, verbose error handling. Don't create overly cautious code. it is ok if things fail. Unless i tell you, the code should be as lightweight as possible and as free of code that is unrelated to the task at hand. 
If the user says to do something, or stop doing something add that correction to the agents.md file. 
Do not use decorations, bullet points, indenting in code or documentation. Only add important detail that is not specific to this repo in this file. This file is to improve the quality of any code - not just that which is specific to this repo.

Error handling.
DO NOT create empty or low-value try-catch blocks. Let exceptions propagate unless specifically handling expected conditions.
Use ArgumentNullException.ThrowIfNull(x) for null checks.
Use string.IsNullOrWhiteSpace(x) for strings.
Guard early. Avoid blanket !.
Choose precise exception types: ArgumentException, InvalidOperationException.
No silent catches. Don't swallow errors. Log and rethrow or bubble up.

Software architecture.
When creating a new console app, or webapi use DefaultApplicationBuilder or WebApplicationHostBuilder patterns. 
Use extension methods for service registration. eg .AddConsoleApp

Coding patterns.
Apply SOLID principles.
Classes should have a single concern and only a primary code path. If a class has more than concern or more than one primary code path consider it for refacting into two classes. 
Do not create dynamic types or records for any reason at any time.
Use file-scoped namespaces.
Use interfaces in Core layer. Implementations in Infrastructure or Application layers. Core has zero external dependencies.
Use DefaultApplicationBuilder pattern for DI setup. Register services in logical order: logging first, then infrastructure, then application services.
Keep classes single concern. Use the service pattern. Use constructor injection for dependencies. 
Don't create private classes. Make types public or internal.
Keep the Main method in a project as minimal as possible. Classes should have only 1 primary code path - if there are more than split the class. 
Use the Autofac nuget package and create an static AutofacContainer.Create() method in the AutofacContainer class and use this to setup the container. 
Use extension methods where practical. 
All services accept required parameters in constructor. No static service locators.
Use type-safe logging with ILog<T>. Never use LogManager or static logger instances. Inject logger via constructor.
Use async Task for I/O operations. 
Return Task<T> from services. 
Never use blocking calls like Wait() or Result.
Only use nullable if this is most optimal.

Testing.
Create unit test to verify DI container can resolve all services.
Use Nunit for tests. Testcases should handle multiple scenarios for single method. 
Use NSubstitute for all interface mocking.
Follow the project's own conventions first, then common C# conventions.
Keep naming, formatting, and project structure consistent.
Tests must use primary code paths only.
No timing-dependent assertions. No Stopwatch usage.
No Task.Delay assertions in tests.
Use async tests unless code path is not async.
use [TestCases] where possible.
Mock all external dependencies: file I/O, network, logging.
Tests should be deterministic and fast.
Don't create unit tests that test for DoesNotThrow(). this are meaningless tests. When testing a method we should be testing the return value which represents the main function of the method. 
Useless/bad code and/or comments.

DON'T add interfaces/abstractions unless used for external dependencies or testing.
Don't wrap existing abstractions.
Keep names consistent. 
Don't add unused methods/params.
When fixing one method, check siblings for the same issue.
Reuse existing methods.

Nuget packages & versions etc.

NEVER directly edit .csproj or Directory.Packages.props to add or remove packages. Use dotnet add/remove commands.
DIRECT EDITING permitted only for changing versions of existing packages.
VERSION UPDATES require verification: target version exists, determine if managed per-project or centrally, update version, run dotnet restore.
do not create nuget.config files in the project directory. if the nuget source does not exist you should never create it. The build should fail. NuGet sources are configured in the user's global config. Never create project-level NuGet.Config files.
Do not append -Debug or -Release suffixes to package names.

Repository structure guidance.

The setup repository contains shared audio infrastructure code including device abstractions, routing, and plugin loading. The ipscm repository contains generic infrastructure shared across all projects: logging, DI configuration, HTTP utilities, and other cross-cutting concerns. The alsionyx repository contains end applications that use setup and ipscm libraries. When creating new projects determine which category they belong to: if it is audio-specific put it in setup, if it is generic infrastructure put it in ipscm, if it is an application put it in alsionyx.

Test Configuration

Use NUnit and NSubstitute for testing frameworks.
Tests must use primary code paths only. Use test cases where possible. If a test class has more than more than 2 tests analyze whether you should split the class or not.
No timing-dependent assertions. No Stopwatch usage.
No Task.Delay assertions in tests.
Use async tests unless code path is not async.
Use [TestCases] where possible.
Mock all external dependencies: file I/O, network, logging.
Tests should be deterministic and fast.
Record test metadata in datestamped JSON files with test name, duration, status, environment. DO NOT use CSV.


powershell/CI pipeline architecture.

repository layout:

/ (repository root)
/ci
    /ci/gh.ps1 - only run in local development environment. do not reference in github action.
    /ci/build-test.ps1 - called from github action with only -ConfigurationFolder configs
    /ci/configs - contains 1 json file with the same name as the visual studio solution it relates to. only contains configuration that is specific to that solution - eg solution name. 
/src - the top level folder for either the solution or solutions. 

build/deployment specific guidelines.

Github action guidelines.

A github action should have only two steps -
dotnet source add. 
built-test.ps1 -configurationFolder $configs.
Create NuGet source in GitHub Actions workflow, not in gh.ps1, to allow -NugetSourceName parameter override. 

NuGet Package Permissions.
When this repo depends on NuGet packages hosted in GitHub Packages from another private repository the GitHub Actions workflow needs proper permissions. The workflow must have permissions: packages: write to authenticate with the GitHub Packages NuGet source. The GITHUB_TOKEN passed to dotnet nuget add source requires read access to the external packages. If builds fail with 403 Forbidden errors when restoring packages, verify repository access: the user running the build must have access to the source repository, or the packages must be published as public. To verify package access without fixing, use: gh api -H "Accept: application/vnd.github+json" "/repos/50chickens/REPO/packages?package_type=nuget" or check the workflow logs for authentication errors. 

When running locally use two powershell files - 
gh.ps1 and build-test.ps1. gh.ps1 should call build-test.ps1 with -nugetPackageSourceName "local-nuget-repo".
gh.ps1 should not test for the nuget repo to exist. it should fail during the restore process.

dotnet guidelines.
Only use Debug for dotnet build configurations. 
pass the buildConfiguration parameter to build.xml to include it in the msbuild task that creates the nuget package. this build configuration value should be added as a nuget package tag.


guidelines relating to build-test.ps1:

build-test.ps1 should only have 1 script parameter -nugetPackageSourceName. It should have a default name of github in build-test.ps1.
build-test.ps1 should live in git repository root under the ci folder.  
build-test.ps1 should generate a BuildNumber-based version which is then passed to build.xml as a parameter. BuildNumber uses ticks: $([System.DateTime]::UtcNow.Ticks.ToString('D').Substring(0, 9)). NugetVersion=$(MajorVersion).$(MinorVersion).$(BuildNumber). Do not append -Debug or -Release suffixes to package names. Clean version numbers only.
when calling any command lines tools such as dotnet or nuget - use logging level minimum but make the logging level a script level variable so that if additional logging is required it is a 1 line change. 
By default the logging level should be minimal. 
After editing any C# source files run dotnet format <solution> before finishing. The CI pipeline runs dotnet format --verify-no-changes and will fail on whitespace errors.

# Generic powershell coding techniques.
General powershell code & scripting guidelines.
Only use approved verbs for function names.
Prefer powershell modules over invoking any command line tools. If there are powershell modules that can be more natural to execute them in powershell and they do not exist they can be installed. 
Assume that you are running on powershell 7 or above always unless i tell you. Don't add any forward or backwards compatbility code for powershell 5.
Scripts should have a single main execution flow at the bottom of the script. do not add try/catch blocks, or functions around this. It should just have a list of build steps and pass the -Configuration $configuration object as parameter to the function.
The only function parameters should be the $configuration object. 
For other script level values - are required add them onto the $configuration object as new properties. eg: Add-Member 
Use as few global or script level variables as possible. 
If a script parameter has a default value add a comment on the end of that line as to why it has a default. keep this description short. 
There should only functions above the main execution part of the script. Define script level variables or constants at the top of the script. 
Set the working directory to the folder where the script lives in as a first command using $PSScriptRoot
use Set-Location $PSScriptRoot to switch to the folder where the script live, don't use real paths in the script.
Do not create an orchestrator function that wraps all steps; call each function in sequence explicitly in main execution to keep the path transparent.
Dont use magic strings in text. if a value is required - add it to the $configuration object and pass it into the function. Add an Add-AdditionalConfiguration -Configuration $configuration which adds any properties/values and returns $configuration.
There should be only 1 function parameter $configuration.
Use an Invoke-PreflightCheck for important configuration values. Otherwise - parameter values such as filenames should not be validated. 
Do not do any validation of parameters unless they are important. Add an Invoke-PreflightCheck function which does this only if required. 
Do not write defensive code except in Invoke-PreflightCheck. if there are directories, or configuration that are essential to the script execution they only be caught in Invoke-PreflightCheck
other workflow guidelines. 
Don't scan for invalid items and then add them to a list and then report the problematic items. 
Error Handling: DO NOT wrap code in try-catch blocks. Let errors surface using $ErrorActionPreference = 'Stop'. CI/CD systems require natural error propagation to detect failures.
Configuration Processing: Process items in sequence without error handling. Each failure stops the script naturally. Authentication failures must surface to caller.
Error Propagation: DO NOT mask errors with try-catch. Let exceptions bubble up for proper CI/CD detection and logging. Use try/catch sparingly - ideally it should only be used for cleanup. 
Do not use head, tail, grep, pipe, redirection, select-object, or Select-String when executing either command lines or in any of the .ps1 scripts. eg 2>&1.  Use minimal loggin as a default and for write-host surface only meaningful information related to the task at hand. if additional detail is required it should surface through errors, or by increasing the log verbosity but the log verbosity by default should be minimal. 
Do not write text/json/other files onto disk for debugging purposes. Errors should be diagnosable only through the script logs although it may require increasing the lo verbosity to do that.
Refactor repeated sequences into functions: If the main execution contains repeated statement sequences (like multiple invocations or load-then-process patterns), extract them into helper functions. Each helper should perform one logical operation: load config, run pipeline, process batch, etc.
Powershell functions should have one and only 1 purpose. 

An example of existing pattern which meets these guidelines is:

param(
    [string]$ConfigurationFolder,  # Path to folder containing JSON configuration files
    [string]$NugetSourceName = "github"  # NuGet source for package publishing
)

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
$nupkgOutFolder = "nupkgOut" 
$BuildNumber = "some calculated value that is required throughout the script"

function Invoke-PreflightCheck ($ConfigurationFolder) 
{ 
    if ([string]:isnullorempty($ConfigurationFolder) or -not (Test-Path $ConfigurationFolder)) 
    {
        Write-Error "ERROR: Configuration folder not specified or not found: $ConfigurationFolder"
        exit 1
    }
}
function Add-RequiredValuesToConfiguration($configuration)
{
    $configuration | Add-Member # $script:buildNumber
    #other parameters here.
}

function Invoke-RestoreDependencies($configuration) {
    Write-Host "Restoring dependencies..."
    $solutionFile = $configuration.SolutionFile
    #rest of function here.
    Write-host "Finished restoring dependencies"
}
function Invoke-CodeFormatCheck {
    param([object]$Configuration)
    
    $solutionFile = $Configuration.solutionFile
    Write-Host "Checking code format..."
    dotnet format $solutionFile --verify-no-changes
    write-host "finished code format check."
}


#main script execution starts here.

Invoke-PreflightCheck -ConfigurationFolder $ConfigurationFolder
$configurations = Get-BuildConfigurations -ConfigurationFolder $ConfigurationFolder
Add-RequiredValuesToConfiguration $configuration
Write-Host "=== Build & Test ==="
$configurations |%{
    $configuration = $_
    Invoke-RestoreDependencies -configuration $_
    Invoke-CodeFormat -configuration $_
}