using System;

namespace AwesomeCSharp.Example.Core;

public static class AmiExtensions
{
    public static bool MeetsPlatform(this Ami ami, ImagePlatform platform)
    {
        return ami.Platform == platform;
    }

    public static bool HasNamePrefix(this Ami ami, string namePrefix)
    {
        return ami.Name.StartsWith(namePrefix, StringComparison.OrdinalIgnoreCase);
    }

    public static bool UsesBaseImage(this Ami ami, string baseImageName)
    {
        return string.Equals(ami.BaseImageName, baseImageName, StringComparison.Ordinal);
    }

    public static bool HasTagValue(this Ami ami, string tagKey, string tagValue)
    {
        if (!ami.Tags.TryGetValue(tagKey, out var actualTagValue))
        {
            return false;
        }

        return string.Equals(actualTagValue, tagValue, StringComparison.OrdinalIgnoreCase);
    }
}
