# Start folder structure.md

There are 2 patterns of orchestration script but they both follow a similar path.

1. scripts that are used to execute tooling.
2. scripts that are designed to compile software. these follow the ci.ps1 -> build-test.ps1 as we need the build process to work locally during development and then also when we run the build process under a CI environment.

# Main folders.

PS_MODULES_ENABLED. C:\dev\PSModules\enabled. This is where aws powershell modules are eventually downloaded to. It is listed in the psmodulepath environment variable. note modules are not immediately downloaded to this folder - they are downloaded to an intermediate folder due to filelocking problems for aws.tools.common.

PROJECT_ROOT. C:\dev\scripts\all_scripts_go_here\projects\aws\projects. this is where all of the project scripts go regardless of type. each subfolder on this (except for includes) is a REPO_ROOT where REPO_ROOT is specific to a particular task.

DOCUMENTATION_FOLDER: REPO_ROOT/docs. Except for prompt.md this is where all of the docs go.

REPO_ROOT - this is the root of the source repository.

LOG_ROOT - this is REPO_ROOT/logs/SOLUTION_FOLDERS. there should be 1 log folder project per solution so that each solution would write to it's own folder. 
eg 

REPO_ROOT/logs \
    SOLUTION_FOLDER1\project1\time-stamped-log-file.txt.
    SOLUTION_FOLDER1\project2\time-stamped-log-file.txt.
    SOLUTION_FOLDER2\project1\time-stamped-log-file.txt.

CI_FOLDER - this is REPO_ROOT/ci. It is used for the main ci.ps1 and the build-test.ps1 scripts. it is intended for scripts & config that will not be committed into source and are used for local development.
DATA_ROOT - it's location is REPO_ROOT/data. this the root of where any data is stored. Folders/files here are to not be touched for any reason whatsoever. 
SRC_FOLDER - it's location is REPO_ROOT/src/. it is main source root folder. This is for dotnet solutions only. It contains a named dotnet solution. Eg. ipscm.tooling.ssis.scripts, or ipscm_library.Ssis.Deployment. it usually contains a .sln or .slnx
DOCKER_DATA_FOLDER. it's location is DATA_ROOT/docker/SRC_FOLDER. this the root of where any docker volume for the SRC_FOLDER is. Folders/files here are to not be touched for any reason whatsoever. folders/files DOCKER_DATA_FOLDER are meant to be volume mounted at contained start time and contain persistant data. eg databases that are created as part of docker image startup (eg open-webui), or application storage. 
SOLUTION_FOLDERS - SRC_FOLDER/*. these are subfolders under SRC_FOLDER and contain .csproj files referenced by .sln in the SRC_FOLDER.
DEPLOYMENT_FOLDER. This is also REPO_ROOT/src but used for scenarios where we do not do any code compilation. it is the same as SRC_FOLDER but has a name specific to the task - eg fs-resize for resizing a file system.
SRC_SCRIPTS_FOLDER. this is DEPLOYMENT_FOLDER/scripts. it contains the invoke-*.ps1. there can be multiple. eg SRC_SCRIPTS_FOLDER1 & SRC_SCRIPTS_FOLDER2.
DOCKER_ROOT. it's location is SRC_SCRIPTS_FOLDER*/docker. Only files that are required to either build the docker image, or are required when the docker container is running are stored here. See the docker.md pattern file in this folder for subfolders/structure under this folder. 
DOCKER_CONTEXT_ROOT. it's location is DOCKER_ROOT/context. These are files that are required to be avalable at container image build time, or container runtime. the structure of this folder should be relative to the / of the filesystem in the container - eg there is a /opt and & /etc folder. 
DOCKER_BUILD_CONTEXT_ROOT. it's location is DOCKER_CONTEXT_ROOT/build. files in here should be removed in the last step of the Dockerfile. they should not be included in the final image. this folder is included in the DOCKER_CONTEXT_ROOT and so goes into /build but is removed at the end of the docker build.
DOCKER_VOLUME_MOUNT_ROOT. it's location is DOCKER_CONTEXT_ROOT/volume_mount. this is a list of folders or files that should be mounted at container start time but should not be included in the container image. eg credentials, or secrets, or certificates. files should have a 1:1 mapping in the docker-compose.yaml file. only directories should outside of DOCKER_ROOT. 

examples in the docker-compose.yaml are: 
./volume_mounts/etc/env.conf:/etc/env.conf (for files)
../../../../data/docker/open-webui:/app/backend/data (for directories). 

Note there could be more than one SOLUTION_FOLDER and DEPLOYMENT_FOLDER under SRC_FOLDER and each of those can contain multiple subfolders . eg

