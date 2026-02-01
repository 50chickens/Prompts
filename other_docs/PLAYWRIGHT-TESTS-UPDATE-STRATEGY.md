# Playwright Test Strategy Update: Audio Configuration First

## Overview

The Playwright tests need significant updates to reflect the new architecture where:
1. App launches without splash screen
2. Empty pedalboard is visible immediately
3. Audio config is optional and done via UI panels
4. Connection display updates dynamically

---

## Current Tests to Modify

### 1. Journey_CreateBlankPedalboard_Via_UI()

**Current Flow:**
```
1. Navigate to /pedalboards page
2. Create new pedalboard
3. Select backend
4. See dropdown with SoundFlow
5. Create pedalboard
```

**New Flow:**
```
1. Navigate to app (should show pedalboard immediately, no splash)
2. Audio config panels visible on left/right
3. (Optional) Select input device from left panel
4. (Optional) Select output device from right panel
5. Create new pedalboard (can do this at any time)
6. Plugin dropdown should work regardless of audio config
```

**Changes Needed:**
- Remove wait for `/pedalboards` page navigation
- Remove audio config/backend selection steps (now in panels)
- Verify audio panels are visible
- Test can happen with or without audio selected
- Check that connection display updates

### 2. Journey_EditPedalboard_ConnectionViewer_Integration()

**Current:**
- Creates pedalboard
- Opens editor
- Verifies ConnectionViewer renders

**New:**
- Opens app (pedalboard editor is main view)
- Verifies audio panels are visible
- Changes input device in left panel
- Verifies ConnectionViewer updates
- Changes output device in right panel
- Verifies ConnectionViewer updates again

**Key Addition:**
- Add test for real-time connection updates on config change

---

## New Tests to Add

### Test 1: No Splash Screen, Pedalboard Immediate

```csharp
[Test]
public async Task Journey_AppLaunches_NoSplash_PedalboardImmediate()
{
    // Act: Navigate to app
    await Page.GotoAsync(TestConfiguration.BlazorBaseUrl);
    
    // Assert: No splash screen
    var splashScreen = Page.Locator(".splash-screen, [data-testid='splash-screen']");
    Assert.That(await splashScreen.CountAsync(), Is.EqualTo(0), 
        "Should not show splash screen on launch");
    
    // Assert: Pedalboard editor visible
    var pedalboardEditor = Page.Locator(".pedalboard-editor, [data-testid='pedalboard-editor']");
    Assert.That(await pedalboardEditor.CountAsync(), Is.GreaterThan(0),
        "Pedalboard editor should be visible immediately");
    
    // Assert: Audio config panels visible
    var inputPanel = Page.Locator(".input-config-panel, [data-testid='input-panel']");
    var outputPanel = Page.Locator(".output-config-panel, [data-testid='output-panel']");
    
    Assert.That(await inputPanel.CountAsync(), Is.GreaterThan(0),
        "Input config panel should be visible on left side");
    Assert.That(await outputPanel.CountAsync(), Is.GreaterThan(0),
        "Output config panel should be visible on right side");
    
    await CaptureStepAsync(1, "app-launch-no-splash-pedalboard-immediate");
}
```

### Test 2: Audio Config Updates Connections

```csharp
[Test]
public async Task Journey_Connections_UpdateWhen_AudioConfigChanges()
{
    // Arrange: Navigate to app
    await Page.GotoAsync(TestConfiguration.BlazorBaseUrl);
    await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);
    
    // Get initial connection display (may be empty)
    var connectionViewer = Page.Locator(".connection-viewer, [data-testid='connection-viewer']");
    var initialConnectionText = await connectionViewer.TextContentAsync();
    await CaptureStepAsync(1, "initial-state");
    
    // Act: Change input device
    var inputDeviceSelect = Page.Locator("select[data-testid='input-device-select'], .input-device-select");
    var optionCount = await inputDeviceSelect.Locator("option").CountAsync();
    
    if (optionCount > 1) // Only test if multiple devices available
    {
        // Get first available device option (skip default)
        var options = await inputDeviceSelect.Locator("option").AllAsync();
        var deviceName = await options[1].TextContentAsync();
        
        await inputDeviceSelect.SelectOptionAsync(new[] { deviceName });
        await Page.WaitForTimeoutAsync(500); // Allow UI to update
        await CaptureStepAsync(2, "selected-input-device");
        
        // Assert: Connection display updated
        var updatedConnectionText = await connectionViewer.TextContentAsync();
        Assert.That(updatedConnectionText, Is.Not.EqualTo(initialConnectionText),
            "Connection display should update when input device changes");
        
        // Assert: Input info is displayed
        var connectionContent = await connectionViewer.InnerTextAsync();
        Assert.That(connectionContent, Does.Contain(deviceName).IgnoreCase,
            "Connection display should show selected input device");
    }
    
    await CaptureStepAsync(3, "connections-updated");
}
```

