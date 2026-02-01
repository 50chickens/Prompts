# Components by Layer

## Overview

This document breaks down the Alsionyx Audio Manager application by component, showing responsibilities, interfaces, implementations, and testing strategies for each. The system uses a pluggable audio backend architecture supporting SoundFlow (primary), FileAudio, and Mock backends, with plans for future support of JACK, ASIO, and other backends.

```
┌─────────────────────────────────────────────────────────┐
│              Audio Device Management                    │
│           (Core Responsibility of App)                  │
└────┬──────────────────────────────────┬─────────────────┘
     │                                  │
     ▼                                  ▼
┌──────────────────────┐      ┌──────────────────────┐
│ LV2 Plugin System    │      │ Configuration &      │
│ Management           │      │ Persistence          │
└──────────┬───────────┘      └──────────┬───────────┘
           │                            │
           │        ┌────────┬──────────┘
           │        │        │
           ▼        ▼        ▼
        ┌─────────────────────────────┐
        │   REST API Service Layer    │
        └────────────┬────────────────┘
                     │
        ┌────────────┴─────────────┐
        │                          │
        ▼                          ▼
  ┌──────────────┐         ┌──────────────┐
  │  REST API    │         │  Blazor UI   │
  │ Controllers  │         │  Components  │
  └──────────────┘         └──────────────┘
```

## 1. Audio Device Management Component

**Core Responsibility:** Discover, enumerate, configure, and manage audio devices

### Interfaces

```csharp
namespace Alsionyx.Core.Audio
{
    // Represents a single audio device
    public class AudioDevice
    {
        public string Name { get; set; }              // e.g., "Intel HDA"
        public string DeviceClass { get; set; }       // Playback, Capture, Duplex
        public int Channels { get; set; }             // 2, 4, 6, 8, etc.
        public int MaxChannels { get; set; }
        public bool IsPlayback { get; set; }
        public bool IsCapture { get; set; }
    }

    // Supported audio format
    public class AudioFormat
    {
        public int SampleRate { get; set; }           // 44100, 48000, 96000, 192000
        public string BitDepth { get; set; }          // "16-bit", "24-bit", "32-bit"
        public int Channels { get; set; }             // 1-8
    }

    // Device discovery provider interface
    public interface IAudioDeviceProvider
    {
        IEnumerable<AudioDevice> GetAllDevices();
        IEnumerable<AudioDevice> GetPlaybackDevices();
        IEnumerable<AudioDevice> GetCaptureDevices();
        IEnumerable<AudioFormat> GetDeviceFormats(string deviceName);
    }
}
```

### Production Implementation

```csharp
public class RealAudioDeviceProvider : IAudioDeviceProvider
{
    private readonly ILog<RealAudioDeviceProvider> _logger;
    
    public RealAudioDeviceProvider(ILog<RealAudioDeviceProvider> logger)
    {
        _logger = logger;
    }
    
    public IEnumerable<AudioDevice> GetAllDevices()
    {
        _logger.Info("Enumerating audio devices");
        // Uses the active audio backend to discover devices
        // Returns actual system devices from the backend
    }
    
    public IEnumerable<AudioDevice> GetPlaybackDevices()
    {
        return GetAllDevices().Where(d => d.IsPlayback);
    }
    
    public IEnumerable<AudioDevice> GetCaptureDevices()
    {
        return GetAllDevices().Where(d => d.IsCapture);
    }
    
    public IEnumerable<AudioFormat> GetDeviceFormats(string deviceName)
    {
        _logger.Debug($"Getting formats for device: {deviceName}");
        // Queries backend for supported sample rates, bit depths, channels
    }
}
```

### Mock Implementation

