We do not need a test plan for the original requirement (validing access to a RDS instance where the ACL comes from a trusted domain). 

except for that: go and analyse the things in the todo list. 
Once you have figured out the solution/mechanism/control/plan. If there are additional constrains, or specific methods that we need to use to implement it add it to prompt.md at the bottom. 
then if we need to include it in the plan.md go and do that. 

Afterwards re-review the todo list. Are the requirements documented in the prompt.md and do we have a plan for it's implementation covered in in plan.md. if so - remove them from todo.md

then go and re-analyze the plan/prompt - Are there any additional steps that we should include, or things that need either investigating, solutioning or planning ahead of time. If so add them to the todo list. 

don't include any security/performance related items unless it would be required to enable functionality. only think about functional requirements, not non-functional requirements. 

definitions:
prompt.md. This is a document we wrote that contains -
* solutions to problems that we have identified.
* constraints. these are things we should should or should not do, things that we are required to either do not do. these are mandatory and superseed the plan.md. 
* previous learnings or investigations on the way we need to do things that save time/rework in the future. 

what to include in prompt.md.

We need to understand if there are specific processes, mechanisms, strategies on how we need to implement the goal. eg how do we join a member server to our AD managed AWS instance. 
we need to know if there are constraints that apply to that (eg we need a username & password and we need a way to access those credentials). 
We don't include script level implementation details in prompt.md. eg call the aws secret /someSecretContainingSomeCredentials. These are implementation details and should not go in here. 
Only append to prompt.md. this is so that we can evaluate whether things are the right approach and if they are should be the way we implement things. 

what to include in plan.md.
This is the physical orchestration script that will bring our goal to life. 
it implements a sequence of events (eg deploying a CFT, domain joining an ec2 server to the domain). 
We should document too many implementation details here. these will be put into configuration files and it is important that the configuration not the documentation be the authoritive source here.

plan.md.
This is how our orchestration script implements the prompt.md. it has details like:
* phases of the orchestration script. 
* script names/locations. 
* a sequence of events as we understand it needs to be done according to prompt.md.

Todo.md.

These are things that are either still unknown & need a solution/investigation. 

The workflow is:
review prompt.md and plan.md.
Are the items in todo already documented in prompt.md? If so - does the plan.md implement the solution/constraints.  If so, remove it from the todo.
Then, re-review the prompt.md. Are there still things that need to be understood before we are confident in our plan.md.  If so, add them to todo. 