# LVM /var Partition Expansion - Implementation Plan

## Phase 1: Create Test Pipeline Infrastructure

Phase 1 establishes the testing pipeline for verifying partition resizing scripts against the problematic disk layout. This phase creates the automation framework to test each step of the solution before applying to production.

### Step 1: Create Original Host with Problematic Configuration

**Objective**: Instantiate a test server with the exact disk configuration that has the LVM space issue.

**Core PowerShell Command**:
```powershell
New-AzVm -ResourceGroupName $resourceGroup `
  -Name "original-host-test" `
  -Image "Canonical:0001-com-ubuntu-server-focal:20_04-lts-gen2:latest" `
  -Size "Standard_D4s_v3" `
  -DataDiskSizeInGB @(100)
```

**Expected Outcome**: Running EC2/Azure instance with raw disk attached ready for partitioning.

---

### Step 2: Configure Partitions and LVM on Original Host

**Objective**: Create the exact partition layout and LVM configuration that represents the problem state.

**Core PowerShell Commands**:
- Partition disk: `sudo parted /dev/sdb mklabel gpt`
- Create BIOS boot partition: `sudo parted /dev/sdb mkpart bios-boot 1MiB 2MiB; sudo parted /dev/sdb set 1 bios_grub on`
- Create EFI system partition: `sudo parted /dev/sdb mkpart efi-system 2MiB 202MiB; sudo parted /dev/sdb set 2 esp on`
- Create /boot partition: `sudo parted /dev/sdb mkpart boot ext4 202MiB 1202MiB`
- Create root partition: `sudo parted /dev/sdb mkpart root ext4 1202MiB 10GiB`
- Create LVM physical volume: `sudo parted /dev/sdb mkpart lvm-data ext4 10GiB 54GiB; sudo pvcreate /dev/sdb5`
- Create volume group: `sudo vgcreate data_vg /dev/sdb5`
- Create logical volumes in sequence:
  - `sudo lvcreate -L 5G -n lv_usr data_vg`
  - `sudo lvcreate -L 5G -n lv_var data_vg`
  - `sudo lvcreate -L 5G -n lv_opt data_vg`
  - `sudo lvcreate -L 5G -n lv_home data_vg`
  - `sudo lvcreate -L 5G -n lv_var_log data_vg`
  - `sudo lvcreate -L 5G -n lv_var_tmp data_vg`
  - `sudo lvcreate -L 5G -n lv_var_log_audit data_vg`
  - `sudo lvcreate -L [remaining_size] -n lv_var_lib_docker data_vg`

**Expected Outcome**: Original host with exact problematic LVM configuration.

---

### Step 3: Stop Original Host and Detach Disk

**Objective**: Prepare the problematic disk for transfer to helper server.

**Core PowerShell Commands**:
- Stop VM: `Stop-AzVM -ResourceGroupName $resourceGroup -Name "original-host-test" -Force`
- Detach disk (Get-AzVM then Update-AzVM with removed disk from StorageProfile.DataDisks)

**Expected Outcome**: Original host stopped and disk detached.

---

### Step 4: Create Helper Server

**Objective**: Instantiate a temporary server that will hold both disks (source and destination).

**Core PowerShell Command**:
```powershell
New-AzVm -ResourceGroupName $resourceGroup `
  -Name "helper-server-test" `
  -Image "Canonical:0001-com-ubuntu-server-focal:20_04-lts-gen2:latest" `
  -Size "Standard_D4s_v3" `
  -DataDiskSizeInGB @(100, 200)
```

**Expected Outcome**: Helper server running with 2 data disks (one 100GB from original host, one 200GB fresh disk).

---

### Step 5: Connect to Helper Server and Verify Disk Attachment

**Objective**: Establish SSH connection and verify both disks are visible.

**Core PowerShell Command**:
- SSH connection: `ssh -i $privateKeyPath "azureuser@$helperPublicIp"`
- Verify disks in SSH session: `lsblk` or `sudo parted -l`

**Expected Outcome**: SSH session established, both disks visible in helper server.

---

### Step 6: Create Partition and LVM Layout on Larger Disk

**Objective**: Create the new partition structure on the larger disk with /var at the end to allow future expansion.

**Core PowerShell Commands** (executed via SSH):
- Create partitions following same sequence as original but with new layout prioritizing /var at end
- Partition disk: `sudo parted /dev/sdc mklabel gpt`
- Create standard partitions (BIOS, EFI, /boot, /)
- Create LVM volume group: `sudo vgcreate data_vg_new /dev/sdcN`
- Create logical volumes in new order with /var last:
  - `sudo lvcreate -L 5G -n lv_usr data_vg_new`
  - `sudo lvcreate -L 5G -n lv_opt data_vg_new`
  - `sudo lvcreate -L 5G -n lv_home data_vg_new`
  - `sudo lvcreate -L 5G -n lv_var_log data_vg_new`
  - `sudo lvcreate -L 5G -n lv_var_tmp data_vg_new`
  - `sudo lvcreate -L 5G -n lv_var_log_audit data_vg_new`
  - `sudo lvcreate -L [larger_size] -n lv_var data_vg_new`
  - `sudo lvcreate -L [remaining] -n lv_var_lib_docker data_vg_new`