```csharp
public class MockAudioDeviceProvider : IAudioDeviceProvider
{
    private readonly ILog<MockAudioDeviceProvider> _logger;
    private static readonly List<AudioDevice> MockDevices = new()
    {
        new AudioDevice
        {
            Name = "Intel HDA 0",
            DeviceClass = "Duplex",
            IsPlayback = true,
            IsCapture = true,
            Channels = 2,
            MaxChannels = 8
        },
        new AudioDevice
        {
            Name = "USB Audio Device",
            DeviceClass = "Playback",
            IsPlayback = true,
            IsCapture = false,
            Channels = 2,
            MaxChannels = 2
        },
        new AudioDevice
        {
            Name = "Generic Audio",
            DeviceClass = "Duplex",
            IsPlayback = true,
            IsCapture = true,
            Channels = 2,
            MaxChannels = 4
        }
    };
    
    public IEnumerable<AudioDevice> GetAllDevices()
    {
        _logger.Info("Returning mock devices");
        return MockDevices;
    }
    
    public IEnumerable<AudioDevice> GetPlaybackDevices()
    {
        return GetAllDevices().Where(d => d.IsPlayback);
    }
    
    public IEnumerable<AudioDevice> GetCaptureDevices()
    {
        return GetAllDevices().Where(d => d.IsCapture);
    }
    
    public IEnumerable<AudioFormat> GetDeviceFormats(string deviceName)
    {
        // Return realistic formats
        return new[]
        {
            new AudioFormat { SampleRate = 44100, BitDepth = "16-bit", Channels = 2 },
            new AudioFormat { SampleRate = 48000, BitDepth = "16-bit", Channels = 2 },
            new AudioFormat { SampleRate = 48000, BitDepth = "24-bit", Channels = 2 },
            new AudioFormat { SampleRate = 96000, BitDepth = "24-bit", Channels = 2 }
        };
    }
}
```

### Service Layer

```csharp
public interface IDeviceService
{
    Task<IEnumerable<AudioDevice>> DiscoverDevicesAsync();
    Task<IEnumerable<AudioFormat>> GetSupportedFormatsAsync(string deviceName);
    Task SetActiveDeviceAsync(string deviceName);
}

public class DeviceService : IDeviceService
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
    
    public Task<IEnumerable<AudioDevice>> DiscoverDevicesAsync()
    {
        _logger.Info("Starting device discovery");
        var devices = _deviceProvider.GetAllDevices();
        _logger.Info($"Found {devices.Count()} devices");
        return Task.FromResult(devices);
    }
    
    public Task<IEnumerable<AudioFormat>> GetSupportedFormatsAsync(
        string deviceName)
    {
        _logger.Debug($"Getting formats for: {deviceName}");
        var formats = _deviceProvider.GetDeviceFormats(deviceName);
        return Task.FromResult(formats);
    }
    
    public Task SetActiveDeviceAsync(string deviceName)
    {
        _logger.Info($"Setting active device: {deviceName}");
        // Validate device exists
        // Reconfigure audio subsystem
        return Task.CompletedTask;
    }
}
```

### API Controller

```csharp
[ApiController]
[Route("api/[controller]")]
public class DeviceController : ControllerBase
{
    private readonly ILog<DeviceController> _logger;
    private readonly IDeviceService _deviceService;
    
    public DeviceController(
        ILog<DeviceController> logger,
        IDeviceService deviceService)
    {
        _logger = logger;
        _deviceService = deviceService;
    }
    
    [HttpGet]
    public async Task<IActionResult> GetDevices()
    {
        try
        {
            var devices = await _deviceService.DiscoverDevicesAsync();
            return Ok(devices);
        }
        catch (Exception ex)
        {
            _logger.Error(ex, "Failed to discover devices");
            return StatusCode(500, new { error = "Device discovery failed" });
        }
    }
    
    [HttpGet("{deviceName}/formats")]
    public async Task<IActionResult> GetFormats(string deviceName)
    {
        try
        {
            var formats = await _deviceService.GetSupportedFormatsAsync(deviceName);
            return Ok(formats);
        }
        catch (Exception ex)
        {
            _logger.Error(ex, $"Failed to get formats for {deviceName}");
            return StatusCode(500, new { error = "Format retrieval failed" });
        }
    }
}
```

