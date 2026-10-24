using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using AwesomeCSharp.Example.Application;
using AwesomeCSharp.Example.Core;
using AwesomeCSharp.Example.Infrastructure;
using NSubstitute;
using NUnit.Framework;

namespace AwesomeCSharp.Example.Tests;

[TestFixture]
public class DeploymentDecisionServiceTests
{
    private const string SoeImageOwnerId = "111111111111";
    private const string BaseImageOwnerId = "222222222222";
    private const string AlwaysTriggerTag = "AlwaysTrigger";

    private static readonly DateTime OlderBaseImageCreationDate = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc);
    private static readonly DateTime LatestBaseImageCreationDate = new DateTime(2026, 5, 1, 0, 0, 0, DateTimeKind.Utc);

    private IMachineImageRepository _machineImageRepository;
    private IAmiTagRepository _amiTagRepository;
    private DeploymentDecisionService _deploymentDecisionService;

    [SetUp]
    public void SetUp()
    {
        _machineImageRepository = Substitute.For<IMachineImageRepository>();
        _amiTagRepository = Substitute.For<IAmiTagRepository>();

        var settings = new BaseImageSelectionSettings
        {
            WindowsPrefix = "base-windows",
            LinuxPrefix = "base-linux",
            AlwaysTriggerTag = AlwaysTriggerTag
        };

        _deploymentDecisionService = new DeploymentDecisionService(
            _machineImageRepository,
            new LatestBaseImageSelector(settings),
            new ForceTriggerTagRemover(_amiTagRepository, settings, new ConsoleLog<ForceTriggerTagRemover>()),
            new ConsoleLog<DeploymentDecisionService>());
    }

    // platform is the image platform whose base image naming convention is under test
    [TestCase(ImagePlatform.Windows)]
    [TestCase(ImagePlatform.Linux)]
    public async Task Test_That_We_Trigger_Deployment_When_The_Soe_Images_Do_Not_Use_The_Latest_Base_Image(ImagePlatform platform)
    {
        var latestBaseImage = CreateBaseImage(platform, "2026", LatestBaseImageCreationDate, AmiTestDataFactory.CreateNoTags());
        var soeImage = AmiTestDataFactory.CreateSoeImage($"soe-{platform}-2025", platform, "base-2024");

        ArrangeAmis([latestBaseImage], [soeImage]);

        var shouldTrigger = await _deploymentDecisionService.ShouldTriggerDeploymentAsync(SoeImageOwnerId, BaseImageOwnerId, platform);

        Assert.That(shouldTrigger, Is.True);
    }

    // platform is the image platform whose base image naming convention is under test
    [TestCase(ImagePlatform.Windows)]
    [TestCase(ImagePlatform.Linux)]
    public async Task Test_That_We_Do_Not_Trigger_Deployment_When_A_Soe_Image_Uses_The_Latest_Base_Image(ImagePlatform platform)
    {
        var latestBaseImage = CreateBaseImage(platform, "2026", LatestBaseImageCreationDate, AmiTestDataFactory.CreateNoTags());
        var soeImage = AmiTestDataFactory.CreateSoeImage($"soe-{platform}-2026", platform, latestBaseImage.Name);

        ArrangeAmis([latestBaseImage], [soeImage]);

        var shouldTrigger = await _deploymentDecisionService.ShouldTriggerDeploymentAsync(SoeImageOwnerId, BaseImageOwnerId, platform);

        Assert.That(shouldTrigger, Is.False);
    }

    [TestCase(ImagePlatform.Windows)]
    [TestCase(ImagePlatform.Linux)]
    public async Task Test_That_We_Select_The_Base_Image_With_The_Latest_Creation_Date(ImagePlatform platform)
    {
        var olderBaseImage = CreateBaseImage(platform, "2025", OlderBaseImageCreationDate, AmiTestDataFactory.CreateNoTags());
        var latestBaseImage = CreateBaseImage(platform, "2026", LatestBaseImageCreationDate, AmiTestDataFactory.CreateNoTags());
        var soeImage = AmiTestDataFactory.CreateSoeImage($"soe-{platform}-2026", platform, olderBaseImage.Name);

        ArrangeAmis([olderBaseImage, latestBaseImage], [soeImage]);

        var shouldTrigger = await _deploymentDecisionService.ShouldTriggerDeploymentAsync(SoeImageOwnerId, BaseImageOwnerId, platform);

        Assert.That(shouldTrigger, Is.True);
    }

    [TestCase(ImagePlatform.Windows)]
    [TestCase(ImagePlatform.Linux)]
    public async Task Test_That_We_Trigger_Deployment_When_No_Base_Image_Matches_The_Platform(ImagePlatform platform)
    {
        var otherPlatform = platform == ImagePlatform.Windows ? ImagePlatform.Linux : ImagePlatform.Windows;
        var otherPlatformBaseImage = CreateBaseImage(otherPlatform, "2026", LatestBaseImageCreationDate, AmiTestDataFactory.CreateNoTags());

        ArrangeAmis([otherPlatformBaseImage], []);

        var shouldTrigger = await _deploymentDecisionService.ShouldTriggerDeploymentAsync(SoeImageOwnerId, BaseImageOwnerId, platform);

        Assert.That(shouldTrigger, Is.True);
    }

    [TestCase(ImagePlatform.Windows)]
    [TestCase(ImagePlatform.Linux)]
    public async Task Test_That_We_Do_Not_Trigger_Deployment_When_The_Soe_Account_Has_No_Images(ImagePlatform platform)
    {
        var latestBaseImage = CreateBaseImage(platform, "2026", LatestBaseImageCreationDate, AmiTestDataFactory.CreateNoTags());

        ArrangeAmis([latestBaseImage], []);

        var shouldTrigger = await _deploymentDecisionService.ShouldTriggerDeploymentAsync(SoeImageOwnerId, BaseImageOwnerId, platform);

        Assert.That(shouldTrigger, Is.False);
    }

    [TestCase(ImagePlatform.Windows)]
    [TestCase(ImagePlatform.Linux)]
    public async Task Test_That_We_Remove_The_Always_Trigger_Tag_From_The_Latest_Base_Image(ImagePlatform platform)
    {
        var latestBaseImage = CreateBaseImage(platform, "2026", LatestBaseImageCreationDate, AmiTestDataFactory.CreateTags(AlwaysTriggerTag, "True"));

        ArrangeAmis([latestBaseImage], []);

        await _deploymentDecisionService.ShouldTriggerDeploymentAsync(SoeImageOwnerId, BaseImageOwnerId, platform);

        await _amiTagRepository.Received(1).RemoveTagAsync(latestBaseImage.Id, AlwaysTriggerTag);
    }

    [TestCase(ImagePlatform.Windows)]
    [TestCase(ImagePlatform.Linux)]
    public async Task Test_That_We_Leave_The_Always_Trigger_Tag_When_The_Latest_Base_Image_Does_Not_Carry_It(ImagePlatform platform)
    {
        var latestBaseImage = CreateBaseImage(platform, "2026", LatestBaseImageCreationDate, AmiTestDataFactory.CreateTags(AlwaysTriggerTag, "False"));

        ArrangeAmis([latestBaseImage], []);

        await _deploymentDecisionService.ShouldTriggerDeploymentAsync(SoeImageOwnerId, BaseImageOwnerId, platform);

        await _amiTagRepository.DidNotReceive().RemoveTagAsync(Arg.Any<string>(), Arg.Any<string>());
    }

    private static Ami CreateBaseImage(ImagePlatform platform, string year, DateTime creationDate, Dictionary<string, string> tags)
    {
        return AmiTestDataFactory.CreateBaseImage($"base-{platform}-{year}", platform, creationDate, tags);
    }

    private void ArrangeAmis(List<Ami> baseImageAmis, List<Ami> soeImageAmis)
    {
        _machineImageRepository.GetAmisAsync(BaseImageOwnerId).Returns(baseImageAmis);
        _machineImageRepository.GetAmisAsync(SoeImageOwnerId).Returns(soeImageAmis);
    }
}
