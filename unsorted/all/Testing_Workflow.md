# Solution Architecture & Testing Framework

## Executive Overview

This document describes a comprehensive end-to-end testing architecture for a modern .NET application with separate API and Web UI components. The solution implements an integrated testing framework using Playwright for browser automation, combined with a sophisticated test server pattern that executes application components in-process for efficient integration testing.

The architecture is designed to enable:
- Parallel test execution with isolated server instances
- Full end-to-end testing without external dependencies
- Comprehensive coverage of critical user workflows
- Clear separation of concerns through Page Object Model patterns
- Automatic browser lifecycle management through the NUnit testing framework

---

## Solution Structure

### High-Level Organization

```
Solution/
├── Application Projects (src/)
│   ├── RESTful API (Minimal APIs pattern)
│   └── Web UI (Blazor Server with InteractiveServer components)
├── Test Infrastructure (tests/shared/)
│   ├── Base test classes
│   ├── Common configuration
│   └── Test server management
├── API Test Project (tests/api/)
│   └── HTTP endpoint validation tests
├── UI Test Project (tests/ui/)
│   ├── Individual page/component tests
│   └── Critical user journey tests
└── CI/CD Scripts (ci/)
    ├── Lint verification
    ├── Build and test orchestration
    └── Environment simulation
```

### Project Types

1. **API Application Project**: Minimal ASP.NET Core Web API exposing RESTful endpoints
2. **Web UI Application Project**: Blazor Server application with InteractiveServer render mode
3. **Shared Test Infrastructure Project**: Provides base classes, configuration, and shared utilities
4. **API Test Project**: NUnit tests targeting HTTP endpoints
5. **UI Test Project**: NUnit tests targeting Blazor pages and critical workflows

---

## Core Architecture Patterns

### 1. In-Process Test Server Pattern (WebApplicationFactory)

Instead of running applications externally and testing over the network, the testing framework uses Microsoft's `WebApplicationFactory` pattern to host both the API and UI servers in-process during tests.

**Key Characteristics:**
- Both application instances are created fresh for each test
- Applications run on dynamically assigned ports (port 0)
- Enables parallel test execution without port conflicts
- Supports full dependency injection access for test setup/verification
- Servers are isolated to a single test and disposed after completion

**Implementation Details:**
- The test infrastructure class (`Sut` - System Under Test) extends `WebApplicationFactory`
- Overrides `ConfigureWebHost` to use dynamic ports
- Overrides `CreateHost` to switch from TestServer to Kestrel
- Uses `IServerAddressesFeature` to extract the dynamically assigned URL
- Kestrel is required because Playwright (running in a real browser) needs a real HTTP endpoint

**Benefits:**
- Tests run entirely in-process with no external service dependencies
- Enables access to application state and services for complex test scenarios
- Supports parallel execution - each test gets its own server instance
- Realistic HTTP communication (identical to production networking)

**⚠️ CRITICAL: WebApplicationFactory Host Initialization**

WebApplicationFactory uses **lazy initialization** - the host is not created until first use. When accessing properties like `ServerAddress` (which extracts the actual listening port from `IServerAddressesFeature`), you must force host creation first:

```csharp
[SetUp]
public async Task BeforeTestCase()
{
    Sut = _scope.ServiceProvider.GetRequiredService<AlsionyxSut>();
    
    // ❌ WRONG: ServerAddress will be empty!
    // ApiBaseUrl = Sut.ServerAddress.TrimEnd('/');
    
    // ✅ RIGHT: Force host creation by making HTTP request
    using var httpClient = Sut.CreateClient();
    await httpClient.GetAsync("/api/health");  // Triggers CreateHost()
    
    // Now ServerAddress is populated with actual listening URL
    ApiBaseUrl = Sut.ServerAddress.TrimEnd('/');
}
```

**Why This Matters**:
- `ServerAddress` property is only populated in `CreateHost()` method
- `CreateHost()` only called when WebApplicationFactory creates resources
- Creating an HttpClient (`CreateClient()`) triggers this initialization
- Without this, `ServerAddress` remains empty string, causing "Invalid URL" errors
- This is especially critical for Playwright tests where Page.APIRequest needs valid URLs

### 2. Base Test Class Hierarchy

All integration tests inherit from a shared `PlaywrightTestBase` class:

```
PageTest (from Microsoft.Playwright.NUnit)
  └── PlaywrightTestBase (shared infrastructure)
      ├── API Tests
      ├── UI Page Tests
      └── Critical Journey Tests
```

**Responsibilities of PlaywrightTestBase:**
- Inherits from `PageTest` for automatic browser lifecycle management
- Initializes the System Under Test (in-process servers) before each test
- Configures browser context options (e.g., video recording for debugging)
- Manages test timeouts and default wait times
- Handles video capture on test failure for debugging
- Implements cleanup after test completion

**Key Features:**
- `[SetUp]` method creates a fresh Sut instance and dependency injection scope
- `ContextOptions()` override enables video recording to `videos/` directory
- `[TearDown]` method disposes browser context and saves video with test name
- `[Parallelizable(ParallelScope.Self)]` attribute enables parallel test execution
- Sets reasonable defaults: 30-second timeouts for navigation and general operations

### 3. Browser Lifecycle Management

Browser and context management is handled by the `PageTest` base class from the Playwright NUnit package.

**Automatic Process:**
1. On first test run, Playwright CLI automatically downloads browser binaries
2. Binaries are cached in system-specific directory (~/.playwright)
3. Browser instance created per test method (not shared)
4. Page context created with custom options (video recording directory)
5. Page lifecycle hooks: SetUp (before test), TearDown (after test)
6. Context cleanup automatically disposes resources

**Configuration Source:**
- Browser type, launch options, and features configured via XML-based `playwrightconfig.runsettings`
- Separate configuration files for each test project (API and UI tests may use different browsers)
- Configuration is copied to output directory during build

**Benefits:**
- Zero manual browser installation scripts required
- Cross-platform support (Windows, Linux, macOS) via .NET
- Configuration-based (not code-based) browser behavior
- Automatic caching prevents re-downloading

### 4. Page Object Model Pattern

UI locators and interaction methods are organized through Page Object classes.

**Structure:**
- Base page class: Contains common page operations (navigation, screenshot, wait states)
- Derived page classes: Contain page-specific locators and methods
- Pattern isolates UI changes to page objects, reducing test maintenance

**Usage in Tests:**
- Tests access page elements through page object methods
- Reduces duplication when multiple tests use the same page elements
- Facilitates UI changes without modifying test logic

### 5. Mock Classes vs Production Code: Strict Separation

**⚠️ CRITICAL PRINCIPLE: Mock classes must NEVER appear in production code or dependency injection**

Mock implementations (such as `MockAudioBackend`, `MockAudioDeviceProvider`) are testing utilities ONLY and should:

**CORRECT Architecture (Production):**
```csharp
// In ApiContainerBuilder.cs (PRODUCTION code)
services.AddSingleton<SoundFlowAudioBackend>();      // Real implementation
services.AddSingleton<FileAudioBackend>();           // Real implementation

services.AddSingleton<IAudioBackendService>(sp =>
{
    var logger = sp.GetRequiredService<ILog<AudioBackendService>>();
    var backends = new IAudioBackend[]
    {
        sp.GetRequiredService<SoundFlowAudioBackend>(),  // Real
        sp.GetRequiredService<FileAudioBackend>()        // Real
    };
    return new AudioBackendService(backends, logger);
});
```

**INCORRECT Architecture (Anti-Pattern - DO NOT DO THIS):**
```csharp
// ❌ WRONG: MockAudioBackend in production DI container!
services.AddSingleton<MockAudioBackend>();           // Mock should never be in prod!

services.AddSingleton<IAudioBackendService>(sp =>
{
    var logger = sp.GetRequiredService<ILog<AudioBackendService>>();
    var backends = new IAudioBackend[]
    {
        sp.GetRequiredService<MockAudioBackend>(),     // ❌ WRONG
        sp.GetRequiredService<SoundFlowAudioBackend>()
    };
    return new AudioBackendService(backends, logger);
});
```

**Why This Matters:**
- Mock implementations are tightly coupled to testing patterns
- Production users see "Mock" backend as an actual option
- Mocks may have testing-specific behavior that breaks production workflows
- Violates separation of concerns principle
- Makes the system unreliable in actual use

**Testing with Mocks (Integration Tests Only):**

```csharp
// In test-specific ApiContainerBuilder (TESTS ONLY)
public static void RegisterTestCoreServices(IServiceCollection services, IConfiguration configuration)
{
    // Register MOCK implementations for testing
    services.AddSingleton<IAudioDeviceProvider, MockAudioDeviceProvider>();  // ✅ OK in tests
    services.AddSingleton<ILv2PluginDiscoverer, MockLv2PluginDiscoverer>();  // ✅ OK in tests
    
    // Register real backends (or mocks for unit tests)
    services.AddSingleton<MockAudioBackend>();                               // ✅ OK in tests
    services.AddSingleton<IAudioBackendService>(sp =>
    {
        var logger = sp.GetRequiredService<ILog<AudioBackendService>>();
        var backends = new IAudioBackend[]
        {
            sp.GetRequiredService<MockAudioBackend>()                          // ✅ OK in tests
        };
        return new AudioBackendService(backends, logger);
    });
}
```

**Key Rule: If code uses `Substitute.For<IInterface>()` or instantiates a Mock class, it belongs in Tests/ project only.**

### 6. Global Setup and Dependency Injection

A global setup fixture (`GlobalSetup`) runs once before any tests execute:

**Responsibilities:**
- Invokes Playwright CLI to install browser binaries (with retry logic)
- Creates dependency injection container for test execution
- Registers shared services (logging, System Under Test factory)
- Cleans up resources after all tests complete

**Key Patterns:**
- Uses NUnit's `[SetUpFixture]` attribute
- Implements `[OneTimeSetUp]` and `[OneTimeTearDown]` methods
- Creates async service scope for each test via dependency injection
- Retry logic handles transient failures during browser installation

---

## Testing Framework Architecture

### Test Execution Flow

```
1. NUnit discovers test assemblies
   ↓
2. GlobalSetup.OneTimeSetUp() executes
   - Browser installation via Playwright CLI
   - Dependency injection container created
   ↓
3. For each test method:
   
   a) PlaywrightTestBase.BeforeTestCase() [SetUp]
      - Creates fresh System Under Test (in-process servers)
      - Obtains async service scope from DI container
      - Initializes Sut with scoped services
      - Sets browser context options (video recording)
      - Sets default timeouts
      ↓
   b) Test method executes
      - Browser page is ready via inherited PageTest
      - Sut provides server URL (ServerAddress property)
      - Test uses Sut to navigate/interact with UI
      - Tests can call API via Sut.Services if needed
      ↓
   c) PlaywrightTestBase.AfterTestCase() [TearDown]
      - Closes page context
      - Saves video with test name (for debugging)
      - Disposes Sut (stops in-process servers)
      - Cleans up async service scope
      ↓
4. All tests complete
   ↓
5. GlobalSetup.OneTimeTearDown() executes
   - Disposes dependency injection container
```

### Test Organization

Tests are organized into three distinct categories:

#### Category 1: API Endpoint Tests
**Purpose:** Validate HTTP endpoints in isolation

**Characteristics:**
- Uses Playwright's APIRequestContext for HTTP calls
- Tests status codes, response structure, content types
- Validates business logic at API contract level
- Typically single-assertion per test method
- Fast execution, no UI rendering

**Example Test Scenarios:**
- Endpoint returns HTTP 200
- Response contains expected JSON structure
- Response array has correct element count
- Response includes all required properties

#### Category 2: UI Component Tests
**Purpose:** Validate individual Blazor pages and components

**Characteristics:**
- Tests a single page or logical component
- Validates render state, element visibility, initial values
- Tests user interactions (clicks, form input)
- Verifies page-specific behavior and business rules
- Medium execution time (includes browser navigation)

**Typical Test Organization by Page:**
- Page load success
- Expected content rendering
- Element visibility and state
- User interactions and responses
- Form validation and submission

#### Category 3: Critical User Journey Tests
**Purpose:** Validate complete user workflows across multiple pages

**Characteristics:**
- Multi-step scenario reflecting real user behavior
- Crosses multiple pages and components
- Captures screenshots at each step for documentation
- Validates state persistence across navigation
- Tests complete business functionality

**Example Journey Characteristics:**
- Steps through main application features
- Takes screenshot at each step
- Uses browser navigation controls and links
- Verifies end-to-end integration
- Validates user-facing success criteria

---

## Test Configuration and Execution

### Configuration File: playwrightconfig.runsettings

Each test project contains an XML configuration file defining browser behavior:

```xml
<?xml version="1.0" encoding="utf-8"?>
<RunSettings>
  <Playwright>
    <BrowserName>chromium</BrowserName>
    <LaunchOptions>
      <Headless>true</Headless>
    </LaunchOptions>
  </Playwright>
</RunSettings>
```

**Configuration Elements:**
- `BrowserName`: Specifies browser (chromium, firefox, webkit)
- `LaunchOptions`: Controls browser launch behavior
- `Headless`: Boolean for headless mode
- Additional launch options can include: locale, timezone, device type, proxy settings

**Build Integration:**
- File is copied to output directory during build (`<None Update="...">` in csproj)
- NUnit discovers via `RunSettingsFilePath` property in project file
- Separate configurations per test project allow different browser behaviors

### Environment Configuration

Runtime behavior can be overridden via environment variables:

**Configuration Source Priority:**
1. Environment variables (highest priority)
2. Configuration file (playwrightconfig.runsettings)
3. Code defaults (lowest priority)

**Common Environment Variables:**
- `HEADLESS`: Set to false for visible browser testing
- `API_BASE_URL`: Override API endpoint location
- `BLAZOR_BASE_URL`: Override UI endpoint location

### Project File Configuration

Each test project includes NUnit and Playwright dependencies:

```xml
<PropertyGroup>
  <RunSettingsFilePath>$(MSBuildProjectDirectory)\playwrightconfig.runsettings</RunSettingsFilePath>
</PropertyGroup>

<ItemGroup>
  <PackageReference Include="Microsoft.Playwright.NUnit" Version="..." />
  <PackageReference Include="NUnit" Version="..." />
  <PackageReference Include="Microsoft.NET.Test.Sdk" Version="..." />
</ItemGroup>

<ItemGroup>
  <None Update="playwrightconfig.runsettings">
    <CopyToOutputDirectory>Always</CopyToOutputDirectory>
  </None>
</ItemGroup>
```

---

## CI/CD Pipeline Architecture

### Pipeline Stages

The CI pipeline follows a three-stage model:

```
Stage 1: Lint
  ↓ (exit on failure)
Stage 2: Build
  ↓ (exit on failure)
Stage 3: Test
  ↓ (exit on failure)
Success
```

### Stage Details

#### Stage 1: Code Format Verification (Lint)
**Purpose:** Enforce code style consistency

**Implementation:**
- Uses `dotnet format --verify-no-changes` command
- Checks formatting against `.editorconfig` file
- Prevents merge of misformatted code
- Fast execution (completes in seconds)

**Failure Handling:**
- Non-zero exit code halts pipeline
- Developers must run `dotnet format` locally and re-commit

#### Stage 2: Build and Restore
**Purpose:** Compile solution and verify no build errors

**Implementation:**
- Restores NuGet dependencies: `dotnet restore`
- Compiles all projects: `dotnet build`
- Validates project references and configurations
- Checks for compilation warnings

**Failure Handling:**
- Non-zero exit code halts pipeline
- Compilation errors must be fixed before testing

#### Stage 3: Test Execution
**Purpose:** Run all test suites with browser automation

**Implementation:**
- Executes command: `dotnet test`
- NUnit discovers all test assemblies
- GlobalSetup handles one-time browser installation
- Tests run in parallel (if configured)
- Results summarized with pass/fail counts

**Failure Handling:**
- Non-zero exit code indicates test failures
- Test output shows which tests failed and why

### CI Environment Simulation Scripts

PowerShell scripts in the `ci/` directory simulate GitHub Actions locally:

**`ci.ps1` - Main orchestrator:**
- Navigates to correct directory
- Loads build configuration JSON
- Sequences lint, build, and test stages
- Provides user-friendly output

**`lint.ps1` - Code format check:**
- Runs `dotnet format --verify-no-changes`
- Reports formatting violations
- Does not modify code

**`build-test.ps1` - Build and test:**
- Restores dependencies
- Verifies code format
- Builds solution
- Runs all tests

### Build Configuration File

A JSON file defines solution-level build settings:

```json
{
  "solutionFile": "./PlayWrightDemo.sln",
  "build": { "configuration": "Debug" },
  "test": { "configuration": "Debug" }
}
```

**Properties:**
- `solutionFile`: Path to solution file
- `build.configuration`: Build configuration (Debug/Release)
- `test.configuration`: Test execution configuration

---

## Application Architecture

### API Application

**Technology Stack:**
- ASP.NET Core Web API
- Minimal APIs pattern (no controller classes)
- RESTful endpoint design

**Characteristics:**
- Stateless operation
- JSON request/response format
- HTTP status codes for result indication
- CORS enabled for UI consumption (in production scenarios)

**Typical Endpoint Structure:**
- GET endpoints for data retrieval
- POST endpoints for creation
- PUT/PATCH endpoints for updates
- DELETE endpoints for removal
- Consistent error response format

### Web UI Application

**Technology Stack:**
- Blazor Server
- InteractiveServer render mode
- SignalR for real-time updates

**Characteristics:**
- Component-based architecture
- Server-side rendering with client-side interactivity
- SignalR enables real-time state updates
- Supports form submission and validation
- Static assets served with fallback to index.html

**Component Organization:**
- Layout components for application structure
- Page components for routed views
- Reusable components for common UI patterns
- Interactive components with event handlers

---

## Test Infrastructure Components

### Shared Test Infrastructure Project

**Provides:**
- `PlaywrightTestBase`: Base class for all tests
- `TestConfiguration`: Centralized configuration access
- `BasePage`: Base class for Page Object implementations
- `GlobalSetup`: One-time setup fixture
- `PlayWrightDemoSut`: System Under Test (WebApplicationFactory)

**Responsibilities:**
- Abstract test framework details from test projects
- Provide consistent configuration and initialization
- Enable test projects to focus on test logic, not infrastructure

### Test Data and Scenarios

**API Test Scenarios:**
- Valid request handling
- Response structure validation
- Array/collection size verification
- Property existence and type checking
- Status code validation

**UI Test Scenarios:**
- Page load and render
- Element visibility and accessibility
- User interaction handling
- Navigation between pages
- Form submission and validation
- State persistence across navigation

**Critical Journey Scenarios:**
- Complete user workflows
- Multi-page navigation
- Feature interaction sequences
- State validation at journey endpoints
- Screenshot documentation at key steps

---

## Advanced Testing Patterns

### Screenshot Capture Strategy

Screenshots serve multiple purposes:

**Usage:**
- Documentation of critical user journeys
- Visual debugging of failed tests
- Comparison of before/after UI states
- Evidence of application functionality

**Directory Structure:**
```
screenshots/
├── critical-journey/
│   ├── 01-step-name.png
│   ├── 02-step-name.png
│   └── ...
└── [other-test-screenshots]/
```

**Best Practices:**
- Capture at each significant step
- Use descriptive names with numeric prefixes for ordering
- Full-page screenshots for complete context
- Save to standardized directory for CI artifact collection

### Video Recording for Debugging

Browser interaction videos are automatically captured:

**Features:**
- Records on every test execution
- Saved to `videos/` directory
- Named with test method name
- Enabled via `ContextOptions()` override
- Useful for debugging intermittent failures

### Parallel Test Execution

The framework supports parallel test execution:

**Configuration:**
- NUnit assembly-level `[Parallelizable(ParallelScope.Children)]`
- Class-level `[Parallelizable(ParallelScope.Self)]`
- Each test runs in isolated server instance (no shared state)

**Safety Mechanisms:**
- Dynamically assigned ports prevent conflicts
- Fresh Sut instance per test ensures isolation
- Async service scope per test maintains DI isolation

### Wait and Retry Strategies

Built-in waiting mechanisms prevent flakiness:

