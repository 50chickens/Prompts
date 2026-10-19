using System.Threading.Tasks;
using Amazon.EC2;
using Amazon.EC2.Model;
using AwesomeCSharp.Example.Core;

namespace AwesomeCSharp.Example.Infrastructure;

public class Ec2AmiTagRepository : IAmiTagRepository
{
    private readonly IAmazonEC2 _ec2;

    public Ec2AmiTagRepository(IAmazonEC2 ec2)
    {
        _ec2 = ec2;
    }

    public async Task RemoveTagAsync(string amiId, string tagKey)
    {
        var request = new DeleteTagsRequest
        {
            Resources = [amiId],
            Tags = [new Tag { Key = tagKey }]
        };

        await _ec2.DeleteTagsAsync(request).ConfigureAwait(false);
    }
}
