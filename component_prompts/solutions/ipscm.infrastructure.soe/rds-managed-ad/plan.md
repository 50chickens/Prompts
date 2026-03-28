# plan: rds-managed-ad

## folder structure

```
REPO_ROOT\
├── ci\
│   ├── ci.ps1
│   ├── build-test.ps1                                             # noop
│   └── configs\
│       └── rds-managed-ad.local.json                             # all configuration for this deployment
│
└── src\
    ├── env-setup\ (Invoke-SetupLocalEnvironment)
    │
    ├── networking\ (Invoke-DeployNetworking)
    │   └── cft\
    │       └── networking.yaml
    │
    ├── iam\ (Invoke-DeployIam)
    │   └── cft\
    │       └── iam.yaml
    │
    ├── s3-bucket\ (Invoke-CreateS3Bucket)
    │   └── cft\
    │       └── s3-bucket.yaml
    │
    ├── secrets\ (Invoke-CreateSecrets)
    │
    ├── upload-scripts\ (Invoke-UploadHostScriptsToS3Bucket)       # all instance scripts live here
    │   ├── instance\
    │   │   ├── bootstrap\
    │   │   │   └── assets\
    │   │   │       └── bootstrap.ps1
    │   │   ├── configure-ipscminet-dc\
    │   │   │   └── assets\
    │   │   │       ├── configure-ipscminet-dc-pre-reboot.ps1
    │   │   │       └── configure-ipscminet-dc-post-reboot.ps1
    │   │   ├── configure-pbs-dc\
    │   │   │   └── assets\
    │   │   │       ├── configure-pbs-dc-pre-reboot.ps1
    │   │   │       └── configure-pbs-dc-post-reboot.ps1
    │   │   ├── configure-trust\
    │   │   │   └── assets\
    │   │   │       └── configure-trust-pbs-side.ps1
    │   │   └── configure-managed-member\
    │   │       └── assets\
    │   │           └── configure-managed-member.ps1
    │   └── configs\
    │       └── rds-managed-ad.instance.json                        # configuration consumed by all instance scripts
    │
    ├── managed-ad\ (Invoke-DeployManagedAd)
    │   └── cft\
    │       └── managed-ad.yaml
    │
    ├── rds\ (Invoke-DeployRds)
    │   └── cft\
    │       └── rds.yaml
    │
    ├── ec2-instances\ (Invoke-DeployEc2Instances)
    │   └── cft\
    │       └── ec2-instances.yaml
    │
    ├── configure-ipscminet-dc\ (Invoke-ConfigureIpscminetDc)
    ├── configure-pbs-dc\ (Invoke-ConfigurePbsDc)

    ├── configure-trust\ (Invoke-ConfigureTrust)
    ├── configure-managed-member\ (Invoke-ConfigureManagedMember)
    └── teardown\ (Invoke-Teardown)
```

## DNS and DHCP strategy

Windows AD has a strict requirement that domain members use the domain controller as their primary DNS server.
The VPC has three private /24 subnets, one in each AZ, and a public /28 subnet solely for the NAT gateway.
EC2 instances and their pre-assigned ENIs all reside in the first private subnet (AZ1). The second and third
private subnets exist solely to satisfy the RDS DB subnet group requirement of subnets in at least 2 AZs.
The DHCP options set is initially set to AmazonProvidedDNS and updated to Managed AD DNS IPs after the
managed-ad phase completes. The ipscminet-dc and pbs-dc instance scripts must override their NIC DNS to
point to themselves early in execution (before domain promotion) since the Managed AD DNS cannot resolve
ipscminet.com or pbs.ipscminet.com until those domains exist and conditional forwarders are in place.
Managed AD is configured with conditional forwarders for ipscminet.com and pbs.ipscminet.com pointing at their
respective DC IPs. This allows the managed-member (which uses DHCP → Managed AD DNS) to resolve all domains
in the environment.

## phases

ci.ps1 generates a timestamp (format: YYYYMMDDHHmm) at startup that is passed to all invoke-deployment.ps1 scripts and used as the prefix for all CloudWatch log stream names created in that run.

