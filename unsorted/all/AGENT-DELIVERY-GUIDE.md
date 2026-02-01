# Agent Delivery Guide

**Purpose:** Provides precise implementation requirements and acceptance criteria for Alsionyx.

**Last Updated:** January 2026

**Important References:**
- [03-ARCHITECTURE-AND-DESIGN.md](03-ARCHITECTURE-AND-DESIGN.md) - System architecture and design patterns
- [Testing_Workflow.md](Testing_Workflow.md) - Complete testing requirements and patterns (REQUIRED reading)
- [IMPLEMENTATION-ROADMAP.md](IMPLEMENTATION-ROADMAP.md) - Phase definitions and deliverables

All testing must follow [Testing_Workflow.md](Testing_Workflow.md) conventions. This is the authoritative source for test structure, mock patterns, and coverage requirements.

---

## Table of Contents

1. [Delivery Standards](#delivery-standards)
2. [Phase 1: Core Audio System](#phase-1-core-audio-system)
3. [Phase 2: Pedalboard System & UI](#phase-2-pedalboard-system--ui)
4. [Phase 3: Polish & Extended Backends](#phase-3-polish--extended-backends)
5. [Quality Criteria](#quality-criteria)
6. [Common Mistakes](#common-mistakes)

---

## Delivery Standards

### Definition of "Complete"

A feature is **COMPLETE** when:

1. **Code Implementation**
   - All interfaces/classes implemented per specification
   - No TODO comments in code
   - All methods have proper error handling
   - All async operations use await correctly
   - No mock code in production files (mocks only in test projects)

2. **Testing**
   - Unit tests for every public method
   - Integration tests for service interactions
   - Edge cases tested (null inputs, empty collections, errors)
   - Test coverage meets phase target (70%-80%)
   - All tests passing

3. **Documentation**
   - XML comments on all public types/methods
   - Complex logic has inline comments explaining "why"
   - Configuration requirements documented
   - Example usage in code comments for public APIs

4. **API Compliance**
   - All documented endpoints implemented
   - Request/response DTOs match specifications
   - HTTP status codes correct (200, 201, 400, 404, 500)
   - Error responses include meaningful messages

5. **Build Quality**
   - Code compiles with zero warnings
   - dotnet format applied
   - Build succeeds: `dotnet build src/Alsionyx.sln`

### Verification Checklist

Before declaring any step complete:

- All interfaces defined per specification
- All classes implement interfaces correctly
- All public methods have XML documentation
- Unit tests exist for each method
- Integration tests for service interactions
- API endpoints match specification exactly
- Response DTOs match specification
- Error handling for all edge cases
- dotnet format applied (zero warnings)
- dotnet build succeeds
- Test suite passes (100% green)
- Documentation updated

---

## Phase 1: Core Audio System

**What to Deliver:**
- Pluggable audio backend interface (IAudioBackend)
- Three implementations: SoundFlow, FileAudio, Mock
- Flexible routing engine (arbitrary port connections)
- LV2 plugin discovery system
- Plugin instance management
- Complete REST API for audio operations
- 80%+ test coverage

**Definition of Done:**
- All 3 backends implement IAudioBackend correctly
- Routing prevents feedback loops and validates connections
- Plugin discovery finds 100+ real LV2 plugins
- Plugin metadata and modgui systems working
- API endpoints return correct data
- 80%+ test coverage across all components
- Zero compiler warnings
- All tests passing

**Key Interfaces to Implement:**

`IAudioBackend.cs`:
- EnumerateDevicesAsync()
- GetDeviceDetailsAsync(deviceId)
- GetSupportedFormatsAsync(deviceId)
- SelectDeviceAsync(deviceId)
- ConnectPortsAsync(source, destination)
- DisconnectPortsAsync(source, destination)
- GetAvailableControlsAsync()
- GetControlValueAsync(controlId)
- SetControlValueAsync(controlId, value)

`IPluginService.cs`:
- GetAllPluginsAsync()
- GetPluginAsync(uri)
- CreateInstanceAsync(uri)
- GetInstanceAsync(instanceId)
- SetParameterAsync(instanceId, parameterId, value)
- GetParameterAsync(instanceId, parameterId)

**API Endpoints (minimum):**
- GET /api/audio/backends - List available backends
- GET /api/audio/backends/{name} - Get backend details
- GET /api/audio/devices - List devices for active backend
- GET /api/plugins - List all plugins
- GET /api/plugins/{uri} - Get plugin details
- GET /api/plugins/{uri}/modgui - Get modgui UI data
- POST /api/plugins/{uri}/instances - Create plugin instance
- PUT /api/plugins/{uri}/instances/{id}/parameters/{paramId} - Set parameter

**Testing Requirements:**
- Refer to [Testing_Workflow.md](Testing_Workflow.md) for complete testing requirements and patterns
- Unit tests for each backend (minimum 15 per class)
- Unit tests for routing engine and validation
- Unit tests for plugin discovery (TTL parsing)
- Unit tests for modgui parsing
- Unit tests for plugin instance management
- Integration tests with mock audio system
- Integration tests with mock LV2 directory
- API integration tests for all endpoints
- Performance tests for plugin discovery
- E2E Playwright test for FileAudio workflow
- Mock audio backend used for ALL tests (no real hardware)
- Error scenario testing
- Test coverage target: 80%

---

## Phase 2: Pedalboard System & UI

**What to Deliver:**
- Pedalboard service with full CRUD operations
- Signal routing with connection validation
- Blazor UI components for pedalboard editing
- Real-time WebSocket synchronization
- Backend controls UI
- 70%+ test coverage

**Definition of Done:**
- Pedalboards create/load/save without errors
- Effects can be added/removed from chains
- Port connections work with feedback loop prevention
- UI components render correctly
- Real-time updates via WebSocket working
- Backend controls display correctly
- 70%+ test coverage
- Zero compiler warnings
- All tests passing

**Key Components to Build:**

`IPedalboardService.cs`:
- CreatePedalboardAsync(name)
- LoadPedalboardAsync(id)
- SavePedalboardAsync(pedalboard)
- DeletePedalboardAsync(id)
- AddEffectAsync(pedalboardId, pluginUri)
- RemoveEffectAsync(pedalboardId, instanceId)
- ConnectEffectsAsync(pedalboardId, source, destination)

Blazor Components:
- PedalboardPage.razor - Main container
- EffectsRack.razor - Effect chain display
- EffectSlot.razor - Individual effect with controls
- AvailableEffectsPanel.razor - Effect browser
- ConnectionVisualizer.razor - Visual wire display
- BackendControlsPanel.razor - Backend settings

**API Endpoints (minimum):**
- GET /api/pedalboards - List pedalboards
- POST /api/pedalboards - Create pedalboard
- GET /api/pedalboards/{id} - Get pedalboard
- DELETE /api/pedalboards/{id} - Delete pedalboard
- POST /api/pedalboards/{id}/effects - Add effect
- DELETE /api/pedalboards/{id}/effects/{instanceId} - Remove effect
- POST /api/pedalboards/{id}/connections - Create connection
- DELETE /api/pedalboards/{id}/connections - Delete connection
- PUT /api/pedalboards/{id}/effects/{instanceId}/parameters/{paramId} - Set effect parameter

**WebSocket Hub:**
- Connection updates pushed to all clients
- Effect parameter changes broadcast
- Effect add/remove notifications
- Real-time UI refresh without page reload

**Testing Requirements:**
- Refer to [Testing_Workflow.md](Testing_Workflow.md) for complete testing requirements and patterns
- Component unit tests with parameter verification
- Service integration tests with mocked backend
- API integration tests with WebApplicationFactory
- E2E tests with Playwright for UI interactions
- Real-time sync verification tests
- Test all 4 backend control types (Slider, Toggle, Enum, Textbox)
- SignalR/WebSocket tests for real-time updates
- Test coverage target: 70%

---

## Phase 3: Polish & Extended Backends

**What to Deliver:**
- Control presets and templates system
- Undo/redo functionality
- Keyboard shortcuts
- Performance optimization
- Undo/redo functionality
- Keyboard shortcuts
- Performance optimization
- JACK backend implementation
- ASIO backend implementation
- 70%+ test coverage

**Definition of Done:**
- Undo/redo works for all operations
- All keyboard shortcuts respond correctly
- Performance optimized for 50+ effects without glitches
- Both new backends functional
- 70%+ test coverage
- Zero compiler warnings
- All tests passing

**Undo/Redo System:**
- Track all operations (add effect, remove effect, connect, disconnect, parameter change)
- Undo/redo stack management
- Keyboard shortcuts (Ctrl+Z, Ctrl+Y)
- Visual indicators for undo/redo state

**Keyboard Shortcuts:**
- Ctrl+S: Save pedalboard
- Ctrl+Z: Undo
- Ctrl+Y: Redo
- Ctrl+N: New pedalboard
- Delete: Remove selected effect
- Tab: Next effect/parameter
- Shift+Tab: Previous effect/parameter

**Performance Optimization:**
- Connection caching to avoid repeated lookups
- Control value caching to reduce API calls
- Optimized parameter updates (batch where possible)
- Verified: 50+ effects without audio glitches

**Extended Backends:**

JACK Backend:
- Implement IAudioBackend
- JACK client initialization and connection
- Port management and dynamic routing
- Real-time audio scheduling
- Error handling (server unavailable)
- Device enumeration from JACK
- 12+ unit tests per Testing_Workflow.md
- Integration tests with audio routing

ASIO Backend (Windows):
- Implement IAudioBackend
- ASIO driver integration
- Buffer management and sizing
- Low-latency device configuration
- Windows device enumeration
- Device capability detection
- 12+ unit tests per Testing_Workflow.md
- Integration tests

**Testing Requirements:**
- Refer to [Testing_Workflow.md](Testing_Workflow.md) for complete testing requirements and patterns
- Unit tests for undo/redo stack operations
- Unit tests for keyboard shortcut handling
- Unit tests for all new backend implementations
- Integration tests for JACK backend with port management
- Integration tests for ASIO backend
- Performance benchmark tests (verify 50+ effects)
- E2E tests for undo/redo workflows
- E2E tests for keyboard shortcuts
- Test coverage target: 70%+

---

## Quality Criteria

### Universal Requirements

#### Code Quality
- Zero compiler warnings
- dotnet format applied
- StyleCop compliance
- No TODO comments left behind
- Proper async/await usage
- Null reference handling

#### Testing
- Unit tests for all public methods
- Integration tests for service interactions
- Edge case coverage
- Error scenario testing
- Mock usage (no real hardware)
- Phase target coverage met

#### Documentation
- XML comments on all public types
- Complex logic has inline comments
- README files updated
- Configuration documented
- Example code provided

#### Build & Deployment
- Solution builds successfully
- All tests pass
- No runtime warnings
- Graceful error handling
- Meaningful error messages

### Performance Requirements

| Operation | Target |
|-----------|--------|
| Plugin discovery | <2s for 100+ plugins |
| Pedalboard load | <500ms |
| Parameter change | <50ms |
| Connection create | <100ms |
| UI component render | <200ms |

---

## Common Mistakes

### Incomplete Testing

Mistake: Writing unit tests but skipping integration tests

Fix: Include integration tests, test mocks + real code paths

### Production Code in Tests

Mistake: Mock implementations or test data in production files

Fix: ALL mocks in test projects ONLY. Use Substitute.For<T>

### Incomplete Error Handling

Mistake: Happy path only, errors throw NotImplementedException

Fix: Handle all error cases, return meaningful messages

### Missing Async/Await

Mistake: Async methods written as sync with .Wait() or .Result

Fix: Use await everywhere, ensure methods marked async

### No Documentation

Mistake: Code written without XML comments or inline documentation

Fix: Document all public APIs, explain "why" not just "what"

### Large Monolithic Tests

Mistake: Single test method testing multiple features

Fix: One assertion per test ideally, clear test names

### Hardcoded Values

Mistake: Magic strings/numbers in code

Fix: All constants in ApplicationConstants.cs, configuration classes

---

## Pre-Implementation Checklist

Before starting ANY phase:

- Read entire phase specification
- Review related code in 11-COMPLETE-REBUILD-SPECIFICATION.md
- Create feature branch from latest main
- Set up test project structure
- Run existing tests to verify baseline
- Check build succeeds before starting
- Document any questions in ticket

---

## Acceptance Process

1. **Self-Review:**
   - All deliverables completed
   - Tests passing locally
   - Build successful
   - Documentation updated
   - No compiler warnings

2. **Code Review:**
   - Peer reviews code
   - Tests verify functionality
   - Documentation checked
   - Performance acceptable

3. **Integration Testing:**
   - Full test suite passes
   - No regressions
   - E2E tests if applicable
   - Performance benchmarks met

4. **Final Verification:**
   - Build succeeds on CI/CD
   - All checks pass
   - Merge to main

---

**Last Review:** January 26, 2026
