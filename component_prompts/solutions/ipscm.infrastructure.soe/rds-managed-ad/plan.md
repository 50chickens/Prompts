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
    ├── env-setup\
    │   └── invoke-deployment.ps1
    │
    ├── networking\
    │   ├── invoke-deployment.ps1
    │   └── cft\
    │       └── networking.yaml
    │
    ├── iam\
    │   ├── invoke-deployment.ps1
    │   └── cft\
    │       └── iam.yaml
    │
    ├── s3-bucket\
    │   ├── invoke-deployment.ps1
    │   └── cft\
    │       └── s3-bucket.yaml
    │
    ├── secrets\
    │   └── invoke-deployment.ps1
    │
    ├── upload-scripts\                                            # all instance scripts live here
    │   ├── invoke-deployment.ps1
    │   └── instance\
    │       ├── configure-ipscminet-dc\
    │       │   └── assets\
    │       │       └── configure-ipscminet-dc.ps1
    │       ├── configure-pbs-dc\
    │       │   └── assets\
    │       │       └── configure-pbs-dc.ps1
    │       ├── configure-managed-ad-gpo\
    │       │   └── assets\
    │       │       └── configure-managed-ad-gpo.ps1
    │       ├── configure-trust\
    │       │   └── assets\
    │       │       └── configure-trust-pbs-side.ps1
    │       └── configure-managed-member\
    │           └── assets\
    │               └── configure-managed-member.ps1
    │
    ├── managed-ad\
    │   ├── invoke-deployment.ps1
    │   └── cft\
    │       └── managed-ad.yaml
    │
    ├── rds\
    │   ├── invoke-deployment.ps1
    │   └── cft\
    │       └── rds.yaml
    │
    ├── ec2-instances\
    │   ├── invoke-deployment.ps1
    │   └── cft\
    │       └── ec2-instances.yaml
    │
    ├── configure-ipscminet-dc\
    │   ├── invoke-deployment.ps1
    │   └── host\
    │
    ├── configure-pbs-dc\
    │   ├── invoke-deployment.ps1
    │   └── host\
    │
    ├── configure-managed-ad-gpo\
    │   ├── invoke-deployment.ps1
    │   └── host\
    │
    ├── configure-trust\
    │   ├── invoke-deployment.ps1
    │   └── host\
    │
    └── configure-managed-member\
        ├── invoke-deployment.ps1
        └── host\
