---
name: write-csharp-code
description: Write high-quality, readable C# code following conventions
---

# How to write good C# code

## Banned patterns

### Nullability / object construction

| Banned | Reason | Use instead |
|---|---|---|
| `List<TModel?>` / `Task<TModel?>` built from an unfiltered source collection | The nullability is a symptom of not filtering the source first | Filter/select candidates from the raw source (eg AWS SDK `Image` objects by tag/naming convention) before mapping to the model, so the model list is never nullable |
| `Null*` fallback implementations (`NullService`, `NullRealtimeService`, `NullLog`, `NoOpLogger`) | Hides a missing required dependency and masks failures | Fail fast - throw or refuse to start if a required dependency is absent |
| Fallback `??` on a required test/DI seam (eg `ServiceProvider ?? DefaultFactory`) | Hides missing test wiring instead of failing the test immediately | Require the seam to be set explicitly; let it throw if unset |
| Silent default/fallback behaviour when required startup arguments are absent | Masks misconfiguration | Show usage text and exit |
| Nullable reference types used by default "just in case" | Spreads null-checking through the whole call graph | Only make a type/member nullable when it is genuinely optional after filtering/validation |
| Variables that nullable in extension methods - eg this `AutoScalingGroup? autoScalingGroup` | just plain bad. | dont ever use Type? in extension method parameters. |
| terniery operator (`condition ? trueValue : falseValue`) in a flow control context - eg foreach (var autoScalingGroup in autoScalingGroupList ?? []) | Hard to read and reason about in loops | Use explicit `if` statements for flow control instead, or use an extension method to get the filtered collection beforehand |
| Null-forgiving operator (`!`) on a value whose nullability was never actually resolved | Suppresses the compiler's real warning instead of fixing the nullability | Filter/validate earlier so the value is genuinely non-null, or keep it nullable and check it explicitly |

### Dependency injection / architecture

| Banned | Reason | Use instead |
|---|---|---|
| Service locators (`IServiceProvider.GetService<T>()` called deep in business logic) | Hides real dependencies | Constructor injection for every dependency |
| `LogManager.GetLogger<T>()` or static logger instances inside a service | Not injectable/testable, hides real log output | Inject `ILog<T>` via the constructor |
| Dynamic types or `record` types | Project convention is plain C# classes with explicit fields | Native C# classes with `{ get; set; }` properties |
| Public fields on DTOs/result classes | Bypasses encapsulation, breaks serialization/data-binding in some contexts | `{ get; set; }` properties |
| Private classes | Cannot be tested or composed across assemblies within the convention | `public` or `internal` |
| A class with more than one concern or more than one primary code path | Mixing concerns makes the class hard to reason about and test | Split into separate single-concern classes |
| Calling `configuration["Key"]` inside methods | Repeated lookups, hidden dependencies, hard to test | Read into `private readonly` fields in the constructor |
| Registering Autofac `ContainerBuilder.RegisterType<T>()` for a service that tests need to override via `ConfigureTestServices` | Autofac registrations win over `IServiceCollection`, breaking test overrides | Register test-overridable services via `builder.Services.AddSingleton()` in `Program.cs`; reserve `AutofacConfig.Configure` for services never overridden in tests |
| Calling command-line tools (`Process.Start`, shelling out) from C# | Not requested/required by the application requirements | Only do this when explicitly specified in the requirements |
| Filtering by building an exclude-list then `RemoveAll`/subtracting it from the full source collection (upside-down filtering) | Hard to follow - the reader has to mentally invert the logic to know what actually survives; easy to get the exit condition backwards | Build an empty inclusion list and add items that match the eligibility criteria, or `.Where(x => IsEligible(x))` directly against the source |
| Extension methods typed against an SDK/transport response wrapper (eg `this DescribeAutoScalingGroupsResponse`) | Couples business/domain logic to a specific SDK call shape, and can't be reused against the same domain items from another source | Type the extension method against the domain/model collection itself (eg `this IEnumerable<AutoScalingGroup>`); unwrap the SDK response at the call site. This does not apply to an extension method typed against the SDK's own domain/item class itself (eg `this Image` from the AWS SDK) - that is the actual object being converted, not a response wrapper, so it's fine |
| `Func<T, bool>` (or similar delegate) as a parameter on an extension method, to inject a predicate owned elsewhere | Hides the actual data being tested, turns a data-shape mismatch into a runtime bug, and makes the method's behaviour a black box at the call site | Pass the plain data needed for the check (eg `List<string> excludedStacks`) and do the comparison inside the extension method itself |
| Chained/nested `else if` testing unrelated conditions | Each branch is really a different named state - chaining unrelated conditions in one if/elseif is a code smell | A `Get-`/`Determine-` style method that returns a single state value via early-exit guard clauses, then `switch` on the result |
| Calling a cloud SDK (eg AWS) directly from business logic with no repository/service abstraction in between | Couples business logic to the SDK's shape and makes it untestable without hitting the real service | Route the call through a repository/service abstraction (eg `IAutoScalingRepository`) that can be substituted in tests |
| Constructing an SDK request/response object inline in the middle of business logic (eg `await RemoveForceTag(new DeleteTagsRequest{...})`) | Mixes wire-format concerns with business logic, hard to read and test | Build the request in a small dedicated helper/factory, or push it behind the repository/service abstraction so business logic only deals with domain types |
| A single `try/catch` wrapping an entire method | Masks exactly where a failure happened and forces unrelated failure modes through one handler | Validate/filter inputs before the method runs so it only ever runs against states that are expected to succeed |
| A method with more than one concern or primary code path | Hard to read, test and reason about | Split into single-concern methods |
| A `bool` parameter that switches unrelated behaviour inside a method (eg `isWindows` branching an otherwise shared method) | The method silently has two different implementations behind one signature | Split into two differently-named methods, or dispatch via `switch` over an explicit enum/state instead of a boolean |


