# Quick Reference: Pedalboard UI Implementation

## Visual Component Layout

This quick reference shows exactly what the Blazor components look like and how they interact.

### Main Pedalboard Page

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  🎛️  ALSA Audio Manager - Pedalboard Editor                   [Settings] 🔧  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                               │
│ Pedalboard: [My Guitar Setup ▼]  [Save] [Load] [Export] [Import]            │
│ Backend: [ALSA ▼]  Input: [Intel HDA 0 ▼]  Output: [Intel HDA 0 ▼]         │
│                                                                               │
├─────────────────────────────────────────────────────────────────────────────┤
│  INPUT                                                                        │
│  ┌────┐                                                                      │
│  │ 🔊 │────────────────────────────────────────────────────────────────    │
│  └────┘                                                                      │
│     ↓                                                                         │
│                                                                               │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐         │
│  │  REVERB         │    │  COMPRESSOR     │    │  EQUALIZER      │         │
│  │ 🟣 Purple       │    │ 🔵 Blue         │    │ 🟢 Green        │         │
│  │                 │    │                 │    │                 │         │
│  │  ◉  Dry/Wet     │    │  ◉  Threshold   │    │  ◉  Bass        │         │
│  │     50%         │    │     -20dB       │    │     0dB         │         │
│  │                 │    │                 │    │                 │         │
│  │  ◉  Room Size   │    │  ◉  Ratio       │    │  ◉  Mid         │         │
│  │     70%         │    │     4:1         │    │     0dB         │         │
│  │                 │    │                 │    │                 │         │
│  │       [X]       │    │       [X]       │    │       [X]       │         │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘         │
│        ↓                      ↓                      ↓                        │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━                      │
│        (WIRES - visual connections between effects)                         │
│                                                                               │
│     ↓                                                                         │
│  OUTPUT                                                                       │
│  ┌────┐                                                                      │
│  │ 📤 │────────────────────────────────────────────────────────────────    │
│  └────┘                                                                      │
│                                                                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                               │
│  📚 ADD EFFECTS                                                              │
│  [🔍 Search effects...                                    ]                  │
│                                                                               │
│  📂 Category: [All ▼]  [Reverb] [Delay] [Compressor] [EQ] [Distortion]     │
│                                                                               │
│  • Reverb Chamber        (drag to add)                                       │
│  • Large Hall            (drag to add)                                       │
│  • Room Reverb           (drag to add)                                       │
│  • Delay 1s              (drag to add)                                       │
│  • Dynamic Compressor    (drag to add)                                       │
│  • Soft Knee Compressor  (drag to add)                                       │
│  • 3-Band EQ             (drag to add)                                       │
│  • Parametric EQ         (drag to add)                                       │
│                                                                               │
├─────────────────────────────────────────────────────────────────────────────┤
│  CPU: 24%  │ Latency: 5.2ms  │ Sample Rate: 48000Hz  │ Buffer: 256        │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Component Interaction Diagram

```
User Action                Component              Service              API Call
───────────────────────────────────────────────────────────────────────────

[Drag effect to rack] → EffectsRack
                         │
                         ↓ onEffectDrop()
                                          → PedalboardService
                                             │
                                             ↓ AddEffectAsync()
                                                              → POST /api/pedalboards/{id}/effects
                                                                 │
                                                                 ↓ Success
                                                              ← JSON (effect instance)
                                             │
                                             ↓ Update cache
                       ← Notify component
                       │
                       ↓ Re-render
                    [Effect appears on board]


[Turn knob] → EffectSlot
              │
              ↓ onParameterChanged()
                           → PedalboardService
                              │
                              ↓ SetParameterAsync()
                                                   → PUT /api/pedalboards/{id}/effects/{id}/parameters/{name}
                                                      │
                                                      ↓ Success
                                                   ← JSON (updated value)
                              │
                              ↓ Update cache
                       ← Notify component
                       │
                       ↓ Re-render
                    [Knob updates in real-time]


[Remove effect] → EffectSlot
                  │
                  ↓ onRemove()
                                 → PedalboardService
                                    │
                                    ↓ RemoveEffectAsync()
                                                         → DELETE /api/pedalboards/{id}/effects/{id}
                                                            │
                                                            ↓ Success (204)
                                    │
                                    ↓ Update cache
                          ← Notify component
                          │
                          ↓ Re-render
                       [Effect disappears]
```

