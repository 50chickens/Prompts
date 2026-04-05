---

## Delivery Phases — ELRChatBot End-to-End Workflow


All workflow logic that was previously described as PowerShell scripts or chatgpt.exe CLI calls must be re-implemented as C# inside the ELRChatBot API. Do not call any .exe or .ps1 files. All persistent data is written to the `data\` folder using the structure defined in `data-structure.md`.
Important: 
---

### Phase open-webui-persistence


---

### Phase open-webui-customization

Tailor the open-webui interface so it is immediately understandable to a non-technical recruiter with no prior knowledge of the system.
we need a way to customize the open-webui website so that when the container is started - all of the customization for a recruiter is already done for them. 

for example we want all of these things are part of invoke-deploy.ps1 - 
add assets from the C:\git\internal\LinkedIn\src\open-webui\assets. this can be:
prompts.
c#/powershell integrations.
Create callable actions from within the chat.

All of these things should be available to the user the first time the container is started. 




### Phase template-scaffold

Create the standing template files that the API copies when starting new assignments.

**Files to create once (manually or via a one-time setup script):**

`data\template\constraints-template.md` — the blank constraints form. Fields:
- Client/Company Name
- Role/Position Title
- Level of Seniority (e.g. Director, Manager, Individual Contributor)
- Key Skills (must-have)
- Key Skills (nice-to-have)
- Industries to target
- Companies to target (pre-supplied by client, if any)
- Companies off-limits
- Location / Geography
- Additional context or notes

`data\template\company-research\chatgpt\context.md` — the standing context block that is prepended to every ChatGPT research request. It explains: who ELR is, how LinkedIn Recruiter works (tier structure, Boolean strings, industry codes), and what output format is expected. This file is static — it does not change per assignment.

These templates are committed to source control. The API copies them; it never edits them.

---


