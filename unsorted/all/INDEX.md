# Alsionyx Audio Manager - Documentation Index

## Project Overview

Alsionyx is a .NET 9 audio manager for LV2 plugins with a REST API and Blazor UI. It supports multiple audio backends (SoundFlow primary, FileAudio, Mock, with JACK/ASIO planned) and provides a virtual pedalboard interface for audio effect routing.

**Primary Stack:** .NET 9, ASP.NET Core, Blazor WebAssembly, xUnit + NSubstitute, Docker, NLog

---

## Documentation Files

**Foundation**
- [01-LOGGING-ARCHITECTURE.md](01-LOGGING-ARCHITECTURE.md) - NLog integration, structured logging
- [02-FEATURES-AND-REQUIREMENTS.md](02-FEATURES-AND-REQUIREMENTS.md) - Feature inventory
- [03-ARCHITECTURE-AND-DESIGN.md](03-ARCHITECTURE-AND-DESIGN.md) - System layers, design patterns

**Implementation**
- [04-COMPONENTS-BY-LAYER.md](04-COMPONENTS-BY-LAYER.md) - Component architecture
- [05-TESTING-STRATEGY.md](05-TESTING-STRATEGY.md) - Testing approach with xUnit/NSubstitute
- [06-WORKFLOWS-AND-PATTERNS.md](06-WORKFLOWS-AND-PATTERNS.md) - Common workflows
- [07-DOCKER-AND-DEPLOYMENT.md](07-DOCKER-AND-DEPLOYMENT.md) - Containerization

**Reference**
- [08-API-REFERENCE.md](08-API-REFERENCE.md) - All REST API endpoints
- [09-PEDALBOARD-UI-AND-AUDIO-BACKEND.md](09-PEDALBOARD-UI-AND-AUDIO-BACKEND.md) - Pedalboard UI, audio backend architecture
- [11-COMPLETE-REBUILD-SPECIFICATION.md](11-COMPLETE-REBUILD-SPECIFICATION.md) - Complete implementation guidelines
- [15-ENDPOINT-DISCOVERY-ARCHITECTURE.md](15-ENDPOINT-DISCOVERY-ARCHITECTURE.md) - Dynamic API endpoint discovery system

**Roadmap**
- [IMPLEMENTATION-ROADMAP.md](IMPLEMENTATION-ROADMAP.md) - 3-phase delivery roadmap

---

## Quick Start by Role

| Role | Start Here |
|------|-----------|
| Learning the system | [02-FEATURES-AND-REQUIREMENTS.md](02-FEATURES-AND-REQUIREMENTS.md) |
| Understanding design | [03-ARCHITECTURE-AND-DESIGN.md](03-ARCHITECTURE-AND-DESIGN.md) |
| Writing code | [04-COMPONENTS-BY-LAYER.md](04-COMPONENTS-BY-LAYER.md) |
| Writing tests | [05-TESTING-STRATEGY.md](05-TESTING-STRATEGY.md) |
| Building features | [06-WORKFLOWS-AND-PATTERNS.md](06-WORKFLOWS-AND-PATTERNS.md) |
| Deploying | [07-DOCKER-AND-DEPLOYMENT.md](07-DOCKER-AND-DEPLOYMENT.md) |
| Using the API | [08-API-REFERENCE.md](08-API-REFERENCE.md) |
| Rebuilding from scratch | [11-COMPLETE-REBUILD-SPECIFICATION.md](11-COMPLETE-REBUILD-SPECIFICATION.md) |

---

## Implementation Phases

**Phase 1: Core Audio System**
- Audio backends (SoundFlow, FileAudio, Mock)
- Plugin discovery (LV2)
- Routing engine
- REST API

**Phase 2: Pedalboard System & UI**
- Pedalboard service
- Blazor UI components
- Real-time WebSocket updates
- Backend controls integration

**Phase 3: Polish & Extended Backends**
- Advanced features (presets, templates, undo/redo)
- JACK backend
- ASIO backend
- Performance optimization

---

### 1. NLog Instead of Serilog
- **Reason:** Generic `ILog<T>` design pattern works better with NLog's factory approach
- **Benefit:** Type-safe logging with compile-time checking

### 2. NSubstitute Instead of Moq
- **Reason:** Better null-safety and modern fluent API
- **Benefit:** Cleaner test code, better IntelliSense support

### 3. Mock Audio Devices in Tests
- **Reason:** No hardware dependency, reproducible results, faster tests
- **Benefit:** Tests run anywhere, no ALSA configuration needed

### 4. Docker-Based Testing
- **Reason:** Solves HTTP/HTTPS redirect issues, clean environment every run
- **Benefit:** No cert caching, no environment interference

### 5. Configuration-Based Provider Selection
- **Reason:** Single codebase, different providers per environment
- **Benefit:** Prod uses real providers, tests use mocks

---

## Related Projects

- **JackSharpCore** - Reference logging architecture (13 logging files)
- **AlsaSharp.Library** - Reference NLog implementation (13 logging files)
- **pi-stomp** - Reference UI patterns (Blazor)
- **mod-host** - Reference audio plugin system

---

## Key Resources

- **Audio Backend Architecture** → [09-PEDALBOARD-UI-AND-AUDIO-BACKEND.md](09-PEDALBOARD-UI-AND-AUDIO-BACKEND.md)
- **Service Layer Overview** → [03-ARCHITECTURE-AND-DESIGN.md](03-ARCHITECTURE-AND-DESIGN.md)
- **Plugin Discovery** → [06-WORKFLOWS-AND-PATTERNS.md](06-WORKFLOWS-AND-PATTERNS.md)
- **API Endpoints** → [08-API-REFERENCE.md](08-API-REFERENCE.md)
- **Testing Examples** → [05-TESTING-STRATEGY.md](05-TESTING-STRATEGY.md)

**Last Updated:** January 2026
