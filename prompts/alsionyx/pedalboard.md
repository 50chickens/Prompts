Both hardware audio devices and LV2 plugins implement IAudioDevice. A pedalboard routes audio through a matrix of these devices using port names in the format "deviceOrPluginId:portName".

IAudioDevice (Core)

```csharp
interface IAudioDevice
{
    string Id { get; }
    string Name { get; }
    IReadOnlyList<string> InputPorts { get; }
    IReadOnlyList<string> OutputPorts { get; }
    Task InitializeAsync();
    Task StartAsync();
}
```

SoundFlowAudioDevice : IAudioDevice - wraps the SoundFlow backend; ports mapped from SoundFlow device channels
TinyGainPlugin : IAudioDevice - wraps the TinyGain LV2 plugin; InputPorts = ["audio_in"], OutputPorts = ["audio_out"]

Plugin parameter (Core)

```csharp
class PluginParameter
{
    public string Symbol { get; set; }
    public string Name { get; set; }
    public float Min { get; set; }
    public float Max { get; set; }
    public float Value { get; set; }
}
```

Port connection (Core)

```csharp
class PortConnection
{
    public string FromPort { get; set; }
    public string ToPort { get; set; }
}
// e.g. "soundflow-device:capture_1" -> "tinygain-1:audio_in" -> "soundflow-device:playback_1"
```

Connection matrix (Core)

```csharp
interface IConnectionMatrix
{
    IReadOnlyList<IAudioDevice> Devices { get; }
    IReadOnlyList<PortConnection> Connections { get; }
    void AddDevice(IAudioDevice device);
    void Connect(string fromPort, string toPort);
    void Disconnect(string fromPort, string toPort);
}

interface IPedalboard
{
    string Id { get; }
    string Name { get; }
    IConnectionMatrix ConnectionMatrix { get; }
    Task StartAsync();
}
```

Plugin repository (Infrastructure)

```csharp
interface IPluginRepository
{
    IReadOnlyList<IAudioDevice> GetAll();
    IAudioDevice GetByUri(string uri);
}

// MockPluginRepository returns TinyGainPlugin instances; no filesystem access
// IPluginRepository.GetByUri("urn:alsionyx:sample-gain") returns a TinyGainPlugin
```

Pedalboard service (Application)

```csharp
interface IPedalboardService
{
    Task<IPedalboard> CreateAsync(string name, string audioDeviceId);
    Task<IPedalboard> GetAsync(string id);
    Task<IEnumerable<IPedalboard>> ListAsync();
    Task AddPluginAsync(string pedalboardId, string pluginUri);
    Task RemovePluginAsync(string pedalboardId, string instanceId);
    Task ConnectAsync(string pedalboardId, string fromPort, string toPort);
    Task DisconnectAsync(string pedalboardId, string fromPort, string toPort);
    Task SetParameterAsync(string pedalboardId, string instanceId, string symbol, float value);
    Task StartAsync(string pedalboardId);
    Task SaveAsync(string pedalboardId);
}

// AddPluginAsync resolves pluginUri via IPluginRepository, adds the IAudioDevice to IConnectionMatrix
```

Implementation order

1. PluginParameter class, PortConnection class, Pedalboard class
2. IAudioDevice - implement on SoundFlowAudioDevice and TinyGainPlugin
3. IConnectionMatrix and ConnectionMatrix
4. IPluginRepository and MockPluginRepository (returns TinyGainPlugin)
5. IPedalboardService - wire AddPluginAsync through IPluginRepository into IConnectionMatrix