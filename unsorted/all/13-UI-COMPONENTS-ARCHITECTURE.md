# UI Components Architecture

## Overview

This document describes the comprehensive UI component architecture for the Alsionyx pedalboard editor, implementing a professional, user-friendly audio workflow interface.

## Component Hierarchy

```
PedalboardEditor (Main Page)
├── AvailableEffectsPanel (Left Column - 320px)
│   ├── Search Bar
│   ├── Category Tabs
│   └── Plugin Cards
├── EffectsRack (Center Column - Flexible)
│   ├── System Stats (CPU, Latency)
│   ├── Signal Flow Indicators
│   └── EffectSlot[] (Each Effect)
│       ├── Position Badge
│       ├── Bypass Toggle
│       ├── KnobControl[] (Parameters)
│       └── Remove Button
└── BackendControlsPanel (Right Column - 320px)
    ├── Backend Controls
    ├── Refresh/Reset Actions
    └── Connection Viewer
```

## Core Components

### 1. PedalboardEditor (`Pages/PedalboardEditor.razor`)

**Purpose**: Main editing interface for audio pedalboards with comprehensive controls

**Features**:
- 3-column responsive grid layout (320px | 1fr | 320px)
- Real-time pedalboard state management
- Start/Stop controls with backend validation
- CPU and latency monitoring
- Save functionality
- Error/success notifications

**Route**: `/pedalboards/{PedalboardId}/edit`

**Key Capabilities**:
- Load existing pedalboards from API
- Add effects from available plugins
- Remove effects from signal chain
- Adjust effect parameters in real-time
- Toggle effect bypass
- Monitor system performance

**State Management**:
```csharp
private PedalboardDto? pedalboard;
private bool isRunning;
private SystemStatsDto systemStats;
private string? errorMessage;
private string? successMessage;
```

### 2. EffectsRack (`Components/EffectsRack.razor`)

**Purpose**: Visual representation of the audio signal chain

