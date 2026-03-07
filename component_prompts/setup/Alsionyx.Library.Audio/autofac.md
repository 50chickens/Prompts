---

Autofac Dependency Injection Container

Architecture Guidelines
Single Responsibility: Each service has one reason to change. Register as interfaces, resolve implementations.
Configuration Binding: Use IConfiguration.GetSection to bind strongly-typed options from appsettings.json.
Null Safety: Require all dependencies via constructor injection. Use ILogger, IConfiguration, and service interfaces consistently.
Service Lifetimes: Use SingleInstance for stateless services, InstancePerLifetimeScope for stateful components. Avoid transient where unnecessary.
Container Setup Isolation: All DI configuration belongs in dedicated ContainerBuilder setup method, not scattered in Program.Main.

Testing: Create a generic test that verifies all services can be resolved from the container. No mock container needed.

Minimal Program.cs Program.cs should only: load configuration, create the container, run the application service, handle exceptions.

public class Program
{
    public static async Task Main(string[] args)
    {
        var builder = Host.CreateApplicationBuilder(args);
        
        ConfigureApplication(builder);
        
        using var host = builder.Build();
        using var scope = host.Services.CreateScope();
        
        var app = scope.ServiceProvider.GetRequiredService<IApplicationService>();
        await app.RunAsync();
    }
    
    private static void ConfigureApplication(HostApplicationBuilder builder)
    {
        builder.Services.AddSingleton<IContainerSetup, ContainerSetup>();
        var setup = builder.Services.BuildServiceProvider().GetRequiredService<IContainerSetup>();
        setup.RegisterServices(builder.Services);
    }
}

Container Setup Abstraction

Create IContainerSetup interface so all DI configuration is testable and isolated.

public interface IContainerSetup
{
    void RegisterServices(IServiceCollection services);
}

public class ContainerSetup : IContainerSetup
{
    private readonly IConfiguration _config;

    public ContainerSetup(IConfiguration config) => _config = config;

    public void RegisterServices(IServiceCollection services)
    {
        services.AddOptions<AudioServiceOptions>()
            .Bind(_config.GetSection(AudioServiceOptions.Settings))
            .ValidateDataAnnotations();

        services.AddSingleton(_config);
        services.AddSingleton<IPluginRepository, PluginRepository>();
        services.AddSingleton<IPedalboardService, PedalboardService>();
        services.AddSingleton<IApplicationService, ConsoleApplication>();
    }
}

Options Binding Pattern

Strongly-typed options with validation.

public class Lv2PluginDiscoveryServiceOptions
{
    public const string Settings = "Lv2PluginDiscoveryService";
    public string LV2Path { get; set; } = "/usr/lib/lv2";
}
public class AudioServiceOptions
{
    public const string Settings = "AudioService";
    public int BufferSize { get; set; } = 256;
    public int SampleRate { get; set; } = 48000;
}

Generic Container Resolution Test

Test that all registered services can be resolved. Makes registration errors visible immediately.

[TestFixture]
public class ContainerSetupTests
{
    [Test]
    public void AllRegisteredServices_Can_Be_Resolved()
    {
        var config = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string>
            {
                { "AudioService:BufferSize", "256" }
            })
            .Build();

        var services = new ServiceCollection();
        services.AddSingleton(config);

        var setup = new ContainerSetup(config);
        setup.RegisterServices(services);

        var provider = services.BuildServiceProvider();

        Assert.DoesNotThrow(() => provider.GetRequiredService<IApplicationService>());
        Assert.DoesNotThrow(() => provider.GetRequiredService<IPedalboardService>());
        Assert.DoesNotThrow(() => provider.GetRequiredService<IPluginRepository>());
    }
}

appsettings.json Structure

{
    "Lv2PluginDiscoveryService:
    {
        "LV2Path": "/usr/lib/lv2"
    }
  "AudioService": {
    "BufferSize": 256,
    "SampleRate": 48000
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information"
    }
  }
}

Projects Required

Alsionyx.ConsoleApp: Entry point, Program.Main, minimal initialization.

Alsionyx.ConsoleApp.Configuration: AudioServiceOptions, validation, configuration types.

Alsionyx.ConsoleApp.Services: IApplicationService, ConsoleApplication, service entry point logic.

Dependencies:
- Microsoft.Extensions.Hosting
- Microsoft.Extensions.Configuration
- Microsoft.Extensions.DependencyInjection
- Alsionyx.Services.Audio.Plugins
- Alsionyx.Library.Audio
- Alsionyx.Library.Logging