SRC_FOLDER /
    solution1.slnx.
    SOLUTION_FOLDER1/project1.csproj.
    SOLUTION_FOLDER2/project2.csproj.
    SRC_SCRIPTS_FOLDER1/invoke-*.ps1. #for project1. 
    SRC_SCRIPTS_FOLDER1/docker #where we need to build a container for project1.
    SRC_SCRIPTS_FOLDER1/docker/context #files required for creating the container.
    SRC_SCRIPTS_FOLDER1/docker/context/build #temporary files used for configuring the container image - eg adding packages, configuring services. this folder should be removed prior to the Dockerfile completing.
    SRC_SCRIPTS_FOLDER2/invoke-*.ps1. #for project2. 
    SRC_SCRIPTS_FOLDER2/docker #where we need to build a container for project1.

# Main Scripts.

CI_SCRIPT - this is the main script that will be executed. It lives in CI_FOLDER and is called ci.ps1.

BUILD_TEST_SCRIPT. This is the main script that is used to build/compile/test .net code or software locally before checking it in. It lives in CI_FOLDER and is called ci.ps1.
INVOKE_DEPLOYMENT_SCRIPT - this is invoke-*.ps1 which is only used to run tooling or call assemblies that are created under SRC_FOLDER. it always goes into SRC_FOLDER/scripts. if we need to build a docker container we should include the steps here. 

# Main configuration folders.

BUILD_TEST_CONFIG_FOLDER. This folder is defined as CI_FOLDER/configs/. This is for configuration files that are used in the build phase of any project. This contains all of the configuration related to building a dotnet solution. eg solution name & folder.

RUN_CONFIG_FOLDER - this is under SRC_SCRIPTS_FOLDER/configs. This is a folder that contains a .json file that is specific to SRC_SCRIPTS_FOLDER. it contains only json properties that are required for SRC_SCRIPTS_FOLDER, or general properties - eg logVerbosity.

# config files:

use a json file for configuration - One with .local in the name. this is the file name that has all of the configuration that is required when running locally. it has real/resolved values. The filename without the .local name in the json contains tokens/octopus variables that are resolved at runtime in our CI/deployment tooling pipeline.

eg -
fs-resize.json (when no environment is specified).
fs-resize.local.json (when environment is defined as .local as specified in ci.ps1).

Configuration specific to where we need to seperate scripts that run on a host versus scripts that are run on a remote host. This is default pattern for scripts and assets for invoke-*.ps1.

DEPLOYMENT_SCRIPTS. SRC_SCRIPTS_FOLDER\scripts.
DEPLOYMENT_ASSETS_FOLDER. DEPLOYMENT_SCRIPTS/assets.
DEPLOYMENT_TEMPORARY_ASSETS. DEPLOYMENT_SCRIPTS/temporary_assets.
DEPLOYMENT_CACHED_ASSETS. DEPLOYMENT_SCRIPTS/cached_assets.

Configuration specific to where we need to seperate scripts that run on a host versus scripts that are run on a remote host. This is not the default pattern.

HOST_SCRIPTS - SRC_SCRIPTS_FOLDER/host. This is the scripts that are run on the machine running INVOKE_DEPLOYMENT_SCRIPT. This is so that we can keep scripts running as part of INVOKE_DEPLOYMENT_SCRIPT seperate from INSTANCE_SCRIPTS. 


HOST_ASSETS_FOLDER: HOST_SCRIPTS/assets. eg instance-metadata.sh which is used to configure an ssh connection on an ec2 instance.
HOST_TEMPORARY_ASSETS: HOST_SCRIPTS/temporary_assets. Files that are required by the script but would be generated at run time. eg ssh keys for pre-seeding the host. create if not exist, and remove at the end of the script.
HOST_CACHED_ASSETS: HOST_SCRIPTS/cached_assets these are files that used in the pipeline but are the same for each time. eg the raspberry-pi os image. Assets in this folder are not cleaned up post script execution so that they can be used next time. if they do not exist, then they should be create/downloaded etc and if they cannot the script should fail. the filenames of these assets should match the original source/purpose. eg 2025-12-04-raspios-trixie-arm64-lite.img.xz which is the file name of the url to get the raspberry pi image should be the name of the file.

INSTANCE_SCRIPTS: SRC_SCRIPTS_FOLDER/instance. These are scripts that are uploaded onto a remote host for execution (eg file system resizing). there is no crossover between HOST_SCRIPTS and INSTANCE_SCRIPTS.

INSTANCE_ASSETS_FOLDER. defined as INSTANCE_SCRIPTS/assets. eg resize-disk.sh which is run on an ec2 once we can connect to it.
INSTANCE_TEMPORARY_ASSETS. INSTANCE_SCRIPTS/temporary_assets. Files that are required by the remote instance but would be generated at run time. use cases are generating a random value to customize the instance.
INSTANCE_CACHED_ASSETS: INSTANCE_SCRIPTS/cached_assets. Assets that are used by the live instance but do not need to be generated fresh each time. eg octopus tentacle msi. Assets in this folder are not cleaned up post script execution so that they can be used next time. if they do not exist, then they should be create/downloaded etc and if they cannot the script should fail. the filenames of these assets should match the original source/purpose. eg 2025-12-04-raspios-trixie-arm64-lite.img.xz which is the file name of the url to get the raspberry pi image should be the name of the file.

