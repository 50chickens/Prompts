namespace AwesomeCSharp.Example.Core;

public class BaseImageSelectionSettings
{
    public required string WindowsPrefix { get; set; }

    public required string LinuxPrefix { get; set; }

    public required string AlwaysTriggerTag { get; set; }
}
