## c# Coding patterns.

UI rules for Avalonia desktop applications live in [avalonia.md](./avalonia.md). They are not repeated here.
use the default application builder pattern in c#. program.cs should be as small as possible.
for all of the library code - seperate classes into DTOs and services. 
dependency injection wiring could go into a seperate static class other than program.cs. 
use commandlineparser for handling different launch scenarios in the console app. do not have a default behaviour. show the user the options if there are no command line parameters. 
Core interfaces and abstractions are in the Core layer and have zero external dependencies beyond what the Core layer provides. Implementations go in Infrastructure (for lower-level plumbing) or Application (for business logic) layers.
Use SOLID principles and extension methods where practical. DefaultApplicationBuilder pattern for DI setup. there is a good example of the pattern under C:\git\external\WebNon-WebHostingExamples - specifically default application builder. C:\git\external\WebNon-WebHostingExamples\Metalhead.Examples.Hosting.CAB.ConsoleApp. note this project uses serilog not nlog. ignore serilog. you should definately use nlog only (using the established ipscm libraries for nlog).

Services use constructor injection for all dependencies. No service locators.
Do not call command line tools in c# code unless specifically mentioned in the application requirements documents. 
Logging uses ILog<T> injected via constructor. Never use LogManager or static logger instances.
Classes should have a single concern and only a primary code path. If a class has more than concern or more than one primary code path consider it for refacting into two classes. 
Each public class has one primary code path. If a class has multiple concerns, split it into separate classes before adding more logic.
Do not create dynamic types or records for any reason at any time. prefer c# native types - eg int over any native types - eg uint.
Use file-scoped namespaces. Always use program.main() style program.cs. do not use global usings.
Use interfaces in Core layer. Implementations in Infrastructure or Application layers. Core has zero external dependencies.
Use DefaultApplicationBuilder pattern for DI setup. Register services in logical order: logging first, then infrastructure, then application services.
Keep classes single concern. Use the service pattern. Use constructor injection for dependencies. 
Don't create private classes. Make types public or internal.
Keep the Main method in a project as minimal as possible. Classes should have only 1 primary code path - if there are more than split the class. 
Use the Autofac nuget package and create an static AutofacContainer.Create() method in the AutofacContainer class and use this to setup the container. 
Use extension methods where practical. 
All services accept required parameters in constructor. No static service locators.
Use type-safe logging with ILog<T>. Never use LogManager or static logger instances. Inject logger via constructor.
Use async Task for I/O operations. 
Return Task<T> from services. 
Never use blocking calls like Wait() or Result.
A method that returns Task but performs its work synchronously before returning is a defect: it blocks whoever awaited it. File, directory and network work belongs on the thread pool (Task.Run) inside the service, or behind it at the caller, and the caller must not assume the work has started when the call returns.
Long-running work needs a way to stop and a way to pause that the work itself checks. Cancellation goes through CancellationToken; pause and stop-after-current-item go through an injected control object the loop polls, because a token cannot express pause.
Persist user settings through one background writer that owns a thread and coalesces to the latest value. A property setter that writes a file on the calling thread puts disk latency inside the UI event, and two setters racing produce a half-written file. Write to a temporary path and move it into place so a crash cannot leave truncated settings.
Only use nullable if this is most optimal.

### Native interop (P/Invoke)
Always use `[DllImport]` with explicit `CallingConvention = CallingConvention.Cdecl`. Never use `[LibraryImport]` or `[return: MarshalAs(UnmanagedType.Bool)]`.
C99 `bool` (`_Bool`) is 1 byte. `UnmanagedType.Bool` is a 4-byte Win32 `BOOL` — wrong on Linux. Declare C99 bool returns as `int` and compare `!= 0` at the call site.
Static inline functions not exported by the shared library must be reimplemented in C# by reading the native struct layout directly via `Marshal.ReadIntPtr` and invoking the function pointer through a typed delegate.

## dotnet guidelines.
Only use Debug for dotnet build configurations. 
Pass the buildConfiguration parameter to build.xml to include it in the msbuild task that creates the nuget package. this build configuration value should be added as a nuget package tag.

## Software architecture.
When creating a new console app, or webapi use DefaultApplicationBuilder or WebApplicationHostBuilder patterns. 
Use extension methods for service registration. eg .AddConsoleApp

## Patterns/practises to avoid.
Do not create Null* fallback implementations (NullService, NullFm3RealtimeService, etc). These hide missing required dependencies and mask failures. If a dependency is required, fail fast — don't silently no-op.
Do not write inline NullLog/NoOpLogger classes in production code or test files. Use the proper logging infrastructure (Ipscm.Library.Logging + LogManager.GetLogger<T>()). Fake loggers hide real issues and create dead code.
Do not use environment variables to inject runtime variables to determine application or test behaviour. The only exception for this is where libraries explicity use environment variables for their configuration (eg GITHUB_API_KEY, OPENAPI_API_KEY). Put required config in private const or private fields initialised in [OneTimeSetUp].  
Don't use the word mock/fake/test/dummy in the code anywhere - even in unit tests. 
Tests should run or fail deterministically — not silently skip based on environment state. All tests must either run or fail. do not ignore, or skip any tests. 
Do not mark integration tests [Explicit] or gate them on environment variable checks. Integration tests should always run and fail clearly when infrastructure is missing — that is the signal.
Do not provide default/fallback behaviour when required startup arguments are absent. Show usage and exit. Silent fallbacks hide misconfiguration.

