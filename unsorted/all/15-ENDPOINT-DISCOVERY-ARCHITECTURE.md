# API Endpoint Discovery Architecture

## Overview

The Endpoint Discovery system is a key architectural component that enables the Blazor UI to dynamically discover available API endpoints at runtime. This removes hardcoded endpoint paths from the client code and makes the system more maintainable, extensible, and resilient to API changes.

## Problem Solved

**Before Endpoint Discovery:**
- UI hardcodes endpoint paths: `/api/audio/backends`, `/api/pedalboards`, etc.
- Adding new endpoints requires UI code changes
- Refactoring API routes breaks UI without compiler warnings
- No runtime validation that endpoints exist
- UI and API become tightly coupled

**After Endpoint Discovery:**
- UI queries `/api/configuration/endpoints` on load
- All available endpoints are dynamically discovered
- New endpoints are automatically available to UI
- UI operations are mapped to endpoints via attributes
- API changes are immediately reflected in UI

## Architecture

### Configuration Data Model

Located in `Alsionyx.Shared/EndpointConfiguration.cs`:

```csharp
public class EndpointMetadata
{
    // HTTP method and route
    public required string Method { get; set; }
    public required string Route { get; set; }
    
    // UI-facing information
    public required string OperationName { get; set; }
    public required List<string> UiOperations { get; set; }
    
    // Organization
    public required string Category { get; set; }
    public required string ControllerName { get; set; }
    
    // Response information
    public required Dictionary<int, string> ResponseCodes { get; set; }
    public bool RequiresAuth { get; set; }
}

public class ApiEndpointConfiguration
{
    public required string Version { get; set; }
    public required string BaseUrl { get; set; }
    
    // Organized endpoints
    public required Dictionary<string, List<EndpointMetadata>> EndpointsByCategory { get; set; }
    public required List<EndpointMetadata> AllEndpoints { get; set; }
    
    // Maps UI operations to endpoints
    public required Dictionary<string, EndpointMetadata> OperationMap { get; set; }
    
    public DateTime GeneratedAt { get; set; }
    
    // Helper methods
    public EndpointMetadata? GetEndpoint(string uiOperation);
    public List<EndpointMetadata> GetEndpoints(string category);
}
```

### Discovery Service

Located in `Alsionyx.Api/Services/EndpointDiscoveryService.cs`:

The service uses reflection to scan all controllers and extract metadata:

1. **Scans Assembly** - Finds all `ControllerBase` types
2. **Extracts Metadata** - Reads attributes from methods:
   - `[HttpGet]`, `[HttpPost]`, etc. - HTTP method
   - `[Route(...)]` - Endpoint route
   - `[OperationName(...)]` - Human-readable name
   - `[EndpointCategory(...)]` - Grouping
   - `[UiOperations(...)]` - UI operations supported
   - `[ProducesResponseType(...)]` - Response codes
3. **Builds Configuration** - Creates the complete configuration object
4. **Returns at Runtime** - Controllers call this to get metadata

### Metadata Attributes

Added to `EndpointDiscoveryService.cs`:

```csharp
[AttributeUsage(AttributeTargets.Method)]
public class OperationNameAttribute : Attribute
{
    public string Name { get; }
}

[AttributeUsage(AttributeTargets.Method)]
public class EndpointCategoryAttribute : Attribute
{
    public string Category { get; }
}

[AttributeUsage(AttributeTargets.Method)]
public class UiOperationsAttribute : Attribute
{
    public string[] Operations { get; }
}
```

### Configuration Controller

Located in `Alsionyx.Api/Controllers/EndpointConfigurationController.cs`:

Exposes three endpoints for the UI:

```
GET /api/configuration/endpoints
  Returns: Complete ApiEndpointConfiguration
  Usage: UI calls on load to get all endpoints

GET /api/configuration/endpoints/category/{category}
  Returns: Endpoints for specific category (e.g., "Audio", "Pedalboard")
  Usage: UI fetches only relevant endpoints if needed

GET /api/configuration/endpoints/operation/{operation}
  Returns: Specific EndpointMetadata for a UI operation
  Usage: UI looks up endpoint for specific operation
```

## Usage Flow

### UI Load Time (Blazor WebAssembly)

