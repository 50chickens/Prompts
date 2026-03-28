# todo: rds-managed-ad

rewrite the following. it was added to the prompt.md doc. 

it clearly has implementation details. not a list of constraints or things we must or must not do. 
don't include things we have considered but have ruled out. 
also - is AWS-RunRemoteScript better than AWS-RunPowerShellScript for this? 


--- taken from prompt.md. 


SSM Run Command via AWS-RunPowerShellScript is the correct mechanism for all configure-* phases.
It enables ad-hoc, ci.ps1-orchestrated, sequenced script execution with synchronous command tracking.
Lambda is not suitable — it adds indirection with no benefit since ci.ps1 already IS the orchestrator
and Lambda is designed for event-driven (not ad-hoc sequential) invocations. EC2 UserData/instance
metadata seeding is not suitable for configure-* phases because UserData only runs once at first
launch and cannot be re-triggered for post-launch sequenced configuration. SSM State Manager
Associations are for ongoing compliance automation, not one-time sequenced deployment. No custom SSM
documents are needed — AWS-RunPowerShellScript and AWS-JoinDirectoryServiceDomain are both
AWS-managed and always available.

All "Issues SSM Run Command" steps in configure-* invoke-deployment.ps1 scripts send an inline
bootstrap block via AWS-RunPowerShellScript (which executes under powershell.exe 5.1). The inline:
uses aws cli to get bootstrap scripts from s3. 
completely removes older aws powershell modules.
installs powershell 7.
install minimum modern aws AWS.Tools.* modules. 

The S3 bucket name and object keys are embedded into the inline by the host script from values in
rds-managed-ad.local.json — no hardcoded paths in host scripts.

AWS-RunRemoteScript is not used because it downloads scripts to an SSM-managed temp directory, not
c:\bootstrap\, which violates the execution directory constraint.

EC2 domain join reboot polling.
When the configure-managed-member host script needs to wait for managed-member to be available,
it must only poll SSM DescribeInstanceInformation until the instance shows as Online. It must not
attempt to detect the domain join reboot cycle (i.e. wait for the instance to go offline then come
back Online). The domain join reboot triggered by the SSM State Manager Association will have already
completed by the time configure-managed-member runs, given the time taken by the preceding
configure-ipscminet-dc and configure-pbs-dc phases. Waiting for the instance to go offline would hang
indefinitely because the reboot is already done and the instance is already Online.

Phase status tracking — unified model.
The Status-{PhaseName} CFT tag model (InProgress/Completed/Failed) applies to all phases, not only
CFT-based ones. The mechanism varies by phase type:

CFT phases (networking, iam, s3-bucket, managed-ad, rds, ec2-instances): the invoke-deployment.ps1
host script applies the Status-{PhaseName} tag directly to the phase's own CFT stack — InProgress at
the start of execution, Completed on success, Failed on unhandled error. The `successfully-configured
= true` tag described earlier is superseded by Status-{PhaseName} = Completed. ci.ps1 reads this tag
before each phase: Completed → skip; InProgress → inspect the CFT stack's own deployment status to
determine if the stack is still deploying or if ci.ps1 crashed mid-wait, then resume or fail; Failed →
delete the stack and retry.

Configure-* phases (configure-ipscminet-dc, configure-pbs-dc, configure-trust,
configure-managed-member): these phases have no CFT stack of their own. The Status-{PhaseName} tag is
applied to the ec2-instances CFT stack (the stack that owns the relevant EC2 instances). The host
script writes InProgress at the start, Completed on success, Failed on error. When ci.ps1 finds a
configure-* tag in InProgress state on the ec2-instances stack, it must cross-check the CloudWatch log
stream for that phase to determine actual state: if the latest DeploymentScriptStatus is Completed →
update the tag to Completed and skip; if Failed → update tag to Failed and handle; if InProgress or
Rebooting → resume CloudWatch polling from where it left off. The CFT stack name used for configure-*
tags is defined in rds-managed-ad.local.json so no hardcoded stack names appear in host scripts.

Non-CFT phases (secrets, upload-scripts): these phases have no CFT stack of any kind to tag. Phase
status is written to SSM Parameter Store at a path defined in rds-managed-ad.local.json (e.g.
/rds-managed-ad/phase-status/InvokeCreateSecrets). ci.ps1 reads this parameter at the start of each
non-CFT phase: Completed → skip; InProgress or Failed → re-run the phase (these phases are
idempotent). The SSM Parameter Store paths for phase status must be defined in rds-managed-ad.local.json.

env-setup is idempotent and fast (local PowerShell module installation only). No AWS state tracking is
required — it always runs and has no side effects on re-run.

SQS and SNS are not suitable alternatives for phase state tracking. SQS messages are consumed and
deleted when read — they do not persist queryable state across ci.ps1 restarts. SNS is a
fire-and-forget notification system with no durable state. Neither can be queried after a ci.ps1 crash
to determine what actually happened. CFT tags, CloudWatch, and SSM Parameter Store are all durable,
immediately queryable, and already required by this deployment — no additional AWS service is needed.

Status tag value encoding for CloudWatch resume.
The Status-{PhaseName} tag value must encode the ci.ps1 run timestamp alongside the status so that on
resume the correct CloudWatch log stream can be identified. The tag value format is
{Status}:{Timestamp} (e.g. InProgress:202603281200). When ci.ps1 restarts and reads an InProgress tag
from a configure-* phase, it parses the timestamp from the tag value and constructs the exact log
stream name ({timestamp}-{phaseName}) to resume polling. The ci.ps1 run's own new timestamp is only
used for any net-new CloudWatch log streams created in the current run. Completed and Failed tag values
also encode the timestamp: Completed:202603281200 or Failed:202603281200. This applies to both CFT
phase tags and configure-* phase tags on the ec2-instances stack. Non-CFT phase SSM Parameter Store
status values follow the same format.
