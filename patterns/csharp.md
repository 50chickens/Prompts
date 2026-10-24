## c# Coding patterns.

UI rules for Avalonia desktop applications live in [avalonia.md](./avalonia.md).

## Structure and DI

Use the default application builder pattern. program.cs stays as small as possible; Main holds nothing but the bootstrap.
Separate library classes into DTOs and services. Dependency injection wiring goes in its own static class, not program.cs.
Core interfaces and abstractions live in the Core layer with zero external dependencies beyond what Core provides. Implementations go in Infrastructure (plumbing) or Application (business logic).
A new console app or webapi uses DefaultApplicationBuilder or WebApplicationHostBuilder, with an example under `C:\git\external\WebNon-WebHostingExamples\Metalhead.Examples.Hosting.CAB.ConsoleApp`. That example uses serilog; use nlog only, through the Ipscm logging libraries.
Register services in logical order: logging, infrastructure, application services. Register them through extension methods, eg `.AddConsoleApp`.
Use the Autofac package and a static `AutofacContainer.Create()` method to set up the container.
Services take every dependency through the constructor. No service locators, no static logger or static service access.
Do not create private classes. Make types public or internal.
One concern and one primary code path per class. Split the class before adding logic to a second path.
Use SOLID and extension methods where practical. A small calculation that takes no state from its class becomes an extension method with its own test.
Do not use nested `else if` for unrelated comparisons; use `switch`.
Do not use `!` in variable names.
Do not create dynamic types or records. Prefer `int` over narrower native types such as `uint`.
Use file-scoped namespaces, a `program.main()` style entry point, and no global usings.
Only use nullable where it is the most optimal option.
Do not call command line tools from C# code unless the requirements documents name them.
Do not add `Null*` fallback implementations (`NullService`, `NullRealtimeService`) or inline `NullLog`/`NoOpLogger` classes. A required dependency fails fast.
Do not provide default behaviour when required startup arguments are absent. Show usage and exit.
Do not use environment variables to inject runtime or test configuration, except where a library itself reads them (`GITHUB_API_KEY`, `OPENAPI_API_KEY`).

## Configuration

Read configuration into `private readonly` fields in the constructor, never with `configuration["Key"]` inside methods.

```csharp
public class MyService(IConfiguration configuration, IHttpClientFactory httpClientFactory)
{
    private readonly string _host = configuration["Service:Host"] ?? "127.0.0.1";
    private readonly int _port = int.Parse(configuration["Service:Port"] ?? "25");
    private readonly IHttpClientFactory _httpClientFactory = httpClientFactory;
}
```

Constants a class uses move into an `IXxxConfiguration` interface whose implementation holds only properties and defaults, injected through the constructor. Configuration classes contain no code and need no test; they exist so the business logic is testable.
A field initialised as `private readonly Config1 _configuration = new Config1()` is banned; inject `IConfig1` through the primary constructor.

## Autofac with ASP.NET Core

`ContainerBuilder.RegisterType<T>()` in `AutofacConfig.Configure` overrides an `IServiceCollection` registration, which defeats `WebApplicationFactory` `ConfigureTestServices`. Register anything a test replaces with `builder.Services.AddSingleton()` in Program.cs, and keep `AutofacConfig.Configure` for services no test replaces.

```csharp
internal static class AutofacConfig
{
    public static void Configure(ContainerBuilder builder, Action<ContainerBuilder>? containerActions = null)
    {
        builder.RegisterType<TlsSecretService>().As<ITlsSecretService>().SingleInstance();

        containerActions?.Invoke(builder);
    }
}

builder.Host.UseServiceProviderFactory(new AutofacServiceProviderFactory());
builder.Host.ConfigureContainer<ContainerBuilder>((_, b) => AutofacConfig.Configure(b));
```

## Command line

Use CommandLineParser for applications that take options. There is no default behaviour: with no parameters, show the options and exit.
Resolve the service that handles the chosen option through DI, eg `_serviceCollection.Resolve<ServiceThatIsForThisCommandLineOption>().Execute()`. commandlinehandler.cs holds `CommandLineOptions` code only.

## DTOs

DTOs and result classes use properties `{ get; set; }`, never public fields.

## Async and lifetime

