# information for agents.

##  General instructions.
Do not write comments. Don't write documentation files, or any *.md unless it is asked for. Do not write summaries at the end of a task unless i ask you.
Keep summaries after a task is finished to 50 words or less. 
Mention if you have referenced this doc in the summary but keep it very brief. 
Dont add fallbacks, work arounds, graceful handling, verbose error handling. Don't create overly cautious code. it is ok if things fail. Unless i tell you, the code should be as lightweight as possible and as free of code that is unrelated to the task at hand. 
If the user says to do something, or stop doing something add that correction to the agents.md file. 
Do not use decorations, bullet points, indenting in code or documentation. Only add important detail that is not specific to this repo in this file. This file is to improve the quality of any code - not just that which is specific to this repo.
don't create files containing either executable code, or scripts at run time. 
eg don't create create a .cs file that generates powershell or bash scripts which will either be executed invoke-command or written to disk and then executed. these should go into some folders - eg assets, or static and then run directly when required. 