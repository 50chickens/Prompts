---
layout: Conceptual
monikers:
- vs-2022
- visualstudio
defaultMoniker: visualstudio
versioningType: Ranged
title: Install Visual Studio Build Tools into a container to support a consistent build system | Microsoft Learn
canonicalUrl: https://learn.microsoft.com/en-us/visualstudio/install/build-tools-container?view=visualstudio
config_moniker_range: '>= vs-2022'
feedback_system: Standard
feedback_help_link_url: https://developercommunity.microsoft.com/VisualStudio
feedback_help_link_type: ask-the-community
feedback_product_url: https://developercommunity.visualstudio.com/VisualStudio/suggest
breadcrumb_path: /visualstudio/_breadcrumb/toc.json
ms.manager: wiwagn
author: RoseHJM
ms.author: rosemalcolm
audience: developer
ms.service: visual-studio-windows
uhfHeaderId: MSDocsHeader-VisualStudio
toc_preview: true
archive_url: /previous-versions/visualstudio
recommendations: true
description: Learn how to install Visual Studio Build Tools into a Windows container to support continuous integration and continuous delivery (CI/CD) workflows.
ms.date: 2025-02-05T00:00:00.0000000Z
ms.topic: concept-article
ms.subservice: installation
locale: en-us
document_id: b91a4a43-5353-97cf-7532-7644aa3b497f
document_version_independent_id: 858d9a5c-72f3-6a85-9270-0a0dd9e0438b
updated_at: 2026-04-24T22:06:00.0000000Z
original_content_git_url: https://github.com/MicrosoftDocs/visualstudio-docs-pr/blob/live/docs/install/build-tools-container.md
gitcommit: https://github.com/MicrosoftDocs/visualstudio-docs-pr/blob/12e72ec4821de23d6dc3ce8f2219d1ac0fe00968/docs/install/build-tools-container.md
git_commit_id: 12e72ec4821de23d6dc3ce8f2219d1ac0fe00968
default_moniker: visualstudio
site_name: Docs
depot_name: VS.docs
page_type: conceptual
toc_rel: ../toc.json
pdf_url_template: https://learn.microsoft.com/pdfstore/en-us/VS.docs/{branchName}{pdfName}
word_count: 1557
asset_id: install/build-tools-container
moniker_range_name: f22a899ea89b53168e6a2ccb9c507f5c
monikers:
- vs-2022
- visualstudio
item_type: Content
source_path: docs/install/build-tools-container.md
cmProducts:
- https://authoring-docs-microsoft.poolparty.biz/devrel/4628cbd9-6f47-4ae1-b371-d34636609eaf
- https://microsoft-devrel.poolparty.biz/DevRelOfferingOntology/ff72485c-5491-4598-8cf8-17f48e268d96
- https://authoring-docs-microsoft.poolparty.biz/devrel/bcbcbad5-4208-4783-8035-8481272c98b8
spProducts:
- https://authoring-docs-microsoft.poolparty.biz/devrel/be21deb8-8c64-44b0-b71f-2dc56ca7364f
- https://microsoft-devrel.poolparty.biz/DevRelOfferingOntology/e87c7dc9-41c0-49ff-b292-5fb5aa6540f8
- https://authoring-docs-microsoft.poolparty.biz/devrel/43b2e5aa-8a6d-4de2-a252-692232e5edc8
platformId: 5ae8856e-81b2-9ba3-05f3-431b51d22328
---

# Install Visual Studio Build Tools into a container to support a consistent build system | Microsoft Learn

You can install Visual Studio Build Tools into a Windows container to support continuous integration and continuous delivery (CI/CD) workflows. This article guides you through what Docker configuration changes are required, as well as what [workloads and components](workload-component-id-vs-build-tools) you can install in a container.

