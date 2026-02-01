# Alsionyx Audio Manager - Technical Documentation

Welcome! This directory contains comprehensive technical documentation for the Alsionyx Audio Manager project - a .NET 9 application with a Blazor WebAssembly UI that provides a virtual pedalboard interface for managing audio devices, LV2 plugins, and effect chains using SoundFlow and file-based audio processing.

## 📖 Documentation Guide

### Start Here
- **[INDEX.md](INDEX.md)** - Navigation guide, quick start, learning paths by role

### Foundation (Learn the Architecture)
1. **[01-LOGGING-ARCHITECTURE.md](01-LOGGING-ARCHITECTURE.md)** (262 lines)
   - NLog 5.x integration guide
   - Generic ILog<T> interface design
   - Structured logging patterns for app and tests
   - Unit test logging strategies

2. **[02-FEATURES-AND-REQUIREMENTS.md](02-FEATURES-AND-REQUIREMENTS.md)** (350 lines)
   - Complete feature inventory (8 features)
   - All requirements mapped
   - Technology stack justification
   - Architectural decision rationales

3. **[03-ARCHITECTURE-AND-DESIGN.md](03-ARCHITECTURE-AND-DESIGN.md)** (420 lines)
   - Three-layer system architecture
   - Dependency injection patterns
   - Design patterns (6 types)
   - Error handling strategy

### Implementation (Build the Application)
4. **[04-COMPONENTS-BY-LAYER.md](04-COMPONENTS-BY-LAYER.md)** (867 lines)
   - Audio Device Management Component
   - LV2 Plugin Management Component
   - Configuration & Persistence Component
   - REST API Component (13+ endpoints)
   - Blazor WebAssembly UI Component
   - Complete with code examples

5. **[05-TESTING-STRATEGY.md](05-TESTING-STRATEGY.md)** (519 lines)
   - Testing pyramid (60/20/20)
   - xUnit + NSubstitute patterns
   - MockAudioDeviceProvider design
   - MockLv2PluginDiscoverer design
   - Generic DI Container Validator
   - Docker test environment

6. **[06-WORKFLOWS-AND-PATTERNS.md](06-WORKFLOWS-AND-PATTERNS.md)** (693 lines)
   - 3 main user workflows
   - 5 common implementation patterns
   - Detailed sequence diagrams
   - State management in Blazor
   - Real-world code examples

7. **[07-DOCKER-AND-DEPLOYMENT.md](07-DOCKER-AND-DEPLOYMENT.md)** (466 lines)
   - Container isolation strategy
   - Multi-stage Docker builds
   - Configuration-based mocking
   - Docker Compose files
   - Solutions to HTTP/HTTPS issues
   - CI/CD integration

### Advanced Features (Pedalboard & Audio Backend)
8. **[09-PEDALBOARD-UI-AND-AUDIO-BACKEND.md](09-PEDALBOARD-UI-AND-AUDIO-BACKEND.md)** (710 lines)
   - Virtual pedalboard interface design
   - Pedalboard component hierarchy
   - Pluggable audio backend architecture (SoundFlow primary, JACK/ASIO future)
   - SoundFlow/FileAudio/Mock backend support patterns
   - WebSocket real-time updates
   - Effect chain management

### Quick Reference (Visual Guide)
9. **[10-QUICK-REFERENCE-PEDALBOARD-UI.md](10-QUICK-REFERENCE-PEDALBOARD-UI.md)** (414 lines)
   - ASCII visual layouts
   - Blazor component tree
   - HTML/CSS examples
   - JavaScript interaction code
   - Knob control implementation
   - Drag-and-drop examples

### API Documentation
10. **[08-API-REFERENCE.md](08-API-REFERENCE.md)** (1,067 lines)
    - Device endpoints (4)
    - Configuration endpoints (5)
    - Plugin endpoints (3)
    - Pedalboard endpoints (7+)
    - Audio backend endpoints (1)
    - Health check endpoint (1)
    - cURL, Python, JavaScript, C# examples
    - Error response formats
    - Status codes reference
