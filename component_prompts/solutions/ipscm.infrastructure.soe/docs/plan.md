# environment_setup phase plan

## objective

Use the run.ps1 pipeline to install QEMU and create the original-host VM with the problematic LVM disk layout using Alpine Linux (smallest distribution), installed unattended.

## proportional disk sizing

Original production disk ~54GB total. Scale factor ~27x to minimise copy time:

partition 1: 1MB bios boot
partition 2: 8MB EFI system
partition 3: 40MB /boot
partition 4: 320MB / (root)
partition 5: 1000MB LVM physical volume (data_vg)

LVM volumes (data_vg):
lv_usr:           100MB -> /usr
lv_var:           200MB -> /var
lv_opt:           100MB -> /opt
lv_home:          100MB -> /home
lv_var_log:       100MB -> /var/log
lv_var_tmp:       100MB -> /var/tmp
lv_var_log_audit: 100MB -> /var/log/audit
lv_var_lib_docker: remaining -> (to be deleted in solution phase)

Total OS disk: ~370MB, LVM disk: 1000MB, VM RAM: 512MB

## steps

### step 1: install QEMU on host

Install qemu-system-x86, qemu-utils, and ovmf (UEFI firmware) on the Linux host via apt.

core command:
```
& sudo apt install -y qemu-system-x86 qemu-utils ovmf
```

Added to run.ps1 as: `Invoke-InstallQemu $configuration`

---

### step 2: download Alpine Linux virt ISO

Download the Alpine Linux "virt" flavour (smallest, no extra packages). Save path to configuration.

core command:
```powershell
Invoke-WebRequest -Uri $configuration.alpineIsoUrl -OutFile $configuration.isoPath
```

The virt ISO is ~60MB. Store iso in working directory. Added to run.ps1 as: `Invoke-DownloadIso $configuration`

---

### step 3: create OS disk image

Create a qcow2 disk image sized to hold the OS partitions (root + boot + EFI).

core command:
```
& qemu-img create -f qcow2 $configuration.diskImagePath "$($configuration.osDiskSizeMb)M"
```

Added to run.ps1 as: `Invoke-CreateDiskImage $configuration`

---

### step 4: create Alpine unattended answer file

Write an Alpine setup-alpine answer file to disk. The answer file drives the unattended Alpine install:
- keyboard layout
- hostname
- network (none needed for VM)
- root password
- timezone
- disk target and partition mode (sys)
- no proxy

core command (write via Set-Content):
```powershell
Set-Content -Path $configuration.answerFilePath -Value $answerFileContent
```

Added to run.ps1 as: `New-AnswerFile $configuration`

---

### step 5: create answer file disk image

Create a small FAT disk image containing the Alpine answer file so it can be mounted inside the VM at boot. Alpine's setup-alpine reads from a mounted path at /media/*/answerfile.

core commands:
```
& qemu-img create -f raw $configuration.answerDiskPath "2M"
& mkfs.vfat $configuration.answerDiskPath
& mcopy -i $configuration.answerDiskPath $configuration.answerFilePath ::answerfile
```

Added to run.ps1 as: `New-AnswerDisk $configuration`

---

### step 6: run unattended Alpine installation

Boot the VM with the Alpine ISO, the answer disk, and the destination OS disk. Alpine reads the answer file from the mounted FAT disk and runs setup-alpine unattended. VM shuts down after install completes.

QEMU is started with `-nographic -serial stdio` so PowerShell can observe output and detect completion (VM process exits).

core command:
```
& qemu-system-x86_64 `
    -m 512 `
    -nographic `
    -serial mon:stdio `
    -drive file=$($configuration.diskImagePath),format=qcow2,if=virtio `
    -drive file=$($configuration.answerDiskPath),format=raw,if=virtio,readonly=on `
    -cdrom $($configuration.isoPath) `
    -boot d `
    -no-reboot
```

Added to run.ps1 as: `Invoke-InstallAlpineOs $configuration`

---

### step 7: verify installed VM boots

Boot the installed OS disk (without ISO) in headless mode and verify the process exits cleanly within a timeout.

core command:
```
& qemu-system-x86_64 `
    -m 512 `
    -nographic `
    -serial mon:stdio `
    -drive file=$($configuration.diskImagePath),format=qcow2,if=virtio `
    -no-reboot
```

Added to run.ps1 as: `Invoke-VerifyVmBoots $configuration`

---

## run.ps1 main execution sequence after environment_setup

```
Invoke-PreflightCheck $ConfigurationFolder
$configurations = Get-Configurations $ConfigurationFolder
$configurations | ? { $_.enabled } | % {
    $configuration = Add-AdditionalConfiguration $_
    Invoke-InstallQemu $configuration
    Invoke-DownloadIso $configuration
    Invoke-CreateDiskImage $configuration
    New-AnswerFile $configuration
    New-AnswerDisk $configuration
    Invoke-InstallAlpineOs $configuration
    Invoke-VerifyVmBoots $configuration
}
```

## config additions to original-host.json

```json
{
  "alpineIsoUrl": "https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/x86_64/alpine-virt-<version>-x86_64.iso",
  "isoPath": "alpine-virt.iso",
  "diskImagePath": "disks/original-host.qcow2",
  "answerFilePath": "answerfile",
  "answerDiskPath": "disks/answerfile.img"
}
```