### Naming

| Banned | Reason | Use instead |
|---|---|---|
| Naming a `string`/primitive parameter or variable after the object's type convention (eg `autoScalingGroup` holding just the name, when `autoScalingGroup` is the established convention for the full `AutoScalingGroup` object) | Misleads the reader into assuming the variable is the full object, hiding what data is actually available at that point | Name the variable for what it actually is (eg `autoScalingGroupName` for a `string`, `autoScalingGroup` reserved for the real `AutoScalingGroup` instance) |

### Testing

| Banned | Reason | Use instead |
|---|---|---|
| The words mock/fake/test/dummy anywhere in code, including unit tests | Project convention - even test doubles should read as real implementations | A minimal concrete implementation of the real abstraction, see `TestUtils.BuildTestConfiguration()`. This ban is on classes/variables only (`FakeHttpMessageHandler`, `MockHttpClient`) - it does not apply to NUnit test method names, which must say what they test (`Test_That_We_Can_...`) |
| Mocking a raw `HttpClient` (fake `HttpMessageHandler`, canned `HttpResponseMessage`) to test a call to an external API when production code already goes through a repository/client abstraction (eg `IOctopusRepository`) | Tests a fake path instead of the real one, and needs its own HttpClient test-seam constructor | Make production code route the call through the abstraction's own generic call (`Client.Get<T>/Post<T>`), then mock that call directly with NSubstitute |
| `<Feature>Test` / `<Feature>Success` test method names (eg `IsDeploymentFrozenTests`, `ReflectsActiveFreezes`, `PollForDeploymentTest`) | Doesn't read as a description of the behaviour under test | `Test_That_We_Can_<behaviour>` (eg `Test_That_We_Can_Determine_If_Deployment_Is_Frozen`) |
| Hand-rolled `NullLog`/`NoOpLogger` test doubles for `ILog<T>` | Hides log output useful for diagnosing test failures | Real logging infrastructure (`*.Library.Logging` + `LogManager.GetLogger<T>()`) |
| Environment variables to inject test configuration (ports, connection strings) | Non-deterministic, hides required config | `private const` fields assigned in `[OneTimeSetUp]` |
| `[Explicit]` or environment-variable-gated integration tests | Silently skips instead of failing on missing infrastructure | Integration tests always run and fail clearly when infrastructure is missing |
| `Assert.DoesNotThrow()` as the primary assertion | Meaningless - doesn't test the method's actual contract | Assert on the return value that represents the method's main function |
| `Stopwatch`, `Task.Delay` based assertions, other timing-dependent assertions | Flaky, non-deterministic | Deterministic assertions against actual state/return values |
| Mocking/stubbing external dependencies with ad-hoc test-only types scattered across test files | Duplication, inconsistent behaviour between tests | Minimal concrete implementation of the interface, reused across tests |
| `Func` in extension methods. | Can lead to hidden dependencies and make the code harder to test | Pass the required dependencies explicitly as parameters instead of capturing them in a `Func` |
| Getting an unfiltered list of objects and then creating a list of objects to be removed from the original list and then removing those. | Inefficient and harder to read | Use an extension method like `ToInstanceRefreshEligibleAutoScalingGroups` to filter the list directly |
| Hand-rolled Arrange code (repo/project/environment substitute setups) copy-pasted across multiple test methods | Duplication, drifts over time, obscures which setup actually matters to each test | Extract shared non-assertion setup into a static `*TestDataFactory` class, called from each test |
| Near-duplicate test methods differing only by a couple of substituted values (env name, task state, bool flag) | More tests to maintain for no extra coverage | Merge into one `[TestCase(...)]`-parameterized test |
| Named-argument labels (eg `deploymentEnvironment: "..."`) to skip over optional parameters on a test setup helper | Hides that the value is actually a test variation, not a one-off optional default | Promote the varying value to a `[TestCase]` parameter and pass arguments positionally |
| `[TestCase(true)]` / `[TestCase(false)]` or other opaque literals with no explanation | Reader can't tell what the parameter means without reading the test body | One-line comment above the `[TestCase]` attributes naming what each parameter represents, when the same explanation applies to every row |
| One comment shared above a group of `[TestCase]` rows where each row needs a *different* explanation | Goes stale as cases are added, moved or reordered - the reader can't tell which part of the comment maps to which row | A trailing comment on each individual `[TestCase]` line explaining that specific case |
| Repeating identical Arrange code at the top of every `[Test]`/`[TestCase]` method in a fixture | Duplication | `[SetUp]` method building the shared fixtures once per test run |
| Conditional logic (ternary `?:`, `if`/`switch`) inside a test or its helpers that computes the expected or arranged value, eg `var osVersion = imageId.Contains("2022") ? OsVersion.Server2022 : OsVersion.Server2016;` | Hard to evaluate by hand, can hide the same bug as the code under test, and one test then covers several unlabelled scenarios | Supply every exact input and expected value as `[TestCase]` parameters and assert with `Assert.That(actual, Is.EqualTo(expected))` (see Testing section example) |
| A class builds its own un-injectable dependency internally (eg `new HttpClient()` in a constructor) with no way to substitute it in tests | Forces tests to make real network calls | Add an `internal` constructor overload accepting the dependency for test substitution, delegating to the public constructor |

