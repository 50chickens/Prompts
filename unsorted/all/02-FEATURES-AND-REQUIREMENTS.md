# Features & Requirements

## Complete Feature Inventory

### 1. Audio Device Management with Multi-Device Routing (ENHANCED)

**Core Feature:** Discover and manage audio devices with flexible multi-device, multi-backend routing

Features:
- ✅ Enumerate all audio devices on system
- ✅ Filter by device type (Playback, Capture, Duplex)
- ✅ Query supported audio formats per device
- ✅ Set active audio device
- ✅ Get device properties (channels, max channels, class)
- 🆕 **Multi-device input selection** - Select multiple devices/channels for input
- 🆕 **Multi-device output routing** - Route to multiple devices/channels simultaneously
- 🆕 **Per-channel routing** - Route individual channels to specific destinations
- 🆕 **Cross-backend routing** - Mix FileAudio and real audio sources
- 🆕 **Flexible channel mapping** - Map any input channel to any output channel(s)

Example Use Case:
```
Device 1 (2in/2out): Receive channel 1
Device 2 (4 channels): Output to channels 3-4
Device 3 (4 channels): Output to channels 3-4 (simultaneous)
```

API Endpoints:
- `GET /api/devices` - List all devices
- `GET /api/devices/playback` - List playback devices
- `GET /api/devices/capture` - List capture devices
- `GET /api/devices/{name}/formats` - Get supported formats
- 🆕 `GET /api/routing/configurations` - List routing configurations
- 🆕 `POST /api/routing/configurations` - Create routing configuration
- 🆕 `GET /api/routing/configurations/{id}` - Get routing details
- 🆕 `PUT /api/routing/configurations/{id}` - Update routing
- 🆕 `DELETE /api/routing/configurations/{id}` - Delete routing

### 2. Audio Format Configuration

**Core Feature:** Configure audio format parameters

Features:
- ✅ Select sample rate (44.1k, 48k, 96k, 192k Hz)
- ✅ Select bit depth (16-bit, 24-bit, 32-bit)
- ✅ Select channel count (1-8 channels)
- ✅ Validate format against device capabilities
- ✅ Apply configuration to active device

API Endpoints:
- `POST /api/configuration/format` - Update format

### 3. Configuration Management

**Core Feature:** Persist and load application configuration

Features:
- ✅ Load configuration from storage
- ✅ Save configuration to storage
- ✅ Reset to default configuration
- ✅ Validate configuration values
- ✅ Provide sensible defaults when config missing

API Endpoints:
- `GET /api/configuration` - Get current config
- `POST /api/configuration/device` - Set device
- `POST /api/configuration/reset` - Reset to defaults

### 4. LV2 Plugin Management (aka "Effects")

**Core Feature:** Discover and manage LV2 audio plugins with modgui visual representations

Features:
- ✅ Discover all LV2 plugins on system
- ✅ Load modgui visual representations per plugin
- ✅ Extract plugin port metadata (audio, MIDI, control)
- ✅ Filter plugins by type (Reverb, Compressor, etc.)
- ✅ Get plugin properties (URI, name, ports, latency, version)
- ✅ Support arbitrary signal routing (any port to any port)
- ✅ Manage plugin instances in pedalboard
- ✅ Save/load pedalboard with all connections
- ✅ Load/save plugin presets

API Endpoints:
- `GET /api/plugins` - List all plugins
- `GET /api/plugins/type/{type}` - Filter by type
- `GET /api/plugins/{uri}` - Get specific plugin with modgui metadata
- `POST /api/pedalboards` - Create pedalboard
- `GET /api/pedalboards/{id}` - Get pedalboard with connections
- `POST /api/pedalboards/{id}/effects` - Add plugin instance
- `POST /api/pedalboards/{id}/connections` - Create port connection

### 5. REST API

**Core Feature:** HTTP endpoints for device/plugin/configuration management

Specifications:
- ✅ 25+ total endpoints across 6 categories
- ✅ JSON request/response format
- ✅ Standard HTTP status codes (200, 400, 404, 500, 503)
- ✅ Consistent error response format
- ✅ CORS support for browser clients
- ✅ Health check endpoint
- ✅ WebSocket support for real-time updates

