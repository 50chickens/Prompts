there are several repos under ~/git/internal. 
the word internal represents github repos that belong to my github organization and are private. 
alsionyx is the end application we're building.
setup is specific to generic audio code that is related to alsionyx.
ipscm is for general crosscutting concerns - eg logging, configuration and dependency injection.
each has a src & ci folder. src contains source code. ci contains files that give it a build, test and deployment pipeline. 
each src folder can contain multiple dotnet core solutions each with multiple projects. 


as we have nuget package dependencies between the 3 projects there is a main orchestration folder setup under ~/git/internal/orchestration.
it's purpose is to run each of the cicd pipelines for each of the repos in order. 
the workflow should be:
run ~/git/internal/orchestration/gh.ps1.
it runs ~/home/pistomp~/git/internal/orchestration/build-test.ps1. this script loads the json files under the configs folder and executes gh.ps1 for each of the repos. 
this allows us to recreate all of the nuget packages in order of dependency. 