### Native interop (P/Invoke)

| Banned | Reason | Use instead |
|---|---|---|
| `[LibraryImport]` | Project convention uses `[DllImport]` | `[DllImport]` with explicit `CallingConvention = CallingConvention.Cdecl` |
| `[return: MarshalAs(UnmanagedType.Bool)]` | `UnmanagedType.Bool` is a 4-byte Win32 `BOOL` - wrong for a C99 `_Bool` (1 byte), and wrong on Linux | Declare C99 bool returns as `int`, compare `!= 0` at the call site |
| Calling a static inline function not exported by the shared library | Can't be P/Invoked directly | Reimplement by reading the native struct layout via `Marshal.ReadIntPtr` and invoking the function pointer through a typed delegate |

### NuGet

| Banned | Reason | Use instead |
|---|---|---|
| Directly editing `.csproj` / `Directory.Packages.props` to add or remove packages | Bypasses restore/consistency checks | `dotnet add package` / `dotnet remove package` |
| Creating a `nuget.config` in the project directory | NuGet sources are configured in the user's global config; a missing source should fail the build, not be silently added | Let the build fail if a required source is missing |
| `-Debug` / `-Release` suffixes on package names | Not a real package naming convention | Use the base package name; the build configuration goes on the package as a tag |

## General rules

