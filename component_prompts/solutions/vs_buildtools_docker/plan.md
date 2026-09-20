i need to create a docker container that contains the vs 2022 build tools. 

use teh orchestration pipeline pattern to scaffold creating an initial docker container where we download the vs_buildtools.exe from MS. 
it should be based on docker run mcr.microsoft.com/dotnet/framework/runtime:4.8.1-windowsservercore-ltsc2022.

use docker run mcr.microsoft.com/dotnet/framework/runtime:4.8.1-windowsservercore-ltsc2022.
download the vs_buildtools.exe from MS to c:\vs_buildtools in the container. 
run vs_buildtools.exe to create a minimal layout. the workload list should be 
ID: Microsoft.VisualStudio.Workload.ManagedDesktopBuildTools

the goal here is to create a pipeline that creates a docker container which contains the vs_buildtools.exe and the layout. 