## Blazor Component Tree

```
App.razor
│
└── MainLayout.razor
    │
    └── PedalboardPage.razor
        │
        ├── PedalboardHeader.razor
        │   ├── PedalboardSelector.razor
        │   │   └── <select> with pedalboards
        │   │
        │   ├── AudioBackendSelector.razor
        │   │   └── <select> with ALSA/JACK/ASIO/SoundFlow
        │   │
        │   ├── InputDeviceSelector.razor
        │   │   └── <select> with input devices
        │   │
        │   └── OutputDeviceSelector.razor
        │       └── <select> with output devices
        │
        ├── EffectsRack.razor (MAIN CANVAS)
        │   │
        │   ├── InputSource.razor
        │   │   └── Displays input device icon
        │   │
        │   ├── EffectSlot.razor (Repeating - one per effect)
        │   │   │
        │   │   ├── EffectHeader.razor
        │   │   │   ├── EffectName (draggable)
        │   │   │   ├── EffectColorBadge
        │   │   │   │   └── Color based on type
        │   │   │   │
        │   │   │   └── RemoveButton
        │   │   │       └── X icon to remove
        │   │   │
        │   │   ├── EffectKnobs.razor (Repeating - one per parameter)
        │   │   │   ├── KnobControl.razor
        │   │   │   │   ├── SVG arc visualization
        │   │   │   │   ├── Rotation based on value
        │   │   │   │   ├── Mouse drag to adjust
        │   │   │   │   └── Mouse wheel support
        │   │   │   │
        │   │   │   ├── ParameterLabel
        │   │   │   │   └── Parameter name
        │   │   │   │
        │   │   │   └── ParameterValue
        │   │   │       └── Current value display
        │   │   │
        │   │   ├── EffectConnector.razor
        │   │   │   └── SVG line to next effect
        │   │   │
        │   │   └── EffectEnabledToggle.razor
        │   │       └── On/off switch
        │   │
        │   ├── OutputDestination.razor
        │   │   └── Displays output device icon
        │   │
        │   └── ConnectionLines.razor
        │       └── SVG canvas for effect connections
        │
        ├── AvailableEffectsPanel.razor
        │   │
        │   ├── SearchBox.razor
        │   │   └── <input> for effect filtering
        │   │
        │   ├── CategoryTabs.razor
        │   │   ├── AllTab
        │   │   ├── ReverbTab
        │   │   ├── DelayTab
        │   │   ├── CompressorTab
        │   │   ├── EqualizerTab
        │   │   └── ... more tabs
        │   │
        │   └── EffectLibrary.razor
        │       └── Draggable effect list
        │           ├── EffectItem.razor (Repeating)
        │           │   ├── EffectIcon
        │           │   ├── EffectName
        │           │   └── Drag handle
        │           │
        │           └── ... more effects
        │
        └── PedalboardFooter.razor
            ├── SystemLoadIndicator.razor
            │   └── CPU usage bar
            │
            ├── LatencyDisplay.razor
            │   └── Latency in ms
            │
            ├── SampleRateDisplay.razor
            │   └── Current sample rate
            │
            └── BufferSizeDisplay.razor
                └── Current buffer size
```

## Effect Slot HTML Structure

