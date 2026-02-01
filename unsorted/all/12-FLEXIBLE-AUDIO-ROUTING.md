# Flexible Multi-Device Audio Routing Architecture

## Overview

Alsionyx supports flexible, low-latency audio routing through a **pedalboard-centric architecture** where audio flows from input devices, through the pedalboard's plugin chain, to output devices. The pedalboard acts as the central routing hub - inputs and outputs are NOT directly connected unless explicitly configured by the user.

## Audio Flow Architecture

### Pedalboard as Central Hub

```
┌─────────────────┐
│  Input Devices  │ ─────┐
│  - Audio Card 1 │      │
│  - Audio Card 2 │      │
│  - FileAudio    │      │
└─────────────────┘      │
                         ▼
                  ┌──────────────┐
                  │  PEDALBOARD  │
                  │              │
                  │  ┌────────┐  │
                  │  │Plugin 1│  │
                  │  └────┬───┘  │
                  │       │      │
                  │  ┌────▼───┐  │
                  │  │Plugin 2│  │
                  │  └────┬───┘  │
                  │       │      │
                  │  ┌────▼───┐  │
                  │  │Plugin N│  │
                  │  └────────┘  │
                  └──────┬───────┘
                         │
                         ▼
                  ┌─────────────────┐
                  │ Output Devices  │
                  │ - Audio Card 2  │
                  │ - Audio Card 3  │
                  │ - FileAudio     │
                  └─────────────────┘
```

### Key Principles

1. **No Direct Connection**: Input devices do NOT directly connect to output devices
2. **Pedalboard Processing**: All audio passes through the pedalboard's plugin chain
3. **User-Controlled Routing**: User explicitly defines:
   - Which input devices/channels feed into the pedalboard
   - How plugins are connected within the pedalboard
   - Which output devices/channels receive the processed audio
4. **Flexible Connections**: User can optionally create direct input→output connections within the pedalboard if desired

## Key Capabilities

### 1. Multi-Backend Input/Output

Users can select different backends for input and output independently:

- **Input Backends**: FileAudio, SoundFlow (real devices), Mock
- **Output Backends**: FileAudio, SoundFlow (real devices), Mock
- **Mix and Match**: Combine FileAudio input with multiple real device outputs

### 2. Multi-Device Selection

Within each backend (especially SoundFlow), select multiple devices:

- Select multiple input devices simultaneously
- Route to multiple output devices in parallel
- Each device can have different channel counts

### 3. Per-Channel Routing Through Pedalboard

Route individual audio channels through the pedalboard to specific destinations:

```
Example Scenario (Guitar Recording):
┌─────────────┐
│  Device 1   │  Audio Interface (2in/2out)
│  (Guitar In)│  - Use input channel 1
└──────┬──────┘
       │
       ▼
┌──────────────────────────────┐
│      PEDALBOARD              │
│  ┌────────┐  ┌────────┐     │
│  │Amp Sim │→ │Reverb  │     │
│  └────────┘  └────────┘     │
└──────────────┬───────────────┘
               │
       ├───────┴──────────┐
       │                  │
       ▼                  ▼
┌─────────────┐    ┌─────────────┐
│  Device 2   │    │  Device 3   │
│  (Studio)   │    │  (Live PA)  │
│  4 channels │    │  4 channels │
│  → Ch 3-4   │    │  → Ch 3-4   │
└─────────────┘    └─────────────┘
```

## Architecture

### Core Models

#### AudioRoutingConfiguration

```csharp
public class AudioRoutingConfiguration
{
    public string Id { get; set; }
    public string Name { get; set; }
    public List<InputRoute> InputRoutes { get; set; }
    public List<OutputRoute> OutputRoutes { get; set; }
    public ChannelRoutingMatrix ChannelMatrix { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime LastModified { get; set; }
}
```

#### InputRoute

```csharp
public class InputRoute
{
    public string BackendName { get; set; }  // "SoundFlow", "FileAudio"
    public string DeviceId { get; set; }     // Device identifier
    public int Channel { get; set; }         // Specific channel (0-based)
    public string Label { get; set; }        // User-friendly name
}
```

#### OutputRoute

```csharp
public class OutputRoute
{
    public string BackendName { get; set; }  // "SoundFlow", "FileAudio"
    public string DeviceId { get; set; }     // Device identifier
    public List<int> Channels { get; set; }  // Target channels
    public float Gain { get; set; }          // Output gain (0.0 - 1.0)
    public string Label { get; set; }        // User-friendly name
}
```

#### ChannelRoutingMatrix

