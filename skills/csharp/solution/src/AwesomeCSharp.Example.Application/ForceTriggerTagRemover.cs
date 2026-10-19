using System.Threading.Tasks;
using AwesomeCSharp.Example.Core;

namespace AwesomeCSharp.Example.Application;

public class ForceTriggerTagRemover
{
    private const string ForceTagValue = "True";

    private readonly IAmiTagRepository _amiTagRepository;
    private readonly ILog<ForceTriggerTagRemover> _log;
    private readonly string _alwaysTriggerTag;

    public ForceTriggerTagRemover(IAmiTagRepository amiTagRepository, BaseImageSelectionSettings settings, ILog<ForceTriggerTagRemover> log)
    {
        _amiTagRepository = amiTagRepository;
        _log = log;
        _alwaysTriggerTag = settings.AlwaysTriggerTag;
    }

    public async Task RemoveAsync(Ami ami)
    {
        if (!ami.HasTagValue(_alwaysTriggerTag, ForceTagValue))
        {
            return;
        }

        await _amiTagRepository.RemoveTagAsync(ami.Id, _alwaysTriggerTag).ConfigureAwait(false);
        _log.Info($"Removed the {_alwaysTriggerTag} tag from AMI {ami.Id}.");
    }
}
