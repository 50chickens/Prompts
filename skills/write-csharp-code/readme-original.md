7    
8    ## Banned patterns
9    
10   ### Nullability / object construction
11   
12   | Banned | Reason | Use instead |
13   |---|---|---|
14   | `List<TModel?>` / `Task<TModel?>` built from an unfiltered source collection | The nullability is a symptom of not filtering the source first | Filter/select candidates from the raw source (eg AWS SDK `Image` objects by tag/naming convention) before mapping to the model, so the model list is never nullable |
15   | `Null*` fallback implementations (`NullService`, `NullRealtimeService`, `NullLog`, `NoOpLogger`) | Hides a missing required dependency and masks failures | Fail fast - throw or refuse to start if a required dependency is absent |
16   | Fallback `??` on a required test/DI seam (eg `ServiceProvider ?? DefaultFactory`) | Hides missing test wiring instead of failing the test immediately | Require the seam to be set explicitly; let it throw if unset |
17   | Silent default/fallback behaviour when required startup arguments are absent | Masks misconfiguration | Show usage text and exit |
18   | Nullable reference types used by default "Just in case" | Spreads null-checking through the whole call graph | Only make a type/member nullable when it is genuinely optional after filtering/validation |
19   | Variables that nullable in extension methods - eg this `AutoScalingGroup? autoScalingGroup` | just plain bad. | dont ever use Type? in extension method parameters. |
20   
21   ### Dependency injection / architecture
22   
23   | Banned | Reason | Use instead |
24   |---|---|---|
25   | Service locators (`IServiceProvider.GetService<T>()` called deep in business logic) | Hides real dependencies | Constructor injection for every dependency |
26   | `LogManager.GetLogger<T>()` or static logger instances inside a service | Not injectable/testable, hides real log output | Inject `ILog<T>` via the constructor |
27   | Dynamic types or `record` types | Project convention is plain C# classes with explicit fields | Native C# classes with `{ get; set; }` properties |
28   | Public fields on DTOs/result classes | Bypasses encapsulation, breaks serialization/data-binding in some contexts | `{ get; set; }` properties |
29   | Private classes | Cannot be tested or composed across assemblies within the convention | `public` or `internal` |
30   | A class with more than one concern or more than one primary code path | Mixing concerns makes the class hard to reason about and test | Split into separate single-concerning classes |
31   | Calling `configuration["Key"]` inside methods | Repeated lookups, hidden dependencies, hard to test | Read into `private readonly` fields in the constructor |
32   | Registering Autofac `ContainerBuilder.RegisterType<T>()` for a service that tests need to override via `ConfigureTestServices` | Autofac registrations win over `IServiceCollection`, breaking test overrides | Register test-overridable services via `builder.Services.AddSingleton()` in `Program.cs`; reserve `AutofacConfig.Configure` for services never overridden in tests |
33   | Calling command-line tools (`Process.Start`, shelling out) from C# | Not requested/required by the application requirements | Only do this when explicitly specified in the requirements |
34   | Filtering by building an exclude-list then `RemoveAll`/subtracting it from the full source collection (upside-down filtering) | Hard to follow | The reader has to mentally invert the logic to know what actually survives; easy to get the exit condition backwards | Build an empty inclusion list and add items that match the eligibility criteria, or `.Where(x -> IsEligible(x))` directly against the source |
35   | Extension methods typed against an SDK/transport response wrapper (eg `this DescribeAutoScalingGroupsResponse`) | Couples business/domain logic to a specific SDK call shape, and can't be reused against the same domain items from another source | Type the extension method against the domain/model collection itself (eg `this IEnumerable<AutoScalingGroup>`); unwrap the SDK response at the call site. This not apply to an extension method typed against the SDK's own domain/item class itself (eg `this Image` from the AWS SDK) - that is the actual object been converted, not a response wrapper, so it's fine |
36   | `Func<T, bool>` (or similar delegate) as a parameter on an extension method, to inject a predicate owned elsewhere | Hides the actual data being tested, turns a data-shape mismatch into a runtime bug, and makes the method's behaviour a box at the call site | Pass the plain data needed for the check (eg `List<string> excludedStacks`) and do the comparison inside the extension method itself |
37   
38   ### Naming
39   
40   | Banned | Reason | Use instead |
41   |---|---|---|
42   | Naming a `string`/primitive parameter or variable after the object's type convention (eg `autoScalingGroup` holding just the name, when `autoScalingGroup` is the established convention for the full `AutoScalingGroup` object) | Misleads the reader into assuming the variable is the full object, hiding what data is actually available at that point | Name the variable for what it actually is (eg `autoScalingGroupName` for a `string`, `autoScalingGroup` reserved for the real `AutoScalingGroup` instance) |
43   
44   ## Testing
45   
46   | Banned | Reason | Use instead |
47   |---|---|---|
48   | The words mock/fake/test/dummy anywhere in code, including unit tests | Project convention - even test doubles should read as real implementations | A minimal concrete implementation of the real abstraction, see `TestUtils.BuildTestConfiguration()`. This ban is on classes/variables standing in for a real abstraction (`FakeHttpMessageHandler`, `MockHttpClient`) - it does not apply to NUnit test method names, which must say what they test (`Test_That_We_Can_...`) |
49   | Mocking a raw `HttpClient` (fake `HttpMessageHandler`, canned `HttpResponseMessage`) to test a call to an external API when production code already goes through a repository/client abstraction (eg `IOctopusRepository`) | Tests a fake path instead of the real one, and needs its own HttpClient test-seam constructor | Make production code route the call through the abstraction's own generic call (`Client.Get<T>` / `Post<T>`), then mock that call directly, with NSubstitute |
50   | `<Feature>Test` / `<Feature>Success` test method names (eg `IsDeploymentFrozenReflectsActiveFreezes`, `PollForDeploymentTest`) | Doesn't read as a description of the behaviour under test | `Test_That_We_Can_<behaviour>` (eg `Test_That_We_Can_Determine_If_Deployment_Is_Frozen`) |
51   | Hand-rolled `NullLog` / `NoOpLogger` test doubles for `ILog<T>` | Hides log output useful for diagnosing test failures | Real logging infrastructure (`*.Library.Logging` + `LogManager.GetLogger<T>()`) |
52   | Environment variables to inject test configuration (ports, connection strings) | Non-deterministic, hides required config | `private const` / fields assigned in `[OneTimeSetup]` |
53   | `[Explicit]` or environment-variable-dated integration tests | Silently skips instead of failing on missing infrastructure | Integration tests always run and fail clearly when infrastructure is missing |
54   | `Assert.DoesNotThrow()` as the primary assertion | Meaningless - doesn't test the method's actual contract | Assert on the return value that represents the method's main function |
55   | `Stopwatch`, `Task.Delay` based assertions, other timing-dependent assertions | Flaky, non-deterministic | Deterministic assertions against actual state/return values |
56   | Mocking/stubbing external dependencies with ad-hoc test-only types scattered across test files | Duplication, inconsistent behaviour between tests | Minimal concrete implementation of the interface, reused across tests |
57   | Func in extension methods | Can lead to hidden dependencies and make the code harder to test | Pass the required dependencies explicitly as parameters instead of capturing them in a `Func` |
58   | Getting an unfiltered list of objects and then creating a list of objects to be removed from the original list and then removing those | Inefficient and harder to read | Use an extension method like `ToInstanceRefreshEligibleAutoScalingGroups` to filter the list directly |
59   | Hand-rolled Arrange code (repo/project/environment substitute setups) copy-pasted across multiple test methods | Duplication, drifts over time, obscures which setup actually matters to each test | Extract shared non-assertion setup into a static `*TestDataFactory` class, called from each test |
60   | Near-duplicate test methods differing only by a couple of substituted values (env name, task state, bool flag) | More tests to maintain for no extra coverage | Merge into one `[TestCase(...)]`-parameterized test |
61   | Named-argument labels (eg `deploymentEnvironment: "..."`) to skip over optional parameters on a test setup helper | Hides that the value is actually a test variation, not a one-off optional default | Promote the varying value to a `[TestCase]` parameter and pass arguments positionally |
62   | `[TestCase(true)]` / `[TestCase(false)]` or other opaque literals with no explanation | Reader can't tell what the parameter means without reading the test body | One-line comment above the `[TestCase]` attributes naming what each parameter represents, when the same explanation applies to every row |
63   | One comment shared above a group of `[TestCase]` rows where each row needs a *different* explanation | Goes stale as cases are added, removed or reordered - the reader can't tell which part of the comment maps to which row | A trailing comment on each individual `[TestCase]` line explaining that specific case |
64   | Repeating identical Arrange code at the top of every `[Test]` / `[TestCases]` method in a fixture | Duplication | `[Setup]` method building the shared fixtures once per test run |
65   | A class builds its own un-injectable dependency internally (eg `new HttpClient()` in a constructor) with no way to substitute it in tests | Forces tests to make real network calls | Add an `internal` constructor overload accepting the dependency for test substitution, delegating to the public constructor |
66   
67   ### Native interop (P/Invoke)
68   
69   | Banned | Reason | Use instead |
70   |---|---|---|
71   | `[DllImport]` | Project convention uses `[DllImport]` | `[DllImport]` with explicit `CallingConvention = CallingConvention.Cdecl` |
72   | `[return: MarshalAs(UnmanagedType.Bool)]` | `UnmanagedType.Bool` is a 4-byte Win32 `BOOL` - wrong for a C99 `_Bool` (1 byte), and wrong on Linux | Declare C99 bool returns as `int`, compare `!= 0` at the call site |
73   | Calling a static inline function not exported by the shared library | Can't be P/Invoked directly | Reimplement by reading the native struct layout via `Marshal.ReadIntPtr` and invoking the function pointer through a typed delegate |
74   
75   ### NuGet
76   
77   | Banned | Reason | Use instead |
78   |---|---|---|
79   | Directly editing `.csproj` / `Directory.Packages.props` to add or remove packages | Bypasses restore/consistency checks | `dotnet add package` / `dotnet remove package` |
80   | Creating a `nuget.config` in the project directory | NuGet sources are configured in the user's global config; a missing source should fail the build, not be silently added | Let the build fail if a required source is missing |
81   | `-Debug` / `-Release` suffixes on package names | Not a real package naming convention | Use the base package name; the build configuration goes on the package as a tag |
82   
83   ## General rules
84   
85   - Follow the project's own existing conventions first, then common C# conventions.
86   - Use file-scoped namespaces.
87   - Always use `Program.Main()`-style `Program.cs`. Do not use top-level statements or global usings.
88   - Keep `Program.cs` as small as possible - only composition/bootstrap, no business logic.
89   - Use async `Task` / `Task<T>` for I/O operations. Never use blocking calls (`.Wait()`, `.Result`).
90   - Prefer native C# types (`int`) over less common native-width types (`uint`).
91   - Use extension methods where practical (eg `AddConsoleApp()` for service registration).
92   - Only use `Debug` for dotnet build configurations.
93   
94   ## Project / layer structure
95   
96   - Core layer: interfaces and abstractions only, zero external dependencies beyond what Core itself provides.
97   - Infrastructure layer: lower-level plumbing implementations of Core interfaces.
98   - Application layer: business logic implementations of Core interfaces.
99   - Library code is split into DTOs and services - do not mix data and behaviour in one class.
100  - Each public class has exactly one concern and one primary code path. If a class gains a second concern or code path, split it into two classes before adding more logic.
101  - Don't add interfaces/abstractions unless they wrap an external dependency or exist for test substitution.
102  - Don't wrap existing abstractions in another abstraction.
103  - Don't add unused methods or parameters.
104  - When fixing an issue in one method, check sibling methods for the same issue.
105  - Reuse existing methods instead of duplicating logic.
106  
107  ## Program.cs / DefaultApplicationBuilder pattern
108  
109  Use the `DefaultApplicationBuilder` (console apps) or `WebApplicationHostBuilder` (web apis) pattern. DI wiring lives in a separate static class, not in `Program.cs`. Register services in logical order: logging first, then infrastructure, then application services. Use SOLID principles and extension methods where practical.
110  
111  Reference example: `C:\git\external\WebNon-WebHostingExamples\Metalhead.Examples.Hosting.CAB.ConsoleApp`. That project uses Serilog - ignore that part, this project uses Nlog only (the established Ipscm NLog libraries).
112  
113  For console apps with multiple launch scenarios, use `CommandLineParser` to parse options - there is no default behaviour; if no command-line parameters are given, show the user the available options. Resolve the handler for a given option through DI:
114  
115  ```csharp
116  _serviceCollection.Resolve<ServiceThatIsForThisCommandLineOption>().Execute();
117  ```
118  
120  `CommandLineHandler.cs` should contain only `CommandLineOptions` definitions - no execution logic.
121  
122  ## Dependency injection
123  
124  - Constructor injection for every dependency. No service locators.
125  - Use the Autofac NuGet package with a static `AutofacContainer.Create()` method on an `AutofacContainer` class to build the container.
126  - When combining Autofac with ASP.NET Core (`AutofacServiceProviderFactory`), only route services that are never overridden by tests through `AutofacConfig.Configure`. Services that tests override via `ConfigureTestServices` must be registered with `builder.Services.AddSingleton()` in `Program.cs` instead, otherwise the Autofac registration wins and the test override has no effect.
127  
128  ```csharp
129  // CORRECT
130  internal static class AutofacConfig
131  {
132      public static void Configure(ContainerBuilder builder, Action<ContainerBuilder>? containerActions = null)
133      {
134          builder.RegisterType<TlsSecretService>()
135              .As<ITlsSecretService>()
136              .SingleInstance();
137          containerActions?.Invoke(builder);
138      }
139  }
140  ```
141  
142  ```csharp
143  builder.Host.UseServiceProviderFactory(new AutofacServiceProviderFactory());
144  builder.Host.ConfigureContainer<ContainerBuilder>((_, b) => AutofacConfig.Configure(b));
145  ```
146  
147  ## Logging
148  
149  Use type-safe `ILog<T>` injected via the constructor. Never use `LogManager.GetLogger<T>()` or a static logger instance inside a service - that belongs only in composition/bootstrap code or test setup.
150  
151  ## Configuration extraction in constructors
152  
153  Read configuration values into `private readonly` fields in the constructor, not via `configuration["Key"]` calls inside methods. This makes dependencies explicit, avoids repeated lookups, and makes the class easier to test.
154  
155  ```csharp
156  // CORRECT
157  public class MyService(IConfiguration configuration, IHttpClientFactory httpClientFactory)
158  {
159      private readonly string _host = configuration["Service:Host"] ?? "127.0.0.1";
160      private readonly int _port = int.Parse(configuration["Service:Port"] ?? "25");
161      private readonly IHttpClientFactory _httpClientFactory = httpClientFactory;
162  
163      public async Task DoWorkAsync()
164      {
165          var client = _httpClientFactory.CreateClient("name");
166          // uses _host and _port, not configuration
167      }
168  }
169  
170  // BANNED - reads config repeatedly inside methods
171  public class MyService(IConfiguration configuration)
172  {
173      public async Task DoWorkAsync()
174      {
175          var host = configuration["Service:Host"];
176      }
177  }
178  ```
179  
180  ## DTOs and result classes
181  
182  Use properties (`{ get; set; }`), never public fields.
183  
184  ```csharp
185  // CORRECT
186  public class MailpitTestResult
187  {
188      public bool Sent { get; set; }
189      public bool ReceivedByMailpit { get; set; }
190  }
191  
192  // BANNED
193  public class MailpitTestResult
194  {
195      public bool Sent;
196      public bool ReceivedByMailpit;
197  }
198  ```
199  
200  ## getting string values from an object and then using the string for further processing
201  
202  eg
203  ```csharp
204  function void GetImage(string imageName)
205  {
206      Image image = GetImageByName(imageName);
207  }
208  
209  var image = GetImagesFromAWS();
210  string imageName = image.Name;
211  if (!string.IsNullOrEmpty(imageName))
212  {
213      GetImage(imageName);
214  }
215  ```
216  
217  ## Filter before you model
218  
219  If a model type would need to be nullable only because it's built from an unfiltered source collection, filter the source collection first. The nullability is a sign the filtering step missing, not a reason to add `?`.
220  
221  ```csharp
222  // BANNED
223  public void BadFunction()
224  {
225      var imagelist = GetImagelist();
226      List<AmiModel?> amiModels = GetAmiModelsFromImagelist(imagelist); // should never need to be nullable
227  }
228  
229  // CORRECT
230  public static bool MeetsCriteria(this Image image)
231  {
232      //use exit-gate pattern to return early if criteria not met. eg
233      if (!image.SomeProperty)
234      {
235          return false;
236      }
237      if (image.AnotherProperty < 0)
238      {
239          return false;
240      }
241      return true;
242  }
243  public List<Image> GetImagelist()
244  {
245      List<Image> images = _awsImageService.GetImages();
246      return images.Where(x => x.MeetsCriteria()).ToList();
247  }
248  public void GoodFunction()
249  {
250      var candidateImageList = GetImagelist().Where(IsCandidateImage).ToList();
251      List<AmiModel> amiModels = GetAmiModelsFromImagelist(candidateImageList);
252  }
253  ```
254  
255  ## Native interop (P/Invoke)
256  
257  Always use `[DllImport]` with explicit `CallingConvention = CallingConvention.Cdecl`. Never use `[return: MarshalAs(UnmanagedType.Bool)]`.
258  
259  ## Testing
260  
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
- Test configuration (ports, paths, connection strings) goes in `private const` fields or fields assigned in `[OneTimeSetup]` - never environment variables. This keeps the test self-documenting and deterministic.
- Console-app service injection from tests: set a static `Func<IServiceProvider?> ServiceProvider` property on `App` before the test fixture runs (in its constructor); the app calls it at startup. Do not add a `??` fallback on `ServiceProvider` - tests must set it explicitly so missing wiring is caught immediately.
- Extract shared Arrange code (repo/project/environment substitute setups) into a static `*TestDataFactory` class instead of copy-pasting it across tests.
- Merge near-duplicate tests that only vary a couple of values into one `[TestCase(...)]`-parameterized test rather than keeping separate near-identical methods.
- Pass `[TestCase]` arguments positionally, not as named arguments - a named argument used to skip an optional parameter is a sign that value should be its own `[TestCase]` parameter instead.
- Add a one-line comment above any `[TestCase]` block whose values aren't self-explanatory (eg `[TestCase(true)]`/`[TestCase(false)]`) stating what each parameter represents.
- Use `[SetUp]` for Arrange code shared by every test in the fixture, instead of repeating it at the top of each `[Test]` / `[TestCase]` method.
  
  ## Patterns to avoid
  
