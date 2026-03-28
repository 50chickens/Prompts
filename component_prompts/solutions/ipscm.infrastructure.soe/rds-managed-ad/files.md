# File Listing — rds-managed-ad

```
ci/
├── ci.ps1                                                              orchestrates all phases in sequence
├── build-test.ps1                                                      no-op CI shim
└── configs/
    └── rds-managed-ad.local.json                                       all host-side configuration values

src/
├── env-setup/
│   └── invoke-deployment.ps1                                           installs AWS.Tools modules, validates credentials
│
├── networking/
│   ├── invoke-deployment.ps1                                           deploys VPC, subnets, NAT, ENIs, VPC endpoints
│   └── cft/networking.yaml                                             CFT: VPC + all networking resources
│
├── iam/
│   ├── invoke-deployment.ps1                                           deploys EC2 instance profile and RDS directory role
│   └── cft/iam.yaml                                                    CFT: EC2 instance profile + RDS AD role
│
├── s3-bucket/
│   ├── invoke-deployment.ps1                                           deploys private S3 bucket
│   └── cft/s3-bucket.yaml                                             CFT: private S3 bucket
│
├── secrets/
│   └── invoke-deployment.ps1                                           creates 8 secrets in Secrets Manager
│
├── upload-scripts/
│   ├── invoke-deployment.ps1                                           uploads all instance scripts and config to S3
│   ├── configs/
│   │   └── rds-managed-ad.instance.json                               all instance-side configuration values
│   └── instance/
│       ├── bootstrap/assets/
│       │   └── bootstrap.ps1                                           installs PS7 and AWS.Tools on EC2 instances
│       ├── configure-ipscminet-dc/assets/
│       │   ├── configure-ipscminet-dc-pre-reboot.ps1                  promotes ipscminet.com forest root DC
│       │   └── configure-ipscminet-dc-post-reboot.ps1                 adds conditional forwarder for test.ipscm
│       ├── configure-pbs-dc/assets/
│       │   ├── configure-pbs-dc-pre-reboot.ps1                        promotes pbs.ipscminet.com child domain
│       │   └── configure-pbs-dc-post-reboot.ps1                       configures DNS, forwarder, creates pbs user
│       ├── configure-trust/assets/
│       │   └── configure-trust-pbs-side.ps1                           adds reciprocal incoming trust on pbs-dc
│       └── configure-managed-member/assets/
│           └── configure-managed-member.ps1                            provisions HelloWorld DB and pbs login on RDS
│
├── managed-ad/
│   ├── invoke-deployment.ps1                                           deploys Managed AD, updates DHCP, creates join param
│   └── cft/managed-ad.yaml                                            CFT: AWS Managed AD test.ipscm
│
├── rds/
│   ├── invoke-deployment.ps1                                           deploys RDS, polls until domain joined
│   └── cft/rds.yaml                                                    CFT: SQL Server RDS with Windows Authentication
│
├── ec2-instances/
│   ├── invoke-deployment.ps1                                           deploys 3 EC2 instances, creates domain join Association
│   └── cft/ec2-instances.yaml                                         CFT: 3× Windows Server 2022
│
├── configure-ipscminet-dc/
│   └── invoke-deployment.ps1                                           orchestrates ipscminet.com DC installation
│
├── configure-pbs-dc/
│   └── invoke-deployment.ps1                                           orchestrates pbs.ipscminet.com DC installation
│
├── configure-trust/
│   └── invoke-deployment.ps1                                           creates one-way trust, polls until Verified
│
├── configure-managed-member/
│   └── invoke-deployment.ps1                                           runs RDS provisioning script on managed-member
│
└── teardown/
    └── invoke-deployment.ps1                                           deletes all resources in reverse order
```
