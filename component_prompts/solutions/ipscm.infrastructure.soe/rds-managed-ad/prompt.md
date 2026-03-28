We need to create an aws environment for testing the following scenarios

If i can log into a domain member of pbs.ipscminet.com and use either active directory credentials or IAM credentials to access a resource in the test.ipscm domain where test.ipscm has a one way trust to pbs.ipscminet.com.

constraints:
the scripts that we have setup here are to setup a test environment which mirrors our real one. As we are testing we want to focus on what is possible, not what we have setup correctly. Assume that whatever DNS for the scenario has been completed and the user will have access to the database. these are unimportant to the goal. 
assume that connectivity between the user and the MSSQL RDS instance is not a problem. ignore any DNS, Firewalls, or other connectivity problems. Assume that whatever DNS configruations are required to be done to support the authentication story that they have been completed.
Assume that the user has permissions to the database. 
for windows the user is logged onto a pbs.ipscminet.com domain joined windows device. 
for the mac user they will use pbs.ipscminet.com credentials (but use the kerberos/sso flow to get iam credentials).
We have setup an AWS SSO flow (this is already setup in the account that we will use to test the scenario). the authentication flow for that is under C:\git\internal\aws_scripts\aws\SSO\docs\identity-center-azure.
both windows & mac users have a pbs.ipscminet.com AD account and this allows them to SSO login to the AWS Account. we want to provision MSSQL based RDS and have the following scenarios we want to test. 

we have two slightly different scenarios: 
scenario 1. We are testing can a user on windows in a trusted domain account able to use a RDS (based on MSSQL) database where we have a managed active directory with a one way trust. 
scenario 2. We are testing can a user on mac authenticate to an RDS (based on MSSQL) database using Kerberos, where test.ipscm has a one-way trust to pbs.ipscminet.com. IAM credentials obtained via SSO are for AWS API calls only — SQL Server does not support IAM database authentication, so SQL connections must use Kerberos. The Mac user obtains a TGT for the pbs.ipscminet.com realm via kinit (krb5.conf configured for the PBS.IPSCMINET.COM realm with KDC pointing to pbs-dc). The SQL connection uses ODBC Driver 18 for SQL Server with Windows Authentication (Trusted_Connection=Yes). RDS resolves [PBS\<user>] via the one-way trust, identical to scenario 1. The same Windows Auth login provisioned in configure-managed-member is used for both scenarios — no additional SQL Server Auth login is required. 

both scenarios:
we are required to have a managed active directory. Both scenarios authenticate to RDS using Windows Authentication via Kerberos — Managed AD is required for RDS domain join and trust resolution in both cases. 
we are required to use RDS based MSSQL.
we are required that the user exists in pbs.ipscminet.com. even in scenario 1 the user will authenticate using kerberos where the credentials still originate from pbs.ipscminet.com 
we are required to have a one way trust. 
we are required to either 
    - apply permissions in the test.ipscm sql instance to the domain account of the pbs.ipscminet.com based user. 
    - apply iam permissions to the sql instance based on credentials. 
assume we have an alternate pipeline for creating databases and assigning windows permissions. these details are unimportant to the goal in this case. 

plan.md
Don't create example config files in the plan.md - just use a short annotation like: 
rds-managed-ad.local.json - contains configuration related to the rds-managed-ad service. 
use bullet points not numbered items so we don't need to renumber them if we add/remove steps. 

use a simplified structure for the deployment phases - eg instead of 

     ├── configure-ipscminet-dc\
    │   ├── invoke-deployment.ps1
    │   └── host\
    │
    ├── configure-pbs-dc\
    │   ├── invoke-deployment.ps1
    │   └── host\

we should use:

    ├── configure-ipscminet-dc\ (Invoke-ConfigureIpscminetDc)
    ├── configure-pbs-dc\  (Invoke-ConfigurePbsDc)

It is implied what the content of each folder is. eg we know that each of these folders will have an Invoke-Deployment.ps1 according to the orchestration script pattern. 

