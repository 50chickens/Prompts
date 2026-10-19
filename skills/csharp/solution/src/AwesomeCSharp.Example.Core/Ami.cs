using System;
using System.Collections.Generic;

namespace AwesomeCSharp.Example.Core;

public class Ami
{
    public required string Id { get; set; }

    public required string Name { get; set; }

    public required string BaseImageName { get; set; }

    public required DateTime CreationDate { get; set; }

    public required ImagePlatform Platform { get; set; }

    public required Dictionary<string, string> Tags { get; set; }
}