## 2. LV2 Plugin Management Component

**Core Responsibility:** Discover, catalog, filter, and manage LV2 audio plugins

### Interfaces

```csharp
namespace Alsionyx.Core.Plugins
{
    public enum PluginType
    {
        Reverb,
        Delay,
        Compressor,
        Equalizer,
        Distortion,
        Synth,
        Sampler,
        Filter,
        Analyzer,
        Generic
    }
    
    public class PluginInfo
    {
        public string Uri { get; set; }               // Unique identifier
        public string Name { get; set; }              // Display name
        public string Version { get; set; }
        public PluginType Type { get; set; }
        public int InputPorts { get; set; }
        public int OutputPorts { get; set; }
        public bool IsInstantiable { get; set; }
    }
    
    public interface ILv2PluginDiscoverer
    {
        IEnumerable<PluginInfo> GetAllPlugins();
        IEnumerable<PluginInfo> GetPluginsByType(PluginType type);
        PluginInfo GetPluginByUri(string uri);
    }
}
```

### Mock Implementation

```csharp
public class MockLv2PluginDiscoverer : ILv2PluginDiscoverer
{
    private readonly ILog<MockLv2PluginDiscoverer> _logger;
    private static readonly List<PluginInfo> MockPlugins = new()
    {
        new PluginInfo
        {
            Uri = "http://example.com/plugins/reverb",
            Name = "Reverb Chamber",
            Version = "1.0",
            Type = PluginType.Reverb,
            InputPorts = 2,
            OutputPorts = 2,
            IsInstantiable = true
        },
        new PluginInfo
        {
            Uri = "http://example.com/plugins/compressor",
            Name = "Dynamic Compressor",
            Version = "1.0",
            Type = PluginType.Compressor,
            InputPorts = 2,
            OutputPorts = 2,
            IsInstantiable = true
        },
        new PluginInfo
        {
            Uri = "http://example.com/plugins/synth",
            Name = "Basic Synth",
            Version = "1.0",
            Type = PluginType.Synth,
            InputPorts = 0,
            OutputPorts = 2,
            IsInstantiable = true
        }
    };
    
    public IEnumerable<PluginInfo> GetAllPlugins()
    {
        _logger.Info("Returning mock plugins");
        return MockPlugins;
    }
    
    public IEnumerable<PluginInfo> GetPluginsByType(PluginType type)
    {
        _logger.Debug($"Filtering plugins by type: {type}");
        return GetAllPlugins().Where(p => p.Type == type);
    }
    
    public PluginInfo GetPluginByUri(string uri)
    {
        return GetAllPlugins().FirstOrDefault(p => p.Uri == uri);
    }
}
```

### Service Layer

```csharp
public interface IPluginService
{
    Task<IEnumerable<PluginInfo>> DiscoverPluginsAsync();
    Task<IEnumerable<PluginInfo>> GetPluginsByTypeAsync(PluginType type);
    Task<bool> IsPluginAvailableAsync(string uri);
}

public class PluginService : IPluginService
{
    private readonly ILog<PluginService> _logger;
    private readonly ILv2PluginDiscoverer _discoverer;
    
    public PluginService(
        ILog<PluginService> logger,
        ILv2PluginDiscoverer discoverer)
    {
        _logger = logger;
        _discoverer = discoverer;
    }
    
    public Task<IEnumerable<PluginInfo>> DiscoverPluginsAsync()
    {
        _logger.Info("Discovering LV2 plugins");
        var plugins = _discoverer.GetAllPlugins();
        _logger.Info($"Found {plugins.Count()} plugins");
        return Task.FromResult(plugins);
    }
    
    public Task<IEnumerable<PluginInfo>> GetPluginsByTypeAsync(PluginType type)
    {
        _logger.Debug($"Getting plugins of type: {type}");
        var plugins = _discoverer.GetPluginsByType(type);
        return Task.FromResult(plugins);
    }
    
    public Task<bool> IsPluginAvailableAsync(string uri)
    {
        var plugin = _discoverer.GetPluginByUri(uri);
        return Task.FromResult(plugin != null && plugin.IsInstantiable);
    }
}
```

## 3. Configuration & Persistence Component

**Core Responsibility:** Load, validate, save, and manage application configuration

### Data Models

```csharp
namespace Alsionyx.Core.Configuration
{
    public class AudioConfiguration
    {
        public string ActiveDevice { get; set; }
        public int SampleRate { get; set; }
        public string BitDepth { get; set; }
        public int Channels { get; set; }
        public List<PluginChainItem> PluginChain { get; set; }
        public DateTime LastModified { get; set; }
    }
    
    public class PluginChainItem
    {
        public string PluginUri { get; set; }
        public int Order { get; set; }
        public Dictionary<string, float> Parameters { get; set; }
    }
}
```

### Storage Interfaces

```csharp
public interface IConfigurationStore
{
    Task<AudioConfiguration> LoadConfigAsync();
    Task SaveConfigAsync(AudioConfiguration config);
    Task ResetToDefaultAsync();
}
```

### Production Implementation

```csharp
public class FileConfigurationStore : IConfigurationStore
{
    private readonly ILog<FileConfigurationStore> _logger;
    private readonly string _configPath;
    
    public FileConfigurationStore(ILog<FileConfigurationStore> logger)
    {
        _logger = logger;
        // Configuration file path - NO direct file I/O in constructor
        _configPath = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
            "Alsionyx",
            "config.json");
    }
    
    public async Task<AudioConfiguration> LoadConfigAsync()
    {
        try
        {
            _logger.Info($"Loading config from {_configPath}");
            if (!File.Exists(_configPath))
            {
                _logger.Warn("Config file not found, returning defaults");
                return GetDefaultConfiguration();
            }
            
            var json = await File.ReadAllTextAsync(_configPath);
            var config = JsonSerializer.Deserialize<AudioConfiguration>(json);
            _logger.Info("Configuration loaded successfully");
            return config;
        }
        catch (Exception ex)
        {
            _logger.Error(ex, "Failed to load configuration");
            return GetDefaultConfiguration();
        }
    }
    
    public async Task SaveConfigAsync(AudioConfiguration config)
    {
        try
        {
            _logger.Info("Saving configuration");
            var directory = Path.GetDirectoryName(_configPath);
            Directory.CreateDirectory(directory);
            
            var json = JsonSerializer.Serialize(config, 
                new JsonSerializerOptions { WriteIndented = true });
            await File.WriteAllTextAsync(_configPath, json);
            
            _logger.Info("Configuration saved successfully");
        }
        catch (Exception ex)
        {
            _logger.Error(ex, "Failed to save configuration");
            throw;
        }
    }
    
    public Task ResetToDefaultAsync()
    {
        _logger.Warn("Resetting configuration to defaults");
        return SaveConfigAsync(GetDefaultConfiguration());
    }
    
    private AudioConfiguration GetDefaultConfiguration()
    {
        return new AudioConfiguration
        {
            ActiveDevice = "Default",
            SampleRate = 48000,
            BitDepth = "16-bit",
            Channels = 2,
            PluginChain = new(),
            LastModified = DateTime.UtcNow
        };
    }
}
```

### Mock Implementation