orchestration script constraints. 

During ci.ps1 we need to check for and remove any of the existing resources that are marked as failed, or have some kind of error condition. 
Add a validate-invoke-deployment function that provides a way to verify if the resource has been deployed or configured correctly. we should stop/fail the deployment at this point. This function should tag the cft  so that we can check for a successfully-configured tag to know that this aws resource is setup correctly. Apply the tag to the CFT that is used to deploy the resource not the resources themselves. 
Do not use cft outputs. If we need to resolve values in the host scripts where the value comes from from AWS we should query them at invoke-deployment.ps1 time. Each invoke-deployment.ps1 script should be atomic and not require values from prior scripts called from ci.ps1. This also applies to scripts that run inside the instance - eg instance scripts. 

if there are multiple times we need to execute a script on a host via SSM that should be a single Invoke-Deployment.ps1 script.  the reason why is so that we can execute them in sequence and fail at the correct time if need be. 


Script execution/validation constraints. 
Host script constraints. 
To know if a script on an instance has completed successfully for or not it should write progress/success/failure to cloud watch. see the cloudwatch section.
We should set tags on the CFT that contains the resources that the invoke-deployment.ps1 is touching. eg domain join pbs domain member should apply tag Status-Invoke-ConfigurePbsDc:
InProgress.
Completed.
Failed. 

this 1:1 tag match should be checked at the start of each invoke-deployment (the name of the stack should be in the config json file). 
this is so that 
* each invoke-deployment can know if any of the stacks are either
    ** failed (and should be removed and recreated), 
    ** in progress and can be resumed. eg if had an error checking the status of the CFT and need to resume the ci.ps1 but otherwise the instance script is progressing as normal. 
    ** successful and we can skip this step rather than just blindly deleting/recreating the resource. 
We should check cloudwatch to confirm if any errors not just check the CFT tag status. 

Instance scripts. 

All instance scripts need to know which cft tag they should write the status tag to. this is so that if we resume the ci.ps1 the invoke-deployment can correctly resume/take action. 
If an instance runs an instance script via SSM and that host needs to reboot it should write a cloudwatch log stream entry into the log stream prior to it rebooting. This script should then exit. The invoke-deployment.ps1 which is polling asynchronously should see this cloudwatch log stream entry and wait. when the next script is
host scripts. 
We should be watching cloudwatch log streams to know the status of each of the scripts that executing on the host. it can be one of these states:
InProgress.
Rebooting.
Completed.
Failed. 



Configuration constraints. 
There should be no hard coded values/magic strings in any of the instance or host scripts. 
For scripts that run on the instance but require configuration we can include a json file that uses the get-configuration pattern. We should upload this file to s3 in the configs folder under where all of the instance scripts are uploaded to. 
Where a script needs a runtime value (eg the ip address of the test.ipscm domain controller) then if possible we should be creating resources with a name that we have set in the json file. We should not derive it at runtime even if we are able to. to be clear - if we need a value of something and we can define the details of what we would need later - we should define it in the json file and the invoke-deployment.ps1 should use that configuration at runtime where possible. We should avoid deriving runtime values where possible. 

eg 

pbsDCEniIpAddress: 192.168.150.1 #included in the ENI creation script, the PBS DC creation script and the PBS member server script. eg define once, create with the required values, reference the configuration value many times. 

general.
All of this needs to be scripted. 
Use the remote host pattern where the scripts that execute on the host are not in the same folder as the ones that execute on the remote hosts. 
Use the orchestration-script pattern. 
the workflow should look like:
use the ci -> build-test -> invoke-deployment.ps1 pattern. 
there should be multiple DEPLOYMENT_FOLDER entries. these are:
DEPLOYMENT_FOLDER1\invoke-deployment.ps1. configures local environment to be able to use pwsh 7 aws modules for deploying CFT. 
DEPLOYMENT_FOLDER2\invoke-deployment.ps1. deploys cft containing s3 bucket for the purposes of holding all of the ec2 instance scripts. This needs to be a private s3 bucket with no public access. 
DEPLOYMENT_FOLDER3\invoke-deployment.ps1. collects all of the scripts needed to do the entire pipeline and uploads them to the s3 bucket. 

