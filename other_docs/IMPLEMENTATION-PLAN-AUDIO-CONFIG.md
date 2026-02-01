# Implementation Plan: Audio Configuration First Architecture

## Overview

This document outlines the step-by-step implementation to move from splash-screen-first to pedalboard-first with minimized audio config panels.

---

## Phase 1: Preparation & Documentation ✅ COMPLETE

- ✅ Created comprehensive architecture requirements document
- ✅ Defined new workflow
- ✅ Planned component changes
- ✅ Identified files to modify

**Reference:** [ARCHITECTURE-REVISION-AUDIO-CONFIG.md](ARCHITECTURE-REVISION-AUDIO-CONFIG.md)

---

## Phase 2: Remove Splash Screen & Update App Layout

### Step 2.1: Identify Current Splash Screen Location
- Find splash screen component in App.razor or startup layout
- Identify where it's rendered
- Check if there's a splash screen service

### Step 2.2: Update App.razor Layout Structure
**Current:**
```html
<Router>
    <SplashScreen />
    <PedalboardSelector />
</Router>
```

**New:**
```html
<Router>
    <div class="app-container">
        <InputConfigPanel />
        <PedalboardEditor />
        <OutputConfigPanel />
    </div>
</Router>
```

### Step 2.3: CSS Layout for Panels
- Left panel: position fixed, left side, width 120-150px
- Right panel: position fixed, right side, width 120-150px
- Main content: flex container, margins for panels
- Responsive: collapse to edges on small screens

**Files to Modify:**
- `Program.cs` (Blazor)
- `App.razor`
- `App.razor.css`

---

## Phase 3: Create Audio Configuration Components

### Step 3.1: Create InputConfigPanel Component
**File:** `Components/InputConfigPanel.razor`

**Features:**
- Audio device dropdown
- Sample rate selector
- Buffer size selector
- Channel info display
- Input level meter

**State:**
- Current input device name
- Selected sample rate
- Selected buffer size
- Input level data

**Events:**
- OnInputDeviceChanged
- OnSampleRateChanged
- OnBufferSizeChanged

### Step 3.2: Create OutputConfigPanel Component
**File:** `Components/OutputConfigPanel.razor`

**Features:**
- Audio device dropdown
- Sample rate selector (synced with input)
- Buffer size selector (synced with input)
- Channel info display
- Output level meter

**State:**
- Current output device name
- Selected sample rate
- Selected buffer size
- Output level data

**Events:**
- OnOutputDeviceChanged
- OnSampleRateChanged
- OnBufferSizeChanged

### Step 3.3: Create AudioConfigContext Service
**File:** `Services/AudioConfigContext.cs`

**Purpose:** Shared state for audio configuration

**Public Properties:**
```csharp
public class AudioConfigContext
{
    public string InputDevice { get; set; }
    public string OutputDevice { get; set; }
    public int SampleRate { get; set; }
    public int BufferSize { get; set; }
    
    public event Action OnConfigChanged;
    public event Action<AudioConfigChangedEventArgs> OnConfigDetailChanged;
}
```

**Methods:**
- SetInputDevice(string deviceName)
- SetOutputDevice(string deviceName)
- SetSampleRate(int sampleRate)
- SetBufferSize(int bufferSize)
- LoadFromLocalStorage()
- SaveToLocalStorage()

**Files to Create:**
- `Components/InputConfigPanel.razor`
- `Components/InputConfigPanel.razor.cs`
- `Components/InputConfigPanel.razor.css`
- `Components/OutputConfigPanel.razor`
- `Components/OutputConfigPanel.razor.cs`
- `Components/OutputConfigPanel.razor.css`
- `Services/AudioConfigContext.cs`

---

## Phase 4: Update PedalboardEditor Component

### Step 4.1: Load Empty Pedalboard
**Current:** Requires audio backend to be selected first

**New:**
- Accept pedalboard with no audio config
- Show empty plugin list
- Show connection points based on AudioConfigContext
- Don't require active backend