### Functional requirements.
11. **[11-COMPLETE-REBUILD-SPECIFICATION](11-COMPLETE-REBUILD-SPECIFICATION)** (1,067 lines)
    - Complete feature list for rebuilding.
12.  Testing_Workflow
      Contains the workflow you should use for the iteration/testing workflow.
---

## 🎯 Quick Navigation by Role

### I'm an Architect
1. Read [INDEX.md](INDEX.md) overview
2. Study [02-FEATURES-AND-REQUIREMENTS.md](02-FEATURES-AND-REQUIREMENTS.md)
3. Deep dive [03-ARCHITECTURE-AND-DESIGN.md](03-ARCHITECTURE-AND-DESIGN.md)
4. Review [04-COMPONENTS-BY-LAYER.md](04-COMPONENTS-BY-LAYER.md)

### I'm a Backend Developer
1. Start with [04-COMPONENTS-BY-LAYER.md](04-COMPONENTS-BY-LAYER.md)
2. Follow [06-WORKFLOWS-AND-PATTERNS.md](06-WORKFLOWS-AND-PATTERNS.md)
3. Study [05-TESTING-STRATEGY.md](05-TESTING-STRATEGY.md)
4. Reference [08-API-REFERENCE.md](08-API-REFERENCE.md)

### I'm a Frontend Developer
1. Read [09-PEDALBOARD-UI-AND-AUDIO-BACKEND.md](09-PEDALBOARD-UI-AND-AUDIO-BACKEND.md)
2. Study [10-QUICK-REFERENCE-PEDALBOARD-UI.md](10-QUICK-REFERENCE-PEDALBOARD-UI.md)
3. Reference UI section in [04-COMPONENTS-BY-LAYER.md](04-COMPONENTS-BY-LAYER.md)
4. Review [06-WORKFLOWS-AND-PATTERNS.md](06-WORKFLOWS-AND-PATTERNS.md)

### I'm a QA/Tester
1. Read [02-FEATURES-AND-REQUIREMENTS.md](02-FEATURES-AND-REQUIREMENTS.md)
2. Study [05-TESTING-STRATEGY.md](05-TESTING-STRATEGY.md)
3. Reference [08-API-REFERENCE.md](08-API-REFERENCE.md)
4. Review [07-DOCKER-AND-DEPLOYMENT.md](07-DOCKER-AND-DEPLOYMENT.md)

### I'm a DevOps/SRE
1. Start with [07-DOCKER-AND-DEPLOYMENT.md](07-DOCKER-AND-DEPLOYMENT.md)
2. Reference [08-API-REFERENCE.md](08-API-REFERENCE.md)
3. Review [02-FEATURES-AND-REQUIREMENTS.md](02-FEATURES-AND-REQUIREMENTS.md)
4. Study health checks and monitoring in deployment doc

---

## 📊 Statistics

| Metric | Value |
|--------|-------|
| Total Documentation | 5,941 lines |
| Total Files | 11 files |
| Code Examples | 75+ snippets |
| API Endpoints | 20+ endpoints |
| UI Components | 10+ components |
| Design Patterns | 6+ patterns |
| Test Patterns | 7+ patterns |
| Audio Backends | Pluggable: SoundFlow (primary), FileAudio, Mock; Future: JACK, ASIO |

---

## 🔑 Key Features Documented

### Architecture
- ✅ Three-layer clean architecture
- ✅ Full dependency injection
- ✅ Interface-based design for testability
- ✅ Pluggable audio backend pattern
- ✅ Configuration-based behavior

### Pedalboard UI
- ✅ Virtual effects rack with drag-and-drop
- ✅ Color-coded effect types
- ✅ Interactive parameter knobs
- ✅ Real-time WebSocket updates
- ✅ Effect chain visualization