- Do not create `Null*` fallback implementations (`NullService`, `NullRealtimeService`, etc). These hide missing required dependencies and mask failures. If a dependency is required, fail fast - don't silently no-op.
- Do not write inline `NullLog` / `NoOpLogger` classes in production code or test files.
- Do not use environment variables to inject runtime or test configuration (ports, connection strings, etc). The only exception is where a library explicitly requires environment variables for its own configuration (eg `GITHUB_API_KEY`, `OPENAI_API_KEY`).
- Do not provide default/fallback behaviour when required startup arguments are absent - show usage text and exit. Silent fallbacks hide misconfiguration and leave an untested second code path.
  
  ## NuGet
  
  Never directly edit `.csproj` or `Directory.Packages.props` to add or remove packages - use `dotnet add package` / `dotnet remove package`. Direct editing is permitted only to change the version of an already-referenced package.
  Always check for and use the latest nuget packages. don't do a general search and assume you know what the latest is. query the nuget.org feed directly and ensure that we are using the latest. 
  Version updates require verification: confirm the target version exists, determine whether it's managed per-project or centrally, update it, then run `dotnet restore`.
  
  Do not create a `nuget.config` in the project directory. If a required NuGet source doesn't exist, let the build fail rather than adding one - sources are configured in the user's global config only.
  
  Do not append `-Debug` or `-Release` suffixes to package names. Build configuration is recorded as a tag on the package, passed via the `buildConfiguration` parameter to `build.xml` into the msbuild task that creates the NuGet package.