Asset caching.
for INSTANCE_CACHED_ASSETS and HOST_CACHED_ASSETS - generate a hash of the file (use any available) so we are able to check if the file is valid. use the original file hash from the source if it's available, otherwise generate it when the file is created and verify it ahead of using the file. fail the script if the hash does not match the file contents, the md5 filename should match the original filename but with the correct extension on it - eg .md5, .sha256 etc.

Include folders.

COMMON_INCLUDES. PROJECT_ROOT\includes

include folders specific to scripts where we use AWS.
AWS_CONFIG_FOLDER. a folder where we have a custom aws configuration script to stop it colliding with any existing profile in ~/.aws/config. Important: we should never touch ~/.aws/config. If the AWS* environment variables are correct then they supersede ~/.aws/config.
AWS_INCLUDES_FOLDER. goes under COMMON_INCLUDES\aws. There are some scripts that -
* Download/save/copy aws related powershell modules to the PS_MODULES_ENABLED folder.
* Setup SSO session & assume role including custom SSO credentials folders.

---

## Directory Tree.

## Tokens

```
REPO_ROOT                = C:\git\Repo1
CI_FOLDER                = REPO_ROOT\ci
CI_CONFIG_FOLDER         = CI_FOLDER\configs
SRC_SCRIPTS_FOLDER       = REPO_ROOT\src
SRC_SCRIPTS_FOLDER1      = REPO_ROOT\src\Project1
SRC_SCRIPTS_FOLDER2      = REPO_ROOT\src\Project2
DEPLOYMENT_INCLUDES      = SRC_SCRIPTS_FOLDER*\includes
DEPLOYMENT_CONFIG_FOLDER = SRC_SCRIPTS_FOLDER*\configs
TOOLS_FOLDER             = SRC_SCRIPTS_FOLDER*\tools\tools
DATA_FOLDER              = REPO_ROOT\data
DOCKER_ROOT              = SRC_SCRIPTS_FOLDER*\docker
DOCKER_DATA_FOLDER       = DATA_FOLDER\docker\Project*
FILES_FOLDER             = DATA_FOLDER\files
APPLICATION_DATA_FOLDER  = DATA_FOLDER\Project*\*. 
```

## REPO_ROOT layout

```
REPO_ROOT\
├── data\                                                (DATA_FOLDER)
    ├───docker                                           
│       ├───ELRChatbot (APPLICATION_DATA_FOLDER)         (DOCKER_DATA_FOLDER1 - for ELRChatbot)
│       ├───LinkedIn   (APPLICATION_DATA_FOLDER)         (DOCKER_DATA_FOLDER2 - for LinkedIn)
├── ci\                                                  (CI_FOLDER)
│   ├── ci.ps1
│   ├── build-test.ps1
│   └── configs\                                         (CI_CONFIG_FOLDER)
│       └── linkedin.json
└───src                                                  (SRC_FOLDER)                                             
    ├───ELRChatBot                                       
    │   ├───ELRChatBot.slnx                              (main solution file.)                                           
    │   ├───ELRChatBot.Api                                       
    │   ├───ELRChatBot.Library.Foo.                                       
    │   │
    │   └───scripts                                      (SRC_SCRIPTS_FOLDER1 - for ELRChatbot)
    │       │   invoke-application-tests.ps1
    │       │   invoke-deployment-test.ps1
    │       │   invoke-deployment.ps1
    │       │   invoke-docker.ps1
    │       │
    │       ├───configs
    │       │       elrchatbot.local.json
    │       │
    │       └───docker                                  (DOCKER_ROOT)
    │           │   docker-compose.yml
    │           │   Dockerfile
    │           │   readme.md
    │           │
    │           ├───context                             (DOCKER_CONTEXT_ROOT)
    │           │   │   readme.md
    │           │   │
    │           │   ├───build
    │           │   │       install-powershell.sh
    │           │   │
    │           │   ├───etc
    │           │   │       supervisord.conf
    │           │   │
    │           │   └───opt
    │           │           readme.md
    │           │           startup.ps1
    │           │
    │           └───volume_mounts                       (DOCKER_CONTEXT_ROOT)
    │               │   env.conf.example
    │               │
    │               └───etc
    │                       env.conf
    │
│   └── LinkedIn\                                        (SRC_SCRIPTS_FOLDER2 - for LinkedIn)
    │   └───scripts                                      (SRC_SCRIPTS_FOLDER1 - for ELRChatbot)
    │       ├── invoke-*.ps1
    │       ├── configs\                                     (DEPLOYMENT_CONFIG_FOLDER)
    │       │   └── linkedin.json
    │       ├── includes\                                    (DEPLOYMENT_INCLUDES)
    │       │   ├── logging.ps1
    │       │   ├── configuration.ps1
    │       │   ├── assignment.ps1
    │       │   └── research.ps1
    │       └── tools\                                       (TOOLS_FOLDER)
    │           └── tools\
    │               └── chatgpt.exe
└── documentation\
    ├── plans\
    │   ├── plan.md
    │   └── structure.md
    └── prompts\
        └── prompt.md
```