```

## DNS and DHCP strategy

Windows AD has a strict requirement that domain members use the domain controller as their primary DNS server.
The VPC DHCP options set is pointed at the Managed AD DNS IPs. This means all machines that boot with default
DHCP will resolve test.ipscm. The ipscminet-dc and pbs-dc instance scripts must override their NIC DNS to
point to themselves early in execution (before domain promotion) since the Managed AD DNS cannot resolve
ipscminet.com or pbs.ipscminet.com until those domains exist and conditional forwarders are in place.
Managed AD is configured with conditional forwarders for ipscminet.com and pbs.ipscminet.com pointing at their
respective DC IPs. This allows the managed-member (which uses DHCP → Managed AD DNS) to resolve all domains
in the environment.

## phases

- env-setup (`Invoke-SetupLocalEnvironment`)
  Installs AWS.Tools modules (Common, CloudFormation, S3, EC2, DirectoryService, RDS, SSM, SecretsManager)
  into PS_MODULES_ENABLED. Configures a custom AWS config folder. Validates AWS credentials are available
  via environment variables.

- networking (`Invoke-DeployNetworking`)
  Deploys networking.yaml CFT. Creates 1 VPC with a single /24 subnet (no internet gateway, no NAT gateway).
  Creates pre-assigned ENIs for ipscminet-dc, pbs-dc, and managed-member with fixed private IPs so that if
  any instance is rebuilt it retains the same IP address (important for DNS conditional forwarder configuration).
  Creates a default security group allowing all traffic (0.0.0.0/0 ingress and egress) attached to all EC2
  instances. Creates VPC endpoints for SSM, SSMMessages, EC2Messages, and S3 so that Session Manager and S3
  access function without internet egress. Creates a DHCP options set pointed at the Managed AD DNS IPs;
  this is updated after the managed-ad phase outputs the DNS IPs (Invoke-UpdateDhcpOptions).

- iam (`Invoke-DeployIam`)
  Deploys iam.yaml CFT. Creates an EC2 instance profile granting s3:GetObject and s3:ListBucket on the
  script S3 bucket, and ssm:* permissions for Session Manager. Creates the IAM role required for RDS to
  join the Managed AD directory (AmazonRDSDirectoryServiceAccess policy).

- s3-bucket (`Invoke-CreateS3Bucket`)
  Deploys s3-bucket.yaml CFT. Creates a private S3 bucket with BlockPublicAcls, IgnorePublicAcls,
  BlockPublicPolicy, and RestrictPublicBuckets all enabled. No public access of any kind.

- secrets (`Invoke-CreateSecrets`)
  Uses the Secrets Manager GenerateRandomPassword endpoint to create secrets for: Managed AD admin password,
  ipscminet.com domain admin password, pbs.ipscminet.com domain admin password, non-administrator user
  password, and trust shared password. Secret ARNs are written as SSM parameters for retrieval by
  subsequent phases.

- upload-scripts (`Invoke-UploadHostScriptsToS3Bucket`)
  Enumerates all files under upload-scripts/instance/*/assets/ and uploads each to the S3 bucket under a
  key prefix matching the phase subfolder name (e.g. configure-ipscminet-dc/configure-ipscminet-dc.ps1).
  All instance scripts for the entire pipeline are sourced from this single folder.

- managed-ad (`Invoke-DeployManagedAd`)
  Deploys managed-ad.yaml CFT. Creates the AWS Managed AD directory with DNS name test.ipscm and NetBIOS
  name TEST (Standard edition). Stack outputs the two Managed AD DNS IPs. After the stack completes,
  invokes Invoke-UpdateDhcpOptions to attach those DNS IPs to the networking DHCP options set.

- configure-managed-ad-gpo (`Invoke-ConfigureManagedAdGpo`)
  Deploys a temporary Windows Server 2022 EC2 management instance joined to the test.ipscm Managed AD
  domain. Downloads configure-managed-ad-gpo.ps1 from S3 via SSM Run Command and executes it.
  Instance script: uses the ActiveDirectory and GroupPolicy PowerShell modules to create a GPO in
  test.ipscm that disables the Windows Firewall (all profiles) and links it to the domain root. This
  GPO applies to all current and future machines joined to test.ipscm including managed-member.
  The management instance may be left running or stopped after this phase completes.

- rds (`Invoke-DeployRds`)
  Deploys rds.yaml CFT. Creates a DB subnet group using the private subnet. Creates a SQL Server RDS
  instance with Windows Authentication enabled (Domain set to the Managed AD directory ID,
  DomainIAMRoleName set to the IAM role from the iam phase). No public accessibility.

- ec2-instances (`Invoke-DeployEc2Instances`)
  Deploys ec2-instances.yaml CFT. Creates 3 Windows Server 2022 instances, each attached to its
  pre-assigned ENI from the networking phase:
  - ipscminet-dc: forest root DC for ipscminet.com. Not domain joined at launch.
  - pbs-dc: child domain DC for pbs.ipscminet.com. Not domain joined at launch.
  - managed-member: joined to test.ipscm Managed AD at launch via the Domain CFT property. SQL 2019
    will be installed here.
  All instances use the IAM instance profile from the iam phase, the default security group, and the
  private subnet. Access is exclusively via Session Manager (no key pairs, no public IPs).

- configure-ipscminet-dc (`Invoke-ConfigureIpscminetDc`)
  Downloads configure-ipscminet-dc.ps1 from S3 via SSM Run Command and executes it on ipscminet-dc.
  Instance script: disables Windows Firewall immediately via Set-NetFirewallProfile (before any domain
  exists). Overrides NIC DNS to point to itself. Installs AD-Domain-Services. Promotes the server as
  the forest root DC for ipscminet.com using Install-ADDSForest. After promotion, creates and links a
  GPO at the ipscminet.com domain root that disables Windows Firewall for all domain members. Adds a
  conditional forwarder for test.ipscm pointing at the Managed AD DNS IPs. Reboots as part of promotion.

- configure-pbs-dc (`Invoke-ConfigurePbsDc`)
  Downloads configure-pbs-dc.ps1 from S3 via SSM Run Command and executes it on pbs-dc.
  Instance script: disables Windows Firewall immediately via Set-NetFirewallProfile. Temporarily points
  NIC DNS at ipscminet-dc. Installs AD-Domain-Services. Creates the pbs child domain under ipscminet.com
  using Install-ADDSDomain. After promotion, switches NIC DNS to itself with ipscminet-dc as secondary.
  Adds a conditional forwarder for test.ipscm pointing at the Managed AD DNS IPs. Creates and links a
  GPO at the pbs.ipscminet.com domain root that disables Windows Firewall for all domain members. Creates
  a non-administrator domain user in pbs.ipscminet.com. Grants that user Allow log on locally rights on
  the managed-member server via a GPO linked at the pbs.ipscminet.com domain. Reboots as part of promotion.

- configure-trust (`Invoke-ConfigureTrust`)
  Host script: calls AWS DirectoryService API to add conditional forwarders in Managed AD for
  ipscminet.com (→ ipscminet-dc) and pbs.ipscminet.com (→ pbs-dc). Calls New-DSTrust to create a
  one-way outgoing trust from test.ipscm to pbs.ipscminet.com (direction: One-Way: Outgoing means
  pbs users can authenticate to test.ipscm resources).
  Downloads configure-trust-pbs-side.ps1 from S3 via SSM Run Command and executes it on pbs-dc.
  Instance script: adds the reciprocal incoming trust on the pbs.ipscminet.com side using netdom,
  retrieving the shared trust password from Secrets Manager.

- configure-managed-member (`Invoke-ConfigureManagedMember`)
  Downloads configure-managed-member.ps1 from S3 via SSM Run Command and executes it on managed-member.
  Instance script: disables Windows Firewall immediately via Set-NetFirewallProfile (the test.ipscm GPO
  from configure-managed-ad-gpo will also apply via Group Policy refresh). Downloads the SQL Server 2019
  Developer installer from S3 (cached in S3 bucket). Installs SQL Server 2019 in quiet mode with Windows
  Authentication only. Creates the HelloWorld database. Creates a Windows Authentication login for the
  pbs non-administrator user. Grants that user db_datareader and db_datawriter on HelloWorld.
