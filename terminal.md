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
