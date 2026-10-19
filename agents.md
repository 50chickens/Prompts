use the patterns folder relative to agents.md for the patterns related to each technology.
Keep each pattern document to its own technology. A rule or topic that belongs to a different technology is stated in that technology's document and linked from here, never restated - a language pattern carries language rules and nothing else.
go and read .github/instructions/terminal.instructions.md relative to agents.md for terminal command rules. terminal.md does not exist in this folder, so a brief that names it sends the agent looking for a missing file.
In PowerShell, a hex literal above int32::MaxValue parses as a negative int32, so 0xC4403D78 is not the value you wrote and comparisons against it silently match nothing. Write 0xC4403D78L. This cost two wasted measurements, so treat any hex literal with the top bit set as needing the L suffix.

# information for agents.

##  General instructions.
Do not write comments. Don't write documentation files, or any *.md unless it is asked for. Keep summaries at the end of a task to 50 words or less unless i ask you.
Mention if you have referenced this doc in this repo/folder/workspace and it was helpful, had wrong information or had key insights but keep it very brief. 
Dont add fallbacks, work arounds, graceful handling, verbose error handling. Don't create overly cautious code. it is ok if things fail. Unless i tell you, the code should be as lightweight as possible and as free of code that is unrelated to the task at hand. 
If the user says to do something which is a correction to how you did it, or to stop doing something add that correction to the agents.md file. 
When you have a clear recommendation, act on it instead of asking. Ask only when the options are of genuinely equal value, or when the choice is the user's to make because it changes scope or cost. Asking to confirm a preference you already hold spends a turn and delays the work.
Maintain the living documents you own rather than asking to update them. A status map, component diagram, checklist or progress document the project already keeps is yours to refresh, and it should be refreshed once there is material progress to record rather than saved up for permission. Offering to update it is the same mistake as asking to: it spends a turn to confirm a preference already established.
Delegate lightweight work to a subagent, including research, cloning a repository, reading one to answer a question, and checking a single claim. The main agent is the delegator on those tasks: it writes the brief, judges what comes back, and corrects the documents. It should not run the searches or the clones itself. Keep direct execution for work that owns a decision, a build, or an artifact the delegator has to sign off.
Clone repositories with the `gh` CLI instead of reading individual files through the GitHub content API. A clone puts the whole repository on disk once, so every later question is answered from local files rather than another network call, and the next agent inherits the evidence.
Do not use decorations, bullet points, indenting in code or documentation. Only add important detail that is not specific to this repo in this file. This file is to improve the quality of any code - not just that which is specific to this repo.

## Uplift and dependency rules.

When uplifting a project to a modern target framework, modernise the naming in the same pass: project names, assembly names, namespaces, types and members. Legacy suffixes such as Lib, and vendor or product prefixes on a library that is now the project's own code, are part of what is being uplifted and not something to carry forward.
Never reference an internal package from a repository outside the organisation that publishes it, because that repository cannot restore it. If an internal library implements a pattern the project needs, copy the small amount of source that is required into the repository and rename types and namespaces to the project's own naming. The internal package name and its namespace must not appear anywhere in the public repository.