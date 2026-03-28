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
    │   └── instance\
    │       ├── configure-ipscminet-dc\
    │       │   └── assets\
    │       │       ├── configure-ipscminet-dc-pre-reboot.ps1
    │       │       └── configure-ipscminet-dc-post-reboot.ps1
    │       ├── configure-pbs-dc\
    │       │   └── assets\
    │       │       ├── configure-pbs-dc-pre-reboot.ps1
    │       │       └── configure-pbs-dc-post-reboot.ps1
    │       ├── configure-trust\
    │       │   └── assets\
    │       │       └── configure-trust-pbs-side.ps1
    │       └── configure-managed-member\
    │           └── assets\
    │               └── configure-managed-member.ps1
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
    ├── configure-managed-ad-gpo\ (Invoke-ConfigureManagedAdGpo)
    ├── configure-trust\ (Invoke-ConfigureTrust)
    ├── configure-managed-member\ (Invoke-ConfigureManagedMember)
    └── teardown\ (Invoke-Teardown)
```

## DNS and DHCP strategy

Windows AD has a strict requirement that domain members use the domain controller as their primary DNS server.
The VPC has a private /24 subnet for all instances and a public /28 subnet solely for the NAT gateway.
The DHCP options set is initially set to AmazonProvidedDNS and updated to Managed AD DNS IPs after the
managed-ad phase completes. The ipscminet-dc and pbs-dc instance scripts must override their NIC DNS to
point to themselves early in execution (before domain promotion) since the Managed AD DNS cannot resolve
ipscminet.com or pbs.ipscminet.com until those domains exist and conditional forwarders are in place.
Managed AD is configured with conditional forwarders for ipscminet.com and pbs.ipscminet.com pointing at their
respective DC IPs. This allows the managed-member (which uses DHCP → Managed AD DNS) to resolve all domains
in the environment.

## phases

ci.ps1 scans for any existing CFT stacks with a matching name prefix that are in a failed or rollback state (ROLLBACK_COMPLETE, ROLLBACK_FAILED, UPDATE_ROLLBACK_FAILED) and deletes them before invoking each invoke-deployment.ps1.

Each CFT phase includes an `Invoke-ValidateDeployment` function that verifies the deployed resources are in a valid and correct state after the stack completes. On success it applies a `successfully-configured = true` tag to the CFT stack itself (not to individual resources). Subsequent runs check for this tag and skip the phase if present. For non-CFT phases the equivalent validation is a verification step at the end of the host script.

- env-setup (`Invoke-SetupLocalEnvironment`)
  Installs AWS.Tools modules (Common, CloudFormation, S3, EC2, DirectoryService, RDS, SSM, SecretsManager)
  into PS_MODULES_ENABLED. Configures a custom AWS config folder. Validates AWS credentials are available
  via environment variables.

- networking (`Invoke-DeployNetworking`)
  Deploys networking.yaml CFT. Creates 1 VPC with a private /24 subnet for all instances. Adds a small
  public subnet (/28) solely to host a NAT gateway — this is required because NAT gateways must reside in
  a public subnet. Creates an internet gateway attached to the VPC and a default route in the public subnet
  to the internet gateway. Creates a NAT gateway in the public subnet with an elastic IP. Routes all
  outbound traffic from the private subnet through the NAT gateway so instances have internet egress with
  no inbound connectivity from the internet. Creates pre-assigned ENIs for ipscminet-dc, pbs-dc, and
  managed-member with fixed private IPs so that if any instance is rebuilt it retains the same IP address
  (important for DNS conditional forwarder configuration). Creates a default security group allowing all
  traffic (0.0.0.0/0 ingress and egress). Creates VPC endpoints for SSM, SSMMessages, EC2Messages, S3,
  and SecretsManager so that AWS service API calls stay on the AWS network. Creates a DHCP options set
  with AmazonProvidedDNS as the initial DNS server; updated to Managed AD DNS IPs after the managed-ad
  phase completes (Invoke-UpdateDhcpOptions).
  Invoke-ValidateDeployment: verifies VPC, subnets, internet gateway, NAT gateway, ENIs, security group,
  VPC endpoints, and DHCP options set all exist and are in an available/active state. Tags the networking
  CFT stack on success.

- iam (`Invoke-DeployIam`)
  Deploys iam.yaml CFT. Creates an EC2 instance profile granting: s3:GetObject and s3:ListBucket on the
  script S3 bucket; ssm:* for Session Manager; secretsmanager:GetSecretValue for retrieving passwords;
  ssm:GetParameter for retrieving Secret ARNs from Parameter Store. Creates the IAM role required for RDS to
  join the Managed AD directory (AmazonRDSDirectoryServiceAccess policy).
  Invoke-ValidateDeployment: verifies instance profile and both IAM roles exist and are attachable. Tags the
  iam CFT stack on success.

- s3-bucket (`Invoke-CreateS3Bucket`)
  Deploys s3-bucket.yaml CFT. Creates a private S3 bucket with BlockPublicAcls, IgnorePublicAcls,
  BlockPublicPolicy, and RestrictPublicBuckets all enabled. No public access of any kind.
  Invoke-ValidateDeployment: confirms bucket exists and GetBucketPublicAccessBlock returns all four
  block settings as true. Tags the s3-bucket CFT stack on success.

- secrets (`Invoke-CreateSecrets`)
  Uses the Secrets Manager GenerateRandomPassword endpoint to create secrets for: Managed AD admin password,
  ipscminet.com domain admin password, ipscminet.com Safe Mode Administrator password,
  pbs.ipscminet.com domain admin password, pbs.ipscminet.com Safe Mode Administrator password,
  non-administrator user password, and trust shared password. Secret ARNs are stored as SSM Parameter
  Store parameters for retrieval by instance scripts.

- upload-scripts (`Invoke-UploadHostScriptsToS3Bucket`)
  Enumerates all files under upload-scripts/instance/*/assets/ and uploads each to the S3 bucket under a
  key prefix matching the phase subfolder name. All instance scripts for the entire pipeline are sourced
  from this single folder.
  Invoke-ValidateDeployment: lists all expected S3 key prefixes and verifies each script exists in the
  bucket. Fails if any script is missing.

- managed-ad (`Invoke-DeployManagedAd`)
  Deploys managed-ad.yaml CFT. Creates the AWS Managed AD directory with DNS name test.ipscm and NetBIOS
  name TEST (Standard edition). Stack outputs the two Managed AD DNS IPs. After the stack completes,
  invokes Invoke-UpdateDhcpOptions to update the networking DHCP options set to use those DNS IPs.
  Invoke-ValidateDeployment: confirms directory status is Active via DescribeDirectories. Tags the
  managed-ad CFT stack on success.

- configure-managed-ad-gpo (`Invoke-ConfigureManagedAdGpo`)
  Host script: creates a Windows Server 2022 EC2 management instance via the EC2 API (not CFT), using the
  same IAM instance profile and security group as other instances. Uses user data to run a PowerShell script
  that domain-joins the instance to test.ipscm using the Managed AD admin credentials retrieved from
  Secrets Manager, then reboots. Stores the management instance ID in SSM Parameter Store for use by the
  teardown phase. Waits for SSM agent re-registration after the domain-join reboot before issuing Run Command.

  The management instance is stopped (not terminated) after this phase completes.

- rds (`Invoke-DeployRds`)
  Deploys rds.yaml CFT. Creates a DB subnet group using the private subnet. Creates a SQL Server RDS
  instance with Windows Authentication enabled (Domain set to the Managed AD directory ID,
  DomainIAMRoleName set to the IAM role from the iam phase). No public accessibility.
  Invoke-ValidateDeployment: confirms RDS instance status is available and DomainMemberships shows the
  Managed AD directory in a joined state. Tags the rds CFT stack on success.

- ec2-instances (`Invoke-DeployEc2Instances`)
  Deploys ec2-instances.yaml CFT. Creates 3 Windows Server 2022 instances, each attached to its
  pre-assigned ENI from the networking phase:
  - ipscminet-dc: forest root DC for ipscminet.com. Not domain joined at launch.
  - pbs-dc: child domain DC for pbs.ipscminet.com. Not domain joined at launch.
  - managed-member: joined to test.ipscm Managed AD at launch via the Domain CFT property. SQL 2019
    will be installed here.
  All instances use the IAM instance profile from the iam phase, the default security group, and the
  private subnet. Access is exclusively via Session Manager (no key pairs, no public IPs).
  Invoke-ValidateDeployment: verifies all 3 instances are in running state and registered with SSM.
  Tags the ec2-instances CFT stack on success.

- configure-ipscminet-dc (`Invoke-ConfigureIpscminetDc`)
  Host script waits for SSM agent registration on ipscminet-dc before issuing any Run Command.
  Pre-reboot: issues SSM Run Command with configure-ipscminet-dc-pre-reboot.ps1.
  Instance script (pre-reboot): disables Windows Firewall via Set-NetFirewallProfile. Overrides NIC DNS
  to point to itself. Installs AD-Domain-Services. Runs Install-ADDSForest to promote the server as the
  ipscminet.com forest root DC. The promotion triggers an automatic reboot.
  Host script waits for the instance to drop out of SSM and then re-register before issuing the next command.
  Post-reboot: issues SSM Run Command with configure-ipscminet-dc-post-reboot.ps1.
  Instance script (post-reboot): Adds a conditional forwarder for test.ipscm pointing at the Managed AD DNS IPs.

- configure-pbs-dc (`Invoke-ConfigurePbsDc`)
  Depends on configure-ipscminet-dc post-reboot being complete (ipscminet.com DNS must be available).
  Host script waits for SSM agent registration on pbs-dc.
  Pre-reboot: issues SSM Run Command with configure-pbs-dc-pre-reboot.ps1.
  Instance script (pre-reboot): disables Windows Firewall via Set-NetFirewallProfile. Points NIC DNS
  temporarily at ipscminet-dc. Installs AD-Domain-Services. Runs Install-ADDSDomain to create the pbs
  child domain under ipscminet.com. The promotion triggers an automatic reboot.
  Host script waits for the instance to drop out of SSM and re-register.
  Post-reboot: issues SSM Run Command with configure-pbs-dc-post-reboot.ps1.
  Instance script (post-reboot): switches NIC DNS to itself with ipscminet-dc as secondary. Adds a
  conditional forwarder for test.ipscm pointing at the Managed AD DNS IPs. Creates a non-administrator
  domain user in pbs.ipscminet.com.

- configure-trust (`Invoke-ConfigureTrust`)
  Host script: calls AWS DirectoryService API to add conditional forwarders in Managed AD for
  ipscminet.com (→ ipscminet-dc) and pbs.ipscminet.com (→ pbs-dc). Calls New-DSTrust to create a
  one-way outgoing trust from test.ipscm to pbs.ipscminet.com (pbs users can authenticate to test.ipscm
  resources). Waits for SSM registration on pbs-dc then downloads configure-trust-pbs-side.ps1 from S3
  via SSM Run Command.
  Instance script: adds the reciprocal incoming trust on the pbs.ipscminet.com side using netdom,
  retrieving the shared trust password from Secrets Manager.

- configure-managed-member (`Invoke-ConfigureManagedMember`)
  Host script waits for SSM agent registration on managed-member.
  Downloads configure-managed-member.ps1 from S3 via SSM Run Command.
  Instance script: disables Windows Firewall via Set-NetFirewallProfile. Downloads the SQL Server 2019 Developer installer directly from
  the internet (URL TBD — placeholder to be filled in before implementation). Installs SQL Server 2019 in
  quiet mode with Windows Authentication only. Creates the HelloWorld database. Creates a Windows
  Authentication login for the pbs non-administrator user. Grants that user db_datareader and db_datawriter
  on HelloWorld. Grants that user the Allow log on locally right via local security policy (secedit) — a
  cross-domain GPO from pbs.ipscminet.com cannot apply to machines in test.ipscm.

- teardown (`Invoke-Teardown`)
  Terminates EC2 instances (ipscminet-dc, pbs-dc, managed-member, management instance). Deletes CFT stacks
  in reverse order: ec2-instances, rds, managed-ad, s3-bucket (after emptying bucket), iam, networking.
  Deletes all Secrets Manager secrets created in the secrets phase. Deletes all SSM Parameter Store
  parameters created in the secrets phase. Deletes the pre-assigned ENIs if not automatically removed
  by the networking stack.
