# Pedalboard UI & Pluggable Audio Backend

## Overview

Alsionyx features a virtual pedalboard interface for audio effect chain management and a pluggable audio backend architecture for device flexibility.

**Important:** For complete system architecture, refer to:
- [03-ARCHITECTURE-AND-DESIGN.md](03-ARCHITECTURE-AND-DESIGN.md) - System design patterns
- [06-WORKFLOWS-AND-PATTERNS.md](06-WORKFLOWS-AND-PATTERNS.md) - Common workflows
- [12-FLEXIBLE-AUDIO-ROUTING.md](12-FLEXIBLE-AUDIO-ROUTING.md) - Multi-device routing architecture
- [IMPLEMENTATION-ROADMAP.md](IMPLEMENTATION-ROADMAP.md) - Actual deliverables

This document focuses on interface definitions and API contracts.

---

## Blazor UI Routes

**Application Routes (SPA root at `/`):**
- `/` - Home page
- `/pedalboard` - Primary pedalboard UI for creating and managing pedalboards

**API Endpoints (hosted at `http://localhost:5000/api` by default):**

Pedalboard Management:
- GET /api/pedalboards - List all pedalboards
- POST /api/pedalboards - Create pedalboard
- GET /api/pedalboards/{id} - Get pedalboard details
- DELETE /api/pedalboards/{id} - Delete pedalboard
- POST /api/pedalboards/{id}/plugins - Add plugin/effect
- DELETE /api/pedalboards/{id}/plugins/{instanceId} - Remove plugin
- POST /api/pedalboards/{id}/start - Start audio processing
- POST /api/pedalboards/{id}/stop - Stop audio processing

Plugin Management:
- GET /api/plugins - List all discovered plugins
- GET /api/plugins/{uri} - Get plugin details
- GET /api/plugins/{uri}/modgui - Get plugin UI metadata
- POST /api/plugins/rescan - Rescan plugin directories

Audio Device & Backend:
- GET /api/audiobackends - List available backends (SoundFlow, FileAudio, Mock, JACK, ASIO)
- GET /api/audiobackends/{name} - Get backend details
- GET /api/audiobackends/{name}/devices - List devices for backend
- GET /api/routing - Get current routing configuration
- POST /api/routing - Update routing configuration
- **POST /api/audio/backends/{name}/plugins** — load plugin into backend
- **POST /api/audio/backends/{name}/connections** — connect ports on backend
---

## Interface Definitions (Core Contracts)

### IAudioBackend Interface

```csharp
public interface IAudioBackend
{
    Task<bool> InitializeAsync();
    Task<bool> ShutdownAsync();
    Task<IEnumerable<AudioDevice>> GetDevicesAsync();
    Task<bool> SelectDeviceAsync(string deviceId);
    Task<string> LoadEffectAsync(string pluginUri);
    Task<bool> UnloadEffectAsync(string effectId);
    Task<bool> ConnectPortsAsync(string fromPort, string toPort);
    Task<bool> DisconnectPortsAsync(string fromPort, string toPort);
    Task<bool> SetParameterAsync(string effectId, string parameterId, float value);
    Task<float> GetParameterAsync(string effectId, string parameterId);
    Task<IEnumerable<BackendControl>> GetAvailableControlsAsync();
}
```

### IPedalboardService Interface

```csharp
public interface IPedalboardService
{
    Task<Pedalboard> CreateAsync(string name);
    Task<Pedalboard> GetAsync(string id);
    Task<IEnumerable<Pedalboard>> ListAsync();
    Task<bool> SaveAsync(Pedalboard pedalboard);
    Task<bool> DeleteAsync(string id);
    Task<string> AddEffectAsync(string pedalboardId, string pluginUri);
    Task<bool> RemoveEffectAsync(string pedalboardId, string effectId);
    Task<bool> ConnectEffectsAsync(string pedalboardId, string sourcePort, string destPort);
    Task<bool> DisconnectEffectsAsync(string pedalboardId, string sourcePort, string destPort);
}
```

## Component Architecture (Blazor Components)

**Component Hierarchy:**

