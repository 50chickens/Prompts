# Docker & Deployment Strategy

## Problem: Testing Without Real Hardware

**Challenge:** The previous development had issues with HTTP/HTTPS redirect diagnosis and unclear testing baselines when running directly on host.

**Solution:** Docker-based containerized testing with mock audio devices - enables identical behavior in container, CI/CD, and production.

## Docker Architecture for ALSA Audio Manager

### Container Isolation Strategy

```
┌─────────────────────────────────────────────────────────┐
│ Docker Container - Isolated Test Environment            │
├─────────────────────────────────────────────────────────┤
│ ✅ Mock Audio Devices (in-memory)                       │
│ ✅ Mock LV2 Plugin System                               │
│ ✅ Mock Configuration Storage                           │
│ ❌ NO real ALSA hardware access                         │
│ ❌ NO OS-level commands                                 │
│ ❌ NO file system beyond storage layer                  │
└─────────────────────────────────────────────────────────┘
```

### Build Stages

#### Stage 1: Build
```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:9.0 as builder

WORKDIR /src
COPY . .

# Restore
RUN dotnet restore

# Build
RUN dotnet build -c Release --no-restore

# Test with mocks
RUN dotnet test -c Release --no-build --logger:json

# Publish
RUN dotnet publish -c Release --no-build -o /app/publish
```

#### Stage 2: Runtime
```dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:9.0

WORKDIR /app
COPY --from=builder /app/publish .

# Health check
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:5000/api/devices || exit 1

EXPOSE 5000 5002

# Run without real ALSA
ENV ASPNETCORE_ENVIRONMENT=Production
ENV USE_MOCK_DEVICES=true

ENTRYPOINT ["dotnet", "Example.AlsaWebService.dll"]
```

## Configuration-Based Mocking

### Provider Registration (Single Code Path)

```csharp
// In ApiContainerBuilder.cs
// Same code path for all environments
public static void RegisterCoreServices(
    IServiceCollection services,
    IConfiguration configuration)
{
    // Always register real implementations
    services.AddSingleton<IAudioDeviceProvider, RealAudioDeviceProvider>();
    services.AddSingleton<ILv2PluginDiscoverer, RealLv2PluginDiscoverer>();
    services.AddSingleton<IConfigurationStore, FileConfigurationStore>();
}
```

**Benefits of Single Code Path:**
- ✅ Same behavior across all environments
- ✅ No hidden development-only features
- ✅ Tests validate actual production code
- ✅ Simpler deployment logic
- ✅ Fewer configuration variables to manage

// appsettings.Testing.json
{
  "UseMockDevices": true,
  "Logging": {
    "LogLevel": {
      "Default": "Information"
    }
  }
}

// appsettings.Production.json
{
  "UseMockDevices": false,
  "Logging": {
    "LogLevel": {
      "Default": "Warning"
    }
  }
}
```

## Docker Compose for Full Stack

### Development Stack
```yaml
version: '3.8'

services:
  api:
    build:
      context: .
      target: builder
    ports:
      - "5000:5000"
      - "5001:5001"
    volumes:
      - .:/src
    environment:
      ASPNETCORE_ENVIRONMENT: Development
      ASPNETCORE_URLS: http://0.0.0.0:5000
      USE_MOCK_DEVICES: "true"
    command: dotnet run -p src/examples/Example.AlsaWebService --no-build

  ui:
    build:
      context: .
      target: builder
    ports:
      - "5002:5002"
    volumes:
      - .:/src
    environment:
      ASPNETCORE_ENVIRONMENT: Development
      ASPNETCORE_URLS: http://0.0.0.0:5002
    command: dotnet run -p src/examples/Example.AlsaWebService.UI --no-build
```

### Testing Stack
```yaml
version: '3.8'

services:
  unit-tests:
    build:
      context: .
      dockerfile: Dockerfile.Tests
    environment:
      ASPNETCORE_ENVIRONMENT: Testing
    command: dotnet test src/examples/Example.AlsaWebService.Tests

  integration-tests:
    build:
      context: .
      dockerfile: Dockerfile.Tests
    environment:
      ASPNETCORE_ENVIRONMENT: Testing
    command: dotnet test src/examples/Example.AlsaWebService.E2ETests
    depends_on:
      api:
        condition: service_healthy
    
  api:
    build:
      context: .
    ports:
      - "5000:5000"
    environment:
      ASPNETCORE_ENVIRONMENT: Testing
      USE_MOCK_DEVICES: "true"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/api/devices"]
      interval: 5s
      timeout: 3s
      retries: 3
```

## Solving Previous Testing Issues

### Problem 1: HTTP → HTTPS Redirect Confusion

**Old Approach (Failed):**
- Started service directly
- Browser/curl requests got 307 redirects
- Unclear why redirects happening
- Hard to diagnose in real environment

**New Approach (Docker):**
```dockerfile
# Dockerfile.Test
FROM mcr.microsoft.com/dotnet/sdk:9.0

WORKDIR /app
COPY . .

# Configure HTTP ONLY - no cert loading
ENV ASPNETCORE_ENVIRONMENT=Testing
ENV ASPNETCORE_URLS=http://0.0.0.0:5000

RUN dotnet build