```csharp
public class InMemoryConfigStore : IConfigurationStore
{
    private readonly ILog<InMemoryConfigStore> _logger;
    private AudioConfiguration _config;
    
    public InMemoryConfigStore(ILog<InMemoryConfigStore> logger)
    {
        _logger = logger;
        _config = GetDefaultConfiguration();
    }
    
    public Task<AudioConfiguration> LoadConfigAsync()
    {
        _logger.Info("Loading config from memory");
        return Task.FromResult(new AudioConfiguration
        {
            ActiveDevice = _config.ActiveDevice,
            SampleRate = _config.SampleRate,
            BitDepth = _config.BitDepth,
            Channels = _config.Channels,
            PluginChain = new List<PluginChainItem>(_config.PluginChain),
            LastModified = _config.LastModified
        });
    }
    
    public Task SaveConfigAsync(AudioConfiguration config)
    {
        _logger.Info("Saving config to memory");
        _config = config;
        return Task.CompletedTask;
    }
    
    public Task ResetToDefaultAsync()
    {
        _logger.Warn("Resetting to default");
        _config = GetDefaultConfiguration();
        return Task.CompletedTask;
    }
    
    private AudioConfiguration GetDefaultConfiguration()
    {
        return new AudioConfiguration
        {
            ActiveDevice = "Mock Default",
            SampleRate = 48000,
            BitDepth = "16-bit",
            Channels = 2,
            PluginChain = new(),
            LastModified = DateTime.UtcNow
        };
    }
}
```

### Service Layer

```csharp
public interface IConfigurationService
{
    Task<AudioConfiguration> GetCurrentConfigAsync();
    Task UpdateDeviceAsync(string deviceName);
    Task UpdateFormatAsync(int sampleRate, string bitDepth, int channels);
    Task SaveAsync();
}

public class ConfigurationService : IConfigurationService
{
    private readonly ILog<ConfigurationService> _logger;
    private readonly IConfigurationStore _store;
    private AudioConfiguration _current;
    
    public ConfigurationService(
        ILog<ConfigurationService> logger,
        IConfigurationStore store)
    {
        _logger = logger;
        _store = store;
    }
    
    public async Task<AudioConfiguration> GetCurrentConfigAsync()
    {
        if (_current == null)
        {
            _logger.Info("Loading current configuration");
            _current = await _store.LoadConfigAsync();
        }
        return _current;
    }
    
    public async Task UpdateDeviceAsync(string deviceName)
    {
        var config = await GetCurrentConfigAsync();
        _logger.Info($"Updating device to: {deviceName}");
        config.ActiveDevice = deviceName;
    }
    
    public async Task UpdateFormatAsync(int sampleRate, string bitDepth, int channels)
    {
        var config = await GetCurrentConfigAsync();
        _logger.Info($"Updating format: {sampleRate}Hz {bitDepth} {channels}ch");
        config.SampleRate = sampleRate;
        config.BitDepth = bitDepth;
        config.Channels = channels;
    }
    
    public async Task SaveAsync()
    {
        if (_current != null)
        {
            _current.LastModified = DateTime.UtcNow;
            await _store.SaveConfigAsync(_current);
            _logger.Info("Configuration saved");
        }
    }
}
```

## 4. REST API Component

**Core Responsibility:** HTTP endpoints for device and plugin management

### Endpoints

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/devices` | List all audio devices |
| GET | `/api/devices/playback` | List playback devices |
| GET | `/api/devices/capture` | List capture devices |
| GET | `/api/devices/{name}/formats` | Get supported formats |
| POST | `/api/configuration/device` | Set active device |
| GET | `/api/configuration` | Get current configuration |
| POST | `/api/configuration/format` | Update audio format |
| GET | `/api/plugins` | List all plugins |
| GET | `/api/plugins/type/{type}` | Filter by type |
| GET | `/api/plugins/{uri}` | Get specific plugin |
| POST | `/api/configuration/plugins` | Set plugin chain |
| GET | `/api/health` | Health check |
| POST | `/api/configuration/reset` | Reset to defaults |

### Error Response Format

```json
{
    "error": "Invalid device name",
    "statusCode": 400,
    "timestamp": "2026-01-06T10:30:00Z",
    "traceId": "0HN1GMLFMTQQK:00000001"
}
```

## 5. Blazor WebAssembly UI Component

**Core Responsibility:** User interface for device, format, and plugin configuration

### Component Hierarchy

```
App.razor
├── Layout/MainLayout.razor
├── Pages/Index.razor
│   ├── Components/DeviceSelector.razor
│   │   └── Uses: IDeviceService
│   │
│   ├── Components/FormatConfiguration.razor
│   │   └── Uses: IDeviceService, IConfigurationService
│   │
│   ├── Components/PluginChain.razor
│   │   └── Uses: IPluginService, IConfigurationService
│   │
│   └── Components/StatusPanel.razor
│       └── Uses: IConfigurationService
│
└── Services/
    ├── HttpClientService
    └── WebAssemblyApp.cs (DI setup)
