---
applyTo: '**'
---

# Terminal command rules

Applies to every terminal command run by the agent.

- Never prefix a command with `cd`. Scripts call `Set-Location $PSScriptRoot` themselves; run commands in place.
- When running a powershell command just use exactly the & path_to_script.ps1. For scripts that are in the current folder use & .\script.ps1. for scripts that are above the current folder use the full path - eg & c:\somefolder\somescript.ps1.
- A command is a script path followed by literal arguments and nothing else: no pipelines, no `;` chains, no inline `if`, no `$( )` subexpressions, no quoted-expression arguments. Work that needs any of those is a script, not a command line.
- Never redirect or filter output: no `2>&1`, no `| head`, no `| tail`, no `>`, no `*>`, no `Out-File`.
- Banned in commands: head, tail, grep, Select-String, Select-Object, Get-Content, find-content, and piping output into filters.
- Never echo exit codes (`$LASTEXITCODE`, `$?`, `EXIT=...`).
- Assume minimal verbosity; keep output small by running the right command, not by slicing it.
- Never enumerate a whole tree, drive or repository root. Every listing is scoped to a named path with a filter, and you know the expected number of results before you run it. If the number of results depends on how many files happen to exist, the command is wrong.
- Do not use a recursive listing to find something. Search for it instead: name the file if you can, or filter for the pattern. Listing everything and reading it is not a search, and it costs a call for every file you did not need.
- Output volume must be bounded by the question, not by the size of the filesystem. A command whose output grows as the folder grows will eventually be unreadable, and it will be unreadable sooner than you expect.
- Ask for the specific thing you need rather than the whole and then narrowing it. To learn one file's size or timestamp, query that file.
- Do not pipe command output into cmdlets whose purpose is to reshape, reorder or summarise it for display: `Sort-Object`, `Format-Table`, `Format-List`, `Group-Object`, `Measure-Object`, `Where-Object`, `Select-Object`. Produce the right output the first time rather than reformatting it afterwards.
- Do not build display strings by concatenating properties in a `|%` block. That yields text where objects belong, so nothing downstream can be sorted or filtered correctly, and the output cannot be reused.
- No manual path arithmetic: no `Substring`, `Replace` or `-split` on `FullName` to shorten or compare a path. It is brittle, it breaks the moment a path depth changes, and it is unnecessary because the provider already exposes the name and the relative form.
- Never use `| Out-Null`; use `$null = ...`.
- Prefer PowerShell modules/cmdlets over command-line tools. If a suitable module does not exist, install it rather than shelling out.
- Don't use wildcard/partial matches on resources; check you get the expected number of matches (eg 0 or 1) and fail immediately on error.
- Don't guard a required cmdlet with `Get-Command`; let it fail.
- Don't use `-ErrorAction SilentlyContinue` on writes or mutations.
- Do not add fallbacks, workarounds, or graceful error handling. It is ok if things fail.
- Do not scan for invalid items or collect them into a list for reporting later. 
- A command that needs more than one statement goes in `tmp\probe.ps1` at the repo root, run as `& .\tmp\probe.ps1`. When it fails, edit that file and rerun the same command instead of retyping a command line. A probe that outlives its task is deleted or becomes a `psmodules` tool per `TOOLS.md`; `tmp` is untracked and holds no source.
- A non-zero exit does not throw; the terminal reports the exit status, so don't add checks or echoes for it.
- Don't use nested instances of powershell. eg if we are already running in a powershell terminal don't include pwsh in any form on the command line. 
- reuse terminals as much as possible. Some terminals have a slow load time and this introduces problems with detecting when commands return, or it has output etc. 
- Don't write temporary files for debugging purposes outside of the current working area ever. 
- If you need to create working files and if the folder is a git repo - create a temp folder and then check/add for it in the .gitignore file. ask for permission to modify that. 
- No complex single line command line. A command wraps one task; the moment it needs a loop, a variable, or a second statement it is a script.
- If cli tools have a json output format use that. Eg for the AWS Cli use $buckets = (aws s3 list-buckets --output json) | ConvertFrom-Json. 
- Capturing output json into a json means we can cut down on the number of calls, or repeated calls for similar things. Prefer returning all objects one time and then filtering/querying in memory to get the thing we're after. the exception is that if the list is excessively large.
- If you find yourself repeatedly doing similar things - create a helper script with parameters. eg this is excellent example of wasted effort that could be scripted - 
     $ci='D:\git\PS-ScriptFolder\ci'; foreach ($f in @('configuration.json','build-test.json','applicationtests.json')) { $j = Get-Content "$ci\configs\$f" -Raw | ConvertFrom-Json; Write-Output "$f OK - keys: $(($j.PSObject.Properties.Name) -join ', ')" }
- Do not verify json files in the terminal. This is extremely wasted effort. configuration files that are json which are loaded by Get-Configuration would cause the script to fail if they were malformed, or a configuration item is missing etc. relying on the inherent error detection in the powershell script that uses the json file is the validation that we need. Not during terminal sessions.

# WSL scripts

Scripts that run inside WSL are executed only through the harness, never by calling wsl.exe directly:

    & C:\git\internal\Prompts\patterns\examples\wsl\invoke-wsl.ps1 -Script /mnt/c/git/some/folder/script.ps1 -Root -ScriptArgument value

- The harness boots the distribution as its default user, and restarts the distribution when /mnt is owned by the wrong uid. WSL gives /mnt the uid of the user that starts the distribution, so a distribution first started with `wsl -u root` leaves every file under /mnt owned by root; chmod and utime then fail for the real user and git, npm and any build that touches a file under /mnt fail with permission errors that look like something else. Never start a distribution with `wsl -u root` on its own: run the harness, which repairs the mount itself.
- Pass -Root only for a script that installs packages or writes outside /mnt and outside the calling user's own tree.
- Do not pass -e, -d, -u or a WSL_UTF8 assignment by hand, and do not build a command line with an inline `env`, a shell `cd` or a chained second wsl.exe. The harness owns all of that.
- Arguments for the target script go after the harness parameters and are forwarded unchanged. The -Script value must be the WSL form, /mnt/c/git/..., never C:\git\...
- The harness starts the script through its shebang, so every WSL script needs a shebang and LF line endings. A CRLF script fails with "cannot execute: required file not found", which reads like a missing interpreter.
- Only PowerShell 7 scripts are run inside WSL. The one exception is the bootstrap that installs PowerShell, which cannot itself be PowerShell.
- Do not write files into the WSL user's home directory. The distribution is disposable and its home goes with it; write into the project folder under /mnt/c and keep only regenerable build caches inside the distribution.
- A .NET build cannot write its obj directory under /mnt, because MSBuild cannot set the timestamp on its up-to-date marker files there. Point the build at an artifacts path inside the distribution and keep the sources and the emitted output under /mnt/c.
 