folder-structure constraints. 

in folder-structure there are instructions around using a Host and Instance pattern where the host folder is for scripts that will run on the host and instance is for scripts that will be executed on a remote host. for this particular test we should combine all of the scripts that are to be executed on remote hosts into the Invoke-UploadHostScriptsToS3Bucket phase folder. The reason why is so that they can be all grouped into a single set of folders and we do not need to enumerate a list of folders/files outside of the Invoke-UploadHostScriptsToS3Bucket folder. we still need to have a folder per phase under the Instance folder. 
to be clear - the only folder that should have an instances subfolder is the Invoke-UploadHostScriptsToS3Bucket folder as it will be the one that actually does the upload to s3. 

All scripts run on the instance should be run from c:\bootstrap\
All scripts run on the instance should write to cloudwatch. 

AWS cloudwatch.
all cloudwatch resources - log groups, log streams should be create if not exist. they should not be removed by any other process for any reason.
log streams should be date coded by a timestamp that is generated by ci.ps1 this is so that we can track a log stream to a particular invocation of ci.ps1.
log groups/streams should have a 7 day expiry.
Each log stream should be named with the phase - eg Invoke-ConfigurePbsDc. they should be named - TimeStamp-Phase. eg 202603281456-Invoke-ConfigurePbsDc (this represents 2:56PM 28th March 2026). 
The invoke-deployment.ps1 where it uses SSM to run an instance script should poll this cloudwatch stream for failures. 
the structure of cloudwatch logs is a json blob:

{
    "Level": "Info/Error"
    "Message: "Domain joined to pbs.ipscminet.com successfully/failed."
    "Exception": "full stack trace" #include meaningful/detailed errors here. powershell stack trace, http status codes, or other useful troubleshooting content. do not just write 'domain join failed'. 
    "Host": "ec2-xxxxx" #aws host
    "CFT" : "pbs.ipscminet.com" #name of the cft where the resource that created the log stream entry is.
    "Script": "full path name of the script that failed"
    "DeploymentScriptStatus": "one of InProgress/Rebooting/Completed/Failed" # the host script monitoring for ssm execution should be watching this json property.
}

The script that polls the cloudwatch log group should asynchronously poll the log group for progress indicators and completion/failures. 
All AWS resources that are in scope for running instance scripts will need access to create cloudwatch log groups and log streams and write data to it. 

