# Mocking Strategy for Flexible Audio Routing Application

## Core Principle
Complete application testability without hardware. All audio backends, device enumeration, real-time processing, and UI workflows fully mockable before production implementation.

## Mock Architecture Layers

### Layer 1: Audio Backend Abstraction

**Mock Audio Device Provider**
- Use IAudioDeviceProvider with MockAudioDeviceProvider
- Return hardcoded device list (simulate SoundFlow/NAudio device enumeration)
- Devices: 2x input, 3x output, each with configurable channel counts
- Each mock device reports realistic properties: sampleRate, channels, latency

**Mock Audio Processing Engine**
- Replace hardware sample processing with in-memory buffer pass-through
- Support configurable latency injection (simulate real device latency)
- Track buffer movement through routing without actual audio I/O
- Return deterministic audio frames (silence, test patterns, or pre-generated data)

**Mock Plugin Chain Execution**
- Replace real plugin processing with stubs that accept input, return output
- No actual DSP; just validate frame counts and channel routing
- Support latency injection per plugin (configurable per test)

### Layer 2: Routing Engine Mocking

**Routing Configuration Storage**
- In-memory dictionary instead of persistence layer
- Scoped to test lifetime
- Support full CRUD without file I/O

**Channel Matrix Validation**
- Mock validates routing logic without real audio flow
- Verify input/output channel mapping correctness
- Ensure no buffer mismatches or orphaned channels

**Backend Coordination**
- Mock RoutingEngine coordinates mock devices as if real
- Simulate multi-device activation/deactivation
- Track active configurations without actual audio streaming

### Layer 3: Device Stream Simulation

**Input Stream Mock**
- Generate test audio frames on-demand
- Return specified frame count, channels, sampleRate
- Support inject-able test patterns: silence, sine wave, noise, chirp

**Output Stream Mock**
- Accept audio frames without writing to hardware
- Track call count, frame data, timestamps
- Verify correct channel data received

**Sync/Timing Mock**
- Simulate timing without real clock synchronization
- Track elapsed frames for latency calculation
- Support time-jump for fast test execution

### Layer 4: SoundFlow Integration Mocking

**Mock AudioDeviceContext**
- Replicate SoundFlow's device initialization without hardware
- Support multi-instance creation (separate contexts per device)
- Return mock AudioGraph

**Mock AudioGraph**
- Accept audio sources without processing
- Support node connection validation (routing correctness)
- Track graph structure without real DSP execution

**Mock Channel Mapper**
- Simulate SoundFlow's channel selection
- Validate channel index bounds per device
- Track mapped channels for verification

### Layer 5: File Audio Backend Mocking

**Mock FileAudio Backend**
- Simulate WAV file I/O without disk operations
- In-memory buffer replaces file streams
- Support configurable frame counts, formats
- Return deterministic read operations

**Mock Codec Support**
- NAudio codec mocking: WaveFormat validation only
- No actual codec instantiation
- Verify format compatibility in routing

### Layer 6: REST API Mocking (TestServer Pattern)

**Mock DeviceController**
- Inject MockAudioDeviceProvider
- Return hardcoded device list
- Support full /api/devices endpoints

**Mock RoutingController**
- Inject MockRoutingEngine
- In-memory configuration storage
- Support full /api/routing/* endpoints

**Mock HealthController**
- Return mock backend status
- Report all mock providers as healthy

### Layer 7: Pedalboard Plugin System Mocking

**Mock Plugin Discoverer**
- Return static list of test plugins (Amp, Reverb, EQ, Delay)
- No filesystem scanning
- Each mock plugin has name, latency, channel config

**Mock Plugin Instance**
- Accept audio buffers, return output
- No DSP computation
- Configurable latency injection
- Support enable/disable state

**Mock Pedalboard**
- Coordinate mock plugin chain
- Validate plugin connections
- Track active plugins for latency reporting

## Test Scenarios Coverage

### Audio Routing Workflows (from 12-FLEXIBLE-AUDIO-ROUTING.md)

**Workflow 1: Guitar Recording + Live Monitoring**
- Mock input device (1 channel guitar)
- Mock 2x output devices (studio + PA)
- Mock plugin chain (Amp→Reverb→EQ)
- Verify routing validation without audio processing

**Workflow 2: Multi-Source Mixing**
- Mock 3x input sources (Device 1 stereo, Device 2 mono, FileAudio)
- Mock output devices + FileAudio output
- Mock mixer plugin accepting N inputs
- Verify frame alignment, channel routing

**Workflow 3: Distributed System**
- Mock 1x input, 3x output devices (zones)
- Mock delay plugin for sync
- Verify broadcast-style routing correctness

**Workflow 4: Direct Input-to-Output (Bypass)**
- Mock pedalboard pass-through mode
- Verify input directly routes to output
- Confirm no plugin latency added

### UI/UX Workflows (Playwright Tests)

**Device Discovery**
- Mock DeviceController returns static device list
- UI renders all mock devices
- Verify device selector shows correct channels/properties

**Configuration Creation**
- Mock RoutingEngine creates in-memory config
- UI adds input/output routes
- Verify routing matrix visual matches config

**Routing Application**
- Click "Apply Configuration"
- Mock RoutingEngine activates routes
- Verify API call sequencing matches real flow

**Latency Display**
- Mock RoutingEngine calculates latency from mock components
- UI displays latency breakdown
- Verify calculation matches pedalboard structure

**Save/Load Workflow**
- Mock storage persists to in-memory dictionary
- Save configuration, refresh page
- Load configuration returns identical state

**Audio Monitoring (Without Real Audio)**
- Mock input stream generates test frames
- UI graphs show frame movement (not audio content)
- Verify real-time updates work with mock timing

## Implementation Patterns

### Service Registration (DI)

**Production Registration**
- IRoutingEngine → RoutingEngine
- IAudioDeviceProvider → RealAudioDeviceProvider
- IAudioBackendFactory → SoundFlowBackendFactory

**Test Registration (Scoped)**
- IRoutingEngine → MockRoutingEngine
- IAudioDeviceProvider → MockAudioDeviceProvider
- IAudioBackendFactory → MockAudioBackendFactory
- IPedalboardPluginDiscoverer → MockPluginDiscoverer

### Mock Builders

**Device Mock Builder**
- Configure device properties (id, channels, sampleRate, latency)
- Build mock device for test scenario
- Return from MockAudioDeviceProvider.EnumerateDevices()

**Routing Configuration Mock Builder**
- Create input routes (backend, device, channel, label)
- Create output routes (backend, device, channels, gain, label)
- Build channel matrix
- Return configuration object for test

**Audio Stream Mock Builder**
- Configure frame count, channel count, format
- Set test pattern (silence, sine, noise)
- Support frame-by-frame generation or pre-allocated buffer

### Verification Points (No Assertions on Audio Content)

**Routing Validation**
- Verify input/output channel counts match
- Confirm no orphaned routes
- Validate device latencies sum correctly

**Buffer Movement**
- Track frame count through routing chain
- Verify channel data placement in output buffers
- Confirm frame timing (no skips/duplicates)

**Plugin Chain Execution**
- Verify plugin order matches configuration
- Confirm plugin enable/disable respected
- Check latency contributions accumulate

**Configuration Persistence**
- Verify saved configuration loads identically
- Confirm no data loss in mock storage
- Test concurrent read/write scenarios

**API Contract Compliance**
- Verify endpoint response structure matches schema
- Confirm HTTP status codes appropriate
- Check request payload validation

## Mock Boundary Definitions

### What to Mock
- All hardware device access
- All real audio buffer I/O
- All plugin DSP computation
- All file system operations (wav files)
- All network streams (if applicable)
- All OS audio APIs (ALSA, CoreAudio, WASAPI)

### What NOT to Mock
- Routing logic and validation
- Configuration serialization
- Plugin graph structure
- Channel mapping calculations
- Latency arithmetic
- REST API contract (keep real)
- Pedalboard state management

## Test Execution Flow

### Per-Test Setup
1. Create fresh mock DI container
2. Register all mock providers (scoped)
3. Initialize mock device provider with test device set
4. Create mock routing engine with empty config storage
5. Build TestServer with mock-configured DI
6. Verify all services resolve (container validation test)

### Per-Test Workflow Test (e.g., Workflow 1)
1. Mock device provider: register guitar input + 2 output devices
2. Mock plugin discoverer: return Amp, Reverb, EQ plugins
3. Create routing config via API (real HTTP call via TestServer)
4. Add input route (device 1, channel 0)
5. Add output routes (devices 2-3, channels 2-3)
6. Create channel routing (input → pedalboard → outputs)
7. Apply configuration
8. Verify mock routing engine active state
9. Verify channel matrix correctness
10. Calculate and verify latency (mock plugin latencies)

### Per-Test Cleanup
1. Dispose TestServer (frees port)
2. Clear mock storage
3. Verify no resources leaked

## Audio Data Verification Strategy

**No Audio Content Testing**
- Never assert on actual audio sample values
- Mock generates deterministic frames (all zeros or patterns)
- Focus on routing correctness, not signal quality

**Frame Integrity Testing**
- Verify frame count preservation through chain
- Confirm channel assignments maintained
- Check no buffer overwrites or underruns
- Validate sample format consistency

**Timing Validation**
- Mock timing doesn't use real clocks
- Verify frame-based timing logic
- Test latency calculation formulas
- Confirm no race conditions in mock coordinator

## Integration with Existing Libraries

### SoundFlow Mocking Approach
- Do NOT mock SoundFlow directly
- Create MockSoundFlowBackend implementing IAudioBackend
- This backend simulates what real SoundFlow does
- Reuse SoundFlow model classes (AudioDeviceConfig, etc.)
- Only mock execution, not object structure

### NAudio Mocking Approach
- Do NOT mock NAudio library
- Create MockFileAudioBackend implementing IAudioBackend
- Simulate WaveFormat handling without codec instantiation
- Mock in-memory buffer operations
- Reuse NAudio format enums/classes

### Pedalboard/Plugin System
- Mock plugin discoverer scans mock directory (empty)
- Return hardcoded plugin list instead
- Each mock plugin returns stable properties
- Support realistic latency values (e.g., 1ms per plugin)

## Continuous Testing Workflow

**Before Any Real Backend Code**
1. All routing tests use mocks
2. All UI workflows use TestServer + mocks
3. All device discovery tests use mocks
4. Latency calculations verified with mock latencies

**During Real Backend Implementation**
1. Swap mock backend with real backend
2. Run same test suite against real backend
3. Verify test passing with real hardware (if available)
4. Compare latency measurements (mocks vs. real)

**Production Validation**
1. Real backend activated in production container
2. Mock backend available for edge case testing
3. Support mode-switch via configuration

## Mock Configuration Example

Mock setup for all four workflows simultaneously (test suite)

Device Set:
- Input Device 1: 1 channel, 48kHz, 2ms latency
- Input Device 2: 2 channels, 48kHz, 2ms latency
- Input Device 3: 1 channel (FileAudio), infinite latency
- Output Device 1: 4 channels, 48kHz, 3ms latency
- Output Device 2: 4 channels, 48kHz, 3ms latency
- Output Device 3: 4 channels, 48kHz, 3ms latency
- Output Device 4: 1 channel (FileAudio), infinite latency

Plugin Set:
- Amp Simulator: 1ms latency, all channels
- Reverb: 5ms latency, all channels
- EQ: 0.5ms latency, all channels
- Compressor: 0.5ms latency, all channels
- De-esser: 0.5ms latency, all channels
- Noise Gate: 0.5ms latency, all channels
- Delay: 10ms base latency, configurable per test
- Mixer: 0ms latency, N inputs to stereo output
- Master EQ: 0.5ms latency, all channels

These fixed latencies enable deterministic latency testing for all workflows.

## Separation of Real and Mock Code

### Assembly Structure

Production Assembly
- Alsionyx.Core: Interfaces only (IAudioBackend, IRoutingEngine, IAudioDeviceProvider, IPedalboardPlugin)
- Alsionyx.Infrastructure: Real implementations (SoundFlowAudioBackend, RealAudioDeviceProvider, Lv2PluginDiscoverer)
- Alsionyx.Api: REST controllers and Blazor UI

Test Assembly
- Alsionyx.Tests.Mocks: All mock implementations (no dependencies on production Infrastructure)
- Mocks are exclusively for test projects; never referenced by Api or Infrastructure

### Namespace Isolation

Production Namespaces
- Alsionyx.Infrastructure.Audio.SoundFlow
- Alsionyx.Infrastructure.Audio.FileAudio
- Alsionyx.Infrastructure.Plugins.Lv2

Mock Namespaces
- Alsionyx.Tests.Mocks.Audio
- Alsionyx.Tests.Mocks.Plugins
- Alsionyx.Tests.Mocks.Routing

Compiler prevents Api/Infrastructure from referencing mock namespaces due to assembly structure. Mock implementations match interface surface exactly.

### Conditional Compilation and DI Boundaries

DI Container Configuration (Only Entry Point)
- Program.cs (Api) contains environment-based registration logic
- Development environment: Real backends + optional mock overrides via configuration
- Production environment: Real backends only
- Test environment: Exists only in test runners, never touches production code

Mock Registration Only in Test Fixtures
- GlobalSetup.cs (Alsionyx.Tests.Library) registers mocks to container
- Test containers are completely separate from Api container
- No shared container instances between tests and production

Environment Detection
- Program.cs checks ASPNETCORE_ENVIRONMENT
- No hardcoded references to mock types in production code
- Environment variable prevents mock assembly loading in production

### Enforcement Mechanisms

File Organization
- Real backend: src/Alsionyx.Infrastructure/Audio/SoundFlow/
- Mock backend: tests/Alsionyx.Tests.Mocks/Audio/
- Different project folders prevent accidental namespace collision

Project References
- Alsionyx.Api references Alsionyx.Infrastructure and Alsionyx.Core
- Alsionyx.Infrastructure references Alsionyx.Core only
- Alsionyx.Tests.Mocks references Alsionyx.Core only (no Infrastructure ref)
- Alsionyx.Tests.Library references both Core and Mocks, nothing else
- Alsionyx.PlaywrightTests references Alsionyx.Tests.Library only

Compiler Enforcement
- Attempting to reference Alsionyx.Tests.Mocks from Api = build error
- Circular reference attempts = build error
- Unused using statements to mock namespaces = analyzer warnings

### Configuration-Based Backend Selection

Appsettings Configuration (Production Only)
- appsettings.Production.json: audioBackend = "soundflow"
- No "mock" value allowed in production config
- Attempted mock config activation = startup validation error

Container Builder Validation
- ApiContainerBuilder checks configuration before registering backends
- Unknown backend type = throw ConfigurationException
- Unknown backend type can never silently default to mock

### Testing Isolation Pattern

Test Setup Hierarchy
- Test → GlobalSetup.Provider (fresh container)
- GlobalSetup creates mock-only container
- Each test gets AsyncServiceScope from mock container
- No cross-contamination to production code paths

Test Container Lifecycle
- Created once per test assembly
- Destroyed after all tests
- Separate lifetime from Api container
- Mocks exist only within test process memory

### API Contract Verification

Real API Under TestServer
- Api project runs as-is with real backends configured
- No mock injection at TestServer level
- Tests call real HTTP endpoints
- Verify real backend coordination through API

Mock Layer Sits Behind HTTP
- Mocks replace only the backend services
- API layer remains unchanged
- REST contract enforces real/mock indistinguishability
- Playwright tests cannot differentiate mock from real

### Prevention of Mock Leakage

Namespace Search Audits
- grep for "Alsionyx.Tests.Mocks" in src/ folder returns nothing
- grep for mock-specific types (MockRoutingEngine, MockAudioDeviceProvider) in Api/Infrastructure = error
- Pre-commit hook prevents mock references in production code

Static Analysis
- Roslyn analyzer detects unauthorized assembly references
- Custom rule: "Mocks namespace not allowed outside tests"
- Fails build if violation detected
- No workarounds (no InternalsVisibleTo for mocks)

Documentation
- Include "MOCK_SEPARATION.md" explaining boundaries
- Code review checklist: verify no mock references in production PR
- Onboarding docs: show correct separation patterns

### Testing Against Real Backend Fallback

Conditional Test Execution
- Unit tests: Always use mocks (no hardware required)
- Integration tests: Can use mocks or switch to real backend
- E2E tests: Via configuration, point to real device or mock
- CI/CD: Runs with mocks (no hardware in pipeline)

Configuration Override for Integration Tests
- Separate test configuration file: appsettings.IntegrationTest.json
- Override audioBackend setting to real implementation
- Real backend only activated when explicitly configured
- Production never uses test configuration

Device Simulator Fallback
- Real backend can initialize with mock device list for testing
- SoundFlow supports mock device contexts
- FileAudio always available as real backend (no special mock needed)
- Tests can use FileAudio as "real but safe" backend

## Components Required

Core Infrastructure Components
- IAudioBackend (interface in Core)
- IAudioDeviceProvider (interface in Core)
- IAudioStream (interface for input/output streams)
- IPedalboardPlugin (interface for plugin abstraction)
- IRoutingEngine (interface for routing orchestration)
- IPluginDiscoverer (interface for plugin enumeration)
- IAudioBackendFactory (interface for backend creation)

Production Backend Components
- SoundFlowAudioBackend (implements IAudioBackend)
- SoundFlowDeviceProvider (implements IAudioDeviceProvider)
- SoundFlowInputStream (implements IAudioStream)
- SoundFlowOutputStream (implements IAudioStream)
- Lv2PluginDiscoverer (implements IPluginDiscoverer)
- Lv2PluginInstance (implements IPedalboardPlugin)
- FileAudioBackend (implements IAudioBackend, real file I/O)

Mock Components
- MockAudioDeviceProvider (in Tests.Mocks)
- MockAudioBackend (in Tests.Mocks)
- MockInputStream (in Tests.Mocks)
- MockOutputStream (in Tests.Mocks)
- MockRoutingEngine (in Tests.Mocks)
- MockPluginDiscoverer (in Tests.Mocks)
- MockPedalboardPlugin (in Tests.Mocks)
- MockAudioBackendFactory (in Tests.Mocks)
- DeviceMockBuilder (test utility)
- RoutingConfigMockBuilder (test utility)

Test Infrastructure Components
- GlobalSetup (assembly-level test fixture, sets up mock DI container)
- PlaywrightTestBase (Playwright test base class, manages TestServer lifecycle)
- AlsionyxSut (System Under Test WebApplicationFactory with mock DI)
- MockDiContainerBuilder (creates and registers mock-configured container)

Validation Components
- AudioBackendValidator (confirms backend type exists at startup)
- BackendEnvironmentSelector (ensures correct module loaded per environment)
- AssemblyReferenceValidator (CI check for unauthorized mock references)

Integration Components
- BackendRegistrationModule (service registration for production backends)
- MockBackendRegistrationModule (service registration for mock backends)
- AudioBackendFactory (selects backend based on environment at startup)

UI/API Components
- DevicesController (real API, works with any backend)
- RoutingController (real API, works with any backend)
- AudioStatusController (real API, works with any backend)
- HealthCheckEndpoint (reports backend status)
- DeviceSelectorViewModel (Avalonia ViewModel)
- RoutingMatrixViewModel (Avalonia ViewModel)
- LatencyMonitorViewModel (Avalonia ViewModel)
- AudioStateService (handles state for UI viewmodels)

Pedalboard Components
- Pedalboard (orchestrates plugins)
- PluginChain (manages plugin order and connections)
- PedalboardAudioRouter (routes audio through plugins)
- PedalboardLatencyCalculator (sums plugin latencies)

Routing Components
- RoutingEngine (real implementation)
- MockRoutingEngine (in Tests.Mocks)
- AudioRoutingConfiguration (model for saved configs)
- InputRoute (model for input definition)
- OutputRoute (model for output definition)
- ChannelRoutingMatrix (model for channel mapping)
- RoutingValidator (ensures valid routing topology)
- RoutingConfigurationStore (persists configurations)

Separation and Validation Components
- AudioBackendValidator (confirms backend type exists at startup, prevents mock in production)
- BackendRegistrationModule (DI registration module for production backends only)
- MockBackendRegistrationModule (DI registration module for test backends only)
- BackendEnvironmentSelector (selects registration module based on environment)
- AssemblyReferenceValidator (build-time CI check for unauthorized mock references)

Stream and Frame Management Components
- AudioFrameBuffer (holds audio data for routing)
- ChannelData (represents audio channel information)
- AudioStreamCoordinator (manages input/output stream lifecycle)
- MockAudioFrameGenerator (produces deterministic test frames)
- TestDeviceFactory (creates mock device instances for tests)
- TestPluginFactory (creates mock plugin instances for tests)

Builder Components
- DeviceMockBuilder (fluent builder for test devices)
- RoutingConfigurationBuilder (fluent builder for test routing configs)
- PedalboardMockBuilder (fluent builder for test pedalboards)