**Playwright Auto-Waiting:**
- Locators automatically wait for element visibility
- Navigation methods wait for network idle
- Default timeout: 30 seconds (configurable)

**Explicit Waits When Needed:**
- SignalR updates: Small explicit waits for real-time state changes
- Custom conditions: `WaitForFunctionAsync` for complex conditions

**Timeout Configuration:**
- `Page.SetDefaultTimeout()` - General operations
- `Page.SetDefaultNavigationTimeout()` - Page navigation
- Per-operation timeout overrides for specific scenarios

---

## Error Handling and Debugging

### Test Failure Analysis

**Information Available on Failure:**
- Test output with assertion details
- Browser console output (if captured)
- Network logs (if enabled)
- Video recording of failure sequence
- Screenshot at failure point (can be added manually)

### Debugging Techniques

**Local Testing:**
- Override `HEADLESS` environment variable to false
- Browser remains open for inspection
- Pause execution with breakpoints in C# code
- Use browser developer tools while test runs

**Verbose Logging:**
- Enable debug-level logging in test configuration
- Application logs show request/response details
- Browser logs show client-side errors

**Video Analysis:**
- Watch video of failed test from `videos/` directory
- Identify exact point of failure
- Compare with successful test videos

---

## Extensibility and Customization

### Adding New Test Projects

**Steps:**
1. Create new .csproj in `tests/` directory
2. Add NUnit and Playwright.NUnit package references
3. Add `RunSettingsFilePath` property to csproj
4. Add `playwrightconfig.runsettings` with browser configuration
5. Inherit test classes from `PlaywrightTestBase`
6. Add project reference to shared test infrastructure

### Customizing Browser Configuration

**Options:**
1. Modify `playwrightconfig.runsettings` in test project
2. Override `ContextOptions()` in custom base class
3. Override `BrowserNewContextOptions` for context-level settings
4. Use environment variables for runtime overrides

### Extending Test Base Class

**Patterns:**
- Create custom base class inheriting from `PlaywrightTestBase`
- Add project-specific helper methods
- Override configuration for specialized needs
- Inherit shared test infrastructure improvements

---

## Key Dependencies and Versions

**Framework:**
- .NET 9
- C# 13 with nullable reference types enabled

**Testing Libraries:**
- NUnit 4.x
- Microsoft.Playwright.NUnit 1.x
- Microsoft.NET.Test.Sdk 17.x

**Application Frameworks:**
- ASP.NET Core 9
- Blazor Server (InteractiveServer)

**Browser Automation:**
- Playwright (Chromium browser engine)
- API request context for HTTP testing

---

## Performance Considerations

### Test Execution Performance

**Factors Affecting Speed:**
- Number of parallel tests (limited by machine resources)
- Browser startup time (first test ~5-10 seconds)
- Network simulation/slowdown settings
- Browser context recreation per test
- Application initialization time

**Optimization Strategies:**
- Parallel execution (multiple tests simultaneously)
- Browser caching between tests
- Minimal application initialization
- Efficient wait strategies (avoid fixed delays)
- Selective video recording (disable for non-critical tests)

### Resource Management

**Memory Usage:**
- Each test instance uses ~50-100MB (varies by browser)
- Parallel tests multiply resource usage
- Video recording adds additional disk I/O
- Cleanup between tests prevents memory leaks

**Storage:**
- Videos can be large (10-50MB per test depending on duration)
- Screenshots consume minimal space
- Archive old artifacts for CI/CD systems

---

## Summary

This architecture provides a scalable, maintainable framework for comprehensive end-to-end testing of modern .NET applications with API and Web UI components. Key strengths include:

1. **Isolation**: In-process test servers enable parallel execution without external dependencies
2. **Comprehensiveness**: Supports API, UI component, and user journey testing
3. **Maintainability**: Page Object Model reduces test fragility
4. **Automation**: Integrated browser management removes manual setup steps
5. **Debuggability**: Automatic video recording and screenshot capture aid in failure analysis
6. **Scalability**: Parallel execution and efficient resource management support growing test suites
7. **Flexibility**: Configuration-based approach allows customization without code changes

The framework can be adapted to similar applications by:
- Adjusting the test server configuration (URLs, endpoints, features)
- Modifying Page Object implementations for different UI components
- Customizing test scenarios to match business workflows
- Adjusting browser configuration for specific requirements

---

## Implementation Details: Critical Classes and Patterns

### Project Naming Conventions

All projects follow a consistent naming pattern based on the solution name (e.g., "PlayWrightDemo"):

| Project Type | Pattern | Example | Purpose |
|---|---|---|---|
| API Project | `{SolutionName}.Api` | `PlayWrightDemo.Api` | ASP.NET Core API with minimal endpoints |
| Blazor Project | `{SolutionName}.BlazorApp` | `PlayWrightDemo.BlazorApp` | Blazor UI application |
| Shared Test Infrastructure | `{SolutionName}.Tests.Shared` | `PlayWrightDemo.Tests.Shared` | Reusable test base classes, configuration, page objects |
| API Tests | `{SolutionName}.Tests.Api` | `PlayWrightDemo.Tests.Api` | Endpoint and integration tests |
| Blazor/UI Tests | `{SolutionName}.Tests.BlazorApp` | `PlayWrightDemo.Tests.BlazorApp` | Playwright browser automation tests |

### GlobalSetup: Assembly-Level Initialization

The `GlobalSetup.cs` file uses assembly-level attributes for proper test lifecycle:

```
Assembly Attributes (before namespace):
- [assembly: FixtureLifeCycle(InstancePerTestCase)]
- [assembly: Parallelizable(ParallelScope.Children)]
```

**[SetUpFixture] Responsibilities**:
1. **Dependency Container**: Creates ServiceCollection, registers `{SolutionName}Sut` as Scoped, exposes static `IServiceProvider Provider`
2. **Cleanup** (OneTimeTearDown): Disposes the service provider

**⚠️ Browser Installation: Let microsoft.playwright.nunit Handle It**

The `microsoft.playwright.nunit` NuGet package automatically handles browser installation - **DO NOT manually install browsers in GlobalSetup**. 

```csharp
// ❌ WRONG: Do NOT call this in GlobalSetup
Microsoft.Playwright.Program.Main(new[] { "install", "chromium" });

// ✅ RIGHT: The NUnit integration handles browser lifecycle automatically
// Just ensure microsoft.playwright.nunit package is installed
// The PageTest base class from this package manages browser binaries
```

**How It Works**:
- `microsoft.playwright.nunit` NuGet package includes automatic browser management
- When tests first run, PageTest detects missing browsers and downloads them via internal Playwright CLI
- Binaries are cached in system-specific directory (~/.playwright/)
- Subsequent test runs use cached binaries - no re-downloading
- Browser installation happens transparently before test execution
- If installation fails, PageTest throws clear error messages

