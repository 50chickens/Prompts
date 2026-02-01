# Avalonia Testing Library & Client App

## Overview

This package contains:

1. **Alsionyx.Library.Avalonia.Nunit** - A reusable testing library for Avalonia applications using NUnit and the headless platform
2. **Alsionyx.App.Client** - A sample Avalonia desktop application that displays audio backends
3. **Alsionyx.App.Client.Tests** - Comprehensive unit and UI tests for the Avalonia client app

## Alsionyx.Library.Avalonia.Nunit

### Features

- **AvaloniaTestBase** - Base class for all Avalonia NUnit tests
- **Headless Platform Support** - Run tests without a display server
- **Mock Audio Backend Objects** - Pre-built mock audio backend for testing without API calls
- **Dispatcher Helpers** - Utilities for running code in the Avalonia dispatcher context

### Key Components

#### AvaloniaTestBase Class

```csharp
public abstract class AvaloniaTestBase
{
    [SetUp]
    public void AvaloniaSetUp() { }
    
    [TearDown]
    public void AvaloniaCleanUp() { }
    
    protected void RunInDispatcher(Action action) { }
    protected async Task RunInDispatcherAsync(Func<Task> action) { }
}
```

**Usage:**

```csharp
[TestFixture]
public class MyComponentTests : AvaloniaTestBase
{
    [Test]
    public void MyComponent_DoesX_WhenY()
    {
        // Test code here
    }
}
```

#### MockAudioBackend Class

Represents a single audio backend for testing:

```csharp
public class MockAudioBackend
{
    public string Name { get; set; }                // e.g., "SoundFlow", "ALSA"
    public bool IsAvailable { get; set; }           // System availability
    public bool IsRunning { get; set; }             // Current running state
    public string? Status { get; set; }             // Status message
}
```

**Default Backends:**
- SoundFlow (Available)
- ALSA (Available)
- FileAudio (Available)
- ASIO (Not available)
- JACK (Not available)

#### MockAudioBackendProvider Class

Provides managed access to mock audio backends:

```csharp
public class MockAudioBackendProvider
{
    public IEnumerable<MockAudioBackend> GetAllBackends();
    public IEnumerable<MockAudioBackend> GetAvailableBackends();
    public IEnumerable<MockAudioBackend> GetRunningBackends();
    public MockAudioBackend? GetBackendByName(string name);
    public void AddBackend(MockAudioBackend backend);
    public bool RemoveBackend(string name);
    public bool SetBackendRunningState(string name, bool isRunning);
    public void ClearBackends();
}
```

**No API Calls** - All data is provided locally, no HTTP requests to a backend API.

### Usage Example

```csharp
using NUnit.Framework;
using Alsionyx.Library.Avalonia.Nunit;
using Alsionyx.Library.Avalonia.Nunit.Mocks;

[TestFixture]
public class AudioBackendTests : AvaloniaTestBase
{
    private MockAudioBackendProvider _provider;

    [SetUp]
    public void Setup()
    {
        _provider = new MockAudioBackendProvider();
    }

    [Test]
    public void Provider_HasDefaultBackends()
    {
        var backends = _provider.GetAllBackends();
        Assert.That(backends.Count(), Is.EqualTo(5));
    }

    [Test]
    public void Provider_CanSelectBackend()
    {
        var result = _provider.SetBackendRunningState("SoundFlow", true);
        Assert.That(result, Is.True);
    }
}
```

---

## Alsionyx.App.Client

### Overview

A sample Avalonia desktop application demonstrating the audio backend selector component.

### Features

- **AudioBackendSelector** - Reusable component for selecting audio backends
- **Reactive UI** - Built with ReactiveUI for MVVM pattern
- **Type-Safe Binding** - Strongly-typed view models with no code-behind logic
- **No API Calls** - Uses local mock data for audio backends

### Architecture