## Uplift lessons (learned retargeting an old .NET Framework library)

### Project scaffold and references

- `dotnet new` with a relative `-o` writes the project into the current working directory rather than the intended repository. Pass an absolute path, then list the directory to confirm where it landed.
- Retarget the framework before adding packages. Adding a package to a project that is still on an out-of-support TFM emits NETSDK1138 and can resolve an older dependency graph, and a `netstandard2.0` library cannot reference a `net10.0` project at all.
- `dotnet add reference` validates TFM compatibility and can report an error while still leaving the project file in a surprising state. Re-read the csproj after adding several references instead of trusting one success message.
- A class library created from the `classlib` template that is meant to be an application needs `<OutputType>Exe</OutputType>` (or `WinExe`). Without it the solution builds successfully and produces a dll, then the app fails at launch with "hostpolicy.dll required to execute the application was not found ... runtimeconfig.json was not found". A green build is not proof that an app runs: launch it.
- Delete `bin` and `obj` after retargeting. Artifacts for the old target framework stay on disk and mislead later searches and packaging steps.
- `git mv <dir> <newdir>` moves the whole tree, so the follow-up `git mv <olddir>/<file> <newpath>` calls fail with "bad source". Rename files first, then the directory, and finish with `git status --short` to see what git actually recorded.

