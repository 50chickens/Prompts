# Tools

Invoke what exists. A tool has two halves: the implementation in `psmodules\<module>\`, and a launcher at `psmodules\bin\<verb-noun>.ps1` that imports the module through `$PSScriptRoot` and calls one function. Agents run launchers, so no command line carries an import.

| Path | Use for |
| --- | --- |
| `patterns\examples\wsl\invoke-wsl.ps1` | running a PowerShell 7 script inside WSL; owns the distribution start, mount repair and argument forwarding |
| `patterns\examples\build\ci\ci.ps1` | the build gate shape that a repository copies |
| `psmodules\bin\` | empty; every new tool gets its launcher here |

## Wanted, do not rebuild

A probe that matches a row below is not a probe, it is this tool.

| Tool | Replaces |
| --- | --- |
| get-git-read | `git --no-pager diff`, `log`, `show`, with the pager trap |
| test-ps-syntax | the `Parser::ParseFile` one-liner |
| get-scoped-listing | a scoped listing plus the expected-count check |
| read-config-json | `Get-Content -Raw` followed by `ConvertFrom-Json` |
| invoke-repo-script | running a script and reporting its exit status without echoing it |

## Knowledge

| Path | Holds |
| --- | --- |
| `file-content-recommendations.md` | which file owns which content |
| `orchestration\` | manager role: briefs, lanes, queue, gate, reporting, handover |
| `patterns\` | one document per technology, plus worked examples under `patterns\examples\` |
| `skills\` | on-demand workflows with assets |
| `component_prompts\` | one-off recipes for finished tasks |
