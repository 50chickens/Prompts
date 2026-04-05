When building a docker container containing assets of compiled binaries we should only add the dependencies for the container if they are not already installed. 
Always create linux alpine containers unless there are some specific requirements (eg asio under windows). Try and use the alpine linux dotnet core container if you can.

when there are dependencies (eg powershell) use layers. 
use docker-compose so that container creation/cleanup is simpler, but include a step invoke-deploy.ps1 that checks for/removes any containers that contain our application image. don't remove any layers that we created for our dependencies. they will be auto recreated if needed. 

For credentials or other environment variables that the container needs:
Create a powershell script in the assets folder that is a powershell 7 script which uses a file that is volume mounted into the container at startup. this file contains a KEY=VALUE format and sets the environment variable during the container startup. 
The file that holds the values it should use a KEY=VALUE syntax. 
This can be used to pass credentials (eg openapi api key) into the container via script which is run during container startup prior to starting the application.  
This should be a single file which is mounted into the container as a single volume mount. don't create multiple volume mounts for this environment values file. 
for environment variable values - print the value (the first & last 5% of the original text length up to a maximum of 5 characters for each end of the string). This is so we can validate the values but not print the entire value out. 

dockerfile contstraints.
we use a mix of COPY directives and volume mounts to get the container started. 

Use volume mounts to where data lives.
use COPY directives to add compiled/static content by build-test.ps1. Be sure that the invoke-deployment only cleans up the docker images at the start of the deployment and does not destroy/remove any data from the local host.
applications that are compiled should go into /opt - eg /opt/project1.

container startup:

The CMD directive should always be a single .ps1 file - eg /startup.ps1. 
if there are multiple services required (eg two apis, or a http server -> api) then use supervisord to start them indepedently. startup.ps1 in this case should start supervisord.
Any configuration files for the services (eg haproxy/https/supervisord) should have this preference:
they should go into the assets/etc folder. the dockerfile should use a single COPY command to copy them to the location they need to go. eg COPY ./assets/etc /etc.
Keep all of the configuration files from any of the additional sofware (eg postfix/httpd/supervisord) as close to the original as possible.


docker file/folder structure - relative to DOCKER_ROOT. see folder-structure.md for what the tokens mean. eg REPO_ROOT.

PS C:\git\internal\REPO_ROOT\src\Project1\scripts\docker> tree /f
Folder PATH listing
Volume serial number is 06D9-9FC8
C:.
│   docker-compose.yml
│   Dockerfile
│   readme.md
│   
├───context
│   │   readme.md
│   │   
│   ├───build
│   │       install-powershell.sh
│   │       
│   ├───etc
│   │       supervisord.conf
│   │       
│   └───opt
│           readme.md
│           startup.ps1
│
└───volume_mounts
    │   env.conf.example
    │   
    └───etc
            env.conf