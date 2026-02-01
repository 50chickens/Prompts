# Logging Architecture

## Overview

The application uses **NLog** for structured logging across application code and unit tests. A generic `ILog<T>` interface provides compile-time type safety and easy dependency injection.

## Architecture

### Core Components

#### 1. Generic Logger Interface
```
ILog<T> - Generic interface for dependency injection
  ├── Debug(string message)
  ├── Info(string message)
  ├── Warn(string message)
  ├── Error(string message)
  ├── Error(Exception ex, string message)
  └── Trace(string message)
```

**Purpose:** Type-safe logger injection - each class gets `ILog<ClassName>`

#### 2. NLog Integration Layer
- **NLogAdapter** - Adapts ILog<T> to underlying NLog logger
- **NLogLogger** - Per-type logger wrapper
- **NLogLoggerCore** - Core implementation
- **NLogLoggerFactoryAdapter** - Factory for creating loggers
- **NlogExtensions** - Extension methods for NLog configuration

#### 3. Log Manager
- `LogManager.GetLogger<T>()` - Static accessor without DI
- Useful for static contexts or one-off logging needs
- Returns `ILog<T>` interface

## Dependency Injection Setup

### In Application Startup
```csharp
// Register generic logging
builder.Services.AddSingleton(typeof(ILog<>), typeof(NLogAdapter<>));

// OR use LogManager factory
builder.Services.AddSingleton<ILog<MyClass>>(() => 
    LogManager.GetLogger<MyClass>());
```

### In Classes
```csharp
public class MyService
{
    private readonly ILog<MyService> _logger;
    
    public MyService(ILog<MyService> logger)
    {
        _logger = logger;
    }
    
    public void DoWork()
    {
        _logger.Info("Starting work");
        try
        {
            // Work here
            _logger.Info("Work completed");
        }
        catch (Exception ex)
        {
            _logger.Error(ex, "Work failed");
        }
    }
}
```

## Log Levels

| Level | Usage | When |
|-------|-------|------|
| **Trace** | Detailed flow tracing | Method entry/exit, parameter values |
| **Debug** | Development diagnostics | Internal state, loop iterations |
| **Info** | Important events | Service startup, major operations |
| **Warn** | Potential issues | Deprecated usage, recoverable errors |
| **Error** | Failures | Exceptions, failed operations |

## Structured Logging Patterns

### Pattern 1: Operation Context
```csharp
_logger.Info($"[DeviceDiscovery] Found {count} devices");
_logger.Info($"[Config] Loading from {path}");
```

### Pattern 2: Exception Logging
```csharp
_logger.Error(ex, "Failed to save configuration");
```

### Pattern 3: State Transitions
```csharp
_logger.Info("AudioService: IDLE → PLAYING");
_logger.Info("AudioService: PLAYING → ERROR");
```

### Pattern 4: Data Points
```csharp
_logger.Info($"Format: SR={sampleRate} BD={bitDepth} CH={channels}");
_logger.Info($"Device: {name} (Playback: {isPlayback})");
```

## Configuration

### Application Configuration
**appsettings.json:**
```json
{
  "NLog": {
    "Rules": [
      {
        "logger": "*",
        "minLevel": "Info",
        "writeTo": ["console", "file"]
      },
      {
        "logger": "Example.AlsaWebService.*",
        "minLevel": "Debug",
        "writeTo": ["console", "debugger"]
      }
    ],
    "Targets": {
      "file": {
        "type": "File",
        "fileName": "logs/app-.txt",
        "archiveNumbering": "Rolling",
        "archiveAboveSize": "10485760",
        "maxArchiveFiles": 7
      },
      "console": {
        "type": "ColoredConsole",
        "layout": "${longdate} [${level:uppercase}] ${logger}: ${message}"
      }
    }
  }
}
```

### Unit Test Configuration
**nlog.testing.config or via code:**
```csharp
var config = new LoggingConfiguration();
var memoryTarget = new MemoryTarget("memory");
config.AddRule(LogLevel.Trace, LogLevel.Fatal, memoryTarget);
LogManager.Configuration = config;
```

## Unit Test Logging

### Strategy 1: In-Memory Log Capture
```csharp
[Fact]
public void Service_LogsOperations()
{
    // Capture logs in memory
    var logs = new List<string>();
    var mockLogger = Substitute.For<ILog<TestService>>();
    mockLogger.Info(Arg.Do<string>(msg => logs.Add(msg)));
    
    var service = new TestService(mockLogger);
    service.DoWork();
    
    Assert.Contains("Work started", logs);
    Assert.Contains("Work completed", logs);
}
```

### Strategy 2: Verify Logger Calls
```csharp
[Fact]
public void Service_LogsErrors()
{
    var logger = Substitute.For<ILog<TestService>>();
    var service = new TestService(logger);
    
    service.FailOperation();
    
    logger.Received(1).Error(
        Arg.Is<Exception>(e => e is InvalidOperationException),
        Arg.Is<string>(m => m.Contains("Operation failed"))
    );
}
```

### Strategy 3: Structured Log Assertions
```csharp
[Fact]
public void Service_LogsWithContext()
{
    var logger = Substitute.For<ILog<TestService>>();
    var service = new TestService(logger);
    
    service.ProcessData(42);
    
    logger.Received(1).Info(
        Arg.Is<string>(msg => msg.Contains("42"))
    );
}
```

## Benefits of This Approach

1. **Type Safety** - `ILog<T>` prevents logger mixups
2. **Dependency Injection** - Easy to mock and test
3. **Structured** - Consistent logging format
4. **Queryable** - Logs easily filtered and searched
5. **Context Aware** - Logger knows its type
6. **Testable** - Verify logging behavior with NSubstitute
7. **Performance** - NLog is efficient and async-capable
8. **Flexible** - Configuration per environment

## Anti-Patterns to Avoid

❌ **Don't:** Use `Console.WriteLine()` for logging
```csharp
// BAD
Console.WriteLine("Error: " + ex.Message);
```

✅ **Do:** Use structured logging
```csharp
// GOOD
_logger.Error(ex, "Operation failed");
```

❌ **Don't:** Create static loggers
```csharp
// BAD
private static ILog<MyClass> _logger = LogManager.GetLogger<MyClass>();
```

✅ **Do:** Inject via constructor
```csharp
// GOOD
private readonly ILog<MyClass> _logger;
public MyClass(ILog<MyClass> logger) => _logger = logger;
```

❌ **Don't:** Log sensitive data
```csharp
// BAD
_logger.Info($"Password: {password}");
```

✅ **Do:** Log contextual information
```csharp
// GOOD
_logger.Info($"Authentication: attempt for user {username}");
```

## Related Documentation

- [Testing Strategy](05-TESTING-STRATEGY.md) - How logging integrates with tests
- [Architecture & Design](03-ARCHITECTURE-AND-DESIGN.md) - Logging layer in system design
- [Workflows & Patterns](06-WORKFLOWS-AND-PATTERNS.md) - Common logging patterns
