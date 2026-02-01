# Implementation Roadmap

Delivery phases for Alsionyx Audio Manager implementation.

**Important:** Refer to [03-ARCHITECTURE-AND-DESIGN.md](03-ARCHITECTURE-AND-DESIGN.md) for system design and [Testing_Workflow.md](Testing_Workflow.md) for testing requirements. All phases must follow these specifications for consistency.

---

## Current Implementation Status

### Phase 1: Core Audio System - ✅ COMPLETE
- ✅ IAudioBackend interface with 3 implementations (SoundFlow, FileAudio, Mock)
- ✅ Flexible multi-device routing implemented
- ✅ LV2 plugin discovery with modgui support
- ✅ Plugin instance management
- ✅ Full API layer for backends and plugins
- ✅ Comprehensive test coverage
- ✅ All required endpoints implemented

### Phase 2: Pedalboard System & UI - ✅ CORE COMPLETE (UI Update Done)

**Completed:**
- ✅ IPedalboardService with full CRUD operations
- ✅ Pedalboard creation, loading, saving, deletion
- ✅ Plugin/effect management (add, remove)
- ✅ Connection management (create, remove)
- ✅ All API endpoints for pedalboard operations
- ✅ Blazor components (EffectsRack, EffectSlot, AvailableEffectsPanel, ConnectionViewer, BackendControlsPanel)
- ✅ Basic CRUD operations via API

**Completed - UI/UX Update (NEW PATTERN):**
- ✅ **Home.razor refactored** to show blank pedalboard at homepage (`/`)
  - Users now see a blank, unsaved pedalboard interface immediately when opening the app
  - No need to navigate to `/pedalboards` first
  - Simplified UX: directly edit pedalboard on home page
  - "My Pedalboards" link available to navigate to saved pedalboards list
  - Architecture ready for future features (auto-load saved/template pedalboards)

- ✅ **Pedalboards.razor simplified**
  - Create dialog now only requires pedalboard name (no backend selector)
  - Backend selection is now optional, deferred to editor
  - Fixes old UX pattern where backend had to be selected before creation

- ✅ **PlaywrightTestBase.cs enhanced**
  - Added `BlazorUrl` property for dynamic TestServer URLs
  - Both API and Blazor UI run on same Kestrel server in tests
  - Removed hardcoded localhost addresses

- ✅ **Playwright tests updated**
  - Tests now use dynamic `BlazorUrl` from TestBase instead of hardcoded addresses
  - New `Journey_HomePage_LoadsBlankPedalboard` test validates home page accessibility
  - Test `Journey_CreateBlankPedalboard_Via_UI` validates simplified pedalboard creation pattern
  - **Test Results**: 4 of 5 Journey tests passing ✅
    - ✅ Journey_HomePage_LoadsBlankPedalboard (validates API accessible)
    - ✅ Journey_CreateBlankPedalboard_Via_UI (validates new pattern)
    - ✅ Journey_ManualTestingGuidance (documentation)
    - ✅ Journey_AudioBackend_Selection (audio backend discovery)
    - ⏳ Journey_EditPedalboard_ConnectionViewer_Integration (UI navigation test - not critical for home page feature)

**Not Yet Started:**
- ⏳ Real-time WebSocket synchronization (broadcast updates to all clients)
- ⏳ Advanced control types (Slider, Toggle, Enum, Textbox) in BackendControlsPanel
- ⏳ Parameter presets system
- ⏳ Pedalboard templates/favorites system
- ⏳ Auto-loading saved pedalboards at startup
- ⏳ Enhanced UI navigation on pedalboards list page

### Phase 3: Polish & Extended Backends - ⏳ NOT STARTED
- ⏳ All features listed below

---

## Phase 1: Core Audio System

Establish audio backends, plugin discovery, and API foundation.

**Deliverables:**
- IAudioBackend interface with 3 implementations (SoundFlow, FileAudio, Mock)
- Flexible multi-device routing
- Complete LV2 plugin discovery with modgui support
- Plugin instance management
- Full API layer for backends and plugins
- 80%+ test coverage
- FileAudio end-to-end workflow tested

**Backend Infrastructure to Deliver:**

