using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Amazon.EC2;
using Amazon.EC2.Model;
using AwesomeCSharp.Example.Core;

namespace AwesomeCSharp.Example.Infrastructure;

public class Ec2MachineImageRepository : IMachineImageRepository
{
    private readonly IAmazonEC2 _ec2;

    public Ec2MachineImageRepository(IAmazonEC2 ec2)
    {
        _ec2 = ec2;
    }

    public async Task<IReadOnlyList<Ami>> GetAmisAsync(string ownerId)
    {
        var request = new DescribeImagesRequest { Owners = [ownerId] };
        var response = await _ec2.DescribeImagesAsync(request).ConfigureAwait(false);

        return response.Images.Select(image => image.ToAmi()).ToList();
    }
}