```csharp
public class ChannelRoutingMatrix
{
    public Dictionary<string, List<string>> Routes { get; set; }
    // Key: "input:backend:device:channel"
    // Value: ["output:backend:device:channel", ...]
    
    public void AddRoute(InputRoute input, OutputRoute output, int outputChannel)
    {
        var inputKey = $"input:{input.BackendName}:{input.DeviceId}:{input.Channel}";
        var outputKey = $"output:{output.BackendName}:{output.DeviceId}:{outputChannel}";
        
        if (!Routes.ContainsKey(inputKey))
            Routes[inputKey] = new List<string>();
            
        Routes[inputKey].Add(outputKey);
    }
}
```

### Routing Engine

#### IRoutingEngine

```csharp
public interface IRoutingEngine
{
    Task<AudioRoutingConfiguration> CreateConfigurationAsync(string name);
    Task<bool> ApplyConfigurationAsync(string configurationId);
    Task<AudioRoutingConfiguration> GetConfigurationAsync(string configurationId);
    Task<IEnumerable<AudioRoutingConfiguration>> GetAllConfigurationsAsync();
    Task<bool> UpdateConfigurationAsync(AudioRoutingConfiguration configuration);
    Task<bool> DeleteConfigurationAsync(string configurationId);
    Task<bool> AddInputRouteAsync(string configurationId, InputRoute route);
    Task<bool> AddOutputRouteAsync(string configurationId, OutputRoute route);
    Task<bool> CreateChannelRoutingAsync(string configurationId, InputRoute input, 
                                         OutputRoute output, int outputChannel);
    Task<SystemLatencyInfo> GetLatencyInfoAsync(string configurationId);
}
```

#### RoutingEngine Implementation

```csharp
public class RoutingEngine : IRoutingEngine
{
    private readonly IAudioBackendService _backendService;
    private readonly ILog<RoutingEngine> _logger;
    private readonly Dictionary<string, AudioRoutingConfiguration> _configurations;
    private readonly object _lock = new();
    
    // Core responsibilities:
    // 1. Manage routing configurations
    // 2. Coordinate multiple backends
    // 3. Optimize buffer management for low latency
    // 4. Handle sample rate conversion if needed
    // 5. Manage gain/mixing for multiple outputs
}
```

## SoundFlow Integration

### Multi-Device Support

SoundFlow natively supports multi-device management:

```csharp
// Initialize multiple playback devices
var device1 = new AudioDeviceContext(AudioDeviceType.Playback);
device1.Initialize(deviceConfig1);

var device2 = new AudioDeviceContext(AudioDeviceType.Playback);
device2.Initialize(deviceConfig2);

// Each device has its own audio graph
device1.AudioGraph.AddSource(audioSource);
device2.AudioGraph.AddSource(audioSource);
```

### Low-Latency Configuration

```csharp
var config = new AudioDeviceConfig
{
    SampleRate = 48000,
    Channels = 2,
    Format = AudioFormat.Float32,
    BufferSizeInFrames = 128,  // Minimize for low latency
    ShareMode = ShareMode.Exclusive  // For lowest possible latency
};
```

### Channel Selection

```csharp
// Select specific channels from device
var channelMapper = new ChannelMapper();
channelMapper.MapInput(deviceId: "device1", channel: 0, to: "virtual:input:0");
channelMapper.MapOutput(from: "virtual:output:0", deviceId: "device2", channels: [2, 3]);
```

## UI Components

### Routing Matrix View

Visual representation showing:
- All available input sources (devices + channels)
- All available output destinations (devices + channels)
- Active routing connections
- Visual lines connecting inputs to outputs
- Color coding for different backends

### Device Selector

- Dropdown for backend selection
- Multi-select for devices within backend
- Per-device channel selection
- Real-time channel count display

### Latency Monitor

Display total system latency:
- Per-device latency
- Buffer latency
- Processing latency
- Total round-trip latency

## Performance Considerations

### 1. Zero-Copy Optimization

Where possible, avoid copying audio buffers:
- Direct device-to-device routing
- Shared memory buffers
- Reference passing instead of value copying

### 2. Buffer Management

Efficient buffer strategies:
- Ring buffers for smooth streaming
- Pre-allocated buffer pools
- Lock-free circular queues

### 3. Thread Synchronization

Minimize lock contention:
- One audio thread per device
- Lock-free message passing for coordination
- SPSC queues for inter-thread communication

### 4. Sample Rate Conversion

Handle different device sample rates:
- High-quality resampling (SoundFlow built-in)
- Configurable quality vs latency trade-off
- Automatic rate detection and conversion

## Testing Strategy

### Unit Tests

- Routing configuration CRUD operations
- Channel matrix validation
- Backend coordination logic
- Buffer management algorithms

### Integration Tests

- Multi-device initialization
- Cross-backend routing
- Real audio data flow
- Latency measurements

### E2E Tests (Playwright)

- Visual routing matrix interaction
- Device selection workflow
- Live audio monitoring
- Configuration save/load

