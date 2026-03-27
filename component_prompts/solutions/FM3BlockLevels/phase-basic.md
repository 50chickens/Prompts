# Phase: basic

## Scope
Functional CI pipeline. Console app with list verb printing ASIO driver names.

## Implementation
Add AudioLevels.Simple.ConsoleApp and AudioLevels.Tests to solution.
Add Alsionyx.Library.NAudio.Asio to solution.
Change all existing projects from net10.0 to net9.0.
Add NuGet: NAudio to Alsionyx.Library.NAudio.Asio.
Add NuGet: CommandLineParser, Ipscm.Library.Logging to AudioLevels.Simple.ConsoleApp.
Add NuGet: NUnit, NSubstitute to AudioLevels.Tests.
Implement IAsioDeviceEnumerator. Stub IAsioOutputDevice and IAsioInputDevice.
Wire DI, list verb.

## Success Criteria
list verb prints ASIO driver names. Solution builds on CI. Zero test failures. 