- Follow the project's own existing conventions first, then common C# conventions.
- Use file-scoped namespaces.
- Always use `Program.Main()`-style `Program.cs`. Do not use top-level statements or global usings.
- Keep `Program.cs` as small as possible - only composition/bootstrap, no business logic.
- Use async `Task`/`Task<T>` for I/O operations. Never use blocking calls (`.Wait()`, `.Result`).
- Prefer native C# types (`int`) over less common native-width types (`uint`).
- Use extension methods where practical (eg `AddConsoleApp()` for service registration).
- Only use `Debug` for dotnet build configurations.

## Project / layer structure

- Core layer: interfaces and abstractions only, zero external dependencies beyond what Core itself provides.
- Infrastructure layer: lower-level plumbing implementations of Core interfaces.
- Application layer: business logic implementations of Core interfaces.
- Library code is split into DTOs and services - do not mix data and behaviour in one class.
- Each public class has exactly one concern and one primary code path. If a class gains a second concern or code path, split it into two classes before adding more logic.
- Don't add interfaces/abstractions unless they wrap an external dependency or exist for test substitution.
- Don't wrap existing abstractions in another abstraction.
- Don't add unused methods or parameters.
- When fixing an issue in one method, check sibling methods for the same issue.
- Reuse existing methods instead of duplicating logic.

## Program.cs / DefaultApplicationBuilder pattern

Use the `DefaultApplicationBuilder` (console apps) or `WebApplicationHostBuilder` (web APIs) pattern. DI wiring lives in a separate static class, not in `Program.cs`.
Register services in logical order: logging first, then infrastructure, then application services. Use SOLID principles and extension methods where practical.

Reference example: `C:\git\external\WebNon-WebHostingExamples\Metalhead.Examples.Hosting.CAB.ConsoleApp`. That project uses Serilog - ignore that part, this project uses NLog only (the established Ipscm NLog libraries).

For console apps with multiple launch scenarios, use `CommandLineParser` to parse options - there is no default behaviour; if no command-line parameters are given, show the usage text. Resolve the handler for a given option through DI:

```csharp
_serviceCollection.Resolve<ServiceThatIsForThisCommandLineOption>()
    .Execute();
```

`CommandLineHandler.cs` should contain only `CommandLineOptions` definitions - no execution logic.

## Dependency injection

- Constructor injection for every dependency. No service locators.
- Use the Autofac NuGet package with a static `AutofacContainer.Create()` method on an `AutofacContainer` class to build the container.
- When combining Autofac with ASP.NET Core (`AutofacServiceProviderFactory`), only route services that are never overridden by tests through `AutofacConfig.Configure(ContainerBuilder)`. Services that tests override via `ConfigureTestServices` must be registered with `builder.Services.AddSingleton()` in `Program.cs` instead, otherwise the Autofac registration wins and the test override has no effect.

```csharp
// CORRECT
internal static class AutofacConfig
{
    public static void Configure(ContainerBuilder builder, Action<ContainerBuilder>? containerActions = null)
    {
        builder.RegisterType<TlsSecretService>()
            .As<ITlsSecretService>()
            .SingleInstance();

        containerActions?.Invoke(builder);
    }
}

builder.Host.UseServiceProviderFactory(new AutofacServiceProviderFactory());
builder.Host.ConfigureContainer<ContainerBuilder>((_, b) => AutofacConfig.Configure(b));
```

