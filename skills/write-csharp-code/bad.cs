


public async Task<bool> ShouldTriggerOctopusProjectDeployment(string corp1OwnerId,string corp2OwnerId, bool amiNameMatchesCorp1WindowsAmiPrefix = true)
{
    try
    {
        logger.Info("Checking if we need to trigger the octopus project to create the SOE...");

        //Pulls images for corp2 AMIS
        var getImagesMatchingcorp2OwnerRequest = new DescribeImagesRequest { Owners = [corp2OwnerId] };
        var imagesMatchingcorp2OwnerId = await amazonMachineImageService.DescribeImagesAsync(getImagesMatchingcorp2OwnerRequest).ConfigureAwait(false);

        var corp2AmiModels = new List<AmiModel>();

        foreach (var imageMatchingOwnerId in imagesMatchingcorp2OwnerId.Images ?? [])
        {
            var corp2AmiModel = imageMatchingOwnerId.ToAmiModel();

            if (amiNameMatchescorp1WindowsAmiPrefix && corp2AmiModel.IsWindows)
            {
                corp2AmiModels.Add(corp2AmiModel);
            }
            else if (!amiNameMatchescorp1WindowsAmiPrefix && corp2AmiModel.IsLinux)
            {
                corp2AmiModels.Add(corp2AmiModel);
            }
        }

        AmiModel sortedcorp2AmiModels = corp2AmiModels.OrderByDescending(ami => ami.CreationDate).FirstOrDefault(x => x.Name.StartsWith(amiNameMatchescorp1WindowsAmiPrefix? settings.corp2WindowsPrefix: settings.corp2LinuxPrefix,StringComparison.OrdinalIgnoreCase));

        if (!string.IsNullOrWhiteSpace(sortedcorp2AmiModels?.Id) && sortedcorp2AmiModels.Tags.Any(kvp => kvp.Key.Equals(AlwaysTriggerTag, StringComparison.OrdinalIgnoreCase) && kvp.Value.Equals("True",StringComparison.OrdinalIgnoreCase)))
        {
            // Remove the tag after detection
            await RemoveForceTag(new DeleteTagsRequest
            {
                Resources = new List<string> { sortedcorp2AmiModels.Id },
                Tags =
                [
                    new Tag
                    {
                        Key = AlwaysTriggerTag,
                        Value = "True"
                    }
                ]
            });

        }

        //Pulls the images for SOES
        var getImagesMatchingcorp1OwnerIdRequest = new DescribeImagesRequest { Owners = [corp1OwnerId] };
        var imagesMatchingcorp1OwnerId = await amazonMachineImageService.DescribeImagesAsync(getImagesMatchingcorp1OwnerIdRequest).ConfigureAwait(false);
        if (imagesMatchingcorp1OwnerId?.Images == null || imagesMatchingcorp1OwnerId.Images.Count == 0)
        {
            logger.Warn($"Found no AMI images in AWS account {corp1OwnerId}.");
            return false;
        }

        //Need to loop through all images and find if any images have the base image matching to the latest corp2 image.
        //Sort here by creation date

        var corp1AmiModels = new List<AmiModel>();

        foreach (var imageMatchingcorp1OwnerId in imagesMatchingcorp1OwnerId.Images ?? [])
        {
            var corp1ImageModel = imageMatchingcorp1OwnerId.ToAmiModel();

            //If windows, lets make sure any images are only windows images
            if (amiNameMatchescorp1WindowsAmiPrefix && corp1ImageModel.IsWindows)
            {
                corp1AmiModels.Add(corp1ImageModel);
            }
            else if (!amiNameMatchescorp1WindowsAmiPrefix && corp1ImageModel.IsLinux)
            {
                corp1AmiModels.Add(corp1ImageModel);
            }
        }

        foreach (var corp1AmiModel in corp1AmiModels)
        {
            if (corp1AmiModel.BaseImageName == null || sortedcorp2AmiModels?.Name == null)
            {
                continue;
            }
            else if (corp1AmiModel.BaseImageName.Equals(sortedcorp2AmiModels.Name,StringComparison.Ordinal))
            {
                //Need this logic while enterprise release processes still exist
                logger.Info($"corp1 Ami {corp1AmiModel.BaseImageName} basename matches the latest corp2 Ami ({sortedcorp2AmiModels.Name})");
                return false;
            }
        }

        logger.Info($"No corp1 ami detected that uses the latest corp2 ami");
        return true;
    }
    catch (Exception e)
    {
        logger.Error($"Failed to fetch AMIs from AWS for accounts.", e);
        throw;
    }
}