Before invoking each invoke-deployment.ps1, ci.ps1 checks the phase status using the unified Status-{PhaseName} model (see prompt.md). For CFT phases, the Status tag is read from the phase's own CFT stack. For configure-* phases, the Status tag is read from the ec2-instances CFT stack. For non-CFT phases (secrets, upload-scripts), the status is read from an SSM Parameter Store path defined in rds-managed-ad.local.json. Status tag values encode both status and timestamp in the format {Status}:{Timestamp} (e.g. InProgress:202603281200). On resume from InProgress, ci.ps1 parses the timestamp from the tag value to identify the exact CloudWatch log stream to resume polling. Status outcomes: Completed → skip the phase entirely; InProgress → check the underlying source of truth (CFT stack status or CloudWatch DeploymentScriptStatus) to determine whether to resume or fail; Failed → clean up and retry. Stacks in a hard CFT failure state (ROLLBACK_COMPLETE, ROLLBACK_FAILED, UPDATE_ROLLBACK_FAILED) are deleted before the phase is retried.

Each CFT phase includes an `Invoke-ValidateDeployment` function that verifies the deployed resources are in a valid and correct state after the stack completes. The invoke-deployment.ps1 sets the Status-{PhaseName} tag on the relevant CFT stack to InProgress at the start of execution, Completed on successful validation, and Failed on any unhandled error. Tags are applied to the CFT stack, not to individual resources. The configure-* phases apply their Status tag to the ec2-instances CFT stack. Non-CFT phases write their status to SSM Parameter Store.

CloudWatch logging pattern (all configure-* phases).
All instance scripts run from c:\bootstrap\ and write structured JSON log entries to a CloudWatch log
stream. Log groups and log streams are created if they do not exist and have a 7-day retention policy.
Log streams are named {timestamp}-{phaseName} where timestamp is supplied by ci.ps1 (e.g.
202603281456-Invoke-ConfigureIpscminetDc). Each log entry is a JSON blob with fields: Level, Message,
Exception, Host, Script, and DeploymentScriptStatus (one of InProgress / Rebooting / Completed /
Failed). The invoke-deployment.ps1 host script asynchronously polls the CloudWatch log stream for
DeploymentScriptStatus values to detect progress, reboots, completion, and failure. When an instance
script must reboot the OS it writes DeploymentScriptStatus: Rebooting to CloudWatch before triggering
the reboot, then exits. The host script detects Rebooting, then polls SSM DescribeInstanceInformation
until the instance re-registers as Online before issuing the next SSM Run Command. Configuration values
required by instance scripts are stored in rds-managed-ad.instance.json (uploaded to the configs/ S3
prefix). Instance scripts use the get-configuration pattern to load this file from S3. No magic strings
or hardcoded values appear in any instance or host script.

SSM Run Command mechanism (all configure-* phases).
All "Issues SSM Run Command with <script>.ps1" steps use AWS-RunPowerShellScript with a short inline
bootstrap (executed under powershell.exe 5.1). The inline: creates c:\bootstrap\ if absent; uses
`aws s3 cp` to download bootstrap.ps1 from S3; checks if PS7 is installed and if not runs
bootstrap.ps1 (installs PS7, removes AWSPowerShell monolithic, installs required AWS.Tools.* from
PSGallery under pwsh 7); then uses `aws s3 cp` to download rds-managed-ad.instance.json and the
target script to c:\bootstrap\; then invokes the target script with `pwsh -File c:\bootstrap\<script>.ps1`.
All configure-* instance scripts are PS7 and import AWS.Tools.Common, AWS.Tools.CloudWatchLogs,
AWS.Tools.SecretsManager, and AWS.Tools.SimpleSystemsManagement. S3 reads use `aws s3 cp` (AWS CLI)
not AWS.Tools.S3.

- env-setup (`Invoke-SetupLocalEnvironment`)
  Installs AWS.Tools modules (Common, CloudFormation, S3, EC2, DirectoryService, RDS, SSM, SecretsManager,
  CloudWatchLogs) into PS_MODULES_ENABLED. CloudWatchLogs is required by host scripts that poll instance
  CloudWatch log streams for DeploymentScriptStatus. Configures a custom AWS config folder. Validates
  AWS credentials are available via environment variables.

