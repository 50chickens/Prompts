# Architecture & Design

## System Overview

```
┌──────────────────────────────────────────────────────────────┐
│                     Web Browsers / Clients                    │
│                                                                │
│      ┌─────────────────────┐      ┌──────────────────────┐   │
│      │   Blazor WebApp     │      │   REST API Clients   │   │
│      │   (SPA)             │      │   (curl, postman)    │   │
│      │   Port 5002/5003    │      │   Port 5000/5001     │   │
│      └────────┬────────────┘      └──────────┬───────────┘   │
└─────────────────┼──────────────────────────────┼──────────────┘
                  │                              │
            HTTP/HTTPS                     HTTP/HTTPS
                  │                              │
┌─────────────────▼──────────────────────────────▼──────────────┐
│                    Presentation Layer                          │
├──────────────────────────────────────────────────────────────┤
│  Blazor Components          │      REST API Controllers      │
│  ├─ Device Selector         │      ├─ DeviceController      │
│  ├─ Format Configuration    │      ├─ ConfigController      │
│  ├─ Control Panel           │      └─ PluginController      │
│  └─ Status Display          │                                │
└─────────────────────────────┼────────────────────────────────┘
                              │
                         CORS-Enabled
                              │
┌─────────────────────────────▼────────────────────────────────┐
│                    Application Services Layer                 │
├──────────────────────────────────────────────────────────────┤
│  IAudioDeviceProvider          ILv2PluginDiscoverer          │
│  ├─ RealAudioDeviceProvider   ├─ RealLv2PluginDiscoverer   │
│  └─ MockAudioDeviceProvider   └─ MockLv2PluginDiscoverer   │
│                                                               │
│  IConfigurationStore           ILog<T>                        │
│  ├─ FileConfigStore           NLog Integration              │
│  └─ InMemoryConfigStore       ├─ NLogAdapter<T>            │
│                                └─ NLogLoggerCore<T>         │
└──────────────────────────────────────────────────────────────┘
                              │
                         NLog Logging
                              │
┌─────────────────────────────▼────────────────────────────────┐
│                    Infrastructure Layer                       │
├──────────────────────────────────────────────────────────────┤
│  Real (Production)          Mock (Testing)                    │
│  ├─ ALSA Device APIs        ├─ MockAudioDevice List        │
│  ├─ LV2 Plugin System       ├─ Mock Plugin Registry        │
│  ├─ File System             └─ In-Memory Storage           │
│  └─ OS Audio Services                                       │
└──────────────────────────────────────────────────────────────┘
```

## Layered Architecture

### Layer 1: Presentation Layer

**Responsibility:** User interface and HTTP communication

**Components:**
- **Blazor Components** (WebAssembly)
  - Device discovery and selection
  - Audio format configuration
  - Control panel (Start/Stop)
  - Status and error display

- **REST API Controllers**
  - DeviceController - Device management endpoints
  - ConfigurationController - Configuration endpoints
  - PluginController - Plugin management endpoints

**Dependencies:**
- HTTP clients (Blazor HttpClient, .NET HttpClient)
- REST frameworks (ASP.NET Core Controllers)
- UI frameworks (Bootstrap, Blazor)

**Key Principle:** No business logic - just translate HTTP to service calls

### Layer 2: Application Services Layer

**Responsibility:** Business logic and service orchestration

**Interfaces (Contracts):**

```csharp
// Device management
public interface IAudioDeviceProvider
{
    IEnumerable<AudioDevice> GetAllDevices();
    IEnumerable<AudioDevice> GetPlaybackDevices();
    IEnumerable<AudioDevice> GetCaptureDevices();
    IEnumerable<AudioFormat> GetDeviceFormats(string deviceName);
}

// Plugin management
public interface ILv2PluginDiscoverer
{
    IEnumerable<PluginInfo> GetAllPlugins();
    IEnumerable<PluginInfo> GetPluginsByType(PluginType type);
    PluginInfo GetPluginByUri(string uri);
}

// Configuration persistence
public interface IConfigurationStore
{
    Task<AudioConfiguration> LoadConfigAsync();
    Task SaveConfigAsync(AudioConfiguration config);
}

// Logging
public interface ILog<T>
{
    void Debug(string message);
    void Info(string message);
    void Warn(string message);
    void Error(string message);
    void Error(Exception ex, string message);
    void Trace(string message);
}
```

**Implementations:**

| Interface | Production | Testing |
|-----------|-----------|---------|
| IAudioDeviceProvider | RealAudioDeviceProvider | MockAudioDeviceProvider |
| ILv2PluginDiscoverer | RealLv2PluginDiscoverer | MockLv2PluginDiscoverer |
| IConfigurationStore | FileConfigurationStore | InMemoryConfigStore |
| ILog<T> | NLogAdapter<T> | NSubstitute For<ILog<T>> |

**Key Principles:**
- All services injectable via constructor
- All dependencies are interfaces
- Multiple implementations per interface (real vs mock)
- No static state

### Layer 3: Infrastructure Layer

**Responsibility:** External system integration

**Real Infrastructure:**
- ALSA audio device enumeration
- LV2 plugin discovery system
- File system I/O
- Operating system audio services

**Mock Infrastructure (Testing):**
- In-memory device lists
- Simulated plugin registry
- In-memory configuration storage
- NLog logging to memory targets

**Key Principle:** Never called directly by presentation/service layers

## Dependency Injection Pattern

### Registration Structure

```csharp
// In ConfigureServices()
public static void ConfigureServices(WebApplicationBuilder builder)
{
    // Logging - Always injected
    builder.Services.AddSingleton(typeof(ILog<>), 
        typeof(NLogAdapter<>));
    
    // Device Management
    builder.Services.AddSingleton<IAudioDeviceProvider>(
        GetDeviceProvider(builder.Environment));
    
    // Plugin Discovery
    builder.Services.AddSingleton<ILv2PluginDiscoverer>(
        GetPluginDiscoverer(builder.Environment));
    
    // Configuration Storage
    builder.Services.AddSingleton<IConfigurationStore>(
        GetConfigStore(builder.Environment));
    
    // Application Services
    builder.Services.AddScoped<IDeviceService, DeviceService>();
    builder.Services.AddScoped<IPluginService, PluginService>();
    builder.Services.AddScoped<IConfigurationService, ConfigurationService>();
}
```

### Dependency Resolution

```
Controller
  ├── Requests ILog<Controller>
  │   └── Resolved: NLogAdapter<Controller>
  │
  ├── Requests IDeviceService
  │   └── DeviceService
  │       ├── Requests ILog<DeviceService>
  │       │   └── Resolved: NLogAdapter<DeviceService>
  │       │
  │       └── Requests IAudioDeviceProvider
  │           ├── (Prod) RealAudioDeviceProvider
  │           └── (Test) MockAudioDeviceProvider
  │
  └── Requests IConfigurationService
      └── ConfigurationService
          ├── Requests ILog<ConfigurationService>
          │   └── Resolved: NLogAdapter<ConfigurationService>
          │
          └── Requests IConfigurationStore
              ├── (Prod) FileConfigurationStore
              └── (Test) InMemoryConfigStore
```

**Key Benefit:** Everything automatically wired, no manual factory methods needed

## Design Patterns Used

### 1. Dependency Injection (Constructor)
```csharp
public class DeviceService
{
    private readonly ILog<DeviceService> _logger;
    private readonly IAudioDeviceProvider _deviceProvider;
    
    public DeviceService(
        ILog<DeviceService> logger,
        IAudioDeviceProvider deviceProvider)
    {
        _logger = logger;
        _deviceProvider = deviceProvider;
    }
}
```

**Why:** Enables testing with mocks, loose coupling, testable code

### 2. Repository Pattern (Configuration)
```csharp
public interface IConfigurationStore
{
    Task<AudioConfiguration> LoadConfigAsync();
    Task SaveConfigAsync(AudioConfiguration config);
}
```

**Why:** Abstracts storage mechanism (file vs memory vs database)

