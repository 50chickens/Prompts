# SOE Infrastructure Pipeline Pattern

---

## Source Repositories → Destination Copies

`ci.ps1` copies content from sibling projects into `src/` before invoking deployment:

| Source                               | Destination          | What                                       |
|---|---|---|
| `Soe.Linux.Host/role/$role/`         | `src/host/role/`     | Host-side orchestration scripts + includes |
| `Soe.Linux.Instance/scripts/`        | `src/remote/temporary_assets/` | Remote helper scripts |
| `Soe.Linux.Instance/role/$role/`     | `src/remote/role/`   | Instance-side deployment script |
| `ci/configs/`                        | `src/host/configs/`  | Env-specific config files                  |

Folders in `excludedCleanupFolders` (e.g. `modules`, `cached_assets`) survive cleanup.  
Folders in `excludedInstanceFolders` are not copied from instance source.

---

## Execution Flow

```text
ci.ps1
├── cleanup target folders
├── [optional] Invoke-HostRolePreDeployment.ps1   ← if exists in host role source
├── copy instance role content → src/remote/
├── copy host role content → src/host/role/
├── dot-source ci/src/includes/ + host role includes/
├── [optional] update PS modules
├── set AWS env vars + proxy settings
├── ensure AWS session (OIDC device flow)
└── invoke-deployment.ps1
    ├── dot-source src/host/includes/
    ├── Get-Configuration                 ← reads create-instance.json
    ├── Get-RuntimeConfiguration          ← adds AWS runtime values (AMI id, instance details)
    ├── Invoke-PreflightCheck
    ├── [steps...]
    │
    └── Invoke-HostRoleDeployment.ps1     ← copied from Linux.Host
        ├── includes/asg.ps1              ← ASG operations
        ├── includes/ebs.ps1              ← EBS volume operations
        ├── includes/ssh.ps1              ← SCP upload + SSH exec
        ├── includes/ssm.ps1              ← SSM commands
        ├── [uploads + runs on instance]
        │
        └── Invoke-InstanceRoleDeployment.ps1  ← copied from Linux.Instance


# SOE Infrastructure Pipeline Pattern

---

## Source Repositories → Destination Copies

`ci.ps1` copies content from sibling projects into `src/` before invoking deployment:

| Source | Destination | What |
|---|---|---|
| `Soe.Linux.Host/role/$role/` | `src/host/role/` | Host-side orchestration scripts + includes |
| `Soe.Linux.Instance/scripts/` | `src/remote/temporary_assets/` | Remote helper scripts |
| `Soe.Linux.Instance/role/$role/` | `src/remote/role/` | Instance-side deployment script |
| `ci/configs/` | `src/host/configs/` | Env-specific config files |

Folders in `excludedCleanupFolders` (e.g. `modules`, `cached_assets`) survive cleanup.  
Folders in `excludedInstanceFolders` are not copied from instance source.

---

## Execution Flow

```text
ci.ps1
├── cleanup target folders
├── [optional] Invoke-HostRolePreDeployment.ps1   ← if exists in host role source
├── copy instance role content → src/remote/
├── copy host role content → src/host/role/
├── dot-source ci/src/includes/ + host role includes/
├── [optional] update PS modules
├── set AWS env vars + proxy settings
├── ensure AWS session (OIDC device flow)
└── invoke-deployment.ps1
    ├── dot-source src/host/includes/
    ├── Get-Configuration                 ← reads create-instance.json
    ├── Get-RuntimeConfiguration          ← adds AWS runtime values (AMI id, instance details)
    ├── Invoke-PreflightCheck
    ├── [steps...]
    │
    └── Invoke-HostRoleDeployment.ps1     ← copied from Linux.Host
        ├── includes/asg.ps1              ← ASG operations
        ├── includes/ebs.ps1              ← EBS volume operations
        ├── includes/ssh.ps1              ← SCP upload + SSH exec
        ├── includes/ssm.ps1              ← SSM commands
        ├── [uploads + runs on instance]
        │
        └── Invoke-InstanceRoleDeployment.ps1  ← copied from Linux.Instance