Alsionyx.Library.Audio Implementation Plan
Project and Class Summary
Alsionyx.Library.Audio: IAudioDevice, IConnectionMatrix, PluginParameter, PortConnection, ConnectionMatrix, ChannelMapper
Alsionyx.Library.PedalBoard: IPedalboard, Pedalboard, PedalboardDescriptor, IPedalboardService, PedalboardService
Alsionyx.Library.Audio.Plugins: ILv2PluginLoader, Lv2PluginInfo, Lv2PluginLoader, TinyGainPlugin
Alsionyx.Library.Audio.SoundFlow: SoundFlowAudioDevice for discovering and routing audio through system audio devices using the SoundFlow library
Alsionyx.Services.Audio.Plugins: IPluginRepository


Skeleton Code

Alsionyx.Library.Audio

public interface IAudioDevice
{
    string Id { get; }
    string Name { get; }
    IReadOnlyList<string> InputPorts { get; }
    IReadOnlyList<string> OutputPorts { get; }
    Task InitializeAsync();
    Task StartAsync();
}

public interface IConnectionMatrix
{
    IReadOnlyList<IAudioDevice> Devices { get; }
    IReadOnlyList<PortConnection> Connections { get; }
    void AddDevice(IAudioDevice device);
    void Connect(string fromPort, string toPort);
    void Disconnect(string fromPort, string toPort);
}

public class PluginParameter
{
    public string Symbol { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public float Min { get; set; }
    public float Max { get; set; }
    public float Value { get; set; }
}

public class PortConnection
{
    public string FromPort { get; set; } = string.Empty;
    public string ToPort { get; set; } = string.Empty;
}

public class ConnectionMatrix : IConnectionMatrix
{
    public IReadOnlyList<IAudioDevice> Devices => throw new NotImplementedException();
    public IReadOnlyList<PortConnection> Connections => throw new NotImplementedException();
    public void AddDevice(IAudioDevice device) => throw new NotImplementedException();
    public void Connect(string fromPort, string toPort) => throw new NotImplementedException();
    public void Disconnect(string fromPort, string toPort) => throw new NotImplementedException();
}

public class ChannelMapper
{
    public void MapInput(string deviceId, int channel, string toVirtualPort) => throw new NotImplementedException();
    public void MapOutput(string fromVirtualPort, string deviceId, int[] channels) => throw new NotImplementedException();
}


Alsionyx.Library.PedalBoard

public interface IPedalboard
{
    string Id { get; }
    string Name { get; }
    IConnectionMatrix ConnectionMatrix { get; }
    Task StartAsync();
}

public class Pedalboard : IPedalboard
{
    public string Id { get; } = Guid.NewGuid().ToString();
    public string Name { get; init; } = string.Empty;
    public IConnectionMatrix ConnectionMatrix { get; } = new ConnectionMatrix();
    public Task StartAsync() => throw new NotImplementedException();
}

public class PedalboardDescriptor
{
    public string Id { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public List<string> DeviceIds { get; set; } = [];
    public List<PortConnection> Connections { get; set; } = [];
    public Dictionary<string, List<PluginParameter>> Parameters { get; set; } = [];
}

public interface IPedalboardService
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

public class PedalboardService : IPedalboardService
{
    private readonly IPluginRepository _plugins;

    public PedalboardService(IPluginRepository plugins) => _plugins = plugins;

    public Task<IPedalboard> CreateAsync(string name, string audioDeviceId) => throw new NotImplementedException();
    public Task<IPedalboard> GetAsync(string id) => throw new NotImplementedException();
    public Task<IEnumerable<IPedalboard>> ListAsync() => throw new NotImplementedException();
    public Task AddPluginAsync(string pedalboardId, string pluginUri) => throw new NotImplementedException();
    public Task RemovePluginAsync(string pedalboardId, string instanceId) => throw new NotImplementedException();
    public Task ConnectAsync(string pedalboardId, string fromPort, string toPort) => throw new NotImplementedException();
    public Task DisconnectAsync(string pedalboardId, string fromPort, string toPort) => throw new NotImplementedException();
    public Task SetParameterAsync(string pedalboardId, string instanceId, string symbol, float value) => throw new NotImplementedException();
    public Task StartAsync(string pedalboardId) => throw new NotImplementedException();
    public Task SaveAsync(string pedalboardId) => throw new NotImplementedException();
}





Alsionyx.Library.Audio.SoundFlow

public class SoundFlowAudioDevice : IAudioDevice
{
    public string Id { get; init; } = string.Empty;
    public string Name { get; init; } = string.Empty;
    public IReadOnlyList<string> InputPorts => throw new NotImplementedException();
    public IReadOnlyList<string> OutputPorts => throw new NotImplementedException();
    public Task InitializeAsync() => throw new NotImplementedException();
    public Task StartAsync() => throw new NotImplementedException();
}

public class SoundFlowAudioRouter
{
    public Task RouteAudioAsync(string inputDeviceId, string outputDeviceId, IAudioDevice plugin) => throw new NotImplementedException();
}


Alsionyx.Services.Audio.Plugins

public interface IPluginRepository
{
    IReadOnlyList<IAudioDevice> GetAll();
    IAudioDevice GetByUri(string uri);
}

Implementation Order

1. PluginParameter, PortConnection (value objects)
2. IAudioDevice, IConnectionMatrix, IPedalboard
3. ConnectionMatrix, Pedalboard, ChannelMapper
4. Lv2PluginInfo, ILv2PluginLoader
5. TinyGainPlugin
6. Lv2PluginLoader (native lilv)
7. SoundFlowAudioDevice
8. IPluginRepository, PluginRepository
9. IPedalboardService, PedalboardService
10. Tests: ConnectionMatrixTests, PedalboardTests, SoundFlowAudioDeviceTests

