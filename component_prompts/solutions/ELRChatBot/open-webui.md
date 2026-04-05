Read the documents in C:\git\internal\LinkedIn\documentation\prompts\. the goal behind this open-webui is to streamline/automate the assignment from extracting & collating the information from the client, the task is getting chatgpt to act as a research assistant in compiling a list of companies, and then using that data to do a LinkedIn search. 

what changes to the open-webui can we make so that the open-webui is more tailored/specific to this task? can i create some initial prompts for the user that what im helping them with. is there some equivalent of the ELRNewAssignment.prompt file in open-webui?

what suggestion can you make about making open-webui as a single point of entry for this entire workflow. remember - the user is not technical and is not expected to enter commands, run scripts or binaries etc. 

also - go and re-read the C:\git\internal\LinkedIn\documentation\plans folder. This has a description of an old idea where we were going to develop a number of c# & powershell scripts that that be executed as part of a prompt system. Instead of that - can we integrate those into open-webui so that could be executed as integrations or plugins. if it's possible is there any plugin/extension system that we can use or extend to be able to run c# directly to help with the users tasks. 

also - i want to start working on the remaining sections of the plan.md - but instead of extending the pipeline i want to build out this functionality into the ELRChatbot -> open-webui pipeline. 

functional requirements for open-webui.

Add a volume mount to the open-webui service in `docker/docker-compose.yml` so the open-webui SQLite database survives container restarts.

- Map the container path `/app/backend/data` to `C:\git\internal\LinkedIn\data\docker\open-webui` on the host.
- Create the host folder if it does not exist before the container starts — add this to `Invoke-PreflightCheck` in `invoke-deployment.ps1`.
- Verify: restart the container after creating a saved prompt in open-webui and confirm the prompt survives the restart.

The open-webui SQLite database is stored on the host in the DATA_ROOT folder. All saved prompts, model settings, and conversation history survive container restarts. The recruiter's work is never lost because the container was restarted or updated.
Because the database is persistent, every research conversation is saved. A recruiter can return to a previous assignment conversation and continue where they left off.

---

## Planned Customisations

The following changes are to be made to the open-webui instance to tailor it for the ELR workflow. All are configuration or admin-panel changes — no code changes to open-webui itself.

**Volume mount — database persistence**
Mount `/app/backend/data` in the open-webui container to `C:\git\internal\LinkedIn\data\docker\open-webui` on the host. The host folder is created by `Invoke-PreflightCheck` before the container starts if it does not already exist.

**Model filtering**
In Admin Panel → Models, hide or disable any models that are not suitable for research and reasoning (image generation, audio, code-only models). Only models that support function calling and are appropriate for company research are shown to the recruiter.

**ELRChatBot model system prompt**
In Admin Panel → Models, add a system prompt to the ELRChatBot model entry. It tells the LLM it is a recruitment research assistant for ELR, describes the workflow phases, and sets expectations for output format (tiered company lists, LinkedIn Boolean strings, industry codes).

**Welcome / landing message**
Configure the default chat placeholder text to orient the recruiter on first use — listing the available slash commands and describing the workflow in plain language.

**Saved prompts (slash commands)**
In Admin Panel → Prompts, create one saved prompt per workflow phase. Content is taken from the corresponding `.github/prompts/` file. The slash commands are:
- `/new-assignment` — start a new client assignment
- `/company-research` — run company research for an existing assignment
- `/linkedin-search` — filter research and generate LinkedIn search strings

**Knowledge / RAG collection**
Upload the standing context document (explaining LinkedIn Recruiter, tier structure, industry codes, Boolean string format) as a Workspace knowledge collection. It is referenced automatically in research conversations so the recruiter does not need to provide it each time.

**Default conversation title**
Configure open-webui to auto-title conversations from the first user message so saved conversations are identifiable by assignment name in the history sidebar.

open-webui lets admins create saved prompts that appear as slash commands in the chat. Each of the workflow phases gets its own slash command. When a recruiter types `/new-assignment` the correct instructions are injected automatically and the conversation begins in the right context. No copy-pasting, no knowing what to type. The prompt content is taken directly from the `.github/prompts/` files.

In the Admin Panel the ELRChatBot model can be given a system prompt that is silently prepended to every conversation. This sets the scene — ChatGPT knows it is acting as a recruitment research assistant for ELR, it knows the workflow phases, and it knows what output formats are expected (tiered company lists, LinkedIn Boolean strings, industry codes). The recruiter never sees or manages this — it is just always there.

The default chat landing message is configured to orient the recruiter immediately. It lists the available slash commands and describes what the system can do in plain language. First-time users understand the tool without any training document.
Only models appropriate for research and reasoning tasks are exposed. Models that are optimised for image, audio, or code generation are hidden. The recruiter only sees models relevant to their work.


Customizations:

