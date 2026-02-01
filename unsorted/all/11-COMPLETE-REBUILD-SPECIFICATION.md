# Complete Rebuild Specification

**Document Purpose:** Provides complete requirements, coding standards, and architectural patterns necessary for rebuilding the Alsionyx project from scratch.

**Important:** This document supplements [IMPLEMENTATION-ROADMAP.md](IMPLEMENTATION-ROADMAP.md) and [Testing_Workflow.md](Testing_Workflow.md). When code examples appear below, they illustrate specific patterns (like proper DI usage or error handling) that are non-obvious. Remove any examples that merely show "obvious" code; keep only complex, tricky, or pattern-demonstrating examples.

**Last Updated:** 18 January 2026  
**Target Framework:** .NET 9.0  
**Status:** Production-ready architecture with comprehensive testing

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Solution Structure & Projects](#solution-structure--projects)
3. [Coding Standards & Conventions](#coding-standards--conventions)
4. [Dependency Injection Patterns](#dependency-injection-patterns)
5. [Service Lifetime Guidelines](#service-lifetime-guidelines)
6. [Error Handling Strategy](#error-handling-strategy)
7. [Controller Design Patterns](#controller-design-patterns)
8. [Model & DTO Design](#model--dto-design)
9. [Testing Requirements](#testing-requirements)
10. [Build & Deployment Configuration](#build--deployment-configuration)

---

## Project Overview

### Mission Statement
Alsionyx is a professional-grade audio management system with LV2 plugin support, virtual pedalboard interface, and REST API. Built for reliability, testability, and extensibility using SoundFlow and file-based audio processing.

### Core Value Propositions
1. **Pluggable Architecture**: Swap audio backends (SoundFlow/FileAudio/Mock) without code changes
2. **Test-First Design**: Every component mockable, 80%+ code coverage target
3. **Clean Separation**: UI, API, Core, and Infrastructure clearly separated
4. **Production Ready**: Comprehensive logging, error handling, and monitoring

### Technical Constraints
- **No Real Hardware in Tests**: All audio operations must use mocks in test scenarios.
- **Mocks only referenced in Tests**: there should be no references to mocks/test code except in unit tests. concrete classes based on mocks should be only be used in tests.
- **LV2 mocks**: Create a Mock of the lv2 tinyGain plugin called TinyGainMock for use only in unit tests. 
- **Integration tests** should use mocks for audio related operations.
- **Build Configuration**: All code compilations should use Debug builds, and assume the Development environment.
- **No OS Command Execution**: Only dedicated system abstraction layers (no `Process.Start` for hardware queries)
- **No Static State**: All services injected, no singleton patterns outside DI container
- **Async-First**: All I/O operations use async/await
- **No Real Hardware in Tests**: All audio operations must use mocks in test scenarios.

---

## Solution Structure & Projects

### Project Taxonomy

```
Alsionyx.sln (15 projects)
├── Core Domain Layer (3 projects)
│   ├── Alsionyx.Core               - Domain models, interfaces, core services
│   ├── Alsionyx.Shared             - Shared DTOs and common types
├── Infrastructure Layer (2 projects)
│   ├── Alsionyx.Library.Logging    - NLog integration, ILog<T> implementation
│   └── Alsionyx.Library.Extensions - Extension methods, helpers
│   ├── Alsionyx.Library.SoundFlow         - SoundFlow audio backend
│   ├── Alsionyx.Library.FileAudio         - File-based audio processing  
│   └── Alsionyx.Library.Interop           - P/Invoke wrappers for LV2
│
├── Application Layer (3 projects)
│   ├── Alsionyx.Api                - REST API (ASP.NET Core)
│   ├── Alsionyx.BlazorUI           - Blazor WebAssembly UI
│   └── Alsionyx.PedalboardConsole  - Console application for automation
│
└── Test Layer (7 projects)
    ├── Alsionyx.Core.Tests         - Core domain unit tests
    ├── Alsionyx.Library.Logging.Tests - Logging infrastructure tests
    ├── Alsionyx.Api.Tests          - API unit tests
    ├── Alsionyx.BlazorUI.Tests     - Blazor component tests
    ├── Alsionyx.Integration.Tests  - Integration tests (API + services)
    ├── Alsionyx.PlaywrightTests    - E2E browser tests
    └── Alsionyx.Tests.Library      - Shared test utilities
```

### Project Dependencies (Must Follow)

**Dependency Rules (Enforced):**
1. **Core** depends on NOTHING (pure domain)
2. **Infrastructure** depends on Core only
3. **Application** depends on Core + Infrastructure
4. **Tests** depend on their target project + Tests.Library

**Forbidden Dependencies:**
- ❌ Core → Infrastructure
- ❌ Core → Application
- ❌ Infrastructure → Application
- ❌ Any circular dependencies

### Critical Files Per Project

**Alsionyx.Core:**
- `Models/` - All domain entities (Pedalboard, PluginInstance, PortConnection, etc.)
- `Interfaces/` - Service contracts (IAudioBackend, IPedalboardService, etc.)
- `Services/` - Core business logic (PedalboardService, PluginService, etc.)
- `Providers/` - Mock implementations (MockAudioBackend, MockLv2PluginDiscoverer)
- `Constants/ApplicationConstants.cs` - ALL magic strings centralized here
- `Configuration/AudioBackendSettings.cs` - Configuration models

**Alsionyx.Api:**
- `Controllers/` - REST API endpoints (5 controllers)
  - `PedalboardsController` - Pedalboard lifecycle only
  - `PedalboardPluginsController` - Plugin management for pedalboards
  - `PedalboardConnectionsController` - Connection management
  - `AudioBackendsController` - Backend management
  - `PluginsController` - Global plugin discovery
- `Services/` - API-specific services (port descriptions, connection analysis)
- `ApiContainerBuilder.cs` - DI container registration
- `Program.cs` - Application entry point

**Alsionyx.Library.Logging:**
- `ILog.cs` - Generic logging interface
- `NLogAdapter.cs` - NLog implementation
- `NLogLoggerCore.cs` - Type-safe wrapper
- `LogBuilder.cs` - NLog configuration builder

---

## Coding Standards & Conventions

### C# Language Standards

**Version:** C# 12 (Latest)  
**Nullable Reference Types:** Enabled (required)  
**Implicit Usings:** Enabled

### Naming Conventions

| Type | Convention | Example |
|------|-----------|---------|
| Namespace | PascalCase | `Alsionyx.Core.Services` |
| Class | PascalCase | `PedalboardService` |
| Interface | I + PascalCase | `IPedalboardService` |
| Method | PascalCase | `GetPedalboardAsync` |
| Property | PascalCase | `PedalboardId` |
| Private Field | _camelCase | `_logger`, `_pedalboardService` |
| Parameter | camelCase | `pedalboardId`, `pluginUri` |
| Local Variable | camelCase | `pedalboard`, `connectionInfo` |
| Constant | PascalCase | `ApplicationConstants.AudioPorts.SystemDevicePrefix` |
| Enum | PascalCase (singular) | `ConnectionType`, `ChannelType` |
| Enum Member | PascalCase | `ConnectionType.InputToPlugin` |

### File Organization

**One Type Per File Rule:**
- Each class, interface, enum gets its own file
- Exception: Small related records can share a file with the class that uses them
- Example: `PedalboardsController.cs` can contain `CreatePedalboardRequest` record

**Namespace = Folder Structure:**
```
src/Alsionyx.Core/Models/Audio/
└── AudioPortIdentity.cs
    namespace Alsionyx.Core.Models.Audio;
    public class AudioPortIdentity { }
```

### XML Documentation Requirements

**Required for ALL public APIs:**
```csharp
/// <summary>
/// Creates a connection between two audio ports in a pedalboard.
/// </summary>
/// <param name="pedalboardId">The unique identifier of the pedalboard.</param>
/// <param name="fromPort">The source port name (e.g., "system:capture_0").</param>
/// <param name="toPort">The destination port name (e.g., "plugin:input_0").</param>
/// <returns>A task representing the asynchronous operation.</returns>
/// <exception cref="ArgumentNullException">Thrown when any parameter is null or empty.</exception>
/// <exception cref="InvalidOperationException">Thrown when pedalboard is not found.</exception>
public async Task ConnectPortsAsync(string pedalboardId, string fromPort, string toPort)
```

**Minimum Requirements:**
- `<summary>` for all public types and members
- `<param>` for all method parameters
- `<returns>` for methods returning values
- `<exception>` for all thrown exceptions
- `<remarks>` for complex behavior, threading concerns, or usage notes

### Code Formatting (Enforced by CI)

**Use `dotnet format` before all commits:**
```bash
dotnet format src/Alsionyx.sln
```

**Key Rules:**
- Indentation: 4 spaces (no tabs)
- Braces: Opening brace on same line for control structures
- Line length: 120 characters max (recommendation, not enforced)
- Empty lines: One between methods, two between major sections
- Using directives: Inside namespace (not outside)

### Anti-Patterns to Avoid

#### 1. Magic Strings
❌ **Wrong:**
```csharp
if (port.StartsWith("system"))  // Magic string!
{
    var name = $"system:{portName}";  // More magic!
}
```

✅ **Right:**
```csharp
using Alsionyx.Core.Constants;

if (port.StartsWith(ApplicationConstants.AudioPorts.SystemDevicePrefix, 
    StringComparison.OrdinalIgnoreCase))
{
    var name = $"{ApplicationConstants.AudioPorts.SystemDevicePrefix}{ApplicationConstants.AudioPorts.PortSeparator}{portName}";
}
```

#### 2. String Concatenation for Complex Objects
❌ **Wrong:**
```csharp
var description = $"{device} - {channel} ({mixer})";  // Not structured!
return description;  // Loses semantic meaning
```

✅ **Right:**
```csharp
var portDescription = new PortDescription
{
    DeviceName = device,
    Channel = channel,
    MixerControl = mixer,
    DisplayName = BuildDisplayName()
};
return portDescription;  // Preserves structure
```

#### 3. String Returns Instead of Enums
❌ **Wrong:**
```csharp
public string GetChannelType(int channel) => channel switch
{
    0 => "Left",   // Stringly-typed!
    1 => "Right",
    _ => "Unknown"
};
```

✅ **Right:**
```csharp
public ChannelType GetChannelType(int channel) => channel switch
{
    0 => ChannelType.Left,   // Type-safe!
    1 => ChannelType.Right,
    _ => ChannelType.Unknown
};

public enum ChannelType
{
    Unknown = 0,
    Left = 1,
    Right = 2,
    Center = 3
}
```

#### 4. Static Loggers
❌ **Wrong:**
```csharp
private static readonly ILog<MyClass> _logger = LogManager.GetLogger<MyClass>();  // Static!
```

✅ **Right:**
```csharp
private readonly ILog<MyClass> _logger;

public MyClass(ILog<MyClass> logger)  // Injected!
{
    _logger = logger ?? throw new ArgumentNullException(nameof(logger));
}
```

#### 5. Console.WriteLine for Logging
❌ **Wrong:**
```csharp
Console.WriteLine($"Error: {ex.Message}");  // Not structured!
```

✅ **Right:**
```csharp
_logger.Error(ex, "Operation failed");  // Structured logging!
```

---

## Dependency Injection Patterns

### Container Registration Pattern

**Container Builder Structure:**
Every application has a dedicated container builder (`ApiContainerBuilder`, `ConsoleContainerBuilder`, `BlazorContainerBuilder`).

**Example: ApiContainerBuilder.cs**
```csharp
public static class ApiContainerBuilder
{
    public static void RegisterCoreServices(
        IServiceCollection services,
        IConfiguration configuration)
    {
        // 1. Logging FIRST (everything depends on it)
        services.AddSingleton(typeof(ILog<>), typeof(NLogLoggerCore<>));
        
        // 2. Configuration binding
        services.Configure<AudioBackendSettings>(
            configuration.GetSection("AudioBackend"));
        
        // 3. Infrastructure layer (providers, backends)
        services.AddSingleton<IAudioBackend, SoundFlowAudioBackend>();
        services.AddSingleton<IAudioDeviceProvider, MockAudioDeviceProvider>();
        services.AddSingleton<ILv2PluginDiscoverer, MockLv2PluginDiscoverer>();
        
        // 4. Application services (business logic)
        services.AddSingleton<IAudioBackendService, AudioBackendService>();
        services.AddSingleton<IPedalboardService, PedalboardService>();
        services.AddSingleton<DeviceDiscoveryService>();
        services.AddSingleton<PluginService>();
        
        // 5. API-specific services
        services.AddSingleton<IPortDescriptionBuilder, PortDescriptionBuilder>();
        services.AddSingleton<IPedalBoardConnectionService, PedalBoardConnectionFactory>();
        services.AddScoped<PedalboardLoggingService>();
        
        // 6. Configure NLog
        var logBuilder = new LogBuilder(configuration);
        logBuilder.Build();
    }
    
    public static void RegisterApiServices(
        IServiceCollection services,
        IConfiguration configuration)
    {
        services.AddControllers();
        services.AddOpenApi();
        services.AddSwaggerGen(/* options */);
        services.AddCors(/* options */);
    }
}
```

### Constructor Injection Pattern

**Standard Pattern:**
```csharp
public class PedalboardService : IPedalboardService
{
    private readonly IAudioBackendService _backendService;
    private readonly ILog<PedalboardService> _logger;
    
    // Constructor: All dependencies injected
    public PedalboardService(
        IAudioBackendService backendService,
        ILog<PedalboardService> logger)
    {
        // Null-coalescing throw pattern (modern C#)
        _backendService = backendService ?? throw new ArgumentNullException(nameof(backendService));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }
    
    // Methods use injected dependencies
    public async Task<Pedalboard> CreatePedalboardAsync(string name, string backendName)
    {
        _logger.Info($"Creating pedalboard: {name}");
        // Implementation...
    }
}
```

**Validation in Constructor:**
```csharp
public class PortDescriptionService : IPortDescriptionService
{
    private readonly IPortDescriptionBuilder _builder;
    private readonly ILog<PortDescriptionService> _logger;
    
    public PortDescriptionService(
        IPortDescriptionBuilder builder,
        ILog<PortDescriptionService> logger)
    {
        _builder = builder ?? throw new ArgumentNullException(nameof(builder));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }
}
```

---

## Service Lifetime Guidelines

### Service Lifetime Decision Matrix

| Scenario | Lifetime | Rationale |
|----------|----------|-----------|
| Logging (`ILog<T>`) | **Singleton** | Stateless, thread-safe, shared across app |
| Audio Backends (`IAudioBackend`) | **Singleton** | Heavy initialization, shared state |
| Audio Backend Service | **Singleton** | Manages singleton backends |
| Device Providers | **Singleton** | Stateless enumeration service |
| Plugin Discoverers | **Singleton** | Cached plugin metadata |
| Configuration Store | **Singleton** | Shared config state |
| Pedalboard Service | **Singleton** | Manages shared pedalboard state |
| Port Description Services | **Singleton** | Stateless transformation service |
| Connection Services | **Singleton** | Stateless analysis service |
| Logging Services (wrappers) | **Scoped** | Request-specific context |
| Configuration Service | **Scoped** | Request-specific changes |
| Controllers | **Scoped** | Per-request lifecycle (ASP.NET default) |

### Singleton Guidelines

**Use Singleton When:**
- Service is stateless OR manages shared state correctly (thread-safe)
- Service is expensive to initialize (caches, connections)
- Service needs to maintain global state (pedalboards collection)

**Example: Singleton with Shared State**
```csharp
public class PedalboardService : IPedalboardService
{
    private readonly Dictionary<string, Pedalboard> _pedalboards = new();
    private readonly object _lock = new();  // Thread safety
    
    public async Task<Pedalboard> CreatePedalboardAsync(string name, string backendName)
    {
        lock (_lock)  // Protect shared state
        {
            var pedalboard = new Pedalboard { Id = Guid.NewGuid().ToString(), Name = name };
            _pedalboards[pedalboard.Id] = pedalboard;
            return pedalboard;
        }
    }
}
```

### Scoped Guidelines

**Use Scoped When:**
- Service holds request-specific state
- Service is cheap to instantiate
- Service composes singleton dependencies

**Example: Scoped Service**
```csharp
services.AddScoped<PedalboardLoggingService>();  // Request-scoped

public class PedalboardLoggingService
{
    private readonly IPedalboardService _pedalboardService;  // Singleton OK!
    private readonly IConnectionDescriptionService _descriptionService;  // Singleton OK!
    private readonly ILog<PedalboardLoggingService> _logger;  // Singleton OK!
    
    // Scoped service can inject singleton dependencies
}
```

### Transient Guidelines

**Use Transient When:**
- Service holds operation-specific state
- Service is lightweight to create
- Service is used once and discarded

**Generally Avoided in Alsionyx** (prefer Singleton/Scoped for predictable lifecycle)

---

## Error Handling Strategy

### Exception Handling Layers

**Layer 1: Domain Layer (Core)**
- Throw specific exceptions (`ArgumentException`, `InvalidOperationException`)
- Never catch exceptions (let them bubble)
- Validate inputs and throw immediately

**Example:**
```csharp
public async Task ConnectPortsAsync(string pedalboardId, string fromPort, string toPort)
{
    // Validate immediately
    if (string.IsNullOrWhiteSpace(pedalboardId))
        throw new ArgumentException("Pedalboard ID cannot be null or empty", nameof(pedalboardId));
    
    if (string.IsNullOrWhiteSpace(fromPort))
        throw new ArgumentException("From port cannot be null or empty", nameof(fromPort));
    
    var pedalboard = await GetPedalboardAsync(pedalboardId);
    if (pedalboard == null)
        throw new InvalidOperationException($"Pedalboard '{pedalboardId}' not found");
    
    // Business logic...
}
```

**Layer 2: Service Layer**
- Log exceptions with context
- Transform domain exceptions if needed
- Let exceptions propagate to controller

**Layer 3: Controller Layer (Presentation)**
- Catch all exceptions
- Transform to appropriate HTTP status codes
- Return structured error responses

**Controller Pattern:**
```csharp
[HttpPost("{id}/plugins")]
public async Task<IActionResult> AddPlugin(string id, [FromBody] AddPluginRequest request)
{
    try
    {
        _logger.Info($"Adding plugin: PedalboardId='{id}', PluginUri='{request.PluginUri}'");
        
        var instanceId = await _pedalboardService.AddPluginAsync(id, request.PluginUri);
        
        _logger.Info($"Plugin added successfully: InstanceId='{instanceId}'");
        return Ok(new { InstanceId = instanceId });
    }
    catch (ArgumentException ex)
    {
        _logger.Warn($"Invalid request: {ex.Message}");
        return BadRequest(new { error = ex.Message });
    }
    catch (InvalidOperationException ex)
    {
        _logger.Warn($"Operation failed: {ex.Message}");
        return NotFound(new { error = ex.Message });
    }
    catch (Exception ex)
    {
        _logger.Error(ex, "Unexpected error adding plugin");
        return StatusCode(500, new { error = "Internal server error" });
    }
}
```

### Error Response Format

**Standard JSON Error Response:**
```json
{
  "error": "Human-readable error message",
  "details": "Optional additional details",
  "timestamp": "2026-01-18T10:30:00Z",
  "path": "/api/pedalboards/123/plugins"
}
```

**Implementation:**
```csharp
public record ErrorResponse(
    string Error,
    string? Details = null,
    DateTime? Timestamp = null,
    string? Path = null);

// Usage in controller:
return BadRequest(new ErrorResponse(
    Error: "Invalid plugin URI",
    Details: ex.Message,
    Timestamp: DateTime.UtcNow,
    Path: HttpContext.Request.Path
));
```

---

## Controller Design Patterns

### RESTful API Design Principles

**HTTP Verb Mapping:**
| Operation | HTTP Verb | Endpoint Pattern | Returns |
|-----------|-----------|-----------------|---------|
| List | GET | `/api/resource` | 200 + array |
| Get One | GET | `/api/resource/{id}` | 200 + object or 404 |
| Create | POST | `/api/resource` | 201 + object + Location header |
| Update | PUT | `/api/resource/{id}` | 200 + object or 204 |
| Partial Update | PATCH | `/api/resource/{id}` | 200 + object |
| Delete | DELETE | `/api/resource/{id}` | 204 or 200 + confirmation |
| Action | POST | `/api/resource/{id}/action` | 200 + result |

### Controller Responsibility Separation

**Alsionyx follows Single Responsibility Principle for controllers:**

**Bad (Old Design):**
```csharp
// PedalboardsController - TOO MANY RESPONSIBILITIES!
[Route("api/[controller]")]
public class PedalboardsController
{
    [HttpPost("{id}/plugins")]          // Plugin management
    [HttpPost("{id}/connections")]      // Connection management
    [HttpPost("{id}/start")]             // Pedalboard lifecycle
}
```

**Good (Current Design):**
```csharp
// Separated into 3 controllers:

// 1. Pedalboard lifecycle only
[Route("api/pedalboards")]
public class PedalboardsController
{
    [HttpGet]                    // List pedalboards
    [HttpGet("{id}")]            // Get pedalboard
    [HttpPost]                   // Create pedalboard
    [HttpDelete("{id}")]         // Delete pedalboard
    [HttpPost("{id}/start")]     // Start pedalboard
    [HttpPost("{id}/stop")]      // Stop pedalboard
    [HttpPost("{id}/save")]      // Save pedalboard
}

// 2. Plugin management for pedalboards
[Route("api/pedalboards/{pedalboardId}/plugins")]
public class PedalboardPluginsController
{
    [HttpPost]                   // Add plugin
    [HttpDelete("{instanceId}")] // Remove plugin
}

// 3. Connection management for pedalboards
[Route("api/pedalboards/{pedalboardId}/connections")]
public class PedalboardConnectionsController
{
    [HttpGet]                    // Get connections
    [HttpPost]                   // Create connection
    [HttpDelete]                 // Remove connection
}
```

### Controller Dependency Pattern

**Minimal Dependencies:**
Controllers should depend ONLY on the services they directly use.

**PedalboardsController (Lifecycle Only):**
```csharp
public class PedalboardsController : ControllerBase
{
    private readonly IPedalboardService _pedalboardService;  // Business logic
    private readonly ILog<PedalboardsController> _logger;    // Logging
    
    // NO connection service, NO plugin service - those are in separate controllers
}
```

**PedalboardConnectionsController (Connections Only):**
```csharp
public class PedalboardConnectionsController : ControllerBase
{
    private readonly IPedalBoardConnectionService _connectionService;  // ONLY connection service
    private readonly ILog<PedalboardConnectionsController> _logger;
    
    // NO pedalboard service - single responsibility!
}
```

### Route Naming Conventions

**Resource Routes:**
- Use plural nouns: `/api/pedalboards`, `/api/plugins`
- Use kebab-case for multi-word: `/api/audio-backends` (if needed)
- Prefer flat structure: `/api/pedalboards/{id}/plugins` not `/api/pedalboards/{id}/plugins/{pluginId}`

**Action Routes:**
- Use verbs for non-CRUD: `/api/pedalboards/{id}/start`, `/api/plugins/rescan`
- Place actions at end: `POST /api/resource/{id}/action`

---

## Model & DTO Design

### Domain Models vs DTOs

**Domain Models (in Alsionyx.Core):**
- Rich with behavior
- Validation logic
- Business rules
- Can be mutable

**DTOs (Request/Response):**
- Data transfer only
- Immutable (use records)
- Flat structure
- Validation attributes

### Record Pattern for DTOs

**Modern C# Records (Preferred):**
```csharp
// Request DTOs - immutable, validation-ready
public record CreatePedalboardRequest(string Name, string BackendName);

public record AddPluginRequest(string PluginUri);

public record ConnectPortsRequest(string FromPort, string ToPort);

// Response DTOs - can include computed properties
public record PedalboardResponse(
    string Id,
    string Name,
    bool IsActive,
    int PluginCount)
{
    public static PedalboardResponse FromDomain(Pedalboard pedalboard) => new(
        Id: pedalboard.Id,
        Name: pedalboard.Name,
        IsActive: pedalboard.IsActive,
        PluginCount: pedalboard.Plugins.Count
    );
}
```

### Model Validation Pattern

**Data Annotations (Simple Cases):**
```csharp
using System.ComponentModel.DataAnnotations;

public record CreatePedalboardRequest(
    [Required, MinLength(1, ErrorMessage = "Name cannot be empty")]
    string Name,
    
    [Required, MinLength(1, ErrorMessage = "Backend name cannot be empty")]
    string BackendName
);
```

**Manual Validation (Complex Cases):**
```csharp
public async Task<IActionResult> AddPlugin(string id, [FromBody] AddPluginRequest request)
{
    if (string.IsNullOrWhiteSpace(request.PluginUri))
        return BadRequest(new { error = "Plugin URI cannot be empty" });
    
    if (!Uri.IsWellFormedUriString(request.PluginUri, UriKind.Absolute))
        return BadRequest(new { error = "Plugin URI must be a valid absolute URI" });
    
    // Continue...
}
```

### Immutable Model Pattern

**Use `init` for Domain Models:**
```csharp
public class PortDescription
{
    public string DeviceName { get; init; } = string.Empty;
    public string PortName { get; init; } = string.Empty;
    public ChannelType Channel { get; init; }
    public string DisplayName { get; init; } = string.Empty;
    
    // No setters - constructed via builder or object initializer
}
```

**Builder Pattern for Complex Construction:**
```csharp
public interface IPortDescriptionBuilder
{
    PortDescription BuildDescription(
        AudioPortIdentity identity,
        string deviceName,
        string? mixerControl = null);
}

// Usage:
var description = _builder.BuildDescription(identity, "Intel HDA", "Master");
// Returns immutable PortDescription
```

---

## Testing Requirements

### Testing Pyramid (Target Distribution)

```
        E2E Tests (10%)
        ┌─────────────┐
        │ ~6 tests    │
       /└─────────────┘\
      /                 \
     /  Integration (20%) \
    ┌─────────────────────┐
    │    ~12 tests        │
   /└─────────────────────┘\
  /                         \
 /      Unit Tests (70%)     \
┌───────────────────────────────┐
│        ~42 tests              │
└───────────────────────────────┘

Total: ~60 tests for 80%+ coverage
```

### Browser Management: Automatic via microsoft.playwright.nunit

**Critical**: The `microsoft.playwright.nunit` NuGet package automatically manages browser lifecycle. **Do NOT manually install browsers**.

```csharp
// ❌ WRONG: Do NOT put this in GlobalSetup
[OneTimeSetUp]
public void Setup()
{
    Microsoft.Playwright.Program.Main(new[] { "install", "chromium" });
}

// ✅ RIGHT: Just inherit from PageTest
[TestFixture]
public class TestClass : PageTest
{
    // Browser installation is automatic - handled by PageTest base class
    // Binaries cached in ~/.playwright/ directory
    // Downloaded on first run, reused thereafter
}
```

**How It Works**:
- `microsoft.playwright.nunit` automatically detects when browser binaries are missing
- On first test run, it downloads and caches browsers (~/.playwright/)
- Subsequent runs use cached binaries - no re-downloading
- Browser availability is transparent to your tests
- If browsers are unavailable, clear error messages guide resolution

**Why NOT Manual Installation**:
- Duplicate functionality already in the package
- Manual scripts fail silently or with obscure errors
- Slower test startup (redundant checks)
- Fragile if Playwright CLI location changes
- The NUnit package is purpose-built for this scenario

**GlobalSetup Focus**:
Only use GlobalSetup for dependency injection and one-time initialization - never for browser installation:

```csharp
[SetUpFixture]
public class GlobalSetup
{
    [OneTimeSetUp]
    public void OneTimeSetUp()
    {
        // Create DI container for test infrastructure
        var services = new ServiceCollection();
        services.AddScoped<AlsionyxSut>();
        Provider = services.BuildServiceProvider();
        
        // Browser setup happens automatically in PageTest base class
    }
    
    public static IServiceProvider Provider { get; private set; } = null!;
}
```

### Test Naming Convention

**Pattern: `MethodName_Scenario_ExpectedBehavior`**

**Examples:**
```csharp
[Test]
public void GetPedalboardAsync_WithValidId_ReturnsPedalboard()

[Test]
public void GetPedalboardAsync_WithInvalidId_ReturnsNull()

[Test]
public void ConnectPortsAsync_WithNullPedalboardId_ThrowsArgumentException()

[Test]
public void Constructor_WithNullLogger_ThrowsArgumentNullException()
```

### Unit Test Structure (AAA Pattern)

**Arrange-Act-Assert:**
```csharp
[TestFixture]
public class PedalboardServiceTests
{
    [Test]
    public async Task AddPluginAsync_WithValidPlugin_ReturnsInstanceId()
    {
        // ARRANGE - Set up dependencies and test data
        var mockBackend = Substitute.For<IAudioBackend>();
        var mockLogger = Substitute.For<ILog<PedalboardService>>();
        var service = new PedalboardService(mockBackend, mockLogger);
        
        var pedalboard = await service.CreatePedalboardAsync("Test", "Mock");
        var pluginUri = "http://example.org/plugins/reverb";
        
        // ACT - Execute the method under test
        var instanceId = await service.AddPluginAsync(pedalboard.Id, pluginUri);
        
        // ASSERT - Verify the outcome
        Assert.That(instanceId, Is.Not.Null);
        Assert.That(instanceId, Is.Not.Empty);
        Assert.That(pedalboard.Plugins, Has.Count.EqualTo(1));
        Assert.That(pedalboard.Plugins[0].InstanceId, Is.EqualTo(instanceId));
        Assert.That(pedalboard.Plugins[0].PluginUri, Is.EqualTo(pluginUri));
    }
}
```

### Mocking with NSubstitute

**DO use NSubstitute (NOT Moq):**
```csharp
// Create mock
var mockService = Substitute.For<IPedalboardService>();

// Setup return value
mockService.GetPedalboardAsync("123").Returns(Task.FromResult(new Pedalboard()));

// Verify call was made
mockService.Received(1).GetPedalboardAsync("123");

// Verify call with specific argument
mockService.Received(1).AddPluginAsync(
    Arg.Is<string>(id => id == "123"),
    Arg.Any<string>()
);
```

### Test Fixtures and Setup

**Shared Setup Pattern:**
```csharp
[TestFixture]
public class PedalboardServiceTests
{
    private IAudioBackendService _mockBackendService = null!;
    private ILog<PedalboardService> _mockLogger = null!;
    private PedalboardService _service = null!;
    
    [SetUp]
    public void SetUp()
    {
        _mockBackendService = Substitute.For<IAudioBackendService>();
        _mockLogger = Substitute.For<ILog<PedalboardService>>();
        _service = new PedalboardService(_mockBackendService, _mockLogger);
    }
    
    [Test]
    public async Task TestSomething()
    {
        // Arrange (mocks already set up)
        // Act
        // Assert
    }
}
```

### Integration Test Pattern

**Testing with Real DI Container:**
```csharp
[TestFixture]
public class ApiContainerBuilderTests
{
    private IServiceProvider _serviceProvider = null!;
    
    [SetUp]
    public void SetUp()
    {
        var services = new ServiceCollection();
        var configuration = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string>())
            .Build();
        
        ApiContainerBuilder.RegisterCoreServices(services, configuration);
        _serviceProvider = services.BuildServiceProvider();
    }
    
    [Test]
    public void RegisterServices_PedalboardServiceRegistered_CanBeResolved()
    {
        // Act
        var service = _serviceProvider.GetService<IPedalboardService>();
        
        // Assert
        Assert.That(service, Is.Not.Null);
        Assert.That(service, Is.InstanceOf<PedalboardService>());
    }
}
```

### Playwright E2E Testing with WebApplicationFactory

**Critical Pattern for Kestrel + Playwright Integration:**

When using Playwright with `WebApplicationFactory`, the host must be explicitly initialized before accessing `ServerAddress`:

```csharp
[TestFixture]
[Parallelizable(ParallelScope.Self)]
public class CriticalJourneyTests : PlaywrightTestBase
{
    [SetUp]
    public async Task BeforeTestCase()
    {
        var provider = GlobalSetup.Provider 
            ?? throw new InvalidOperationException("GlobalSetup.Provider not initialized");
        
        _scope = provider.CreateAsyncScope();
        Sut = _scope.ServiceProvider.GetRequiredService<AlsionyxSut>();
        
        // ⚠️ CRITICAL: Force WebApplicationFactory to initialize Kestrel
        // WebApplicationFactory uses lazy initialization - ServerAddress is empty until host is created
        // Creating an HttpClient triggers CreateHost() and starts Kestrel server
        using var httpClient = Sut.CreateClient();
        await httpClient.GetAsync("/api/health");  // Triggers host startup
        
        // Now ServerAddress contains actual listening URL (e.g., "http://127.0.0.1:52048/")
        ApiBaseUrl = Sut.ServerAddress.TrimEnd('/');
        
        Page.SetDefaultTimeout(30_000);
        Page.SetDefaultNavigationTimeout(30_000);
    }
    
    [Test]
    public async Task Journey_CreateEntity_VerifyResponse()
    {
        // Use Page.APIRequest to make API calls
        var response = await Page.APIRequest.PostAsync(
            $"{ApiBaseUrl}/api/entities", 
            new() { DataObject = new { name = "Test" } });
        
        Assert.That(response.Ok, Is.True);
        var json = await response.JsonAsync();
        
        // ✅ Validate against actual API response properties
        var id = json.Value.GetProperty("id").GetString();
        Assert.That(id, Is.Not.Null.And.Not.Empty);
    }
}
```

**Key Implementation Details**:
- `[Parallelizable(ParallelScope.Self)]` enables parallel test execution
- Each test gets isolated Kestrel instance on dynamic port
- `AsyncServiceScope` ensures async disposal of servers after test
- `CreateClient()` call forces host initialization - **this is essential**
- Response validation uses actual model property names (camelCase in JSON)

**Common Gotchas**:
1. **Empty ServerAddress**: Forgot to call `CreateClient()` before accessing `ServerAddress`
2. **Invalid URL errors**: Tests try to use `/api/endpoint` instead of `{ApiBaseUrl}/api/endpoint`
3. **Property name mismatches**: Assuming `state` when actual property is `isActive`
4. **Non-existent endpoints**: Testing endpoints that don't actually exist in the API

---

## Build & Deployment Configuration

### Project File Configuration

**Standard .csproj Template:**
```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net9.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <TreatWarningsAsErrors>false</TreatWarningsAsErrors>
  </PropertyGroup>

  <!-- Package References -->
  <ItemGroup>
    <PackageReference Include="NLog" Version="5.x" />
  </ItemGroup>

  <!-- Project References -->
  <ItemGroup>
    <ProjectReference Include="..\Alsionyx.Core\Alsionyx.Core.csproj" />
  </ItemGroup>
</Project>
```

### GitHub Actions CI/CD

**Workflow Triggers:**
```yaml
on:
  push:
    branches: [ main, develop, 'copilot/**', 'feature/**' ]
  pull_request:
    branches: [ main, develop ]
```

**Build Steps:**
1. Restore dependencies (`dotnet restore`)
2. Check formatting (`dotnet format --verify-no-changes`)
3. Build solution (`dotnet build --configuration Release`)
4. Run tests (`dotnet test --no-build`)
5. Generate coverage (`coverlet`)

### NLog Configuration

**appsettings.json Integration:**
```json
{
  "NLog": {
    "autoReload": true,
    "throwConfigExceptions": true,
    "targets": {
      "async": true,
      "logfile": {
        "type": "File",
        "fileName": "${basedir}/logs/alsionyx-${shortdate}.log",
        "layout": "${longdate}|${level:uppercase=true}|${logger}|${message} ${exception:format=tostring}"
      },
      "console": {
        "type": "Console",
        "layout": "${time}|${level:uppercase=true}|${logger:shortName=true}|${message}"
      }
    },
    "rules": [
      {
        "logger": "*",
        "minLevel": "Info",
        "writeTo": "logfile,console"
      }
    ]
  }
}
```

### Docker Configuration

**Dockerfile (Multi-stage Build):**
```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY ["Alsionyx.Api/Alsionyx.Api.csproj", "Alsionyx.Api/"]
COPY ["Alsionyx.Core/Alsionyx.Core.csproj", "Alsionyx.Core/"]
RUN dotnet restore "Alsionyx.Api/Alsionyx.Api.csproj"
COPY . .
RUN dotnet build "Alsionyx.Api/Alsionyx.Api.csproj" -c Release -o /app/build
RUN dotnet publish "Alsionyx.Api/Alsionyx.Api.csproj" -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "Alsionyx.Api.dll"]
```

---

## Appendix: Quick Reference Checklists

### New Service Checklist
- [ ] Create interface in `Alsionyx.Core/Interfaces/`
- [ ] Implement service in `Alsionyx.Core/Services/`
- [ ] Add XML documentation to all public members
- [ ] Register in appropriate ContainerBuilder
- [ ] Create test fixture in `Alsionyx.Core.Tests/`
- [ ] Write at least 5 unit tests (happy path + edge cases)
- [ ] Verify DI resolution in container tests

### New Controller Checklist
- [ ] Inherit from `ControllerBase`
- [ ] Add `[ApiController]` and `[Route]` attributes
- [ ] Inject only required services (minimal dependencies)
- [ ] Add XML documentation to all endpoints
- [ ] Use appropriate HTTP verbs (GET/POST/PUT/DELETE)
- [ ] Wrap all logic in try/catch with proper status codes
- [ ] Add request/response DTOs as records
- [ ] Create integration tests

### New Model Checklist
- [ ] Define in `Alsionyx.Core/Models/`
- [ ] Add XML documentation to class and all properties
- [ ] Use `init` for immutable properties
- [ ] Consider using record type for DTOs
- [ ] Add validation where appropriate
- [ ] Create unit tests for any business logic

### Pre-Commit Checklist
- [ ] Run `dotnet format src/Alsionyx.sln`
- [ ] Run `dotnet build src/Alsionyx.sln`
- [ ] Run `dotnet test src/Alsionyx.sln`
- [ ] Verify no new compiler warnings
- [ ] Update documentation if public API changed
- [ ] Add XML comments to new public members

---

## Document Maintenance

**This document supplements:**
- [02-FEATURES-AND-REQUIREMENTS.md](02-FEATURES-AND-REQUIREMENTS.md) - Feature inventory
- [03-ARCHITECTURE-AND-DESIGN.md](03-ARCHITECTURE-AND-DESIGN.md) - System design
- [04-COMPONENTS-BY-LAYER.md](04-COMPONENTS-BY-LAYER.md) - Component details
- [05-TESTING-STRATEGY.md](05-TESTING-STRATEGY.md) - Testing patterns
- [06-WORKFLOWS-AND-PATTERNS.md](06-WORKFLOWS-AND-PATTERNS.md) - Common patterns

**For complete rebuild:**
1. Read this document first (coding standards, patterns)
2. Review architecture docs (system design)
3. Study existing code examples (reference implementation)
4. Follow test-first development (write tests, then implementation)

---

**End of Document**
