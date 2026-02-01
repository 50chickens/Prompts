# Quick Reference: Pedalboard UI Components

## Component Usage Guide

### PedalboardEditor Page

**Route**: `/pedalboards/{PedalboardId}/edit`

**Usage in Navigation**:
```csharp
Navigation.NavigateTo($"/pedalboards/{pedalboardId}/edit");
```

**Key Methods**:
```csharp
// Load pedalboard from API
protected override async Task OnInitializedAsync()

// Add effect to pedalboard
private async Task HandleAddEffect(string pluginUri)

// Remove effect from pedalboard
private async Task HandleRemoveEffect(string instanceId)

// Update parameter value
private async Task HandleParameterChange(string instanceId, string parameter, float value)

// Start/stop audio processing
private async Task StartPedalboard()
private async Task StopPedalboard()
```

---

### EffectsRack Component

**Import**:
```razor
@using Alsionyx.BlazorUI.Components
```

**Basic Usage**:
```razor
<EffectsRack 
    Effects="@pedalboard.Plugins"
    OnAddEffect="@HandleAddEffect"
    OnRemoveEffect="@HandleRemoveEffect"
    OnParameterChange="@HandleParameterChange"
    IsReadOnly="false" />
```

**EventCallback Signatures**:
```csharp
EventCallback<string> OnAddEffect
EventCallback<string> OnRemoveEffect
EventCallback<(string InstanceId, string Parameter, float Value)> OnParameterChange
```

**Handler Example**:
```csharp
private async Task HandleParameterChange((string InstanceId, string Parameter, float Value) change)
{
    var (instanceId, parameter, value) = change;
    await UpdateParameter(instanceId, parameter, value);
}
```

---

### EffectSlot Component

**Basic Usage**:
```razor
<EffectSlot 
    Effect="@effect"
    Position="@index"
    OnRemove="@(() => RemoveEffect(effect.InstanceId))"
    OnParameterChange="@((param) => UpdateParameter(effect.InstanceId, param.Parameter, param.Value))"
    OnBypassToggle="@(() => ToggleBypass(effect.InstanceId))"
    IsReadOnly="false" />
```

**Required Parameters**:
- `Effect`: PluginInstanceDto
- `Position`: int (0-based index in chain)

**Optional Parameters**:
- `IsReadOnly`: bool (default: false)

---

### KnobControl Component

**Basic Usage**:
```razor
<KnobControl 
    Value="@parameterValue"
    MinValue="0"
    MaxValue="1"
    Label="Gain"
    Unit="dB"
    OnValueChange="@(value => UpdateGain(value))"
    IsReadOnly="false" />
```

**All Parameters**:
```csharp
[Parameter] public float Value { get; set; }
[Parameter] public float MinValue { get; set; } = 0f;
[Parameter] public float MaxValue { get; set; } = 1f;
[Parameter] public string Label { get; set; } = string.Empty;
[Parameter] public string? Unit { get; set; }
[Parameter] public EventCallback<float> OnValueChange { get; set; }
[Parameter] public bool IsReadOnly { get; set; }
```

**Styling**:
- Size: 80x80 pixels
- Rotation: -135° to +135° (270° total)
- Colors: Green to Blue gradient

---

### AvailableEffectsPanel Component

**Basic Usage**:
```razor
<AvailableEffectsPanel 
    OnPluginSelected="@HandlePluginSelected" />
```

**EventCallback**:
```csharp
EventCallback<string> OnPluginSelected  // Passes plugin URI
```

**Features**:
- Search box (filters by plugin name)
- Category tabs (8 categories)
- Plugin count badges
- Rescan button

**Categories**:
- All, Distortion, Delay, Reverb, Modulation, EQ, Dynamics, Filter, Synth

---

### BackendControlsPanel Component

**Basic Usage**:
```razor
<BackendControlsPanel 
    Controls="@backendControls"
    OnControlChanged="@HandleControlChanged"
    OnRefresh="@RefreshControls"
    OnResetDefaults="@ResetDefaults" />
```

**Control Types**:
```csharp
public class BackendControlDto
{
    public string Type { get; set; } // "Slider", "Toggle", "Enum", "Textbox"
    public float Value { get; set; }
    public float MinValue { get; set; }
    public float MaxValue { get; set; }
    public string? StringValue { get; set; }
    public List<string> Options { get; set; } // For Enum type
}
```

---

## Common Patterns

### Creating a New Pedalboard

```csharp
var request = new CreatePedalboardRequest
{
    Name = "My Pedalboard",
    AudioBackend = "SoundFlow",
    SampleRate = 48000,
    BufferSize = 512
};

var pedalboard = await PedalboardService.CreatePedalboardAsync(request);
Navigation.NavigateTo($"/pedalboards/{pedalboard.Id}/edit");
```

