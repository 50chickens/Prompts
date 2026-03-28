## pre-assigned-eni

Create Elastic Network Interfaces (ENIs) as standalone resources before EC2 instances are launched, then attach each instance to its pre-assigned ENI at launch. This gives each instance a fixed, known private IP address that survives instance termination and recreation.

## Why

EC2 instances are assigned a private IP address at launch from the subnet pool. If an instance is terminated and replaced the new instance gets a different IP. Any configuration that references the old IP — DNS conditional forwarders, NIC DNS overrides, static forwarder entries on other hosts — is now broken.

Pre-assigning ENIs decouples the IP address from the instance lifecycle. The ENI persists after the instance is terminated. When the replacement instance attaches to the same ENI it gets the same IP address and all configuration referencing that IP remains valid without changes.

This matters most for domain controllers and other hosts that are registered by IP in DNS or AD conditional forwarders, and for any host that is referenced by IP in a configuration file that would be expensive to regenerate.

## How

Create ENIs in the networking CFT as `AWS::EC2::NetworkInterface` resources with a fixed `PrivateIpAddress`. One ENI per instance. No instance is created yet.

Define all ENI IP addresses in the configuration JSON file, not as CFT parameters or outputs. Every script that needs the IP reads it from the same configuration value.

```json
{
  "ipscminetDcEniPrivateIp": "192.168.10.10",
  "pbsDcEniPrivateIp":       "192.168.10.11",
  "managedMemberEniPrivateIp": "192.168.10.12"
}
```

In the EC2 CFT, attach each instance to its ENI using `NetworkInterfaces` rather than `SubnetId` + `SecurityGroupIds`. Do not set `SubnetId` at the instance level when using a pre-assigned ENI — the subnet and security group are inherited from the ENI.

```yaml
# networking.yaml — create the ENI
IpscminetDcEni:
  Type: AWS::EC2::NetworkInterface
  Properties:
    SubnetId: !Ref PrivateSubnetAz1
    PrivateIpAddress: "192.168.10.10"
    GroupSet:
      - !Ref DefaultSecurityGroup
```

```yaml
# ec2-instances.yaml — attach at launch
IpscminetDc:
  Type: AWS::EC2::Instance
  Properties:
    NetworkInterfaces:
      - NetworkInterfaceId: <eni-id queried at deploy time from EC2 API>
        DeviceIndex: "0"
```

The ENI ID is not a CFT output. The invoke-deployment.ps1 for the ec2-instances phase queries the ENI ID at deploy time using the EC2 `DescribeNetworkInterfaces` API, filtering by the fixed private IP address defined in the configuration file. It then passes the ID as a CFT parameter to `ec2-instances.yaml`.

## Rules

- **ENIs live in the networking CFT.** They must be created before any EC2 instance CFT is deployed. Teardown deletes the EC2 instance CFT first; the networking CFT (and its ENIs) is deleted last.
- **All IP addresses are defined in the configuration JSON.** The same value is used when creating the ENI, when configuring DNS forwarders, when overriding NIC DNS on instance scripts, and anywhere else the IP is needed. Define once, reference many times.
- **Do not use CFT outputs to pass ENI IDs.** Query the ENI ID at deploy time in invoke-deployment.ps1 using `DescribeNetworkInterfaces` filtered by private IP.
- **One ENI per instance.** Do not reuse an ENI across instances.
- **Do not set SubnetId at the instance level.** When `NetworkInterfaces` is specified, subnet and security group membership come from the ENI.

## Teardown

ENIs attached to a running instance are released automatically when the instance is terminated. The ENI resource in the networking CFT stack is deleted when that stack is deleted. Delete the EC2 instance stack before the networking stack. If an ENI is not released cleanly (e.g. the instance was force-terminated), explicitly detach it before deleting the networking stack.