```html
<div class="effect-slot" data-instance-id="reverb-1" draggable="true">
  
  <div class="effect-header">
    <div class="effect-color-badge" style="background: purple;"></div>
    <div class="effect-name">Reverb Chamber</div>
    <button class="remove-btn" @onclick="OnRemove">×</button>
  </div>
  
  <div class="effect-body">
    <!-- Parameter Controls -->
    <div class="parameter-group">
      <label>Dry/Wet</label>
      <div class="knob-control">
        <svg class="knob-svg" viewBox="0 0 100 100">
          <circle cx="50" cy="50" r="45" class="knob-background"/>
          <path class="knob-indicator" d="M50,10 L50,5" transform="rotate(135 50 50)"/>
        </svg>
        <div class="parameter-value">50%</div>
      </div>
    </div>
    
    <div class="parameter-group">
      <label>Room Size</label>
      <div class="knob-control">
        <svg class="knob-svg" viewBox="0 0 100 100">
          <circle cx="50" cy="50" r="45" class="knob-background"/>
          <path class="knob-indicator" d="M50,10 L50,5" transform="rotate(189 50 50)"/>
        </svg>
        <div class="parameter-value">70%</div>
      </div>
    </div>
  </div>
  
  <div class="effect-footer">
    <input type="checkbox" checked class="enable-toggle"/>
  </div>
  
</div>
```

## Knob Control Interaction

```javascript
// KnobControl.razor.cs

[Component]
public partial class KnobControl
{
    private float _angle;  // 0-270 degrees
    
    protected override void OnParametersSet()
    {
        // Calculate angle from Value (Min to Max = 0° to 270°)
        var normalized = (Value - Min) / (Max - Min);
        _angle = normalized * 270;
    }
    
    private async Task OnMouseDown(MouseEventArgs e)
    {
        // Start dragging
        // Track mouse move to update angle
        // Broadcast parameter change
    }
    
    private async Task OnMouseWheel(WheelEventArgs e)
    {
        // Adjust value based on wheel direction
        // +5% per scroll up
        // -5% per scroll down
    }
}
```

## CSS Styling

```css
/* Effect Slot */
.effect-slot {
  background: linear-gradient(135deg, #f5f5f5, #e0e0e0);
  border: 2px solid #999;
  border-radius: 8px;
  padding: 12px;
  width: 120px;
  box-shadow: 0 4px 6px rgba(0,0,0,0.1);
  transition: transform 0.2s, box-shadow 0.2s;
}

.effect-slot:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 12px rgba(0,0,0,0.2);
}

.effect-slot.dragging {
  opacity: 0.7;
  border: 2px dashed #999;
}

/* Effect Colors */
.effect-slot.reverb { border-color: purple; }
.effect-slot.delay { border-color: blue; }
.effect-slot.compressor { border-color: orange; }
.effect-slot.equalizer { border-color: green; }
.effect-slot.distortion { border-color: red; }
.effect-slot.synth { border-color: cyan; }

/* Knob Control */
.knob-control {
  position: relative;
  width: 60px;
  height: 60px;
  margin: 10px auto;
}

.knob-svg {
  cursor: grab;
  user-select: none;
}

.knob-svg:active {
  cursor: grabbing;
}

.knob-background {
  fill: #ddd;
  stroke: #999;
  stroke-width: 2;
}

.knob-indicator {
  stroke: #333;
  stroke-width: 3;
  stroke-linecap: round;
  transform-origin: 50px 50px;
}

/* Available Effects Panel */
.available-effects-panel {
  position: absolute;
  right: 20px;
  top: 150px;
  width: 250px;
  max-height: 400px;
  background: white;
  border: 1px solid #ccc;
  border-radius: 4px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  overflow-y: auto;
}

.effect-item {
  padding: 12px;
  border-bottom: 1px solid #eee;
  cursor: grab;
  transition: background 0.2s;
}

.effect-item:hover {
  background: #f5f5f5;
}

.effect-item.dragging {
  opacity: 0.5;
  background: #e8e8e8;
}
```

## Related Documentation

- [Pedalboard UI & Audio Backend](09-PEDALBOARD-UI-AND-AUDIO-BACKEND.md) - Detailed architecture
- [Components by Layer](04-COMPONENTS-BY-LAYER.md) - Full component specifications
- [Workflows & Patterns](06-WORKFLOWS-AND-PATTERNS.md) - User workflows
