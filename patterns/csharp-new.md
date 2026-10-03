c# Coding patterns.

use the default application builder pattern in c#. program.cs should be as small as possible.
for all of the library code - seperate classes into DTOs and services.
dependency injection wiring could go into a seperate static class other than program.cs.
use commandlineparser for handling different launch scenarios in the console app.
do not have a default behaviour.
show the user the options if there are no command line parameters.

Core interfaces and abstractions are in the Core layer and have zero external dependencies beyond what the Core layer provides.
Implementations go in Infrastructure (for lower-level plumbing) or Application (for business logic) layers.
Use SOLID principles and extension methods where practical. DefaultApplicationBuilder pattern for DI setup.

there is a good example of the pattern under

C:\git\external\WebNon-WebHostingExamples\Metalhead.Examples.Hosting.CAB.ConsoleApp
C:\git\external\WebNon-WebHostingExamples\Metalhead.Examples.Hosting.CAB.ConsoleApp

note this project uses serilog not nlog. ignore serilog, you should definately use nlog only (using the established ipscm libraries for nlog).

Services use constructor injection for all dependencies.
No service locators.
Do not call command line tools in c# code unless specifically mentioned in the application requirements documents.

Logging uses ILog<T> injected via constructor. Never use LogManager or static logger instances.

Classes should have a single concern and only a primary code path.
If a class has more than concern or more than one primary code path consider it for refactoring into two classes.
Each public class has one primary code path. If a class has multiple concerns, split it into separate classes before adding more logic.

Do not create dynamic types or records for any reason at any time.
prefer c# native types - eg int over any native types - eg uint.

Use file-scoped namespaces.
Always use program.main() style program.cs.
do not use global usings.


Configuration extraction in service constructors

Read configuration values into private readonly fields in the constructor rather than calling configuration["Key"] inside methods.

This makes dependencies explicit, avoids repeated lookups, and makes the class easier to test.


// CORRECT

public class MyService(IConfiguration configuration, IHttpClientFactory httpClientFactory)
{
    private readonly string _host
        = configuration["Service:Host"] ?? "127.0.0.1";

    private readonly int _port
        = int.Parse(configuration["Service:Port"] ?? "25");

    private readonly IHttpClientFactory _httpClientFactory
        = httpClientFactory;

    public async Task DoWorkAsync()
    {
        var client = _httpClientFactory.CreateClient("name");

        // uses _host and _port, not configuration
    }
}


// WRONG - reads config repeatedly inside methods

public class MyService(IConfiguration configuration)
{
    public async Task DoWorkAsync()
    {
        var host = configuration["Service:Host"];
    }
}


Autofac with ASP.NET Core - IServiceCollection vs ContainerBuilder

When using Autofac.Extensions.DependencyInjection.AutofacServiceProviderFactory,
services registered in AutofacConfig.Configure via ContainerBuilder.RegisterType<T>()
override registrations in IServiceCollection.

This breaks WebApplicationFactory.ConfigureTestServices test overrides because the production Autofac registrations win.

Pattern:

Register services that are mocked in tests via builder.Services.AddSingleton() in Program.cs.

Use AutofacConfig.Configure only for services that are NOT overridden in tests
(e.g. infrastructure services requiring Autofac-specific lifetime management or assembly scanning).

Example AutofacConfig.cs

internal static class AutofacConfig
{
    public static void Configure(
        ContainerBuilder builder,
        Action<ContainerBuilder>? containerActions = null)
    {
        builder.RegisterType<TlsSecretService>()
               .As<ITlsSecretService>()
               .SingleInstance();

        // Override registrations for tests
        containerActions?.Invoke(builder);
    }
}

Wire up in Program.cs

builder.Host.UseServiceProviderFactory(
    new AutofacServiceProviderFactory());

builder.Host.ConfigureContainer<ContainerBuilder>(
    (_, b) => AutofacConfig.Configure(b));


Properties not public fields

DTOs and result classes must use properties ({ get; set; }) not public fields.

Public fields bypass encapsulation, break serialization in some contexts, and cannot be overridden or databinding-aware.


// CORRECT

public class MailpitTestResult
{
    public bool Sent { get; set; }
    public bool ReceivedByMailpit { get; set; }
}


// WRONG