**Features**:
- Sequential effect display (Input → Effects → Output)
- Signal flow visualization with green arrows
- CPU load bars and latency display
- Add/Clear/Remove controls
- Dark gradient background (#2a2a2a to #1a1a1a)

**Parameters**:
```csharp
[Parameter] public List<PluginInstanceDto> Effects { get; set; }
[Parameter] public EventCallback<string> OnAddEffect { get; set; }
[Parameter] public EventCallback<string> OnRemoveEffect { get; set; }
[Parameter] public EventCallback<(string InstanceId, string Parameter, float Value)> OnParameterChange { get; set; }
[Parameter] public bool IsReadOnly { get; set; }
```

**Visual Design**:
- Dark theme with professional rack aesthetic
- Green signal flow indicators (#4CAF50)
- CPU load bars (green/yellow/red based on threshold)
- Latency display with warning indicators

### 3. EffectSlot (`Components/EffectSlot.razor`)

**Purpose**: Individual effect display with parameter controls

**Features**:
- Circular position badge showing order in chain
- Effect name and instance ID display
- Bypass toggle (grayed out when bypassed)
- Parameter grid (6 visible, expandable)
- Remove button
- modgui-style rendering simulation

**Parameters**:
```csharp
[Parameter] public PluginInstanceDto Effect { get; set; }
[Parameter] public int Position { get; set; }
[Parameter] public EventCallback OnRemove { get; set; }
[Parameter] public EventCallback<(string Parameter, float Value)> OnParameterChange { get; set; }
[Parameter] public EventCallback OnBypassToggle { get; set; }
```

**Parameter Display**:
- Up to 6 parameters shown by default
- "Show More" button for additional parameters
- KnobControl for each parameter with visual feedback
- Parameter name, value, and unit display

### 4. KnobControl (`Components/KnobControl.razor`)

**Purpose**: SVG-based rotary knob for parameter control

**Technical Specifications**:
- ViewBox: 80x80 pixels
- Rotation range: -135° to +135° (270° total)
- Arc visualization with gradient fill
- Indicator line showing current value
- Touch and mouse event support

**Parameters**:
```csharp
[Parameter] public float Value { get; set; }
[Parameter] public float MinValue { get; set; }
[Parameter] public float MaxValue { get; set; }
[Parameter] public string Label { get; set; }
[Parameter] public string? Unit { get; set; }
[Parameter] public EventCallback<float> OnValueChange { get; set; }
[Parameter] public bool IsReadOnly { get; set; }
```

**Visual Features**:
- Circular arc showing value range
- Green to blue gradient (#4CAF50 to #2196F3)
- Indicator line rotation
- Value text display with unit
- Min/Max labels
- Slider fallback for accessibility

### 5. AvailableEffectsPanel (`Components/AvailableEffectsPanel.razor`)

**Purpose**: Browse and add effects to pedalboard

**Features**:
- Real-time search across plugin names
- Category filtering (8 categories)
- Plugin count badges per category
- Click-to-select, button-to-add UX
- Rescan functionality
- Empty state messaging

**Categories**:
1. All - All available plugins
2. Distortion - Distortion, overdrive, fuzz
3. Delay - Delay, echo effects
4. Reverb - Reverb effects
5. Modulation - Chorus, flanger, phaser
6. EQ - Equalizers
7. Dynamics - Compressors, limiters, gates
8. Filter - Filters, wahs
9. Synth - Synthesizers

**Plugin Icons** (Open Iconic):
- Distortion: `oi-bolt`
- Delay: `oi-timer`
- Reverb: `oi-pulse`
- Modulation: `oi-waves`
- EQ: `oi-audio-spectrum`
- Dynamics: `oi-signal`
- Filter: `oi-graph`
- Synth: `oi-musical-note`

**Integration**:
```csharp
@inject PluginApiService PluginService
```

### 6. BackendControlsPanel (`Components/BackendControlsPanel.razor`)

**Purpose**: Display and manage backend-specific controls

**Supported Control Types**:

1. **Slider** - Range input for numeric values
   ```html
   <input type="range" min="@control.MinValue" max="@control.MaxValue" 
          step="@control.Step" value="@control.Value" />
   ```

2. **Toggle** - Checkbox for boolean values
   ```html
   <input type="checkbox" checked="@(control.Value > 0)" />
   ```

3. **Enum** - Dropdown for option selection
   ```html
   <select>
     @foreach (var option in control.Options)
     {
       <option value="@option">@option</option>
     }
   </select>
   ```

4. **Textbox** - Text input for string values
   ```html
   <input type="text" value="@control.StringValue" />
   ```

**Features**:
- Empty state when no controls available
- Refresh button to reload controls
- Reset to defaults button
- Control descriptions and tooltips
- Dark theme consistent with rack

## Data Transfer Objects (DTOs)

### PluginInstanceDto
```csharp
public class PluginInstanceDto
{
    public string InstanceId { get; set; } = string.Empty;
    public string PluginUri { get; set; } = string.Empty;
    public string PluginName { get; set; } = string.Empty;
    public bool IsBypassed { get; set; }
    public List<PluginParameterDto> Parameters { get; set; } = new();
}
```

### PluginParameterDto
```csharp
public class PluginParameterDto
{
    public string Symbol { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public float Value { get; set; }
    public float MinValue { get; set; }
    public float MaxValue { get; set; }
    public float Step { get; set; } = 0.01f;
    public string? Unit { get; set; }
}
```

### BackendControlDto
```csharp
public class BackendControlDto
{
    public string Id { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string Type { get; set; } = "Slider"; // Slider, Toggle, Enum, Textbox
    public float Value { get; set; }
    public float MinValue { get; set; }
    public float MaxValue { get; set; }
    public float Step { get; set; } = 1.0f;
    public string? StringValue { get; set; }
    public List<string> Options { get; set; } = new();
}
```

## Design System

### Color Palette

**Primary Colors**:
- Background Dark: `#1a1a1a`
- Background Medium: `#2a2a2a`
- Background Light: `#3a3a3a`
- Accent Green: `#4CAF50`
- Accent Blue: `#2196F3`

**Status Colors**:
- Success: `#4CAF50`
- Warning: `#FFC107`
- Danger: `#F44336`
- Info: `#2196F3`

**Text Colors**:
- Primary: `#e0e0e0`
- Secondary: `#b0b0b0`
- Muted: `#808080`

### Typography

**Font Family**: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif

**Font Sizes**:
- Heading 1: 2rem
- Heading 2: 1.5rem
- Heading 3: 1.25rem
- Body: 0.9rem
- Small: 0.75rem

### Spacing

**Grid Layout**:
- Left Panel: 320px fixed width
- Center Panel: Flexible (1fr)
- Right Panel: 320px fixed width
- Gap: 20px

**Component Spacing**:
- Padding: 15px (standard)
- Margin: 10px (between elements)
- Border Radius: 8px (cards)
- Border Radius: 4px (buttons)

### Responsive Design

**Breakpoints**:
- Mobile: < 768px (stacked layout)
- Tablet: 768px - 1200px (2-column layout)
- Desktop: > 1200px (3-column layout)

**Mobile Adaptations**:
```css
@media (max-width: 1200px) {
    .editor-grid {
        grid-template-columns: 1fr;
        grid-template-rows: auto auto auto;
    }
}
```

## Event Flow

### Adding an Effect

1. User browses AvailableEffectsPanel
2. User clicks plugin card to select
3. User clicks "+" button to add
4. AvailableEffectsPanel raises `OnAddEffect` event
5. PedalboardEditor calls API to add effect
6. API returns updated pedalboard
7. EffectsRack updates to show new effect
8. EffectSlot renders with default parameters

### Adjusting a Parameter

1. User interacts with KnobControl (drag/click)
2. KnobControl calculates new value
3. KnobControl raises `OnValueChange` event
4. EffectSlot receives value change
5. EffectSlot raises `OnParameterChange` with (parameter, value) tuple
6. EffectsRack receives parameter change
7. EffectsRack raises `OnParameterChange` with (instanceId, parameter, value) tuple
8. PedalboardEditor calls API to update parameter
9. API updates backend and returns success
10. UI updates to reflect new value

### Starting/Stopping Pedalboard

1. User clicks Start/Stop button in PedalboardEditor
2. PedalboardEditor validates backend is assigned
3. PedalboardEditor calls API start/stop endpoint
4. API initializes/shuts down audio backend
5. API updates pedalboard IsActive status
6. PedalboardEditor updates UI state
7. System stats polling begins (if started)

## Performance Optimizations

### Rendering Optimization

**Component Update Strategy**:
- Use `@key` directive for effect list rendering
- Implement `ShouldRender()` for expensive components
- Debounce parameter changes (100ms)
- Batch state updates

**Example**:
```csharp
@foreach (var effect in Effects)
{
    <EffectSlot @key="effect.InstanceId" Effect="@effect" ... />
}
```

### State Management

**Local State**:
- UI-only state (expanded panels, selected plugin)
- Kept in component-level fields

**Shared State**:
- Pedalboard data from API
- Loaded on page initialization
- Updated via API calls

**Real-time State** (Future Enhancement):
- SignalR hub for parameter changes
- WebSocket connection for system stats
- Live synchronization across clients

### API Call Optimization

**Batching**:
- Group multiple parameter changes
- Send batch update every 100ms

**Caching**:
- Cache plugin list in PluginApiService
- Cache backend list in AudioBackendApiService
- Invalidate on rescan

**Polling Strategy**:
- System stats: Poll every 500ms when running
- Stop polling when pedalboard stopped
- Use CancellationToken for cleanup

## Accessibility

### Keyboard Navigation

**Tab Order**:
1. Search box
2. Category tabs
3. Plugin cards
4. Effect slots
5. Parameter controls
6. Action buttons

**Keyboard Shortcuts** (Planned):
- `Ctrl+S`: Save pedalboard
- `Ctrl+N`: New pedalboard
- `Delete`: Remove selected effect
- `Space`: Toggle bypass on selected effect
- `Tab/Shift+Tab`: Navigate elements

### Screen Reader Support

**ARIA Labels**:
```html
<button aria-label="Add effect to pedalboard">
<input aria-label="Search plugins" />
<div role="slider" aria-valuenow="@Value" aria-valuemin="@MinValue" aria-valuemax="@MaxValue">
```

**Semantic HTML**:
- Proper heading hierarchy
- Form labels for all inputs
- Button types specified
- Alt text for icons

### Visual Accessibility

**Contrast Ratios**:
- Text on background: 7:1 (AAA)
- Button text: 4.5:1 (AA)
- Disabled states: 3:1

**Focus Indicators**:
```css
:focus {
    outline: 2px solid #4CAF50;
    outline-offset: 2px;
}
```

## Testing Strategy

### Unit Tests (Planned)

**Component Tests**:
- Render tests for each component
- Parameter binding tests
- Event callback tests
- State management tests

**Example**:
```csharp
[Test]
public void KnobControl_ValueChange_RaisesEvent()
{
    // Arrange
    var knob = RenderComponent<KnobControl>(parameters =>
    {
        parameters.Add(p => p.Value, 0.5f);
        parameters.Add(p => p.MinValue, 0f);
        parameters.Add(p => p.MaxValue, 1f);
    });
    
    // Act
    knob.Find("input").Change(0.75f);
    
    // Assert
    Assert.That(eventRaised, Is.True);
    Assert.That(eventValue, Is.EqualTo(0.75f));
}
```

### Integration Tests (Planned)

**Workflow Tests**:
- Add effect to pedalboard
- Adjust parameter end-to-end
- Start/stop pedalboard
- Save pedalboard

### Playwright E2E Tests (Future)

**User Scenarios**:
- Create new pedalboard
- Add distortion effect
- Adjust gain parameter
- Add reverb effect
- Reorder effects
- Save and verify

## Future Enhancements

### Phase 2 (Planned)

1. **Real-time Synchronization**
   - SignalR hub for parameter updates
   - WebSocket for system stats
   - Multi-client support

2. **Drag and Drop**
   - Reorder effects in rack
   - Drag from available panel to rack
   - Visual drop indicators

3. **Connection Editor**
   - Visual connection graph
   - Drag to connect ports
   - Validation and error display

### Phase 3 (Planned)

1. **Undo/Redo System**
   - Command pattern implementation
   - History stack with size limits
   - Keyboard shortcuts (Ctrl+Z, Ctrl+Y)

2. **Presets**
   - Save effect parameter presets
   - Load presets from library
   - Share presets via export

3. **Advanced Visualization**
   - Real-time audio spectrum analyzer
   - Waveform display
   - VU meters for each effect

4. **Performance Profiling**
   - Per-effect CPU usage
   - Latency breakdown
   - Performance recommendations

## Build and Deployment

### Build Commands

**Development Build**:
```powershell
dotnet build Alsionyx.BlazorUI
```

**Release Build**:
```powershell
dotnet build Alsionyx.BlazorUI -c Release
```

**Run Development Server**:
```powershell
dotnet run --project Alsionyx.BlazorUI
```

### Configuration

**appsettings.json**:
```json
{
  "ApiBaseUrl": "https://localhost:5001",
  "SignalRHubUrl": "https://localhost:5001/pedalboardHub",
  "PollingInterval": 500,
  "EnableRealTimeSync": true
}
```

### Static Assets

**wwwroot Structure**:
```
wwwroot/
├── css/
│   ├── app.css
│   └── components/
│       ├── effects-rack.css
│       ├── effect-slot.css
│       └── knob-control.css
├── js/
│   └── audio-visualizer.js
└── icons/
    └── plugin-icons/
```

## Conclusion

This UI component architecture provides a professional, user-friendly interface for audio pedalboard editing with:

✅ **Comprehensive Component Set**: 6 main components covering all workflow aspects
✅ **Professional Design**: Dark theme with green accents, consistent spacing
✅ **Responsive Layout**: 3-column grid adapting to screen sizes
✅ **Interactive Controls**: SVG-based knobs, real-time parameter updates
✅ **Robust State Management**: Clear event flow, API integration
✅ **Accessibility**: Keyboard navigation, ARIA labels, high contrast
✅ **Future-Proof**: Planned enhancements for Phase 2 and 3

The implementation follows Blazor best practices with proper EventCallback patterns, parameter binding, and component lifecycle management. All components build successfully with minimal warnings and provide a solid foundation for the complete audio workflow system.
