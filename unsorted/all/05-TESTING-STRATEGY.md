# Testing Strategy & Patterns

## Overview

Testing strategy uses **xUnit** for test framework, **NSubstitute** for mocking, and emphasizes testing valuable assertions with full Docker integration for deployment testing.

## Testing Pyramid

```
        ┌─────────────────────────┐
        │   E2E Tests             │
        │ (Playwright/Docker)     │
        │   ~30 tests             │
        └────────┬────────────────┘
               / \
              /   \
             /     \
        ┌──────────────────────────┐
        │ Integration Tests        │
        │ (API + Mock Services)    │
        │ ~20 tests                │
        └──────────┬───────────────┘
                 / \
                /   \
               /     \
        ┌──────────────────────────┐
        │ Unit Tests               │
        │ (Isolated Classes)       │
        │ ~60 tests                │
        └──────────────────────────┘
```

## Unit Testing Framework

### 1. xUnit + NSubstitute Pattern

#### Basic Service Test
```csharp
// TEST CLASS STRUCTURE
public class DeviceDiscoveryServiceTests
{
    private readonly ILog<DeviceDiscoveryService> _logger;
    private readonly IAudioDeviceProvider _deviceProvider;
    private readonly DeviceDiscoveryService _service;
    
    public DeviceDiscoveryServiceTests()
    {
        // Arrange - Create substitutes
        _logger = Substitute.For<ILog<DeviceDiscoveryService>>();
        _deviceProvider = Substitute.For<IAudioDeviceProvider>();
        
        // Arrange - Create service with dependencies
        _service = new DeviceDiscoveryService(_logger, _deviceProvider);
    }
    
    [Fact]
    public void GetDevices_WithValidProvider_ReturnsDeviceList()
    {
        // Arrange
        var mockDevices = new List<AudioDevice>
        {
            new("hw:0", "Built-in Audio", 2, 2),
            new("hw:1", "USB Audio", 2, 2)
        };
        _deviceProvider.GetAllDevices().Returns(mockDevices);
        
        // Act
        var result = _service.GetDevices();
        
        // Assert - VALUE TEST
        Assert.NotNull(result);
        Assert.Equal(2, result.Count);
        Assert.All(result, device => Assert.NotNull(device.Name));
    }
    
    [Fact]
    public void GetDevices_LogsDiscoveryAttempt()
    {
        // Arrange
        _deviceProvider.GetAllDevices().Returns(new List<AudioDevice>());
        
        // Act
        _service.GetDevices();
        
        // Assert - BEHAVIOR TEST
        _logger.Received(1).Info(Arg.Is<string>(s => s.Contains("Discovery")));
    }
    
    [Fact]
    public void GetPlaybackDevices_FiltersCorrectly()
    {
        // Arrange
        var devices = new List<AudioDevice>
        {
            new("hw:0", "Playback Device", playbackChannels: 2, captureChannels: 0),
            new("hw:1", "Capture Device", playbackChannels: 0, captureChannels: 2),
            new("hw:2", "Duplex Device", playbackChannels: 2, captureChannels: 2)
        };
        _deviceProvider.GetAllDevices().Returns(devices);
        
        // Act
        var result = _service.GetPlaybackDevices();
        
        // Assert
        Assert.Equal(2, result.Count);
        Assert.True(result.All(d => d.PlaybackChannels > 0));
    }
}
```

### 2. Testing Valuable Assertions

**GOOD TESTS** - Test something meaningful:

```csharp
✅ [Fact]
public void AudioFormat_CalculatesBitrate_Correctly()
{
    var format = new AudioFormat(48000, 24, 2); // 48kHz, 24-bit, stereo
    var bitrate = format.CalculateBitrate();
    Assert.Equal(2304000, bitrate); // 48000 * 24 * 2
}

// WHY THIS IS VALUABLE:
// - Tests actual calculation logic
// - Catches regressions in math
// - Serves as specification
```

**BAD TESTS** - Don't test framework behavior:

```csharp
❌ [Fact]
public void AudioFormat_Constructor_CreatesInstance()
{
    var format = new AudioFormat(48000, 24, 2);
    Assert.NotNull(format);
}

// WHY THIS IS WEAK:
// - Constructor will always work or throw
// - Tests framework, not our code
// - Adds noise, no real value
```

### 3. DI Container Testing (Generic Pattern)

**Problem:** How to verify all services are registered and resolvable?

**Solution:** Generic DI Validation Service

