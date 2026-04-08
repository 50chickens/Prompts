
Docker patterns.

Dockerfile contstraints.

We use a mix of COPY directives and volume mounts to get the container started. 
Use COPY directives to add compiled/static content by build-test.ps1. look at the orchestration-scripts.md for how to do this.
Tag any images created by invoke-docker.ps1. we should be removing only images created with that tag as part of invoke-docker.ps1. 
The CMD directive should always be a single .ps1 file - eg /startup.ps1. 

Docker image building guidelines. 
Always create linux alpine containers unless there are some specific requirements (eg asio under windows). Try and use the alpine linux dotnet core container if you can.
When there are dependencies (eg powershell) use layers. 
docker-compose is only to start the container once it is built by docker build. 
Only use docker build to create the image.

Application dependencies.
When building a docker container containing assets of compiled binaries we should only add the dependencies for the container if they are not already installed. 

Application data storage.
For the folder structure for building/running docker containers look in the folder-structure.md document.
Use volume mounts to where data lives. see the orchestration-script.md and folder-structucture.md for how to do this.

Application configuration.

Any configuration files for application/packages that are installed from package sources (ie - not applications we add in) the configuration should follow these rules: 
they should go into the /etc folder under their normal location. 
The dockerfile should use a single COPY command to copy them to the location they need to go. see orchestration-script.md on where to put them to achieve this.
Keep all of the configuration files from any of the additional sofware (eg postfix/httpd/supervisord) as close to the original as possible.

Application configuration for environment variables. 
Create a powershell script in the assets folder that is a powershell 7 script which uses a file that is volume mounted into the container at startup. this file contains a KEY=VALUE format and sets the environment variable during the container startup. 

For credentials or other environment variables that the container needs:

The file that holds the values it should use a KEY=VALUE syntax. 
This can be used to pass credentials (eg openapi api key) into the container via script which is run during container startup prior to starting the application.  
This should be a single file whcih contains all environment variables. This can be mounted into the container as a single volume mount. Don't create multiple volume mounts for this environment values file. 
For environment variable values - print the value (the first & last 5% of the original text length up to a maximum of 5 characters for each end of the string). This is so we can validate the values but not print the entire value out. 

Application orchestration.

if there are multiple services required (eg two apis, or a http server -> api) then use supervisord to start them indepedently. startup.ps1 in this case should start supervisord.