**Expected Outcome**: New disk formatted with improved layout ready for data transfer.

---

### Step 7: Copy Content from Original Disk to New Disk

**Objective**: Transfer all filesystems from original disk to new disk preserving data and structure.

**Core PowerShell Commands** (executed via SSH):
- Mount original partitions (read-only)
- Mount new partitions
- Copy filesystems: `sudo rsync -av /mnt/original/usr /mnt/new/usr` (and repeat for each logical volume)
- Copy boot partition: `sudo dd if=/dev/sdX3 of=/dev/sdcY bs=4M status=progress`

**Expected Outcome**: All data copied from original disk to new disk.

---

### Step 8: Apply Boot Configuration to New Disk

**Objective**: Update boot configuration on new disk to match original host specifications for when disk is reattached.

**Core PowerShell Commands** (executed via SSH):
- Mount root filesystem from new disk
- Update /etc/fstab with UUIDs from new disk partitions: `sudo blkid` to get UUIDs, then edit /mnt/new/etc/fstab
- Reinstall bootloader on new disk: `sudo grub-install --target=x86_64-efi --efi-directory=/mnt/new/boot/efi --root-directory=/mnt/new /dev/sdc`
- Update GRUB configuration: `sudo grub-mkconfig -o /mnt/new/boot/grub/grub.cfg`

**Expected Outcome**: New disk configured with correct boot parameters for original host.

---

### Step 9: Shutdown Helper Instance

**Objective**: Stop helper server to prepare for disk detachment.

**Core PowerShell Command**:
- `Stop-AzVM -ResourceGroupName $resourceGroup -Name "helper-server-test" -Force`

**Expected Outcome**: Helper server stopped.

---

### Step 10: Detach New Disk from Helper Server

**Objective**: Remove the resized disk from helper server for reattachment to original host.

**Core PowerShell Command**:
- Remove disk using Az cmdlet: `$vm = Get-AzVM -ResourceGroupName $resourceGroup -Name "helper-server-test"; $vm.StorageProfile.DataDisks.RemoveAt([index_of_new_disk]); Update-AzVM -ResourceGroupName $resourceGroup -VM $vm`

**Expected Outcome**: New disk detached from helper server.

---

### Step 11: Reattach New Disk to Original Server

**Objective**: Connect the resized disk to the original host.

**Core PowerShell Command**:
- Attach disk to original host: `$vm = Get-AzVM -ResourceGroupName $resourceGroup -Name "original-host-test"; $diskId = (Get-AzDisk -ResourceGroupName $resourceGroup -Name $newDiskName).Id; Add-AzVMDataDisk -VM $vm -Name $newDiskName -ManagedDiskId $diskId -Lun 0; Update-AzVM -ResourceGroupName $resourceGroup -VM $vm`

**Expected Outcome**: New disk attached to original host.

---

### Step 12: Start Original Host

**Objective**: Boot original host from the resized disk.

**Core PowerShell Command**:
- `Start-AzVM -ResourceGroupName $resourceGroup -Name "original-host-test"`

**Expected Outcome**: Original host booting from new disk with expanded /var space.

---

### Step 13: Verify Disk Layout

**Objective**: Confirm the disk was properly resized and all filesystems are accessible with correct layout.

**Core PowerShell Commands** (via SSH to original host):
- Check volume group: `sudo vgdisplay data_vg`
- Check logical volumes: `sudo lvdisplay`
- Check free space: `sudo vgfs` and `df -h`
- Verify /var is at end of disk: `sudo parted -l` and check partition ordering
- Mount all filesystems and verify data integrity: `mount | grep data_vg`

**Expected Outcome**: Original host running with expanded /var partition positioned at disk end.

---

## Pipeline Architecture

The PowerShell automation will follow this structure:

- **Entry point**: `ci/build-test.ps1` with parameter `-ConfigurationFolder configs`
- **Configuration**: `ci/configs/ipscm.soe.aws.json` containing provider credentials, resource group, VM names, disk sizes
- **Functions**: Separate helper functions for each major step (Create-OriginalHost, Configure-PartitionsAndLVM, Stop-InstanceAndDetachDisk, etc.)
- **Main execution**: Sequential invocation of helper functions with configuration passed throughout
- **Error handling**: Allow errors to propagate naturally; $ErrorActionPreference = 'Stop'
- **Logging**: Minimal by default; surface only meaningful progress information

---

## Success Criteria

- Original host provisions with exact problematic LVM configuration
- Helper server successfully mounts both disks
- Partition copying completes without data loss
- Boot configuration correctly transfers to new disk
- Original host boots successfully from resized disk
- /var filesystem accessible with increased space
- /var positioned at end of disk for future expansion capability