## Logging

Use type-safe `ILog<T>` injected via the constructor. Never use `LogManager.GetLogger<T>()` or a static logger instance inside a service - that belongs only in composition/bootstrap code or test setup.

## Configuration extraction in constructors

Read configuration values into `private readonly` fields in the constructor, not via `configuration["Key"]` calls inside methods. This makes dependencies explicit, avoids repeated lookups, and makes the class easier to test.

```csharp
// CORRECT
public class MyService(IConfiguration configuration, IHttpClientFactory httpClientFactory)
{
    private readonly string _host = configuration["Service:Host"] ?? "127.0.0.1";
    private readonly int _port = int.Parse(configuration["Service:Port"] ?? "25");
    private readonly IHttpClientFactory _httpClientFactory = httpClientFactory;

    public async Task DoWorkAsync()
    {
        var client = _httpClientFactory.CreateClient("name");
        // uses _host and _port, not configuration
    }
}

// BANNED - reads config repeatedly inside methods
public class MyService(IConfiguration configuration)
{
    public async Task DoWorkAsync()
    {
        var host = configuration["Service:Host"];
    }
}
```

## DTOs and result classes

Use properties (`{ get; set; }`), never public fields.

```csharp
// CORRECT
public class MailpitTestResult
{
    public bool Sent { get; set; }
    public bool ReceivedByMailpit { get; set; }
}

// BANNED
public class MailpitTestResult
{
    public bool Sent;
    public bool ReceivedByMailpit;
}
```

## getting string values from an object and then using the string for further processing

eg
```csharp
function void GetImage(string imageName)
{
    Image image = GetImageByName(imageName);
}
var image = GetImagesFromAWS();
string imageName = image.Name;
if (!string.IsNullOrEmpty(imageName))
{
    GetImage(imageName);
}
```

## Filter before you model

If a model type would need to be nullable only because it's built from an unfiltered source collection, filter the source collection first. The nullability is a sign the filtering step is missing, not a reason to add `?`.

```csharp
// BANNED
public void BadFunction()
{
    var imageList = GetImageList();
    List<AmiModel?> amiModels = GetAmiModelsFromImageList(imageList); // should never need to be nullable
}

// CORRECT
public static bool MeetsCriteria(this Image image)
{
    //use exit-gate pattern to return early if criteria not met. eg
    if (!image.SomeProperty)
    {
        return false;
    }
    if (image.AnotherProperty < 0)
    {
        return false;
    }
    return true;
}
public List<Image> GetImageList()
{
    List<Image> images = _awsImageService.GetImages();
    return images.Where(x => x.MeetsCriteria()).ToList();
}
public void GoodFunction()
{
    var candidateImageList = GetImageList().Where(IsCandidateImage).ToList();
    List<AmiModel> amiModels = GetAmiModelsFromImageList(candidateImageList);
}
```

## Configuration classes

Pull constants used by a class out into a dedicated `XxxConfiguration` class when they're values that could reasonably change per environment/deployment. Define an interface (eg `IConfig1`) even for a configuration class, and inject it via DI. Configuration classes contain no logic - they're only a list of properties with defaults - so business logic classes stay unit testable without needing a real configuration instance; a minimal implementation of the interface is enough in a test.

```csharp
// BANNED - hardcoded constant, and a concrete class constructed inline instead of injected
private readonly Config1 _configuration = new Config1();

// CORRECT - interface injected via constructor
public class ServiceConfiguration(IConfiguration configuration)
{
}
```

## Async and long-running work

A method that returns `Task` but performs its work synchronously before returning is a defect: it blocks whoever awaited it. File, directory and network work belongs on the thread pool (`Task.Run`) inside the service, or behind it at the caller - the caller must not assume the work has started when the call returns.