## helper knowledge
Logging in tests: use Ipscm.Library.Testing (TestUtils.BuildTestConfiguration()) + Ipscm.Library.Logging (new LogBuilder(config).Build()) then LogManager.GetLogger<T>(). Never mock or stub ILog<T> with a hand-rolled NullLog — it hides log output that is useful for diagnosing test failures.
Test configuration: all values a test needs (ports, paths, connection strings) go in private const or private fields assigned in [OneTimeSetUp]. This makes the test self-documenting and deterministic. Do not use environment variables to inject test configuration (ports, connection strings, etc). 
Consolonia app service injection from tests: set a static Func<IService>? ServiceProvider property on App before the test fixture runs (in the constructor). The app calls it at startup. Do not use a fallback null-safe operator (??) on ServiceProvider — tests must set it explicitly so missing wiring is caught immediately.
When an app has required startup arguments, enforce them at the entry point and exit with usage text. Do not silently fall back to a default mode — the fallback path is never tested and creates two code paths to maintain.
Use the CommandLineParser nuget packages for applications that require command line options. 
Use DI to resolve to get the service which processes that command line option - eg 
_serviceCollection.Resolve<ServiceThatIsForThisCommandLineOption>.Execute(); the commandlinehandler.cs should only have CommandLineOptions code in it.


## Nuget

NEVER directly edit .csproj or Directory.Packages.props to add or remove packages. Use dotnet add/remove commands.
DIRECT EDITING permitted only for changing versions of existing packages.
VERSION UPDATES require verification: target version exists, determine if managed per-project or centrally, update version, run dotnet restore.
do not create nuget.config files in the project directory. if the nuget source does not exist you should never create it. The build should fail. NuGet sources are configured in the user's global config. Never create project-level NuGet.Config files.
Do not append -Debug or -Release suffixes to package names.

## Long-running operations

Do not measure before starting. Start the work, then measure alongside it on its own thread, and ramp the parallelism up when the measurement lands. A recursive scan that gates the first byte of work is the classic mistake: it is instant on a fixture and minutes on real data.
Validate input where the user supplies it, with checks that answer immediately. A probe that has to walk a tree belongs nowhere in the start path; if a job fails because of disk space or a locked file, report it from the work itself.
Concurrency limits that open up during a run belong behind the same control object the loop already polls for pause and stop, and are raised by releasing permits on its semaphore.

## Progress and diagnostics for long operations

Report progress inside an item, with a byte count, not only when the item finishes; throttle the reports with a clock so a thousand threads do not flood the consumer, and make the interval configurable so a test can turn it off.
Guard any observable collection mutated from a worker thread with a lock in the view model, even when you already post to a synchronization context, because the same code runs in tests with no dispatcher.
One state is not enough for a comparison: missing on the target, missing on the source, identical and different are four outcomes, and content comparison only makes sense for items present on both sides.
Write a plain text log to a logs folder under the working directory, log one line at startup so the file exists, and expose it as a file the user can open with the shell.
Open files with the least restrictive sharing that still works: FileShare.ReadWrite | FileShare.Delete for reads, at least FileShare.ReadWrite for writes. Exclusivity is a choice, not a default.

## Retry policy

Keep one retry policy per operation, owned by the layer that knows what the user asked for. An inner loop that retries raw IO failures defeats an outer policy that says "skip a locked file", because the inner loop burns its own budget first. Rethrow anything the outer layer classifies, and let the inner loop retry only genuinely transient faults.
Express a retry budget in wall-clock terms when you design it, not in attempts. Attempts times delay is the number the user experiences as a hang.
Use await Task.Delay in async code; Thread.Sleep inside a loop that holds a semaphore parks a pool thread and keeps the permit.
Log every retry with a timestamp so a stalled operation is diagnosable from the log alone.

## Concurrency limits

A limit on concurrent work bounds work that is running, so an item waiting to retry must release its slot and take it again on the next attempt. Otherwise a few permanently failing items consume the budget and everything else waits behind them.
Bound in-flight items separately from running items. Running is the user's performance choice; in-flight is your safety limit, and it is what keeps a two million file tree from creating two million tasks.
Size the thread budget from running items times threads per item, capped at a constant. Never derive both from one optional flag.
Only one layer owns retries. A low level loop that retries IO errors defeats the policy layer and multiplies the budget into minutes per item.
Classify failures by the OS error code, including the ones that are not literally access denied: an unresolvable reparse point will not succeed on the second attempt.
Delete a temporary destination file when an attempt fails, and offer zero in every "how many retries" setting.

## Adaptive concurrency

Treat a configured concurrency limit as a ceiling and start at one unit of work. Add a unit only while measured throughput keeps up, and hold when it drops. Compare each sample with the previous sample rather than an all time best, so a fast phase does not freeze the ramp for the rest of the run.
Measure throughput, not device utilisation: utilisation counters are platform specific and read 100 percent for a queue that is thrashing.
Keep the decision in a pure object that takes a byte delta, an elapsed time and whether work is pending, so it can be unit tested without a running scheduler. Keep the sampling in the engine, make the interval configurable, and log every expansion with the throughput behind it.
Never expand when nothing is queued.
