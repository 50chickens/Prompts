# Generic powershell coding techniques.
read the logging pattern from C:\git\internal\Prompts\component_prompts\solutions\ipscm\skils.md
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