AWS.
We should not remove any AWS resources that are not under scope of this testing for any reason whatsoever. 
Create only 1 vpc with 3 /24 subnets. one in each AZ. 
All machines should use dhcp options.
All aws resources should be private with no public or external internet access via AWS (eg IAM permissions/external/public s3 bucket urls) to any of them unless otherwise specified.
All resources in the vpc should have access to the internet. 
The VPC should not have any inbound connectivity from the internet except where the request was initated internally. use a transit gateway/nat setup to do this.
Enable AWS Session connect for windows servers. 
Create a single default security group which has allow 0.0.0.0/0. this is a testing setup where we don't want any firewall related complexity. Attach that to all ec2 instances. 
Give the ec2 instances iam permissions to access the s3 bucket. 
use the secrets manager generate secret endpoint to generate any password or credentials. 
Create pre-assigned ENIs for all of the ec2 domain members so that we if we need to rebuild then and they have configuration associated with them that is IP based (eg dns) it gets recreated with the same IP address.
The EC2 instance profile must include secretsmanager:GetSecretValue and ssm:GetParameter in addition to S3 and SSM Session Manager permissions. Instance scripts retrieve passwords from Secrets Manager and Secret ARNs from SSM Parameter Store.
The DHCP options set created in the networking phase must initially use AmazonProvidedDNS. It is updated to the Managed AD DNS IPs after the managed-ad phase completes. ipscminet-dc and pbs-dc instance scripts must override their NIC DNS immediately on boot because their DHCP-assigned DNS server will not resolve ipscminet.com or pbs.ipscminet.com before those domains are promoted.
Each configure-* host script must poll for SSM agent registration before issuing any Run Command. EC2 instances are not immediately registerd with SSM after launch. Use the SSM DescribeInstanceInformation API to wait until the instance is registered and shows as Online.
Add a Secrets Manager VPC endpoint (com.amazonaws.region.secretsmanager) to the networking CFT. Even with NAT available, keeping AWS API calls on the AWS network avoids any dependency on NAT availability for secret retrieval from instance scripts.
Do not hardcode Windows Server 2022 AMI IDs. Resolve them at deploy time via the SSM public parameter /aws/service/ami-windows-latest/Windows_Server-2022-English-Full-Base.
All resources in the VPC need outbound internet access (for downloading software, calling AWS public endpoints, etc). No inbound connectivity from the internet is permitted except for responses to requests initiated from within the VPC. Use an internet gateway and NAT gateway to achieve this. NAT gateways must be placed in a public subnet. A small public /28 subnet is required alongside the private /24 subnet to host the NAT gateway. The private subnet routes outbound traffic to the NAT gateway. All instances remain in the private subnet with no public IPs.
For CFT templates, resolve the Windows Server 2022 AMI ID using the CloudFormation dynamic reference syntax directly in the ImageId property: {{resolve:ssm:/aws/service/ami-windows-latest/Windows_Server-2022-English-Full-Base}}. No separate lookup step or parameter passing is required in the template.
EC2 seamless domain join requires an SSM State Manager Association.
The CI runner credentials (provided via environment variables and validated in env-setup) are assumed to have all AWS permissions required for host-side operations: CloudFormation (stack CRUD), EC2 (VPC/subnet/ENI/instance/security group/NAT/IGW management), IAM (role and instance profile CRUD), S3 (bucket and object management), SSM host-side (PutParameter, GetParameter, SendCommand, DescribeInstanceInformation, CreateAssociation, DeleteAssociation), SecretsManager (CreateSecret, DeleteSecret, GetSecretValue, GenerateRandomPassword), CloudWatchLogs read (GetLogEvents, FilterLogEvents, DescribeLogStreams, DescribeLogGroups), DirectoryService (CreateConditionalForwarder, CreateTrust, DescribeTrusts, DescribeDirectories, UpdateConditionalForwarder), and RDS (CreateDBInstance, DescribeDBInstances). This deployment does not provision the CI runner IAM principal.

AWS service requirements. 
A managed active directory service. The dns name is test.ipscm. the netbios name is TEST. It needs to have a one way trust to ipscminet.com. 

A SQL RDS instance which can uses the managed active directory service for it's authentication. 

Windows/Active Directory Constraints.

All windows servers should have firewalls turned off via the instance scripts.
Create a non administrator account on the pbs.ipscminet.com domain.
Instance scripts that trigger an OS reboot (domain controller promotion via Install-ADDSForest or Install-ADDSDomain) must be split into two scripts: a pre-reboot script and a post-reboot script. The host script must issue the pre-reboot SSM Run Command, wait for the instance to become unavailable to SSM (indicating the reboot has occurred), then wait for SSM re-registration before issuing the post-reboot Run Command.

AWS Domain join constraints.
The configure-trust host script must retrieve the shared trust password from Secrets Manager (via its SSM Parameter Store ARN) before calling New-DSTrust — the same secret used by the pbs-dc instance script on the reciprocal side. After the pbs-dc instance script completes, the host script must poll Get-DSTrust (DescribeTrusts) until TrustState equals Verified before the phase completes. configure-managed-member must not run until this is confirmed.

