---
applyTo: '**'
---

# Terminal command rules

Applies to every terminal command run by the agent.

- Never prefix a command with `cd`. Scripts call `Set-Location $PSScriptRoot` themselves; run commands in place.
- Each command runs in a fresh process, so nothing set in one call reaches the next: not `Set-Location`, not an environment variable, not a PATH change, not an activated environment, not a shell alias. A step that depends on setup - a tool's environment script, a toolchain selector, a `vcvars64.bat` - has to run in the same process as the command that needs it, which for a batch file means one `cmd.exe` invocation, not two calls.
- When running a powershell command just use exactly the & path_to_script.ps1. For scripts that are in the current folder use & .\script.ps1. for scripts that are above the current folder use the full path - eg & c:\somefolder\somescript.ps1.
- Never redirect or filter output: no `2>&1`, no `| head`, no `| tail`, no `>`, no `*>`, no `Out-File`.
- Banned in commands: head, tail, grep, Select-String, Select-Object, Get-Content, find-content, and piping output into filters.
- Never echo exit codes (`$LASTEXITCODE`, `$?`, `EXIT=...`).
- Assume minimal verbosity; keep output small by running the right command, not by slicing it.
- A long-running command that outlives the initial wait keeps running; read the output of that run rather than starting it again, because a second copy doubles the cost and races the first one's writes.
- This shell does not support the PowerShell 7-only operators `&&`, `||`, `??`, `??=`, `?.` or `?[]`. Use `;` to chain, and gate a dependent step with `if ($?) { ... }`. There is no heredoc either; build multi-line content with a here-string rather than a shell heredoc.
- Disable the pager on any command that has one (`git --no-pager`, or a pager's own non-interactive flag). A paginated command looks like a hang and costs a call to diagnose.
- Never enumerate a whole tree, drive or repository root. Every listing is scoped to a named path with a filter, and you know the expected number of results before you run it. If the number of results depends on how many files happen to exist, the command is wrong.
- Do not use a recursive listing to find something. Search for it instead: name the file if you can, or filter for the pattern. Listing everything and reading it is not a search, and it costs a call for every file you did not need.
- Output volume must be bounded by the question, not by the size of the filesystem. A command whose output grows as the folder grows will eventually be unreadable, and it will be unreadable sooner than you expect.
- Ask for the specific thing you need rather than the whole and then narrowing it. To learn one file's size or timestamp, query that file.
- Do not pipe command output into cmdlets whose purpose is to reshape, reorder or summarise it for display: `Sort-Object`, `Format-Table`, `Format-List`, `Group-Object`, `Measure-Object`, `Where-Object`, `Select-Object`. Produce the right output the first time rather than reformatting it afterwards.
- Do not build display strings by concatenating properties in a `ForEach-Object` block. That yields text where objects belong, so nothing downstream can be sorted or filtered correctly, and the output cannot be reused.
- No manual path arithmetic: no `Substring`, `Replace` or `-split` on `FullName` to shorten or compare a path. It is brittle, it breaks the moment a path depth changes, and it is unnecessary because the provider already exposes the name and the relative form.
- Address a path you can already name with `-LiteralPath`, and select a set with `-Filter` at the provider. Both are cheaper and safer than building a wildcard or a computed string to express something you already know.
- When a tool hands back a file path because its own output was too large, search that file and read a bounded range of it. Dumping the whole file re-creates the problem the tool just solved, and the dump will be offloaded again.
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

# WSL scripts

Scripts that run inside WSL are executed only through the harness, never by calling wsl.exe directly:

    & C:\git\internal\Prompts\patterns\examples\wsl\invoke-wsl.ps1 -Script /mnt/c/git/some/folder/script.ps1

- The harness takes the script path and, when the distribution matters, `-Distro <name>`. It is not optional in practice: the default distribution can be too old for the tooling, so a step that needs the supported one passes `-Distro`. There are no *script* arguments and no root switch: a script that needs to vary its behaviour loads that from its own config file through Get-Configuration, and every script run through the harness runs as root because these scripts configure the machine.
- If a task really needs a choice passed in, add the step to a ci.ps1 pipeline inside WSL and select it from that pipeline's config, rather than adding a parameter to the harness.
- A WSL script is written to the same standard as any other PowerShell script: the powershell patterns, the orchestration-script pattern with its ci.ps1 entry hook, and a Get-Configuration section. A script that looks like it needs command line arguments usually wants to be either more generic or split into a separate script.
- A script the harness will run needs **two** things before anything else, because the harness execs it directly as `wsl -u root -e <path>`. Its first line must be `#!/usr/bin/env pwsh`, and the file must use LF endings. The file tools write CRLF, so a script authored with them fails with `env: $'pwsh\r': No such file or directory`, and a script with no shebang fails with `Exec format error`. Neither message mentions line endings or shebangs, so fix both before diagnosing the script body. Convert endings with `$t=[System.IO.File]::ReadAllText($p); $t=$t.Replace("`r`n","`n"); [System.IO.File]::WriteAllText($p,$t)`.
- A script that exits 127 with `env: ... No such file or directory` has a CRLF shebang, not a missing interpreter, and a script that exits 1 with `Exec format error` has no shebang at all. Those are the two failure modes and they are distinguishable, so log which one you hit.
- The harness checks that /mnt is owned by the distribution's default user, and restarts the distribution when it is not. WSL normally gives /mnt that uid, but a distribution can be left with a root-owned /mnt. On a root-owned /mnt every chmod and utime fails with EPERM for everyone but root, so git clone fails with "could not set 'core.filemode' to 'false'", npm fails, and MSBuild fails with "The last access/last write time on file ... cannot be set". Those messages point at the wrong thing; check the mount owner first. If the harness cannot repair it, run `wsl --shutdown`.
- Do not pass -e, -u or a WSL_UTF8 assignment by hand, and do not build a command line with an inline `env`, a shell `cd` or a chained second wsl.exe. The harness owns all of that.
- Only PowerShell 7 scripts are run inside WSL. The one exception is the bootstrap that installs PowerShell, which cannot itself be PowerShell.
- Write every WSL file into the project's own folder on the Windows drive, /mnt/c/git/..., and never into the WSL user's home. The distribution is disposable and its home goes with it; only installed toolchains and regenerable build caches belong inside it.

# Know which side you are on

Establish the execution context before choosing a command form, because the two contexts take different command lines for the same work.

- **On the Windows host, with the shell running a command line that WSL will execute.** Every WSL command line is built by the harness above; you author a PowerShell script and the harness runs it inside the distribution. Use Windows paths for the file you author.
- **Inside WSL, because the default terminal is the distribution.** The host shell is bash, so quoting, `$variable` expansion and path separators are bash's, not PowerShell's, and a path like `/mnt/c/git/...` is the form that resolves. Do not assume a Windows path works here, and do not assume a bash command line works on the host.

Either way PowerShell is the implementation language, so the answer to "which shell am I in" changes how you invoke a script, never what the script is written in. When you are on the host, run PowerShell directly. When you are inside WSL, still write PowerShell, and reach it through the harness or an explicit `pwsh -NoProfile -File`. The one exception is the bootstrap that installs PowerShell into a fresh distribution, which cannot itself be PowerShell.

# Choose the right tool for the weight of the job

- Heavy lifting is PowerShell first, then a .NET package from NuGet if PowerShell is genuinely too slow or the algorithm belongs in a typed library. Only reach for C# when there is a real performance reason, and prefer a single `.cs` file run with `dotnet run file.cs`, which compiles and runs with no project and leaves no bin or obj behind in a source folder.
- Never use Python, Rust, Go or Ruby, and never install them to work around a PowerShell limitation. That applies to one-off measurements as much as to committed tooling, because a one-off measurement becomes the evidence a later task is built on. PowerShell is for orchestration and C# for calculation, and those two are the languages to write.
- The one exception is the primary language of a tool you are extending: coding against Tool1 means writing Technology1's own language, because the artifact is an extension hosted inside Tool1 and cannot be delivered in anything else. The exception is decided by the tool, not by the task, and it ends as soon as the work becomes arithmetic, file handling or orchestration. Do not branch to a third language because it is the natural one for the problem - a script in a fourth language on another operating system to do arithmetic is the case to refuse. The reason is not taste: PowerShell and C# arrive with the host, need no interpreter install, no virtual environment and no lockfile, and do not fail differently on another machine next week. An interpreter's version pinning and package-dependency chains are a distraction that spends budget on a problem the task does not have.
- Lightweight work is a subagent investigation, not a compilation. A question that a read answers ("which file says X", "does this repo mention Y", "what does this constant mean") needs a search and a citation, so delegate it and keep the compile for work that has to produce an artifact. Do not build a script to answer a question that a grep and a `view` already answer.

# Arithmetic and data rules that apply to both PowerShell and C#

Both languages are the same at this level, and the mistakes below bite in either. They are here rather than in a language pattern because they apply whichever one a command happens to use, and because several of them are silent: the value is wrong without anything failing.

- A shift count is masked to the width of the operand. `1 -shl 32` is `1`, and a 32-bit value in C# behaves the same way, so widen the operand to a 64-bit type before shifting by 32 or more. This is the usual cause of a packed value losing its high half while looking plausible.
- Division is the one place the two languages differ, and that difference is the hazard. PowerShell's `/` always yields a fractional result while C#'s `/` truncates when both operands are integers, so an expression is not portable without deciding which is wanted. Related: a value that is not an integer cannot be given an integer format specifier, which is why `:X` throws on a number that looks whole.
- An integer literal that does not fit its type does not fail; it wraps or parses as negative, so the constant you wrote and the value you compared against are different numbers and the comparison silently matches nothing. Give every literal an explicit width rather than relying on inference, and treat any hex literal with its top bit set as needing the `L` suffix.
- Parse and format with an invariant culture whenever a value crosses a boundary - between processes, between machines, or into a file. A culture-dependent separator turns a value that round-trips on one machine into a different number on another, and a format that is right for display is not necessarily right for data.
- Keep one exact type through a pipeline instead of converting along the way. A bit pattern that passes through a string, a floating-point value or an object of unknown numeric type can arrive correct-looking and wrong, and the failure surfaces far from the conversion that caused it.
- Prefer an explicit cast and mask where a value is produced, rather than an implicit narrowing where it is consumed. When a value has to fit a width, say so at the point it is made.

 
