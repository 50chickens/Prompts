# C# Code Generation Instructions

General instructions.
Do not write comments. Don't write documentation files, or any *.md unless it is asked for. Keep summaries after a task is finished to 50 words or less. Mention if you have referenced this doc in the summary but keep it very brief.
If the user suggest's do or do not do somnething add the guidance that they have given you to this file. 
Do not use decorations, bullets, indenting. Only add important detail that is not specific to this 
repo in this file. This file is to improve the quality of any code - not just that which is specific to this repo.

Error handling.
DO NOT create empty or low-value try-catch blocks. Let exceptions propagate unless specifically handling expected conditions.
Use ArgumentNullException.ThrowIfNull(x) for null checks.
Use string.IsNullOrWhiteSpace(x) for strings.
Guard early. Avoid blanket !.
Choose precise exception types: ArgumentException, InvalidOperationException.
No silent catches. Don't swallow errors. Log and rethrow or bubble up.

Software architecture.
When creating a new console app, or webapi use DefaultApplicationBuilder or WebApplicationHostBuilder patterns. 
Use extension methods for service registration.

Coding patterns.
Apply SOLID principles.
Use file-scoped namespaces.
when adding a new component check/add the usings statement. this will save time doing rework due to simple compilation errors. 
Do not create dynamics for any reason at any time.
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

dont do this. It is a low value try/catch block. 

catch (Exception ex)
{
    _logger.Error(ex, "Failed to shutdown SoundFlow backend");
    return Task.FromResult(false);
}

Testing.
Create unit test to verify DI container can resolve all services.
Use nunit for tests. Testcases handle multiple scenarios for single method. If testing many methods, split class.
Record test metadata in datestamped JSON files. Include test name, duration, status, environment. DO NOT use CSV.
Follow the project's own conventions first, then common C# conventions.
Keep naming, formatting, and project structure consistent.

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

CI pipeline architecture.

The pattern for managing the CI pipeline with powershell is:
A github action should have only two steps. 
dotnet source add. 
built-test.ps1 -configurationFolder $configs.
    - this should only have 1 script parameter - nugetPackageSourceName. It should have a default name of github. 
When running locally use two powershell files - 
gh.ps1 and build-test.ps1. gh.ps1 should call build-test.ps1 with -nugetPackageSourceName "local-nuget-repo".
gh.ps1 should not test for the nuget repo to exist. it should fail during the restore process.
build-test.ps1 information:
build-test.ps1 should live in git repo root under the ci folder. it should have a subfolder - configs that contains configuration json files with the naming convention of solution-name.json. these json files contain build configuration that is specific to the solution being built. do not put generic build details in this file. 
build-test.ps1 should have a single main execution flow at the bottom of the script. do not add try/catch blocks, or functions around this. It should just have a list of build steps and pass the -Configuration $configuration object as parameter to the function.
if a script parameter has a default value add a comment on the end of that line as to why it has a default. keep this description short. 
There should only functions above the main execution part of the script. Define script level variables or constants at the top of the script. 


# generic powershell coding techniques.

Do not create an orchestrator function that wraps all steps; call each function in sequence explicitly in main execution to keep the path transparent.
Dont use magic strings in text. if a value is required - add it to the $configuration object and pass it into the function. add an Add-AdditionalConfiguration -Configuration $configuration which adds any properties/values and returns $configuration.
Rhere should be only 1 function parameter $configuration.
Do not do any validation of parameters unless they are important. Add an Invoke-PreflightCheck function which does this only if required. 
Do not write defensive code except in the Invoke-PreflightCheck. if there are directories, configuration that are essential to the script execution they should be caught here. 
Don't scan for invalid items and then add them to a list and then report the problematic items. This is a waste of code and unneccarily complex. 
Error Handling: DO NOT wrap code in try-catch blocks. Let errors surface using $ErrorActionPreference = 'Stop'. CI/CD systems require natural error propagation to detect failures.
Configuration Processing: Process items in sequence without error handling. Each failure stops the script naturally. Authentication failures must surface to caller.
Error Propagation: DO NOT mask errors with try-catch. Let exceptions bubble up for proper CI/CD detection and logging. Use try/catch sparingly - ideally it should only be used for cleanup. 
do not use head, tail, grep, pipe, redirection, get-content, or Select-String. the best option is to keep logging minimum and surface only meaningful information. if additional detail is required it should surface through errors, or by increasing the log verbosity but the log verbosity by default should be minimal.
Do not write text/json/other files onto disk for debugging purposes. Errors should be diagnosable only through the build logs.
Refactor repeated sequences into functions: If the main execution contains repeated statement sequences (like multiple invocations or load-then-process patterns), extract them into helper functions. Each helper should perform one logical operation: load config, run pipeline, process batch, etc.

CI/CD Pipeline Pattern: 
Create NuGet source in GitHub Actions workflow, not in gh.ps1, to allow -NugetSourceName parameter override. 
build-test.ps1 is called from either subsequent step in GHA or via gh.ps1. It gets all .json files in configs folder and for each it: restore, build, test sequentially per config. 
NuGet Versioning:
Use timestamp-based versioning in build.xml: NugetVersion=1.0.$([System.DateTime]::UtcNow.Ticks.ToString('D').Substring(0, 9)). Do not append -Debug or -Release suffixes to package names. Clean version numbers only.

Sample Plugins:
The application includes 2 sample plugins for development and testing:
1. Sample Reverb - URI: urn:alsionyx:sample-reverb
2. Sample Gain - URI: urn:alsionyx:sample-gain
These are provided by MockLv2PluginDiscoverer and available via GET /api/plugins endpoint. No fallbacks or loading from disk.