public class MailpitTestResult
{
    public bool Sent;
    public bool ReceivedByMailpit;
}


Use interfaces in Core layer.
Implementations in Infrastructure or Application layers.
Core has zero external dependencies.

Use DefaultApplicationBuilder pattern for DI setup.
Register services in logical order: logging first, then infrastructure, then application services.

Keep classes single concern.
Use the service pattern.

Use constructor injection for dependencies.

Don't create private classes.
Make types public or internal.

Keep the Main method in a project as minimal as possible.

Classes should have only 1 primary code path - if there are more than one split the class.

Use the Autofac nuget package and create an static AutofacContainer.Create() method.
in the AutofacContainer class and use this to setup the container.

Use extension methods where practical.

All services accept required parameters in constructor.
No static service locators.

Use type-safe logging with ILog<T>.
Never use LogManager or static logger instances.
Inject logger via constructor.

Use async Task for I/O operations.

Return Task<T> from services.

Never use blocking calls like Wait() or Result.

Only use nullable if this is most optimal.


Native interop (P/Invoke)

Always use [DllImport] with explicit
CallingConvention = CallingConvention.Cdecl.

Never use [LibraryImport] or [return: MarshalAs(UnmanagedType.Bool)].

C99 bool (_Bool) is 1 byte.

UnmanagedType.Bool is a 4-byte Win32 BOOL
and is wrong on Linux.

Declare C99 bool returns as int
and compare != 0 at the call site.

Static inline functions not exported by the shared library must be reimplemented in C# by reading the native struct layout directly via Marshal.ReadIntPtr and invoking the function pointer through a typed delegate.


dotnet guidelines.

Only use Debug for dotnet build configurations.

Pass the buildConfiguration parameter to build.xml to include it in the msbuild task that creates the nuget package.

this build configuration value should be added as a nuget package tag.


Software architecture.

When creating a new console app, or webapi use DefaultApplicationBuilder or WebApplicationHostBuilder patterns.

Use extension methods for service registration.
eg .AddConsoleApp


Patterns/practises to avoid.

Do not create Null* fallback implementations
(NullService, NullRealtimeService, etc).
These hide missing required dependencies and mask failures.

If a dependency is required, fail fast – don't silently no-op.

Do not write inline NullLog/NoOpLogger classes in production code or test files.

Use the proper logging infrastructure
(*.Library.Logging + LogManager.GetLogger<T>()).

Fake loggers hide real issues and create dead code.

Do not use environment variables to inject test configuration
(ports, connection strings, etc).

Put required config in private const or private fields initialised in [OneTimeSetUp].

Tests should run or fail deterministically and not silently skip based on environment state.

Do not mark integration tests [Explicit] or gate them on environment variable checks.

Integration tests should always run and fail clearly when infrastructure is missing – that is the signal.

Do not provide default/fallback behaviour when required startup arguments are absent.

Show usage and exit.
Silent fallbacks hide misconfiguration.


helper knowledge

Logging in tests:

use *.Library.Testing
(TestUtils.BuildTestConfiguration())

+ *.Library.Logging
(new LogBuilder(config).Build())

then LogManager.GetLogger<T>().

Never mock or stub ILog<T> with a hand-rolled NullLog.
it hides log output that is useful for diagnosing test failures.

Test configuration:

all values a test needs
(ports, paths, connection strings, etc).

go in private const or private fields assigned in [OneTimeSetUp].

This makes the test self-documenting and deterministic.

Do not use environment variables to inject test configuration
(ports, connection strings, etc).

Console app service injection from tests:

set a static Func<IService>? ServiceProvider property on App before the test fixture runs (in the constructor).

The app calls it at startup.

Do not use a fallback null-safe operator (??) on ServiceProvider.
tests must set it explicitly so missing wiring is caught immediately.

When an app has required startup arguments, enforce them at the entry point and exit with usage text.

Do not silently fall back to a default mode.
the fallback path is never tested and creates two code paths to maintain.

Use the CommandLineParser nuget packages for applications that require command line options.

Use DI to resolve the service which processes that command line option.

Example:

_serviceCollection.Resolve<ServiceThatIsForThisCommandLineOption>()
                  .Execute();

commandlinehandler.cs should only have CommandLineOptions code in it.