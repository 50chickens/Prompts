using System;
using System.Globalization;
using System.Linq;
using Amazon.EC2.Model;
using AwesomeCSharp.Example.Core;

namespace AwesomeCSharp.Example.Infrastructure;

public static class Ec2ImageExtensions
{
    private const string WindowsPlatform = "windows";
    private const string BaseImageNameTagKey = "BaseImageName";

    public static Ami ToAmi(this Image image)
    {
        return new Ami
        {
            Id = image.ImageId,
            Name = image.Name,
            BaseImageName = ReadBaseImageName(image),
            CreationDate = DateTime.Parse(image.CreationDate, CultureInfo.InvariantCulture, DateTimeStyles.AdjustToUniversal),
            Platform = IsWindows(image) ? ImagePlatform.Windows : ImagePlatform.Linux,
            Tags = image.Tags.ToDictionary(tag => tag.Key, tag => tag.Value, StringComparer.OrdinalIgnoreCase)
        };
    }

    private static bool IsWindows(Image image)
    {
        return string.Equals(image.Platform, WindowsPlatform, StringComparison.OrdinalIgnoreCase);
    }

    private static string ReadBaseImageName(Image image)
    {
        return image.Tags
            .Where(tag => tag.Key.Equals(BaseImageNameTagKey, StringComparison.OrdinalIgnoreCase))
            .Select(tag => tag.Value)
            .FirstOrDefault(string.Empty);
    }
}