```
1. User loads Alsionyx application
2. App.razor component mounts
3. Initialize() calls ApiService.LoadEndpointsAsync()
4. ApiService.LoadEndpointsAsync():
   - GET http://api:5014/api/configuration/endpoints
   - Deserialize into ApiEndpointConfiguration
   - Store in CascadingParameter or service state
5. UI components can now:
   - Access configuration.AllEndpoints
   - Look up operations: configuration.GetEndpoint("LoadAudioBackends")
   - Filter by category: configuration.GetEndpoints("Audio")
6. Build HTTP calls dynamically:
   - const endpoint = configuration.GetEndpoint("LoadAudioBackends");
   - var response = await client.GetAsync(endpoint.Route);
```

### Adding New Endpoints

To add a new endpoint that's automatically discoverable:

```csharp
[ApiController]
[Route("api/pedalboards")]
[EndpointCategory("Pedalboard")]
public class PedalboardsController : ControllerBase
{
    [HttpPost]
    [OperationName("Create Pedalboard")]
    [UiOperations("CreatePedalboard")]
    [ProducesResponseType(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Create([FromBody] CreatePedalboardRequest request)
    {
        // Implementation
    }
}
```

When the API starts:
1. Discovery service finds this method
2. Reads attributes: "Create Pedalboard", "CreatePedalboard", etc.
3. Includes in configuration
4. UI loads configuration and sees "CreatePedalboard" operation

## Benefits

### For Developers
- **No Hardcoded Routes** - Routes are discovered from attributes
- **Automatic Documentation** - Attributes describe the API
- **Easy Refactoring** - Change route in one place
- **Type Safety** - Operation names are validated at runtime
- **Self-Documenting** - Attributes explain what each endpoint does

### For the UI
- **Dynamic Endpoint Resolution** - No hardcoded paths
- **Runtime Validation** - Can check if operation is available
- **Intelligent Error Handling** - Knows expected response codes
- **Feature Detection** - Can detect if new endpoints exist
- **Fallback Support** - Can handle missing endpoints gracefully

### For Testing
- **Mock Discovery** - Can stub configuration in tests
- **Validation** - Integration tests verify all endpoints are discoverable
- **API Contract Testing** - Can verify endpoints match configuration

## Implementation Details

### Reflection-Based Discovery

The service uses reflection to extract:

1. **HTTP Method** - From `[HttpGet]`, `[HttpPost]`, etc.
2. **Route** - From `[Route]` attributes, resolves `[controller]` token
3. **Operation Names** - From `[OperationName]` and `[UiOperations]` attributes
4. **Categories** - From `[EndpointCategory]` attributes
5. **Response Codes** - From `[ProducesResponseType]` attributes
6. **Authorization** - From `[Authorize]` attributes

### Route Resolution

Routes are resolved at discovery time:

```
Base: api/[controller]
Controller: AudioBackendsController (strips "Controller")
Result: /api/audiobackends

With Route Attribute: [Route("api/audio/backends")]
Result: /api/audio/backends

With Method Route: [Route("{id}")]
Result: /api/audio/backends/{id}
```

### Operation Mapping

Each endpoint can support multiple UI operations:

```csharp
[HttpGet("{id}")]
[UiOperations("LoadPedalboardDetails", "GetPedalboard")]
public async Task<IActionResult> GetById(string id)
{
    // Both operations resolve to this endpoint
}

// UI code:
var endpoint = config.GetEndpoint("LoadPedalboardDetails");
var endpoint2 = config.GetEndpoint("GetPedalboard");
// Both return the same EndpointMetadata
```

## Caching and Performance

The discovery service:
- **Discovers at Request Time** - Called when `/api/configuration/endpoints` is requested
- **Uses Reflection Caching** - .NET caches reflection results
- **Lightweight** - Only runs on specific requests, not on every API call
- **Cacheable** - UI can cache configuration in LocalStorage and revalidate periodically

For production optimization:
- Cache the configuration in memory (ApplicationState)
- Implement cache invalidation when controllers change
- Add `Cache-Control` headers to the endpoint response

## Future Enhancements

### Versioning
```csharp
public class ApiEndpointConfiguration
{
    public required string Version { get; set; }  // e.g., "v1", "v2"
    public required string MinimumUiVersion { get; set; }
}
```

### Capability Detection
```csharp
public List<string> Capabilities { get; set; }
// e.g., ["WebSockets", "RealTimeUpdates", "FileUpload"]
```

### Authentication Metadata
```csharp
public class EndpointMetadata
{
    public required List<string> RequiredScopes { get; set; }
    public required List<string> AllowedRoles { get; set; }
}
```

