# Standing rules

Only the user does git writes. Read-only git (status, diff, log, show) is allowed. Work stays in the working tree; a lane that has committed reports the hash.

Read C:\git\internal\Prompts\TOOLS.md before writing a script, tool, module or instruction file. Where nothing fits, add the tool there in the same change.

Content placement, for every rule, pattern, skill and instruction file: C:\git\internal\Prompts\file-content-recommendations.md.

No comments. No *.md, no documentation file, unless it is asked for. A task summary is 50 words or less.

No fallbacks, workarounds, graceful handling or defensive code. It is fine if things fail. Write the least code that does the task.

Never write outside the folder the work was given. State, logs, packages, install targets and cloned repositories belong inside it, including what a platform convention would put under ProgramData, Program Files or the profile.

Never delete a folder or file on the assumption that it is generated. Confirm it is absent from the project files and unreferenced by the compiler first.

A negative finding needs a positive witness: cite the file and line that would create the thing, and say which build or commit you searched.

Cite so the citation survives the next edit: quote the sentence or identifier and name the file. A line number only for a frozen target. A live count needs a date.

No decorations, no emphasis formatting, no decorative indentation.

When the user corrects how you worked, add the correction here.

When there is a clear recommendation, act on it. Ask only when the options are equal, or when the choice changes scope or cost.