```

### Key Components

**DeviceSelector.razor**
```html
@inject HttpClient Http
@inject ILocalStorageService LocalStorage

<div class="device-selector">
    <label>Select Audio Device:</label>
    <select @onchange="OnDeviceChanged">
        @foreach (var device in Devices)
        {
            <option value="@device.Name">
                @device.Name (@device.DeviceClass)
            </option>
        }
    </select>
    
    @if (IsLoading)
    {
        <p>Loading devices...</p>
    }
    
    @if (!string.IsNullOrEmpty(Error))
    {
        <div class="alert alert-danger">@Error</div>
    }
</div>

@code {
    private List<AudioDevice> Devices = new();
    private bool IsLoading;
    private string Error;
    
    protected override async Task OnInitializedAsync()
    {
        await LoadDevices();
    }
    
    private async Task LoadDevices()
    {
        try
        {
            IsLoading = true;
            Devices = await Http.GetFromJsonAsync<List<AudioDevice>>(
                "api/devices");
        }
        catch (Exception ex)
        {
            Error = $"Failed to load devices: {ex.Message}";
        }
        finally
        {
            IsLoading = false;
        }
    }
    
    private async Task OnDeviceChanged(ChangeEventArgs e)
    {
        var deviceName = e.Value.ToString();
        await Http.PostAsJsonAsync(
            "api/configuration/device",
            new { deviceName });
    }
}
```

**FormatConfiguration.razor**
```html
@inject HttpClient Http

<div class="format-config">
    <h3>Audio Format</h3>
    
    <div class="form-group">
        <label>Sample Rate (Hz):</label>
        <select @bind="SelectedSampleRate">
            <option value="44100">44100</option>
            <option value="48000">48000</option>
            <option value="96000">96000</option>
            <option value="192000">192000</option>
        </select>
    </div>
    
    <div class="form-group">
        <label>Bit Depth:</label>
        <select @bind="SelectedBitDepth">
            <option value="16-bit">16-bit</option>
            <option value="24-bit">24-bit</option>
            <option value="32-bit">32-bit</option>
        </select>
    </div>
    
    <div class="form-group">
        <label>Channels:</label>
        <select @bind="SelectedChannels">
            <option value="1">Mono</option>
            <option value="2">Stereo</option>
            <option value="4">4.0</option>
            <option value="6">5.1</option>
            <option value="8">7.1</option>
        </select>
    </div>
    
    <button @onclick="SaveFormat">Save</button>
</div>

@code {
    private int SelectedSampleRate = 48000;
    private string SelectedBitDepth = "16-bit";
    private int SelectedChannels = 2;
    
    private async Task SaveFormat()
    {
        var request = new
        {
            SampleRate = SelectedSampleRate,
            BitDepth = SelectedBitDepth,
            Channels = SelectedChannels
        };
        
        await Http.PostAsJsonAsync("api/configuration/format", request);
    }
}
```

## Component Testing Strategy

Each component tested with:

1. **Unit Tests** - Service logic, pure C# methods
2. **Integration Tests** - WebApplicationFactory with mock providers
3. **E2E Tests** - Playwright browser automation testing actual UI

See [Testing Strategy](05-TESTING-STRATEGY.md) for detailed patterns.

## Related Documentation

- [Architecture & Design](03-ARCHITECTURE-AND-DESIGN.md) - System-level patterns
- [Testing Strategy](05-TESTING-STRATEGY.md) - How to test each component
- [Features & Requirements](02-FEATURES-AND-REQUIREMENTS.md) - What each component provides
