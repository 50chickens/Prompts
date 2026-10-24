using System;
using System.Collections.Generic;
using AwesomeCSharp.Example.Application;
using AwesomeCSharp.Example.Core;
using NUnit.Framework;

namespace AwesomeCSharp.Example.Tests;

[TestFixture]
public class LatestBaseImageSelectorTests
{
    private static readonly DateTime OlderCreationDate = new DateTime(2025, 1, 1, 0, 0, 0, DateTimeKind.Utc);
    private static readonly DateTime NewerCreationDate = new DateTime(2026, 6, 1, 0, 0, 0, DateTimeKind.Utc);

    private LatestBaseImageSelector _latestBaseImageSelector;
    private List<Ami> _baseImageAmis;

    [SetUp]
    public void SetUp()
    {
        var settings = new BaseImageSelectionSettings
        {
            WindowsPrefix = "base-windows",
            LinuxPrefix = "base-linux",
            AlwaysTriggerTag = "AlwaysTrigger"
        };

        _latestBaseImageSelector = new LatestBaseImageSelector(settings);

        _baseImageAmis =
        [
            AmiTestDataFactory.CreateBaseImage("base-windows-2025", ImagePlatform.Windows, OlderCreationDate, AmiTestDataFactory.CreateNoTags()),
            AmiTestDataFactory.CreateBaseImage("soe-windows-2026", ImagePlatform.Windows, NewerCreationDate, AmiTestDataFactory.CreateNoTags()),
            AmiTestDataFactory.CreateBaseImage("base-linux-2026", ImagePlatform.Linux, NewerCreationDate, AmiTestDataFactory.CreateNoTags())
        ];
    }

    // expectedName is the only image allowed to match the naming convention for the given platform
    [TestCase(ImagePlatform.Windows, "base-windows-2025")]
    [TestCase(ImagePlatform.Linux, "base-linux-2026")]
    public void Test_That_We_Can_Select_The_Latest_Image_Matching_The_Platform_Naming_Convention(ImagePlatform platform, string expectedName)
    {
        var selected = _latestBaseImageSelector.Select(platform, _baseImageAmis);

        Assert.That(selected?.Name, Is.EqualTo(expectedName));
    }

    [Test]
    public void Test_That_We_Return_No_Image_When_No_Name_Matches_The_Platform_Naming_Convention()
    {
        var settings = new BaseImageSelectionSettings
        {
            WindowsPrefix = "unmatched-windows",
            LinuxPrefix = "unmatched-linux",
            AlwaysTriggerTag = "AlwaysTrigger"
        };

        var selector = new LatestBaseImageSelector(settings);

        var selected = selector.Select(ImagePlatform.Windows, _baseImageAmis);

        Assert.That(selected, Is.Null);
    }
}
