there is pre-existing code already written for implementing some patterns. 

the ipscm repo contains a number of existing patterns for core/infrastructure/scaffolding the solution. reference these before building anything new. the ipscm repo is normally added to the workspace so you can find it. 

go and review the pre-existing patterns document for how to find existing logging patterns. 
they tell you how to find source that already implements logging. 

For console apps 
- ensure they use the AddConsoleApp extension method which wires up the DI container. program.cs should not be extended except to call the AddConsoleApp method. 