- networking (`Invoke-DeployNetworking`)
  Deploys networking.yaml CFT. Creates 1 VPC with three private /24 subnets, one in each AZ. All EC2
  instances and pre-assigned ENIs reside in the first private subnet (AZ1). The second and third private
  subnets exist solely to satisfy the RDS DB subnet group requirement of at least 2 subnets in different AZs.
  Adds a small public subnet (/28) solely to host a NAT gateway — NAT gateways must reside in a public subnet.
  Creates an internet gateway attached to the VPC and a default route in the public subnet to the internet
  gateway. Creates a NAT gateway in the public subnet with an elastic IP. All three private subnets route
  outbound traffic through the NAT gateway so instances have internet egress with no inbound connectivity
  from the internet. Creates pre-assigned ENIs for ipscminet-dc, pbs-dc, and managed-member with fixed
  private IPs in the first private subnet so that if any instance is rebuilt it retains the same IP address
  (important for DNS conditional forwarder configuration). Creates a default security group allowing all
  traffic (0.0.0.0/0 ingress and egress). Creates VPC endpoints for SSM, SSMMessages, EC2Messages, S3,
  and SecretsManager so that AWS service API calls stay on the AWS network. Creates a DHCP options set
  with AmazonProvidedDNS as the initial DNS server; updated to Managed AD DNS IPs after the managed-ad
  phase completes (Invoke-UpdateDhcpOptions).
  Invoke-ValidateDeployment: verifies VPC, all 3 private subnets, public subnet, internet gateway, NAT
  gateway, ENIs, security group, VPC endpoints, and DHCP options set all exist and are in an available/active
  state. Tags the networking CFT stack on success.

- iam (`Invoke-DeployIam`)
  Deploys iam.yaml CFT. Creates an EC2 instance profile granting: s3:GetObject and s3:ListBucket on the
  script S3 bucket; ssm:* for Session Manager; secretsmanager:GetSecretValue for retrieving passwords;
  ssm:GetParameter for retrieving Secret ARNs from Parameter Store;
  logs:CreateLogGroup, logs:CreateLogStream, logs:PutLogEvents, logs:DescribeLogStreams, and
  logs:DescribeLogGroups for writing and reading instance CloudWatch log streams. Creates the IAM role
  required for RDS to join the Managed
  AD directory (AmazonRDSDirectoryServiceAccess policy).
  Invoke-ValidateDeployment: verifies instance profile and both IAM roles exist and are attachable. Tags the
  iam CFT stack on success.

- s3-bucket (`Invoke-CreateS3Bucket`)
  Deploys s3-bucket.yaml CFT. Creates a private S3 bucket with BlockPublicAcls, IgnorePublicAcls,
  BlockPublicPolicy, and RestrictPublicBuckets all enabled. No public access of any kind.
  Invoke-ValidateDeployment: confirms bucket exists and GetBucketPublicAccessBlock returns all four
  block settings as true. Tags the s3-bucket CFT stack on success.

- secrets (`Invoke-CreateSecrets`)
  Writes Status-Invoke-CreateSecrets = InProgress to SSM Parameter Store (path from rds-managed-ad.local.json)
  at the start of execution. Uses the Secrets Manager GenerateRandomPassword endpoint to create secrets for:
  Managed AD admin password, ipscminet.com domain admin password, ipscminet.com Safe Mode Administrator
  password, pbs.ipscminet.com domain admin password, pbs.ipscminet.com Safe Mode Administrator password,
  non-administrator user password, and trust shared password. Secret ARNs are stored as SSM Parameter Store
  parameters for retrieval by instance scripts. Writes Status-Invoke-CreateSecrets = Completed to SSM
  Parameter Store on success.

