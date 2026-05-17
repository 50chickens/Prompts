# SOE Infrastructure Pipeline Pattern

## Entry Point

`ci/src/ci.ps1` — only script ever run directly. Accepts params for environment, OS, and role.

## Key Parameters

| Param | Purpose |
|---|---|
| `$operatingSystem` | `linux` or `windows` — selects config file and role content |
| `$ExecutingEnvironment` | `local` or `aws` |
| `$targetEnvironment` | `dev01`, `env02`, etc. |
| `$role` | `DevServer` etc. — selects which role subfolder to copy |

Config filename: `ci.$operatingSystem.$ExecutingEnvironment.$targetEnvironment.json`
e.g. `ci.linux.local.dev01.json`

## File Layout

```
Infrastructure.Soe/
├── ci/
│   ├── src/
│   │   └── ci.ps1                              ← ONLY entry point
│   └── configs/
│       ├── ci.linux.local.dev01.json           ← env+OS-specific ci config
│       ├── ci.windows.local.dev01.json
│       ├── ec2-parameters.linux.local.dev01.json   ← CFT parameters
│       └── create-instance.linux.local.dev01.json  ← deployment config
├── src/
│   ├── host/                                   ← runs on LOCAL MACHINE
│   │   ├── invoke-deployment.ps1               ← called by ci.ps1
│   │   ├── includes/                           ← dot-sourced by ci.ps1
│   │   │   ├── aws/                            ← AWS session/credential helpers
│   │   │   ├── instance.ps1
│   │   │   └── package.ps1
│   │   ├── assets/
│   │   │   └── autoscale-linux.yaml            ← CFT template
│   │   ├── configs/                            ← COPIED from ci/configs by ci.ps1
│   │   └── role/                               ← COPIED from Soe.Linux.Host
│   │       ├── Invoke-HostRoleDeployment.ps1
│   │       ├── configs/
│   │       │   └── role.json                   ← host-side role config
│   │       ├── cached_assets/                  ← ssh keys (excluded from cleanup)
│   │       └── includes/                       ← asg, ebs, ssh, ssm...
│   ├── remote/                                 ← uploaded to EC2 instance
│   │   ├── scripts/
│   │   │   └── init-ec2-linux.sh               ← injected into CFT UserData/cfn-init
│   │   ├── role/                               ← COPIED from Soe.Linux.Instance
│   │   │   └── Invoke-InstanceRoleDeployment.ps1
│   │   └── temporary_assets/                   ← scratch; cleaned on each run
│   └── common/                                 ← shared between host and remote
```

## Source → Destination Copies

`ci.ps1` copies content from sibling projects into `src/` before invoking deployment:

| Source | Destination | What |
|---|---|---|
| `Soe.Linux.Host/role/$role/` | `src/host/role/` | Host-side orchestration scripts + includes |
| `Soe.Linux.Instance/scripts/` | `src/remote/temporary_assets/` | Remote helper scripts |
| `Soe.Linux.Instance/role/$role/` | `src/remote/role/` | Instance-side deployment script |
| `ci/configs/` | `src/host/configs/` | Env-specific config files |

Folders in `excludedCleanupFolders` (e.g. `modules`, `cached_assets`) survive cleanup.
Folders in `excludedInstanceFolders` are not copied from instance source.

## Execution Flow

```
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
    ├── Get-Configuration                         ← reads create-instance.json
    ├── Get-RuntimeConfiguration                  ← adds AWS runtime values (AMI id, instance details)
    ├── Invoke-PreflightCheck
    ├── [steps...]
    └── Invoke-HostRoleDeployment.ps1             ← copied from Linux.Host
        ├── includes/asg.ps1                      ← ASG operations
        ├── includes/ebs.ps1                      ← EBS volume operations
        ├── includes/ssh.ps1                      ← SCP upload + SSH exec
        ├── includes/ssm.ps1                      ← SSM commands
        ├── [uploads + runs on instance]
        └── Invoke-InstanceRoleDeployment.ps1     ← copied from Linux.Instance
```

## Environment / OS Selection

Config filename is composed from `$operatingSystem.$ExecutingEnvironment.$targetEnvironment`.
`linux` vs `windows` selects: CFT parameters file, role source project, init script.
`local` vs `aws` controls proxy settings and credential source.
No code branching on OS — selection is purely through which files get copied.

## Testing / Incremental Validation

Steps in `Invoke-HostRoleDeployment.ps1` are guarded by boolean flags in `role.json`:
```json
"updateASGInstanceState": false,
"updateASGDiskState": false,
"PerformDiskResizing": true,
"ValidateConnectionViaSSH": false,
"ValidateScriptUploadViaScp": true
```

Steps in `Invoke-InstanceRoleDeployment.ps1` are guarded by script-level flags:
```powershell
$PerformDiskPartitioning = $false
$PerformLvmCreation      = $false
```

Set one flag to `$true` at a time to validate each phase, then re-run `ci.ps1`.
`ReuseStack = true` in `create-instance.json` skips CFT deployment and reuses the existing stack.