# API Reference

## Base URL

- **Production:** `https://alsaudio.example.com/api`
- **Development:** `http://localhost:5000/api`

## Authentication

Currently no authentication. Future versions will add Bearer token support.

---

## Device Endpoints

### GET /devices

List all available audio devices.

**Request:**
```
GET /api/devices HTTP/1.1
Host: localhost:5000
```

**Response (200 OK):**
```json
[
  {
    "name": "Intel HDA 0",
    "deviceClass": "Duplex",
    "channels": 2,
    "maxChannels": 8,
    "isPlayback": true,
    "isCapture": true
  },
  {
    "name": "USB Audio Device",
    "deviceClass": "Playback",
    "channels": 2,
    "maxChannels": 2,
    "isPlayback": true,
    "isCapture": false
  },
  {
    "name": "Generic Audio",
    "deviceClass": "Duplex",
    "channels": 2,
    "maxChannels": 4,
    "isPlayback": true,
    "isCapture": true
  }
]
```

**Error (500 Internal Server Error):**
```json
{
  "error": "Device enumeration failed",
  "statusCode": 500,
  "timestamp": "2026-01-06T10:30:00Z"
}
```

**cURL Example:**
```bash
curl -X GET http://localhost:5000/api/devices
```

---

### GET /devices/playback

List playback-capable devices.

**Request:**
```
GET /api/devices/playback HTTP/1.1
```

**Response (200 OK):**
```json
[
  {
    "name": "Intel HDA 0",
    "deviceClass": "Duplex",
    "channels": 2,
    "maxChannels": 8,
    "isPlayback": true,
    "isCapture": true
  },
  {
    "name": "USB Audio Device",
    "deviceClass": "Playback",
    "channels": 2,
    "maxChannels": 2,
    "isPlayback": true,
    "isCapture": false
  }
]
```

**cURL Example:**
```bash
curl -X GET http://localhost:5000/api/devices/playback
```

---

### GET /devices/capture

List capture-capable devices.

**Request:**
```
GET /api/devices/capture HTTP/1.1
```

**Response (200 OK):**
```json
[
  {
    "name": "Intel HDA 0",
    "deviceClass": "Duplex",
    "channels": 2,
    "maxChannels": 8,
    "isPlayback": true,
    "isCapture": true
  },
  {
    "name": "Generic Audio",
    "deviceClass": "Duplex",
    "channels": 2,
    "maxChannels": 4,
    "isPlayback": true,
    "isCapture": true
  }
]
```

**cURL Example:**
```bash
curl -X GET http://localhost:5000/api/devices/capture
```

---

### GET /devices/{deviceName}/formats

Get supported audio formats for a device.

**Request:**
```
GET /api/devices/Intel%20HDA%200/formats HTTP/1.1
```

**Path Parameters:**
- `deviceName` (URL encoded string) - Name of device

**Response (200 OK):**
```json
[
  {
    "sampleRate": 44100,
    "bitDepth": "16-bit",
    "channels": 2
  },
  {
    "sampleRate": 48000,
    "bitDepth": "16-bit",
    "channels": 2
  },
  {
    "sampleRate": 48000,
    "bitDepth": "24-bit",
    "channels": 2
  },
  {
    "sampleRate": 96000,
    "bitDepth": "24-bit",
    "channels": 2
  },
  {
    "sampleRate": 192000,
    "bitDepth": "24-bit",
    "channels": 2
  }
]
```

**Error (404 Not Found):**
```json
{
  "error": "Device not found: Unknown Device",
  "statusCode": 404,
  "timestamp": "2026-01-06T10:30:00Z"
}
```

**cURL Example:**
```bash
curl -X GET "http://localhost:5000/api/devices/Intel%20HDA%200/formats"
```

---

## Configuration Endpoints

### GET /configuration

Get current audio configuration.

**Request:**
```
GET /api/configuration HTTP/1.1
```

**Response (200 OK):**
```json
{
  "activeDevice": "Intel HDA 0",
  "sampleRate": 48000,
  "bitDepth": "24-bit",
  "channels": 2,
  "pluginChain": [
    {
      "pluginUri": "http://example.com/plugins/reverb",
      "order": 0,
      "parameters": {
        "dryWet": 0.5,
        "roomSize": 0.7
      }
    },
    {
      "pluginUri": "http://example.com/plugins/compressor",
      "order": 1,
      "parameters": {
        "threshold": -20.0,
        "ratio": 4.0
      }
    }
  ],
  "lastModified": "2026-01-06T08:15:00Z"
}
```