### 3. Provider Pattern (Device & Plugin Discovery)
```csharp
public interface IAudioDeviceProvider
{
    IEnumerable<AudioDevice> GetAllDevices();
    // ...
}
```

**Why:** Multiple implementations (real vs mock) without code changes

### 4. Strategy Pattern (Logging)
```csharp
public interface ILog<T>
{
    void Info(string message);
    // ...
}
```

**Why:** Swap logging implementation (NLog vs others) without affecting services

### 5. Adapter Pattern (NLog Wrapper)
```csharp
public class NLogAdapter<T> : ILog<T>
{
    private readonly ILogger _nlogLogger;
    
    public void Info(string message) => _nlogLogger.Info(message);
}
```

**Why:** Decouples NLog from application code

### 6. Configuration-Based Pattern (Service Selection)
```csharp
// Register providers based on configuration
services.AddSingleton<IAudioDeviceProvider>(
    new RealAudioDeviceProvider()  // Always use real implementation
);
```

**Why:** Single code path for all environments ensures consistent behavior

## Error Handling Strategy

### API Error Response
```csharp
// Standard error format
{
    "error": "Invalid device name",
    "statusCode": 400,
    "timestamp": "2026-01-06T08:00:00Z"
}
```

### Service Error Handling
```csharp
public async Task<AudioConfiguration> LoadConfigAsync()
{
    try
    {
        _logger.Info("Loading configuration");
        var config = await _store.LoadConfigAsync();
        _logger.Info("Configuration loaded");
        return config;
    }
    catch (FileNotFoundException ex)
    {
        _logger.Warn("Config file not found, using defaults");
        return GetDefaultConfiguration();
    }
    catch (Exception ex)
    {
        _logger.Error(ex, "Failed to load configuration");
        throw;
    }
}
```

**Principle:** Log all errors, provide sensible defaults, let caller decide recovery

## Data Flow Diagrams

### Device Selection Workflow
```
User selects device in UI
  ↓
Blazor component calls API
  ↓
POST /api/configuration with new device
  ↓
ConfigurationController validates
  ↓
IConfigurationService.UpdateDevice()
  ↓
IConfigurationStore.SaveConfigAsync()
  ↓
(Prod) FileConfigurationStore writes JSON
(Test) InMemoryConfigStore updates memory
  ↓
Success response to UI
  ↓
UI updates display
```

### Format Configuration Workflow
```
User selects sample rate/bitrate/channels
  ↓
Blazor calculates bitrate in real-time
  ↓
User clicks "Save"
  ↓
API POST /api/configuration/format
  ↓
Service validates against device capabilities
  ↓
Config persisted
  ↓
UI confirms "Settings saved"
```

## Testing Architecture Impact

### What Gets Mocked
- Audio device enumeration
- Plugin discovery
- Configuration storage
- Logging output

### What Doesn't Get Mocked
- Service logic (business rules)
- API controllers
- Dependency injection
- JSON serialization

**Principle:** Mock external dependencies, test internal logic

## Deployment Considerations

### Production Configuration
- Use real providers (`RealAudioDeviceProvider`, `RealLv2PluginDiscoverer`)
- File-based configuration storage
- NLog to file + event log
- CORS restricted to trusted domains

### Docker/Testing Configuration
- Use mock providers automatically
- In-memory configuration storage
- NLog to memory targets
- CORS open for testing

### Environment Variables
```bash
# Production
ASPNETCORE_ENVIRONMENT=Production
USE_MOCK_DEVICES=false

# Testing/Docker
ASPNETCORE_ENVIRONMENT=Testing
USE_MOCK_DEVICES=true
```

## Related Documentation

- [Logging Architecture](01-LOGGING-ARCHITECTURE.md) - How NLog integrates
- [Components by Layer](04-COMPONENTS-BY-LAYER.md) - Detailed component breakdown
- [Testing Strategy](05-TESTING-STRATEGY.md) - How mocks implement this architecture
- [Docker & Deployment](07-DOCKER-AND-DEPLOYMENT.md) - Environment configuration