### Naming

- The uplift includes the names. Replace legacy suffixes (`*Lib`) and vendor prefixes with the layer names the patterns already use (`*.Core`, `*.Infrastructure`, `*.Application`, `*.Cli`, `*.Ui`, `*.Tests`), and rename namespaces and files to match - a file called `XEngine.cs` whose class is still `X` costs the next reader a search.

### Formatting gate

- `dotnet format --verify-no-changes` fails on the tab-indented files inherited from an old codebase, and `dotnet format` rewrites them. Expect one large whitespace-only diff on the first uplift, and run `dotnet format` yourself before the first CI run rather than diagnosing it from a red pipeline.

### Public repository hygiene

- A public repository cannot restore an internal package feed. If an internal library implements a pattern the project needs, copy only the source that is required into the repository and rename the types and namespaces to the project's own names. The internal package name must not appear anywhere in the public repository.

### Failure policy

- Decide the failure policy before building a UI on top of a long-running operation. An engine that aborts on the first file error can never report "completed with 2 errors", and a progress contract with only start/end events cannot show per-item state. Report a state per item (pending, copying, completed, failed, skipped) and keep a failing item from stopping the rest when the user is meant to see the whole run.

### Async callbacks

- Progress callbacks that are posted to a UI context can arrive after the operation has completed and overwrite the final status. Guard the callback with a flag that is cleared only once the terminal state has been written.
- A minimal in-place implementation of an abstraction that returns an already-completed task changes the ordering of posted callbacks. Do not let production code depend on progress arriving before completion.

