# todo: rds-managed-ad

- End-to-end smoke test. The purpose of the environment is to verify a pbs domain user can authenticate
  to a test.ipscm resource. There is no defined phase or verification step that tests this in the plan.
  Decide whether to add a dedicated smoke-test phase or fold it into configure-managed-member validation.
  The challenge: the instance script runs as SYSTEM. One option is to use Start-Process with a PSCredential
  for the pbs user to launch sqlcmd in that user's context and verify connectivity to the HelloWorld
  database on managed-member. Decide on approach before implementation.

- managed-member seamless domain join reboot not handled in configure-managed-member. When managed-member
  launches, the SSM agent reads the /aws/directory-services/{directoryId}/joinDomain SSM parameter and
  initiates a domain join, which causes an OS reboot. The configure-managed-member host script currently
  only polls for SSM agent registration before issuing Run Command. If it catches the pre-domain-join
  SSM registration (before the reboot), it will issue Run Command too early — before the domain join has
  completed. The configure-managed-member host script must follow the same pattern as the DC promotions:
  wait for the initial SSM registration, then wait for the instance to go offline (the domain join
  reboot), then wait for SSM re-registration before issuing Run Command.