```
┌─────────────────────────────────────────┐
│          MainWindow.xaml                 │
│  ┌───────────────────────────────────┐  │
│  │  Title & Description              │  │
│  │  ┌─────────────────────────────┐  │  │
│  │  │ AudioBackendSelector        │  │  │
│  │  │ (ComboBox + Details)        │  │  │
│  │  └─────────────────────────────┘  │  │
│  │  ┌─────────────────────────────┐  │  │
│  │  │ Status Panel                │  │  │
│  │  └─────────────────────────────┘  │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

### Key Components

#### MainWindow

The main application window displaying:
- Application title
- Description text
- AudioBackendSelector component
- Status information panel

#### AudioBackendSelector Component

User control featuring:
- ComboBox listing available audio backends
- Details panel showing selected backend information
- Backend status (Available/Running)
- Description display

#### AudioBackendSelectorViewModel

Manages the presentation logic:
- Backend list management
- Selection state
- Backend filtering
- Data binding for UI

### Running the Application

```bash
cd src
dotnet run --project Alsionyx.App.Client
```

The application will start with the MainWindow showing available audio backends. Select any backend from the dropdown to view its details.

---

## Alsionyx.App.Client.Tests

### Test Suites

#### 1. AudioBackendSelectorViewModelTests

Tests the view model logic:

```csharp
[TestFixture]
public class AudioBackendSelectorViewModelTests
{
    [Test]
    public void Constructor_InitializesWithDefaultBackends() { }
    
    [Test]
    public void Constructor_SetsFirstBackendAsSelected() { }
    
    [Test]
    public void GetAvailableBackends_ReturnsOnlyAvailableBackends() { }
    
    [Test]
    public void SelectBackendByName_WithValidName_SelectsBackend() { }
    
    [Test]
    public void SelectBackendByName_WithInvalidName_ReturnsFalse() { }
    
    [Test]
    public void CustomBackends_CanBeInitialized() { }
}
```

#### 2. AudioBackendSelectorComponentTests

Tests the Avalonia UI component:

```csharp
[TestFixture]
public class AudioBackendSelectorComponentTests : AvaloniaTestBase
{
    [Test]
    public void Component_IsCreated() { }
    
    [Test]
    public void Component_HasViewModel() { }
    
    [Test]
    public void Component_ViewModelHasBackends() { }
    
    [Test]
    public void Component_CanSelectBackend() { }
    
    [Test]
    public void Component_ShowsSoundFlowByDefault() { }
}
```

#### 3. MockAudioBackendProviderTests

Tests the mock provider:

```csharp
[TestFixture]
public class MockAudioBackendProviderTests
{
    [Test]
    public void Constructor_InitializesWithDefaultBackends() { }
    
    [Test]
    public void GetAvailableBackends_ReturnsOnlyAvailable() { }
    
    [Test]
    public void SetBackendRunningState_ChangesRunningState() { }
    
    [Test]
    public void CustomBackends_CanBeInitialized() { }
}
```

### Running Tests

```bash
cd src
dotnet test Alsionyx.App.Client.Tests
```

Or run specific test class:

```bash
dotnet test Alsionyx.App.Client.Tests --filter "AudioBackendSelectorViewModelTests"
```

---

## Architecture Decisions

### 1. No Real API Calls

The client and testing library use local mock data instead of calling a backend API:

- ✅ **Advantages:**
  - Tests run offline
  - No network dependencies
  - Faster test execution
  - Reproducible results

- **API Integration:**
  - When ready to integrate with the real API, replace `MockAudioBackendProvider` with an `HttpAudioBackendProvider`
  - Keep the same interface for seamless integration

### 2. Headless Avalonia Platform

Tests use Avalonia's headless platform for:

- Running on CI/CD servers without a display
- Parallel test execution
- Consistent behavior across platforms
- No X11/Wayland dependencies

### 3. MVVM Pattern

The application follows the MVVM (Model-View-ViewModel) pattern:

- **View** - AudioBackendSelector.axaml (XAML UI)
- **ViewModel** - AudioBackendSelectorViewModel (Logic, state, commands)
- **Model** - AudioBackendItem (Data representation)

Benefits:
- Testable logic (view models tested without UI)
- Reusable components
- Data binding support
- Separation of concerns

---

## Future Enhancements

### 1. API Integration

Replace mock provider with real API provider:

```csharp
public interface IAudioBackendProvider
{
    Task<IEnumerable<AudioBackend>> GetBackendsAsync();
}