### Avalonia

Rules that are specific to Avalonia desktop applications and their headless tests live in [patterns/avalonia.md](../../../patterns/avalonia.md). They are not repeated here.

### Async UI work

- Dispatch every file, directory or network call from the view model through `Task.Run`, so the UI thread is free whatever the injected service does. Prove it in a journey test by having the double record `Environment.CurrentManagedThreadId` and comparing it with the test body's thread.
- Do the reconciliation that finishes a job (recording per-item state, building the results) in one pass after the awaited operation returns, and run that pass off the UI thread too. It is the same mistake as blocking the scan: a hundred thousand items applied one notification at a time freezes the window at the end of the copy instead of the beginning.
- Persist settings through a single background writer that coalesces to the latest value, and apply loaded settings behind a guard flag so loading does not raise the change handlers that save.
- Once work runs off the UI thread, a click returns before the job does. A test that asserts straight after `RunJobs()` is a race: pump `RunJobs()` in a bounded loop until the expected state appears, then assert.

### Long-running job workflow

- Lock the inputs when the job starts, not just the button that started it. Every path field, browse button and option control needs its own `IsEnabled` binding, otherwise the user can change the source folder halfway through a copy and the screen no longer describes the job that is running.
- Put conflict handling where the destination `FileInfo` is already in hand, and give every policy its own real-file test. A policy exercised only through test doubles misses the branches real IO takes: one method can honour the already-copied set in its directory loop and re-copy the same file in its single-file branch, and no double reports the difference.
- A retry policy is three decisions, not one: classify the error, then choose the attempt count and the delay. Retrying an access-denied failure ten times turns a fast skip into a stalled job.
- Persist a resumable job as an append-only record and delete it only when the run ends with no failures. Rewriting a status file at each step loses the state of a crashed run, and deleting it on cancel makes resume impossible.
- Validate the whole job before the scan: source exists, source readable, folders differ, neither nests inside the other, destination writable, free space sufficient. Each check is one call and prevents a long copy that fails at the end.