IAudioBackend interface:
- Device management (enumerate, select, configure)
- Plugin/effect management (load, create instances, manage)
- Connection/routing (connect/disconnect ports, validate)
- Controls (get available, get value, set value)
- Monitoring (status, state queries)
- All methods async with proper error handling

SoundFlowAudioBackend implementation:
- Multi-device enumeration via SoundFlow
- Device format configuration
- Plugin loading and processing
- Real-time audio streaming with low latency
- Multi-device routing support
- Error handling for missing SoundFlow

FileAudioBackend implementation:
- .wav and .mp3 file input support
- Audio processing through plugin chain
- Output to .wav or .mp3 file
- Uses appropriate audio libraries
- Progress tracking during processing
- Proper resource cleanup

MockAudioBackend implementation:
- In-memory device list for testing
- Fake effect library
- Mock control values
- Deterministic responses for testing

Routing System:
- AudioRoutingConfiguration model
- IRoutingEngine service
- Support multiple backends simultaneously (input from one, output to another)
- Per-channel routing across devices
- Connection validation (prevent feedback loops)
- Port naming: "backend:device:port" format
- Connection persistence in Pedalboard model

API Endpoints:
- GET /api/audiobackends (list available backends)
- GET /api/audiobackends/{name} (backend details)
- GET /api/audiobackends/{name}/devices (connected devices)
- GET /api/routing (current routing configuration)
- POST /api/routing (update routing)

Plugin Discovery System:
- ILv2PluginDiscoverer interface
- Scan /usr/lib/lv2 and ~/.lv2 directories
- Parse plugin TTL metadata (RDF/Turtle format)
- Extract port information (audio, MIDI, control)
- Discover latency information
- Load modgui folder for each plugin
- Parse modgui.ttl metadata
- Load HTML templates (Mustache format)
- Load CSS stylesheets with sanitization
- Load JavaScript interaction code
- Map ports to UI elements

Plugin API Endpoints:
- GET /api/plugins (list all discovered plugins)
- GET /api/plugins/{uri} (plugin details with ports, latency, modgui)
- GET /api/plugins/{uri}/modgui (modgui HTML/CSS/JS)
- POST /api/plugins/rescan (rescan directories)

Plugin Instance Management:
- IPluginService interface
- Create plugin instances with unique IDs
- Manage parameters (get/set values)
- Load/save presets
- Handle bypass state
- Concurrent instance support
- Resource cleanup

Testing Requirements:
- Refer to [Testing_Workflow.md](Testing_Workflow.md) for complete testing requirements
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

UI Requirements:
- Backend selection dropdown in main layout
- Allow pedalboard creation without active backend
- Empty pedalboards creatable when no backend available
- Start/stop controls disabled when no backend active
- Backend indicator showing current selection

Definition of Done for Phase 1:
- All interfaces defined per specification (see 03-ARCHITECTURE-AND-DESIGN.md)
- All implementations complete and functional
- No TODO comments in code
- All error cases handled
- Async/await patterns correct throughout
- All public methods have XML documentation
- Unit tests for every public method (follow Testing_Workflow.md)
- Integration tests for service interactions
- Edge cases covered (null, empty, errors)
- Code compiles with zero warnings
- dotnet format applied
- All tests passing with 80%+ coverage

## Phase 2: Pedalboard System & UI

---

## Phase 2: Pedalboard System & UI (Detailed Specification)

### NEW UI/UX Requirement: Homepage Blank Pedalboard

**User Flow:**
1. User opens application (navigates to `/` or `/home`)
2. Homepage displays a blank, unsaved pedalboard interface
3. User can immediately:
   - Add effects from the AvailableEffectsPanel
   - Route connections between effects
   - Adjust effect parameters
   - Configure audio backend
4. User clicks "Save" to persist the pedalboard
5. User can load previously saved pedalboards from a dropdown or menu

**Architecture:**
- Generic `PedalboardLoader` service that determines which pedalboard to display
- Currently: Always returns a blank, temporary pedalboard (ID = "unsaved" or null)
- Future enhancement (not yet implemented): Support loading saved/template pedalboards
- Temporary pedalboards use in-memory storage (not persisted)
- Persisted when user clicks "Save"

**Implementation Details:**
- Modify `Home.razor` to show full PedalboardEditor component (not just marketing content)
- Remove or minimize marketing/hero section
- Create `PedalboardLoader` service interface:
  ```csharp
  public interface IPedalboardLoader
  {
      Task<PedalboardDto> GetInitialPedalboardAsync();
  }
  ```