API Categories:
- Device endpoints (4 endpoints)
- Configuration endpoints (5 endpoints)
- Plugin endpoints (3+ endpoints)
- Pedalboard endpoints (7+ endpoints)
- Audio backend endpoints (3+ endpoints) - includes new backend controls
- Health/Status endpoint (1 endpoint)

### 6. Virtual Pedalboard UI

**Core Feature:** Interactive visual pedalboard with flexible signal routing

Features:
- ✅ Visual representation of each LV2 plugin using its modgui system
- ✅ Free-form pedalboard layout (plugins can be positioned anywhere)
- ✅ Interactive parameter controls (knobs, switches) per plugin
- ✅ Visual patch bay showing all port connections
- ✅ Drag-and-drop port connection (create arbitrary signal routing)
- ✅ Flexible signal routing:
  - Audio input → Output (bypass)
  - Audio input → Plugin input
  - Plugin output → Plugin input (effect chaining)
  - Plugin output → Audio output
  - Multiple plugins sharing same input
- ✅ Plugin bypass toggle without removal
- ✅ System monitoring (latency, CPU load per plugin)
- ✅ Real-time WebSocket updates for multi-client sync

Technologies:
- Blazor WebAssembly (.NET in browser)
- modgui HTML/CSS/JavaScript for plugin visuals
- SVG for patch bay connections
- WebSocket for real-time collaboration
- Bootstrap for UI framework

### 7. Backend-Specific Controls (Generic Audio Subsystem Settings)

**Core Feature:** Expose audio backend-specific settings in a generic, extensible way

Features:
- ✅ ALSA backend controls (Master Volume, Microphone Boost, Input Source, etc.)
- ✅ JACK backend controls (Buffer Size, Sample Rate, etc.) - read-only
- ✅ ASIO backend controls (Buffer Size, Latency Compensation, etc.)
- ✅ SoundFlow backend controls (via pattern)
- ✅ Generic control types (Slider, Toggle, Enum, Textbox)
- ✅ Read-only controls (for informational purposes)
- ✅ Hidden controls (queryable but not shown in UI)
- ✅ Real-time control value updates
- ✅ Backend-independent UI rendering (same controls for any backend)
- ✅ Per-backend control sets (different controls per audio subsystem)

API Endpoints:
- `GET /api/audio/backends/{name}/controls` - List available controls
- `GET /api/audio/backends/{name}/controls/{controlId}` - Get control current value
- `PUT /api/audio/backends/{name}/controls/{controlId}` - Set control value

UI Components:
- BackendControlsPanel - Renders all available controls dynamically
- PortLevelMonitor - Shows dBFS level on hover with real-time WebSocket updates
- Control type rendering (sliders, toggles, dropdowns, text boxes)
- Read-only indicators for non-editable controls
- Real-time value synchronization
- Meter visualization with color-coded levels (green/orange/red)

### 8. Pluggable Audio Backend with Backend Controls & Signal Monitoring

**Core Feature:** Abstract audio subsystem supporting multiple backends with backend-specific controls and signal monitoring

Features:
- ✅ Abstract IAudioBackend interface (audio subsystem agnostic)
- ✅ ALSA backend implementation (primary Linux support)
- ✅ Mock backend for testing (no hardware required)
- ✅ JACK backend pattern (for future implementation)
- ✅ ASIO backend pattern (Windows support)
- ✅ SoundFlow backend pattern (future cross-platform support)
- ✅ Configuration-based backend selection
- ✅ Pedalboard-level backend choice (different boards use different backends)
- ✅ **Generic backend controls exposure**:
  - ALSA: Master volume, microphone boost, input source, line levels
  - JACK: Buffer size, sample rate, server settings
  - ASIO: Buffer size, latency compensation
  - SoundFlow: Network settings, routing
- ✅ **Dynamic control discovery** - UI automatically exposes available controls per backend
- ✅ **Port-level signal monitoring (dBFS)**
  - Real-time updates via WebSocket
  - Peak hold detection
  - VU-meter visualization
  - Color-coded levels (green normal, orange caution, red clipping)

Capabilities:
- Device enumeration and selection
- Audio format configuration
- Real-time port connection/disconnection
- Plugin instance management
- System load monitoring
- Latency measurement
- Backend-specific control management (mixer, settings)
- Real-time signal level monitoring with peak detection
- Hover-activated port level display

Technologies:
- Abstract factory pattern
- Dependency injection for backend selection
- Configuration-driven provider instantiation
- WebSocket for real-time level streaming

### 9. Logging & Diagnostics

**Core Feature:** Comprehensive logging for debugging and monitoring

Features:
- ✅ Structured logging with NLog
- ✅ Generic `ILog<T>` interface for type-safe injection
- ✅ Log levels (Debug, Info, Warn, Error, Trace)
- ✅ Exception logging with stack traces
- ✅ Operation context tracking
- ✅ Test logging via NSubstitute mocks
- ✅ Environment-specific log configuration

Technologies:
- NLog 5.x framework
- File and console targets
- Memory targets for testing
- Structured property support

### 10. Testing Infrastructure

**Core Feature:** Comprehensive test suite

Test Types:
- ✅ Unit tests (xUnit) - 60% of tests
- ✅ Integration tests (WebApplicationFactory) - 20% of tests
- ✅ E2E tests (Playwright) - 20% of tests

Test Features:
- ✅ xUnit test framework
- ✅ NSubstitute mocking (no Moq)
- ✅ FluentAssertions for readable assertions
- ✅ Mock audio device provider
- ✅ Mock LV2 plugin discoverer
- ✅ Mock configuration store (in-memory)
- ✅ Mock audio backend for testing any backend
- ✅ Generic DI container validator
- ✅ Docker-based test environment

---

## Non-Functional Features

### Performance
- Device discovery completes in <100ms
- Configuration save/load in <50ms
- Plugin discovery in <200ms
- modgui HTML/CSS parsing in <50ms per plugin
- API endpoint response time <500ms
- Signal routing computation <10ms for 50+ plugins

### Reliability
- Graceful handling of missing config (use defaults)
- Device enumeration fallback to empty list
- Plugin discovery failure returns empty list
- Validate connections before applying (prevent audio feedback loops)
- Health checks indicate system status
- Recover from audio device disconnection

### Security
- CORS configured per environment
- Input validation on all endpoints
- No command execution or file traversal
- Dependency-based system access (no direct file I/O outside storage layer)
- Validate plugin URIs before loading
- Sandbox plugin GUI rendering (HTML/CSS/JS isolation)

### Maintainability
- Clean architecture with clear layer separation
- Interface-based design for testability
- Comprehensive documentation
- Standard code organization
- Consistent naming conventions
- No magic strings or numbers
- Plugin-agnostic system (no hardcoded plugin list)

### Scalability
- Mock devices enable unlimited concurrent testing
- Mock plugin discovery enables fast plugin enumeration
- In-memory configuration store for tests
- Stateless API design for horizontal scaling
- Docker containerization for deployment scaling
- Support arbitrary number of plugins and connections

---

## Requirements Mapping

### Original User Requirements → Implementation

| Requirement | Status | Document |
|-------------|--------|----------|
| Examine existing logging in JackSharpCore & alsa.net | ✅ DONE | [Logging Architecture](01-LOGGING-ARCHITECTURE.md) |
| Switch from Serilog to NLog | ✅ DESIGNED | [Logging Architecture](01-LOGGING-ARCHITECTURE.md) |
| Switch from Moq to NSubstitute | ✅ DESIGNED | [Testing Strategy](05-TESTING-STRATEGY.md) |
| Create mock ALSA device library | ✅ DESIGNED | [Testing Strategy](05-TESTING-STRATEGY.md) |
| Design generic DI validation testing | ✅ DESIGNED | [Testing Strategy](05-TESTING-STRATEGY.md) |
| Document all components by layer | ✅ DONE | [Components by Layer](04-COMPONENTS-BY-LAYER.md) |
| Docker testing strategy | ✅ DESIGNED | [Docker & Deployment](07-DOCKER-AND-DEPLOYMENT.md) |
| Remove OS commands from non-storage | ✅ DESIGNED | [Architecture & Design](03-ARCHITECTURE-AND-DESIGN.md) |
| Complete feature documentation | ✅ DONE | This document |
| Testing patterns & techniques | ✅ DOCUMENTED | [Testing Strategy](05-TESTING-STRATEGY.md) |
| API endpoint documentation | ✅ DONE | [API Reference](08-API-REFERENCE.md) |

