# Tool Calling for open-webui for ELR.

We need to create a number of tools. these are used by the dataextraction skill and need to be added to the open-webui site in the invoke-deployment.ps1 phase.

the csproj file called ELRChatBot.Library.OpenWebUi.Tooling contains a number of netcore librarys that we need to use in the data-extraction skill. 

this is the workflow. 
user uses the prompt to start the workflow. 
during the assignment scaffolding there might be existing data (.doc/.pdf) that we can extract text out of. 
we need to use a skill (dataextraction) to work out how to do this. this skill needs a tool.
we need to build some dotnet based tools that can extract this text. this is one of our tools. 
we need to use python.net so that tools we call from openweb-ui using python can leverage code that we have written in c#. 

phases of the ELR workflow and what tools/skills we need to build for each phase. 

assignment_scaffold. 
identify_candidate_constraints. a c# library that can extract text from a .pdf or .doc/.docx file. 
Research_companies. a c# library that we can use to connect to chatgpt so we can use it to be our research partner. build a ELRChatBot.Library.ChatGPT which we can refactor from the ELRChatbot.Api. do not call the ELRChatbot.Api here. 
Filter_research
Prepare_linkedin_search. 
Linkedin_search
External_searches