### Audio Backend
- ✅ Abstract IAudioBackend interface
- ✅ SoundFlow implementation (production-ready, multi-device support)
- ✅ FileAudio implementation (file processing, testing)
- ✅ Mock implementation (for testing)
- ✅ JACK support pattern (future)
- ✅ ASIO support pattern (Windows)
- ✅ SoundFlow support pattern (future)

### API
- ✅ Device management endpoints
- ✅ Plugin management endpoints
- ✅ Pedalboard management endpoints
- ✅ Configuration endpoints
- ✅ Audio backend selection endpoints
- ✅ Health check endpoints

### Testing
- ✅ Unit tests (xUnit + NSubstitute)
- ✅ Integration tests (WebApplicationFactory)
- ✅ E2E tests (Playwright + Docker)
- ✅ Mock audio devices
- ✅ Generic DI validation

### Deployment
- ✅ Docker containerization
- ✅ Multi-stage builds
- ✅ Environment configuration
- ✅ Health checks
- ✅ CI/CD integration

---

## Implementation Phases

### Phase 1: Core Audio Backend
- [ ] Implement IAudioBackend interface
- [ ] SoundFlowAudioBackend
- [ ] FileAudioBackend
- [ ] MockAudioBackend

### Phase 2: Service Layer
- [ ] DeviceService
- [ ] PluginService
- [ ] PedalboardService

### Phase 3: REST API
- [ ] Device controller
- [ ] Plugin controller
- [ ] Pedalboard controller

### Phase 4: Blazor UI
- [ ] PedalboardPage
- [ ] EffectsRack
- [ ] EffectSlot
- [ ] KnobControl
- [ ] AvailableEffectsPanel

### Phase 5: Testing & Deployment
- [ ] Unit tests
- [ ] Integration tests
- [ ] E2E tests
- [ ] Docker setup

---

## 💡 Technology Stack

| Layer | Technology |
|-------|-----------|
| Runtime | .NET 9 Core |
| Web Framework | ASP.NET Core + Kestrel |
| Frontend | Blazor WebAssembly |
| Logging | NLog 5.x |
| Testing | xUnit + NSubstitute |
| E2E Testing | Playwright |
| Containerization | Docker |
| Audio Backend | Pluggable (SoundFlow primary, FileAudio, Mock) |

---

## 🎓 Learning Resources

- All code examples are ready-to-use
- Visual diagrams included
- Complete API specifications
- Mock implementations provided
- Test patterns documented
- Docker files included

---

## 📝 Document Status

- ✅ All foundation documents complete
- ✅ All implementation documents complete
- ✅ All advanced topics documented
- ✅ Quick reference provided
- ✅ API fully documented
- ✅ Ready for implementation phase

---

## Related Documentation

This documentation references:
- **mod-ui** - UI/pedalboard design inspiration
- **SoundFlow** - Primary audio backend framework
- **mod-host** - Audio plugin system reference

---

## 📧 Questions?

Refer to the appropriate document based on your question:
- **Architecture questions?** → [03-ARCHITECTURE-AND-DESIGN.md](03-ARCHITECTURE-AND-DESIGN.md)
- **How to code this?** → [04-COMPONENTS-BY-LAYER.md](04-COMPONENTS-BY-LAYER.md)
- **How to test?** → [05-TESTING-STRATEGY.md](05-TESTING-STRATEGY.md)
- **API details?** → [08-API-REFERENCE.md](08-API-REFERENCE.md)
- **Pedalboard UI?** → [09-PEDALBOARD-UI-AND-AUDIO-BACKEND.md](09-PEDALBOARD-UI-AND-AUDIO-BACKEND.md)
- **Visual examples?** → [10-QUICK-REFERENCE-PEDALBOARD-UI.md](10-QUICK-REFERENCE-PEDALBOARD-UI.md)

---

**Documentation Status:** Complete ✅  
**Ready for:** Implementation Phase 🚀  
**Last Updated:** January 2026
