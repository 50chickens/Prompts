# Workflow — rds-managed-ad

`ci.ps1` drives the entire pipeline. It generates a run timestamp and calls each phase's `invoke-deployment.ps1` in sequence, checking a status tag before each one to skip, resume, or retry.

## Local environment

`Invoke-SetupLocalEnvironment` — installs the required AWS.Tools modules and validates credentials before anything touches AWS.

## Foundation infrastructure

Three CFT phases stand up the baseline AWS resources in dependency order:

- `Invoke-DeployNetworking` — VPC, subnets, NAT gateway, pre-assigned ENIs, security group, VPC endpoints, and an initial DHCP options set.
- `Invoke-DeployIam` — EC2 instance profile and the RDS directory-service IAM role.
- `Invoke-CreateS3Bucket` — private S3 bucket that will hold all instance scripts.

## Secrets and scripts

Two non-CFT phases run after the bucket exists:

- `Invoke-CreateSecrets` — generates all passwords via Secrets Manager and stores their ARNs in SSM Parameter Store.
- `Invoke-UploadHostScriptsToS3Bucket` — uploads every instance script and the instance config JSON to S3. All subsequent instance scripts are sourced from here.

## Services

- `Invoke-DeployManagedAd` — creates the Managed AD directory, updates the VPC DHCP options to use its DNS IPs, and writes the domain join credentials SSM parameter that triggers seamless EC2 domain join at launch.
- `Invoke-DeployRds` — creates the SQL Server RDS instance joined to the Managed AD directory, passing master user credentials from Secrets Manager as CFT parameters. Polls until the domain join is confirmed.
- `Invoke-DeployEc2Instances` — launches three Windows Server 2022 instances attached to their pre-assigned ENIs, then creates an SSM State Manager Association on the domain member to trigger its domain join and reboot.

## Instance configuration

Each configure-* phase sends scripts to instances via SSM Run Command, polls a CloudWatch log stream for `DeploymentScriptStatus`, and handles reboots by detecting the `Rebooting` entry then waiting for SSM re-registration before sending the next script:

- `Invoke-ConfigureIpscminetDc` — promotes the forest root domain controller for `ipscminet.com` and adds a conditional forwarder for `test.ipscm`.
- `Invoke-ConfigurePbsDc` — promotes the child domain controller for `pbs.ipscminet.com`, configures DNS, adds the same conditional forwarder, and creates a non-administrator domain user.
- `Invoke-ConfigureTrust` — creates a one-way outgoing trust from `test.ipscm` to `pbs.ipscminet.com` via the DirectoryService API host-side, and runs `netdom` on the pbs DC to add the reciprocal incoming trust. Polls `DescribeTrusts` until `TrustState = Verified`.
- `Invoke-ConfigureManagedMember` — installs the ODBC Driver and sqlcmd client, connects to the RDS endpoint as the master user, and provisions the database, Windows Auth login, and permissions via T-SQL.

## Teardown

`Invoke-Teardown` — deletes all resources in reverse order: SSM Association, EC2 instances, CFT stacks (ec2 → rds → managed-ad → s3 → iam → networking), Secrets Manager secrets, and all SSM Parameter Store entries created during the deployment.
