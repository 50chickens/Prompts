---
applyTo: '**'
---

# Terminal command rules

Applies to every terminal command run by the agent.

- Never prefix a command with `cd`. Scripts call `Set-Location $PSScriptRoot` themselves; run commands in place.
- When running a powershell command just use exactly the & path_to_script.ps1. For scripts that are in the current folder use & .\script.ps1. for scripts that are above the current folder use the full path - eg & c:\somefolder\somescript.ps1.
- Never redirect or filter output: no `2>&1`, no `| head`, no `| tail`, no `>`, no `*>`, no `Out-File`.
- Banned in commands: head, tail, grep, Select-String, Select-Object, Get-Content, find-content, and piping output into filters.
- Never echo exit codes (`$LASTEXITCODE`, `$?`, `EXIT=...`).
- Assume minimal verbosity; keep output small by running the right command, not by slicing it.
- Never use `| Out-Null`; use `$null = ...`.
- Prefer PowerShell modules/cmdlets over command-line tools. If a suitable module does not exist, install it rather than shelling out.
- Don't use wildcard/partial matches on resources; check you get the expected number of matches (eg 0 or 1) and fail immediately on error.
- Don't guard a required cmdlet with `Get-Command`; let it fail.
- Don't use `-ErrorAction SilentlyContinue` on writes or mutations.
- Do not add fallbacks, workarounds, or graceful error handling. It is ok if things fail.
- Do not scan for invalid items or collect them into a list for reporting later. 
- Do not write files to disk for debugging during once off commands. if debugging is multi step create a script which follows the powershell skills for triage. 
- A non-zero exit does not throw; the terminal reports the exit status, so don't add checks or echoes for it.
- Don't use nested instances of powershell. eg if we are already running in a powershell terminal don't include pwsh in any form on the command line. 
- reuse terminals as much as possible. Some terminals have a slow load time and this introduces problems with detecting when commands return, or it has output etc. 
- Don't write temporary files for debugging purposes outside of the current working area ever. 
- If you need to create working files and if the folder is a git repo - create a temp folder and then check/add for it in the .gitignore file. ask for permission to modify that. 
- Don't use complex single line command lines that wraps a small task. This is boiler plate that can be used in ci.ps1 Invoke-PreflightCheck. See the powershell skill on where this should be added. 
- This is an example of a complex single line command lines that wraps a small task that could go into Invoke-PreflightCheck
     $ci='D:\git\PS-someFolder\ci'; foreach ($f in @('ci.ps1','build-test.ps1','invoke-application-tests.ps1')) { $e=$null; $null=[System.Management.Automation.Language.Parser]::ParseFile("$ci\$f",[ref]$null,[ref]$e); Write-Output "$f parse errors=$($e.Count)" }; Write-Output '--- build-test gate ---'; pwsh -NoProfile -File "$ci\build-test.ps1"; Write-Output "exit=$LASTEXITCODE"; Write-Output '--- app-tests gate ---'; pwsh -NoProfile -File "$ci\invoke-application-tests.ps1"; Write-Output "exit=$LASTEXITCODE". 
- If cli tools have a json output format use that. Eg for the AWS Cli use $buckets = (aws s3 list-buckets --output json) | ConvertFrom-Json. 
- Capturing output json into a json means we can cut down on the number of calls, or repeated calls for similar things. Prefer returning all objects one time and then filtering/querying in memory to get the thing we're after. the exception is that if the list is excessively large.
- If you find yourself repeatedly doing similar things - create a helper script with parameters. eg this is excellent example of wasted effort that could be scripted - 
     $ci='D:\git\PS-ScriptFolder\ci'; foreach ($f in @('configuration.json','build-test.json','applicationtests.json')) { $j = Get-Content "$ci\configs\$f" -Raw | ConvertFrom-Json; Write-Output "$f OK - keys: $(($j.PSObject.Properties.Name) -join ', ')" }
- Do not verify json files in the terminal. This is extremely wasted effort. configuration files that are json which are loaded by Get-Configuration would cause the script to fail if they were malformed, or a configuration item is missing etc. relying on the inherent error detection in the powershell script that uses the json file is the validation that we need. Not during terminal sessions. 
