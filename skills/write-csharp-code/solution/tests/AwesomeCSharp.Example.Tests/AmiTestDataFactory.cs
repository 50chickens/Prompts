using System;
using System.Collections.Generic;
using AwesomeCSharp.Example.Core;

namespace AwesomeCSharp.Example.Tests;

public static class AmiTestDataFactory
{
    public static Ami CreateBaseImage(string name, ImagePlatform platform, DateTime creationDate, Dictionary<string, string> tags)
    {
        return new Ami
        {
            Id = name,
            Name = name,
            BaseImageName = string.Empty,
            CreationDate = creationDate,
            Platform = platform,
            Tags = tags
        };
    }

    public static Ami CreateSoeImage(string name, ImagePlatform platform, string baseImageName)
    {
        return new Ami
        {
            Id = name,
            Name = name,
            BaseImageName = baseImageName,
            CreationDate = DateTime.UnixEpoch,
            Platform = platform,
            Tags = new Dictionary<string, string>()
        };
    }

    public static Dictionary<string, string> CreateTags(string tagKey, string tagValue)
    {
        return new Dictionary<string, string> { [tagKey] = tagValue };
    }

    public static Dictionary<string, string> CreateNoTags()
    {
        return new Dictionary<string, string>();
    }
}
