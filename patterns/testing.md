
## Testing & iteration guidelines.
Use NUnit and NSubstitute for testing frameworks. Create unit tests to verify the DI container can resolve all services.
Create unit test to verify DI container can resolve all services.
Use Nunit for tests. Testcases should handle multiple scenarios for single method. 
Use NSubstitute for all interface mocking.
Follow the project's own conventions first, then common C# conventions.
Keep naming, formatting, and project structure consistent.
Tests must use primary code paths only.
No timing-dependent assertions. No Stopwatch usage.
No Task.Delay assertions in tests.
Use async tests unless code path is not async.
use [TestCases] where possible.
Mock all external dependencies: file I/O, network, logging.
Tests should be deterministic and fast.
Don't create unit tests that test for DoesNotThrow(). this are meaningless tests. When testing a method we should be testing the return value which represents the main function of the method. 
DON'T add interfaces/abstractions unless used for external dependencies or testing.
Don't wrap existing abstractions.
Keep names consistent. 
Don't add unused methods/params.
When fixing one method, check siblings for the same issue.
Reuse existing methods.

## Test Configuration

Use NUnit and NSubstitute for testing frameworks.
Tests must use primary code paths only. Use test cases where possible. If a test class has more than more than 2 tests analyze whether you should split the class or not.
No timing-dependent assertions. No Stopwatch usage.
No Task.Delay assertions in tests.
Use async tests unless code path is not async.
Use [TestCases] where possible.
Mock all external dependencies: file I/O, network, logging.
Tests should be deterministic and fast.
Record test metadata in datestamped JSON files with test name, duration, status, environment. DO NOT use CSV.