## Implementation Phases

### Phase 1: Core Models & Services
- [ ] Create routing models
- [ ] Implement RoutingEngine
- [ ] Add routing API endpoints

### Phase 2: SoundFlow Backend
- [ ] Implement SoundFlowAudioBackend
- [ ] Multi-device initialization
- [ ] Channel routing support

### Phase 3: UI Components
- [ ] Routing matrix component
- [ ] Device selector component
- [ ] Latency monitor component

### Phase 4: Testing & Optimization
- [ ] Performance profiling
- [ ] Latency optimization
- [ ] E2E workflow tests

## Example Workflows

All workflows show audio flowing through the pedalboard's plugin chain before reaching outputs.

### Workflow 1: Guitar Recording + Live Monitoring

```
Input:
- Device 1 (Audio Interface) - Channel 1 (Guitar input)

Pedalboard Processing:
- Plugin 1: Amp Simulator
- Plugin 2: Reverb
- Plugin 3: EQ

Output (from pedalboard):
- Device 2 (Studio Monitors) - Channels 1-2 (Stereo monitoring)
- Device 3 (Recording Interface) - Channels 1-2 (To DAW)
- FileAudio - output.wav (Backup recording)

Flow: Device 1 Ch1 → Pedalboard (Amp→Reverb→EQ) → Device 2 + Device 3 + File
```

### Workflow 2: Multi-Source Mixing

```
Input:
- Device 1 - Channels 1-2 (Mic pair)
- Device 2 - Channel 1 (DI bass)
- FileAudio - backing-track.wav (Playback)

Pedalboard Processing:
- Mixer: Combine all inputs
- Plugin 1: Compressor
- Plugin 2: Master EQ

Output (from pedalboard):
- Device 3 (Main PA) - Channels 1-2 (Mix)
- FileAudio - live-mix.wav (Recording)

Flow: (Device 1 + Device 2 + FileIn) → Pedalboard (Mix→Compress→EQ) → Device 3 + FileOut
```

### Workflow 3: Distributed Audio System

```
Input:
- Device 1 - Channel 1 (Main microphone)

Pedalboard Processing:
- Plugin 1: De-esser
- Plugin 2: Noise Gate
- Plugin 3: Delay (for zone synchronization)

Output (from pedalboard):
- Device 2 - Channels 1-4 (Zone 1 speakers)
- Device 3 - Channels 1-4 (Zone 2 speakers)
- Device 4 - Channels 1-4 (Zone 3 speakers)
- FileAudio - broadcast.mp3 (Stream recording)

Flow: Device 1 Ch1 → Pedalboard (De-ess→Gate→Delay) → Devices 2,3,4 + File
```

### Workflow 4: Direct Input-to-Output (Optional)

```
While the pedalboard is the hub, users CAN create direct routing if needed:

Input:
- Device 1 - Channel 1 (Monitoring mic)

Pedalboard Connection:
- DIRECT: Input port → Output port (bypass all plugins)

Output:
- Device 2 - Channels 1-2 (Monitor speakers)

Flow: Device 1 Ch1 → Pedalboard (pass-through) → Device 2
Note: This is explicitly configured, not automatic
```

## API Examples

### Create Routing Configuration

```http
POST /api/routing/configurations
Content-Type: application/json

{
  "name": "Guitar Recording Setup",
  "inputRoutes": [
    {
      "backendName": "SoundFlow",
      "deviceId": "device-1",
      "channel": 0,
      "label": "Guitar Input"
    }
  ],
  "outputRoutes": [
    {
      "backendName": "SoundFlow",
      "deviceId": "device-2",
      "channels": [2, 3],
      "gain": 0.8,
      "label": "Studio Monitors"
    },
    {
      "backendName": "SoundFlow",
      "deviceId": "device-3",
      "channels": [2, 3],
      "gain": 0.8,
      "label": "PA System"
    }
  ]
}
```

### Apply Routing Configuration

```http
PUT /api/routing/configurations/{id}/apply
```

### Get System Latency

```http
GET /api/routing/configurations/{id}/latency

Response:
{
  "totalLatencyMs": 12.5,
  "breakdown": {
    "device1InputMs": 2.5,
    "processingMs": 3.0,
    "device2OutputMs": 3.5,
    "device3OutputMs": 3.5
  }
}
```

## References

- [SoundFlow Documentation](https://lsxprime.github.io/soundflow-docs/)
- [SoundFlow GitHub](https://github.com/LSXPrime/SoundFlow)
- [IMPLEMENTATION-ROADMAP.md](./IMPLEMENTATION-ROADMAP.md)
- [02-FEATURES-AND-REQUIREMENTS.md](./02-FEATURES-AND-REQUIREMENTS.md)
