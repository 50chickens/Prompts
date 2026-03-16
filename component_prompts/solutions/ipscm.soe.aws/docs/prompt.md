create a problem description in problem.md where - 

the problem is - 
we have a linux server that the /var partition on the server cannot be resized. 
LVM logical volume requires free space in the volume group to extend.
No free space avialble available in the existing data_vg volume group.
cannot shrink other logical volumes on a running system. 
/var/ is actively in use. 

solution. 

methodology.

develop a process where we create a server with the problematic disk layout. then, we build a second helper server and use that to attach the disk from the original host and then copy the contents of the original disk to a new larger disk.

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

requirements. 
we need to place the /var file system mount at the end of the disk so that if we add new space to the instance it can be filled out to the size of the disk.

high level:

create 1 server with the original configuratation. 
Wait for the server to start. 
Stop the server. 
Detach the disk from the original host.
Create a new helper server. it can have any disk configuration attach 2 disks - one is from the original host. the other is a fresh larger disk.
connect to the new server via ssh. 
create volume group/partition layout on larger empty disk. 
copy content of the original disk with the layout that needs to be fixed to the new fresh disk.
apply boot config which would allow the original server to boot. the configuration needs to match the original host where the larger disk will be reattached, not the helper host. 
shtudown helper instance.
detach larger disk from helper server. 
reattach to original server.
restart original server. 
verify disk layout. 

constraints:
no backups required.
the helper server is replacable and contains no important information.
do not do any git or github actions.
no user impact. there are no users. 
assume no permissions or connectivity issues.
do not do any instance configuration except for those related to disk resizing activity & packages that are required to complete the task.
the environment to create is linux using qemu. dont use aws or azure, or other virtualization technologies.
the run.ps1 should be idempotent with all of it's operations.
Each phase is not complete until ipscm.soe.aws/run.ps1 runs successfully. 
Create a plan.md containing each step in the high level process and the core powershell command that would be used to execute it. 


patterns/folders:

use /home/pistomp/git/internal/Prompts/component_prompts/solutions/ipscm.soe.aws for all of the pipeline scripts to solve the problem long term. 
the guidelines for powershell/the pipeline are under the patterns folder - specifically the powershell.md which contains details of an orchestration script for solving phase 1. 
the scripts for this problem definately need to go into /home/pistomp/git/internal/Prompts/component_prompts/solutions/ipscm.soe.aws. 


Here is the different phases of solving the problem. 

phase initial_setup: 

Create a pipeline to create a basic framework for testing the disk resize scripts. use the CI pattern - eg a configs folder for the various components. ignore any references to nuget or github. we are not using those. 
Dont do any changes towards solving the disk resize problem.  
follow the /home/pistomp/git/internal/Prompts/agents.md on how to create a powershell script.

run /home/pistomp/git/internal/Prompts/component_prompts/solutions/ipscm.soe.aws/run.ps1 and verify this executes successfully. do not do any git or github actions.

phase distribution_creation:
tools: 
1. Raspberry Pi Imager. rpi-allows you to download an existing raspberry pi based linux distribution and also pre-seed it with ssh keys so that can ssh into the machine. you can install it with : sudo apt install rpi-imager. use the raspberry pi OS lite (64 bit) image - rpi-imager should allow you to customize it. note you'll need to create a local disk and use rpi-imager to write the OS to this disk. i am not sure if rpi-imager will let you write to an image where it is not a usb device attached to the system. you will need to look into this. i have cloned the rpi-imager source into /home/pistomp/git/external/rpi-imager so you can check. 

2. qemu - once the distribution is created/customized use qemu to boot it. use the ssh proxy so that we do not need to discover it's ip address.
3. ssh. once the virtual machine is started we should be able to connect to it via ssh.


the installation should pre-seed the root users ssh keys with a public/private key pair that we can then use to ssh into the server and execute the disk resizing commands. 
use /ipscm.soe.aws/fs-resize as the base folder for the entire process. 

options for executing scripts from inside the linux virtual machine: pre-seed the linux distribution with ssh keys that you can use to connect via ssh. this is preferable since we will use that other pattern in other places. 

phase environment_setup:

1. install qemu under linux to create a virtual machine - use the smallest linux distribution for the problematic host  - but the installation needs to be completed unattended. the disk volume group, disk and partition sizes can be proportionally so that the original problem can be solved but the total amount of disk copies is minimized. the disk on the host should be the problematic configuration. 


