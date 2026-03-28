We need to create an aws environment for testing the following scenarios

If i can log into a domain member of pbs.ipscminet.com and use either active directory credentials or IAM credentials to access a resource in the test.ipscm domain where test.ipscm has a one way trust to pbs.ipscminet.com.

constraints:

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

onchestration script constraints. 

During ci.ps1 we need to check for and remove any of the existing resources that are marked as failed, or have some kind of error condition. 
Add a validate-invoke-deployment function that provides a way to verify if the resource has been deployed or configured correctly. we should stop/fail the deployment at this point. This function should tag the cft  so that we can check for a successfully-configured tag to know that this aws resource is setup correctly. Apply the tag to the CFT that is used to deploy the resource not the resources themselves. 

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

AWS.
Create only 1 vpc with 1 /24 subnet. 
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
The management EC2 instance ID is not tracked by any CFT stack. The host script in configure-managed-ad-gpo must store the instance ID in SSM Parameter Store immediately after creation so that the teardown phase can retrieve it and terminate the instance.
All resources in the VPC need outbound internet access (for downloading software, calling AWS public endpoints, etc). No inbound connectivity from the internet is permitted except for responses to requests initiated from within the VPC. Use an internet gateway and NAT gateway to achieve this. NAT gateways must be placed in a public subnet. A small public /28 subnet is required alongside the private /24 subnet to host the NAT gateway. The private subnet routes outbound traffic to the NAT gateway. All instances remain in the private subnet with no public IPs.

AWS service requirements. 
A managed active directory service. The dns name is test.ipscm. the netbios name is TEST. It needs to have a one way trust to ipscminet.com. 

A SQL RDS instance which can uses the managed active directory service for it's authentication. 

Windows/Active Directory Constraints.

All windows servers should have firewalls turned off via the instance scripts.
Create a non administrator account on the pbs.ipscminet.com domain.
the domain member needs to have sql 2019 installed. 
the sql 2019 server needs to have a helloworld database created. 
the non administrator user needs to be able to log onto the pbs.ipscminet.com domain member server and be able to access the sql 2019 helloworld database. 
you need to give the non administrator user logon access to the pbs.ipscminet.com domain member server. 
Instance scripts that trigger an OS reboot (domain controller promotion via Install-ADDSForest or Install-ADDSDomain) must be split into two scripts: a pre-reboot script and a post-reboot script. The host script must issue the pre-reboot SSM Run Command, wait for the instance to become unavailable to SSM (indicating the reboot has occurred), then wait for SSM re-registration before issuing the post-reboot Run Command.
The Allow log on locally right for the pbs non-administrator user on managed-member must be applied on managed-member itself via local security policy. A GPO linked at the pbs.ipscminet.com domain does not apply to machines in test.ipscm. This must be done in the configure-managed-member instance script.

secrets for DC promotion.
Install-ADDSForest and Install-ADDSDomain require a SafeModeAdministratorPassword. A separate secret must be generated in Secrets Manager for each domain's Safe Mode Administrator password. These are distinct from the domain admin passwords.

Management EC2 constraints.
The management EC2 created in the configure-managed-ad-gpo phase cannot use the CFT Domain property because it is created via the EC2 API. Domain join must be performed via user data: a PowerShell script in user data retrieves the Managed AD admin credentials from Secrets Manager and calls Add-Computer to join the machine to test.ipscm, then reboots. The host script must wait for SSM re-registration after this reboot before issuing any Run Command.

sql constraints. 
the domain member that needs SQL should download it directly from the internet. we don't need to know the url/process for this right now. use a placeholder where we will fill it in later. 

host inventory.
3 x Windows EC2 instances - 
a domain controller for ipscminet.com. this is the AD forest root. 
a domain controller for pbs.ipscminet.com. this is a child domain of ipscminet.com.
1 domain member of the managed active directory service. we will install SQL here and create a helloworld database. 

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
