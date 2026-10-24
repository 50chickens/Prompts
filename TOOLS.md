# Tools

Read this before writing a script, a tool, a module or an instruction file. Invoke what exists. Where nothing fits and the need will recur, add it to `psmodules` and add its row here in the same change, so the next agent finds it without rediscovering the problem.
Attempt to create something generic so that it could used for a number of like scenarios -eg find file/find folder but do not create complex list of parameters, configuration choices or input values. Consider nesting if that is useful. 

## Entry points

Every tool is invoked as a path to a launcher plus literal arguments, never as `Import-Module` followed by a call.

| Path | Use for |
| --- | --- |
| `patterns\examples\wsl\invoke-wsl.ps1` | running a PowerShell 7 script inside WSL; owns the distribution start, mount repair and argument forwarding |
| `psmodules\bin\` | empty; every new tool gets its launcher here |

## Modules

`psmodules` exists and holds nothing yet. A tool has two halves. The implementation lives in `psmodules\<module>\` as a manifest, a psm1, `public\`, `private\` and `tests\` holding Pester tests. The launcher lives at `psmodules\bin\<verb-noun>.ps1`, imports the module through `$PSScriptRoot` and calls one function. The launcher is what an agent runs, so no command line ever carries an import.

## Wanted, do not rebuild

These are known gaps with a rule each of them removes. A probe that matches a row below is not a probe; it is this tool.

| Tool | Replaces |
| --- | --- |
| get-git-read | `git --no-pager diff`, `log`, `show`, with the pager trap |
| test-ps-syntax | the `Parser::ParseFile` one-liner |
| get-scoped-listing | a scoped listing plus the expected-count check |
| read-config-json | `Get-Content -Raw` followed by `ConvertFrom-Json` |
| invoke-repo-script | running a script and reporting its exit status without echoing it |

## Rules in force

| File | Applies to | Covers |
| --- | --- | --- |
| `.github\copilot-instructions.md` | every request | index and the reuse rule |
| `.github\instructions\terminal.instructions.md` | every request | command form, banned filters, git reads, WSL invocation |
| `.github\instructions\powershell.instructions.md` | `**/*.ps1` | iteration form |

## Knowledge

| Path | Holds |
| --- | --- |
| `orchestration\` | manager role: briefs, lanes, queue, gates, models, reporting, verification, measurement, handover, documents, failures, contention, capabilities |
| `patterns\aws\` | `pre-assigned-eni.md`, `github.md` |
| `patterns\examples\` | worked examples, including the WSL harness under `wsl\` |
| `patterns\public_patterns\` | empty |
| `skills\csharp\` | C# skill assets: `readme.md`, `bad.cs`, an example solution |
| `skills\powershell\` | empty |
| `component_prompts\` | `Vault.md` and `solutions\`: docker, vs_buildtools_docker, copilot-session-cleanup |

## Insights

A fact about a technology belongs in `patterns\<technology>\`. A fact about this repository's process belongs in this file. Neither belongs in `tmp\`, and nothing stays in `tmp\` after the task that wrote it ends.