### Reading a real directory tree

- `Directory.EnumerateFiles(path, "*", SearchOption.AllDirectories)` throws as soon as one entry cannot be resolved, and on a developer machine that entry is usually a symbolically linked directory inside a source tree you do not own. The failure reads like a path error ("the file cannot be accessed by the system") but the effect is that a whole scan or copy never starts.
- Walk the tree yourself with an explicit stack, catch `IOException` and `UnauthorizedAccessException` per folder, and count what you could not read. A count shown to the user is honest; an aborted scan is not.
- Skip directories carrying `FileAttributes.ReparsePoint` when only measuring. Following them produces cycles and double counting, and no total is worth an unbounded walk.
- Classify the exception once, where it is caught, and report the kind: access denied, missing folder, path too long, invalid path, read or write error. Unwrapping to the innermost exception matters because the outermost is often a wrapper that says nothing useful.
- Test the classification with a control that throws the exception you need, and cover the real-world scan against a large real tree once by hand. A unit test can assert the message, but only the real tree proves the scan returns.

### Ordering and test doubles

- Record terminal per-item state in the reporter itself, under a lock, and reconcile it after the awaited operation returns. State written only from the posted progress callback can be missing at the instant the operation completes. That defect passes when the test runs alone and fails in the suite, because another test has installed a synchronization context that queues the callbacks.
- When a test passes alone and fails in the full suite, run the single test first. The cause is cross-test state or async ordering, and it is not in the code you were about to change.
- Parameterise test doubles instead of duplicating them: one preset per interface with settable outcomes (writable, readable, free space, failing items, interrupted job, stored preferences) serves every test and needs one edit when the interface grows.
- Keep the failure simulator in the test project. Production never references the test project, so no `#if DEBUG` is needed, and nothing needs `InternalsVisibleTo` to keep a double out of the shipped assembly.
- An interface rename or a new interface member reaches further than the compiler shows: container registrations, view models, and every test helper that takes the interface as a parameter. Search the test project for the old name, because the factories that build a view model for tests are the call sites the build errors do not point at.
- Give counts and stored state priority over strings when asserting progress. Assertions on a status message pass or fail with callback timing, while assertions on counters, recorded job entries and the requested skip list describe the outcome the code is responsible for.