### Rate Limiting Information
```csharp
public class EndpointMetadata
{
    public required RateLimitMetadata? RateLimit { get; set; }
}

public class RateLimitMetadata
{
    public required int RequestsPerMinute { get; set; }
    public required int BurstSize { get; set; }
}
```

## Example: Audio Backend Discovery

### API Implementation

```csharp
[ApiController]
[Route("api/audio/backends")]
[EndpointCategory("Audio")]
public class AudioBackendsController : ControllerBase
{
    [HttpGet]
    [OperationName("Get All Audio Backends")]
    [UiOperations("LoadAudioBackends", "RefreshAudioBackends")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status500InternalServerError)]
    public IActionResult GetAll() { ... }

    [HttpGet("{name}")]
    [OperationName("Get Audio Backend Details")]
    [UiOperations("GetAudioBackendDetails")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public IActionResult GetByName(string name) { ... }
}
```

### UI Usage (Blazor)

```csharp
public partial class AudioBackendSelector : ComponentBase
{
    [Inject]
    public ApiEndpointConfiguration Configuration { get; set; }

    private List<AudioBackend> backends = new();

    protected override async Task OnInitializedAsync()
    {
        // Discover the endpoint
        var endpoint = Configuration.GetEndpoint("LoadAudioBackends");
        if (endpoint == null)
        {
            // Handle missing endpoint gracefully
            return;
        }

        // Build HTTP request from metadata
        var response = await Http.GetAsync(
            Configuration.BaseUrl + endpoint.Route
        );

        if (response.IsSuccessStatusCode)
        {
            var json = await response.Content.ReadAsStringAsync();
            backends = JsonSerializer.Deserialize<List<AudioBackend>>(json);
        }
    }
}
```

## Integration with Existing Features

### AudioBackendsController Example

The `AudioBackendsController` is annotated with discovery metadata:

**Before:**
```csharp
[HttpGet]
public IActionResult GetAll() { ... }
```

**After:**
```csharp
[HttpGet]
[OperationName("Get All Audio Backends")]
[EndpointCategory("Audio")]
[UiOperations("LoadAudioBackends", "RefreshAudioBackends")]
public IActionResult GetAll() { ... }
```

This means:
- Operation "LoadAudioBackends" maps to this endpoint
- Grouped in "Audio" category
- Can be called by both "LoadAudioBackends" and "RefreshAudioBackends" operations

## Testing

### Integration Test Example

```csharp
[Test]
public async Task DiscoveryService_IncludesAudioBackendsEndpoints()
{
    // Arrange
    var discovery = new EndpointDiscoveryService(logger, httpContextAccessor);

    // Act
    var config = await discovery.DiscoverEndpointsAsync();

    // Assert
    Assert.That(config.GetEndpoint("LoadAudioBackends"), Is.Not.Null);
    Assert.That(config.GetEndpoints("Audio"), Has.Count.GreaterThan(0));
}
```

### Blazor UI Test Example

```csharp
[Test]
public async Task AudioBackendSelector_LoadsFromConfiguration()
{
    // Arrange
    var configuration = new ApiEndpointConfiguration
    {
        AllEndpoints = new(),
        OperationMap = new() { { "LoadAudioBackends", new() { Route = "/api/audio/backends" } } }
    };

    // Act
    var component = RenderComponent<AudioBackendSelector>(
        parameters => parameters.CascadingValue(configuration)
    );

    // Assert
    var endpoint = configuration.GetEndpoint("LoadAudioBackends");
    Assert.That(endpoint?.Route, Is.EqualTo("/api/audio/backends"));
}
```

## Deployment Considerations

### First Load Performance
- Configuration is fetched on app load
- Consider gzipping the response
- Can be cached aggressively (immutable unless API changes)

### API Changes
- New endpoints are immediately discoverable
- Removed endpoints will cause UI operations to fail gracefully
- Version mismatch can be detected

### Monitoring
- Log failed discoveries in Application Insights
- Monitor configuration fetch latency
- Track operations that fail due to missing endpoints

## Related Documentation

- [08-API-REFERENCE.md](08-API-REFERENCE.md) - Manual endpoint reference
- [03-ARCHITECTURE-AND-DESIGN.md](03-ARCHITECTURE-AND-DESIGN.md) - Overall architecture
- [04-COMPONENTS-BY-LAYER.md](04-COMPONENTS-BY-LAYER.md) - Component structure
- [06-WORKFLOWS-AND-PATTERNS.md](06-WORKFLOWS-AND-PATTERNS.md) - Common patterns
