# Workflows & Patterns

## Common Workflows

### Workflow 1: Device Discovery & Selection

```
User Perspective:
┌─────────────┐
│ Open App    │
└──────┬──────┘
       │
       ▼
┌────────────────────┐
│ "Available Devices"│
│ List appears       │
└──────┬─────────────┘
       │
       ▼
┌────────────────────┐
│ User clicks device │
└──────┬─────────────┘
       │
       ▼
┌────────────────────┐
│ "Device selected"  │
│ Config saved       │
└────────────────────┘


Technical Flow:
Blazor Component (DeviceSelector.razor)
  │
  ├── OnInitialized() → HTTP GET /api/devices
  │   │
  │   └─→ DeviceController.GetDevices()
  │       │
  │       └─→ IDeviceService.DiscoverDevicesAsync()
  │           │
  │           └─→ IAudioDeviceProvider.GetAllDevices()
  │               ├─ RealAudioDeviceProvider (Prod)
  │               │  └─ ALSA APIs → System devices
  │               │
  │               └─ MockAudioDeviceProvider (Test)
  │                  └─ In-memory list
  │
  │   Response: List<AudioDevice> → Render dropdown
  │
  └── OnDeviceChanged(device) → HTTP POST /api/configuration/device
      │
      └─→ ConfigurationController.SetDevice(device)
          │
          └─→ IConfigurationService.UpdateDeviceAsync()
              │
              └─→ IConfigurationStore.SaveConfigAsync()
                  ├─ FileConfigurationStore (Prod)
                  │  └─ Write JSON file
                  │
                  └─ InMemoryConfigStore (Test)
                     └─ Store in memory
```

**Key Logging Points:**
```csharp
// IAudioDeviceProvider
_logger.Info("Enumerating ALSA devices");
_logger.Debug($"Found device: Intel HDA with 2 channels");
_logger.Info("Device enumeration complete");

// IDeviceService
_logger.Info("Starting device discovery");
_logger.Info($"Found {devices.Count()} devices");

// IConfigurationService
_logger.Info($"Updating device to: Intel HDA");

// IConfigurationStore
_logger.Info("Saving configuration");
_logger.Info("Configuration saved successfully");
```

**Testing Strategy:**
```csharp
[Fact]
public async Task SetDevice_WithValidDevice_SavesConfig()
{
    // Arrange
    var mockProvider = Substitute.For<IAudioDeviceProvider>();
    mockProvider.GetAllDevices().Returns(new[] {
        new AudioDevice { Name = "Intel HDA" }
    });
    
    var mockStore = Substitute.For<IConfigurationStore>();
    var service = new ConfigurationService(_logger, mockStore);
    
    // Act
    await service.UpdateDeviceAsync("Intel HDA");
    await service.SaveAsync();
    
    // Assert
    await mockStore.Received(1).SaveConfigAsync(Arg.Is<AudioConfiguration>(
        c => c.ActiveDevice == "Intel HDA"));
}
```

---

### Workflow 2: Format Configuration

```
User Perspective:
┌──────────────────────┐
│ Select Sample Rate   │
│ (dropdown: 44.1k -  │
│  48k - 96k - 192k)   │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ Select Bit Depth     │
│ (dropdown: 16/24/32) │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ Select Channels      │
│ (dropdown: 1-8)      │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ Click "Save"         │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ "Settings saved"     │
│ indicator shows      │
└──────────────────────┘


Technical Flow:
FormatConfiguration.razor
  │
  └── SaveFormat() → HTTP POST /api/configuration/format
      │
      └─→ ConfigurationController.SetFormat(request)
          │
          └─→ IConfigurationService.UpdateFormatAsync()
              │
              ├── Validate format (48000 <= rate <= 192000)
              ├── _logger.Info("Updating format...")
              │
              └─→ Store.SaveConfigAsync(config)
                  │
                  └─→ Write to storage
```

**Validation Rules:**
```csharp
public class FormatValidator
{
    // Sample rates must be standard values
    private static readonly int[] ValidSampleRates = { 
        44100, 48000, 96000, 192000 
    };
    
    // Channels based on device capability
    // Check against IAudioDeviceProvider.GetDeviceFormats(deviceName)
    
    // Bit depths: 16, 24, or 32 bits
    private static readonly string[] ValidBitDepths = { 
        "16-bit", "24-bit", "32-bit" 
    };
}
```

