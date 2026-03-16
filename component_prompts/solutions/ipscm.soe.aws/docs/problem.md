# LVM /var Partition Expansion Problem

## Problem Statement

A Linux server has a `/var` partition that cannot be resized due to LVM constraints. The logical volume requires free space in the volume group to extend, but no free space is available in the existing `data_vg` volume group. The partition cannot be shrunk on a running system, and `/var/` is actively in use.

## Current Disk Layout

### Physical Partitions
- Partition 1: 1 MB BIOS boot
- Partition 2: 200 MB EFI system
- Partition 3: 1 GB /boot
- Partition 4: 8.8 GB / (root filesystem)
- Partition 5: ~44 GB LVM physical volume

### LVM Layout (data_vg volume group)
- lv_usr: 5 GB → /usr
- lv_var: 10 GB → /var (requires expansion)
- lv_opt: 5 GB → /opt
- lv_home: 5 GB → /home
- lv_var_log: 5 GB → /var/log
- lv_var_tmp: 5 GB → /var/tmp
- lv_var_log_audit: 5 GB → /var/log/audit
- lv_var_lib_docker: remaining space (to be deleted)

## Requirements

The `/var` filesystem must be positioned at the end of the disk to allow for future expansion when additional space is added to the instance.

## Constraints

- No backups required
- Helper server is replaceable and contains no important data
- No user impact (no active users)
- Assume no permissions or connectivity issues
- Only disk resizing operations should be performed; no other instance configuration changes
