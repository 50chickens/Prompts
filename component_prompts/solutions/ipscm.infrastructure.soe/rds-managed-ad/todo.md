# todo: rds-managed-ad

- EC2 seamless domain join mechanism and SSM parameter. The ec2-instances phase states managed-member
  joins test.ipscm "via the Domain CFT property" — this property does not exist on AWS::EC2::Instance
  (it exists on AWS::RDS::DBInstance but not EC2). EC2 seamless domain join is triggered by the SSM
  agent reading the Managed AD admin credentials from a specific SSM Parameter Store path
  (/aws/directory-services/{directoryId}/joinDomain) in a specific JSON format. The managed-ad phase
  must create this SSM parameter after the directory ID is known. The ec2-instances phase description
  must be corrected to describe the actual mechanism (SSM agent seamless join, not a CFT property).

- RDS option group. RDS SQL Server with Windows Authentication may require a specific option group
  configuration in addition to the Domain and DomainIAMRoleName CFT properties. Investigate whether an
  explicit option group is required and what options must be enabled for AD authentication to work.

- Windows AMI ID resolution. Both ec2-instances and configure-managed-ad-gpo create Windows Server 2022
  instances. Neither phase currently documents resolving the AMI ID at deploy time via the SSM public
  parameter /aws/service/ami-windows-latest/Windows_Server-2022-English-Full-Base. Update both phases in
  plan.md to reference this and confirm how it is passed to the CFT and EC2 API call respectively.

- End-to-end smoke test phase. The purpose of the environment is to verify a pbs domain user can
  authenticate to a test.ipscm resource. There is no defined phase or verification step that tests this
  in the plan. Decide whether to add a dedicated smoke-test phase or fold it into configure-managed-member
  validation. The test should confirm the pbs non-admin user can connect to the HelloWorld SQL database
  using domain credentials from managed-member.

- Managed AD DNS IPs not propagated to instance scripts. The managed-ad host script uses the two Managed
  AD DNS IPs to update DHCP options via Invoke-UpdateDhcpOptions but never persists them to SSM Parameter
  Store. The configure-ipscminet-dc and configure-pbs-dc post-reboot instance scripts both add a
  conditional forwarder for test.ipscm pointing at those IPs but have no documented way to know what
  those IPs are. The managed-ad host script must write the DNS IPs to SSM Parameter Store after the
  stack completes so that instance scripts can retrieve them at runtime.

- configure-trust CreateTrust must use shared trust password from Secrets Manager. The configure-trust
  host script calls the AWS DirectoryService CreateTrust API (New-DSTrust) to create the trust on the
  Managed AD side. This call requires a trust password. The plan documents the pbs-dc instance script
  retrieving the shared trust password from Secrets Manager, but does not state that the host-side
  CreateTrust call does the same. Both sides must use the same password from the same Secrets Manager
  secret.

- configure-trust must poll for trust verification before completing. New-DSTrust (CreateTrust API) is
  asynchronous. The plan has no step to wait for the trust status to reach Verified after the API call
  returns. configure-managed-member's SQL login creation for the pbs non-admin user will fail if
  configure-managed-member runs before the trust is fully active. The configure-trust host script must
  poll DescribeDirectories or DescribeTrusts until trust status is Verified before completing.

- configure-managed-ad-gpo phase has no remaining purpose. After removing GPO work, this phase only
  creates a management EC2, domain-joins it via user data, stores the instance ID in SSM Parameter Store,
  waits for SSM re-registration, then stops the instance. There are no instance scripts and no Run
  Command to issue. The phase description says "waits for SSM re-registration before issuing Run Command"
  but nothing is issued. Determine whether this phase and management instance are still needed for any
  other purpose, or whether the phase should be removed and the management instance ID storage handled
  differently (e.g. the instance ID is not needed if there is no management instance).

- RDS SQL Server edition must be Standard or Enterprise. AWS RDS SQL Server with Managed AD Windows
  Authentication is not supported on Express edition. The rds phase does not specify the edition. It
  must be explicitly set to Standard or Enterprise in the rds.yaml CFT.
