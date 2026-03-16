
## C# Unit & Integration Testing guidelines.
Use NUnit and NSubstitute for testing frameworks. 
use [TestCases] where possible.

Create a DependencyResolverTest unit test to verify the DI container can resolve all services. make this generic so that it if we add additional dependencies that will automatically be in scope to ensure they can be resolved.
Use GetNunitTestLoggerContext to create a _log and then use if required - eg _log.Info("testing for ....")
Follow the project's own conventions first, then common C# conventions.
Keep naming, formatting, and project structure consistent.
Tests must use primary code paths only.
No timing-dependent assertions. No Stopwatch usage. No Task.Delay assertions in tests.
Use async tests unless code path is not async.
Mock all external dependencies: file I/O, network.
Tests should be deterministic and fast.
Record test metadata in datestamped JSON files with test name, duration, status, environment. DO NOT use CSV.
Don't create unit tests that test for DoesNotThrow(). This are meaningless tests. When testing a method we should be testing the return value which represents the main function of the method. 
DON'T add interfaces/abstractions unless used for external dependencies or testing.
Don't wrap existing abstractions.
Keep names consistent. 
Don't add unused methods/params.
When fixing one method, check siblings for the same issue.
Reuse existing methods.