**cURL Example:**
```bash
curl -X GET http://localhost:5000/api/configuration
```

---

### POST /configuration/device

Set active audio device.

**Request:**
```
POST /api/configuration/device HTTP/1.1
Content-Type: application/json

{
  "deviceName": "USB Audio Device"
}
```

**Request Body:**
- `deviceName` (string, required) - Name of device to activate

**Response (200 OK):**
```json
{
  "message": "Device updated successfully",
  "activeDevice": "USB Audio Device"
}
```

**Error (400 Bad Request):**
```json
{
  "error": "Device not found: Unknown Device",
  "statusCode": 400,
  "timestamp": "2026-01-06T10:30:00Z"
}
```

**Error (500 Internal Server Error):**
```json
{
  "error": "Failed to update device",
  "statusCode": 500,
  "timestamp": "2026-01-06T10:30:00Z"
}
```

**cURL Example:**
```bash
curl -X POST http://localhost:5000/api/configuration/device \
  -H "Content-Type: application/json" \
  -d '{"deviceName": "USB Audio Device"}'
```

---

### POST /configuration/format

Update audio format configuration.

**Request:**
```
POST /api/configuration/format HTTP/1.1
Content-Type: application/json

{
  "sampleRate": 96000,
  "bitDepth": "24-bit",
  "channels": 2
}
```

**Request Body:**
- `sampleRate` (integer, required) - Sample rate in Hz. Valid values: 44100, 48000, 96000, 192000
- `bitDepth` (string, required) - Bit depth. Valid values: "16-bit", "24-bit", "32-bit"
- `channels` (integer, required) - Number of channels. Valid range: 1-8

**Response (200 OK):**
```json
{
  "message": "Format updated successfully",
  "sampleRate": 96000,
  "bitDepth": "24-bit",
  "channels": 2
}
```

**Error (400 Bad Request):**
```json
{
  "error": "Invalid sample rate: 99999. Valid rates: 44100, 48000, 96000, 192000",
  "statusCode": 400,
  "timestamp": "2026-01-06T10:30:00Z"
}
```

**cURL Example:**
```bash
curl -X POST http://localhost:5000/api/configuration/format \
  -H "Content-Type: application/json" \
  -d '{
    "sampleRate": 96000,
    "bitDepth": "24-bit",
    "channels": 2
  }'
```

---

### POST /configuration/plugins

Set plugin chain.

**Request:**
```
POST /api/configuration/plugins HTTP/1.1
Content-Type: application/json

{
  "plugins": [
    {
      "pluginUri": "http://example.com/plugins/reverb",
      "order": 0,
      "parameters": {
        "dryWet": 0.5,
        "roomSize": 0.7
      }
    },
    {
      "pluginUri": "http://example.com/plugins/compressor",
      "order": 1,
      "parameters": {
        "threshold": -20.0,
        "ratio": 4.0
      }
    }
  ]
}
```

**Request Body:**
- `plugins` (array, required) - Array of plugin chain items
  - `pluginUri` (string, required) - Plugin identifier
  - `order` (integer, required) - Position in chain (0-based)
  - `parameters` (object, optional) - Plugin-specific parameters

**Response (200 OK):**
```json
{
  "message": "Plugin chain updated successfully",
  "chainLength": 2
}
```

**Error (400 Bad Request):**
```json
{
  "error": "Plugin not found: http://example.com/plugins/unknown",
  "statusCode": 400,
  "timestamp": "2026-01-06T10:30:00Z"
}
```

**cURL Example:**
```bash
curl -X POST http://localhost:5000/api/configuration/plugins \
  -H "Content-Type: application/json" \
  -d '{
    "plugins": [
      {
        "pluginUri": "http://example.com/plugins/reverb",
        "order": 0,
        "parameters": {"dryWet": 0.5}
      }
    ]
  }'
```

---

### POST /configuration/reset

Reset configuration to defaults.

**Request:**
```
POST /api/configuration/reset HTTP/1.1
```

**Response (200 OK):**
```json
{
  "message": "Configuration reset to defaults",
  "activeDevice": "Default",
  "sampleRate": 48000,
  "bitDepth": "16-bit",
  "channels": 2
}
```