**Testing Strategy:**
```csharp
[Theory]
[InlineData(44100, "16-bit", 2)]  // Valid
[InlineData(48000, "24-bit", 2)]  // Valid
[InlineData(96000, "32-bit", 8)]  // Valid
[InlineData(99999, "16-bit", 2)]  // Invalid sample rate
public async Task UpdateFormat_ValidatesAllParameters(
    int sampleRate, string bitDepth, int channels)
{
    // Arrange
    var service = new ConfigurationService(_logger, _mockStore);
    
    // Act
    await service.UpdateFormatAsync(sampleRate, bitDepth, channels);
    
    // Assert
    var saved = await _mockStore.SaveConfigAsync(Arg.Any<AudioConfiguration>());
}
```

---

### Workflow 3: Plugin Discovery & Chain Configuration

```
User Perspective:
┌─────────────────┐
│ Open Plugins    │
│ tab             │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Available       │
│ plugins         │
│ displayed       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ User drags      │
│ plugins into    │
│ chain           │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Reorder with    │
│ up/down arrows  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Click "Save"    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Chain applied   │
└─────────────────┘


Technical Flow:
PluginChain.razor
  │
  ├── OnInitialized() → HTTP GET /api/plugins
  │   │
  │   └─→ PluginController.GetAllPlugins()
  │       │
  │       └─→ IPluginService.DiscoverPluginsAsync()
  │           │
  │           └─→ ILv2PluginDiscoverer.GetAllPlugins()
  │               ├─ RealLv2PluginDiscoverer (Prod)
  │               │  └─ LV2 plugin paths
  │               │
  │               └─ MockLv2PluginDiscoverer (Test)
  │                  └─ In-memory list
  │
  │   Response: List<PluginInfo> → Render available plugins
  │
  └── SaveChain(chainItems) → HTTP POST /api/configuration/plugins
      │
      └─→ ConfigurationController.SetChain(chainItems)
          │
          └─→ IConfigurationService.UpdateChainAsync()
              │
              └─→ Store.SaveConfigAsync(config)
                  │
                  └─→ Persist plugin order + parameters
```

**Plugin Chain Structure:**
```csharp
// Configuration saved in storage
{
  "ActiveDevice": "Intel HDA",
  "SampleRate": 48000,
  "BitDepth": "16-bit",
  "Channels": 2,
  "PluginChain": [
    {
      "PluginUri": "http://example.com/reverb",
      "Order": 0,
      "Parameters": {
        "DryWet": 0.5,
        "RoomSize": 0.7
      }
    },
    {
      "PluginUri": "http://example.com/compressor",
      "Order": 1,
      "Parameters": {
        "Threshold": -20.0,
        "Ratio": 4.0
      }
    }
  ]
}
```

**Testing Strategy:**
```csharp
[Fact]
public async Task SavePluginChain_WithThreePlugins_PersistsOrderAndParams()
{
    // Arrange
    var mockDiscoverer = Substitute.For<ILv2PluginDiscoverer>();
    mockDiscoverer.GetAllPlugins().Returns(new[] {
        new PluginInfo { Uri = "http://example.com/reverb" },
        new PluginInfo { Uri = "http://example.com/compressor" }
    });
    
    var mockStore = Substitute.For<IConfigurationStore>();
    var service = new PluginService(_logger, mockDiscoverer);
    
    // Act
    var chain = new[] {
        new PluginChainItem { PluginUri = "reverb", Order = 0 },
        new PluginChainItem { PluginUri = "compressor", Order = 1 }
    };
    
    // Assert
    var config = await mockStore.Received(1).SaveConfigAsync(
        Arg.Is<AudioConfiguration>(c => 
            c.PluginChain.Count == 2 &&
            c.PluginChain[0].Order == 0 &&
            c.PluginChain[1].Order == 1
        ));
}
```

---

## Common Patterns

### Pattern 1: Service Initialization

**Problem:** Multiple services depend on configuration being loaded first

