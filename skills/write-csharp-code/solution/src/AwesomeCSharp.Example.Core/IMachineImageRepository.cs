using System.Collections.Generic;
using System.Threading.Tasks;

namespace AwesomeCSharp.Example.Core;

public interface IMachineImageRepository
{
    Task<IReadOnlyList<Ami>> GetAmisAsync(string ownerId);
}
