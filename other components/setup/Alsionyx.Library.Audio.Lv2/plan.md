# Alsionyx.Library.Audio.Lv2 Implementation Plan

## Project and Class Summary

Alsionyx.Library.Audio.Lv2 provides LV2 plugin discovery and loading on Linux systems. ILv2PluginLoader discovers all plugins from standard LV2 search paths and returns plugin metadata. Lv2PluginLoader uses lilv bindings to read LV2 plugin descriptors. Lv2PluginInstance wraps a loaded LV2 plugin and implements IAudioDevice for router integration. Lv2PluginInfo holds immutable plugin metadata. Lv2PortInfo describes individual audio and control ports, supporting both audio and control port types (float and string-based parameters).

## Skeleton Code

ILv2PluginLoader

public interface ILv2PluginLoader
{
    IReadOnlyList<Lv2PluginInfo> DiscoverAll();
    Lv2PluginInfo GetInfo(string uri);
    ILv2PluginInstance Load(string uri, string instanceId);
}

Lv2PluginInfo

public class Lv2PluginInfo
{
    public string Uri { get; init; } = string.Empty;
    public string Name { get; init; } = string.Empty;
    public string BundlePath { get; init; } = string.Empty;
    public IReadOnlyList<Lv2PortInfo> AudioInputPorts { get; init; } = [];
    public IReadOnlyList<Lv2PortInfo> AudioOutputPorts { get; init; } = [];
    public IReadOnlyList<Lv2PortInfo> ControlInputPorts { get; init; } = [];
}

Lv2PortInfo

public class Lv2PortInfo
{
    public string Symbol { get; init; } = string.Empty;
    public string Name { get; init; } = string.Empty;
    public int Index { get; init; }
}

ILv2PluginInstance

public interface ILv2PluginInstance : IAudioDevice
{
    void SetControlValue(string symbol, float value);
    float GetControlValue(string symbol);
    void SetStringProperty(string symbol, string value);
    string GetStringProperty(string symbol);
}

Lv2PluginLoader

public class Lv2PluginLoader : ILv2PluginLoader
{
    private readonly string[] _searchPaths;
    
    public IReadOnlyList<Lv2PluginInfo> DiscoverAll() => throw new NotImplementedException();
    public Lv2PluginInfo GetInfo(string uri) => throw new NotImplementedException();
    public ILv2PluginInstance Load(string uri, string instanceId) => throw new NotImplementedException();
}

Lv2PluginInstance

public class Lv2PluginInstance : ILv2PluginInstance
{
    public string Id { get; }
    public string Name { get; }
    public IReadOnlyList<string> InputPorts { get; }
    public IReadOnlyList<string> OutputPorts { get; }
    
    public Task InitializeAsync() => throw new NotImplementedException();
    public Task StartAsync() => throw new NotImplementedException();
    public void SetControlValue(string symbol, float value) => throw new NotImplementedException();
    public float GetControlValue(string symbol) => throw new NotImplementedException();
    public void SetStringProperty(string symbol, string value) => throw new NotImplementedException();
    public string GetStringProperty(string symbol) => throw new NotImplementedException();
}

## Implementation Notes

Discovery scans ~/.lv2, /usr/lib/lv2, /usr/local/lib/lv2 looking for manifest.ttl files. Loader uses lilv to parse TTL and extract plugin metadata including URIs, port names, and control ranges. Each Load() call instantiates a new plugin worker. Plugin instances store both float control port state and string-type properties that plugins may expose. All audio processing runs on the audio thread without allocation or blocking.