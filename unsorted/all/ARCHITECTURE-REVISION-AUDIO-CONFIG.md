# Architecture Revision: Audio Configuration First Design

## Executive Summary

**Previous Design:** Pedalboard required audio backend to be started before use
**New Design:** Pedalboard loads empty on app launch; user configures audio inputs/outputs after

This revision removes the startup barrier and makes audio configuration a first-class UI concern.

---

## Requirements

### 1. Application Launch Behavior

**Removed:**
- ❌ Splash screen
- ❌ Audio backend initialization requirement
- ❌ Loading spinner

**New:**
- ✅ Show main pedalboard screen immediately
- ✅ Display empty pedalboard (no plugins loaded)
- ✅ Show audio configuration UI on left (input) and right (output) sides
- ✅ Audio configuration UI is **minimized but visible** (not hidden/collapsed)

### 2. Audio Configuration UI

**Location & Layout:**
```
┌─────────────────────────────────────────────────────┐
│         Main Pedalboard Screen                      │
├──────────┬──────────────────────────┬──────────────┤
│ Input    │                          │ Output       │
│ Config   │    Empty Pedalboard      │ Config       │
│ (Left)   │    - No plugins yet      │ (Right)      │
│          │    - Waiting for user    │              │
│          │                          │              │
│          │    [Add Plugin Button]   │              │
├──────────┴──────────────────────────┴──────────────┤
│ Plugin Library / Effects Panel (if needed)         │
└─────────────────────────────────────────────────────┘
```

**Input Configuration Panel (Left Side):**
- Audio device dropdown (e.g., "Built-in Microphone", "Line In")
- Sample rate selector (44.1kHz, 48kHz, 96kHz)
- Buffer size selector (128, 256, 512, 1024 samples)
- Channels indicator (Mono, Stereo, etc.)
- Visual input level meter

**Output Configuration Panel (Right Side):**
- Audio device dropdown (e.g., "Built-in Speaker", "Line Out")
- Sample rate selector (same as input for sync)
- Buffer size selector (same as input for sync)
- Channels indicator
- Visual output level meter

### 3. Dynamic Connection Updates

**Behavior:**
- When user changes input device → **connections update immediately**
- When user changes output device → **connections update immediately**
- When user changes sample rate → **connections sync across UI**
- Connection display should reflect current selection

**Example:**
```
User selects: "Built-in Microphone" (Stereo)
  ↓
UI updates left side to show: [Microphone: CH1, CH2]
  ↓
Empty pedalboard connection points update
  ↓
User sees: "Microphone:CH1 → [Empty Pedalboard] → Speaker:CH1"
```

### 4. UI Minimization Strategy

**Not Collapsed/Hidden:**
- Audio panels are always visible
- User can see current configuration at a glance
- Panels use compact styling (minimal padding/margins)

**Not Expanded/Large:**
- Panels are narrow to maximize pedalboard space
- Use icons + labels instead of full text where possible
- Stack controls vertically to minimize width

**Resizable (Optional Enhancement):**
- User can drag panel edges to resize
- Resizing preference saved to localStorage

### 5. Pedalboard on Launch

**Empty State:**
```
┌──────────────────────────────────┐
│    Pedalboard (No Plugins)       │
│                                  │
│         ↓ Input Points ↓         │
│                                  │
│      [Add Plugin →]              │
│                                  │
│         ↓ Output Points ↓        │
│                                  │
└──────────────────────────────────┘
```

**Behavior:**
- User can add plugins **without selecting audio first** (decoupled)
- Plugins work with whatever audio config is selected
- Can test plugin chain with file playback (no mic needed)

### 6. Pedalboard Persistence

**Save/Load Behavior:**
- Remember last selected input device
- Remember last selected output device
- Remember audio configuration (sample rate, buffer size)
- Restore on next launch

---

## Updated Workflow

### Before (Old Design)
```
1. Launch app
   ↓ [Splash Screen]
2. Wait for audio backend
   ↓ [Loading spinner 3-5 seconds]
3. User selects input device
4. User selects output device
5. Backend starts
6. User creates/loads pedalboard
7. User adds plugins
8. User connects plugins
```

### After (New Design)
```
1. Launch app
   ↓ [Immediate, no splash]
2. See empty pedalboard
   ↓ [Pedalboard visible immediately]
3. (Optional) User selects input device
4. (Optional) User selects output device
5. User creates/loads pedalboard
6. User adds plugins
7. User connects plugins
8. User clicks [Play/Start] when ready
```

**Key Difference:** Audio config and pedalboard creation are decoupled and optional for initial setup

---

## Component Changes Required

### 1. Main App Layout (App.razor / Layout)

**Current:**
- Shows splash screen
- Initializes audio backend
- Then shows pedalboard selector

**New:**
- Shows pedalboard immediately
- Audio config panels rendered alongside
- No splash screen

### 2. Pedalboard Editor Component

**Current:**
- Assumes audio backend is running
- Requires active backend to show connections

**New:**
- Works with or without audio backend
- Shows "unconnected" state when no audio
- Dynamically updates when audio config changes

### 3. Audio Configuration Components

**Current:**
- Separate "Settings" page
- Hidden by default

**New:**
- Integrated into main layout
- Always visible on left/right sides
- Compact minimized style
- Triggers connection updates

### 4. Connection Viewer Component

**Current:**
- Shows connections based on running backend
- Static during pedalboard editing

