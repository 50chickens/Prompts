# Alsionyx.Library.PedalBoard Implementation Plan

## Project and Class Summary

Alsionyx.Library.PedalBoard provides pedalboard management and plugin lifecycle handling. IPedalboard represents a named collection of plugins with audio routing. Pedalboard implements mutable state for active plugin instances and their connections. PedalboardService manages CRUD operations for pedalboards and coordinates plugin loading through ILv2PluginLoader. PedalboardDescriptor provides serializable state for persistence.

## Skeleton Code

IPedalboard

public interface IPedalboard
{
    string Id { get; }
    string Name { get; }
    IConnectionMatrix ConnectionMatrix { get; }
    IReadOnlyList<string> PluginInstanceIds { get; }
    Task StartAsync();
}

Pedalboard

public class Pedalboard : IPedalboard
{
    public string Id { get; }
    public string Name { get; init; } = string.Empty;
    public IConnectionMatrix ConnectionMatrix { get; }
    public IReadOnlyList<string> PluginInstanceIds { get; }
    
    public Task StartAsync() => throw new NotImplementedException();
}

PedalboardDescriptor

public class PedalboardDescriptor
{
    public string Id { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public List<PedalboardPluginSnapshot> Plugins { get; set; } = [];
    public List<PortConnection> Connections { get; set; } = [];
}

PedalboardPluginSnapshot

public class PedalboardPluginSnapshot
{
    public string InstanceId { get; set; } = string.Empty;
    public string PluginUri { get; set; } = string.Empty;
    public Dictionary<string, float> ControlValues { get; set; } = [];
    public Dictionary<string, string> StringProperties { get; set; } = [];
}

IPedalboardService

public interface IPedalboardService
{
    Task<IPedalboard> CreateAsync(string name);
    Task<IPedalboard> GetAsync(string id);
    Task<IEnumerable<IPedalboard>> ListAsync();
    Task AddPluginAsync(string pedalboardId, string pluginUri);
    Task RemovePluginAsync(string pedalboardId, string instanceId);
    Task ConnectAsync(string pedalboardId, string fromPort, string toPort);
    Task DisconnectAsync(string pedalboardId, string fromPort, string toPort);
    Task SetParameterAsync(string pedalboardId, string instanceId, string symbol, float value);
    Task SetStringPropertyAsync(string pedalboardId, string instanceId, string symbol, string value);
    Task StartAsync(string pedalboardId);
    Task SaveAsync(string pedalboardId);
    Task LoadAsync(string pedalboardId, PedalboardDescriptor descriptor);
}

PedalboardService

public class PedalboardService : IPedalboardService
{
    private readonly ILv2PluginLoader _pluginLoader;
    private readonly ILog<PedalboardService> _logger;
    private readonly Dictionary<string, Pedalboard> _pedalboards = [];
    
    public PedalboardService(ILv2PluginLoader pluginLoader, ILog<PedalboardService> logger) => throw new NotImplementedException();
    
    public Task<IPedalboard> CreateAsync(string name) => throw new NotImplementedException();
    public Task<IPedalboard> GetAsync(string id) => throw new NotImplementedException();
    public Task<IEnumerable<IPedalboard>> ListAsync() => throw new NotImplementedException();
    public Task AddPluginAsync(string pedalboardId, string pluginUri) => throw new NotImplementedException();
    public Task RemovePluginAsync(string pedalboardId, string instanceId) => throw new NotImplementedException();
    public Task ConnectAsync(string pedalboardId, string fromPort, string toPort) => throw new NotImplementedException();
    public Task DisconnectAsync(string pedalboardId, string fromPort, string toPort) => throw new NotImplementedException();
    public Task SetParameterAsync(string pedalboardId, string instanceId, string symbol, float value) => throw new NotImplementedException();
    public Task SetStringPropertyAsync(string pedalboardId, string instanceId, string symbol, string value) => throw new NotImplementedException();
    public Task StartAsync(string pedalboardId) => throw new NotImplementedException();
    public Task SaveAsync(string pedalboardId) => throw new NotImplementedException();
    public Task LoadAsync(string pedalboardId, PedalboardDescriptor descriptor) => throw new NotImplementedException();
}

## Implementation Notes

Pedalboard wraps a ConnectionMatrix and maintains a collection of active plugin instances indexed by instance ID. Each plugin instance implements IAudioDevice and connects through the matrix. PedalboardService coordinates loader operations and maintains in-memory pedalboard state. Connections require both ports to exist on loaded plugins. Parameter changes delegate to plugin instance SetControlValue method. String property updates delegate to SetStringProperty for plugins that expose string-type parameters. Save and Load operations work with PedalboardDescriptor for persistence and restore.
