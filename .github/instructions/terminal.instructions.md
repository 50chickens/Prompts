---
applyTo: '**'
---

# Terminal command rules

A command is a script path followed by literal arguments and nothing else: no pipelines, no `;` chains, no inline `if`, no `$( )`, no quoted-expression arguments. Work that needs any of those is a script.

Scripts call Set-Location $PSScriptRoot themselves. Never prefix a command with `cd`.

Run a script as `& .\script.ps1` from the current folder, or `& C:\full\path\script.ps1` from anywhere else.

A command that needs more than one statement goes in `tmp\probe.ps1` at the repo root, run as `& .\tmp\probe.ps1`. Edit that file and rerun the same command rather than retyping a command line. A probe that outlives its task is deleted, or becomes a tool in TOOLS.md.

Never redirect or filter output: no `2>&1`, no `| head`, no `| tail`, no `>`, no `*>`, no Out-File.

No head, tail, grep, Select-String, Select-Object, Get-Content, Find-String, or piping into a filter.

Never echo an exit code. A non-zero exit does not throw; the terminal reports it.

No sorting, formatting, grouping, measuring, filtering or reshaping output for display. Ask for the right thing the first time.

Never enumerate a whole tree, drive or repository root. Every listing is scoped to a named path and a filter, and the expected number of results is known before it runs.

To find something, search for it: name the file, or filter for the pattern.

Query one file when one file is the question.

No manual path arithmetic: no Substring, Replace or -split on FullName.

Use `$null = ...`, never `| Out-Null`.

Prefer a PowerShell cmdlet or module over an external tool. Install the module rather than shelling out.

No wildcard or partial match on a resource; check the expected count is 0 or 1 and fail.

Do not guard a required cmdlet with Get-Command. Let it fail. No -ErrorAction SilentlyContinue on a write.

If a cli tool takes --output json, use it and parse in memory.

Repeating one command with different arguments means a parameterised script under `psmodules`.

Reuse a terminal rather than opening one per command.

WSL scripts run through patterns\examples\wsl\invoke-wsl.ps1 only. Rules in patterns\wsl.md.
