using System.Threading.Tasks;

namespace AwesomeCSharp.Example.Core;

public interface IAmiTagRepository
{
    Task RemoveTagAsync(string amiId, string tagKey);
}
