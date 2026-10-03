Plan: Minecraft Service CI Lifecycle
I read orchestration-script.md and inspected the solution at MineCraftManagementService.sln.

The recommended approach is a local-first Windows lifecycle pipeline using the prescribed structure:

ci.ps1 -> build-test.ps1 -> invoke-*

The pipeline should test the complete disposable service lifecycle:

Uninstall any previous test service
Build, format-check, and test the solution
Publish the service
Install it with automatic startup and recovery settings
Start and stop the Windows service
Start and monitor a controlled Minecraft server fixture
Check for an update using a local deterministic endpoint
Back up the existing server before patching
Apply the patch and restart the managed server
Verify logs, processes, ports, versions, and backup contents
Uninstall the test service and clean up all temporary resources
Implementation phases

Establish configuration and pipeline structure

Add ci/configs/*.json containing:

Solution path
Build configuration and verbosity
Publish directory
Isolated test installation directory
Test service name
Test server path and ports
Service startup/stop timeouts
RunIntegrationTests, defaulting to false
Whether the privileged deployment lifecycle is enabled
Add:

ci/ci.ps1
ci/build-test.ps1
ci/invoke-application-tests.ps1
ci/invoke-docker.ps1, initially a no-op
ci/invoke-deployment.ps1
ci/invoke-deployment-test.ps1
Any narrowly scoped files under ci/includes
Add deterministic unit and integration coverage

There is currently no test project. Add an NUnit test project to the solution using the repository’s testing conventions.

The highest-risk production areas are:

MineCraftServerService.cs
ServerLifecycleService.cs
ServerMonitoringService.cs
ServerUpdateService.cs
PreFlightCheckService.cs
WindowsBackgroundService.cs
Add test coverage for:

Options validation
Generic DI resolution
Service start and stop sequencing
Graceful shutdown followed by force-kill fallback
Preflight process and port handling
Monitoring cancellation
Update-check throttling
Microsoft endpoint success
Fallback endpoint selection
Unavailable or malformed external responses
Download failure
Backup failure
Extraction failure
Backup exclusions
Correct update ordering
Restart behavior
Update idempotence
Introduce only necessary test seams

The current implementation directly creates HttpClient, starts processes, accesses the filesystem, checks ports, and reads DateTime.UtcNow.

Introduce small abstractions only for external effects:

Process start, stop, lookup, and exit state
Filesystem access, copying, extraction, and deletion
HTTP version/download access
TCP port inspection
Clock or delay behavior where required for deterministic throttling tests
In particular, ServerUpdateService.cs should be adjusted so that:

Version responses use structured JSON parsing
Update failures are observable to the caller rather than only logged
A failed backup prevents extraction
The server is stopped before replacement
The server is restarted only when appropriate
A server that was stopped before patching is not unintentionally started afterward
A second check for the same version does not patch again
Startup cleanup in Program.cs should also be placed behind the process boundary so it can be tested without terminating unrelated local processes.

Build and test stage

build-test.ps1 should perform, in order:

Restore
dotnet format --verify-no-changes
Build
Unit tests
Publish the win-x64 artifact
The project currently targets net9.0-windows with Release single-file publishing. The README currently says .NET 10, so the project file should be treated as the source of truth and the documentation corrected.

Deployment stage

invoke-deployment.ps1 should:

Require an elevated PowerShell session
Confirm the test path is isolated from the real Minecraft installation
Stop and remove an existing test service instance
Copy or publish the service artifact
Prepare a controlled server fixture
Install the service
Configure automatic startup
Configure Windows Service recovery actions
Record the installed service state
The deployment must use a unique test service name and disposable server directory. It must refuse to proceed if it could affect the production service or existing Minecraft installation.

Deployed lifecycle test

invoke-deployment-test.ps1 should verify the deployed artifact without performing deployment changes:

Service starts successfully
Management service reaches the expected running state
Controlled Minecraft fixture process starts
Only one managed server process exists
Service stop shuts down the managed server
Update metadata is discovered from a local endpoint
Patch ZIP is downloaded from a local fixture
Backup exists before replacement
Excluded directories follow the intended policy
New version marker is installed
Managed server restarts after patching
Logs are created
Ports are released after shutdown
Service can be uninstalled cleanly
Reboot and recovery validation

Reboot testing should be an explicit, privileged mode rather than part of every ordinary run.

The pipeline should support:

Simulated service failure checks during normal local runs
Verification of Windows Service recovery settings
Optional real reboot on a disposable dedicated Windows machine
A continuation marker before reboot
Automatic continuation after reboot
Verification that the management service starts automatically
Verification that the managed server starts exactly once
Final cleanup and service uninstall
A real reboot must never run against a production Minecraft installation or a developer’s primary service instance.

Verification

Run ci.ps1 from an elevated PowerShell 7 session using a disposable server path.

Run the NUnit suite independently and confirm it performs no real network, service, reboot, or production filesystem operations.

Run the full local lifecycle twice to verify idempotent installation, update checks, and cleanup.

Force download, backup, and extraction failures and verify that the pipeline exits nonzero and does not continue patching.

Inspect the installed service and recovery settings with Windows service tooling.

Run the opt-in reboot mode only on a disposable dedicated Windows machine.

After C# changes, run:

dotnet format c:\git\internal\MineCraftManagementService\src\MineCraftManagementService.sln

Then rerun the pipeline’s format verification and test stages.

Important decisions

Local development is the first target; GitHub Actions wiring can follow once the local pipeline is reliable.
The default update tests use local HTTP and ZIP fixtures, not live Microsoft downloads.
Real Microsoft source checks may be added later as a separate non-blocking smoke test.
Docker is not required for this Windows service and remains a no-op unless a useful fixture requires it.
Windows Service recovery configuration must be explicitly installed and verified; start=auto alone does not prove crash recovery.
The current update service swallows exceptions, so update status must become observable before CI can reliably determine success or failure.