```csharp
public class DiContainerValidator
{
    private readonly IServiceProvider _provider;
    
    public DiContainerValidator(IServiceProvider provider)
    {
        _provider = provider;
    }
    
    /// <summary>
    /// Validates that all service types can be resolved.
    /// Generic - works for any service added to container.
    /// </summary>
    public void ValidateAllServicesResolvable()
    {
        var serviceTypes = _provider
            .GetType()
            .Assembly
            .GetTypes()
            .Where(t => t.Name.EndsWith("Service"))
            .Where(t => !t.IsAbstract && !t.IsInterface);
        
        var failures = new List<string>();
        foreach (var serviceType in serviceTypes)
        {
            try
            {
                var instance = _provider.GetService(serviceType);
                if (instance == null)
                    failures.Add($"Service {serviceType.Name} returned null");
            }
            catch (Exception ex)
            {
                failures.Add($"Service {serviceType.Name}: {ex.Message}");
            }
        }
        
        if (failures.Any())
            throw new InvalidOperationException(
                $"DI Container validation failed:\n{string.Join("\n", failures)}");
    }
}

// USAGE IN TEST
[Fact]
public void DependencyInjection_AllServicesResolvable()
{
    var services = new ServiceCollection();
    ConfigureServices(services); // From your Startup
    var provider = services.BuildServiceProvider();
    
    var validator = new DiContainerValidator(provider);
    validator.ValidateAllServicesResolvable(); // Throws if any service fails
}
```

**Benefits:**
- ✅ Generic - automatically checks ANY service added
- ✅ Early detection - catches missing registrations at startup
- ✅ Extensible - add more validation rules as needed
- ✅ Clear failure messages - tells you exactly what's missing

### 4. Mock ALSA Audio Device Library

**Strategy:** Create in-memory ALSA device simulator

```csharp
// MOCK DEVICE PROVIDER
public class MockAudioDeviceProvider : IAudioDeviceProvider
{
    private readonly List<MockAudioDevice> _devices;
    
    public MockAudioDeviceProvider()
    {
        // Simulate real ALSA device structure
        _devices = new List<MockAudioDevice>
        {
            new MockAudioDevice(
                name: "hw:CARD=Intel",
                longName: "Intel HDA",
                playbackChannels: 2,
                captureChannels: 2,
                supportedRates: new[] { 44100, 48000, 96000, 192000 },
                supportedFormats: new[] { 16, 24, 32 }
            ),
            new MockAudioDevice(
                name: "hw:CARD=USB",
                longName: "USB Audio Device",
                playbackChannels: 2,
                captureChannels: 2,
                supportedRates: new[] { 44100, 48000 },
                supportedFormats: new[] { 16, 24 }
            )
        };
    }
    
    public IEnumerable<AudioDevice> GetAllDevices()
    {
        return _devices.Cast<AudioDevice>();
    }
    
    public IEnumerable<AudioDevice> GetPlaybackDevices()
    {
        return _devices.Where(d => d.PlaybackChannels > 0);
    }
    
    public IEnumerable<AudioDevice> GetCaptureDevices()
    {
        return _devices.Where(d => d.CaptureChannels > 0);
    }
    
    public IEnumerable<AudioFormat> GetDeviceFormats(string deviceName)
    {
        var device = _devices.FirstOrDefault(d => d.Name == deviceName);
        if (device == null) return Enumerable.Empty<AudioFormat>();
        
        var formats = new List<AudioFormat>();
        foreach (var rate in device.SupportedRates)
        {
            foreach (var bitDepth in device.SupportedFormats)
            {
                for (int channels = 1; channels <= device.PlaybackChannels; channels++)
                {
                    formats.Add(new AudioFormat(rate, bitDepth, channels));
                }
            }
        }
        return formats;
    }
}

// MOCK DEVICE CLASS
public class MockAudioDevice : AudioDevice
{
    public int[] SupportedRates { get; }
    public int[] SupportedFormats { get; }
    
    public MockAudioDevice(
        string name,
        string longName,
        int playbackChannels,
        int captureChannels,
        int[] supportedRates,
        int[] supportedFormats
    ) : base(name, longName, playbackChannels, captureChannels)
    {
        SupportedRates = supportedRates;
        SupportedFormats = supportedFormats;
    }
}
```

### 5. Mock LV2 Plugin System

```csharp
public class MockLv2PluginDiscoverer : ILv2PluginDiscoverer
{
    private readonly List<PluginInfo> _plugins;
    
    public MockLv2PluginDiscoverer()
    {
        _plugins = new List<PluginInfo>
        {
            new PluginInfo(
                uri: "http://example.com/plugin/reverb",
                name: "Simple Reverb",
                type: PluginType.Effect,
                inputPorts: 2,
                outputPorts: 2
            ),
            new PluginInfo(
                uri: "http://example.com/plugin/compressor",
                name: "Dynamic Compressor",
                type: PluginType.Effect,
                inputPorts: 1,
                outputPorts: 1
            ),
            new PluginInfo(
                uri: "http://example.com/plugin/synth",
                name: "Simple Synth",
                type: PluginType.Instrument,
                inputPorts: 0,
                outputPorts: 2
            )
        };
    }
    
    public IEnumerable<PluginInfo> GetAllPlugins()
    {
        return _plugins;
    }
    
    public IEnumerable<PluginInfo> GetPluginsByType(PluginType type)
    {
        return _plugins.Where(p => p.Type == type);
    }
    
    public PluginInfo GetPluginByUri(string uri)
    {
        return _plugins.FirstOrDefault(p => p.Uri == uri);
    }
}
```

