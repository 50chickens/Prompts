# Running the Pedalboard Creation Test

## Prerequisites

Before running the test, ensure you have:
- .NET 9.0 SDK installed
- All NuGet packages restored: `dotnet restore`
- Project built in Debug mode: `dotnet build`

## Test: Journey_CreateBlankPedalboard_Via_UI

This comprehensive Playwright test validates the complete workflow for creating a blank pedalboard through the UI, including verification that the SoundFlow backend is available in the dropdown.

### What the Test Does

1. Navigates to the Pedalboards page
2. Opens the "Create New Pedalboard" dialog
3. Enters a unique pedalboard name
4. **Verifies SoundFlow backend is available** ✅
5. Selects the SoundFlow backend
6. Submits the form
7. Verifies the new pedalboard appears in the list
8. Verifies the Edit button is functional

### Running the Test

#### Option 1: Run Test Only (Requires API + UI Running)

**Terminal 1 - Start the API**:
```powershell
cd c:\git\internal\Alsionyx\src
dotnet run --project Alsionyx.Api
# API will be available at http://localhost:5014
```

**Terminal 2 - Start the Blazor UI**:
```powershell
cd c:\git\internal\Alsionyx\src
dotnet run --project Alsionyx.BlazorUI
# Blazor UI will be available at http://localhost:5002
```

**Terminal 3 - Run the Test**:
```powershell
cd c:\git\internal\Alsionyx\src
dotnet test Alsionyx.PlaywrightTests --filter "Journey_CreateBlankPedalboard_Via_UI" --verbosity detailed
```

#### Option 2: Run Full Test Suite

```powershell
cd c:\git\internal\Alsionyx\src
dotnet build  # Ensure build succeeds
dotnet test   # Run all tests
```

### Test Configuration

The test uses default URLs:
- **API**: http://localhost:5014 (set via `API_BASE_URL` environment variable)
- **Blazor UI**: http://localhost:5002 (set via `BLAZOR_BASE_URL` environment variable)

To override:
```powershell
$env:BLAZOR_BASE_URL = "http://myserver:5002"
$env:API_BASE_URL = "http://myserver:5014"
dotnet test Alsionyx.PlaywrightTests --filter "Journey_CreateBlankPedalboard_Via_UI"
```

### Expected Output

```
Passed Journey_CreateBlankPedalboard_Via_UI [timestamp]
All tests passed successfully
```

### Debug Output

The test captures screenshots at each step:
```
screenshots/Journey_CreateBlankPedalboard_Via_UI/
├── 01-pedalboards-page-loaded.png
├── 02-create-dialog-opened.png
├── 03-name-entered.png
├── 04-backend-selected.png
├── 05-pedalboard-created.png
├── 06-pedalboard-in-list.png
├── 07-edit-button-visible.png
└── 08-pedalboard-created-success.png
```

### Troubleshooting

#### Test Fails - "SoundFlow backend should be available"

This means the backend dropdown doesn't contain "SoundFlow". Check:

1. **API is running** - Verify API started successfully on localhost:5014
2. **Backend registered** - Check that ApiContainerBuilder.cs registers SoundFlowAudioBackend
3. **API test endpoints** - Manually test:
   ```bash
   curl http://localhost:5014/api/audio/backends
   ```
   Should return:
   ```json
   [
     {"name":"SoundFlow","displayName":"SoundFlow","available":true,"isDefault":false},
     {"name":"FileAudio","displayName":"FileAudio","available":true,"isDefault":false}
   ]
   ```

#### Test Fails - "Cannot navigate to [URL]"

The Blazor UI is not running. Make sure to start it in a separate terminal:
```powershell
cd c:\git\internal\Alsionyx\src
dotnet run --project Alsionyx.BlazorUI
```

#### Test Fails - Browser Timeout

Playwright couldn't find elements within 5 seconds. This could mean:
- Page is loading slowly
- UI structure changed
- CSS selectors are incorrect

Enable headless=false to watch the browser:
```powershell
$env:HEADLESS = "false"
dotnet test Alsionyx.PlaywrightTests --filter "Journey_CreateBlankPedalboard_Via_UI"
```

### Test Anatomy

```csharp
[Test]
public async Task Journey_CreateBlankPedalboard_Via_UI()
{
    var pedalboardName = $"Test Pedalboard {Guid.NewGuid():N}";
    var blazorUrl = TestConfiguration.BlazorBaseUrl;

    // Step 1-4: Navigate and verify form elements
    
    // Step 5: Key verification - SoundFlow backend availability
    var hasSoundFlow = optionTexts.Any(opt => opt.Contains("SoundFlow", StringComparison.OrdinalIgnoreCase));
    Assert.That(hasSoundFlow, Is.True, "SoundFlow backend should be available in dropdown");
    
    // Step 6-8: Select backend, create, verify result
}
```

### Key Assertions

| Assertion | Purpose | Failure Meaning |
|-----------|---------|-----------------|
| `hasSoundFlow` | SoundFlow in dropdown | Backend not registered in API |
| `createdCard` | Pedalboard in list | Create API endpoint failed |
| `editButton` | Edit available | Form validation issue |
| `statusBadge` | Shows "Stopped" | Backend state tracking issue |

### Performance

Expected test duration: **10-15 seconds**

Timing breakdown:
- Page navigation: 1-2s
- Dialog open: 0.5s
- Form fill: 0.5s
- API create call: 2-3s
- List reload: 1-2s
- Assertions: <1s
- Screenshots: 2-3s

### Next Steps

After test passes:
1. ✅ Verify SoundFlow backend is available in dropdown
2. Create a pedalboard manually through the UI
3. Navigate to the pedalboard editor
4. Test adding effects from the AvailableEffectsPanel
5. Verify audio workflow components work correctly

### Debugging Code

To debug interactively, modify the test to wait for browser interaction:

```csharp
// Add before assertions to inspect state
await Page.PauseAsync();  // Pauses and opens debugger

// Or take screenshot to save current state
await Page.ScreenshotAsync(new() { Path = "debug.png", FullPage = true });
```

### Documentation

- [Complete Fix Summary](AUDIO-BACKEND-FIX-SUMMARY.md)
- [Testing Workflow](docs/Testing_Workflow.md)
- [UI Components Architecture](docs/13-UI-COMPONENTS-ARCHITECTURE.md)
- [Testing Strategy](docs/05-TESTING-STRATEGY.md)