### Step 4.2: Add Real-Time Connection Updates
**When AudioConfigContext changes:**
- Subscribe to OnConfigDetailChanged event
- Retrieve available channels for selected input device
- Retrieve available channels for selected output device
- Update connection display
- Call StateHasChanged() to re-render

### Step 4.3: Handle No-Audio State
**When no audio device selected:**
- Show "No input device selected" message
- Show "No output device selected" message
- Still allow plugin management (for testing)
- Disable connection rendering

**Files to Modify:**
- `Pages/PedalboardEditor.razor`
- `Pages/PedalboardEditor.razor.cs`

---

## Phase 5: Update ConnectionViewer Component

### Step 5.1: Dynamic Connection Point Generation
**Current:** Static based on loaded pedalboard

**New:**
- Accept audio config as parameter
- Generate connection points based on:
  - Input device channels
  - Selected sample rate
  - Output device channels
- Update when config changes

### Step 5.2: Add Refresh Method
```csharp
public async Task RefreshConnectionsAsync()
{
    // Re-fetch device info
    // Rebuild connection point list
    // StateHasChanged()
}
```

**Files to Modify:**
- `Components/ConnectionViewer.razor`
- `Components/ConnectionViewer.razor.cs`

---

## Phase 6: Add Persistence Layer

### Step 6.1: LocalStorage Binding
**In AudioConfigContext:**
- Save to localStorage on SetInputDevice()
- Save to localStorage on SetOutputDevice()
- Save to localStorage on SetSampleRate()
- Save to localStorage on SetBufferSize()

### Step 6.2: Restore on App Launch
**In App.razor or Program.cs:**
- Call AudioConfigContext.LoadFromLocalStorage() on startup
- Restore last used devices and settings
- Trigger UI update to show restored config

**Implementation:**
```csharp
protected override async Task OnInitializedAsync()
{
    await audioConfigContext.LoadFromLocalStorage();
    // Triggers OnConfigChanged event
}
```

---

## Phase 7: Update Playwright Tests

### Step 7.1: Remove Old Test Steps
**Remove from all tests:**
```csharp
// OLD - No longer needed
await Page.WaitForSelectorAsync(".splash-screen");
await Page.WaitForLoadStateAsync(LoadState.NetworkIdle); // for backend init
```

### Step 7.2: Add New Test Cases

**Test: Empty Pedalboard on Launch**
```csharp
[Test]
public async Task Journey_PedalboardLoads_OnAppLaunch_WithoutSplash()
{
    // Navigate to app
    await Page.GotoAsync(BlazorBaseUrl);
    
    // Assert no splash screen
    var splashScreen = Page.Locator(".splash-screen");
    Assert.That(await splashScreen.CountAsync(), Is.EqualTo(0));
    
    // Assert pedalboard visible
    var editor = Page.Locator(".pedalboard-editor");
    Assert.That(await editor.CountAsync(), Is.GreaterThan(0));
    
    // Assert audio config panels visible
    var inputPanel = Page.Locator(".input-config-panel");
    var outputPanel = Page.Locator(".output-config-panel");
    Assert.That(await inputPanel.CountAsync(), Is.GreaterThan(0));
    Assert.That(await outputPanel.CountAsync(), Is.GreaterThan(0));
}
```

**Test: Audio Config Updates Connections**
```csharp
[Test]
public async Task Journey_ConnectionUpdates_WhenAudioConfigChanges()
{
    // Navigate to app
    await Page.GotoAsync(BlazorBaseUrl);
    
    // Get initial connection display
    var initialConnections = await Page.Locator(".connection-viewer").CountAsync();
    
    // Change input device
    var inputDropdown = Page.Locator(".input-device-select");
    await inputDropdown.SelectOptionAsync("Built-in Microphone");
    
    // Wait for UI update
    await Page.WaitForTimeoutAsync(500);
    
    // Assert connections updated
    var updatedConnections = await Page.Locator(".connection-viewer").CountAsync();
    Assert.That(updatedConnections, Is.GreaterThan(0));
}
```