**Solution:** Lazy initialization with null checks
```csharp
public class ConfigurationService
{
    private AudioConfiguration _current;
    
    public async Task<AudioConfiguration> GetCurrentConfigAsync()
    {
        if (_current == null)
        {
            _logger.Info("Loading configuration from store");
            _current = await _store.LoadConfigAsync();
        }
        return _current;
    }
}
```

**Testing:**
```csharp
[Fact]
public async Task FirstCall_LoadsFromStore()
{
    // Act
    await service.GetCurrentConfigAsync();
    
    // Assert
    await _mockStore.Received(1).LoadConfigAsync();
}

[Fact]
public async Task SecondCall_ReturnsCached()
{
    // Act
    await service.GetCurrentConfigAsync();
    await service.GetCurrentConfigAsync();
    
    // Assert - Only called once despite two calls
    await _mockStore.Received(1).LoadConfigAsync();
}
```

---

### Pattern 2: Error Recovery with Defaults

**Problem:** Configuration file missing or corrupted

**Solution:** Return sensible defaults
```csharp
public async Task<AudioConfiguration> LoadConfigAsync()
{
    try
    {
        if (!File.Exists(_configPath))
        {
            _logger.Warn("Config not found, using defaults");
            return GetDefaultConfiguration();
        }
        
        var json = await File.ReadAllTextAsync(_configPath);
        return JsonSerializer.Deserialize<AudioConfiguration>(json);
    }
    catch (Exception ex)
    {
        _logger.Error(ex, "Error loading config, using defaults");
        return GetDefaultConfiguration();
    }
}
```

**Testing:**
```csharp
[Fact]
public async Task LoadConfig_WhenFileNotFound_ReturnsDefaults()
{
    // Arrange
    var store = new FileConfigurationStore(_logger);
    // Don't create the file
    
    // Act
    var config = await store.LoadConfigAsync();
    
    // Assert
    Assert.Equal("Default", config.ActiveDevice);
    Assert.Equal(48000, config.SampleRate);
}
```

---

### Pattern 3: Conditional Service Registration

**Problem:** Different providers needed for Production vs Testing

**Solution:** Environment-based factory
```csharp
public static void ConfigureServices(WebApplicationBuilder builder)
{
    // Always add logging
    builder.Services.AddSingleton(typeof(ILog<>), typeof(NLogAdapter<>));
    
    // Register real implementations (same for all environments)
    builder.Services.AddSingleton<IAudioDeviceProvider, 
        RealAudioDeviceProvider>();
    builder.Services.AddSingleton<IConfigurationStore, 
        FileConfigurationStore>();
}
```

**Testing:**
```csharp
[Fact]
public void AllEnvironments_RegisterRealProviders()
{
    // Arrange
    var builder = WebApplication.CreateBuilder();
    
    // Act
    ConfigureServices(builder);
    var services = builder.Services.BuildServiceProvider();
    
    // Assert - Same implementation for all environments
    var provider = services.GetRequiredService<IAudioDeviceProvider>();
    Assert.IsType<RealAudioDeviceProvider>(provider);
    
    var store = services.GetRequiredService<IConfigurationStore>();
    Assert.IsType<FileConfigurationStore>(store);
}
```

---

### Pattern 4: Logging Structured Data

**Problem:** Need to correlate errors across multiple components

**Solution:** Include context in logs
```csharp
public async Task SetActiveDeviceAsync(string deviceName)
{
    _logger.Info($"Setting active device: {deviceName}");
    
    try
    {
        var devices = _deviceProvider.GetAllDevices();
        var device = devices.FirstOrDefault(d => d.Name == deviceName);
        
        if (device == null)
        {
            _logger.Warn($"Device not found: {deviceName}");
            throw new ArgumentException($"Unknown device: {deviceName}");
        }
        
        _logger.Info($"Device validated. Channels: {device.Channels}, " +
                    $"Class: {device.DeviceClass}");
        
        // Configure audio system
        _logger.Debug("Reconfiguring audio subsystem");
    }
    catch (Exception ex)
    {
        _logger.Error(ex, $"Failed to set device: {deviceName}");
        throw;
    }
}
```