**cURL Example:**
```bash
curl -X POST http://localhost:5000/api/configuration/reset
```

---

## Plugin Endpoints

### GET /plugins

List all available LV2 plugins.

**Request:**
```
GET /api/plugins HTTP/1.1
```

**Response (200 OK):**
```json
[
  {
    "uri": "http://example.com/plugins/reverb",
    "name": "Reverb Chamber",
    "version": "1.0",
    "type": "Reverb",
    "inputPorts": 2,
    "outputPorts": 2,
    "isInstantiable": true
  },
  {
    "uri": "http://example.com/plugins/compressor",
    "name": "Dynamic Compressor",
    "version": "1.0",
    "type": "Compressor",
    "inputPorts": 2,
    "outputPorts": 2,
    "isInstantiable": true
  },
  {
    "uri": "http://example.com/plugins/synth",
    "name": "Basic Synth",
    "version": "1.0",
    "type": "Synth",
    "inputPorts": 0,
    "outputPorts": 2,
    "isInstantiable": true
  }
]
```

**cURL Example:**
```bash
curl -X GET http://localhost:5000/api/plugins
```

---

### GET /plugins/type/{type}

Filter plugins by type.

**Request:**
```
GET /api/plugins/type/Reverb HTTP/1.1
```

**Path Parameters:**
- `type` (string) - Plugin type. Valid values: Reverb, Delay, Compressor, Equalizer, Distortion, Synth, Sampler, Filter, Analyzer, Generic

**Response (200 OK):**
```json
[
  {
    "uri": "http://example.com/plugins/reverb",
    "name": "Reverb Chamber",
    "version": "1.0",
    "type": "Reverb",
    "inputPorts": 2,
    "outputPorts": 2,
    "isInstantiable": true
  }
]
```

**cURL Example:**
```bash
curl -X GET http://localhost:5000/api/plugins/type/Reverb
```

---

### GET /plugins/{pluginUri}

Get specific plugin information.

**Request:**
```
GET /api/plugins/http%3A%2F%2Fexample.com%2Fplugins%2Freverb HTTP/1.1
```

**Path Parameters:**
- `pluginUri` (URL encoded string) - Plugin URI

**Response (200 OK):**
```json
{
  "uri": "http://example.com/plugins/reverb",
  "name": "Reverb Chamber",
  "version": "1.0",
  "type": "Reverb",
  "inputPorts": 2,
  "outputPorts": 2,
  "isInstantiable": true
}
```

**Error (404 Not Found):**
```json
{
  "error": "Plugin not found: http://example.com/plugins/unknown",
  "statusCode": 404,
  "timestamp": "2026-01-06T10:30:00Z"
}
```

**cURL Example:**
```bash
curl -X GET "http://localhost:5000/api/plugins/http%3A%2F%2Fexample.com%2Fplugins%2Freverb"
```

---

## Health & Status Endpoints

### GET /health

Health check endpoint.

**Request:**
```
GET /api/health HTTP/1.1
```

**Response (200 OK):**
```json
{
  "status": "healthy",
  "timestamp": "2026-01-06T10:30:00Z",
  "uptime": "02:15:30"
}
```

**Response (503 Service Unavailable):**
```json
{
  "status": "unhealthy",
  "timestamp": "2026-01-06T10:30:00Z",
  "errors": [
    "Audio device enumeration failed",
    "Configuration store unavailable"
  ]
}
```

**cURL Example:**
```bash
curl -X GET http://localhost:5000/api/health
```

---

## Error Responses

All error responses follow this format:

```json
{
  "error": "Human-readable error message",
  "statusCode": 400,
  "timestamp": "2026-01-06T10:30:00Z",
  "traceId": "0HN1GMLFMTQQK:00000001"
}
```

### HTTP Status Codes

| Code | Meaning | Typical Cause |
|------|---------|---------------|
| 200 | OK | Request succeeded |
| 400 | Bad Request | Invalid parameters |
| 404 | Not Found | Resource doesn't exist |
| 500 | Internal Server Error | Server error |
| 503 | Service Unavailable | Health check failed |

---

## CORS Configuration

By default, CORS is configured as:

**Production:**
```
AllowedOrigins: [https://example.com]
AllowedMethods: [GET, POST, PUT, DELETE, OPTIONS]
AllowedHeaders: [Content-Type, Authorization]
AllowCredentials: true
```

**Development/Testing:**
```
AllowedOrigins: [http://localhost:3000, http://localhost:5002]
AllowedMethods: [GET, POST, PUT, DELETE, OPTIONS]
AllowedHeaders: [*]
AllowCredentials: true
```

---

## Rate Limiting

Currently no rate limiting. Future versions will implement:
- 100 requests per minute per IP
- 10 configuration changes per second
- 1000 device queries per minute

---

## Pagination (Future)

Future API versions will support pagination for large result sets:

```json
{
  "data": [...],
  "pagination": {
    "pageNumber": 1,
    "pageSize": 20,
    "totalCount": 150,
    "totalPages": 8
  }
}
```

---

## Content Negotiation

Supported content types:
- `application/json` (default)
- `application/xml` (future)

---

## API Client Examples

### Python with requests
```python
import requests

# Get all devices
response = requests.get('http://localhost:5000/api/devices')
devices = response.json()

# Set device
response = requests.post(
    'http://localhost:5000/api/configuration/device',
    json={'deviceName': 'Intel HDA 0'}
)
```

### JavaScript with fetch
```javascript
// Get all devices
const response = await fetch('http://localhost:5000/api/devices');
const devices = await response.json();

// Set device
const response = await fetch(
  'http://localhost:5000/api/configuration/device',
  {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ deviceName: 'Intel HDA 0' })
  }
);
```

### Blazor C#
```csharp
// Using HttpClient
var http = new HttpClient { BaseAddress = new Uri("http://localhost:5000") };

// Get devices
var devices = await http.GetFromJsonAsync<AudioDevice[]>("api/devices");

// Set device
await http.PostAsJsonAsync("api/configuration/device", 
    new { deviceName = "Intel HDA 0" });
```

---

## Pedalboard Endpoints

### GET /pedalboards

List all pedalboards.

**Request:**
```
GET /api/pedalboards HTTP/1.1
```

**Response (200 OK):**
```json
[
  {
    "id": "my-pedalboard-1",
    "name": "Guitar Chain",
    "description": "My guitar effects setup",
    "audioBackend": "ALSA",
    "inputDevice": "Intel HDA 0",
    "outputDevice": "Intel HDA 0",
    "createdAt": "2026-01-06T08:00:00Z",
    "lastModified": "2026-01-06T10:30:00Z",
    "effectCount": 3
  },
  {
    "id": "synth-rig",
    "name": "Synth Rig",
    "description": "Synthesizer chain",
    "audioBackend": "JACK",
    "inputDevice": "default",
    "outputDevice": "default",
    "createdAt": "2026-01-05T15:00:00Z",
    "lastModified": "2026-01-05T18:00:00Z",
    "effectCount": 5
  }
]
```

**cURL Example:**
```bash
curl -X GET http://localhost:5000/api/pedalboards
```

---

### POST /pedalboards

Create new pedalboard.

**Request:**
```
POST /api/pedalboards HTTP/1.1
Content-Type: application/json

{
  "name": "New Setup",
  "description": "Testing new effects",
  "audioBackend": "ALSA",
  "inputDevice": "Intel HDA 0",
  "outputDevice": "Intel HDA 0",
  "sampleRate": 48000
}
```

**Response (201 Created):**
```json
{
  "id": "new-setup-20260106",
  "name": "New Setup",
  "description": "Testing new effects",
  "audioBackend": "ALSA",
  "inputDevice": "Intel HDA 0",
  "outputDevice": "Intel HDA 0",
  "createdAt": "2026-01-06T10:35:00Z",
  "lastModified": "2026-01-06T10:35:00Z",
  "effects": []
}
```

**cURL Example:**
```bash
curl -X POST http://localhost:5000/api/pedalboards \
  -H "Content-Type: application/json" \
  -d '{
    "name": "New Setup",
    "audioBackend": "ALSA",
    "inputDevice": "Intel HDA 0",
    "outputDevice": "Intel HDA 0"
  }'
```

---

### GET /pedalboards/{id}

Get pedalboard details.

**Request:**
```
GET /api/pedalboards/my-pedalboard-1 HTTP/1.1
```