// Mock implementation (for tests)
public class MockAudioBackendProvider : IAudioBackendProvider { }

// Real implementation (for production)
public class HttpAudioBackendProvider : IAudioBackendProvider
{
    private readonly HttpClient _client;
    // Calls /api/audio/backends endpoint
}
```

### 2. Real-Time Updates

Add WebSocket support for real-time backend status updates:

```csharp
var hubConnection = new HubConnectionBuilder()
    .WithUrl("https://localhost:5000/hub/audio-backends")
    .WithAutomaticReconnect()
    .Build();

hubConnection.On<AudioBackend>("BackendStatusChanged", backend =>
{
    // Update UI
});
```

### 3. Error Handling

Add resilience patterns:

- Retry logic with exponential backoff
- Circuit breaker for failed API calls
- Fallback to mock data when API is unavailable
- User-friendly error messages

### 4. Themes and Customization

Extend with:

- Dark/Light theme support
- Custom color schemes
- Audio backend icons
- Detailed status and diagnostics

---

## File Structure

```
Alsionyx.Library.Avalonia.Nunit/
├── AvaloniaTestBase.cs              # Base class for all tests
├── Mocks/
│   ├── MockAudioBackend.cs          # Audio backend mock
│   └── MockAudioBackendProvider.cs  # Mock provider
└── Alsionyx.Library.Avalonia.Nunit.csproj

Alsionyx.App.Client/
├── App.xaml                          # Application root
├── App.xaml.cs
├── MainWindow.xaml                   # Main window
├── MainWindow.axaml.cs
├── AudioBackendSelector.xaml         # Component
├── AudioBackendSelector.xaml.cs
├── ViewModels/
│   └── AudioBackendSelectorViewModel.cs
├── Program.cs
└── Alsionyx.App.Client.csproj

Alsionyx.App.Client.Tests/
├── AudioBackendSelectorViewModelTests.cs
├── AudioBackendSelectorComponentTests.cs
├── MockAudioBackendProviderTests.cs
└── Alsionyx.App.Client.Tests.csproj
```

---

## Getting Started

### Build

```bash
cd src
dotnet build
```

### Test

```bash
dotnet test Alsionyx.App.Client.Tests
```

### Run

```bash
dotnet run --project Alsionyx.App.Client
```

### Add to Your Project

To use the testing library in another Avalonia project:

```xml
<ItemGroup>
    <ProjectReference Include="..\Alsionyx.Library.Avalonia.Nunit\Alsionyx.Library.Avalonia.Nunit.csproj" />
</ItemGroup>
```

Then create test classes inheriting from `AvaloniaTestBase`:

```csharp
[TestFixture]
public class MyComponentTests : AvaloniaTestBase
{
    [Test]
    public void Test_DoesX() { }
}
```

---

## Dependencies

### Core

- .NET 9.0
- Avalonia 11.0.10
- ReactiveUI 19.5.41

### Testing

- NUnit 4.1.0
- Avalonia.Headless.NUnit 11.0.10
- NSubstitute 5.1.0
- FluentAssertions 6.12.0

---

## Notes

- The testing library does not include any real Alsionyx Core or API dependencies
- Mock backends are configured to simulate realistic behavior
- The component supports data binding for reactive UI updates
- All tests run headlessly without requiring X11/display server
- The application can be extended with real API integration without modifying test structure