**Test: Audio Config Persists**
```csharp
[Test]
public async Task Journey_AudioConfig_PersistsAcrossReloads()
{
    // Navigate to app
    await Page.GotoAsync(BlazorBaseUrl);
    
    // Select input device
    var inputDropdown = Page.Locator(".input-device-select");
    await inputDropdown.SelectOptionAsync("USB Audio");
    
    // Reload page
    await Page.ReloadAsync();
    
    // Assert same device is selected
    var selectedValue = await inputDropdown.InputValueAsync();
    Assert.That(selectedValue, Contains.Substring("USB"));
}
```

### Step 7.3: Update Existing Tests
**Modify Journey_CreateBlankPedalboard_Via_UI:**
- Remove audio startup wait
- Remove splash screen check
- Add audio config panel visibility checks
- Keep plugin selection logic

**Modify Journey_EditPedalboard_ConnectionViewer_Integration:**
- Start with audio config panels already visible
- Verify they don't obstruct pedalboard
- Test connection updates on config change

---

## Implementation Checklist

### Phase 2: Splash Screen & Layout
- [ ] Remove splash screen component
- [ ] Update App.razor with new layout
- [ ] Create CSS for left/right panels
- [ ] Test layout responsiveness

### Phase 3: Audio Components
- [ ] Create InputConfigPanel component
- [ ] Create OutputConfigPanel component
- [ ] Create AudioConfigContext service
- [ ] Register AudioConfigContext in DI
- [ ] Test component rendering

### Phase 4: PedalboardEditor Updates
- [ ] Update to work without audio backend
- [ ] Add AudioConfigContext subscription
- [ ] Implement real-time connection updates
- [ ] Handle no-audio state
- [ ] Test empty pedalboard load

### Phase 5: ConnectionViewer Updates
- [ ] Add dynamic connection point generation
- [ ] Add RefreshConnectionsAsync method
- [ ] Update on config changes
- [ ] Test with various device configs

### Phase 6: Persistence
- [ ] Implement LocalStorage save/load
- [ ] Test persistence across reloads
- [ ] Handle missing config gracefully

### Phase 7: Testing
- [ ] Update all Playwright tests
- [ ] Create new test cases
- [ ] Test all devices available on system
- [ ] Test edge cases (no devices, etc.)

---

## Risk Assessment

### High Priority
- **Pedalboard must load without audio** - Critical for new flow
  - Mitigation: Thoroughly test with no devices connected
- **Connection display must update in real-time** - UX blocker
  - Mitigation: Use Blazor lifecycle events correctly

### Medium Priority
- **Audio persistence** - Nice to have initially
  - Mitigation: Fall back to defaults if load fails
- **Responsive panels** - UX polish
  - Mitigation: Test on multiple screen sizes

### Low Priority
- **Level meters** - Can be added later
- **Resizable panels** - Enhancement
- **Device hot-plugging** - Future feature

---

## Timeline Estimate

| Phase | Duration | Status |
|-------|----------|--------|
| Documentation | ✅ Done | Complete |
| Remove Splash | 30 min | Ready to start |
| Audio Components | 2 hours | After splash removed |
| Update Pedalboard | 1.5 hours | Parallel with components |
| Connection Updates | 1 hour | Depends on components |
| Persistence | 30 min | Can be last |
| Testing | 2 hours | Throughout |
| **Total** | **~7 hours** | **~1 workday** |

---

## Success Criteria

- ✅ No splash screen on app launch
- ✅ Empty pedalboard visible immediately
- ✅ Audio config panels visible on left and right
- ✅ Audio config changes update connections in real-time
- ✅ Audio config persists between sessions
- ✅ All existing functionality still works
- ✅ All Playwright tests pass (with updates)
- ✅ Responsive design works on mobile

---

## Next Steps

1. **Review & Approve** - User reviews this plan
2. **Start Phase 2** - Remove splash screen
3. **Implement in Order** - Follow phases 2-7
4. **Test Throughout** - Don't wait until end
5. **Deploy** - When all phases complete

---

**Ready to proceed?** Let me know when you'd like me to start implementation!