## Integration Testing

### Testing API + Mock Services

```csharp
public class DeviceApiIntegrationTests : IAsyncLifetime
{
    private WebApplicationFactory<Program> _factory;
    private HttpClient _client;
    
    public async Task InitializeAsync()
    {
        _factory = new WebApplicationFactory<Program>()
            .WithWebHostBuilder(builder =>
            {
                builder.ConfigureServices(services =>
                {
                    // Replace real provider with mock
                    services.RemoveAll(typeof(IAudioDeviceProvider));
                    services.AddSingleton<IAudioDeviceProvider>(
                        new MockAudioDeviceProvider()
                    );
                });
            });
        
        _client = _factory.CreateClient();
    }
    
    [Fact]
    public async Task GetDevices_ReturnsJson()
    {
        var response = await _client.GetAsync("/api/devices");
        Assert.True(response.IsSuccessStatusCode);
        
        var json = await response.Content.ReadAsStringAsync();
        Assert.NotEmpty(json);
        // Verify structure
        Assert.Contains("hw:CARD", json);
    }
    
    public async Task DisposeAsync()
    {
        _client?.Dispose();
        _factory?.Dispose();
    }
}
```

## E2E Testing with Docker

### Dockerfile for Testing
```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:9.0

# NO ALSA hardware access in test container
# Use mocked providers instead

WORKDIR /app
COPY . .

# Build
RUN dotnet build

# Run tests
CMD ["dotnet", "test", "--logger:json"]
```

### Docker Compose for Full Stack Testing
```yaml
version: '3.8'
services:
  api:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "5000:5000"
    environment:
      - ASPNETCORE_ENVIRONMENT=Testing
      - USE_MOCK_DEVICES=true
    command: dotnet run --configuration Release
  
  e2e-tests:
    build:
      context: .
      dockerfile: Dockerfile.E2E
    depends_on:
      - api
    environment:
      - API_URL=http://api:5000
    command: dotnet test Example.AlsaWebService.E2ETests
```

## Testing Best Practices

### 1. Arrange-Act-Assert (AAA) Pattern
```csharp
[Fact]
public void Service_DoesSomething_UnderCondition()
{
    // ARRANGE - Set up preconditions
    var mock = Substitute.For<IDependency>();
    var service = new Service(mock);
    
    // ACT - Do the thing
    var result = service.DoWork();
    
    // ASSERT - Verify outcome
    Assert.Equal(expected, result);
}
```

### 2. One Assertion Per Concept
```csharp
// GOOD - One idea per test
[Fact]
public void Filter_ExcludesInvalidDevices() => /* test one concept */

[Fact]
public void Filter_IncludesValidDevices() => /* test another concept */

// BAD - Multiple concepts
[Fact]
public void Filter_Works() => /* tests too many things */
```

### 3. Test Behavior, Not Implementation
```csharp
// GOOD - Tests what the class DOES
_service.LoadConfiguration();
Assert.Equal(expectedConfig, _service.CurrentConfig);

// BAD - Tests HOW it does it
Assert.True(_mockFile.ReadAsyncWasCalled);
```

### 4. Meaningful Test Names
```csharp
// GOOD
GetFormats_WithInvalidDevice_ThrowsArgumentException()
CalculateBitrate_WithStereoAndHighDepth_ReturnsCorrectValue()

// BAD
TestFormats()
Test1()
DoStuff()
```

## Test Metrics That Matter

| Metric | Goal | Why |
|--------|------|-----|
| **Code Coverage** | 70%+ | Find untested paths |
| **Assertion Quality** | All meaningful | Weak tests = false confidence |
| **Test Execution Time** | < 5 seconds | Enables frequent runs |
| **Failure Messages** | Crystal clear | Debug failures quickly |
| **DI Resolution** | 100% services | Catches wiring issues |

## Related Documentation

- [Logging Architecture](01-LOGGING-ARCHITECTURE.md) - Logger testing patterns
- [Components by Layer](04-COMPONENTS-BY-LAYER.md) - What to test in each component
- [Docker & Deployment](07-DOCKER-AND-DEPLOYMENT.md) - Docker testing containers
