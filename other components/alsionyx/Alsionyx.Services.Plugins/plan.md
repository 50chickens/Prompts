# alsionyx/Alsionyx.Services.Plugins Implementation Plan

## Project and Class Summary

Alsionyx.Services.Plugins provides the service layer for plugin discovery and management operations. IPluginDiscoveryService exposes methods to list all discovered plugins and get plugin metadata for any LV2 plugin. IPluginInstanceService manages the lifecycle of individual plugin instances within pedalboards. These services coordinate with ILv2PluginLoader and IPedalboardService from the audio library layers and work with SoundFlow audio routing.

## Skeleton Code

IPluginDiscoveryService

public interface IPluginDiscoveryService
{
    IReadOnlyList<Lv2PluginInfo> DiscoverAll();
    Lv2PluginInfo GetPluginInfo(string uri);
}

PluginDiscoveryService

public class PluginDiscoveryService : IPluginDiscoveryService
{
    private readonly ILv2PluginLoader _pluginLoader;
    private readonly ILog<PluginDiscoveryService> _logger;
    
    public PluginDiscoveryService(ILv2PluginLoader pluginLoader, ILog<PluginDiscoveryService> logger) => throw new NotImplementedException();
    
    public IReadOnlyList<Lv2PluginInfo> DiscoverAll() => throw new NotImplementedException();
    public Lv2PluginInfo GetPluginInfo(string uri) => throw new NotImplementedException();
}

IPedalboardCommandService

public interface IPedalboardCommandService
{
    Task<string> CreatePedalboardAsync(string name);
    Task RemovePedalboardAsync(string pedalboardId);
    Task AddPluginAsync(string pedalboardId, string pluginUri);
    Task RemovePluginAsync(string pedalboardId, string instanceId);
    Task ConnectPortsAsync(string pedalboardId, string fromPort, string toPort);
    Task DisconnectPortsAsync(string pedalboardId, string fromPort, string toPort);
    Task SetParameterAsync(string pedalboardId, string instanceId, string symbol, float value);
    Task SetStringPropertyAsync(string pedalboardId, string instanceId, string symbol, string value);
}

PedalboardCommandService

public class PedalboardCommandService : IPedalboardCommandService
{
    private readonly IPedalboardService _pedalboardService;
    private readonly ILog<PedalboardCommandService> _logger;
    
    public PedalboardCommandService(IPedalboardService pedalboardService, ILog<PedalboardCommandService> logger) => throw new NotImplementedException();
    
    public Task<string> CreatePedalboardAsync(string name) => throw new NotImplementedException();
    public Task RemovePedalboardAsync(string pedalboardId) => throw new NotImplementedException();
    public Task AddPluginAsync(string pedalboardId, string pluginUri) => throw new NotImplementedException();
    public Task RemovePluginAsync(string pedalboardId, string instanceId) => throw new NotImplementedException();
    public Task ConnectPortsAsync(string pedalboardId, string fromPort, string toPort) => throw new NotImplementedException();
    public Task DisconnectPortsAsync(string pedalboardId, string fromPort, string toPort) => throw new NotImplementedException();
    public Task SetParameterAsync(string pedalboardId, string instanceId, string symbol, float value) => throw new NotImplementedException();
    public Task SetStringPropertyAsync(string pedalboardId, string instanceId, string symbol, string value) => throw new NotImplementedException();
}

## Implementation Notes

PluginDiscoveryService wraps ILv2PluginLoader caching discovered plugins on first call. DiscoverAll returns the full list and GetPluginInfo looks up by URI. Discovery returns metadata for all discovered plugins and their available parameters. PedalboardCommandService coordinates pedalboard and plugin operations delegating to IPedalboardService. SetStringPropertyAsync enables setting string-type parameters on any plugin that exposes them. Each command validates pedalboard existence before modification and logs operations at appropriate levels. Service coordinates with SoundFlow audio routing when starting pedalboards to establish audio input from primary device through plugins to output device.