EC2 instances do not support a Domain CFT property (unlike AWS::RDS::DBInstance). SSM agent seamless domain join is used instead. After the managed-ad directory is created and the directory ID is known, the managed-ad host script must create a SecureString SSM Parameter Store parameter at the path /aws/directory-services/{directoryId}/joinDomain. The value must be JSON in the format {"username":"Admin@test.ipscm","password":"<plaintext>"}. The SSM agent on each EC2 instance reads this parameter at launch and joins the domain automatically. The ec2-instances CFT requires no Domain property — the SSM parameter and the instance profile's ssm:GetParameter permission are sufficient.

Install-ADDSForest and Install-ADDSDomain require a SafeModeAdministratorPassword. A separate secret must be generated in Secrets Manager for each domain's Safe Mode Administrator password. These are distinct from the domain admin passwords.

The /aws/directory-services/{directoryId}/joinDomain SSM Parameter Store parameter provides the credentials, but it does not trigger domain join on its own. The SSM agent only joins the domain when an SSM State Manager Association targets the instance with the AWS-JoinDirectoryServiceDomain document.
This Association must be created explicitly — it is not automatic. Only managed-member should receive this Association. ipscminet-dc and pbs-dc must not be associated with this document as they must boot unjoined and promote themselves as domain controllers. The Association should be created in the ec2-instances invoke-deployment.ps1 after the CFT stack completes, using the managed-member instance ID queried from the EC2 API.

sql constraints.
The RDS SQL Server instance must use Standard or Enterprise edition. Express edition does not support Managed Active Directory Windows Authentication. No option group configuration is required for SQL Server with AD authentication — the Domain and DomainIAMRoleName CFT properties are sufficient.
RDS domain join via the Domain CFT property is asynchronous. CloudFormation reports CREATE_COMPLETE when
the RDS instance reaches available status, which can occur before the domain join completes.
Invoke-ValidateDeployment for the rds phase must poll DescribeDBInstances.DomainMemberships until the
status is joined, not just check it once immediately after the stack completes.
The configure-managed-member phase is responsible for provisioning the HelloWorld database and the pbs user permissions on the RDS SQL Server. The configure-managed-member instance script retrieves the RDS master user credentials (username and password) from Secrets Manager and connects to the RDS endpoint using SQL Server Authentication as the master user. All T-SQL scaffolding (CREATE DATABASE HelloWorld, CREATE LOGIN [PBS\<user>] FROM WINDOWS, GRANT db_datareader and db_datawriter on HelloWorld to the pbs user) is executed under this single master-user connection. Only the sqlcmd standalone client and ODBC Driver for SQL Server are installed on managed-member — no SQL Server engine. The RDS endpoint hostname is read from rds-managed-ad.instance.json (no hardcoding).
Both scenario 1 (Windows, domain-joined device, automatic Kerberos) and scenario 2 (Mac, kinit-obtained TGT, ODBC Driver 18 Trusted_Connection=Yes) authenticate to RDS using Windows Authentication. No SQL Server Authentication login for the pbs user is provisioned — only the [PBS\<user>] Windows Auth login created in configure-managed-member is needed.

SSM Run Command script execution mechanism.
All configure-* phases use SSM Run Command with the AWS-RunPowerShellScript document to execute
scripts on instances. 
All instance scripts must run from c:\bootstrap\. 
Each SSM execution must first ensure PowerShell 7 is installed, the monolithic AWSPowerShell module is removed, and the minimum required AWS.Tools.* modules are installed under PS7 before the target script runs.
All instance scripts must be PS7 scripts and must use AWS.Tools.* modules, not the monolithic AWSPowerShell module. S3 reads from within instance scripts must use the AWS CLI (`aws s3 cp`), not AWS.Tools.S3. 
No hardcoded S3 bucket names or script key paths may appear in host scripts or instance scripts — all values come from rds-managed-ad.local.json.

