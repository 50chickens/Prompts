# File content recommendations

Read this before adding a rule, a pattern document, a skill or an instruction file. It says which file owns which content, so a rule is written once and is found where the agent needs it.

## Recognised carriers

Three locations load without an agent choosing to open them: `agents.md` and `.github\copilot-instructions.md`, on every request; `.github\instructions\*.instructions.md`, when `applyTo` matches a path in context; and the VS Code user prompts folder, for cross-workspace scope. Every other file is inert until an always-on file names it, which costs a tool call and depends on the agent complying.

An action is not a path. `applyTo` is matched against files in context, so no instruction file reaches a command line typed into the terminal, a one-off measurement, or a decision made between tool calls. Anything that must hold for those goes in an always-on file, or in a hook.

## Where each kind of content goes

| Content | Home | Arrives when |
| --- | --- | --- |
| Invariants that must never be missed: git writes, no comments, no fallbacks, jail, deletions | C:\git\internal\Prompts\agents.md | every request |
| Router: which files load, and the reuse rule | C:\git\internal\Prompts\.github\copilot-instructions.md | every request |
| Command shape, banned filters, output volume, probe rule | C:\git\internal\Prompts\.github\instructions\terminal.instructions.md | every request, applyTo: '**' |
| PowerShell language rules, iteration form, script shape | C:\git\internal\Prompts\.github\instructions\powershell.instructions.md | a .ps1 is written, read or open, applyTo: '**/*.ps1' |
| PowerShell detail: Get-Configuration, banned patterns, logging, retries, hex literals | C:\git\internal\Prompts\patterns\powershell.md | named by the .ps1 rules |
| C# language rules, package policy, project file settings, modernisation | C:\git\internal\Prompts\patterns\csharp.md | named by a brief or by the C# skill |
| ci and release script shape, workflow files, release layout | C:\git\internal\Prompts\patterns\ci-scripts.md | a ci.ps1 or a workflow file is written |
| WSL invocation and mount rules | C:\git\internal\Prompts\patterns\wsl.md | a WSL script is run |
| Evidence rules for vendor documents, devices and absence claims | C:\git\internal\Prompts\patterns\investigation.md | an investigation or a device claim is made |
| Worked code: build ci, WSL harness | C:\git\internal\Prompts\patterns\examples\ | a pattern document names it |
| Tool inventory and wanted tools | C:\git\internal\Prompts\TOOLS.md | named by agents.md |
| Manager process: briefs, lanes, queue, gate, reporting, handover | C:\git\internal\Prompts\orchestration\README.md | a brief or the orchestrator names it |
| Executable workflow with assets | C:\git\internal\Prompts\skills\csharp\SKILL.md | the model chooses from its description |
| One-off recipe for a finished task | C:\git\internal\Prompts\component_prompts\ | a human opens it |

## Placement test

Would the rule still be obeyed if the agent read it one step earlier? If yes, it can live behind a link. If it must be held while the first line is typed, it goes inline in the file that is already loaded for that action.

## Keeping the volume down

A rule lives in one file and is linked from everywhere else. Restatement is how two files come to disagree.

Every line of an always-on file is paid on every request, including requests it has nothing to do with. `agents.md` and `terminal.instructions.md` are budgets, not archives.

Prose explains; a table or a code sample transfers. Where a paragraph says what to do, keep the sentence and delete the reasoning, unless the reasoning is the only thing that stops a mistake that has already happened.

A rule that must be held rather than advised belongs in a gate or a hook, not in a longer document.