**Why This Matters**:
- Manual installation scripts are fragile and duplicate functionality
- They fail silently or with cryptic errors if Playwright CLI isn't found
- They unnecessarily slow down test startup
- The NUnit package is purpose-built for this exact scenario
- Tests run more reliably when browser lifecycle is managed by the framework

**GlobalSetup Simplified Example**:
```csharp
[SetUpFixture]
public class GlobalSetup
{
    [OneTimeSetUp]
    public void OneTimeSetUp()
    {
        // ONLY handle DI container setup
        var services = new ServiceCollection();
        services.AddScoped<Sut>();  // Register test server
        Provider = services.BuildServiceProvider();
        
        // Browser installation is handled by PageTest base class
        // No explicit browser setup needed here
    }
    
    public static IServiceProvider Provider { get; set; } = null!;
}
```

### PlaywrightTestBase: Test Lifecycle

Inherits from `PageTest` (Playwright.NUnit) and implements:

**[SetUp]**: Creates AsyncServiceScope, retrieves Sut from DI, sets 30-second timeouts, enables video recording
**[TearDown]**: Closes context, saves video to `videos/{TestName}.webm`, disposes scope

### WebApplicationFactory: {SolutionName}Sut Class

Critical override pattern: **MUST use Kestrel, NOT TestServer** (Playwright needs real HTTP server)

**ConfigureWebHost**: Sets `builder.UseUrls("http://127.0.0.1:0")` (dynamic port for parallel execution)
**CreateHost**: Calls `builder.ConfigureWebHost(p => p.UseKestrel())` to switch from TestServer
**Address Extraction**: Gets actual URL via `IServerAddressesFeature`, sets `ClientOptions.BaseAddress`

### TestConfiguration: Static Configuration Class

Environment variable pattern with defaults:
- `ApiBaseUrl`: "API_BASE_URL" → "http://localhost:5000"
- `BlazorBaseUrl`: "BLAZOR_BASE_URL" → "http://localhost:5001"  
- `IsHeadless`: "HEADLESS" → true

### Test Organization: By Concern/Page

**Naming**: `{Action}_{Condition}_{Result}` (e.g., `AddToCart_WithValidProduct_ShouldIncreaseCount`)
**Structure**: Separate test classes per page, shared Page Objects in `Pages/` folder
**Per-page count**: 3-8 tests typical, critical journeys: 2-5 workflows

### BasePage: Page Object Foundation

Abstract base with:
- `protected IPage Page` property
- `virtual async Task IsLoadedAsync()` (verify page loaded)
- `async Task TakeScreenshotAsync(string fileName)` helper for debugging

### Critical Journeys: Multi-Step Workflows

End-to-end tests with:
- Step-by-step navigation
- Screenshot at each major step
- Assertions throughout
- Keep to 5-7 steps per journey

---

## Advanced Patterns: Complex Implementation Details

### Host/Server Lifecycle: Dual-Mode Pattern (Critical)

The `CreateHost()` override in WebApplicationFactory implements a sophisticated dual-server pattern that is essential for the entire testing strategy to work correctly.

**The Problem This Solves**:

1. WebApplicationFactory expects its `CreateHost()` to return a TestServer-based host (for framework internal access)
2. Playwright (a real browser) cannot connect to TestServer - it needs a real HTTP server like Kestrel
3. Naive approaches (returning Kestrel, not TestServer) cause WebApplicationFactory framework errors
4. Solution: Create and manage BOTH servers simultaneously, return TestServer, but configure the factory to route to Kestrel

**The Critical Sequence** (order matters):

1. Call `builder.Build()` **once** - initializes WebHostBuilder state
2. Call `builder.ConfigureWebHost(p => p.UseKestrel())` - reconfigure to use Kestrel
3. Call `builder.Build()` **again** - creates the actual Kestrel host  
4. Call `_host.Start()` - starts the Kestrel server on a dynamic port
5. Extract the actual listening address via `IServerAddressesFeature`
6. Set `ClientOptions.BaseAddress` to Kestrel's actual address
7. Start the original TestServer instance
8. **Return the TestServer** (not Kestrel) - satisfies framework internals

**Why This Sequence**:

- Calling `Build()` first primes the builder state for `ConfigureWebHost()` to work correctly
- Must start Kestrel BEFORE extracting its address (OS hasn't assigned the dynamic port until startup)
- Must set `ClientOptions.BaseAddress` to Kestrel's address so all HTTP calls route there
- Returning TestServer prevents framework errors; Kestrel is accessed through configured routing

**The Result** (dual-mode operation):

- **WebApplicationFactory framework**: Sees a TestServer-based host, can access services via public factory APIs
- **Playwright browser**: Connects via real HTTP to Kestrel on the configured address:port
- **Both**: Share identical configuration, dependency injection, and application state
- **Execution**: Parallel test runs each get isolated servers on unique dynamic ports

**Environment Setting** (Production, not Development):

Tests must run in Production environment mode to validate the actual production code path:
- Same code path used in development, testing, and production
- No environment-specific shortcuts
- Ensures behavior consistency across all deployment scenarios

**Middleware Configuration Critical Point** (learned from testing):

- HTTPS redirection is disabled - using HTTP-only until certificates are configured
- All environments use identical middleware configuration
- No IsDevelopment() checks for different code paths

**URL Configuration Critical Point**:

- Server address extraction returns URLs with trailing slashes: `http://127.0.0.1:52048/`
- Tests must trim trailing slashes when constructing API endpoint URLs
- Otherwise double-slashes occur: `http://127.0.0.1:52048//weatherforecast` → 404
- Solution in test base: `ApiBaseUrl = serverAddress.TrimEnd('/')`

**Reference Implementation**:

This pattern is proven and used in the TestExamplesDotnet repository's Vue.Playwright project. That implementation serves as the authoritative reference for the correct sequence and approach.

### Common Pitfalls: Lessons Learned

**Pitfall 1: Returning Kestrel Instead of TestServer**

❌ **Problem**: Returning `_host` (Kestrel) instead of `testHost` (TestServer) causes WebApplicationFactory cast errors:
```
Unable to cast KestrelServerImpl to TestServer
```

✅ **Solution**: Always return the TestServer instance. Kestrel is accessed via `ClientOptions.BaseAddress` routing.

**Pitfall 2: URL Construction with Trailing Slashes**

❌ **Problem**: Server address has trailing slash: `http://127.0.0.1:52048/`. Appending path without check creates: `http://127.0.0.1:52048//weatherforecast`:
```
Response: 404 (malformed URL)
```

✅ **Solution**: Trim trailing slash in test base class:
```
ApiBaseUrl = serverAddress.TrimEnd('/');
// Usage: $"{ApiBaseUrl}/weatherforecast"
```

**Pitfall 3: Extracting Address Before Server Starts**

❌ **Problem**: Extracting address from `IServerAddressesFeature` before calling `_host.Start()` returns port 0 (not assigned yet), making all requests fail.

✅ **Solution**: Always call `_host.Start()` before extracting the address. The OS assigns a real dynamic port only when the server actually starts.

**Pitfall 4: Development Environment Shortcuts**

❌ **Problem**: Running tests in Development mode hides real issues:
- Error handling differs from production
- Middleware behaves differently
- HTTPS and security settings are relaxed
- Tests validate incorrect behavior

✅ **Solution**: Always use `Environments.Production` for test hosts. Tests must validate production behavior.

### Debugging Strategies

**Server Address Verification**:

Add debug output to test setup to verify servers are accessible:
```
Console.WriteLine($"API URL: {ApiBaseUrl}");
Console.WriteLine($"Server Address: {Sut.ServerAddress}");
```

**Port Conflict Diagnosis**:

If tests fail with "address already in use", dynamic port assignment has failed. This indicates:
1. Environment not set to Production (development middleware may interfere)
2. Network configuration issue (firewall blocking localhost)
3. Previous test process didn't clean up properly

**Middleware Order Issues**:

If endpoints return 404 but HTTPS redirect is fixed, check middleware registration order in Program.cs:
1. Exception handling must come first
2. HTTPS redirect (if enabled) should be early
3. API endpoints must be mapped AFTER middleware setup

---

Browser installation can fail intermittently due to network issues, disk access, or transient platform issues. Implement retry logic:

```csharp
private static void InstallPlayWright()
{
    var attempts = 0;
    const int maxAttempts = 3;
    
    while (attempts <= maxAttempts)
    {
        try
        {
            var exitCode = Microsoft.Playwright.Program.Main(
                ["install", "--with-deps", "chromium"]);
            
            if (exitCode == 0)
                return;  // Success
            
            Console.WriteLine($"Installation failed with exit code {exitCode}");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Installation error: {ex.Message}");
        }
        
        if (attempts >= maxAttempts)
            throw new InvalidOperationException(
                "Failed to install Playwright after 3 attempts");
        
        attempts++;
        Console.WriteLine(
            $"Retrying... (attempt {attempts + 1}/{maxAttempts + 1})");
    }
}
```

**Key Principles**:
- Check exit codes, not just exceptions (Playwright.Program.Main returns 0 on success)
- Log all failure reasons (exit code, exception message)
- Set reasonable max attempts (3 is typical: allows for transient failures)
- Throw after max attempts (don't fail silently)
- Helpful message indicates this isn't an immediate problem

### Async Scope Management: Preventing Resource Leaks

Per-test DI scopes must be carefully managed:

```csharp
private AsyncServiceScope _scope;

[SetUp]
public void BeforeTestCase()
{
    // Create new scope for this test
    _scope = GlobalSetup.Provider.CreateAsyncScope();
    
    // Get Sut from scope (new instance per test)
    Sut = _scope.ServiceProvider.GetRequiredService<SimpleEcommerceSut>();
    
    // Set timeouts
    Page.SetDefaultTimeout(30_000);
    Page.SetDefaultNavigationTimeout(30_000);
}

[TearDown]
public async Task AfterTestCase()
{
    try
    {
        // Close browser context (stops recording video)
        await Page.Context.CloseAsync();
        
        // Rename video with test name
        if (Page.Video != null)
        {
            var path = await Page.Video.PathAsync();
            var newName = Path.Combine(folder, $"{testName}.webm");
            File.Move(path, newName, true);
        }
    }
    finally
    {
        // CRITICAL: Always dispose scope, even if errors above
        await _scope.DisposeAsync();
    }
}
```

**Why AsyncServiceScope**:
- `AsyncServiceScope` vs regular `Scope`: AsyncServiceScope supports async disposal (required for server cleanup)
- `Scoped` services: New instance per test, shared within test
- `CreateAsyncScope()`: Creates independent scope; disposal won't affect other tests

**Why try-finally-dispose**:
- Scope contains disposable services (Sut contains IHost)
- Disposal must happen even if exceptions above
- `await _scope.DisposeAsync()` stops servers and frees ports
- Failure to dispose causes port exhaustion in long test runs

### Page Object Element Selection Strategy

Prefer ARIA roles over CSS selectors for robustness:

```csharp
public class HomePage : BasePage
{
    // ✅ GOOD: Role-based (resilient to styling changes)
    public ILocator WelcomeHeading => 
        Page.GetByRole(AriaRole.Heading, new() { Name = /Welcome/ });
    
    public ILocator ProductsLink => 
        Page.GetByRole(AriaRole.Link, new() { Name = "Products" });
    
    // ❌ AVOID: CSS selectors (brittle - break with styling changes)
    // public ILocator ProductsLink => Page.Locator("#nav-products");
    
    // ⚠️ FALLBACK: Test ID when role unavailable
    public ILocator CartBadge => 
        Page.GetByTestId("cart-count-badge");
}
```

**Strategy Rationale**:
- **Roles (GetByRole)**: Match accessibility tree structure; resilient to CSS changes
- **Test IDs (GetByTestId)**: When semantic role unavailable; explicit test contract
- **CSS selectors**: Last resort only; break when styling updates
- **Regex patterns** (`/Welcome/`): Match partial text; helpful when exact text varies

### Test Organization: When to Split Test Classes

Growing test files need organization strategy:

**Guidelines**:
- **1-5 tests**: Keep in one class (lightweight)
- **6-10 tests**: Consider splitting when covering different workflows
- **10+ tests**: Definitely split into focused test classes
- **Logical grouping**: All tests for HomePage in HomePageTests class
- **Critical journeys**: Separate class (e.g., CriticalJourneyTests)

**Example Structure**:
```
ProductsPageTests.cs
├── ProductsPageTests (normal tests)
│   ├── ProductsPage_Loads_Successfully
│   ├── ProductsPage_DisplaysProductList
│   └── ProductsPage_AddToCart_UpdatesCount
└── ProductsPageFiltersTests (filtering scenarios)
    ├── Filter_ByPrice_ShowsFiltered
    └── Filter_Reset_ShowsAllProducts
```

### API Response Validation: Testing Against Actual API Responses

**Common Mistake**: Assuming API response structure instead of validating actual responses

```csharp
// ❌ WRONG: Assumes API returns 'state' property
var getJson = await response.JsonAsync();
var state = getJson.Value.GetProperty("state").GetString();  // KeyNotFoundException!
Assert.That(state, Is.EqualTo("Running"));

// ✅ RIGHT: Validate against actual API model properties
var getJson = await response.JsonAsync();
var isActive = getJson.Value.GetProperty("isActive").GetBoolean();  // Matches actual model
Assert.That(isActive, Is.True);
```

**Best Practice**:
1. Run API once manually to see actual response structure
2. Check the C# model/DTO to see property names (PascalCase: `IsActive`)
3. JSON output uses camelCase by default: `isActive`
4. Validate tests match actual API, not hypothetical structure
5. When endpoints change, update tests immediately

**Gotcha with Response Arrays**:
```csharp
// ❌ WRONG: Endpoint doesn't exist
var response = await Page.APIRequest.GetAsync($"{ApiBaseUrl}/api/pedalboards/{id}/plugins");
// Returns 404 because this endpoint doesn't exist

// ✅ RIGHT: Get full pedalboard which includes plugins array
var response = await Page.APIRequest.GetAsync($"{ApiBaseUrl}/api/pedalboards/{id}");
var json = await response.JsonAsync();
var plugins = json.Value.GetProperty("plugins").EnumerateArray().ToList();
// Now you have the plugins from the main pedalboard object
```

**Why This Matters**:
- Tests validate API contracts, not assumptions
- When API is updated, tests catch breaking changes
- Wrong property names cause KeyNotFoundException at runtime
- Tests should fail fast with clear errors, not silent failures

Or consider separate files:
```
BlazorAppTests/
├── ProductsPageTests.cs
├── ProductsPageFiltersTests.cs
├── OrdersPageTests.cs
└── CriticalJourneyTests.cs
```

### Video Recording: Debugging Failed Tests

Video recording provides context for debugging failures:

**Recording Strategy**:
```csharp
public override BrowserNewContextOptions ContextOptions()
{
    return new BrowserNewContextOptions()
    {
        // Save videos to artifacts/videos/ folder
        // Videos named: {FullTestName}.webm
        RecordVideoDir = "videos",
    };
}
```

**Naming Pattern**: `{Namespace}.{ClassName}.{MethodName}.webm`
- Example: `SimpleEcommerce.Tests.BlazorApp.HomePageTests.HomePage_Loads_Successfully.webm`
- Allows matching videos to test results in CI pipeline

**Storage Considerations**:
- Videos are WebM format (VP8/VP9 codec)
- Size: ~2-5 MB per minute of video
- Retention: Keep 7-30 days in CI artifacts
- Local: Keep for failed tests for debugging

**Conditional Recording** (Optional):
```csharp
// Only record on failure (saves disk space)
public override BrowserNewContextOptions ContextOptions()
{
    return new BrowserNewContextOptions()
    {
        RecordVideoDir = TestContext.CurrentContext.Result.Outcome.Status == TestStatus.Failed
            ? "videos"
            : null,
    };
}
```

### XML Documentation: Code-Level Specifications

Infrastructure classes require comprehensive documentation:

**Pattern for Infrastructure Classes**:
```csharp
/// <summary>
/// System Under Test (Sut) - WebApplicationFactory for {SolutionName}.
/// 
/// Manages the lifecycle of both the API and Blazor servers for integration testing.
/// Uses Kestrel (not TestServer) so that Playwright browser can reach the servers.
/// 
/// Key pattern from: [Reference link]
/// </summary>
public sealed class {SolutionName}Sut : WebApplicationFactory<Program>
{
    /// <summary>
    /// Gets the base URL where the Kestrel servers are listening.
    /// Dynamically assigned port allows parallel test execution.
    /// </summary>
    public string ServerAddress { get; }
    
    /// <summary>
    /// Configures the web host to use dynamic ports.
    /// </summary>
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        // CRITICAL: Switch from TestServer to Kestrel
        // This allows Playwright to access the servers via HTTP
        builder.UseUrls("http://127.0.0.1:0");
    }
}
```

**Documentation Level**:
- **Classes**: Explain purpose, key decisions, external references
- **Properties**: Document what values represent, why they matter
- **Methods**: Explain entry points, key behaviors, critical sections
- **Critical decisions**: Use `// CRITICAL:` comments explaining why (e.g., Kestrel choice)

**Benefits**:
- Future maintainers understand design decisions
- Reduces need to refer to source code comments
- Catches design issues during documentation phase

---

## Implementation Iteration Process: Testing & Validation

### Critical: Validate Early and Often

The most common quality issues arise when implementations are not tested until the end. **This architecture includes a CI/CD validation workflow that should be run after each major implementation step**, not just at the very end.

**Recommended Iteration Schedule**:

1. **After Project Setup** (projects created, basic structure)
   - Run lint: `.\ci\lint.ps1`
   - Verify: No formatting errors
   - Fix: Code formatting issues immediately

2. **After Infrastructure Implementation** (GlobalSetup, TestBase, Sut)
   - Run build: `dotnet build`
   - Verify: Projects compile without errors
   - Fix: Compilation errors immediately
   - DO NOT proceed to tests if build fails

3. **After Test Project Setup** (base test classes, page objects)
   - Run full CI: `.\ci\ci.ps1`
   - Verify: Lint passes, build succeeds
   - Fix: Any issues found
   - Expected time: 5-10 minutes

4. **After Adding Tests** (test methods written)
   - Run full CI: `.\ci\ci.ps1`
   - Verify: All tests execute (even if some fail)
   - Fix: Test failures indicate implementation issues
   - Expected time: 15-30 minutes (includes browser installation on first run)

5. **Before Finalizing** (all components complete)
   - Run full CI: `.\ci\ci.ps1`
   - Verify: All tests pass (100% green)
   - Fix: Any remaining issues
   - Expected time: 30 seconds (cached browsers)

### CI/CD Workflow Location and Usage

**Location**: `{SolutionName}/ci/ci.ps1`

**Purpose**: Simulates the complete CI pipeline locally, catching issues before they propagate

**Execution**:
```powershell
# From solution ci/ directory
cd .\ci\
.\ci.ps1
```

**What It Does** (in order):

1. **Stage 1: Lint** (`lint.ps1`)
   - Checks code formatting with `dotnet format --verify-no-changes`
   - Fails if code doesn't match `.editorconfig` style
   - **Stop here and fix**: If lint fails, the entire pipeline stops
   - **Fix command**: `dotnet format` (auto-fixes formatting)

2. **Stage 2: Build** (`build-test.ps1` - build phase)
   - Restores NuGet dependencies: `dotnet restore`
   - Compiles all projects: `dotnet build`
   - Fails if compilation errors found
   - **Stop here and fix**: If build fails, tests cannot run
   - **Common issues**: 
     - Missing using statements
     - Typos in class/method names
     - Mismatched method signatures
     - Missing project references

3. **Stage 3: Test** (`build-test.ps1` - test phase)
   - Runs all tests: `dotnet test`
   - NUnit discovers and executes test methods
   - First run: Installs Playwright browsers (~2 minutes)
   - Subsequent runs: Use cached browsers (~30 seconds)
   - **Stop here and fix**: If tests fail, there are implementation issues
   - **Test failures indicate**: 
     - Incorrect test logic
     - Mismatched endpoints/pages
     - Configuration issues
     - Browser interaction problems

### Expected Workflow Example

**Correct Iteration**:
```
1. Create projects structure
   └─ Run: .\ci.ps1 → Lint passes ✓
   
2. Implement GlobalSetup, PlaywrightTestBase, Sut
   └─ Run: .\ci.ps1 → Build passes ✓
   
3. Add Page Objects (HomePage, ProductsPage)
   └─ Run: .\ci.ps1 → Build passes ✓
   
4. Add Test Methods (10+ tests)
   └─ Run: .\ci.ps1 → All tests pass ✓
   
5. Add Critical Journeys
   └─ Run: .\ci.ps1 → All tests pass ✓
   
RESULT: High-quality implementation, zero surprises
```

**Incorrect Iteration** (what causes quality issues):
```
1. Create ALL projects
2. Implement ALL code
3. Add ALL tests
4. Run .\ci.ps1 for the first time
   └─ 15+ errors discovered at once
   └─ Takes hours to untangle
   └─ Quality suffers
   
RESULT: Firefighting, missed issues, low quality
```

### Quick Reference: When Stages Fail

| Stage | Fails At | Common Causes | Fix Time |
|---|---|---|---|
| **Lint** | Format check | Indentation, spacing | 10 seconds |
| **Build** | Compilation | Missing imports, typos, mismatched signatures | 5-10 minutes |
| **Test** | Test execution | Configuration, routing, browser interaction | 10-30 minutes |

### Critical Debugging Tips

**If Lint Fails**:
```powershell
# Auto-fix formatting
dotnet format

# Verify fixed
dotnet format --verify-no-changes
```

**If Build Fails**:
- Check error messages carefully
- Verify all using statements are present
- Check for typos in class/method names
- Ensure project references are correct
- Review compiler warnings (often indicative)

**If Tests Fail**:
- Check video recordings in `videos/` directory
- Look for navigation errors in test output
- Verify localhost URLs are correct
- Check browser console output for client errors
- Review test logic against application behavior

### Early Issue Detection Benefits

**Why Test Early**:
- ✅ Catch compilation errors before writing 20 tests
- ✅ Discover configuration issues immediately
- ✅ Validate infrastructure working correctly
- ✅ Prevent cascading failures
- ✅ Maintain momentum (small fixes vs large issues)
- ✅ Higher quality implementation overall

**Time Impact**:
- **Early validation** (after each step): +5 minutes per iteration = 20 minutes total
- **Late validation** (at the end): +2 hours debugging = 120 minutes total
- **Net savings**: 100 minutes (83% reduction in debugging time)

### CRITICAL: CI/CD Script Validation Rules

**Golden Rule**: Always use `./ci.ps1` to validate changes. If you cannot validate with just `./ci.ps1`, the script needs enhancement.

**Why This Matters**:
- The CI/CD pipeline is the source of truth for solution quality
- Any workaround (filtering output, piping to file, using intermediate scripts) indicates the pipeline is incomplete
- Clean pipeline output ensures anyone can validate locally exactly as CI does

**Validation Workflow**:

From the solution `ci/` directory, run only `./ci.ps1`. No other commands needed:
- Do NOT use intermediate build scripts, only ci.ps1
- Do NOT filter output with Select-String, head, tail, or grep
- Do NOT redirect to files or use piping
- Do NOT use different verbosity settings on the command line

If you need different behavior, the solution is to update `build-configuration.json`, not to work around the scripts.

**Clean Output Configuration**:

The `build-configuration.json` file controls all pipeline behavior:

1. **Verbosity**: Set to `minimal` by default (shows errors, key milestones, test results)
2. **Warning Suppression**: List specific warning codes that are non-critical (e.g., `NU1603` for package resolution notices)
3. **Build Flags**: Includes `--nologo` to reduce startup chatter

**Suppressing Non-Critical Warnings**:

Some warnings are informational only (like NuGet package resolution notices). Configure these in `build-configuration.json`:

```json
"suppressWarnings": ["NU1603"]
```

Each warning has an identifier (e.g., `NU1603`). To suppress:
1. Identify the warning code from the build output
2. Add it to the `suppressWarnings` array
3. Re-run `./ci.ps1` to verify the warning no longer appears

This filters noise while keeping real compilation errors visible.

**The Pipeline Mechanism**:

The `build-test.ps1` scripts automatically:
- Load configuration from `build-configuration.json`
- Pass verbosity to all `dotnet` commands
- Apply warning suppression via MSBuild properties
- Display only actionable information

**To Change Pipeline Behavior**:
1. Edit `build-configuration.json` (not the scripts)
2. Re-run `./ci.ps1` to validate
3. Commit the configuration file

---

### CRITICAL: CI/CD Script Architecture Pattern

**Single Source of Truth for Configuration**:

The `build-configuration.json` file is the authoritative source for all build, test, and CI settings. This ensures consistency and eliminates configuration scattered across multiple scripts.

**Script Organization Rules**:

1. **Minimal Project-Specific Variables**: Only hardcode solution names and file paths
   - Example: `$solutionName = "PlayWrightDemo"`
   - Example: `$solutionFile = "PlayWrightDemo.sln"`
   - These are constant for each project; never change them

2. **All Configuration in JSON**: Every setting must be in `build-configuration.json`
   - `build.verbosity`: Controls dotnet build output level
   - `build.suppressWarnings`: Array of warning codes to suppress
   - `test.verbosity`: Controls dotnet test output level
   - Example: `"suppressWarnings": ["NU1603", "CS0436"]`

3. **Single Config Object Pattern**: All functions receive configuration as a single parameter
   - Load once at script start: `$config = Get-Content $configPath | ConvertFrom-Json`
   - Pass to all functions: `Invoke-LintCode -Config $config -SolutionFile $solutionFile`
   - Functions access: `$config.build.verbosity`, `$config.build.suppressWarnings`, `$config.test.verbosity`

**Why This Architecture**:

- **Maintainability**: Changes only happen in JSON, never scattered through scripts
- **Consistency**: All projects follow the same pattern and structure
- **Clarity**: Reading a function signature immediately shows all dependencies
- **Testability**: Configuration is data, easily validated without running code
- **Flexibility**: New configuration options added without modifying function signatures

**Function Pattern**:

Every function receives the config object and accesses what it needs:

```powershell
function Invoke-BuildSolution {
    param([object]$Config, [string]$SolutionFile)
    
    # Access configuration via $Config object
    $verbosity = $Config.build.verbosity
    $suppressWarnings = $Config.build.suppressWarnings -join ";"
    
    # Pass to dotnet commands
    dotnet build $SolutionFile /p:Verbosity=$verbosity /p:NoWarn=$suppressWarnings
}
```

**Never do this**:
- ❌ Individual parameters for each setting (breaks consistency)
- ❌ Hardcoding configuration in scripts (creates maintenance nightmare)
- ❌ Using command-line arguments to override configuration (defeats single source of truth)
- ❌ Reading config multiple times (inefficient)

---

````