- Default implementation returns temporary blank pedalboard
- Future: Can be extended to check user preferences, saved pedalboards, etc.

**Backwards Compatibility:**
- Keep `/pedalboards` page for managing saved pedalboards list
- Allow users to navigate to pedalboards management page
- "New Pedalboard" button should still work (but may redirect to home with new temp pedalboard)

### Build virtual pedalboard with complete user interface and controls.

**Deliverables:**
- Pedalboard service with full CRUD and workflow
- Complete Blazor UI for pedalboard management
- Real-time WebSocket synchronization
- Backend-specific controls system
- All API endpoints for pedalboard operations
- 70%+ test coverage

**Pedalboard Service to Deliver:**

IPedalboardService interface:
- Create pedalboard (name, backend selection)
- Load existing pedalboard (by ID)
- Save pedalboard state
- Get pedalboard details
- List all pedalboards
- Delete pedalboard
- Add effect to pedalboard (plugin instance)
- Remove effect from pedalboard
- Connect two effects (create port connection)
- Disconnect effects (remove port connection)
- Update effect parameter value
- Get connection list for pedalboard
- Validate connections (prevent feedback loops)

Signal Routing:
- Port connection in IAudioBackend: ConnectPortsAsync(fromPort, toPort)
- Port disconnection in IAudioBackend: DisconnectPortsAsync(fromPort, toPort)
- Port naming convention: "backend:device:port"
- Connection persistence in Pedalboard model
- Feedback loop prevention (validate no circular connections)
- Connection validation logic

UI Components (Blazor):
- HomePage: Displays blank pedalboard interface (uses PedalboardLoader to determine content)
- PedalboardEditor: Full editing interface with effects rack, connections, parameters
- PedalboardsPage: Manage saved pedalboards list (create new, open, delete)
- EffectsRack: Displays effects in signal chain
- EffectSlot: Individual effect display with modgui rendering
- KnobControl: Parameter control (range slider)
- AvailableEffectsPanel: Browse and select effects to add
- ConnectionVisualizer: Visual representation of connections (SVG wire drawing)
- BackendControlsPanel: Display and control backend-specific settings

**UI Requirements (Updated):**
- Homepage loads a blank, temporary pedalboard directly
- No need to create new pedalboard or select backend before starting
- User can immediately add effects and configure audio
- Backend selection available in BackendControlsPanel (optional, only needed for Start/Stop)
- Save button persists temporary pedalboard to database
- Separate "Pedalboards" management page for saved pedalboards list
- Navigation between home (new pedalboard) and pedalboards (saved list)

Real-Time Synchronization:
- WebSocket hub for pedalboard updates
- Parameter change notifications (broadcast to all connected clients)
- Effect addition notifications
- Effect removal notifications
- Connection update notifications
- Real-time UI refresh without page reload

API Endpoints:
- GET /api/pedalboards (list all pedalboards)
- POST /api/pedalboards (create new pedalboard)
- GET /api/pedalboards/{id} (pedalboard details)
- DELETE /api/pedalboards/{id} (delete pedalboard)
- POST /api/pedalboards/{id}/plugins (add effect to pedalboard)
- DELETE /api/pedalboards/{id}/plugins/{instanceId} (remove effect)
- POST /api/pedalboards/{id}/connections (create connection)
- DELETE /api/pedalboards/{id}/connections (remove connection)
- PUT /api/pedalboards/{id}/plugins/{instanceId}/parameters/{paramId} (set parameter)
- GET /api/pedalboards/{id}/connections (list connections)

Backend Controls System:
- Extend IAudioBackend with control methods:
  - GetAvailableControlsAsync() returns list of backend-specific controls
  - GetControlValueAsync(controlId) gets current value
  - SetControlValueAsync(controlId, value) sets value
- BackendControl model: id, name, description, type, min, max, step, default
- BackendControlValue model: controlId, value, timestamp, state
- Support control types: Slider, Toggle, Enum, Textbox
- BackendControlsPanel component renders all control types
- Error handling for invalid control IDs
- API endpoints:
  - GET /api/audio/backends/{name}/controls (list backend controls)
  - GET /api/audio/backends/{name}/controls/{controlId} (get details)
  - PUT /api/audio/backends/{name}/controls/{controlId} (set value)