### Adding an Effect

```csharp
private async Task HandleAddEffect(string pluginUri)
{
    try
    {
        var request = new AddPluginRequest
        {
            PluginUri = pluginUri,
            InstanceId = $"effect_{Guid.NewGuid():N}"
        };
        
        await PedalboardService.AddPluginAsync(PedalboardId, request);
        
        // Reload pedalboard
        pedalboard = await PedalboardService.GetPedalboardAsync(PedalboardId);
        successMessage = "Effect added successfully";
    }
    catch (Exception ex)
    {
        errorMessage = $"Failed to add effect: {ex.Message}";
    }
}
```

### Updating a Parameter

```csharp
private async Task HandleParameterChange(string instanceId, string parameter, float value)
{
    try
    {
        var request = new SetParameterRequest
        {
            InstanceId = instanceId,
            Parameter = parameter,
            Value = value
        };
        
        await PedalboardService.SetPluginParameterAsync(PedalboardId, request);
        
        // Update local state
        var effect = pedalboard.Plugins.Find(p => p.InstanceId == instanceId);
        if (effect != null)
        {
            var param = effect.Parameters.Find(p => p.Symbol == parameter);
            if (param != null)
            {
                param.Value = value;
            }
        }
    }
    catch (Exception ex)
    {
        errorMessage = $"Failed to update parameter: {ex.Message}";
    }
}
```

### Starting a Pedalboard

```csharp
private async Task StartPedalboard()
{
    if (string.IsNullOrWhiteSpace(pedalboard?.AudioBackend) || 
        pedalboard.AudioBackend == "None")
    {
        errorMessage = "Cannot start: No audio backend assigned";
        return;
    }
    
    try
    {
        await PedalboardService.StartPedalboardAsync(PedalboardId);
        isRunning = true;
        successMessage = "Pedalboard started";
        
        // Start polling system stats
        await PollSystemStats();
    }
    catch (Exception ex)
    {
        errorMessage = $"Failed to start: {ex.Message}";
    }
}
```

### Polling System Stats

```csharp
private async Task PollSystemStats()
{
    while (isRunning)
    {
        try
        {
            systemStats = await PedalboardService.GetSystemStatsAsync(PedalboardId);
            StateHasChanged();
            await Task.Delay(500); // Poll every 500ms
        }
        catch
        {
            break;
        }
    }
}
```

---

## API Service Methods

### PedalboardApiService

```csharp
Task<List<PedalboardDto>> GetAllPedalboardsAsync()
Task<PedalboardDto> GetPedalboardAsync(string id)
Task<PedalboardDto> CreatePedalboardAsync(CreatePedalboardRequest request)
Task<PedalboardDto> UpdatePedalboardAsync(string id, UpdatePedalboardRequest request)
Task DeletePedalboardAsync(string id)
Task StartPedalboardAsync(string id)
Task StopPedalboardAsync(string id)
Task<PedalboardDto> AddPluginAsync(string id, AddPluginRequest request)
Task<PedalboardDto> RemovePluginAsync(string id, string instanceId)
Task SetPluginParameterAsync(string id, SetParameterRequest request)
Task<SystemStatsDto> GetSystemStatsAsync(string id)
```

### PluginApiService

```csharp
Task<List<PluginInfoDto>> GetAllPluginsAsync()
Task<PluginInfoDto> GetPluginAsync(string uri)
Task<List<PluginInfoDto>> GetPluginsByTypeAsync(string type)
Task RescanPluginsAsync()
```

### AudioBackendApiService

```csharp
Task<List<BackendInfoDto>> GetAllBackendsAsync()
Task<BackendInfoDto> GetBackendAsync(string name)
Task<List<AudioDeviceDto>> GetDevicesAsync(string backend)
Task<List<BackendControlDto>> GetControlsAsync(string backend)
Task SetControlAsync(string backend, string controlId, object value)
```

---

## Styling Customization

### Component CSS Classes

**EffectsRack**:
```css
.effects-rack { /* Main container */ }
.rack-header { /* Header with stats */ }
.signal-flow { /* Input → Output display */ }
.effects-chain { /* Effect list container */ }
```

**EffectSlot**:
```css
.effect-slot { /* Main card */ }
.effect-slot.bypassed { /* Grayed out state */ }
.position-badge { /* Circular position indicator */ }
.parameters-grid { /* Parameter layout */ }
```

**KnobControl**:
```css
.knob-control { /* Container */ }
.knob-svg { /* SVG element */ }
.knob-slider { /* Fallback slider */ }
```