Long-running work needs a way to stop and a way to pause that the work itself checks. Cancellation goes through `CancellationToken`; pause and stop-after-current-item go through an injected control object the loop polls, because a token cannot express pause.

Persist user settings through one background writer that owns a thread and coalesces to the latest value. A property setter that writes a file on the calling thread puts disk latency inside the UI event, and two setters racing produce a half-written file. Write to a temporary path and move it into place so a crash cannot leave truncated settings.

### Long-running operations

Do not measure before starting. Start the work, then measure alongside it on its own thread, and ramp the parallelism up when the measurement lands. A recursive scan that gates the first byte of work is the classic mistake: it is instant on a fixture and minutes on real data.
Validate input where the user supplies it, with checks that answer immediately. A probe that has to walk a tree belongs nowhere in the start path; if a job fails because of disk space or a locked file, report it from the work itself.
Concurrency limits that open up during a run belong behind the same control object the loop already polls for pause and stop, and are raised by releasing permits on its semaphore.

### Progress and diagnostics for long operations

Report progress inside an item, with a byte count, not only when the item finishes; throttle the reports with a clock so a thousand threads do not flood the consumer, and make the interval configurable so a test can turn it off.
Guard any observable collection mutated from a worker thread with a lock in the view model, even when already posting to a synchronization context, because the same code runs in tests with no dispatcher.
One state is not enough for a comparison: missing on the target, missing on the source, identical and different are four outcomes, and content comparison only makes sense for items present on both sides.
Write a plain text log to a logs folder under the working directory, log one line at startup so the file exists, and expose it as a file the user can open with the shell.
Open files with the least restrictive sharing that still works: `FileShare.ReadWrite | FileShare.Delete` for reads, at least `FileShare.ReadWrite` for writes. Exclusivity is a choice, not a default.

### Retry policy

Keep one retry policy per operation, owned by the layer that knows what the user asked for. An inner loop that retries raw IO failures defeats an outer policy that says "skip a locked file", because the inner loop burns its own budget first. Rethrow anything the outer layer classifies, and let the inner loop retry only genuinely transient faults.
Express a retry budget in wall-clock terms when designing it, not in attempts. Attempts times delay is the number the user experiences as a hang.
Use `await Task.Delay` in async code; `Thread.Sleep` inside a loop that holds a semaphore parks a pool thread and keeps the permit.
Log every retry with a timestamp so a stalled operation is diagnosable from the log alone.

### Concurrency limits

A limit on concurrent work bounds work that is running, so an item waiting to retry must release its slot and take it again on the next attempt. Otherwise a few permanently failing items consume the budget and everything else waits behind them.
Bound in-flight items separately from running items. Running is the user's performance choice; in-flight is the safety limit, and it is what keeps a two million file tree from creating two million tasks.
Size the thread budget from running items times threads per item, capped at a constant. Never derive both from one optional flag.
Only one layer owns retries. A low level loop that retries IO errors defeats the policy layer and multiplies the budget into minutes per item.
Classify failures by the OS error code, including the ones that are not literally access denied: an unresolvable reparse point will not succeed on the second attempt.
Delete a temporary destination file when an attempt fails, and offer zero in every "how many retries" setting.

### Adaptive concurrency

Treat a configured concurrency limit as a ceiling and start at one unit of work. Add a unit only while measured throughput keeps up, and hold when it drops. Compare each sample with the previous sample rather than an all time best, so a fast phase does not freeze the ramp for the rest of the run.

Measure throughput, not device utilisation: utilisation counters are platform specific and read 100 percent for a queue that is thrashing.

Keep the decision in a pure object that takes a byte delta, an elapsed time and whether work is pending, so it can be unit tested without a running scheduler. Keep the sampling in the engine, make the interval configurable, and log every expansion with the throughput behind it.
Never expand when nothing is queued.

## Native interop (P/Invoke)

Always use `[DllImport]` with explicit `CallingConvention = CallingConvention.Cdecl`. Never use `[LibraryImport]` or `[return: MarshalAs(UnmanagedType.Bool)]`.