[Containers](https://www.docker.com/what-container) are a great way to package a consistent build system you can use, not only in a CI/CD server environment but for development environments as well. For example, you can mount your source code into a container to be built by a customized environment while you continue to use Visual Studio or other tools to write your code. If your CI/CD workflow uses the same container image, you can rest assured that your code builds consistently. You can use containers for runtime consistency as well, which is common for micro-services using multiple containers with an orchestration system; however, that's beyond the scope of this article.

If Visual Studio Build Tools doesn't have what you require to build your source code, these same steps can be used for other Visual Studio products. Do note, however, that Windows containers don't support an interactive user interface so all commands must be automated.

## Before you begin

Some familiarity with [Docker](https://www.docker.com/what-docker) is assumed. If you're not familiar with it, learn how to install and configure the [Docker engine on Windows](/en-us/virtualization/windowscontainers/manage-docker/configure-docker-daemon).

The following base image is a sample and might not work for your system. Read [Windows container version compatibility](/en-us/virtualization/windowscontainers/deploy-containers/version-compatibility) to determine which base image you should use for your environment.

## Create and build the Dockerfile

Save the following example Dockerfile to a new file on your disk. If the file is named simply *Dockerfile*, it's recognized by default.

Warning

This example Dockerfile excludes only earlier Windows SDKs that can't be installed into containers. Earlier releases cause the build command to fail.

1. Open a command prompt.
2. Create a new directory (recommended):

    ```shell
    mkdir C:\BuildTools
    ```
3. Change directories to this new directory:

    ```shell
    cd C:\BuildTools
    ```
4. Save the following content to C:\BuildTools\Dockerfile.

::: moniker range="visualstudio"

    ```dockerfile
    # escape=`
    
    # Use the latest .NET Framework runtime image.
    FROM mcr.microsoft.com/dotnet/framework/runtime:4.8.1-windowsservercore-ltsc2025
    
    # Restore the default Windows shell for correct batch processing.
    SHELL ["cmd", "/S", "/C"]
    
    RUN `
        # Download the Build Tools bootstrapper.
        curl -SL --output vs_buildtools.exe https://aka.ms/vs/stable/vs_buildtools.exe `
        `
        # Install Build Tools with the Microsoft.VisualStudio.Workload.AzureBuildTools workload, excluding workloads and components with known issues.
        && (start /w vs_buildtools.exe --quiet --wait --norestart --nocache `
            --installPath "%ProgramFiles(x86)%\Microsoft Visual Studio\BuildTools" `
            --add Microsoft.VisualStudio.Workload.AzureBuildTools `
            --remove Microsoft.VisualStudio.Component.Windows10SDK.10240 `
            --remove Microsoft.VisualStudio.Component.Windows10SDK.10586 `
            --remove Microsoft.VisualStudio.Component.Windows10SDK.14393 `
            --remove Microsoft.VisualStudio.Component.Windows81SDK `
            || IF "%ERRORLEVEL%"=="3010" EXIT 0) `
        `
        # Cleanup
        && del /q vs_buildtools.exe
    
    # Define the entry point for the docker container.
    # This entry point starts the developer command prompt and launches the PowerShell shell.
    ENTRYPOINT ["C:\\Program Files (x86)\\Microsoft Visual Studio\\BuildTools\\Common7\\Tools\\VsDevCmd.bat", "&&", "powershell.exe", "-NoLogo", "-ExecutionPolicy", "Bypass"]
    ```

Tip

To target 64-bit, specify the `-arch=amd64` option in the `ENTRYPOINT` command to start the [Developer Command Prompt for Visual Studio](../ide/reference/command-prompt-powershell#developer-command-prompt) (`VSDevCmd.bat`).

For example: `ENTRYPOINT ["C:\\Program Files (x86)\\Microsoft Visual Studio\\BuildTools\\Common7\\Tools\\VsDevCmd.bat", "-arch=amd64", "&&", "powershell.exe", "-NoLogo", "-ExecutionPolicy", "Bypass"]`

Warning

If you base your image directly on *microsoft/windowsservercore*, the .NET Framework might not install properly and no install error is indicated. Managed code might not run after the install is complete. Instead, base your image on *microsoft/dotnet-framework:4.8* or later. Also note that images that are tagged version 4.8 or later might use PowerShell as the default `SHELL`, which causes the `RUN` and `ENTRYPOINT` instructions to fail.

To learn which container OS versions are supported on which host OS versions, see [Windows container version compatibility](/en-us/virtualization/windowscontainers/deploy-containers/version-compatibility). Check Troubleshooting Windows and Build Tools containers for known issues.

::: moniker-end

::: moniker range="vs-2022"

    ```dockerfile
    # escape=`
    
    # Use the latest Windows Server Core 2022 image.
    FROM mcr.microsoft.com/windows/servercore:ltsc2022
    
    # Restore the default Windows shell for correct batch processing.
    SHELL ["cmd", "/S", "/C"]
    
    RUN `
        # Download the Build Tools bootstrapper.
        curl -SL --output vs_buildtools.exe https://aka.ms/vs/17/release/vs_buildtools.exe `
        `
        # Install Build Tools with the Microsoft.VisualStudio.Workload.AzureBuildTools workload, excluding workloads and components with known issues.
        && (start /w vs_buildtools.exe --quiet --wait --norestart --nocache `
            --installPath "%ProgramFiles(x86)%\Microsoft Visual Studio\2022\BuildTools" `
            --add Microsoft.VisualStudio.Workload.AzureBuildTools `
            --remove Microsoft.VisualStudio.Component.Windows10SDK.10240 `
            --remove Microsoft.VisualStudio.Component.Windows10SDK.10586 `
            --remove Microsoft.VisualStudio.Component.Windows10SDK.14393 `
            --remove Microsoft.VisualStudio.Component.Windows81SDK `
            || IF "%ERRORLEVEL%"=="3010" EXIT 0) `
        `
        # Cleanup
        && del /q vs_buildtools.exe
    
    # Define the entry point for the docker container.
    # This entry point starts the developer command prompt and launches the PowerShell shell.
    ENTRYPOINT ["C:\\Program Files (x86)\\Microsoft Visual Studio\\2022\\BuildTools\\Common7\\Tools\\VsDevCmd.bat", "&&", "powershell.exe", "-NoLogo", "-ExecutionPolicy", "Bypass"]
    ```

Tip

To target 64-bit, specify the `-arch=amd64` option in the `ENTRYPOINT` command to start the [Developer Command Prompt for Visual Studio](../ide/reference/command-prompt-powershell#developer-command-prompt) (`VSDevCmd.bat`).

For example: `ENTRYPOINT ["C:\\Program Files (x86)\\Microsoft Visual Studio\\2022\\BuildTools\\Common7\\Tools\\VsDevCmd.bat", "-arch=amd64", "&&", "powershell.exe", "-NoLogo", "-ExecutionPolicy", "Bypass"]`

Warning

If you base your image directly on *microsoft/windowsservercore*, the .NET Framework might not install properly and no install error is indicated. Managed code might not run after the install is complete. Instead, base your image on *microsoft/dotnet-framework:4.8* or later. Also note that images that are tagged version 4.8 or later might use PowerShell as the default `SHELL`, which causes the `RUN` and `ENTRYPOINT` instructions to fail.

To learn which container OS versions are supported on which host OS versions, see [Windows container version compatibility](/en-us/virtualization/windowscontainers/deploy-containers/version-compatibility). Check Troubleshooting Windows and Build Tools containers for known issues.

::: moniker-end

    Note

    Error code `3010` is used to indicate success with a reboot required. For more information, see [MsiExec.exe error messages](/en-us/windows/win32/msi/error-codes).
5. Run the following command within that directory.

::: moniker range="visualstudio vs-2022"

    ```shell
    docker build -t buildtools:latest -m 2GB .
    ```

This command builds the Dockerfile in the current directory using 2 GB of memory. The default 1 GB isn't sufficient when some workloads are installed; however, you might be able to build with only 1 GB of memory depending on your build requirements.

The final image is tagged *buildtools:latest* so you can easily run it in a container as *buildtools* since the *latest* tag is the default if no tag is specified. If you want to use a specific version of Visual Studio Build Tools in a more [advanced scenario](advanced-build-tools-container), you might instead tag the container with a specific Visual Studio build number as well as *latest* so containers can use a specific version consistently.

::: moniker-end

## Use the built image

Now that you have created an image, you can run it in a container to do both interactive and automated builds. The example uses the Developer Command Prompt, so your PATH and other environment variables are already configured.

1. Open a command prompt.
2. Run the container to start a PowerShell environment with all developer environment variables set:

::: moniker range="visualstudio vs-2022"

    ```shell
    docker run -it buildtools
    ```

::: moniker-end

To use this image for your CI/CD workflow, you can publish it to your own [Azure Container Registry](https://azure.microsoft.com/services/container-registry) or other internal Docker registry so servers need only to pull it.

Note

If the Docker container fails to start, there's likely a Visual Studio installation issue. You can update the Dockerfile to remove the step that calls the Visual Studio batch command. This enables you to start the Docker container and read the installation error logs.

In your Dockerfile file, remove the `C:\\BuildTools\\Common7\\Tools\\VsDevCmd.bat` and `&&` parameters from the `ENTRYPOINT` command. The command should now be `ENTRYPOINT ["powershell.exe", "-NoLogo", "-ExecutionPolicy", "Bypass"]`. Next, rebuild the Dockerfile and execute the `run` command to access container files. To locate the installation error logs, go to the `$env:TEMP` directory and locate the `dd_setup_<timestamp>_errors.log` file.

After you identify and fix the installation issue, you can add the `C:\\BuildTools\\Common7\\Tools\\VsDevCmd.bat` and `&&` parameters back to the `ENTRYPOINT` command and rebuild your Dockerfile.

For more information, see Troubleshooting Windows and Build Tools containers.

## Troubleshooting Windows and Build Tools containers

There are a few issues when installing Visual Studio into a Docker container.

### Troubleshoot Windows containers

The following known issues occur when you install Visual Studio Build Tools into a Windows container.

- Pass `-m 2GB` (or more) when building the image. Some workloads require more memory than the default 1 GB when installed.
- Configure Docker to use disks larger than the default 20 GB.
- Pass `--norestart` on the command line. As of this writing, attempting to restart a Windows container from within the container returns `ERROR_TOO_MANY_OPEN_FILES` to the host.
- If you base your image directly on mcr.microsoft.com/windows/servercore, the .NET Framework might not install properly and no install error is indicated. Managed code might not run after the install is complete. Instead, base your image on microsoft/dotnet-framework:4.7.1 or later. As an example, you might see an error when building with MSBuild that's similar to the following:

> 
> C:\BuildTools\MSBuild\15.0\bin\Roslyn\Microsoft.CSharp.Core.targets(84,5): error MSB6003: The specified task executable "csc.exe" could not be run. Could not load file or assembly 'System.IO.FileSystem, Version=4.0.1.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a' or one of its dependencies. The system cannot find the file specified.

### Troubleshoot Build Tools containers

The following known issues might occur when you use a Build Tools container. To see whether issues have been fixed or if there are other known issues, visit [Developer Community](https://aka.ms/feedback/suggest?space=8).

- IntelliTrace might not work in [some scenarios](https://github.com/Microsoft/vstest/issues/940) within a container.
- On older versions of Docker for Windows, the default container image size is only 20 GB and doesn't fit Build Tools. Follow [instructions to change image size](/en-us/virtualization/windowscontainers/manage-containers/container-storage#storage-limits) to 127 GB or more. To confirm a disk space issue, check the log files for more information. Your `vslogs\dd_setup_<timestamp>_errors.log` file includes the following if you run out of disk space:

```
Pre-check verification: Visual Studio needs at least 91.99 GB of disk space. Try to free up space on C:\ or change your target drive.
Pre-check verification failed with error(s) :  SizePreCheckEvaluator.
```

---

## Other Supported Versions

- [vs-2017](https://learn.microsoft.com/en-us/visualstudio/install/build-tools-container?view=vs-2017&accept=text/markdown)