---

## Technology Stack

| Layer | Technology | Version | Justification |
|-------|-----------|---------|---------------|
| **Runtime** | .NET Core | 9 | Latest LTS, good ALSA support |
| **Web Framework** | ASP.NET Core | 9 | Built-in, performant, integrated |
| **Frontend** | Blazor WebAssembly | 9 | C# code-sharing, no JavaScript needed |
| **Logging** | NLog | 5.x+ | Generic interface pattern works well |
| **Testing - Framework** | xUnit | 2.4+ | Modern, clean API |
| **Testing - Mocking** | NSubstitute | 5.x+ | Better null-safety than Moq |
| **Testing - Assertions** | FluentAssertions | 6.x+ | Readable assertion syntax |
| **Testing - E2E** | Playwright | Latest | Cross-browser support, stable |
| **Containerization** | Docker | Latest | Clean test environments |
| **Orchestration** | Docker Compose | Latest | Multi-container test setups |
| **Persistence** | JSON files | - | Simple, human-readable, versioned |
| **Audio** | ALSA via AlsaSharp | Latest | Linux standard, well-supported |

---

## Architectural Decisions

### 1. NLog Over Serilog

**Decision:** Use NLog instead of Serilog

**Rationale:**
- Supports generic `ILog<T>` interface pattern elegantly
- Factory pattern works better than static configuration
- Better for constructor-injected logging

**Benefits:**
- Type-safe logging (compile-time checking)
- DI-friendly design
- Less boilerplate in service classes

**Trade-offs:**
- Slightly less fashionable than Serilog
- Configuration is XML/code-based, not fluent

### 2. NSubstitute Over Moq

**Decision:** Use NSubstitute instead of Moq for mocking

**Rationale:**
- Better null-safety
- More modern fluent API
- No "loose" vs "strict" behavior surprises

**Benefits:**
- Cleaner test code
- Better IntelliSense support
- Fewer "non-obvious" defaults

**Trade-offs:**
- Smaller community than Moq
- Less documentation examples online

### 3. Mock Audio Devices in Tests

**Decision:** Never use real ALSA hardware in tests

**Rationale:**
- Tests must be reproducible and fast
- Not all machines have audio hardware
- CI/CD environments don't have audio devices

**Benefits:**
- Tests run anywhere (Docker, CI, headless)
- Complete control over test data
- No flaky tests due to hardware state

**Trade-offs:**
- Must maintain mock device library
- Need separate integration tests with real hardware

### 4. Docker-Based Testing

**Decision:** Run tests in Docker containers

**Rationale:**
- Solves HTTP/HTTPS redirect issues
- Clean environment every run
- No cert caching or DLL conflicts
- Production parity

**Benefits:**
- Reproducible results
- No host system interference
- CI/CD ready out of the box

**Trade-offs:**
- Docker installation required
- Slightly slower than native testing
- Image build/pull overhead

### 5. Configuration-Based Provider Selection

**Decision:** Use environment variables to select Real vs Mock providers

**Rationale:**
- Single codebase for all environments
- Dependency injection handles implementation selection
- No conditional compilation needed

**Benefits:**
- Easy to switch between implementations
- Same code runs in all environments
- Easy to test with real providers

**Trade-offs:**
- Must manage multiple config files
- Need clear environment documentation

---

## Future Enhancements (Phases)

### Phase 2: JACK Integration
- JACK server connection/disconnection
- JACK port enumeration
- JACK client session management
- JACK transport control

### Phase 3: Advanced Plugin Management
- Plugin parameter UI/API
- Real-time parameter changes
- Plugin preset management
- Plugin CPU metering

### Phase 4: Recording & Playback
- Audio file recording
- Recorded file playback
- Format conversion
- Batch processing

### Phase 5: Advanced Diagnostics
- Audio latency measurement
- Buffer underrun detection
- Device compatibility checking
- Performance metrics dashboard

---

## Related Documentation

- [Logging Architecture](01-LOGGING-ARCHITECTURE.md) - How logging is implemented
- [Architecture & Design](03-ARCHITECTURE-AND-DESIGN.md) - System design patterns
- [Testing Strategy](05-TESTING-STRATEGY.md) - How to test these features