C99 `bool` (`_Bool`) is 1 byte. `UnmanagedType.Bool` is a 4-byte Win32 `BOOL` and is wrong on Linux. Declare C99 bool returns as `int` and compare `!= 0` at the call site.

Static inline functions not exported by the shared library must be reimplemented in C# by reading the native struct layout directly via `Marshal.ReadIntPtr` and invoking the function pointer through a typed delegate.

## Testing

- Frameworks: NUnit and NSubstitute. Use `[TestCase]` where possible.
- Never use the words mock/fake/test/dummy anywhere in code, including unit tests. Where a substitute is needed, create a minimal concrete implementation of the real abstraction and use that instead (see `TestUtils.BuildTestConfiguration()`).
- Create a `DependencyResolverTest` that verifies the DI container can resolve every registered service. Make it generic over the registrations so newly added dependencies are automatically covered.
- Use `UseNunitTestContext` to obtain `_log`, and log context with it (eg `_log.Info("testing for ...")`).
- Tests exercise primary code paths only.
- No timing-dependent assertions. No `Stopwatch`. No `Task.Delay` based assertions.
- Use async tests unless the code path under test is not async.
- Mock all external dependencies: file I/O, network.
- Tests must be deterministic and fast.
- Record test metadata (test name, duration, status, environment) in datestamped JSON files. Never CSV.
- Don't write tests that only assert `DoesNotThrow()` - assert on the return value that represents the method's main function instead.
- Don't mark integration tests `[Explicit]` or gate them on environment variable checks - they must always run and fail clearly when infrastructure is missing.
- Logging in tests: use `*.Library.Testing` (`TestUtils.BuildTestConfiguration()`) plus `*.Library.Logging` (`new LogBuilder(config).Build()`), then `LogManager.GetLogger<T>()`. Never mock or stub `ILog<T>` with a hand-rolled `NullLog`.
- Test configuration (ports, paths, connection strings) goes in `private const` fields or fields assigned in `[OneTimeSetUp]` - never environment variables. This keeps the test self-documenting and deterministic.
- Console-app service injection from tests: set a static `Func<IService>? ServiceProvider` property on `App` before the test fixture runs (in its constructor); the app calls it at startup. Do not add a `??` fallback on `ServiceProvider` - tests must set it explicitly so missing wiring is caught immediately.
- Extract shared Arrange code (repo/project/environment substitute setups) into a static `*TestDataFactory` class instead of copy-pasting it across tests.
- Merge near-duplicate tests that only vary a couple of values into one `[TestCase(...)]`-parameterized test rather than keeping separate near-identical methods.
- Pass `[TestCase]` arguments positionally, not as named arguments - a named argument used to skip an optional parameter is a sign that value should be its own `[TestCase]` parameter instead.
- Add a one-line comment above any `[TestCase]` block whose values aren't self-explanatory (eg `[TestCase(true)]`/`[TestCase(false)]`) stating what each parameter represents.
- Use `[SetUp]` for Arrange code shared by every test in the fixture, instead of repeating it at the top of each `[Test]`/`[TestCase]` method.
- Never compute expected or arranged values with ternaries or other conditional logic in a test. Put each exact value in the `[TestCase]` row and compare against it.
- use `TestCaseSources` if possible. eg
    [TestCaseSource(nameof(TagsWithoutForceRecreation))]
    public void Test_That_Image_Without_Tags_Has_No_Force_Recreation_Tag(List<Tag> tags, bool expectedResult) testCase)

Bad - the ternary decides the arranged value, so the reader has to evaluate it by hand and each scenario is implicit:

```csharp
private static AmiInfo ToAmiInfo(Image image)
{
    var osVersion = image.ImageId.Contains("2022") ? OsVersion.Server2022 : OsVersion.Server2016;
    return new AmiInfo(image) { OsVersion = osVersion };
}

var expected = isWindows ? OsVersion.Server2022 : OsVersion.Rhel9;
```

