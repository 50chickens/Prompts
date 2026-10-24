WSL patterns.

Work in WSL is written in PowerShell 7 whichever side starts it. This file covers how it is started from a Windows orchestrator, and how it is reached when the distribution is the terminal.

## Which side you are on

| Context | How work reaches Linux |
|---------|------------------------|
| Windows host, PowerShell | the harness below runs the script in Ubuntu as the default user |
| Inside the distribution, bash | invoke PowerShell explicitly: `pwsh -NoProfile -File /mnt/c/git/some/folder/script.ps1` |

## Running a script

All WSL work goes through the harness. Never hand-build a wsl.exe command line.

    & C:\git\internal\Prompts\patterns\examples\wsl\invoke-wsl.ps1 -Script /mnt/c/git/project1_linux/scripts/host/install-toolchain.ps1

The harness resolves the newest registered Ubuntu, sets it as the default distribution when it is not already, and runs the script as that distribution's default user, with WSL_UTF8=1 so wsl.exe output arrives as text.

## Resolving the distribution

Never pass a literal name. Match the registered name against `^Ubuntu`, compare the captured version numerically, take the highest and throw when nothing matches; Get-LatestDistro in invoke-wsl.ps1 does exactly this. A literal fails as a missing distribution the moment the host registers another name, and the message does not mention versions.

The default distribution is inherited from whatever was last registered or set. On a machine with Docker Desktop it is docker-desktop, which has no /mnt/c mount, so a run against it fails with `stat: can't stat '/mnt/c': No such file or directory`. Resolving the name is what avoids that.

The tooling needs Ubuntu 24.04 or newer, so apply the version floor after the match rather than in the name. The execution flag is lowercase `-e`; this wsl.exe rejects `-E`.

## Repairing the mount

A root-owned /mnt breaks every chmod and utime for the non-root user. The symptoms name something else: git clone reports "could not set 'core.filemode' to 'false'", checkout and npm fail, MSBuild cannot set a file time. Check before believing them:

    wsl -d $distro -e stat -c %u /mnt/c

It must print 1000. Run Invoke-Repair-wsl.ps1 beside the harness; it restarts the distribution only when the uid is wrong, and wsl --shutdown is the fallback. Do not reinstall.

## Layout

Everything written for this work lives under the project folder on /mnt/c, because the distribution is disposable and its home directory goes with it; only the installed toolchain stays inside the distribution.

    project1_linux/repos
    project1_linux/languages
    project1_linux/home
    project1_linux/work

HOME points into that tree so build-tool caches land on the Windows drive, and a .NET build passes --artifacts-path into it so obj does not land in the source repository. Only PowerShell 7 and .NET are installed: do not install Python, Rust, Go or Ruby, and do not assume them.

## Writing the command line

Two traps, both avoided by the harness. PowerShell expands $variables inside double quotes before wsl.exe sees them, so `wsl -e bash -c "echo $HOME"` carries the Windows value. wsl.exe writes UTF-16, so output needs $env:WSL_UTF8=1 in the same command. Multi-step work belongs in a script run through the harness.

## Line endings

A script started through its shebang must be LF. With CRLF the kernel looks for an interpreter whose name ends in a carriage return and reports "No such file or directory", which reads as a missing interpreter. `file` separates the cases: "a /usr/bin/env pwsh script" is usable, "with CRLF line terminators" is not. core.autocrlf is true in this repository, so a fresh checkout writes CRLF and such a script needs a `*.ps1 -text` rule in .gitattributes to survive it. Only the shebang path cares; PowerShell and C# do not.
