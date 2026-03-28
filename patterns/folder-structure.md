# Start folder structure.md

There are 2 patterns of orchestration script but they both follow a similar path.

1. scripts that are used to execute tooling.
2. scripts that are designed to compile software. these follow the ci.ps1 -> build-test.ps1 as we need the build process to work locally during development and then also when we run the build process under a CI environment.

# Main folders.

PS_MODULES_ENABLED. C:\dev\PSModules\enabled. This is where aws powershell modules are eventually downloaded to. It is listed in the psmodulepath environment variable. note modules are not immediately downloaded to this folder - they are downloaded to an intermediate folder due to filelocking problems for aws.tools.common.

PROJECT_ROOT. C:\dev\scripts\all_scripts_go_here\projects\aws\projects. this is where all of the project scripts go regardless of type. each subfolder on this (except for includes) is a REPO_ROOT where REPO_ROOT is specific to a particular task.

DOCUMENTATION_FOLDER: REPO_ROOT/docs. Except for prompt.md this is where all of the docs go.

REPO_ROOT - this is the root of the source repository.

CI_FOLDER - this is REPO_ROOT/ci. It is used for the main ci.ps1 and the build-test.ps1 scripts. it is intended for scripts & config that will not be committed into source and are used for local development.

SRC_FOLDER - this is the REPO_ROOT/src/ folder under REPO_ROOT. it is main source root folder. This is for dotnet solutions only. It contains a named dotnet solution. Eg. ipscm.tooling.ssis.scripts, or ipscm_library.Ssis.Deployment. it usually contains a .sln or .slnx

SOLUTION_FOLDERS - SRC_FOLDER/*. these are subfolders under SRC_FOLDER and contain .csproj files referenced by .sln in the SRC_FOLDER.

DEPLOYMENT_FOLDER. This is also REPO_ROOT/src but used for scenarios where we do not do any code compilation. it is the same as SRC_FOLDER but has a name specific to the task - eg fs-resize for resizing a file system.

SRC_SCRIPTS_FOLDER. this is DEPLOYMENT_FOLDER/scripts. it contains the invoke-deployment.ps1.

note there maybe both SOLUTION_FOLDERS and DEPLOYMENT_FOLDER1 under SRC_FOLDER and each can contain multiple subfolders . eg

SRC_FOLDER \
    solution1.slnx.
    SOLUTION_FOLDER1\project1.csproj.
    SOLUTION_FOLDER2\project2.csproj.
    DEPLOYMENT_FOLDER1\invoke-deployment.ps1. #for task 1. 
    DEPLOYMENT_FOLDER2\invoke-deployment.ps1. #for task 2. 

# Main Scripts.

CI_SCRIPT - this is the main script that will be executed. It lives in CI_FOLDER and is called ci.ps1.

BUILD_TEST_SCRIPT. This is the main script that is used to build/compile/test .net code or software locally before checking it in. It lives in CI_FOLDER and is called ci.ps1.

INVOKE_DEPLOYMENT_SCRIPT - this is invoke-deployment.ps1 which is only used to run tooling or call assemblies that are created under SRC_FOLDER. it always goes into SRC_FOLDER/scripts.

# Main configuration folders.

BUILD_TEST_CONFIG_FOLDER. This folder is defined as CI_FOLDER/configs/. This is for configuration files that are used in the build phase of any project. This contains all of the configuration related to building a dotnet solution. eg solution name & folder.

RUN_CONFIG_FOLDER - this is under SRC_SCRIPTS_FOLDER/configs. This is a folder that contains a .json file that is specific to SRC_SCRIPTS_FOLDER. it contains only json properties that are required for SRC_SCRIPTS_FOLDER, or general properties - eg logVerbosity.

# config files:

use a json file for configuration - One with .local in the name. this is the file name that has all of the configuration that is required when running locally. it has real/resolved values. The filename without the .local name in the json contains tokens/octopus variables that are resolved at runtime in our CI/deployment tooling pipeline.

eg -
fs-resize.json (when no environment is specified).
fs-resize.local.json (when environment is defined as .local as specified in ci.ps1).

Configuration specific to where we need to seperate scripts that run on a host versus scripts that are run on a remote host. This is default pattern for scripts and assets for invoke-deployment.ps1.

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
REPO_ROOT                = C:\git\LinkedIn
CI_FOLDER                = REPO_ROOT\ci
CI_CONFIG_FOLDER         = CI_FOLDER\configs
DEPLOYMENT_FOLDER        = REPO_ROOT\src\LinkedIn
DEPLOYMENT_INCLUDES      = DEPLOYMENT_FOLDER\includes
DEPLOYMENT_CONFIG_FOLDER = DEPLOYMENT_FOLDER\configs
TOOLS_FOLDER             = DEPLOYMENT_FOLDER\tools\tools
DATA_FOLDER              = REPO_ROOT\data
FILES_FOLDER             = DATA_FOLDER\files
ASSIGNMENTS_FOLDER       = DATA_FOLDER\LinkedIn\assignments
```

## REPO_ROOT layout

```
REPO_ROOT\
├── ci\                                                  (CI_FOLDER)
│   ├── ci.ps1
│   ├── build-test.ps1
│   └── configs\                                         (CI_CONFIG_FOLDER)
│       └── linkedin.json
├── src\
│   └── LinkedIn\                                        (DEPLOYMENT_FOLDER)
│       ├── invoke-deployment.ps1
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
├── data\                                                (DATA_FOLDER)
│   ├── files\                                           (FILES_FOLDER)
│   │   ├── background.md
│   │   └── identify_candidate_constraints-template.md
│   └── LinkedIn\
│       └── assignments\                                 (ASSIGNMENTS_FOLDER)
│           └── <AssignmentName>\
│               ├── chatgpt\
│               ├── LinkedIn\
│               └── prompt\
│                   └── identify_candidate_constraints.md
└── documentation\
    ├── plans\
    │   ├── plan.md
    │   └── structure.md
    └── prompts\
        └── prompt.md
```


##insert example here.

this is an example directory tree for a set of scripts where we - use AWS and connect to a remote host.

##insert example here.