**Response (200 OK):**
```json
{
  "id": "my-pedalboard-1",
  "name": "Guitar Chain",
  "description": "My guitar effects setup",
  "audioBackend": "ALSA",
  "inputDevice": "Intel HDA 0",
  "outputDevice": "Intel HDA 0",
  "sampleRate": 48000,
  "bufferSize": 256,
  "createdAt": "2026-01-06T08:00:00Z",
  "lastModified": "2026-01-06T10:30:00Z",
  "effects": [
    {
      "instanceId": "reverb-1",
      "pluginUri": "http://example.com/plugins/reverb",
      "pluginName": "Reverb Chamber",
      "enabled": true,
      "parameters": [
        {
          "name": "dryWet",
          "value": 0.5
        },
        {
          "name": "roomSize",
          "value": 0.7
        }
      ]
    }
  ]
}
```

---

### PUT /pedalboards/{id}

Update pedalboard metadata.

**Request:**
```
PUT /api/pedalboards/my-pedalboard-1 HTTP/1.1
Content-Type: application/json

{
  "name": "Updated Guitar Chain",
  "description": "New description"
}
```

**Response (200 OK):**
```json
{
  "id": "my-pedalboard-1",
  "name": "Updated Guitar Chain",
  "description": "New description",
  "lastModified": "2026-01-06T11:00:00Z"
}
```

---

### DELETE /pedalboards/{id}

Delete pedalboard.

**Request:**
```
DELETE /api/pedalboards/my-pedalboard-1 HTTP/1.1
```

**Response (204 No Content):**
```
(empty body)
```

---

### POST /pedalboards/{id}/effects

Add effect to pedalboard.

**Request:**
```
POST /api/pedalboards/my-pedalboard-1/effects HTTP/1.1
Content-Type: application/json

{
  "pluginUri": "http://example.com/plugins/compressor"
}
```

**Response (201 Created):**
```json
{
  "instanceId": "compressor-1",
  "pluginUri": "http://example.com/plugins/compressor",
  "pluginName": "Dynamic Compressor",
  "position": 1,
  "enabled": true,
  "parameters": [
    {
      "name": "threshold",
      "value": -20.0,
      "min": -60.0,
      "max": 0.0
    },
    {
      "name": "ratio",
      "value": 4.0,
      "min": 1.0,
      "max": 16.0
    }
  ]
}
```

---

### DELETE /pedalboards/{id}/effects/{instanceId}

Remove effect from pedalboard.

**Request:**
```
DELETE /api/pedalboards/my-pedalboard-1/effects/compressor-1 HTTP/1.1
```

**Response (204 No Content):**
```
(empty body)
```

---

### PUT /pedalboards/{id}/effects/{instanceId}/parameters/{paramName}

Set effect parameter value.

**Request:**
```
PUT /api/pedalboards/my-pedalboard-1/effects/reverb-1/parameters/dryWet HTTP/1.1
Content-Type: application/json

{
  "value": 0.75
}
```

**Response (200 OK):**
```json
{
  "parameterName": "dryWet",
  "value": 0.75,
  "min": 0.0,
  "max": 1.0
}
```

---

### GET /audio/backends

List available audio backends.

**Request:**
```
GET /api/audio/backends HTTP/1.1
```

**Response (200 OK):**
```json
[
  {
    "name": "ALSA",
    "displayName": "ALSA (Linux)",
    "available": true,
    "isDefault": true,
    "requiresConfiguration": false
  },
  {
    "name": "JACK",
    "displayName": "JACK Audio Connection Kit",
    "available": true,
    "isDefault": false,
    "requiresConfiguration": true
  },
  {
    "name": "ASIO",
    "displayName": "ASIO (Windows)",
    "available": false,
    "isDefault": false,
    "requiresConfiguration": true
  },
  {
    "name": "SoundFlow",
    "displayName": "SoundFlow",
    "available": false,
    "isDefault": false,
    "requiresConfiguration": true
  }
]
```

---

## Related Documentation

- [Components by Layer](04-COMPONENTS-BY-LAYER.md) - API controller implementation
- [Pedalboard UI & Audio Backend](09-PEDALBOARD-UI-AND-AUDIO-BACKEND.md) - Pedalboard design and audio backend architecture
- [Testing Strategy](05-TESTING-STRATEGY.md) - Integration testing API endpoints