**Testing:**
```csharp
[Fact]
public async Task SetDevice_UnknownDevice_LogsWarning()
{
    // Arrange
    var mockProvider = Substitute.For<IAudioDeviceProvider>();
    mockProvider.GetAllDevices().Returns(new AudioDevice[0]);
    
    var mockLogger = Substitute.For<ILog<DeviceService>>();
    var service = new DeviceService(mockLogger, mockProvider);
    
    // Act
    await Assert.ThrowsAsync<ArgumentException>(
        () => service.SetActiveDeviceAsync("Unknown"));
    
    // Assert
    mockLogger.Received(1).Warn(Arg.Any<string>());
}
```

---

### Pattern 5: Request Validation Before Processing

**Problem:** Invalid requests should fail early and clearly

**Solution:** Validation layer in service
```csharp
public async Task UpdateFormatAsync(int sampleRate, string bitDepth, int channels)
{
    // Validate inputs
    if (!IsValidSampleRate(sampleRate))
    {
        _logger.Warn($"Invalid sample rate: {sampleRate}");
        throw new ArgumentException(
            $"Sample rate must be one of: 44100, 48000, 96000, 192000");
    }
    
    if (!IsValidBitDepth(bitDepth))
    {
        _logger.Warn($"Invalid bit depth: {bitDepth}");
        throw new ArgumentException(
            $"Bit depth must be one of: 16-bit, 24-bit, 32-bit");
    }
    
    if (channels < 1 || channels > 8)
    {
        _logger.Warn($"Invalid channel count: {channels}");
        throw new ArgumentException("Channels must be between 1 and 8");
    }
    
    // Update configuration
    var config = await GetCurrentConfigAsync();
    config.SampleRate = sampleRate;
    config.BitDepth = bitDepth;
    config.Channels = channels;
    
    _logger.Info($"Format updated: {sampleRate}Hz {bitDepth} {channels}ch");
}
```

**Testing:**
```csharp
[Theory]
[InlineData(99999)]    // Invalid
[InlineData(-1)]       // Invalid
[InlineData(0)]        // Invalid
public async Task UpdateFormat_InvalidRate_Throws(int rate)
{
    // Act & Assert
    await Assert.ThrowsAsync<ArgumentException>(
        () => service.UpdateFormatAsync(rate, "16-bit", 2));
}

[Theory]
[InlineData(44100)]    // Valid
[InlineData(48000)]    // Valid
[InlineData(192000)]   // Valid
public async Task UpdateFormat_ValidRate_Succeeds(int rate)
{
    // Act
    await service.UpdateFormatAsync(rate, "16-bit", 2);
    
    // Assert
    var config = await service.GetCurrentConfigAsync();
    Assert.Equal(rate, config.SampleRate);
}
```

---

## State Management in Blazor

### Managing Application State

```csharp
// AppState.cs - Centralized state container
public class AppState
{
    private AudioConfiguration _currentConfig;
    private List<AudioDevice> _availableDevices;
    
    public event Action OnStateChanged;
    
    public AudioConfiguration CurrentConfig
    {
        get => _currentConfig;
        set
        {
            if (_currentConfig != value)
            {
                _currentConfig = value;
                OnStateChanged?.Invoke();
            }
        }
    }
    
    public List<AudioDevice> AvailableDevices
    {
        get => _availableDevices;
        set
        {
            if (_availableDevices != value)
            {
                _availableDevices = value;
                OnStateChanged?.Invoke();
            }
        }
    }
}
```

### Using State in Components

```html
@inject AppState State
@implements IAsyncDisposable

<div>
    <h2>Current Device</h2>
    <p>@State.CurrentConfig?.ActiveDevice</p>
</div>

@code {
    protected override void OnInitialized()
    {
        State.OnStateChanged += StateHasChanged;
    }
    
    async ValueTask IAsyncDisposable.DisposeAsync()
    {
        State.OnStateChanged -= StateHasChanged;
    }
}
```

---

## Related Documentation

- [Architecture & Design](03-ARCHITECTURE-AND-DESIGN.md) - System architecture
- [Components by Layer](04-COMPONENTS-BY-LAYER.md) - Component details
- [Testing Strategy](05-TESTING-STRATEGY.md) - How to test these workflows
