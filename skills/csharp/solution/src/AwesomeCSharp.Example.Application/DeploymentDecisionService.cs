using System.Linq;
using System.Threading.Tasks;
using AwesomeCSharp.Example.Core;

namespace AwesomeCSharp.Example.Application;

public class DeploymentDecisionService
{
    private readonly IMachineImageRepository _machineImageRepository;
    private readonly LatestBaseImageSelector _latestBaseImageSelector;
    private readonly ForceTriggerTagRemover _forceTriggerTagRemover;
    private readonly ILog<DeploymentDecisionService> _log;

    public DeploymentDecisionService(IMachineImageRepository machineImageRepository,LatestBaseImageSelector latestBaseImageSelector,ForceTriggerTagRemover forceTriggerTagRemover,ILog<DeploymentDecisionService> log)
    {
        _machineImageRepository = machineImageRepository;
        _latestBaseImageSelector = latestBaseImageSelector;
        _forceTriggerTagRemover = forceTriggerTagRemover;
        _log = log;
    }

    public async Task<bool> ShouldTriggerDeploymentAsync(string soeImageOwnerId, string baseImageOwnerId, ImagePlatform platform)
    {
        var baseImageAmis = await _machineImageRepository.GetAmisAsync(baseImageOwnerId).ConfigureAwait(false);
        var latestBaseImageAmi = _latestBaseImageSelector.Select(platform, baseImageAmis);

        if (latestBaseImageAmi is null)
        {
            _log.Warn($"No {platform} base image matches the naming convention in account {baseImageOwnerId}.");
            return true;
        }

        await _forceTriggerTagRemover.RemoveAsync(latestBaseImageAmi).ConfigureAwait(false);

        var soeAmis = await _machineImageRepository.GetAmisAsync(soeImageOwnerId).ConfigureAwait(false);
        if (soeAmis.Count == 0)
        {
            _log.Warn($"Found no AMI images in AWS account {soeImageOwnerId}.");
            return false;
        }

        if (soeAmis.Any(ami => ami.MeetsPlatform(platform) && ami.UsesBaseImage(latestBaseImageAmi.Name)))
        {
            _log.Info($"SOE images already use the latest {platform} base image {latestBaseImageAmi.Name}.");
            return false;
        }

        _log.Info($"No SOE image uses the latest {platform} base image {latestBaseImageAmi.Name}.");
        return true;
    }
}