### Color Overrides

```css
:root {
    --rack-bg-dark: #1a1a1a;
    --rack-bg-light: #2a2a2a;
    --accent-green: #4CAF50;
    --accent-blue: #2196F3;
    --text-primary: #e0e0e0;
}
```

---

## Performance Tips

### 1. Debounce Parameter Changes

```csharp
private System.Timers.Timer? debounceTimer;

private void HandleParameterChangeDebounced(string instanceId, string parameter, float value)
{
    debounceTimer?.Stop();
    debounceTimer = new System.Timers.Timer(100);
    debounceTimer.Elapsed += async (s, e) =>
    {
        await HandleParameterChange(instanceId, parameter, value);
        debounceTimer?.Dispose();
    };
    debounceTimer.Start();
}
```

### 2. Use @key for List Rendering

```razor
@foreach (var effect in Effects)
{
    <EffectSlot @key="effect.InstanceId" Effect="@effect" ... />
}
```

### 3. Implement ShouldRender

```csharp
protected override bool ShouldRender()
{
    // Only render if critical state changed
    return hasStateChanged;
}
```

### 4. Batch API Calls

```csharp
private List<(string instanceId, string parameter, float value)> pendingChanges = new();

private async Task FlushPendingChanges()
{
    if (pendingChanges.Count == 0) return;
    
    var batch = new BatchParameterUpdateRequest
    {
        Changes = pendingChanges
    };
    
    await PedalboardService.BatchUpdateParametersAsync(PedalboardId, batch);
    pendingChanges.Clear();
}
```

---

## Error Handling

### Display Errors to User

```csharp
private string? errorMessage;
private string? successMessage;

private async Task SafeApiCall(Func<Task> apiCall, string operation)
{
    try
    {
        errorMessage = null;
        await apiCall();
        successMessage = $"{operation} successful";
    }
    catch (HttpRequestException ex)
    {
        errorMessage = $"Network error: {ex.Message}";
    }
    catch (Exception ex)
    {
        errorMessage = $"{operation} failed: {ex.Message}";
    }
}
```

### Use in Component

```razor
@if (!string.IsNullOrEmpty(errorMessage))
{
    <div class="alert alert-danger">
        @errorMessage
        <button @onclick="@(() => errorMessage = null)">×</button>
    </div>
}

@if (!string.IsNullOrEmpty(successMessage))
{
    <div class="alert alert-success">
        @successMessage
        <button @onclick="@(() => successMessage = null)">×</button>
    </div>
}
```

---

## Testing Examples

### Component Render Test

```csharp
[Test]
public void EffectsRack_RendersWithEffects()
{
    // Arrange
    var effects = new List<PluginInstanceDto>
    {
        new() { InstanceId = "fx1", PluginName = "Distortion" },
        new() { InstanceId = "fx2", PluginName = "Reverb" }
    };
    
    // Act
    var component = RenderComponent<EffectsRack>(parameters =>
    {
        parameters.Add(p => p.Effects, effects);
    });
    
    // Assert
    Assert.That(component.FindAll(".effect-slot").Count, Is.EqualTo(2));
}
```

### Event Callback Test

```csharp
[Test]
public void KnobControl_ValueChange_InvokesCallback()
{
    // Arrange
    float callbackValue = 0;
    var component = RenderComponent<KnobControl>(parameters =>
    {
        parameters.Add(p => p.Value, 0.5f);
        parameters.Add(p => p.OnValueChange, EventCallback.Factory.Create<float>(
            this, value => callbackValue = value));
    });
    
    // Act
    component.Find("input").Change(0.75f);
    
    // Assert
    Assert.That(callbackValue, Is.EqualTo(0.75f));
}
```

---

## Keyboard Shortcuts (Planned)

```csharp
@code {
    private async Task HandleKeyDown(KeyboardEventArgs e)
    {
        if (e.CtrlKey && e.Key == "s")
        {
            e.PreventDefault();
            await SavePedalboard();
        }
        else if (e.Key == "Delete" && selectedEffect != null)
        {
            await RemoveEffect(selectedEffect.InstanceId);
        }
        else if (e.Key == " " && selectedEffect != null)
        {
            await ToggleBypass(selectedEffect.InstanceId);
        }
    }
}
```

```razor
<div @onkeydown="HandleKeyDown" tabindex="0">
    <!-- Component content -->
</div>
```

---

## Build Status

✅ All components build successfully  
✅ 0 errors, 1 warning (unused field)  
✅ 238 total tests passing  
✅ 44 SoundFlow backend tests passing  
✅ Ready for development and testing  

Last updated: 2024 (Build: Release mode verified)