- upload-scripts (`Invoke-UploadHostScriptsToS3Bucket`)
  Writes Status-Invoke-UploadHostScriptsToS3Bucket = InProgress to SSM Parameter Store at the start of
  execution. Enumerates all files under upload-scripts/instance/*/assets/ and uploads each to the S3 bucket
  under a key prefix matching the phase subfolder name. Uploads rds-managed-ad.instance.json from
  upload-scripts/configs/ to the configs/ S3 prefix. All instance scripts and configuration files for the
  entire pipeline are sourced from this single folder.
  Invoke-ValidateDeployment: lists all expected S3 key prefixes (scripts and config) and verifies each file
  exists in the bucket. Fails if any file is missing. Writes Status-Invoke-UploadHostScriptsToS3Bucket =
  Completed to SSM Parameter Store on success.

- managed-ad (`Invoke-DeployManagedAd`)
  Deploys managed-ad.yaml CFT. Creates the AWS Managed AD directory with DNS name test.ipscm and NetBIOS
  name TEST (Standard edition). After the stack completes, calls DescribeDirectories to query the
  directory ID and DNS IP addresses from the DirectoryService API at runtime (CFT outputs are not used).
  Invokes Invoke-UpdateDhcpOptions to update the networking DHCP options set to use those DNS IPs.
  Writes the two Managed AD DNS IP addresses to SSM Parameter Store (one parameter per IP, parameter
  names from rds-managed-ad.local.json) so that instance scripts can retrieve them at runtime for
  conditional forwarder configuration. Retrieves the Managed AD admin plaintext password from Secrets
  Manager (using the ARN stored in SSM Parameter Store by the secrets phase), then creates a SecureString
  SSM Parameter Store parameter at /aws/directory-services/{directoryId}/joinDomain containing JSON with
  the Managed AD admin username and plaintext password, enabling SSM agent seamless domain join for EC2
  instances at launch.
  Invoke-ValidateDeployment: confirms directory status is Active via DescribeDirectories. Tags the
  managed-ad CFT stack on success.

- rds (`Invoke-DeployRds`)
  Deploys rds.yaml CFT. Creates a DB subnet group spanning all three private subnets (across all 3 AZs) to
  satisfy the AWS requirement of subnets in at least 2 AZs. Creates a SQL Server RDS
  instance (Standard or Enterprise edition — Express does not support Managed AD Windows Authentication)
  with Windows Authentication enabled (Domain set to the Managed AD directory ID, DomainIAMRoleName set
  to the IAM role from the iam phase). No option group is required for SQL Server AD authentication; the
  Domain and DomainIAMRoleName properties are sufficient. No public accessibility.
  Invoke-ValidateDeployment: confirms RDS instance status is available, then polls DomainMemberships
  until the Managed AD directory shows status joined. The domain join is asynchronous — the CFT stack
  may report CREATE_COMPLETE while DomainMemberships is still in a joining state. Tags the rds CFT
  stack on success.

- ec2-instances (`Invoke-DeployEc2Instances`)
  Deploys ec2-instances.yaml CFT. The Windows Server 2022 AMI ID is resolved at deploy time using the
  CloudFormation dynamic reference {{resolve:ssm:/aws/service/ami-windows-latest/Windows_Server-2022-English-Full-Base}}
  as the ImageId — no hardcoded AMI ID. Creates 3 Windows Server 2022 instances, each attached to its
  pre-assigned ENI from the networking phase:
  - ipscminet-dc: forest root DC for ipscminet.com. Not domain joined at launch.
  - pbs-dc: child domain DC for pbs.ipscminet.com. Not domain joined at launch.
  - managed-member: joined to test.ipscm Managed AD at launch via SSM agent seamless domain join using
    the credentials SSM parameter created in the managed-ad phase. SQL 2019 will be installed here.
  All instances use the IAM instance profile from the iam phase, the default security group, and the
  private subnet. Access is exclusively via Session Manager (no key pairs, no public IPs).
  After the CFT stack completes, the invoke-deployment.ps1 queries the managed-member instance ID from
  the EC2 API and creates an SSM State Manager Association on that instance using the
  AWS-JoinDirectoryServiceDomain document and the Managed AD directory ID (queried via DescribeDirectories).
  This Association triggers the domain join and OS reboot on managed-member. ipscminet-dc and pbs-dc do
  not receive this Association and boot unjoined.
  Invoke-ValidateDeployment: verifies all 3 instances are in running state and registered with SSM.
  Tags the ec2-instances CFT stack on success.

- configure-ipscminet-dc (`Invoke-ConfigureIpscminetDc`)
  Sets Status-Invoke-ConfigureIpscminetDc = InProgress on the ec2-instances CFT stack at the start of
  execution (CFT stack name from rds-managed-ad.local.json). On ci.ps1 restart with this tag in InProgress,
  cross-checks the CloudWatch log stream {timestamp}-Invoke-ConfigureIpscminetDc for the latest
  DeploymentScriptStatus before deciding to resume or fail. Host script polls SSM DescribeInstanceInformation
  until ipscminet-dc is Online before issuing any Run Command. Issues SSM Run Command with
  configure-ipscminet-dc-pre-reboot.ps1. Polls the CloudWatch log stream {timestamp}-Invoke-ConfigureIpscminetDc
  asynchronously for DeploymentScriptStatus changes.
  Instance script (pre-reboot): runs from c:\bootstrap\. Writes InProgress to CloudWatch. Disables
  Windows Firewall via Set-NetFirewallProfile. Overrides NIC DNS to point to itself. Installs
  AD-Domain-Services. Writes DeploymentScriptStatus: Rebooting to CloudWatch, then calls
  Install-ADDSForest to promote the server as the ipscminet.com forest root DC and exits. The OS reboots.
  Host script detects Rebooting in CloudWatch, then polls SSM DescribeInstanceInformation until the
  instance re-registers as Online. Issues SSM Run Command with configure-ipscminet-dc-post-reboot.ps1.
  Instance script (post-reboot): runs from c:\bootstrap\. Writes InProgress to CloudWatch. Adds a
  conditional forwarder for test.ipscm using the Managed AD DNS IPs retrieved from SSM Parameter Store.
  Writes DeploymentScriptStatus: Completed (or Failed with full exception detail) to CloudWatch. Host
  script sets Status-Invoke-ConfigureIpscminetDc = Completed (or Failed) on the ec2-instances CFT stack.

- configure-pbs-dc (`Invoke-ConfigurePbsDc`)
  Sets Status-Invoke-ConfigurePbsDc = InProgress on the ec2-instances CFT stack at the start of execution.
  On ci.ps1 restart with this tag in InProgress, cross-checks CloudWatch log stream
  {timestamp}-Invoke-ConfigurePbsDc for the latest DeploymentScriptStatus before deciding to resume or fail.
  Depends on configure-ipscminet-dc completing successfully (ipscminet.com DNS must be available). Host
  script polls SSM DescribeInstanceInformation until pbs-dc is Online before issuing any Run Command.
  Issues SSM Run Command with configure-pbs-dc-pre-reboot.ps1. Polls the CloudWatch log stream
  {timestamp}-Invoke-ConfigurePbsDc asynchronously for DeploymentScriptStatus changes.
  Instance script (pre-reboot): runs from c:\bootstrap\. Writes InProgress to CloudWatch. Disables
  Windows Firewall via Set-NetFirewallProfile. Points NIC DNS temporarily at ipscminet-dc. Installs
  AD-Domain-Services. Writes DeploymentScriptStatus: Rebooting to CloudWatch, then calls
  Install-ADDSDomain to create the pbs child domain under ipscminet.com and exits. The OS reboots.
  Host script detects Rebooting in CloudWatch, then polls SSM DescribeInstanceInformation until the
  instance re-registers as Online. Issues SSM Run Command with configure-pbs-dc-post-reboot.ps1.
  Instance script (post-reboot): runs from c:\bootstrap\. Writes InProgress to CloudWatch. Switches NIC
  DNS to itself with ipscminet-dc as secondary. Adds a conditional forwarder for test.ipscm using the
  Managed AD DNS IPs retrieved from SSM Parameter Store. Creates a non-administrator domain user in
  pbs.ipscminet.com. Writes DeploymentScriptStatus: Completed (or Failed with full exception detail) to
  CloudWatch. Host script sets Status-Invoke-ConfigurePbsDc = Completed (or Failed) on the ec2-instances
  CFT stack.

- configure-trust (`Invoke-ConfigureTrust`)
  Sets Status-Invoke-ConfigureTrust = InProgress on the ec2-instances CFT stack at the start of execution.
  On ci.ps1 restart with this tag in InProgress, cross-checks CloudWatch log stream
  {timestamp}-Invoke-ConfigureTrust for the latest DeploymentScriptStatus before deciding to resume or
  fail. Three sub-cases: (a) no stream entries or DeploymentScriptStatus=InProgress → re-poll pbs-dc
  for Online then re-issue the SSM Run Command; (b) DeploymentScriptStatus=Completed → the instance
  script has already finished, skip re-issuing the SSM Run Command and resume polling DescribeTrusts
  directly; (c) DeploymentScriptStatus=Failed → fail the phase.
  Host script: calls AWS DirectoryService API to add conditional forwarders in Managed AD for
  ipscminet.com (→ ipscminet-dc) and pbs.ipscminet.com (→ pbs-dc). Retrieves the shared trust password
  from Secrets Manager (via its SSM Parameter Store ARN) then calls New-DSTrust to create a one-way
  outgoing trust from test.ipscm to pbs.ipscminet.com (pbs users can authenticate to test.ipscm
  resources). Polls SSM DescribeInstanceInformation until pbs-dc is Online, then issues SSM Run Command
  with configure-trust-pbs-side.ps1. Polls the CloudWatch log stream {timestamp}-Invoke-ConfigureTrust
  asynchronously for DeploymentScriptStatus changes.
  Instance script: runs from c:\bootstrap\. Writes InProgress to CloudWatch. Adds the reciprocal incoming
  trust on the pbs.ipscminet.com side using netdom, retrieving the shared trust password from Secrets
  Manager. Writes DeploymentScriptStatus: Completed (or Failed with full exception detail) to CloudWatch.
  After the instance script completes, the host script polls Get-DSTrust (DescribeTrusts) until TrustState
  equals Verified before the phase completes. Sets Status-Invoke-ConfigureTrust = Completed (or Failed) on
  the ec2-instances CFT stack.

- configure-managed-member (`Invoke-ConfigureManagedMember`)
  Sets Status-Invoke-ConfigureManagedMember = InProgress on the ec2-instances CFT stack at the start of
  execution. On ci.ps1 restart with this tag in InProgress, cross-checks CloudWatch log stream
  {timestamp}-Invoke-ConfigureManagedMember for the latest DeploymentScriptStatus before deciding to
  resume or fail. Host script polls SSM DescribeInstanceInformation until managed-member is Online. The
  domain join reboot triggered by the SSM State Manager Association will have completed long before this
  phase runs (given the preceding configure-ipscminet-dc and configure-pbs-dc phases). The host script
  does not attempt to detect the reboot cycle — it simply waits until the instance is Online. Once Online,
  the host issues SSM Run Command with configure-managed-member.ps1. Polls the CloudWatch log stream
  {timestamp}-Invoke-ConfigureManagedMember asynchronously for DeploymentScriptStatus changes.
  Instance script: runs from c:\bootstrap\. Writes InProgress to CloudWatch. Disables Windows Firewall
  via Set-NetFirewallProfile. Downloads the SQL Server 2019 Developer installer directly from the internet
  (URL TBD — placeholder to be filled in before implementation). Installs SQL Server 2019 in quiet mode
  with Windows Authentication only. Creates the HelloWorld database. Creates a Windows Authentication
  login for the pbs non-administrator user. Grants that user db_datareader and db_datawriter on HelloWorld.
  Grants that user the Allow log on locally right via local security policy (secedit). Writes
  DeploymentScriptStatus: Completed (or Failed with full exception detail) to CloudWatch. Host script sets
  Status-Invoke-ConfigureManagedMember = Completed (or Failed) on the ec2-instances CFT stack.

- teardown (`Invoke-Teardown`)
  Deletes the SSM State Manager Association created in the ec2-instances phase (the Association targeting
  managed-member with AWS-JoinDirectoryServiceDomain). This must be deleted explicitly as it is not
  managed by any CFT stack. Terminates EC2 instances (ipscminet-dc, pbs-dc, managed-member). Deletes CFT
  stacks in reverse order: ec2-instances, rds, managed-ad, s3-bucket (after emptying bucket), iam,
  networking. Deletes all Secrets Manager secrets created in the secrets phase. Deletes all SSM Parameter
  Store parameters created in the secrets phase. Deletes all SSM Parameter Store parameters created in the
  managed-ad phase (Managed AD DNS IP parameters and the joinDomain SecureString parameter). Deletes the
  SSM Parameter Store phase-status parameters written by the secrets and upload-scripts phases (paths from
  rds-managed-ad.local.json). Deletes the pre-assigned ENIs if not automatically removed by the networking
  stack.