- PedalboardPage (main container)
  - PedalboardHeader (name, controls)
  - EffectsRack (effect chain display)
    - EffectSlot (individual effect)
      - ModguiRenderer (plugin's custom UI)
      - KnobControl (parameters)
  - AvailableEffectsPanel (effect browser)
  - ConnectionVisualizer (wires/routing)
  - BackendControlsPanel (backend settings)

**Real-Time Synchronization:**
- SignalR hub for WebSocket updates
- Broadcast effect changes to all connected clients
- Sync parameter updates in real-time
- Sync connection changes

For complete component specifications, see [IMPLEMENTATION-ROADMAP.md Phase 2](IMPLEMENTATION-ROADMAP.md#phase-2-pedalboard-system--ui).

## Backend Architecture (Audio Processing)

For flexible multi-device routing architecture and detailed backend specifications, see:
- [12-FLEXIBLE-AUDIO-ROUTING.md](12-FLEXIBLE-AUDIO-ROUTING.md) - Multi-device routing patterns
- [IMPLEMENTATION-ROADMAP.md Phase 1](IMPLEMENTATION-ROADMAP.md#phase-1-core-audio-system) - Backend deliverables

**Supported Backends:**
- SoundFlow (primary, Phase 1)
- FileAudio (Phase 1)
- Mock (Phase 1, testing only)
- JACK (Phase 3)
- ASIO (Phase 3, Windows only)

## API Reference Summary

See [08-API-REFERENCE.md](08-API-REFERENCE.md) for complete API documentation.

**Key Endpoint Categories:**

Pedalboard CRUD:
- GET /api/pedalboards
- POST /api/pedalboards
- GET /api/pedalboards/{id}
- DELETE /api/pedalboards/{id}

Effect Management:
- POST /api/pedalboards/{id}/plugins
- DELETE /api/pedalboards/{id}/plugins/{instanceId}
- PUT /api/pedalboards/{id}/plugins/{instanceId}/parameters/{paramId}

Routing:
- GET /api/routing
- POST /api/routing
- POST /api/pedalboards/{id}/connections
- DELETE /api/pedalboards/{id}/connections

Plugin Discovery:
- GET /api/plugins
- GET /api/plugins/{uri}
- GET /api/plugins/{uri}/modgui
- POST /api/plugins/rescan

Backend Management:
- GET /api/audiobackends
- GET /api/audiobackends/{name}
- GET /api/audiobackends/{name}/devices

---

## Consolidated References

**For detailed content, refer to these documents:**

| Topic | Document |
|-------|----------|
| System architecture | [03-ARCHITECTURE-AND-DESIGN.md](03-ARCHITECTURE-AND-DESIGN.md) |
| Component layer | [04-COMPONENTS-BY-LAYER.md](04-COMPONENTS-BY-LAYER.md) |
| Common workflows | [06-WORKFLOWS-AND-PATTERNS.md](06-WORKFLOWS-AND-PATTERNS.md) |
| Multi-device routing | [12-FLEXIBLE-AUDIO-ROUTING.md](12-FLEXIBLE-AUDIO-ROUTING.md) |
| Implementation phases | [IMPLEMENTATION-ROADMAP.md](IMPLEMENTATION-ROADMAP.md) |
| Testing requirements | [Testing_Workflow.md](Testing_Workflow.md) |
| API details | [08-API-REFERENCE.md](08-API-REFERENCE.md) |
| Complete rebuild specs | [11-COMPLETE-REBUILD-SPECIFICATION.md](11-COMPLETE-REBUILD-SPECIFICATION.md)
│   ├── Settings button
│   └── Save/Load buttons
│
├── EffectsRack.razor (Main pedalboard canvas)
│   ├── InputSource.razor
│   │   └── Device selector
│   │
│   ├── EffectSlot.razor (Repeating for each effect)
│   │   ├── EffectName (draggable)
│   │   ├── EffectKnobs.razor (for each parameter)
│   │   │   ├── Knob visualization
│   │   │   ├── Value display
│   │   │   └── Min/Max labels
│   │   │
│   │   ├── EffectColorIndicator
│   │   │   └── Plugin type color
│   │   │
│   │   ├── EffectConnections.razor
│   │   │   └── Visual wire lines to next effect
│   │   │
│   │   └── RemoveEffectButton (X icon)
│   │
│   ├── OutputDestination.razor
│   │   └── Device selector
│   │
│   └── AvailableEffectsPanel.razor
│       ├── Search/filter
│       ├── Category tabs (Reverb, Delay, Compressor, etc.)
│       ├── Drag-and-drop zone
│       └── Effect library list
│
└── PedalboardFooter.razor
    ├── CPU load indicator
    ├── Latency display
    └── Export/Import pedalboard
```

### Key UI Components

#### 1. EffectsRack Component

```csharp
// Blazor component managing the effects chain visualization
[Component]
public partial class EffectsRack
{
    [Parameter]
    public Pedalboard Pedalboard { get; set; }
    
    [Inject]
    public IPedalboardService PedalboardService { get; set; }
    
    private List<EffectInstance> Effects { get; set; } = new();
    private bool IsDragging { get; set; }
    private EffectInstance DraggedEffect { get; set; }
    
    // Handle drag and drop
    private async Task OnEffectDrop(EffectInstance effect, int newPosition)
    {
        await PedalboardService.ReorderEffectAsync(
            Pedalboard.Id, 
            effect.InstanceId, 
            newPosition);
        
        await RefreshAsync();
    }
    
    // Handle effect removal
    private async Task OnEffectRemove(string instanceId)
    {
        await PedalboardService.RemoveEffectAsync(
            Pedalboard.Id, 
            instanceId);
        
        await RefreshAsync();
    }
    
    // Handle parameter change (knob turn)
    private async Task OnParameterChanged(
        string instanceId, 
        string parameterName, 
        float value)
    {
        await PedalboardService.SetEffectParameterAsync(
            Pedalboard.Id, 
            instanceId, 
            parameterName, 
            value);
    }
}
```

#### 2. EffectSlot Component

```csharp
// Individual effect display with interactive knobs
[Component]
public partial class EffectSlot
{
    [Parameter]
    public EffectInstance Effect { get; set; }
    
    [Parameter]
    public EventCallback<string> OnRemove { get; set; }
    
    [Parameter]
    public EventCallback<(string ParameterName, float Value)> OnParameterChange { get; set; }
    
    private PluginInfo PluginInfo { get; set; }
    
    // Render effect with colored background based on plugin type
    private string GetEffectColor() => Effect.Type switch
    {
        PluginType.Reverb => "purple",
        PluginType.Delay => "blue",
        PluginType.Compressor => "orange",
        PluginType.Equalizer => "green",
        PluginType.Distortion => "red",
        PluginType.Synth => "cyan",
        _ => "gray"
    };
}
```

#### 3. KnobControl Component

```csharp
// Visual knob for effect parameters
[Component]
public partial class KnobControl
{
    [Parameter]
    public string ParameterName { get; set; }
    
    [Parameter]
    public float Value { get; set; }
    
    [Parameter]
    public float Min { get; set; } = 0f;
    
    [Parameter]
    public float Max { get; set; } = 100f;
    
    [Parameter]
    public EventCallback<float> ValueChanged { get; set; }
    
    // Render interactive knob
    // On mouse drag: update value
    // On mouse wheel: adjust value
    // Display: angle based on (Value - Min) / (Max - Min) * 270°
}
```

#### 4. AvailableEffectsPanel Component

```csharp
// Browse and add effects to pedalboard
[Component]
public partial class AvailableEffectsPanel
{
    [Parameter]
    public List<PluginInfo> AvailablePlugins { get; set; }
    
    [Parameter]
    public EventCallback<string> OnEffectSelected { get; set; }
    
    private List<PluginInfo> FilteredPlugins { get; set; }
    private PluginType? SelectedCategory { get; set; }
    private string SearchText { get; set; } = "";
    
    // Filter plugins by type and search text
    // Drag effect from list to pedalboard
    // Show effect preview on hover
}
```

### Pedalboard Persistence

Pedalboards are stored as JSON files with complete signal routing:

```json
{
  "id": "my-pedalboard-2024",
  "name": "My Custom Setup",
  "description": "Guitar effects chain",
  "createdAt": "2026-01-06T10:00:00Z",
  "lastModified": "2026-01-06T15:30:00Z",
  "audioBackend": "ALSA",
  "inputDevice": "Intel HDA 0",
  "outputDevice": "Intel HDA 0",
  "sampleRate": 48000,
  "bufferSize": 256,
  
  "effects": [
    {
      "instanceId": "reverb-1",
      "pluginUri": "http://example.com/plugins/reverb",
      "pluginName": "Reverb Chamber",
      "enabled": true,
      "positionX": 100,
      "positionY": 50,
      "parameters": [
        {
          "symbol": "dryWet",
          "name": "Dry/Wet",
          "value": 0.5
        },
        {
          "symbol": "roomSize",
          "name": "Room Size",
          "value": 0.7
        }
      ]
    },
    {
      "instanceId": "compressor-1",
      "pluginUri": "http://example.com/plugins/compressor",
      "pluginName": "Dynamic Compressor",
      "enabled": true,
      "positionX": 300,
      "positionY": 50,
      "parameters": [
        {
          "symbol": "threshold",
          "name": "Threshold",
          "value": -20.0
        },
        {
          "symbol": "ratio",
          "name": "Compression Ratio",
          "value": 4.0
        }
      ]
    },
    {
      "instanceId": "delay-1",
      "pluginUri": "http://example.com/plugins/delay",
      "pluginName": "Stereo Delay",
      "enabled": true,
      "positionX": 500,
      "positionY": 50,
      "parameters": [
        {
          "symbol": "time",
          "name": "Delay Time",
          "value": 0.5
        },
        {
          "symbol": "feedback",
          "name": "Feedback",
          "value": 0.4
        }
      ]
    }
  ],
  
  "connections": [
    {
      "connectionId": "wire-1",
      "fromPort": "ALSA:in_L",
      "toPort": "reverb-1:audio_in_L",
      "type": "audio"
    },
    {
      "connectionId": "wire-2",
      "fromPort": "ALSA:in_R",
      "toPort": "reverb-1:audio_in_R",
      "type": "audio"
    },
    {
      "connectionId": "wire-3",
      "fromPort": "reverb-1:audio_out_L",
      "toPort": "compressor-1:audio_in_L",
      "type": "audio"
    },
    {
      "connectionId": "wire-4",
      "fromPort": "reverb-1:audio_out_R",
      "toPort": "compressor-1:audio_in_R",
      "type": "audio"
    },
    {
      "connectionId": "wire-5",
      "fromPort": "compressor-1:audio_out_L",
      "toPort": "delay-1:audio_in_L",
      "type": "audio"
    },
    {
      "connectionId": "wire-6",
      "fromPort": "compressor-1:audio_out_R",
      "toPort": "delay-1:audio_in_R",
      "type": "audio"
    },
    {
      "connectionId": "wire-7",
      "fromPort": "delay-1:audio_out_L",
      "toPort": "ALSA:out_L",
      "type": "audio"
    },
    {
      "connectionId": "wire-8",
      "fromPort": "delay-1:audio_out_R",
      "toPort": "ALSA:out_R",
      "type": "audio"
    }
  ]
}
```

**Port Naming Convention:**
- Device ports: `"{DeviceName}:in_{Channel}"` or `"{DeviceName}:out_{Channel}"`
- Plugin ports: `"{InstanceId}:{PortSymbol}"` (from LV2 metadata)
- MIDI ports: Audio + MIDI types both supported

---

## modgui System: Plugin Visual Representation

### What is modgui?

Each LV2 plugin package (`.lv2`) contains an optional `modgui` folder that provides:
- HTML template for the visual representation
- CSS stylesheet for styling
- JavaScript for interactive controls
- SVG graphics for knobs, switches, etc.
- Metadata in TTL format linking UI to plugin parameters

### Directory Structure

```
Ratatouille.lv2/
├── Ratatouille.so          # Plugin binary
├── Ratatouille.ttl         # Plugin metadata
├── manifest.ttl            # Plugin manifest
├── modgui.ttl              # modgui metadata
└── modgui/
    ├── icon-ratatouille.html       # Main UI template (Mustache)
    ├── stylesheet-ratatouille.css  # Styling
    ├── script-ratatouille.js       # Interactive JS
    ├── thumbnail-ratatouille.png   # 128x128 icon
    ├── screenshot-ratatouille.png  # 600x500 preview
    ├── knobs/                       # Knob graphics
    │   └── ratatouille-knob.png
    ├── pedals/                      # Pedal casing graphics
    │   └── ratatouille-pedal.png
    └── switches/                    # Switch graphics
        └── ratatouille-switch.png
```

### modgui.ttl Metadata Structure

```ttl
@prefix modgui: <http://moddevices.com/ns/modgui#> .
@prefix lv2:    <http://lv2plug.in/ns/lv2core#> .

<urn:brummer:ratatouille>
    modgui:gui [
        modgui:resourcesDirectory <modgui> ;
        modgui:iconTemplate <modgui/icon-ratatouille.html> ;
        modgui:stylesheet <modgui/stylesheet-ratatouille.css> ;
        modgui:javascript <modgui/script-ratatouille.js> ;
        modgui:screenshot <modgui/screenshot-ratatouille.png> ;
        modgui:thumbnail <modgui/thumbnail-ratatouille.png> ;
        modgui:brand "brummer" ;
        modgui:label "Ratatouille" ;
        modgui:model "mod-pedal-ratatouille" ;
        modgui:monitoredOutputs [ lv2:symbol "ms_latency" ] ;
        modgui:port [
            lv2:index 0 ;
            lv2:symbol "Knob0" ;
            lv2:name "input" ;
        ] , [
            lv2:index 2 ;
            lv2:symbol "Knob2" ;
            lv2:name "blend" ;
        ] , [
            lv2:index 4 ;
            lv2:symbol "Knob3" ;
            lv2:name "mix" ;
        ] ;
    ] .
```

### HTML Template (Mustache Format)

The HTML template uses Mustache templating to dynamically render controls:

```html
<div class="mod-pedal mod-pedal-ratatouille {{{cns}}}">
    <div mod-role="drag-handle" class="mod-drag-handle"></div>
    
    <div class="mod-powerswitch" mod-role="bypass">
        <div class="mod-powerswitch-image" mod-role="bypass-light"></div>
    </div>

    <div class="mod-control-group mod-knobs top clearfix">
        {{#controls.0}}
        <div class="mod-knob" title="{{name}}">
            <div class="mod-knob-image" 
                 mod-role="input-control-port" 
                 mod-port-symbol="{{symbol}}">
            </div>
            <span class="mod-knob-title">{{name}}</span>
        </div>
        {{/controls.0}}
        
        {{#controls.2}}
        <div class="mod-knob" title="{{name}}">
            <div class="mod-knob-image" 
                 mod-role="input-control-port" 
                 mod-port-symbol="{{symbol}}">
            </div>
            <span class="mod-knob-title">{{name}}</span>
        </div>
        {{/controls.2}}
    </div>
</div>
```

### CSS Example

```css
.mod-pedal {
    width: 120px;
    height: 200px;
    border: 2px solid #333;
    border-radius: 10px;
    background: linear-gradient(135deg, #444, #666);
    padding: 10px;
    box-shadow: 0 4px 8px rgba(0,0,0,0.5);
}

.mod-knob {
    width: 40px;
    height: 40px;
    display: inline-block;
    margin: 5px;
    text-align: center;
}

.mod-knob-image {
    width: 40px;
    height: 40px;
    background: url('knobs/knob.png') center/contain no-repeat;
    cursor: pointer;
}

.mod-powerswitch {
    position: absolute;
    top: 10px;
    right: 10px;
    width: 30px;
    height: 30px;
}

.mod-control-group {
    margin: 10px 0;
}
```

### JavaScript Interaction

```javascript
// Dynamically handle parameter changes
(function(mod) {
    // Called when parameter value changes
    mod.setPortValue = function(port, value) {
        // Update visual representation (knob angle, etc.)
        const knobElement = document.querySelector(
            `[mod-port-symbol="${port}"] .mod-knob-image`
        );
        if (knobElement) {
            // Calculate angle: 0° to 270° based on normalized value
            const angle = (value * 270) - 135;
            knobElement.style.transform = `rotate(${angle}deg)`;
        }
    };

    // Called when user clicks/drags a control
    mod.onPortChanged = function(port, value) {
        // Send to backend via API/WebSocket
        fetch(`/api/pedalboard/effects/${effectId}/parameter/${port}`, {
            method: 'PUT',
            body: JSON.stringify({ value })
        });
    };
})(Pedalboard);
```

### Implementation in C# / Blazor

```csharp
public class PluginModgui
{
    public string PluginUri { get; set; }
    
    // Loaded from modgui.ttl
    public string Brand { get; set; }
    public string Label { get; set; }
    public string Model { get; set; }
    public string IconTemplateHtml { get; set; }
    public string StylesheetCss { get; set; }
    public string JavascriptCode { get; set; }
    public string ScreenshotPath { get; set; }
    public string ThumbnailPath { get; set; }
    
    // Port mappings
    public List<ModguiPort> Ports { get; set; } = new();
    
    // Monitored outputs (for latency, etc.)
    public List<string> MonitoredOutputs { get; set; } = new();
}

public class PluginInfo
{
    public string Uri { get; set; }
    public string Name { get; set; }
    public string Version { get; set; }
    public string Description { get; set; }
    public PluginType Type { get; set; }
    
    // Port definitions from LV2 metadata
    public List<PortInfo> Ports { get; set; } = new();
    
    // Visual representation from modgui
    public PluginModgui Modgui { get; set; }
    
    // Capabilities
    public bool SupportsAudio { get; set; }
    public bool SupportsMidi { get; set; }
    public int MinChannels { get; set; }
    public int MaxChannels { get; set; }
    public float Latency { get; set; }
}

// Service to load modgui
public class PluginDiscoveryService : ILv2PluginDiscoverer
{
    private async Task<PluginModgui> LoadModguiAsync(string pluginPath)
    {
        var modguiFolder = Path.Combine(pluginPath, "modgui");
        if (!Directory.Exists(modguiFolder))
            return null; // No UI available, but plugin still usable
        
        // Parse modgui.ttl
        var ttlPath = Path.Combine(modguiFolder, "modgui.ttl");
        var modguiData = ParseTtlFile(ttlPath);
        
        // Load HTML template
        var htmlPath = Path.Combine(
            modguiFolder, 
            modguiData["iconTemplate"]
        );
        var html = await File.ReadAllTextAsync(htmlPath);
        
        // Load CSS
        var cssPath = Path.Combine(
            modguiFolder,
            modguiData["stylesheet"]
        );
        var css = await File.ReadAllTextAsync(cssPath);
        
        // Load JavaScript
        var jsPath = Path.Combine(
            modguiFolder,
            modguiData["javascript"]
        );
        var js = await File.ReadAllTextAsync(jsPath);
        
        return new PluginModgui
        {
            Brand = modguiData["brand"],
            Label = modguiData["label"],
            Model = modguiData["model"],
            IconTemplateHtml = html,
            StylesheetCss = css,
            JavascriptCode = js,
            ScreenshotPath = Path.Combine(modguiFolder, modguiData["screenshot"]),
            ThumbnailPath = Path.Combine(modguiFolder, modguiData["thumbnail"]),
            Ports = ParsePortMetadata(modguiData["port"])
        };
    }
}
```

### Integration with Pedalboard UI

```csharp
@* Blazor component that renders plugin using modgui *@
@implements IDisposable

<div id="effect-@EffectInstance.InstanceId" 
     class="effect-slot"
     @onmouseenter="@ShowConnections"
     @onmouseleave="@HideConnections">
    
    @* Render modgui HTML template *@
    @if (PluginInfo?.Modgui != null)
    {
        <div class="mod-pedal-container">
            @* Dynamically render the HTML with Mustache data *@
            <div @ref="ModguiContainer"></div>
            
            @* Inject CSS *@
            <style>@PluginInfo.Modgui.StylesheetCss</style>
            
            @* Inject JavaScript *@
            <script>@PluginInfo.Modgui.JavascriptCode</script>
        </div>
    }
    else
    {
        @* Fallback UI if no modgui available *@
        <div class="fallback-effect">
            <div class="effect-name">@PluginInfo.Name</div>
            <div class="effect-controls">
                @foreach (var port in PluginInfo.Ports.Where(p => p.IsControl))
                {
                    <div class="control">
                        <label>@port.Name</label>
                        <input type="range" 
                               min="@port.Min" 
                               max="@port.Max" 
                               value="@GetParameterValue(port.Symbol)"
                               @onchange="@((ChangeEventArgs e) => OnParameterChanged(port.Symbol, e.Value))" />
                    </div>
                }
            </div>
        </div>
    }
    
    @* Bypass toggle *@
    <div class="effect-bypass">
        <input type="checkbox" 
               checked="@EffectInstance.Enabled"
               @onchange="@OnBypassToggled" />
    </div>
    
    @* Remove button *@
    <button class="remove-effect" @onclick="@OnRemove">×</button>
    
    @* Port connectors (for signal routing) *@
    <div class="ports">
        @foreach (var port in PluginInfo.Ports.Where(p => p.IsAudio || p.IsMidi))
        {
            <div class="port @(port.IsInput ? "input" : "output")"
                 @ondragover:preventDefault 
                 @ondrop="@((DragEventArgs e) => OnPortDrop(port, e))"
                 title="@port.Name">
                @if (port.IsInput)
                {
                    <span class="port-label">@port.Name</span>
                }
                else
                {
                    <span class="port-label">@port.Name</span>
                }
            </div>
        }
    </div>
</div>

@code {
    [Parameter]
    public EffectInstance EffectInstance { get; set; }
    
    [Parameter]
    public Pedalboard Pedalboard { get; set; }
    
    [Inject]
    public ILv2PluginDiscoverer PluginDiscoverer { get; set; }
    
    [Inject]
    public IPedalboardService PedalboardService { get; set; }
    
    private PluginInfo PluginInfo { get; set; }
    private ElementReference ModguiContainer { get; set; }
    
    protected override async Task OnInitializedAsync()
    {
        // Load plugin metadata and modgui
        PluginInfo = await PluginDiscoverer.GetPluginAsync(
            EffectInstance.PluginUri
        );
    }
    
    private async Task OnParameterChanged(string paramName, object value)
    {
        await PedalboardService.SetEffectParameterAsync(
            Pedalboard.Id,
            EffectInstance.InstanceId,
            paramName,
            float.Parse(value.ToString())
        );
    }
    
    private async Task OnBypassToggled(ChangeEventArgs e)
    {
        EffectInstance.Enabled = (bool)e.Value;
        await PedalboardService.UpdateEffectAsync(
            Pedalboard.Id,
            EffectInstance
        );
    }
    
    private async Task OnRemove()
    {
        await PedalboardService.RemoveEffectAsync(
            Pedalboard.Id,
            EffectInstance.InstanceId
        );
    }
    
    private async Task OnPortDrop(PortInfo port, DragEventArgs e)
    {
        // Handle connection drag-and-drop
        // Create wire from source port to this port
    }
}
```

---

## Pluggable Audio Backend Architecture

### Problem: Hard-coded Audio Subsystem

Original architecture was tightly coupled to JACK:
```
mod-ui → mod-host → JACK → Audio Hardware
```

Limitations:
- ❌ No ALSA support (Linux)
- ❌ No ASIO support (Windows)
- ❌ No SoundFlow support
- ❌ No portability across platforms
- ❌ Required JACK installation and configuration

### Solution: Abstract Audio Backend

New architecture uses interface abstraction:

```csharp
// Core audio backend abstraction
public interface IAudioBackend
{
    string Name { get; }                    // "ALSA", "JACK", "ASIO", etc.
    
    // Lifecycle
    Task<bool> InitializeAsync();
    Task<bool> ShutdownAsync();
    bool IsRunning { get; }
    
    // Device management
    Task<IEnumerable<AudioDevice>> GetDevicesAsync();
    Task<bool> SetActiveDeviceAsync(string deviceName);
    
    // Plugin/Effect management
    Task<string> LoadEffectAsync(string pluginUri);      // Returns instance ID
    Task<bool> RemoveEffectAsync(string instanceId);
    Task<bool> SetEffectParameterAsync(string instanceId, string paramName, float value);
    Task<IEnumerable<float>> GetEffectParameterAsync(string instanceId, string paramName);
    
    // Connection management (flexible routing)
    Task<bool> ConnectPortsAsync(string fromPort, string toPort);
    Task<bool> DisconnectPortsAsync(string fromPort, string toPort);
    
    // Backend-specific controls (NEW)
    // E.g., ALSA mixer controls, JACK server settings, ASIO buffer size, etc.
    Task<IEnumerable<BackendControl>> GetAvailableControlsAsync();
    Task<BackendControlValue> GetControlValueAsync(string controlId);
    Task<bool> SetControlValueAsync(string controlId, BackendControlValue value);
    
    // Monitoring
    Task<SystemLoad> GetSystemLoadAsync();
    Task<float> GetLatencyAsync();
}
```

### Backend Controls: Audio Subsystem-Specific Settings

Each audio backend can expose its own controls via `GetAvailableControlsAsync()`. This allows the UI to dynamically display backend-specific settings without hardcoding them.

**Backend Control Data Structures:**

```csharp
/// <summary>
/// Represents a control exposed by an audio backend
/// ALSA example: Master Volume, Microphone Boost, Line In Level
/// JACK example: Buffer Size, Sample Rate
/// ASIO example: ASIO Buffer Size, Latency Compensation
/// </summary>
public class BackendControl
{
    public string Id { get; set; }                  // "alsa_master_volume"
    public string Label { get; set; }               // "Master Volume"
    public string Description { get; set; }         // "Main output level"
    public BackendControlType Type { get; set; }    // Slider, Toggle, Enum, etc.
    public bool IsReadOnly { get; set; }
    public bool IsHidden { get; set; }              // Hidden from UI but queryable
    
    // For slider/numeric controls
    public float? Min { get; set; }
    public float? Max { get; set; }
    public float? Step { get; set; }
    public string Unit { get; set; }                // "dB", "%", "ms", etc.
    
    // For enum/choice controls
    public List<ControlOption> Options { get; set; }
}

public enum BackendControlType
{
    Slider,                 // Numeric range with min/max
    Toggle,                 // Boolean on/off
    Enum,                   // Select from list of options
    Textbox                 // Free text input
}

public class ControlOption
{
    public string Value { get; set; }
    public string Label { get; set; }
    public string Description { get; set; }
}

public class BackendControlValue
{
    public string ControlId { get; set; }
    public object Value { get; set; }               // float, bool, string, int
    public DateTime Timestamp { get; set; }
}
```

**ALSA Backend Example:**

```csharp
public class AlsaAudioBackend : IAudioBackend
{
    public async Task<IEnumerable<BackendControl>> GetAvailableControlsAsync()
    {
        var controls = new List<BackendControl>();
        
        // Use 'amixer' to enumerate ALSA mixer controls
        // amixer scontrols | grep -E "Master|Microphone|Line|Capture"
        
        // Master Volume Control
        controls.Add(new BackendControl
        {
            Id = "alsa_master_volume",
            Label = "Master Volume",
            Description = "Main output level",
            Type = BackendControlType.Slider,
            Min = 0,
            Max = 100,
            Step = 1,
            Unit = "%"
        });
        
        // Microphone Boost (Toggle)
        controls.Add(new BackendControl
        {
            Id = "alsa_mic_boost",
            Label = "Microphone Boost",
            Description = "Enable microphone gain boost",
            Type = BackendControlType.Toggle,
            IsReadOnly = false
        });
        
        // Line In Level (Slider)
        controls.Add(new BackendControl
        {
            Id = "alsa_line_in_level",
            Label = "Line In Level",
            Description = "Input level from line in port",
            Type = BackendControlType.Slider,
            Min = 0,
            Max = 100,
            Step = 1,
            Unit = "%"
        });
        
        // Input Source Selection (Enum)
        controls.Add(new BackendControl
        {
            Id = "alsa_input_source",
            Label = "Input Source",
            Description = "Select microphone, line in, or aux input",
            Type = BackendControlType.Enum,
            Options = new List<ControlOption>
            {
                new ControlOption { Value = "mic", Label = "Microphone" },
                new ControlOption { Value = "line", Label = "Line In" },
                new ControlOption { Value = "aux", Label = "Aux Input" }
            }
        });
        
        return controls;
    }
    
    public async Task<BackendControlValue> GetControlValueAsync(string controlId)
    {
        // Use 'amixer cget' to read current value
        // amixer cget numid=1
        
        return controlId switch
        {
            "alsa_master_volume" => new BackendControlValue
            {
                ControlId = controlId,
                Value = 80.0f,  // Read from amixer output
                Timestamp = DateTime.UtcNow
            },
            "alsa_mic_boost" => new BackendControlValue
            {
                ControlId = controlId,
                Value = true,   // Read from amixer output
                Timestamp = DateTime.UtcNow
            },
            _ => throw new ArgumentException($"Unknown control: {controlId}")
        };
    }
    
    public async Task<bool> SetControlValueAsync(string controlId, BackendControlValue value)
    {
        // Use 'amixer cset' to set control value
        // amixer cset numid=1 -- 80
        
        var success = controlId switch
        {
            "alsa_master_volume" => 
                _alsaClient.SetMixerControl("Master", (float)value.Value),
            "alsa_mic_boost" => 
                _alsaClient.SetMixerControl("Mic Boost", (bool)value.Value),
            _ => false
        };
        
        return success;
    }
}
```

**JACK Backend Example:**

```csharp
public class JackAudioBackend : IAudioBackend
{
    public async Task<IEnumerable<BackendControl>> GetAvailableControlsAsync()
    {
        var controls = new List<BackendControl>
        {
            // JACK Server Buffer Size
            new BackendControl
            {
                Id = "jack_buffer_size",
                Label = "Buffer Size",
                Description = "JACK server buffer size in samples",
                Type = BackendControlType.Enum,
                IsReadOnly = true,  // Usually read-only while running
                Options = new List<ControlOption>
                {
                    new ControlOption { Value = "256", Label = "256 samples (5.3ms @ 48k)" },
                    new ControlOption { Value = "512", Label = "512 samples (10.7ms @ 48k)" },
                    new ControlOption { Value = "1024", Label = "1024 samples (21.3ms @ 48k)" }
                }
            },
            
            // JACK Sample Rate
            new BackendControl
            {
                Id = "jack_sample_rate",
                Label = "Sample Rate",
                Description = "JACK server sample rate",
                Type = BackendControlType.Enum,
                IsReadOnly = true,
                Options = new List<ControlOption>
                {
                    new ControlOption { Value = "44100", Label = "44.1 kHz" },
                    new ControlOption { Value = "48000", Label = "48 kHz" },
                    new ControlOption { Value = "96000", Label = "96 kHz" }
                }
            }
        };
        
        return controls;
    }
    
    public async Task<BackendControlValue> GetControlValueAsync(string controlId)
    {
        return controlId switch
        {
            "jack_buffer_size" => new BackendControlValue
            {
                ControlId = controlId,
                Value = _jackClient.GetBufferSize().ToString(),
                Timestamp = DateTime.UtcNow
            },
            "jack_sample_rate" => new BackendControlValue
            {
                ControlId = controlId,
                Value = _jackClient.GetSampleRate().ToString(),
                Timestamp = DateTime.UtcNow
            },
            _ => throw new ArgumentException($"Unknown control: {controlId}")
        };
    }
    
    public async Task<bool> SetControlValueAsync(string controlId, BackendControlValue value)
    {
        // Note: JACK server settings usually require server restart
        return await Task.FromResult(false);
    }
}
```

**ASIO Backend Example:**

```csharp
public class AsioAudioBackend : IAudioBackend
{
    public async Task<IEnumerable<BackendControl>> GetAvailableControlsAsync()
    {
        var controls = new List<BackendControl>
        {
            new BackendControl
            {
                Id = "asio_buffer_size",
                Label = "ASIO Buffer Size",
                Description = "ASIO driver buffer size in samples",
                Type = BackendControlType.Slider,
                Min = 64,
                Max = 2048,
                Step = 64
            },
            
            new BackendControl
            {
                Id = "asio_latency_compensation",
                Label = "Latency Compensation",
                Description = "Compensate for driver/hardware latency (ms)",
                Type = BackendControlType.Slider,
                Min = 0,
                Max = 100,
                Step = 1,
                Unit = "ms"
            }
        };
        
        return controls;
    }
    
    public async Task<BackendControlValue> GetControlValueAsync(string controlId)
    {
        return controlId switch
        {
            "asio_buffer_size" => new BackendControlValue
            {
                ControlId = controlId,
                Value = _asioDriver.GetBufferSize(),
                Timestamp = DateTime.UtcNow
            },
            _ => throw new ArgumentException($"Unknown control: {controlId}")
        };
    }
    
    public async Task<bool> SetControlValueAsync(string controlId, BackendControlValue value)
    {
        return controlId switch
        {
            "asio_buffer_size" => 
                _asioDriver.SetBufferSize((int)(float)value.Value),
            _ => false
        };
    }
}
```

**Mock Backend Example (for testing):**

```csharp
public class MockAudioBackend : IAudioBackend
{
    public async Task<IEnumerable<BackendControl>> GetAvailableControlsAsync()
    {
        return new List<BackendControl>
        {
            new BackendControl
            {
                Id = "mock_volume",
                Label = "Mock Volume",
                Type = BackendControlType.Slider,
                Min = 0,
                Max = 100,
                Step = 1
            }
        };
    }
    
    public async Task<BackendControlValue> GetControlValueAsync(string controlId)
    {
        return new BackendControlValue
        {
            ControlId = controlId,
            Value = _mockValues.TryGetValue(controlId, out var val) ? val : 50f,
            Timestamp = DateTime.UtcNow
        };
    }
    
    public async Task<bool> SetControlValueAsync(string controlId, BackendControlValue value)
    {
        _mockValues[controlId] = value.Value;
        return true;
    }
    
    private Dictionary<string, object> _mockValues = new();
}
```

### Implementation Pattern

Each audio subsystem implements `IAudioBackend`:

```
├── AlsaAudioBackend : IAudioBackend
│   ├── Device enumeration via ALSA APIs
│   ├── Plugin loading via LV2
│   └── Port connections via ALSA Jack
│
├── JackAudioBackend : IAudioBackend
│   ├── Device enumeration via JACK
│   ├── Plugin loading via LV2
│   └── Port connections via JACK
│
├── AsioAudioBackend : IAudioBackend
│   ├── Device enumeration via ASIO
│   ├── Plugin loading via VST/LV2
│   └── Port connections via ASIO
│
├── SoundFlowAudioBackend : IAudioBackend
│   ├── Device enumeration via SoundFlow API
│   ├── Plugin loading via SoundFlow plugins
│   └── Port connections via SoundFlow routing
│
└── MockAudioBackend : IAudioBackend
    ├── In-memory device list
    ├── In-memory effect library
    └── In-memory port connections
```

### Configuration-Based Selection

```csharp
// Startup configuration
public void ConfigureAudioBackend(WebApplicationBuilder builder)
{
    var audioBackend = builder.Configuration["AudioBackend"] ?? "ALSA";
    
    // Register implementation based on configuration
    builder.Services.AddSingleton<IAudioBackend>(provider =>
    {
        var logger = provider.GetRequiredService<ILog<AudioBackendFactory>>();
        
        return audioBackend switch
        {
            "JACK" => new JackAudioBackend(logger),
            "ASIO" => new AsioAudioBackend(logger),
            "SoundFlow" => new SoundFlowAudioBackend(logger),
            "Mock" => new MockAudioBackend(logger),
            _ => new AlsaAudioBackend(logger)
        };
    });
}
```

### Environment Configuration

```bash
# appsettings.Production.json
{
  "AudioBackend": "ALSA",
  "AudioBackendConfig": {
    "DeviceName": "default",
    "BufferSize": 256,
    "SampleRate": 48000
  }
}

# appsettings.Development.json
{
  "AudioBackend": "Mock",
  "AudioBackendConfig": {
    "DeviceName": "Mock Device",
    "BufferSize": 256,
    "SampleRate": 48000
  }
}

# appsettings.Docker.json
{
  "AudioBackend": "Mock",
  "AudioBackendConfig": {
    "UseMockDevices": true,
    "UseMockPlugins": true
  }
}
```

### Pedalboard Audio Backend Selection

Users can choose which audio backend to use when creating a pedalboard:

```csharp
public class CreatePedalboardRequest
{
    public string Name { get; set; }
    public string AudioBackend { get; set; }  // "ALSA", "JACK", "ASIO", etc.
    public string InputDevice { get; set; }
    public string OutputDevice { get; set; }
    public int SampleRate { get; set; }
}

// API Endpoint
[HttpPost("pedalboards")]
`

### Problem: Hard-coded Audio Subsystem

Original architecture was tightly coupled to JACK:
```
mod-ui → mod-host → JACK → Audio Hardware
```

Limitations:
- ❌ No ALSA support (Linux)
- ❌ No ASIO support (Windows)
- ❌ No SoundFlow support
- ❌ No portability across platforms
- ❌ Required JACK installation and configuration

### Solution: Abstract Audio Backend

New architecture uses interface abstraction:

```csharp
// Core audio backend abstraction
public interface IAudioBackend
{
    string Name { get; }                    // "ALSA", "JACK", "ASIO", etc.
    
    // Lifecycle
    Task<bool> InitializeAsync();
    Task<bool> ShutdownAsync();
    bool IsRunning { get; }
    
    // Device management
    Task<IEnumerable<AudioDevice>> GetDevicesAsync();
    Task<bool> SetActiveDeviceAsync(string deviceName);
    
    // Plugin/Effect management
    Task<string> LoadEffectAsync(string pluginUri);      // Returns instance ID
    Task<bool> RemoveEffectAsync(string instanceId);
    Task<bool> SetEffectParameterAsync(string instanceId, string paramName, float value);
    Task<IEnumerable<float>> GetEffectParameterAsync(string instanceId, string paramName);
    
    // Connection management
    Task<bool> ConnectPortsAsync(string fromPort, string toPort);
    Task<bool> DisconnectPortsAsync(string fromPort, string toPort);
    
    // Monitoring
    Task<SystemLoad> GetSystemLoadAsync();
    Task<float> GetLatencyAsync();
}
```

### Implementation Pattern

Each audio subsystem implements `IAudioBackend`:

```
├── AlsaAudioBackend : IAudioBackend
│   ├── Device enumeration via ALSA APIs
│   ├── Plugin loading via LV2
│   └── Port connections via ALSA Jack
│
├── JackAudioBackend : IAudioBackend
│   ├── Device enumeration via JACK
│   ├── Plugin loading via LV2
│   └── Port connections via JACK
│
├── AsioAudioBackend : IAudioBackend
│   ├── Device enumeration via ASIO
│   ├── Plugin loading via VST/LV2
│   └── Port connections via ASIO
│
├── SoundFlowAudioBackend : IAudioBackend
│   ├── Device enumeration via SoundFlow API
│   ├── Plugin loading via SoundFlow plugins
│   └── Port connections via SoundFlow routing
│
└── MockAudioBackend : IAudioBackend
    ├── In-memory device list
    ├── In-memory effect library
    └── In-memory port connections
```

### Configuration-Based Selection

```csharp
// Startup configuration
public void ConfigureAudioBackend(WebApplicationBuilder builder)
{
    var audioBackend = builder.Configuration["AudioBackend"] ?? "ALSA";
    
    // Register implementation based on configuration
    builder.Services.AddSingleton<IAudioBackend>(provider =>
    {
        var logger = provider.GetRequiredService<ILog<AudioBackendFactory>>();
        
        return audioBackend switch
        {
            "JACK" => new JackAudioBackend(logger),
            "ASIO" => new AsioAudioBackend(logger),
            "SoundFlow" => new SoundFlowAudioBackend(logger),
            "Mock" => new MockAudioBackend(logger),
            _ => new AlsaAudioBackend(logger)
        };
    });
}
```

### Environment Configuration

```bash
# appsettings.Production.json
{
  "AudioBackend": "ALSA",
  "AudioBackendConfig": {
    "DeviceName": "default",
    "BufferSize": 256,
    "SampleRate": 48000
  }
}

# appsettings.Development.json
{
  "AudioBackend": "Mock",
  "AudioBackendConfig": {
    "DeviceName": "Mock Device",
    "BufferSize": 256,
    "SampleRate": 48000
  }
}

# appsettings.Docker.json
{
  "AudioBackend": "Mock",
  "AudioBackendConfig": {
    "UseMockDevices": true,
    "UseMockPlugins": true
  }
}
```

### Pedalboard Audio Backend Selection

Users can choose which audio backend to use when creating a pedalboard:

```csharp
public class CreatePedalboardRequest
{
    public string Name { get; set; }
    public string AudioBackend { get; set; }  // "ALSA", "JACK", "ASIO", etc.
    public string InputDevice { get; set; }
    public string OutputDevice { get; set; }
    public int SampleRate { get; set; }
}

// API Endpoint
[HttpPost("pedalboards")]
public async Task<IActionResult> CreatePedalboard(CreatePedalboardRequest request)
{
    // Validate selected backend is available
    var availableBackends = await GetAvailableAudioBackends();
    if (!availableBackends.Any(b => b.Name == request.AudioBackend))
    {
        return BadRequest(new { error = "Audio backend not available" });
    }
    
    // Create pedalboard with selected backend
    var pedalboard = await PedalboardService.CreateAsync(request);
    return Created($"/api/pedalboards/{pedalboard.Id}", pedalboard);
}
```

---

## Pedalboard API Endpoints

### Pedalboard Management

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/pedalboards` | List all pedalboards |
| POST | `/api/pedalboards` | Create new pedalboard |
| GET | `/api/pedalboards/{id}` | Get pedalboard details |
| PUT | `/api/pedalboards/{id}` | Update pedalboard (name, description) |
| DELETE | `/api/pedalboards/{id}` | Delete pedalboard |
| POST | `/api/pedalboards/{id}/duplicate` | Duplicate pedalboard |

### Effect Chain Management

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/api/pedalboards/{id}/effects` | Add effect to pedalboard |
| DELETE | `/api/pedalboards/{id}/effects/{instanceId}` | Remove effect from pedalboard |
| PUT | `/api/pedalboards/{id}/effects/{instanceId}` | Update effect (bypass, preset, etc.) |
| PUT | `/api/pedalboards/{id}/effects/{instanceId}/parameters/{paramName}` | Set effect parameter value |
| GET | `/api/pedalboards/{id}/effects/{instanceId}/parameters` | Get all effect parameters |

### Flexible Signal Routing (Port Connections)

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/api/pedalboards/{id}/connections` | Create connection (wire) between ports |
| DELETE | `/api/pedalboards/{id}/connections/{connectionId}` | Remove connection |
| GET | `/api/pedalboards/{id}/connections` | List all connections in pedalboard |

**Connection Examples:**
- `"ALSA:in_0" → "reverb-1:audio_in"` - Input to plugin
- `"reverb-1:audio_out" → "compressor-1:audio_in"` - Plugin to plugin
- `"compressor-1:audio_out" → "ALSA:out_0"` - Plugin to output
- `"ALSA:in_0" → "ALSA:out_0"` - Bypass (input directly to output)

### Pedalboard Operations

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/api/pedalboards/{id}/load` | Activate pedalboard |
| POST | `/api/pedalboards/{id}/save` | Save current state |
| POST | `/api/pedalboards/{id}/export` | Export as file |
| POST | `/api/pedalboards/{id}/import` | Import from file |
| GET | `/api/pedalboards/{id}/snapshot` | Get current state |
| POST | `/api/pedalboards/{id}/snapshot` | Save as snapshot |

### Audio Backend Selection

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/audio/backends` | List available backends |
| GET | `/api/audio/backends/{name}` | Get backend details |
| POST | `/api/audio/backends/{name}/test` | Test backend connection |

### Port Signal Level Monitoring (dBFS Display)

| Method | Path | Purpose |
|--------|------|---------|  
| GET | `/api/ports/{portName}/level` | Get current dBFS level of port |
| WebSocket | `/ws/port-levels` | Stream dBFS levels for multiple ports |

**Example: Real-time Port Level**

```bash
# Get instantaneous dBFS level for a specific port
GET /api/ports/ALSA%3Ain_L/level

Response:
{
  "portName": "ALSA:in_L",
  "dbfs": -18.5,
  "peakDbfs": -12.0,
  "timestamp": "2026-01-06T10:30:00.123Z"
}
```

**WebSocket Stream (for real-time UI updates):**

```javascript
// Subscribe to port level updates
const socket = new WebSocket('ws://localhost:5000/ws/port-levels');

socket.send(JSON.stringify({
  type: 'subscribe',
  ports: ['ALSA:in_L', 'ALSA:in_R', 'reverb-1:audio_out_L', 'reverb-1:audio_out_R']
}));

socket.onmessage = (event) => {
  const update = JSON.parse(event.data);
  // update = { portName: "ALSA:in_L", dbfs: -18.5, peakDbfs: -12.0 }
  updatePortLevelUI(update.portName, update.dbfs, update.peakDbfs);
};
```

### Backend Controls (Audio Subsystem-Specific Settings)

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/audio/backends/{name}/controls` | Get available controls for backend |
| GET | `/api/audio/backends/{name}/controls/{controlId}` | Get control current value |
| PUT | `/api/audio/backends/{name}/controls/{controlId}` | Set control value |

**Example: ALSA Backend Controls**

```bash
# Get available ALSA controls
GET /api/audio/backends/ALSA/controls

Response:
{
  "controls": [
    {
      "id": "alsa_master_volume",
      "label": "Master Volume",
      "description": "Main output level",
      "type": "Slider",
      "min": 0,
      "max": 100,
      "step": 1,
      "unit": "%"
    },
    {
      "id": "alsa_mic_boost",
      "label": "Microphone Boost",
      "description": "Enable microphone gain boost",
      "type": "Toggle"
    },
    {
      "id": "alsa_input_source",
      "label": "Input Source",
      "type": "Enum",
      "options": [
        { "value": "mic", "label": "Microphone" },
        { "value": "line", "label": "Line In" },
        { "value": "aux", "label": "Aux Input" }
      ]
    }
  ]
}
```

```bash
# Get current value of a control
GET /api/audio/backends/ALSA/controls/alsa_master_volume

Response:
{
  "controlId": "alsa_master_volume",
  "value": 80.0,
  "timestamp": "2026-01-06T10:30:00Z"
}
```

```bash
# Set control value
PUT /api/audio/backends/ALSA/controls/alsa_master_volume
Body:
{
  "value": 75.0
}

Response:
{
  "success": true,
  "newValue": 75.0
}
```

---

## UI Components: Backend Controls & Signal Monitoring

### 1. BackendControlsPanel Component

Dynamically renders controls based on available backend.

```csharp
// Blazor component that renders backend-specific controls
[Component]
public partial class BackendControlsPanel
{
    [Parameter]
    public string AudioBackendName { get; set; }  // "ALSA", "JACK", "ASIO"
    
    [Inject]
    public IBackendControlService BackendService { get; set; }
    
    private List<BackendControl> AvailableControls { get; set; } = new();
    private Dictionary<string, object> ControlValues { get; set; } = new();
    
    protected override async Task OnInitializedAsync()
    {
        // Load available controls for current backend
        AvailableControls = (await BackendService.GetAvailableControlsAsync(
            AudioBackendName
        )).ToList();
        
        // Load current values for each control
        foreach (var control in AvailableControls)
        {
            var value = await BackendService.GetControlValueAsync(
                AudioBackendName,
                control.Id
            );
            ControlValues[control.Id] = value.Value;
        }
    }
    
    private async Task OnControlChanged(string controlId, object newValue)
    {
        ControlValues[controlId] = newValue;
        
        // Send to backend
        var result = await BackendService.SetControlValueAsync(
            AudioBackendName,
            controlId,
            newValue
        );
        
        if (!result)
        {
            // Revert to previous value on failure
            var value = await BackendService.GetControlValueAsync(
                AudioBackendName,
                controlId
            );
            ControlValues[controlId] = value.Value;
        }
    }
}
```

```html
@* Blazor markup for backend controls panel *@
<div class="backend-controls-panel">
    <h3>@AudioBackendName Audio Controls</h3>
    
    <div class="controls-grid">
        @foreach (var control in AvailableControls.Where(c => !c.IsHidden))
        {
            <div class="control-item" key="@control.Id">
                <label>@control.Label</label>
                <small class="description">@control.Description</small>
                
                @if (control.Type == BackendControlType.Slider)
                {
                    <div class="slider-control">
                        <input type="range" 
                               min="@control.Min" 
                               max="@control.Max" 
                               step="@control.Step"
                               value="@ControlValues[control.Id]"
                               @onchange="@((ChangeEventArgs e) => OnControlChanged(control.Id, e.Value))"
                               disabled="@control.IsReadOnly" />
                        <span class="value">@ControlValues[control.Id]@control.Unit</span>
                    </div>
                }
                else if (control.Type == BackendControlType.Toggle)
                {
                    <div class="toggle-control">
                        <input type="checkbox" 
                               checked="@((bool)ControlValues[control.Id])"
                               @onchange="@((ChangeEventArgs e) => OnControlChanged(control.Id, e.Value))"
                               disabled="@control.IsReadOnly" />
                    </div>
                }
                else if (control.Type == BackendControlType.Enum)
                {
                    <div class="enum-control">
                        <select @onchange="@((ChangeEventArgs e) => OnControlChanged(control.Id, e.Value))"
                                disabled="@control.IsReadOnly">
                            @foreach (var option in control.Options)
                            {
                                <option value="@option.Value" 
                                        selected="@(ControlValues[control.Id]?.ToString() == option.Value)">
                                    @option.Label
                                </option>
                            }
                        </select>
                    </div>
                }
            </div>
        }
    </div>
</div>
```

### 2. PortLevelMonitor Component

Displays dBFS levels on port hover with real-time updates via WebSocket.

```csharp
[Component]
public partial class PortLevelMonitor
{
    [Parameter]
    public string PortName { get; set; }  // "ALSA:in_L"
    
    [Parameter]
    public PortInfo PortInfo { get; set; }
    
    [Inject]
    public IPortLevelService PortLevelService { get; set; }
    
    private float CurrentDbfs { get; set; } = float.MinValue;
    private float PeakDbfs { get; set; } = float.MinValue;
    private bool IsHovering { get; set; }
    private IAsyncDisposable LevelSubscription { get; set; }
    
    protected override async Task OnInitializedAsync()
    {
        // Subscribe to port level updates when component loads
        LevelSubscription = await PortLevelService.SubscribeToPortLevelAsync(
            PortName,
            OnPortLevelUpdated
        );
    }
    
    private void OnPortLevelUpdated(PortLevelUpdate update)
    {
        CurrentDbfs = update.DbFs;
        PeakDbfs = update.PeakDbFs;
        StateHasChanged();
    }
    
    private void OnMouseEnter()
    {
        IsHovering = true;
    }
    
    private void OnMouseLeave()
    {
        IsHovering = false;
    }
    
    private string GetMeterStyle()
    {
        // Convert dBFS (-∞ to 0) to percentage (0-100)
        // Typical range: -60 dBFS to 0 dBFS
        if (CurrentDbfs <= float.MinValue) return "width: 0%";
        
        var normalized = (CurrentDbfs + 60) / 60;
        var percentage = Math.Max(0, Math.Min(100, normalized * 100));
        
        var color = normalized > 0.95 ? "#ff4444" :
                    normalized > 0.80 ? "#ffaa00" :
                    "#00dd00";
        
        return $"width: {percentage}%; background-color: {color};";
    }
    
    private string FormatDbFS(float dbfs)
    {
        return dbfs <= float.MinValue ? "-∞" : dbfs.ToString("F1");
    }
    
    async ValueTask IAsyncDisposable.DisposeAsync()
    {
        if (LevelSubscription is not null)
            await LevelSubscription.DisposeAsync();
    }
}
```

```html
@* Visual port with level indicator on hover *@
<div class="port @PortInfo.Direction" 
     @onmouseenter="@OnMouseEnter"
     @onmouseleave="@OnMouseLeave"
     title="@PortInfo.Name">
    
    <span class="port-label">@PortInfo.Name</span>
    
    @if (IsHovering)
    {
        <div class="port-level-overlay">
            <div class="level-meter">
                <div class="meter-bar" style="@GetMeterStyle()"></div>
            </div>
            <span class="level-text">
                @FormatDbFS(CurrentDbfs) dBFS
                <span class="peak">peak: @FormatDbFS(PeakDbfs)</span>
            </span>
        </div>
    }
</div>
```

### 3. Supporting Service Interfaces

```csharp
public class PortLevelUpdate
{
    public string PortName { get; set; }
    public float DbFs { get; set; }         // Range: -∞ to 0
    public float PeakDbFs { get; set; }
    public DateTime Timestamp { get; set; }
}

public interface IPortLevelService
{
    // Get instantaneous level
    Task<PortLevelUpdate> GetPortLevelAsync(string portName);
    
    // Subscribe to real-time level updates via WebSocket
    Task<IAsyncDisposable> SubscribeToPortLevelAsync(
        string portName,
        Action<PortLevelUpdate> onUpdate
    );
    
    // Subscribe to multiple ports (efficient batch)
    Task<IAsyncDisposable> SubscribeToPortLevelsAsync(
        IEnumerable<string> portNames,
        Action<IEnumerable<PortLevelUpdate>> onUpdate
    );
}

public interface IBackendControlService
{
    Task<IEnumerable<BackendControl>> GetAvailableControlsAsync(string backendName);
    Task<BackendControlValue> GetControlValueAsync(string backendName, string controlId);
    Task<bool> SetControlValueAsync(string backendName, string controlId, object value);
}
```

### 4. Integration Examples

**Input Source with Level Display:**

```html
@* Input device selector with real-time level monitoring *@
<div class="io-source">
    <h4>Input Source</h4>
    <select @onchange="@OnInputDeviceChanged">
        @foreach (var device in AvailableInputDevices)
        {
            <option value="@device.Name">@device.Label</option>
        }
    </select>
    
    <div class="ports">
        @foreach (var port in CurrentInputPorts)
        {
            <PortLevelMonitor PortName="@port.Name" PortInfo="@port" />
        }
    </div>
</div>
```

**Effect Slot with Port Level Monitoring:**

```html
@* Effect with port-level display on hover *@
<div class="effect-slot">
    @* ... modgui UI ... *@
    
    <div class="ports-container">
        <div class="input-ports">
            @foreach (var port in EffectInfo.InputPorts)
            {
                <PortLevelMonitor PortName="@(EffectInstance.InstanceId + \":\" + port.Symbol)" 
                                  PortInfo="@port" />
            }
        </div>
        
        <div class="output-ports">
            @foreach (var port in EffectInfo.OutputPorts)
            {
                <PortLevelMonitor PortName="@(EffectInstance.InstanceId + \":\" + port.Symbol)" 
                                  PortInfo="@port" />
            }
        </div>
    </div>
</div>
```

---

## Backend Controls UI Component

### BackendControlsPanel Component

```csharp
// Blazor component that renders backend-specific controls
[Component]
public partial class BackendControlsPanel
{
    [Parameter]
    public string AudioBackendName { get; set; }
    
    [Inject]
    public HttpClient HttpClient { get; set; }
    
    [Inject]
    public ILog<BackendControlsPanel> Logger { get; set; }
    
    private List<BackendControl> AvailableControls { get; set; } = new();
    private Dictionary<string, BackendControlValue> ControlValues { get; set; } = new();
    private bool IsLoading { get; set; } = true;
    private string ErrorMessage { get; set; }
    
    protected override async Task OnInitializedAsync()
    {
        await LoadControlsAsync();
    }
    
    private async Task LoadControlsAsync()
    {
        try
        {
            IsLoading = true;
            ErrorMessage = null;
            
            // Fetch available controls from backend
            var response = await HttpClient.GetAsync(
                $"/api/audio/backends/{AudioBackendName}/controls"
            );
            
            if (response.IsSuccessStatusCode)
            {
                var json = await response.Content.ReadAsStringAsync();
                var data = JsonSerializer.Deserialize<ControlsResponse>(json);
                AvailableControls = data.Controls;
                
                // Load current values for each control
                foreach (var control in AvailableControls)
                {
                    if (!control.IsHidden)
                    {
                        var value = await GetControlValueAsync(control.Id);
                        if (value != null)
                        {
                            ControlValues[control.Id] = value;
                        }
                    }
                }
            }
            else
            {
                ErrorMessage = "Failed to load backend controls";
            }
        }
        catch (Exception ex)
        {
            Logger.Error($"Error loading backend controls: {ex.Message}");
            ErrorMessage = "Error loading controls";
        }
        finally
        {
            IsLoading = false;
        }
    }
    
    private async Task<BackendControlValue> GetControlValueAsync(string controlId)
    {
        var response = await HttpClient.GetAsync(
            $"/api/audio/backends/{AudioBackendName}/controls/{controlId}"
        );
        
        if (response.IsSuccessStatusCode)
        {
            var json = await response.Content.ReadAsStringAsync();
            return JsonSerializer.Deserialize<BackendControlValue>(json);
        }
        
        return null;
    }
    
    private async Task OnControlValueChanged(BackendControl control, object newValue)
    {
        try
        {
            var controlValue = new BackendControlValue
            {
                ControlId = control.Id,
                Value = newValue,
                Timestamp = DateTime.UtcNow
            };
            
            // Send update to backend
            var request = new HttpRequestMessage(
                HttpMethod.Put,
                $"/api/audio/backends/{AudioBackendName}/controls/{control.Id}"
            )
            {
                Content = new StringContent(
                    JsonSerializer.Serialize(controlValue),
                    Encoding.UTF8,
                    "application/json"
                )
            };
            
            var response = await HttpClient.SendAsync(request);
            
            if (response.IsSuccessStatusCode)
            {
                ControlValues[control.Id] = controlValue;
                Logger.Info($"Updated {control.Label} to {newValue}");
            }
            else
            {
                ErrorMessage = $"Failed to update {control.Label}";
            }
        }
        catch (Exception ex)
        {
            Logger.Error($"Error updating control: {ex.Message}");
            ErrorMessage = "Error updating control";
        }
    }
}
```

### HTML/Razor Markup for Backend Controls

```html
@if (IsLoading)
{
    <div class="loading">Loading backend controls...</div>
}
else if (!string.IsNullOrEmpty(ErrorMessage))
{
    <div class="alert alert-danger">@ErrorMessage</div>
}
else if (AvailableControls.Any())
{
    <div class="backend-controls-panel">
        <h3>@AudioBackendName Controls</h3>
        
        @foreach (var control in AvailableControls.Where(c => !c.IsHidden))
        {
            <div class="control-group">
                <label>@control.Label</label>
                <small>@control.Description</small>
                
                @switch (control.Type)
                {
                    case BackendControlType.Slider:
                        <input type="range"
                               min="@control.Min"
                               max="@control.Max"
                               step="@control.Step"
                               value="@(ControlValues.TryGetValue(control.Id, out var val) ? val.Value : control.Min)"
                               disabled="@control.IsReadOnly"
                               @onchange="@((ChangeEventArgs e) => OnControlValueChanged(control, float.Parse(e.Value.ToString())))" />
                        <span class="control-value">
                            @(ControlValues.TryGetValue(control.Id, out var sliderVal) ? sliderVal.Value : control.Min)
                            @control.Unit
                        </span>
                        break;
                    
                    case BackendControlType.Toggle:
                        <input type="checkbox"
                               checked="@(ControlValues.TryGetValue(control.Id, out var toggleVal) && (bool)toggleVal.Value)"
                               disabled="@control.IsReadOnly"
                               @onchange="@((ChangeEventArgs e) => OnControlValueChanged(control, (bool)e.Value))" />
                        break;
                    
                    case BackendControlType.Enum:
                        <select disabled="@control.IsReadOnly"
                                @onchange="@((ChangeEventArgs e) => OnControlValueChanged(control, e.Value.ToString()))">
                            @foreach (var option in control.Options)
                            {
                                <option value="@option.Value"
                                        selected="@(ControlValues.TryGetValue(control.Id, out var enumVal) && enumVal.Value.ToString() == option.Value)">
                                    @option.Label
                                </option>
                            }
                        </select>
                        break;
                    
                    case BackendControlType.Textbox:
                        <input type="text"
                               value="@(ControlValues.TryGetValue(control.Id, out var textVal) ? textVal.Value : "")"
                               disabled="@control.IsReadOnly"
                               @onchange="@((ChangeEventArgs e) => OnControlValueChanged(control, e.Value.ToString()))" />
                        break;
                }
            </div>
        }
    </div>
}
else
{
    <p>No backend-specific controls available for @AudioBackendName</p>
}

<style>
.backend-controls-panel {
    border: 1px solid #ddd;
    padding: 15px;
    border-radius: 5px;
    margin: 20px 0;
    background: #f9f9f9;
}

.control-group {
    margin-bottom: 15px;
    padding: 10px;
    border-radius: 3px;
    background: white;
}

.control-group label {
    display: block;
    font-weight: bold;
    margin-bottom: 5px;
}

.control-group small {
    display: block;
    color: #666;
    font-size: 12px;
    margin-bottom: 10px;
}

.control-group input[type="range"] {
    width: 200px;
    vertical-align: middle;
}

.control-group select,
.control-group input[type="text"] {
    padding: 5px;
    border: 1px solid #ccc;
    border-radius: 3px;
    min-width: 200px;
}

.control-value {
    display: inline-block;
    margin-left: 10px;
    font-weight: bold;
    min-width: 80px;
}

.control-group input:disabled,
.control-group select:disabled {
    background: #f0f0f0;
    cursor: not-allowed;
    opacity: 0.7;
}
</style>
```

### Integration with Pedalboard Page

```csharp
// In PedalboardPage.razor component
<div class="pedalboard-container">
    <div class="pedalboard-header">
        <h1>Pedalboard: @Pedalboard.Name</h1>
        <p>Backend: @Pedalboard.AudioBackend</p>
    </div>
    
    @* Show backend controls if ALSA or other backend with controls *@
    <BackendControlsPanel AudioBackendName="@Pedalboard.AudioBackend" />
    
    @* Main pedalboard effects rack *@
    <EffectsRack Pedalboard="@Pedalboard" />
    
    @* Available effects panel *@
    <AvailableEffectsPanel />
</div>
```

---

## Real-Time Updates via WebSocket

For interactive pedalboard editing, use WebSocket for real-time updates:

```csharp
[Component]
public partial class PedalboardPage
{
    private HubConnection _hubConnection;
    
    protected override async Task OnInitializedAsync()
    {
        _hubConnection = new HubConnectionBuilder()
            .WithUrl("http://localhost:5000/pedalboard-hub")
            .WithAutomaticReconnect()
            .Build();
        
        _hubConnection.On<string, float>("ParameterChanged", 
            async (param, value) =>
        {
            // Update UI when parameter changes from another client
            await RefreshEffectDisplayAsync();
        });
        
        _hubConnection.On<string>("EffectAdded", async (effectId) =>
        {
            // Update UI when effect added
            await RefreshAsync();
        });
        
        await _hubConnection.StartAsync();
    }
}
```

### WebSocket Messages

```csharp
// Server sends to all connected clients
{
    "type": "ParameterChanged",
    "instanceId": "reverb-1",
    "parameterName": "dryWet",
    "value": 0.75
}

{
    "type": "EffectAdded",
    "instanceId": "compressor-2",
    "pluginUri": "http://example.com/compressor"
}

{
    "type": "EffectRemoved",
    "instanceId": "reverb-1"
}

{
    "type": "EffectReordered",
    "instanceId": "compressor-1",
    "newPosition": 0
}

{
    "type": "SystemLoad",
    "cpuUsage": 45.2,
    "latency": 5.2
}
```

---

## Testing Strategy for Audio Backend

### Unit Tests - Backend Interface

```csharp
[Trait("Category", "Unit")]
public class MockAudioBackendTests
{
    private MockAudioBackend _backend;
    
    [Fact]
    public async Task Initialize_WithValidConfig_Succeeds()
    {
        // Arrange
        _backend = new MockAudioBackend(_logger);
        
        // Act
        var result = await _backend.InitializeAsync();
        
        // Assert
        Assert.True(result);
        Assert.True(_backend.IsRunning);
    }
    
    [Fact]
    public async Task LoadEffect_ReturnsUniqueInstanceId()
    {
        // Arrange
        await _backend.InitializeAsync();
        
        // Act
        var id1 = await _backend.LoadEffectAsync("reverb-uri");
        var id2 = await _backend.LoadEffectAsync("reverb-uri");
        
        // Assert
        Assert.NotEqual(id1, id2);
    }
}
```

### Integration Tests - Multiple Backends

```csharp
[Trait("Category", "Integration")]
public class AudioBackendIntegrationTests
{
    [Theory]
    [InlineData("ALSA")]
    [InlineData("JACK")]
    [InlineData("Mock")]
    public async Task AllBackends_SupportDeviceEnumeration(string backendName)
    {
        // Arrange
        var backend = GetAudioBackend(backendName);
        
        // Act
        var devices = await backend.GetDevicesAsync();
        
        // Assert
        Assert.NotNull(devices);
    }
}
```

### E2E Tests - Pedalboard Workflow

```csharp
[Trait("Category", "E2E")]
public class PedalboardWorkflowTests : IAsyncLifetime
{
    private IPage _page;
    
    [Fact]
    public async Task UserCanCreateAndEditPedalboard()
    {
        // Navigate to pedalboard creation
        await _page.GoToAsync("http://localhost:3000/pedalboards/new");
        
        // Select audio backend
        await _page.SelectOptionAsync("select#audio-backend", "ALSA");
        
        // Create pedalboard
        await _page.ClickAsync("button#create");
        await _page.WaitForLoadStateAsync(LoadState.NetworkIdle);
        
        // Add effect
        await _page.DragAndDropAsync(
            "#available-reverb",
            "#effects-rack"
        );
        
        // Verify effect appears
        var effectElement = await _page.QuerySelectorAsync("[data-instance-id]");
        Assert.NotNull(effectElement);
    }
}
```

---

## Migration Path: ALSA → Other Backends

### Phase 1: ALSA Primary (Current)
```
✅ AlsaAudioBackend (production ready)
✅ MockAudioBackend (for testing)
⏳ Other backends as future enhancements
```

### Phase 2: JACK Support (Future)
```
ADD: JackAudioBackend
- Implements IAudioBackend
- JACK socket communication
- Configuration for JACK server connection
```

### Phase 3: ASIO Support (Future)
```
ADD: AsioAudioBackend
- Implements IAudioBackend
- Windows ASIO APIs
- Configuration for ASIO device selection
```

### Phase 4: SoundFlow Support (Future)
```
ADD: SoundFlowAudioBackend
- Implements IAudioBackend
- SoundFlow API integration
- Configuration for SoundFlow endpoints
```

---

## Related Documentation

- [Components by Layer](04-COMPONENTS-BY-LAYER.md) - Service layer integration
- [Testing Strategy](05-TESTING-STRATEGY.md) - Testing multiple backends
- [Docker & Deployment](07-DOCKER-AND-DEPLOYMENT.md) - Backend configuration per environment
- [API Reference](08-API-REFERENCE.md) - Updated pedalboard endpoints
