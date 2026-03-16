Workflow overview for Ipscm, Setup, and Alsionyx repositories.

## Repositories.

Repository structure guidance.

The setup repository contains shared audio infrastructure code including device abstractions, routing, and plugin loading. The ipscm repository contains generic infrastructure shared across all projects: logging, DI configuration, HTTP utilities, and other cross-cutting concerns. The alsionyx repository contains end applications that use setup and ipscm libraries. When creating new projects determine which category they belong to: if it is audio-specific put it in setup, if it is generic infrastructure put it in ipscm, if it is an application put it in alsionyx.
Ipscm is generic infrastructure for logging, dependency injection, HTTP utilities, and other cross-cutting concerns. It is the foundation that both Setup and Alsionyx depend on. Packages published by Ipscm are prefixed Ipscm.* and are all private NuGet packages.
Setup contains audio-specific infrastructure including device abstractions, audio routing, and plugin loading mechanisms. It depends on Ipscm and publishes audio-related packages prefixed Alsionyx.Library.Audio.*. The Setup repository also publishes Alsionyx.Library.Plugins.Lv2 for LV2 plugin integration.
Alsionyx is the end-user application layer. It consumes libraries from both Ipscm and Setup, contains the console app for LV2 plugin loading, and includes offline audio verification services. Alsionyx does not publish NuGet packages (createNugetPackages: false in CI config).
All three repos use the develop branch for active development. Each repo has GitHub Actions CI configured.

## iteration & testing process:
the iteration process is: 
    - gather requirements
    - make changes.
    - run all gh.ps1 scripts in order to verify code builds and tests ok before doing any commits. 
    - note the following paths:
        ~/git/internal/Alsionyx/Alsionyx/ci/gh.ps1
        ~/git/internal/Ipscm/ci/gh.ps1
        ~/git/internal/Setup/Alsionyx/ci/gh.ps1
    - git commit the changes.
    - verify github actions succcess.
Code formatting errors (WHITESPACE) must be fixed. Run dotnet format on the solution, commit the formatting changes, and push again.
If tests fail locally, examine the NUnit output. Tests must be deterministic and fast. No timing assertions, no Task.Delay in test logic, and no tests for DoesNotThrow() (meaningless).
When pushing to github check workflow status: gh run list --repo $repoName --limit 1 --json conclusion. If failure, get logs: gh run view <runId> --repo $repoName  --log-failed.


## local testing, git, github workflow.

Before pushing any changes, always run the local build script first. Each repo has a /ci/gh.ps1 (or equivalent) which orchestrates the full build pipeline locally. Run this from the ci directory: pwsh ./gh.ps1. gh.ps1 will switch to the folder that it lives in and then all files/folders are relative to that.
The gh.ps1 script performs: restore dependencies via NuGet, dotnet build, dotnet format (whitespace check), compile for package creation, and NUnit tests. If any step fails, fix the issue before pushing.
gh.ps1 is for running the pipeline to pick up errors before commiting to git.
Whitespace formatting errors are common. Run dotnet format <solution> from the src directory to auto-fix all formatting issues. Verify with gh.ps1 again.
After local build passes, commit changes with git add -A && git commit -m "descriptive message" && git push origin develop. This triggers GitHub Actions CI.
When running locally use two powershell files - 
gh.ps1 and build-test.ps1. gh.ps1 should call build-test.ps1 with -nugetPackageSourceName "local-nuget-repo".
gh.ps1 should not test for the nuget repo to exist. it should fail during the restore process.
When running locally use two powershell files - 
    - gh.ps1 and build-test.ps1. gh.ps1 should call build-test.ps1 with -nugetPackageSourceName "local-nuget-repo".
    - gh.ps1 should not test for the nuget repo to exist. it should fail during the restore process.

## GitHub Actions CI pipeline.

Each repo has .github/workflows/build-test.yml (or yaml) that runs on push to develop. The workflow has three steps: checkout, setup .NET 9.0, add NuGet source with GITHUB_TOKEN, and run build-test.ps1. do not reference gh.ps1 in build-test.yml. gh.ps1 is for developing locally.
The workflow file sets permissions: contents: read, packages: write. This allows the workflow to authenticate with GitHub Packages NuGet source.
build-test.ps1 is in the ci/ folder and accepts -NugetSourceName parameter. Default is "github". The script restores dependencies, builds, formats, packages, and runs tests. If it fails, the workflow logs will show the exact error.

## NuGet packages and versioning.

Packages are built only when the build succeeds and are published to GitHub Packages (nuget.pkg.github.com/$githubOrg$/...). All packages are private.
Version format is MajorVersion.MinorVersion.BuildNumber. BuildNumber is computed as the first 9 digits of System.DateTime.UtcNow.Ticks (unix ticks). This ensures each CI run produces a unique version.
Build configuration is always Debug. Version and build config are passed as parameters to build.xml which invokes msbuild.
Package names must not include -Debug or -Release suffixes. Version numbers are clean only.
Adding or removing packages must be done via dotnet add/remove commands, not by direct .csproj editing. Editing .csproj directly is only permitted for version updates of existing packages, and only after verifying the version exists in NuGet.
Assembly loading uses the standard .NET assembly resolution. Ensure all PackageReferences in .csproj files match actual NuGet packages. ProjectReferences must be converted to PackageReferences when packages are published (e.g., Alsionyx.Library.Audio.SoundFlow converts ProjectRef to PackageRef).

## nuget package repo permissions.
Cross-repository package dependencies and permissions.
The three repos have cross-repo NuGet dependencies. GitHub Packages restricts private package access by default to the repo that owns them. When RepoA depends on a private package from RepoB, RepoA's CI workflow cannot authenticate to RepoB's packages without explicit permission.
If local gh.ps1 passes but GitHub Actions fails, the issue is usually package permissions or a transitive dependency not found. Check the Actions log for 403 errors and apply fixes to Package settings.
NuGet Package Permissions.
When this repo depends on NuGet packages hosted in GitHub Packages from another private repository the GitHub Actions workflow needs proper permissions. The workflow must have permissions: packages: write to authenticate with the GitHub Packages NuGet source. The GITHUB_TOKEN passed to dotnet nuget add source requires read access to the external packages. If builds fail with 403 Forbidden errors when restoring packages, verify repository access: the user running the build must have access to the source repository, or the packages must be published as public. To verify package access without fixing, use: gh api -H "Accept: application/vnd.github+json" "/repos/50chickens/REPO/packages?package_type=nuget" or check the workflow logs for authentication errors. 

## Common issues and fixes.
Build failure with error NU1301 and 403 Forbidden means the consuming repo does not have read access to a private package. Check the package name in the error, go to its GitHub Package page, and add the consuming repo's read access. Re-run the workflow after granting access.