### Test 3: Panels are Minimized (Not Hidden)

```csharp
[Test]
public async Task Journey_AudioPanels_AreMinimized_ButVisible()
{
    // Arrange: Navigate to app
    await Page.GotoAsync(TestConfiguration.BlazorBaseUrl);
    await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);
    
    // Act: Check input panel dimensions and visibility
    var inputPanel = Page.Locator(".input-config-panel, [data-testid='input-panel']");
    var inputBBox = await inputPanel.BoundingBoxAsync();
    
    Assert.That(inputBBox, Is.Not.Null, "Input panel should exist");
    Assert.That(inputBBox.Width, Is.LessThan(200), "Input panel should be narrow (minimized)");
    Assert.That(inputBBox.Height, Is.GreaterThan(0), "Input panel should have some height");
    
    // Act: Check output panel dimensions and visibility  
    var outputPanel = Page.Locator(".output-config-panel, [data-testid='output-panel']");
    var outputBBox = await outputPanel.BoundingBoxAsync();
    
    Assert.That(outputBBox, Is.Not.Null, "Output panel should exist");
    Assert.That(outputBBox.Width, Is.LessThan(200), "Output panel should be narrow (minimized)");
    Assert.That(outputBBox.Height, Is.GreaterThan(0), "Output panel should have some height");
    
    // Assert: Pedalboard still has room (not completely obscured)
    var pedalboardEditor = Page.Locator(".pedalboard-editor, [data-testid='pedalboard-editor']");
    var pedalboardBBox = await pedalboardEditor.BoundingBoxAsync();
    
    Assert.That(pedalboardBBox.Width, Is.GreaterThan(400),
        "Pedalboard should have significant width despite panels");
    
    await CaptureStepAsync(1, "panels-minimized-visible");
}
```

### Test 4: Audio Config Persists Across Reloads

```csharp
[Test]
public async Task Journey_AudioConfig_PersistsAcrossPageReloads()
{
    // Arrange: Navigate to app
    await Page.GotoAsync(TestConfiguration.BlazorBaseUrl);
    await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);
    
    // Act: Select input device
    var inputDeviceSelect = Page.Locator("select[data-testid='input-device-select'], .input-device-select");
    var options = await inputDeviceSelect.Locator("option").AllAsync();
    
    if (options.Count > 1)
    {
        var selectedDeviceName = await options[1].TextContentAsync();
        await inputDeviceSelect.SelectOptionAsync(new[] { selectedDeviceName });
        await Page.WaitForTimeoutAsync(500);
        await CaptureStepAsync(1, "selected-device");
        
        // Act: Reload page
        await Page.ReloadAsync();
        await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);
        await CaptureStepAsync(2, "page-reloaded");
        
        // Assert: Same device is still selected
        var reloadedInputSelect = Page.Locator("select[data-testid='input-device-select'], .input-device-select");
        var selectedValue = await reloadedInputSelect.InputValueAsync();
        
        Assert.That(selectedValue, Does.Contain(selectedDeviceName).IgnoreCase,
            "Selected audio device should persist across page reload");
        
        await CaptureStepAsync(3, "config-persisted");
    }
}
```

### Test 5: Can Add Plugin Without Audio Config

```csharp
[Test]
public async Task Journey_CanAddPlugin_WithoutAudioConfig()
{
    // Arrange: Navigate to app (no audio config selected yet)
    await Page.GotoAsync(TestConfiguration.BlazorBaseUrl);
    await Page.WaitForLoadStateAsync(LoadState.NetworkIdle);
    
    // Verify no input device selected
    var inputDeviceSelect = Page.Locator("select[data-testid='input-device-select'], .input-device-select");
    var selectedInput = await inputDeviceSelect.InputValueAsync();
    
    if (string.IsNullOrEmpty(selectedInput) || selectedInput == "")
    {
        await CaptureStepAsync(1, "no-audio-configured");
        
        // Act: Click Add Plugin button
        var addPluginButton = Page.Locator("button:has-text('Add Plugin'), [data-testid='add-plugin-btn']");
        
        if (await addPluginButton.CountAsync() > 0)
        {
            await addPluginButton.ClickAsync();
            await Page.WaitForTimeoutAsync(500);
            await CaptureStepAsync(2, "plugin-dialog-opened");
            
            // Assert: Can see plugin options
            var pluginList = Page.Locator(".plugin-list, [data-testid='plugin-list']");
            Assert.That(await pluginList.CountAsync(), Is.GreaterThan(0),
                "Plugin list should be available even without audio config");
        }
    }
}
```