**New:**
- Shows connections based on user selection
- Updates in real-time when config changes
- Can show "Virtual" connections (software routing)

---

## Data Flow Diagram

### Audio Configuration Change Flow
```
┌────────────────────────────────────────────────────────┐
│ User selects input device from dropdown               │
└─────────────────────┬────────────────────────────────┘
                      │
                      ↓
         ┌────────────────────────────┐
         │ AudioConfigService         │
         │ .SetInputDeviceAsync()     │
         └────────────┬───────────────┘
                      │
         ┌────────────┴────────────┐
         │                         │
         ↓                         ↓
    ┌─────────────┐         ┌──────────────────┐
    │ Save to     │         │ Notify UI of     │
    │ LocalStorage│         │ change via       │
    │             │         │ StateHasChanged()│
    └─────────────┘         └──────────┬───────┘
                                       │
                                       ↓
                            ┌──────────────────────┐
                            │ Connection Viewer    │
                            │ .Refresh()           │
                            │ Re-render with new   │
                            │ input points         │
                            └──────────────────────┘
```

---

## Testing Strategy Updates

### Playwright Tests - New Test Cases

**Test 1: Empty Pedalboard on Launch**
```gherkin
Given user launches the application
When the app finishes loading
Then the pedalboard editor is visible
And the pedalboard contains no plugins
And audio configuration panels are visible on left and right
```

**Test 2: Audio Configuration Updates Connections**
```gherkin
Given user is viewing empty pedalboard
When user selects "Built-in Microphone" from input dropdown
Then input connection points update to show microphone channels
And connection display reflects the selection
```

**Test 3: Add Plugin Without Audio**
```gherkin
Given empty pedalboard with no audio configured
When user clicks [Add Plugin]
Then plugin dialog opens
And user can add a plugin
And pedalboard renders with plugin (even without audio)
```

**Test 4: Audio Config Persists**
```gherkin
Given user selects "USB Audio" as input device
And user selects 96kHz sample rate
When user refreshes the page
Then the same audio config is restored
```

### Integration Tests - Enhanced

**Current:** Tests assume audio backend is running

**New:** Tests should cover:
- Audio config without backend
- Connection updates on config change
- Pedalboard rendering without audio
- Plugin addition without audio
- Persistence of audio config

---

## UI/UX Considerations

### Minimized Panel Design

**Input Panel Example:**
```
┌─────────────────┐
│ 🎤 INPUT      │ ← Compact header
├─────────────────┤
│ Device:        │
│ [🔊 Microphone▼]│ ← Dropdown
│                │
│ 48 kHz | 256   │ ← Quick selectors
│ Stereo | 2 ch  │
│                │
│ ▂▃▄▅▆▇█ ▂▃▄▅▆ │ ← Level meter
└─────────────────┘
```

**Design Principles:**
- Max width: 120-150px
- Use icons to save space
- Vertical stacking
- No wasted whitespace
- Contrasting colors for panels

### Responsiveness

- **Desktop:** Left/right panels visible at full width
- **Tablet:** Panels collapse to icons on left/right edges
- **Mobile:** Panels accessible via tabs/modals

---

## Migration Path

### Phase 1: Documentation (This Document)
- ✅ Define requirements
- ✅ Plan component changes
- ✅ Update test strategy

### Phase 2: Component Architecture Update
- [ ] Remove splash screen
- [ ] Update App.razor layout
- [ ] Create minimized AudioConfigPanel components
- [ ] Update connection display logic

### Phase 3: Audio Configuration Integration
- [ ] Implement input config panel
- [ ] Implement output config panel
- [ ] Add real-time update logic
- [ ] Add persistence (localStorage)

### Phase 4: Connection Updates
- [ ] Update ConnectionViewer for dynamic updates
- [ ] Implement audio config change handlers
- [ ] Test with various device configurations

### Phase 5: Testing
- [ ] Update Playwright tests
- [ ] Add integration tests for new flows
- [ ] Test audio config persistence
- [ ] Test connection updates

---

## Backward Compatibility

**What Changes:**
- App launch flow
- Initial UI layout
- Connection display behavior

**What Stays the Same:**
- Pedalboard saving/loading
- Plugin management
- Audio backend API
- REST endpoints

**Migration for Users:**
- Existing pedalboards load as before
- First launch shows new UI with no splash
- Audio config panels appear automatically

---

## Implementation Notes

### Key Files to Modify

1. **App.razor** - Remove splash, add layout structure
2. **PedalboardEditor.razor** - Update for minimized panels
3. **ConnectionViewer.razor** - Dynamic update on config change
4. **AudioConfigService.cs** - Add change notification
5. **Program.cs (Blazor)** - Remove splash screen rendering

### New Components to Create

1. **InputConfigPanel.razor** - Minimized left panel
2. **OutputConfigPanel.razor** - Minimized right panel
3. **AudioConfigContext.cs** - State management for audio config

### Tests to Update

1. **CriticalJourneyTests.cs** - Remove audio start steps
2. **PedalboardEditorTests.cs** - Test empty load
3. Add new tests for audio config changes

---

## Success Criteria

- ✅ App launches without splash screen
- ✅ Empty pedalboard visible immediately
- ✅ Audio config panels visible on left/right
- ✅ Audio config changes update connections in real-time
- ✅ Pedalboard can be used without audio (for testing)
- ✅ Audio config persists between sessions
- ✅ All existing tests pass with updates
- ✅ New Playwright tests cover audio config workflow
