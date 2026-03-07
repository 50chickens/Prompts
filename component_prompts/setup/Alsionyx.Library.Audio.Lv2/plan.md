Alsionyx.Library.Audio.Plugins

public class Lv2PluginInfo
{
    public string Uri { get; init; } = string.Empty;
    public string Name { get; init; } = string.Empty;
    public IReadOnlyList<string> AudioInputPorts { get; init; } = [];
    public IReadOnlyList<string> AudioOutputPorts { get; init; } = [];
    public IReadOnlyList<PluginParameter> Parameters { get; init; } = [];
}

public interface ILv2PluginLoader
{
    IReadOnlyList<Lv2PluginInfo> DiscoverAll();
    Lv2PluginInfo? GetInfo(string uri);
    IAudioDevice Load(string uri, string instanceId);
}

public class Lv2PluginLoader : ILv2PluginLoader
{
    public IReadOnlyList<Lv2PluginInfo> DiscoverAll() => throw new NotImplementedException();
    public Lv2PluginInfo? GetInfo(string uri) => throw new NotImplementedException();
    public IAudioDevice Load(string uri, string instanceId) => throw new NotImplementedException();
}

public class TinyGainPlugin : IAudioDevice
{
    public string InstanceId { get; init; } = "tinygain-1";
    public string Id => InstanceId;
    public string Name => "TinyGain";
    public IReadOnlyList<string> InputPorts => ["audio_in"];
    public IReadOnlyList<string> OutputPorts => ["audio_out"];
    public IReadOnlyList<PluginParameter> Parameters => throw new NotImplementedException();
    public Task InitializeAsync() => throw new NotImplementedException();
    public Task StartAsync() => throw new NotImplementedException();
}