### Starting expensive work immediately

- Never put an expensive measurement in front of an operation the user asked for. A recursive scan of the source tree is the commonest example: it is fast on the test fixture and minutes on a real tree, and while it runs nothing the user asked for has happened. Start the work, then measure alongside it.
- Start the operation with a small share of the available parallelism, and open it up once the measurement finishes. The measurement is metadata IO on the same disk, so it competes with the copy for the queue; one working thread plus one measuring thread leaves room for both, and the copy then ramps to the full count. On a large tree of small files the measurement usually finishes long before the copy, so the throughput cost of the ramp is negligible and the wait it removes is not.
- A shared semaphore is how the ramp is implemented: create it with the starting permit count and `Release(n)` to raise the limit. Only ever raise it mid-operation. Lowering it either blocks the caller or needs a permit-reclaim scheme, and no user has asked for that.
- Poll the requested limit where the work item waits for a permit rather than pushing an event across threads. The wait site is already the place that knows the limit, and a poll costs nothing when the value has not changed.
- Progress needs two modes, not one: indeterminate until the total is known, then a percentage. Format the counters for both ("Files copied: 1,245" then "Files copied: 1,245 / 208,516") instead of showing a zero total, and keep the sum of copied bytes visible throughout, which is the number the user watches.
- Validate at the moment the input is chosen, using only checks that answer without walking anything: exists, readable by one directory read, same folder, nested folder, writable by one probe file. Move the readable and writable probes off the UI thread anyway; a network path answers slowly and the field must not stutter. Give the validation result a completion signal so the UI can distinguish still checking from valid, and discard a result whose inputs have changed since it started.
- The count may legitimately fail or be cancelled; that must not fail the copy. Reconcile the count's result after the operation returns and only apply it if it was not already applied, so the final state does not depend on which continuation ran first.

### Per-item progress and comparison

- Report progress inside an item, not only when it finishes. A per-item state of copying with no byte count is indistinguishable from a hung operation on a large file, and a run made of a handful of large items then shows nothing until each completes. Add a byte count to the in-progress report.
- Throttle those reports with a clock, not with a chunk counter: a shared `Environment.TickCount64` gate updated by `Interlocked.CompareExchange` gives a fixed report rate across every thread copying at once, and it costs one read per chunk. Make the interval an option so a test can set it to zero and assert on the reports deterministically.
- Keep the per-item view keyed by item path in a concurrent dictionary and remove entries on every terminal state, including the ones you did not expect. An entry that never leaves the view after a failure looks like a stalled copy.
- Mutation of the observable collection that backs a view happens on whichever thread reported progress when no synchronization context exists, and the framework collection throws corruption errors that read like an off-by-one in your own code. Guard the collection with a lock in the view model as well as posting to the context; the lock costs nothing and the alternative is a crash in a test that runs without a dispatcher.
- A comparison feature is two axes, presence and content, and each needs its own state: missing on the target, missing on the source, present with identical content, present with different content. Collapsing them into one boolean loses the distinction the user acts on.
- Compare content only when sizes match, and only for files present on both sides. Checksumming a file that only exists in one place compares nothing and costs a full read.
- Aggregate a per-item state up a tree as a priority, not a count: any difference outranks any missing item, which outranks an identical one. Also mark every ancestor as "has data" when a descendant has any, otherwise a root node reports nothing was compared while its children know better.
- Filtering a tree view is cheaper as a per-node visibility flag bound from a container style than as a rebuilt filtered collection. The flag keeps node identity, expansion state and lazy loading intact, and the filter itself is a bottom-up pass that keeps a node visible when it or any descendant matches.

### Diagnostics you can point at