Use `async Task` for I/O and return `Task<T>` from services. Never block with `Wait()` or `Result`.
A method that returns `Task` but finishes its work before returning is a defect: file, directory and network work belongs on the thread pool inside the service, or behind the caller, and the caller must not assume the work has started.
Long-running work needs a stop and a pause the work itself checks. Cancellation goes through `CancellationToken`; pause and stop-after-current-item go through an injected control object the loop polls, because a token cannot express pause.
Persist user settings through one background writer that owns a thread and coalesces to the latest value. A setter that writes a file on the calling thread puts disk latency inside the UI event, and two setters racing produce a half-written file; write a temporary path and move it into place.

## Native interop (P/Invoke)

Always use `[DllImport]` with explicit `CallingConvention = CallingConvention.Cdecl`. Never use `[LibraryImport]` or `[return: MarshalAs(UnmanagedType.Bool)]`.
C99 `bool` (`_Bool`) is 1 byte. `UnmanagedType.Bool` is a 4-byte Win32 `BOOL` — wrong on Linux. Declare C99 bool returns as `int` and compare `!= 0` at the call site.
Static inline functions not exported by the shared library must be reimplemented in C# by reading the native struct layout directly via `Marshal.ReadIntPtr` and invoking the function pointer through a typed delegate.

## Logging

Inject `ILog<T>` through the constructor. Never `LogManager` or a static logger instance.
nlog is the only logging backend, from the `Ipscm.Library.Logging` packages, which reference the nlog packages themselves, so nlog is not added directly.
Log paths stay inside REPO_ROOT, under the folder structure this project uses for logs.

## Testing

NUnit and NSubstitute. Use `[TestCase]` where possible.
Do not use the words mock, fake, test or dummy in code, including unit tests. Where an abstraction needs a stand-in, write a minimal implementation of the interface in the unit test; `TestUtils.BuildTestConfiguration()` is the example. Do not build a full configuration class.
Create one generic `DependencyResolverTest` that resolves every service, so a new registration is covered without editing the test.
Use `UseNunitTestContext` for a `_log` when the test needs output.
Tests exercise primary code paths only. No timing assertions, no `Stopwatch`, no `Task.Delay` assertions. Use async tests unless the path is not async.
Tests are deterministic. No skip, no `[Explicit]`, no environment-variable gate. An integration test runs and fails clearly when infrastructure is missing.
Every value a test needs (ports, paths, connection strings) goes in a `private const` or a field assigned in `[OneTimeSetUp]`.
Do not assert `DoesNotThrow()`; assert the return value that carries the method's purpose.
Record test metadata (name, duration, status, environment) in datestamped JSON files, never CSV.
When fixing one method, check its siblings for the same defect. Reuse existing methods. Do not add unused methods or parameters. Do not add an interface or abstraction unless an external dependency or a test needs it, and do not wrap an existing abstraction.
Logging in tests: `TestUtils.BuildTestConfiguration()` plus `new LogBuilder(config).Build()`, then `LogManager.GetLogger<T>()`. A hand-rolled `NullLog` hides the log output that diagnoses the failure.
Console app service injection from tests: set a static `Func<IService>? ServiceProvider` property on `App` before the fixture runs. The app calls it at startup, and there is no `??` fallback on it, so missing wiring fails immediately.

Avalonia views, view models and headless journey tests: `patterns\avalonia.md`.

## Nuget

Never edit .csproj or Directory.Packages.props to add or remove a package; use `dotnet add` and `dotnet remove`. Direct editing is only for changing the version of an existing package.
A version update verifies the target version exists, checks whether the package is managed per-project or centrally, updates the version, then runs `dotnet restore`.
Never create a project-level NuGet.Config or nuget.config. Sources come from the user's global config, and a missing source fails the build.
Only Debug for build configurations. Pass buildConfiguration to build.xml for the msbuild task that packs the package, and add that value to the package as a tag.
Do not append -Debug or -Release suffixes to package names.

## Banned shapes

`skills\csharp\bad.cs` is the worked example of these, in a class that decides whether an Octopus deployment should be triggered from AMI images in two AWS accounts.
A `bool` parameter that switches behaviour inside the method.
A service called directly with no abstraction in front of it.
`foreach` with nested `if`/`else if`/`else` branching on object properties.
Conditional logic inside a filter: `.FirstOrDefault(x => x.Name.StartsWith(prefix ? prefix : string.Empty))`.
Nested negated nullable evaluation, such as `!string.IsNullOrWhiteSpace(sortedAmiModels?.Id)`.
Request and response objects created in the middle of business logic: `await RemoveForceTag(new DeleteTagsRequest { ... })`.
Null and count checks for objects that can be assumed to exist.
One `try`/`catch` around an entire method; validate before calling it instead.
More than one concern in a method.

