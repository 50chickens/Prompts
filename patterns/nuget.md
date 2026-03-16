## Nuget packages & versions etc.

NEVER directly edit .csproj or Directory.Packages.props to add or remove packages. Use dotnet add/remove commands.
DIRECT EDITING permitted only for changing versions of existing packages.
VERSION UPDATES require verification: target version exists, determine if managed per-project or centrally, update version, run dotnet restore.
do not create nuget.config files in the project directory. if the nuget source does not exist you should never create it. The build should fail. NuGet sources are configured in the user's global config. Never create project-level NuGet.Config files.
Do not append -Debug or -Release suffixes to package names.