- A long-running desktop operation needs a durable log the user can open after the fact. Write plain text to a `logs` folder under the working directory, log one line at startup so the file exists even when nothing else happens, and give the window a button that opens the file with the shell rather than a log viewer.
- Reading a file that another process may hold is the usual source of access denied. Open source files with `FileShare.ReadWrite | FileShare.Delete`, and destination files with at least `FileShare.ReadWrite`, so an open copy does not lock out the application that wants to inspect or move the file. Reserve `FileShare.None` for a case where exclusivity is the whole point.

### Retry layers

- Two retry loops stacked on the same operation is a hang waiting to happen. The inner loop retries the raw IO failure and only the outer one knows the user policy, so a policy of "skip a locked file" is defeated by an inner loop that sleeps through twenty attempts first. Rethrow every failure the outer layer classifies - sharing violations and access denied included - and let the inner loop retry only what it can genuinely fix, such as a short read.
- Multiply the knobs before shipping them: twenty attempts at ten seconds is over three minutes per file, and with four slots a folder of locked editor index files stalls the whole copy for tens of minutes while every other file waits behind it. A retry budget is a wall-clock promise, not a count.
- Never `Thread.Sleep` inside an async loop that holds a semaphore; it parks a pool thread and keeps the permit. Use `await Task.Delay` so the slot can still be released or cancelled.
- Log every retry with its timestamp. The log is what turns "the app is hung" into "it has been retrying one locked file for eleven minutes", and it is the first thing anyone will ask for.
- A status line that counts only successes reads as frozen while the run skips hundreds of thousands of files. Show the processed count, and keep the succeeded count in the summary.

### Admission versus work

- A concurrency limit is a promise about how much work is running, not about how many operations are in flight. An operation that is sleeping between retries is not running: it must give its permit back before it waits and take it again for the next attempt, or a handful of doomed items consume the whole budget and the run makes no progress while looking busy.
- Bound the two populations separately: the number of running items, and the number of in-flight items that may be waiting. The first is a performance decision the user makes; the second is a memory and thread-safety decision you make, and it is the only thing protecting you when a source tree of two million unreadable entries arrives.
- Size the thread budget from the running-item limit, not the file count: threads per item times running items, capped at a constant. Deriving both from a single "multi-threaded" flag leaves four running copies sharing four threads, which is one real copy and three queues pretending to be busy.
- Only one layer retries. A chunk-level loop that retries IO failures defeats a policy layer that knows the user asked to skip locked files, and it multiplies budgets: twenty attempts at ten seconds is three minutes per file, per slot, silently. Reclassify at the boundary instead: access denied and sharing violations belong to the policy, transient read faults to the loop that owns the buffer.
- Classify by the error the OS actually returned, and include the ones that do not look like access problems. On Windows, `ERROR_CANT_ACCESS_FILE` (1920) arrives as an `IOException` from a reparse point that cannot be resolved, and it will never succeed on retry; it belongs with `ERROR_ACCESS_DENIED` (5), not with the transient set.
- A failed attempt that created a temporary destination file must delete it on the way out, or every unreadable source file leaves a zero byte artefact that the user will report as a new bug.
- Offer zero as a value in every "how many times" setting. Zero is the correct answer for a whole class of inputs, and without it the user has no way to say "do not retry this, it will never work".

### Adaptive concurrency

- A configured concurrency limit is a ceiling, not a starting point. Start at one unit of work, give it the whole thread budget, and add another only while the measured throughput keeps up. Starting at the ceiling means a spinning disk gets four seeks interleaved from the first byte and every small file waits behind a large one.
- Measure the device by throughput, not by utilisation. Per-device counters are platform specific, need privileges or extra packages, and report 100 percent for a queue that is saturated with seek thrash. Aggregate bytes per second is portable and is the number the user actually cares about.
- Compare each sample with the previous one, not with an all time best. A copy of two large files establishes a throughput that a folder of small files can never match, and an all time high water mark freezes the ramp for the rest of the run. A previous-sample comparison with a 15 percent tolerance tracks the current regime and resumes expanding after a dip.
- Make the ramp a pure, unit tested object with `NextLimit(bytesSinceLastSample, elapsed, hasPendingWork)`. Timing based tests of a live scheduler are slow and flaky; a pure function covers every branch in milliseconds, and the engine keeps only the sampling.
- Only expand while there is pending work; otherwise the limit climbs at the end of a copy for no benefit.
- Make the sample interval an option so a test can shorten it, and log each expansion with the throughput that justified it. That log line is how you tell a saturated device from a stalled one.