Good - every input and expected value is explicit in the row; the test body has no logic:

```csharp
[TestCase("XXX-SOE-Srv2019-Deployments-7991559", "062774028013", true, ImageOwner.YYY)]
[TestCase("XXX-SOE-Srv2016-Deployments-7815480", "298998457971", true, ImageOwner.ZZZ)]
[TestCase("XXX-SOE-Srv2016-Deployments-7815480", "111111111111", true, ImageOwner.Unknown)]
public void Test_That_Image_Details_Are_Correct(string imageName, string ownerId, bool expectedIsWindows, ImageOwner expectedOwner)
{
    var image = TestDataGenerator.GenerateImage(imageName, ownerId, expectedIsWindows);

    var amiInfo = new AmiInfoService(_log).GetAmiInfo(image);

    Assert.That(amiInfo.IsWindows, Is.EqualTo(expectedIsWindows));
    Assert.That(amiInfo.Owner, Is.EqualTo(expectedOwner));
}
```

Where a helper needs a derived value (eg an `OsVersion` for a mocked image), pass it in as a parameter from the `[TestCase]` row instead of deriving it inside the helper.

## Patterns to avoid/aka code smells

- Do not create `Null*` fallback implementations (`NullService`, `NullRealtimeService`, etc). These hide missing required dependencies and mask failures. If a dependency is required, fail fast - don't silently no-op.
- Do not write inline `NullLog`/`NoOpLogger` classes in production code or test files.
- Do not use environment variables to inject runtime or test configuration (ports, connection strings, etc). The only exception is where a library explicitly requires environment variables for its own configuration (eg `GITHUB_API_KEY`, `OPENAI_API_KEY`).
- Do not provide default/fallback behaviour when required startup arguments are absent - show usage text and exit. Silent fallbacks hide misconfiguration and leave an untested second code path.

These patterns are bad:

amiId ??= (await GetCurrentAmiInfo(autoScalingGroup))?.XXXAmiId ?? throw new InvalidOperationException($"Could not resolve current AMI for {autoScalingGroup}.");

var latestLaunchTemplate = (launchTemplates?.LaunchTemplates?.FirstOrDefault()) ?? throw new InvalidOperationException();
var stackDisplayName = asgInfo.AutoScalingGroups.FirstOrDefault()?.Tags.FirstOrDefault(tag => tag.Key.Equals(Constants.StackDisplayNameTag, StringComparison.OrdinalIgnoreCase))?.Value;

if (string.IsNullOrWhiteSpace(stackDisplayName))
{
    // we expect to find a stack display name from the ASG tags, if not, log a warning
    logger.Warn($"Failed to find a stack display name on ASG: {autoScalingGroup}.");
}

EligibleAutoScaleGroups exists so that we have a sanitized list of autoscale groups that meet the necessary criteria for instance refresh. If we use EligibleAutoScaleGroups as the primary set of ASG that we are dealing with - then we can get rid of many of the safety checks/nullable checks or operators/low value if/then/else statements.

We should be filtering before working with a collection of objects where our assumptions about it may not be true.

## NuGet

Never directly edit `.csproj` or `Directory.Packages.props` to add or remove packages - use `dotnet add package` / `dotnet remove package`. Direct editing is permitted only to change the version of an already-referenced package.
Version updates require verification: confirm the target version exists, determine whether it's managed per-project or centrally, update it, then run `dotnet restore`.
Do not create a `nuget.config` in the project directory. If a required NuGet source doesn't exist, let the build fail rather than adding one - sources are configured in the user's global config only.
Do not append `-Debug` or `-Release` suffixes to package names. Build configuration is recorded as a tag on the package, passed via the `buildConfiguration` parameter to `build.xml` into the msbuild task that creates the NuGet package.
Extension methods are single functions that are meant to be very specific - they should not talk to AMS even via an abstraction. It should take an instance of an object and a short list of parameters - not a Settings or configuration class but working parameters.
