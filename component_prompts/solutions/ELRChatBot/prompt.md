we need to create an api to wrap the ELR workflow. 
for anywhere there is a token - eg REPO_ROOT check folder-structure.md for where this would resolve to.
go and read C:\git\internal\LinkedIn\documentation\prompts\prompt.md for the workflow. 

i need the following:

a open-webui website for allowing the user to interactive with an api that runs locally which implements the openai specification. you do not need to build a new user interface. the open-webui under C:\git\external\open-webui is already created to do this - you only need to create a running instance. i want thit so 

a new openai compatible api. it needs to go into C:\git\internal\LinkedIn\src\ELRChatBot. this is a new c# api which:
Is able to guide the user through the tasks in C:\git\internal\LinkedIn\.github\prompts\ELRNewAssignment.prompt.md

constraints.
A recruiter opens a browser, goes to a locally hosted chat page, and works through the entire ELR recruitment workflow in a single conversation. They never run a command, manage a file, or leave the chat interface.
use windows only. 
reimplement any c# or .ps1 code in the api. Don't call any .exe or .ps1 files directly. 
add swagger-ui to the api. 
use the patterns from the patterns folder. 
don't use https in the api. we will add it later. 
Add volume mounts to the open-webui so that if/when i restart the container the open-webui database will be reused in the container. the volume mount path should be DATA_ROOT\docker (see )
by default we should limit the models exposed in open-webui to shoe that are applicable for the task of doing company research as outlined in the 
The docker file that creates the open-webui container needs to be extended to add the installation of powershell 7 and the dotnet core runtime/sdk. 

tasks:

We need to include supervisord as want to run both the open-webui and elrchatbot services. Use the assets folder to create a supervisord.conf which orchestrates both the open-webui and elrchatbot services. 
We need to update the docker-compose file REPO_ROOT\docker\docker-compose.yml for only the one container not seperate open-webui & elrchatbot ones. 
We need to include the compiled binaries for the ELRChatbot so that supervisord can start/see them. there needs to be an additional COPY command in the dockerfile - 
/opt/ELRChatbot -> bin/debug folder where the compiled binary exists.

volume mounts:
ephemeral/persistant data should be exposed via volume mount into the container and this is what the ELRCatbot sees. 
/opt/ELRChatbotData -> DATA_ROOT (see folder-structure.md for where this exists on the host). 

workflow from recruiters:

The recruiter tells the system the client name and role. They can give links to local folders on the local machine to materials — briefs, meeting transcripts, notes. The system creates the assignment, extracts relevant information from the materials, and shows the recruiter a checklist of what was captured and what still needs to be filled in.

Phase planning

* Phase basic.

We do not need to integrate any of the other workflow just yet. 
a basic openai compatible api that can call the chatgpt with a "say hello world" request. chatgpt would reply with "hello world". 
See the orchestration script pattern. we need a basic pipeline setup which uses this pattern to build the api and we need to be able to call the api endpoint to get the "hello world" response from chatgpt. 

* phase combine-open-webui-ELRChatbot.

we need to combine the two docker containers into a single container. the reason why is because we want to use tool-calling in open-webui but this is inefficient/fragile if there are two seperate containers. since open-webui lives in an easily extendable container (debian) we should add dotnet/powershell/supervisord so that can we can run both the open-web and ELRChatbot and take full advantage of the tool-calling to execute subprocess commands that call dotnet to call custom worflows that exist in the local dotnet solution (and therefore have good things like unit tests etc).

* phase extend-open-webui 

//this is where we turn the existing open-webui -> api -> chatgpt connectivity into something that is tailored for the recruiters workflow. 

**Tools / Function Calling (via the ELRChatBot API)**
open-webui supports the OpenAI tool-calling protocol. The ELRChatBot API exposes the workflow phases as callable tools. When the recruiter speaks naturally in the chat ("run research for Acme Corp"), the LLM calls the appropriate tool in the API — creating folders, reading files, calling ChatGPT, saving results — without the recruiter knowing any of that is happening.

