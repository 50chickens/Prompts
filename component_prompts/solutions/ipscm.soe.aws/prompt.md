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
no user impact. there are no users. 
assume no permissions or connectivity issues.
do not do any instance configuration except for those related to disk resizing activity.


create a plan.md containing each step in the high level process and the core powershell command that would be used to execute it. 

phase 1: 

create a pipeline to test the scripts. use qemu under linux to create a virtual machine for the problematic host. dont do any changes towards solving the problem in phase 1. this is only for setting up the pipeline.
follow the /home/pistomp/git/internal/Prompts/agents.md on how to create a powershell script. ignore any instructions about github - we are not using that. do not write any code yet. we are only creating the plan. write the plan into /home/pistomp/git/internal/Prompts/component_prompts/solutions/ipscm.soe.aws
 