EC2 domain join reboot polling.
When the configure-managed-member host script needs to wait for managed-member to be available, it must only poll SSM DescribeInstanceInformation until the instance shows as Online. It must not attempt to detect the domain join reboot cycle (i.e. wait for the instance to go offline then come back Online). The domain join reboot triggered by the SSM State Manager Association will have already completed by the time configure-managed-member runs, given the time taken by the preceding
configure-ipscminet-dc and configure-pbs-dc phases. Waiting for the instance to go offline would hang
indefinitely because the reboot is already done and the instance is already Online.

Phase status tracking — unified model.
The Status-{PhaseName} CFT tag model (InProgress/Completed/Failed) applies to all phases, not only
CFT-based ones. The mechanism varies by phase type:

CFT phases (networking, iam, s3-bucket, managed-ad, rds, ec2-instances): the invoke-deployment.ps1 host script applies the Status-{PhaseName} tag directly to the phase's own CFT stack — InProgress at the start of execution, Completed on success, Failed on unhandled error. The `successfully-configured = true` tag described earlier is superseded by Status-{PhaseName} = Completed. ci.ps1 reads this tag before each phase: Completed → skip; InProgress → inspect the CFT stack's own deployment status to determine if the stack is still deploying or if ci.ps1 crashed mid-wait, then resume or fail; Failed → delete the stack and retry.

Status tag value encoding for CloudWatch resume.
The Status-{PhaseName} tag value must encode the ci.ps1 run timestamp alongside the status so that on resume the correct CloudWatch log stream can be identified. 
The tag value format is {Status}:{Timestamp} (e.g. InProgress:202603281200). 
When ci.ps1 restarts and reads an InProgress tag from a configure-* phase, it parses the timestamp from the tag value and constructs the exact log stream name ({timestamp}-{phaseName}) to resume polling. The ci.ps1 run's own new timestamp is only used for any net-new CloudWatch log streams created in the current run. Completed and Failed tag values also encode the timestamp: Completed:202603281200 or Failed:202603281200. This applies to both CFT phase tags and configure-* phase tags on the ec2-instances stack. 
Non-CFT phase SSM Parameter Storestatus values follow the same format.


host inventory.
3 x Windows EC2 instances - 
a domain controller for ipscminet.com. this is the AD forest root. 
a domain controller for pbs.ipscminet.com. this is a child domain of ipscminet.com.
1 domain member of the managed active directory service (managed-member). Used as the SSM execution host for RDS provisioning — installs only the sqlcmd client and ODBC Driver, not a SQL Server engine. Runs T-SQL against the RDS endpoint as Local System (computer account) to create the HelloWorld database and provision the pbs user login.

things to look into. 

go and research best practises about building an aws vpc containing windows server - especially domain members. active directory has specific DNS requirements - eg domain members should have the domain controller set as their primary dns server which can be done via aws dhcp options. 

Rewrite the plan using phases. I have removed the plan.md. use the following naming convention/level of detail. the name of the phase should be the folder name under DEPLOYMENT_FOLDER.

Invoke-DeployNetworking. Deploy VPC and network resources.
Invoke-CreateS3Bucket. Deploy private S3 bucket CFT.
Invoke-UploadHostScriptsToS3Bucket. Uploads all scripts which will be executed on a host to a corrosponding s3 bucket folder. 
Invoke-DeployManagedAd. Deploy AWS Managed AD.

Do things in this order:
setup local environment.
deploy foundation aws network resources. eg vpc, subnets, r53 resolvers/dhcp options, security groups
deploy foundation aws iam policies. create 1 cft for all iam requirements unless it depends on a resource which isnt created yet.
deploy foundation aws non network resources - eg s3 buckets, ssm parameters/secrets. Each resource type should be it's own phase/folder.
deploy additional aws resources - eg managed active directory, RDS. Each resource type should be it's own phase. trusts etc do not need to be done yet. 
deploy domain controllers. Each different type of domain controller should be it's own step. trusts etc do not need to be done yet. 
#other resources/deployment steps.

additional requirements.