---

## Test Execution Sequence

### Before Implementation
```
1. Run current tests - Will FAIL (expecting old splash screen/flow)
2. Update tests according to new architecture
3. Verify tests still fail (code not changed yet)
```

### During Implementation
```
1. Phase 2 (Remove splash): Journey_AppLaunches_NoSplash_PedalboardImmediate passes
2. Phase 3-5 (Components): Panels visible tests pass
3. Phase 6 (Persistence): Config persistence test passes
4. Final: All tests pass together
```

### After Implementation
```
1. Run all tests - Should PASS
2. Run on CI/CD pipeline
3. Monitor for flakiness
```

---

## Data Test Attributes to Add

### To InputConfigPanel.razor
```html
<select data-testid="input-device-select" class="input-device-select">
    ...
</select>

<div class="input-config-panel" data-testid="input-panel">
    ...
</div>
```

### To OutputConfigPanel.razor
```html
<select data-testid="output-device-select" class="output-device-select">
    ...
</select>

<div class="output-config-panel" data-testid="output-panel">
    ...
</div>
```

### To PedalboardEditor.razor
```html
<div class="pedalboard-editor" data-testid="pedalboard-editor">
    ...
</div>

<button data-testid="add-plugin-btn">Add Plugin</button>
```

### To ConnectionViewer.razor
```html
<div class="connection-viewer" data-testid="connection-viewer">
    ...
</div>
```

---

## Test Maintenance

### Critical Tests (Must Always Pass)
1. App launch without splash
2. Pedalboard visible immediately
3. Audio panels visible
4. Can add plugins

### Important Tests (Should Pass)
1. Connection updates on config change
2. Audio config persists
3. Multiple device switching

### Nice-to-Have Tests (Can Add Later)
1. Responsive panel sizing
2. Level meter updates
3. Device hot-plugging

---

## Edge Cases to Test

### Device Availability
- [ ] No audio devices available
- [ ] Only input device available (no output)
- [ ] Only output device available (no input)
- [ ] Multiple devices of each type

### Config Persistence
- [ ] LocalStorage disabled
- [ ] Invalid stored config (missing device)
- [ ] Config from deleted device

### UI Interaction
- [ ] Rapidly changing devices
- [ ] Changing config while plugin is selected
- [ ] Changing config while playing

---

## Test Environment Setup

### Before Running Tests
```bash
# Ensure API is running
dotnet run --project Alsionyx.Api &

# Ensure Blazor UI is running
dotnet run --project Alsionyx.BlazorUI &

# Run tests
dotnet test Alsionyx.PlaywrightTests --filter "Journey_"
```

### Mock Devices for CI/CD
- May need to provide mock audio devices in test environment
- Or skip audio device tests if not available
- Document requirements in README

---

## Success Metrics

| Metric | Target | How to Measure |
|--------|--------|----------------|
| All tests pass | 100% | `dotnet test` exit code 0 |
| No flaky tests | 0 failures in 5 runs | Run tests 5x |
| Test coverage | >80% | Coverage report |
| Performance | <5sec per test | Test execution time |
| Device handling | Works with 0-3 devices | Test on various systems |

---

## Rollback Plan

If implementation causes issues:

1. **Revert code changes** - Git revert to last known good
2. **Restore old tests** - Use git history
3. **Deploy old version** - Users see original splash flow
4. **Post-mortem** - Document what failed

**Safe Point:** Save working tests to separate branch before starting

---

## Notes for Test Developer

1. **Use data-testid attributes** - More reliable than text selectors
2. **Wait for async operations** - Use WaitForTimeoutAsync for UI updates
3. **Capture screenshots** - At each major step
4. **Handle variable state** - Device availability varies per system
5. **Test on multiple devices** - Desktop, tablet, mobile layouts
6. **Document failures** - Record what went wrong for debugging

---

## Ready to Implement?

These tests are ready to be implemented. Recommend:

1. ✅ Review this document
2. ✅ Create new test branch: `feature/audio-config-tests`
3. ✅ Implement tests (they'll fail initially)
4. ✅ Implement code changes (tests will pass)
5. ✅ Deploy when all tests pass