## Long-running operations

Start the work, then measure alongside it on its own thread, and ramp parallelism when the measurement lands. A recursive scan that gates the first byte of work is instant on a fixture and minutes on real data.
Validate input where the user supplies it, with checks that answer immediately. A probe that has to walk a tree belongs nowhere in the start path; a job that fails on disk space or a locked file reports it from the work itself.
Concurrency limits that open up during a run hang off the same control object the loop polls for pause and stop, raised by releasing permits on its semaphore.

## Progress and diagnostics

Report progress inside an item with a byte count, not only when the item finishes, throttled with a clock so a thousand threads do not flood the consumer, and with a configurable interval a test can turn off.
Guard an observable collection mutated from a worker thread with a lock in the view model, even when you post to a synchronization context, because the same code runs in tests with no dispatcher.
Comparison has four outcomes, not two: missing on the target, missing on the source, identical, different. Content comparison applies only to items present on both sides.
Write a plain text log to a logs folder under the working directory, log one line at startup so the file exists, and expose it as a file the user can open with the shell.
Open files with the least restrictive sharing that still works: `FileShare.ReadWrite | FileShare.Delete` for reads, at least `FileShare.ReadWrite` for writes.

## Retry

One retry policy per operation, owned by the layer that knows what the user asked for. An inner loop that retries raw IO failures burns the budget of the outer policy that says skip a locked file.
Express a retry budget in wall-clock terms. Attempts times delay is the number the user experiences as a hang.
Use `await Task.Delay` in async code. `Thread.Sleep` inside a loop that holds a semaphore parks a pool thread and keeps the permit.
Log every retry with a timestamp.
Classify failures by the OS error code, including the ones that are not literally access denied: an unresolvable reparse point does not succeed on the second attempt.
Delete a temporary destination file when an attempt fails, and offer zero in every how-many-retries setting.

## Concurrency limits

A limit bounds work that is running, so an item waiting to retry releases its slot and takes it again on the next attempt; otherwise a few permanently failing items consume the budget.
Bound in-flight items separately from running items. Running is the user's performance choice; in-flight is the safety limit that keeps a two million file tree from creating two million tasks.
Size the thread budget from running items times threads per item, capped at a constant. Never derive both from one flag.

## Adaptive concurrency

Treat the configured limit as a ceiling and start at one unit of work. Add a unit only while measured throughput keeps up and hold when it drops. Compare each sample with the previous sample, not an all-time best, so a fast phase does not freeze the ramp.
Measure throughput, not device utilisation: utilisation counters are platform specific and read 100 percent for a queue that is thrashing.
Keep the decision in a pure object that takes a byte delta, an elapsed time and whether work is pending, so it is unit testable without a scheduler. Sampling stays in the engine, the interval is configurable, and every expansion is logged with the throughput behind it.
Never expand when nothing is queued.

## Tooling facts

`dotnet new` `-o` must be absolute; list the folder to confirm.
A `classlib` app needs `<OutputType>Exe</OutputType>`, or the launch fails with hostpolicy.dll or runtimeconfig.json not found.
`dotnet format --verify-no-changes` fails on tab-indented legacy files; run `dotnet format` before the first CI run.

## API shapes

`Directory.EnumerateFiles(..., AllDirectories)` throws on one unresolvable entry. Walk an explicit stack, catch `IOException` and `UnauthorizedAccessException` per folder, and skip `FileAttributes.ReparsePoint`.
Never type an extension method parameter as nullable: `this AutoScalingGroup? autoScalingGroup`.
Never type an extension method against an SDK response wrapper such as `DescribeAutoScalingGroupsResponse`; unwrap at the call site.
Never take a `Func<T, bool>` parameter on an extension method to inject a predicate.

## Test shapes

Test names read `Test_That_We_Can_<behaviour>`; never `<Feature>Test` or `<Feature>Success`.
Pass `[TestCase]` arguments positionally; a named argument that skips an optional parameter makes that value its own parameter.
Put fixture-wide Arrange in `[SetUp]`, not at the top of every test.
