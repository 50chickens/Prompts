Open web ui defaults.

* requirements.

A non-technical recruiter opens the ELRChatBot web UI and sees a ready-to-use workspace — no configuration, no slash-command memorisation required.  
The entry point for each workflow phase is a visible, labelled, clickable card on the **Prompts** page (`/workspace/prompts`).  
The recruiter clicks a card, the prompt fills the chat, they press send.

* implementation.

When the open-webui is initialized invoke-deployment.ps1 we need to do the following idempotent operations.
All open-webui configuration is applied by the deployment script (ivoke-deployment.ps1) after the container is healthy, using the open-webui REST API authenticated as the admin user. Every operation is idempotent — check whether a resource already exists before writing.

Create a list of open-webui groups and users. see users.md for requirements.
Add/enable the open-terminal feature. 
Import a number of prompts. share them with the ELR group.  Load prompts from the host assets folder and register them in open-webui via the API. Share each prompt with the ELR group. See the assets folder for the list of prompts and their source files.
Import a number of skills. share them with the ELR group.  Load skills from the host assets folder and register them in open-webui via the API. Share each skill with the ELR group. See the assets folder for the list of skills and their source files.
add the python.net component to be able to call .net code directly from python scripts. The source code for python.net is from https://github.com/pythonnet/pythonnet.git and is cloned under C:\git\external\pythonnet
Create a number of open-webui actions. see open-webui-actions.md for details. 
Create a number of tools.

**Model filtering**
In Admin Panel → Models, hide or disable any models that are not suitable for research and reasoning (image generation, audio, code-only models). Only models that support function calling and are appropriate for company research are shown to the recruiter. Hide models that are not suitable for research and reasoning tasks. Only expose models relevant to the recruiter workflow.

**Welcome / landing message**
Configure the default chat placeholder text to orient the recruiter on first use — pointing out the customizations and giving a short overview of the workflow in plain language.

**Default conversation title**
Configure open-webui to auto-title conversations from the first user message so saved conversations are identifiable by assignment name in the history sidebar.

Open-webui lets admins create saved prompts that appear as slash commands in the chat. The prompt content is taken directly from the `DATA_ROOT/prompts/` folder. for each of the .prompt.md files they need to be imported via the api at container image creation time.

The default chat landing message is configured to orient the recruiter immediately. It lists the available slash commands and describes what the system can do in plain language. First-time users understand the tool without any training document.
Only models appropriate for research and reasoning tasks are exposed. Models that are optimised for image, audio, or code generation are hidden. The recruiter only sees models relevant to their work.