Testing Requirements:
- Refer to [Testing_Workflow.md](Testing_Workflow.md) for complete testing requirements
- Component unit tests for all Blazor components
- Service unit tests for IPedalboardService
- Signal routing validation tests
- Pedalboard persistence tests (save/load cycle)
- Feedback loop prevention tests
- Connection persistence tests
- WebSocket real-time sync tests
- E2E tests with Playwright for complete workflows
- Integration tests with mock audio backend
- Control type rendering tests (all 4 types)
- Error handling tests
- Test coverage target: 70%

Definition of Done for Phase 2:
- ✅ All service methods implemented per specification
- ✅ All UI components render without errors
- 🔄 Homepage displays blank pedalboard directly (not pedalboards list)
- 🔄 Users can add effects, create connections, and adjust parameters without backend selection
- 🔄 Backend configuration is optional (only required for Start/Stop)
- 🔄 Save button persists temporary pedalboard
- ⏳ Real-time updates propagate via WebSocket (not yet started)
- ✅ Pedalboard state persists (save/load works)
- ✅ All API endpoints return correct data with proper HTTP status codes
- ✅ All connection validations working
- 🔄 All Playwright tests passing with new homepage pattern
- ⏳ Test coverage target: 70% (WebSocket sync not yet counted)
- ✅ No compiler warnings
- ✅ Code formatted and clean

---

## Phase 3: Polish & Extended Backends

Advanced features, performance optimization, and additional audio backend support.

**Deliverables:**
- Undo/redo functionality for all operations
- Keyboard shortcuts for common workflows
- Performance optimizations for large pedalboards
- JACK backend implementation
- ASIO backend implementation
- 70%+ test coverage

**Features to Deliver:**

Undo/Redo System:
- Operation history tracking (add effect, remove effect, connect, disconnect, parameter change)
- Undo/redo stack management with size limits
- Keyboard shortcuts: Ctrl+Z (undo), Ctrl+Y (redo)
- Visual undo/redo state indicators
- Works across all pedalboard operations

Keyboard Shortcuts:
- Ctrl+S: Save pedalboard
- Ctrl+Z: Undo operation
- Ctrl+Y: Redo operation
- Ctrl+N: New pedalboard
- Delete: Remove selected effect
- Tab: Next effect / parameter
- Shift+Tab: Previous effect / parameter

Performance Optimization:
- Connection caching to avoid repeated route lookups
- Control value caching to reduce API calls
- Efficient graph traversal for connection validation
- Optimized parameter updates (batch where possible)
- Verified performance: 50+ effects without audio glitches

Extended Audio Backends:

JACK Backend:
- JackAudioBackend implementing IAudioBackend
- JACK client initialization and connection
- Port management and dynamic routing through JACK
- Real-time audio scheduling
- Error handling (server unavailable, connection failure)
- Device enumeration from JACK
- Unit tests (minimum 12 per backend following Testing_Workflow.md)
- Integration tests with audio routing

ASIO Backend (Windows):
- AsioAudioBackend implementing IAudioBackend
- ASIO driver integration
- Buffer management and sizing
- Low-latency device configuration
- Windows device enumeration
- Device capability detection
- Unit tests (minimum 12 per backend following Testing_Workflow.md)
- Integration tests

Testing Requirements:
- Refer to [Testing_Workflow.md](Testing_Workflow.md) for complete testing requirements
- Unit tests for undo/redo stack operations
- Unit tests for keyboard shortcut handling
- Unit tests for all new backend implementations
- Integration tests for JACK backend with port management
- Integration tests for ASIO backend with Windows APIs
- Performance benchmark tests (verify 50+ effects goal)
- E2E tests for undo/redo workflows
- E2E tests for keyboard shortcuts
- Test coverage target: 70%+

Definition of Done for Phase 3:
- Undo/redo working for all operations
- All keyboard shortcuts responsive
- Performance benchmarks met (50+ effects)
- Both new backends functional per specification
- All tests passing with 70%+ coverage
- Zero compiler warnings
- Code formatted and clean
- Following 03-ARCHITECTURE-AND-DESIGN.md conventions
