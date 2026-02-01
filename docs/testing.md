## Test Configuration

Use NUnit framework.
Use NSubstitute for all interface mocking.
Tests must use primary code paths only.
No timing-dependent assertions. No Stopwatch usage.
No Task.Delay assertions in tests.
Use async tests unless code path is not async.
use [TestCases] where possible.
Mock all external dependencies: file I/O, network, logging.
Tests should be deterministic and fast.