# Test with clean environment
CMD ["dotnet", "run", "--configuration", "Release", "--no-build"]
```

**Result:**
- ✅ Clean environment every run
- ✅ No cert caching issues
- ✅ Reproducible behavior
- ✅ Easy to debug

### Problem 2: Environment-Specific Issues

**Old Approach (Failed):**
- Settings scattered in host system
- Different DLLs from different builds
- Hard to reset state
- Builds affected by .gitignore files

**New Approach:**
```dockerfile
# Fresh container every time
RUN dotnet clean
RUN rm -rf bin obj
RUN dotnet restore
RUN dotnet build
```

### Problem 3: Hardware Access Variability

**Old Approach (Failed):**
- Tests sometimes passed (hardware available)
- Sometimes failed (different hardware)
- Unclear why test failures

**New Approach:**
```csharp
// Always use mocks in container
public IServiceCollection AddAudioDevices(this IServiceCollection services)
{
    if (Environment.GetEnvironmentVariable("DOCKER_CONTAINER") == "true")
    {
        services.AddSingleton<IAudioDeviceProvider>(
            new MockAudioDeviceProvider());
    }
    else
    {
        services.AddSingleton<IAudioDeviceProvider>(
            new RealAudioDeviceProvider());
    }
    return services;
}
```

## Testing Workflows

### Workflow 1: Local Development
```bash
# Terminal 1: Start services
docker-compose -f docker-compose.dev.yml up

# Terminal 2: Run tests
docker-compose -f docker-compose.test.yml up

# Access UI: http://localhost:5002
# Access API: http://localhost:5000/swagger
```

### Workflow 2: CI/CD Pipeline
```yaml
# .github/workflows/build-test.yml
name: Build & Test

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v2
      
      - name: Build Docker image
        run: docker build -t alsa-audio-manager:test .
      
      - name: Run unit tests
        run: docker run alsa-audio-manager:test dotnet test --filter Category!=Integration
      
      - name: Run integration tests
        run: |
          docker-compose -f docker-compose.test.yml up --abort-on-container-exit
      
      - name: Upload coverage
        uses: codecov/codecov-action@v2
```

### Workflow 3: Production Deployment
```bash
# Build for production
docker build -t alsa-audio-manager:latest .

# Tag for registry
docker tag alsa-audio-manager:latest myregistry.azurecr.io/alsa-audio-manager:latest

# Push
docker push myregistry.azurecr.io/alsa-audio-manager:latest

# Deploy
kubectl apply -f k8s/deployment.yaml
```

## Mock Device Library Design

### Audio Device Mock Provider

```csharp
/// <summary>
/// Simulates ALSA device behavior for testing.
/// Mimics real device capabilities without hardware access.
/// </summary>
public class MockAudioDeviceProvider : IAudioDeviceProvider
{
    // Predefined realistic devices
    private static readonly List<MockAudioDevice> DefaultDevices = new()
    {
        new(
            "hw:CARD=PCH",
            "HDA Intel PCH",
            playback: 2, capture: 2,
            rates: new[] { 44100, 48000, 96000, 192000 },
            formats: new[] { 16, 24, 32 }
        ),
        new(
            "hw:CARD=Generic",
            "HDA Generic",
            playback: 2, capture: 2,
            rates: new[] { 44100, 48000 },
            formats: new[] { 16, 24 }
        ),
        new(
            "hw:CARD=USB",
            "USB Audio Device",
            playback: 2, capture: 2,
            rates: new[] { 44100, 48000, 96000 },
            formats: new[] { 16, 24 }
        )
    };
    
    private readonly List<MockAudioDevice> _devices;
    
    public MockAudioDeviceProvider()
    {
        _devices = new List<MockAudioDevice>(DefaultDevices);
    }
    
    public IEnumerable<AudioDevice> GetAllDevices() => _devices;
    
    public IEnumerable<AudioDevice> GetPlaybackDevices() =>
        _devices.Where(d => d.PlaybackChannels > 0);
    
    public IEnumerable<AudioDevice> GetCaptureDevices() =>
        _devices.Where(d => d.CaptureChannels > 0);
    
    public IEnumerable<AudioFormat> GetDeviceFormats(string deviceName)
    {
        var device = _devices.FirstOrDefault(d => d.Name == deviceName);
        if (device == null) yield break;
        
        // Generate all valid format combinations
        foreach (var rate in device.SupportedRates)
            foreach (var bitDepth in device.SupportedFormats)
                for (int channels = 1; channels <= device.PlaybackChannels; channels++)
                    yield return new AudioFormat(rate, bitDepth, channels, 256);
    }
}
```

## Healthchecks

### API Healthcheck
```csharp
// In ContainerBuilder
app.MapGet("/health", () =>
{
    var checks = new
    {
        status = "healthy",
        timestamp = DateTime.UtcNow,
        services = new
        {
            deviceProvider = CheckDeviceProvider(),
            pluginDiscoverer = CheckPluginDiscoverer(),
            configStorage = CheckConfigStorage()
        }
    };
    return Results.Ok(checks);
});

private static string CheckDeviceProvider()
{
    try
    {
        var devices = _deviceProvider.GetAllDevices();
        return devices.Any() ? "ready" : "degraded";
    }
    catch { return "failed"; }
}
```

### Docker Healthcheck
```dockerfile
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:5000/health || exit 1
```

## Benefits of Docker Approach

| Benefit | How |
|---------|-----|
| **Reproducible** | Same behavior every run |
| **Isolated** | No host system interference |
| **Fast** | Mocks are faster than real hardware |
| **Testable** | Full control over state |
| **Scalable** | Easy to run multiple containers |
| **CI/CD Ready** | Works in GitHub Actions, Azure Pipelines, etc |
| **Production Parity** | Container runs identically everywhere |

## Related Documentation

- [Testing Strategy](05-TESTING-STRATEGY.md) - Mock implementation details
- [Components by Layer](04-COMPONENTS-BY-LAYER.md) - Interfaces to mock
- [Architecture & Design](03-ARCHITECTURE-AND-DESIGN.md) - Dependency injection patterns
