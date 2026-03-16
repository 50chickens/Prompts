create a problem description in problem.md where - 

references:

working directory - ~/git/internal/ipscm.infrastructure.soe/src/. this is referenced as WORKING_DIRECTORY in this prompt.
orchestration script folder: same as working directory.
orchestration script name: WORKING_DIRECTORY/ci/run.ps1
documents folder: docs folder under working directory.

patterns/folders:

use WORKING_DIRECTORY for all of the pipeline scripts to solve the problem long term. 
the run.ps1 used by this solution is the tooling ps1 pattern. 
the scripts for this problem definately need to go into WORKING_DIRECTORY. do not references files outside this folder. if you need any additional code - copy it into the WORKING_DIRECTORY.

Patterns/guidelines to reference:
read ~git/internal/Prompts/agents.md for patterns relating to orchestration scripts, powershell coding guidelines and others.

## Problem
we have a linux server that the /var partition on the server cannot be resized. 
LVM logical volume requires free space in the volume group to extend.
No free space avialble available in the existing data_vg volume group.
cannot shrink other logical volumes on a running system. 
/var/ is actively in use. 

## Solution. 

We will attach the disk with the problematic layout to a helper instance and copy the data from that to an empty disk with an improved layout. 

## Methodology.

Develop a process where we create a server with the problematic disk layout. then, we build a second helper server and use that to attach the disk from the original host and then copy the contents of the original disk to a new larger disk.

original host -

partition 1: 1 mb bios boot.
partition 2: 200 MB EFI system.
partition 3: 1GB /boot
partition 4: 8.8 / (root fs)
partition 5: ~44gb LVM physical volume.

lvm layout (vg_data)
1. lv_usr: 5GB -> /usr
2. lv_var: 10GB /var (this is is the partition we need expanded).
3. lv_opt: 5GB -> /opt
4. lv_home: 5GB -> /home
5. lv_var_log: 5GB -> /var/log
6. lv_var-tmp: 5GB -> /var/tmp
7. lv_var_log_audit: 5GB -> /var/log/audit.  
8. lv_var_lib_docker: remaining space. this VG should be deleted.

Requirements. 
we need to place the /var file system mount at the end of the disk so that if we add new space to the instance it can be filled out to the size of the disk.

## High level process.

Create 1 server with the original configuratation. 
Wait for the server to start. 
Stop the server. 
Detach the disk from the original host.
Create a new helper server. it can have any disk configuration attach 2 disks - one is from the original host. the other is a fresh larger disk.
Connect to the new server via ssh. 
Create volume group/partition layout on larger empty disk. 
Copy content of the original disk with the layout that needs to be fixed to the new fresh disk.
Apply boot config which would allow the original server to boot. the configuration needs to match the original host where the larger disk will be reattached, not the helper host. 
Shutdown helper instance.
Detach larger disk from helper server. 
Reattach to original server.
Restart original server. 
Verify disk layout. 

## solution constrains.
The helper server is replacable and contains no important information.
Do not do any instance configuration except for those related to disk resizing activity & packages that are required to complete the task.
The environment to execute all of the scripts and where the virtual machine will be created is a local linux server. Do not use aws or azure, or other virtualization technologies.


## General Constraints.
No backups required.
Do not do any git or github actions.
Assume no permissions or connectivity issues.
No user impact. there are no users. 
The run.ps1 should be idempotent with all of it's operations.
Each phase is not complete until the orchestration script runs successfully. 
Create a problem.md that only contains the following - 
    Problem description.
    Solution. 
Create a phase specific plan.md first before writing any code for that phase. it should contain only each step in the high level process and the core powershell command that would be used to execute it.  call the file plan-phase.md - eg plan-initial_setup.md

## Phases.
Here is the different phases of solving the problem. 

phase initial_setup: 

Create a pipeline to create a basic framework for testing the disk resize scripts. use the CI pattern - eg a configs folder for the various components. ignore any references to nuget or github. we are not using those. 
Don't do any changes towards solving the disk resize problem.  


### phase distribution_creation.
tools: 
1. Raspberry Pi Imager. rpi-allows you to download an existing raspberry pi based linux distribution and also pre-seed it with ssh keys so that can ssh into the machine. you can install it with : sudo apt install rpi-imager. use the raspberry pi OS lite (64 bit) image - rpi-imager should allow you to customize it. note you'll need to create a local disk and use rpi-imager to write the OS to this disk. i am not sure if rpi-imager will let you write to an image where it is not a usb device attached to the system. you will need to look into this. i have cloned the rpi-imager source into /home/pistomp/git/external/rpi-imager so you can check. 

2. qemu - once the distribution is created/customized use qemu to boot it. use the ssh proxy so that we do not need to discover it's ip address.
3. ssh. once the virtual machine is started we should be able to connect to it via ssh.

the installation should pre-seed the root users ssh keys with a public/private key pair that we can then use to ssh into the server and execute the disk resizing commands. 
use /ipscm.soe.aws/fs-resize as the base folder for the entire process. 

options for executing scripts from inside the linux virtual machine: pre-seed the linux distribution with ssh keys that you can use to connect via ssh. this is preferable since we will use that other pattern in other places. 

### phase environment_setup:

1. install qemu under linux to create a virtual machine - use the smallest linux distribution for the problematic host  - but the installation needs to be completed unattended. the disk volume group, disk and partition sizes can be proportionally so that the original problem can be solved but the total amount of disk copies is minimized. the disk on the host should be the problematic configuration. 