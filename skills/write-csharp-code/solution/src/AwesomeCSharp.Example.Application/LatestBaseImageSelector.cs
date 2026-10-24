using System.Collections.Generic;
using System.Linq;
using AwesomeCSharp.Example.Core;

namespace AwesomeCSharp.Example.Application;

public class LatestBaseImageSelector
{
    private readonly string _windowsPrefix;
    private readonly string _linuxPrefix;

    public LatestBaseImageSelector(BaseImageSelectionSettings settings)
    {
        _windowsPrefix = settings.WindowsPrefix;
        _linuxPrefix = settings.LinuxPrefix;
    }

    public Ami? Select(ImagePlatform platform, IEnumerable<Ami> baseImageAmis)
    {
        var namePrefix = platform == ImagePlatform.Windows ? _windowsPrefix : _linuxPrefix;
        return baseImageAmis.Where(ami => ami.MeetsPlatform(platform)).Where(ami => ami.HasNamePrefix(namePrefix)).OrderByDescending(ami => ami.CreationDate).FirstOrDefault();
    }
}
