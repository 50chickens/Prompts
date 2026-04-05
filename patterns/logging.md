See the pattern under folder structures for log paths. keep the logs within the REPO_ROOT folder so that they are always within the workspace and you do not need to ask me.

for nunit test logging look for:

look for Ipscm.Library.Logging.NUnit and use BuildTestConfiguration & UseNunitTestContext.
the ipscm logging libraries are available in the ipscm.* nuget packages. they reference the nlog packages themselves so you don't need to add them directly. 