---
name: csharp-code-reviewer
description: Review C# code for banned patterns and code smells (null-coalescing, nullable models, ternaries in flow control, upside-down filtering, bloated services, SDK types leaking through the codebase) and show how each should be rewritten. Use when asked to code review, clean up or reduce code in a C# repository.
---

# C# code reviewer

Companion to write-csharp-code. That skill says how to write code; this one says what to hunt for and what the fix looks like. Review the whole solution, not just the diff, and when a smell is found in one method check its siblings.
Core principle: filter before you work. Establish the facts about a collection or object once, at the boundary, into a type that cannot be wrong. Everything downstream then stops checking.

## Search first

Run these searches over production code before reading anything. Every hit is a candidate.

```
??
?.
| ? .* :
Func<
RemoveAll
LogManager
Process.Start
record
public [A-Za-z<>]+ [A-Za-z]+;
else if
try
\.
!;
new \w+Request
```

## Null-coalescing and null-conditional operators

Every `??`, `??=`, `?? []`, `?? string.Empty`, `?? throw` and chained `?.` is an assumption that was never resolved. Decide what is really true, filter on it once, and delete the operator.
Bad, collection assumed possibly null at every use.
```csharp
foreach (var instance in autoScalingGroup.Instances ?? [])
{
    instanceIds.Add(instance.InstanceId);
}
```
Good, the curated type guarantees the list.
```csharp
InstanceIds = autoScalingGroup.Instances.Select(instance => instance.InstanceId).ToList()
```
Bad, string fallbacks that hide a missing tag.
```csharp
var squad = autoScalingGroup.Tags?.FirstOrDefault(tag => tag.Key == "Squad")?.Value ?? string.Empty;
```
Good, eligibility requires the tag, conversion reads it without fallback.
```csharp
public static bool IsInstanceRefreshEligible(this AutoScalingGroup autoScalingGroup, List<string> stackNames, List<string> excludedStackNames)
{
    if (!autoScalingGroup.HasRequiredTags())
    {
        return false;
    }
    return true;
}

Squad = autoScalingGroup.GetRequiredTagValue(SquadTagKey)
```
Bad, optional parameter that is coalesced inside.
```csharp
public Task Trigger(string? amiId, bool? autoRollbackEnabled = null)
{
    AutoRollback = autoRollbackEnabled ?? false;
}
```
Good, the type says what is required, the default says what is optional.
```csharp
public Task Trigger(string amiId, bool autoRollbackEnabled = false)
{
    AutoRollback = autoRollbackEnabled;
}
```
Bad, resolve-or-throw fallback chains.
```csharp
amiId ??= (await GetCurrentAmiInfo(group))?.CommSecAmiId ?? throw new InvalidOperationException();
var template = (templates?.LaunchTemplates?.FirstOrDefault()) ?? throw new InvalidOperationException();
```
Good, filter to the items that can be worked on and skip the rest explicitly.
```csharp
if (!message.AmiIdsByVariant.TryGetValue(currentAmi.OsVersion.ToString(), out var targetAmiId))
{
    logger.Info($"No new AMI for {currentAmi.OsVersion}, skipping {group.Name}.");
    continue;
}
```
Bad, a nullable return type that is never null.
```csharp
Task<AmiInfo?> GetCurrentAmiInfo(string group);
```
Good, return type matches behaviour and the dead `== null` branches in callers go.
```csharp
Task<AmiInfo> GetCurrentAmiInfo(string group);
```
Genuinely optional data stays nullable, and is consumed with an explicit `if`, not a coalesce. Example: a base image tag that some AMIs do not have.
```csharp
public string? BaseImageName { get; set; }
```
## Ternary in flow control
Banned in loop sources, early returns and branching. Use `if`, or filter the collection beforehand.

Bad.
```csharp
return stackNames == null || stackNames.Count == 0 ? all : all.Where(group => stackNames.Any(group.Name.Contains)).ToList();
```
Good, two explicit methods, no null list.
```csharp
Task<List<EligibleAutoScaleGroup>> GetAll(CancellationToken cancellationToken = default);
Task<List<EligibleAutoScaleGroup>> GetForStacks(List<string> stackNames, CancellationToken cancellationToken = default);
```
## Nullable models built from unfiltered sources
If a `List<Model?>` or `Task<Model?>` exists only because the source was not filtered, filter the source.

Bad.
```csharp
List<AmiModel?> models = images.Select(ToAmiModel).ToList();
```

Good.
```csharp
var candidates = images.Where(image => image.MeetsCriteria()).ToList();
List<AmiModel> models = candidates.Select(ToAmiModel).ToList();
```

## Upside-down filtering

Bad, build an exclusion list then subtract it.
```csharp
var excluded = groups.Where(group => IsExcluded(group)).ToList();
groups.RemoveAll(group => excluded.Contains(group));
```

Good, state what survives.
```csharp
var eligible = groups.Where(group => group.IsInstanceRefreshEligible(stackNames, excludedStackNames)).ToList();
```
Eligibility predicates use exit gates, one reason per `if`.
```csharp
public static bool IsInstanceRefreshEligible(this AutoScalingGroup autoScalingGroup, List<string> stackNames, List<string> excludedStackNames)
{
    if (!autoScalingGroup.IsCommSecAutoScaleGroup())
    {
        return false;
    }
    if (!autoScalingGroup.IsInCurrentPhase())
    {
        return false;
    }
    return true;
}
```
## SDK and transport types leaking through the codebase
Raw SDK objects (`AutoScalingGroup`, `Image`, response wrappers) carry optional everything, so every consumer re-checks them. Convert once into a curated class with required properties and pass that instead.

Bad.
```csharp
Task<List<AutoScalingGroup>> GetEligibleGroups();
var squad = group.Tags?.FirstOrDefault(tag => tag.Key == "Squad")?.Value;
```

Good.
```csharp
public class EligibleAutoScaleGroup
{
    public required string Name { get; set; }
    public required string Squad { get; set; }
    public required List<string> InstanceIds { get; set; }
}
Task<List<EligibleAutoScaleGroup>> GetEligibleGroups();
```
The curated type is built in exactly one place, behind the eligibility filter. Test fixtures must build the same shape the real API returns, for example non-null `Tags` and `Instances`, rather than the code defending against hand-built objects.
## Extension methods
Bad, nullable receiver or parameters, delegates, SDK response wrappers, configuration objects, anything that talks to AWS.

```csharp
public static bool IsEligible(this AutoScalingGroup? group, Func<string, bool> isExcluded, Settings settings)
public static List<AutoScalingGroup> Filter(this DescribeAutoScalingGroupsResponse response)
```

Good, one specific job, plain working parameters, typed against the domain item or collection.
```csharp
public static bool IsExcludedByStackName(this AutoScalingGroup autoScalingGroup, List<string> excludedStackNames)
public static List<EligibleAutoScaleGroup> ToEligibleAutoScaleGroups(this List<AutoScalingGroup> autoScalingGroups, List<string> stackNames, List<string> excludedStackNames)
```
Unwrap the response at the call site: `response.AutoScalingGroups.ToEligibleAutoScaleGroups(...)`.
## Null-forgiving operator and negated nested null checks
`!` on a value whose nullability was never resolved is the same smell as `??` - it suppresses the compiler's real warning instead of fixing the nullability.
Bad.

```csharp
var amiId = currentAmi!.CommSecAmiId;
```

Good, filter or check explicitly so the value is genuinely non-null at that point.
```csharp
if (currentAmi == null)
{
    continue;
}
var amiId = currentAmi.CommSecAmiId;
```
Negated, nested nullable checks are the same problem read backwards.

Bad.
```csharp
if (!string.IsNullOrWhiteSpace(image?.Tags?.FirstOrDefault(tag => tag.Key == "Id")?.Value))
```

Good, resolve the tag once through a curated extension method and check the result directly.
```csharp
if (image.HasIdTag())
```
## Nested unrelated if/else-if chains
Chaining unrelated conditions through `else if` hides the fact that each branch is really a different named state.

Bad.
```csharp
if (function == _configuration.FunctionData)
{
    ProcessData();
}
else if (function == _configuration.FunctionReset)
{
    Reset();
}
else if (function == _configuration.FunctionShutdown)
{
    Shutdown();
}
```

Good, resolve to a single state value with early-exit guard clauses, then `switch` on it.
```csharp
switch (function)
{
    case var f when f == _configuration.FunctionData:
        ProcessData();
        break;
    case var f when f == _configuration.FunctionReset:
        Reset();
        break;
    case var f when f == _configuration.FunctionShutdown:
        Shutdown();
        break;
}
```
## Calling a cloud SDK directly from business logic

Bad, business logic talks to the AWS SDK directly and builds its request object inline.
```csharp
await _amazonEc2Client.DeleteTagsAsync(new DeleteTagsRequest
{
    Resources = [instanceId],
    Tags = [new Tag { Key = "Force" }]
});
```

Good, business logic calls a repository/service abstraction; the SDK request is built behind it.
```csharp
await _instanceRepository.RemoveForceTag(instanceId);
```
## Try/catch wrapping an entire method
Bad, one handler for every failure mode in the method, masking exactly where it failed.

```csharp
public async Task ProcessGroup(AutoScalingGroup group)
{
    try
    {
        var info = await GetCurrentAmiInfo(group);
        var template = await GetLaunchTemplate(group);
        await UpdateLaunchTemplate(template, info);
    }
    catch (Exception ex)
    {
        _log.Error(ex, "Failed to process group");
    }
}
```

Good, validate/filter before the method runs so it only ever runs against states expected to succeed; let genuine faults propagate.
```csharp
public async Task ProcessGroup(AutoScalingGroup group)
{
    var info = await GetCurrentAmiInfo(group);
    var template = await GetLaunchTemplate(group);
    await UpdateLaunchTemplate(template, info);
}
```
## Boolean flag controlling method behaviour
Bad, one signature silently has two different implementations behind a flag.
```csharp
public void InstallAgent(bool isWindows)
{
    if (isWindows)
    {
        // windows-specific install
    }
    else
    {
        // linux-specific install
    }
}
```

Good, split into two differently-named methods, or dispatch on an explicit enum/state.
```csharp
public void InstallAgentOnWindows() { }
public void InstallAgentOnLinux() { }
```

## Classes with too many concerns
A constructor with more than one business dependency (excluding logger, settings, cache, metrics) is a candidate to split. Typical causes and fixes:
A dashboard class that talks to Octopus and also to AWS. The dashboard should depend on one thing that already knows the answer.
A service depending on a sibling's dependency. If A needs B only to call C, then C belongs to B.
A thin pass-through method on a facade. Let the caller depend on the real service instead. This is OK if the facade adds no additional logic and exists solely for structural purposes. - eg IAwsAutoScaleGroupService (business class) -> IAutoScalingService (aws sdk)
Orchestration mixed with mapping. Keep the mapping class shallow (inputs in, model out) and put caching and looping in a coordinator.

Bad.
```csharp
public class DashboardService(IOctopusService octopus, IAmiService ami, IAutoScalingService autoScaling, IEligibleStackService stacks, IInstanceRefreshService refresh, IOctopusRepository repository, IMemoryCache cache, Settings settings)
```

Good.
```csharp
public class DashboardService(IOctopusService octopus, IAmiService ami, IEligibleAutoScaleGroupService groups, Settings settings)
```
A split should also reduce the substitutes needed in that class's unit tests. If it does not, the split was cosmetic.
## Unused and pointless code
Unused constructor parameters, unused interface members, unused public extension methods, unused optional parameters (a filter nobody passes), dead `if (x != null)` on values that cannot be null, a `continue` as the last statement of a loop, a warning log for a condition that is now impossible, commented-out code, and `// NoOp` comments. Delete them. Interfaces are only justified when they wrap an external dependency or exist for test substitution, and a wrapper around an existing abstraction is not justified.
## Duplicated branches

Bad, two blocks identical except for one or two fields.
```csharp
if (squadList.Count == 0)
{
    var model = new EmailModel { To = defaultAddress, Stack = stack };
    await channel.WriteAsync(model);
}
else
{
    var model = new EmailModel { To = squadList.First(), Stack = stack, Cc = squadList.Skip(1).ToList() };
    await channel.WriteAsync(model);
}
```

Good, build once, vary only what differs.
```csharp
var model = new EmailModel { To = defaultAddress, Stack = stack };
if (squadList.Count > 0)
{
    model.To = squadList.First();
    model.Cc = squadList.Skip(1).ToList();
}
await channel.WriteAsync(model);
```
Repeated status checks and repeated cache writes get one home: an extension predicate such as `refresh.IsRunning()`, and one method that writes the cache. Two TTLs for the same cache key is a bug.
## Hand-rolled loops that are queries

Bad.
```csharp
var relevant = new List<string>();
foreach (var alarm in alarms)
{
    if (alarm.State != StateValue.Unknown && alarm.Name.Contains(prefix))
    {
        relevant.Add(alarm.Name);
    }
}
```

Good.
```csharp
public static class AlarmExtensions
{
    public static IEnumerable<Alarm> AlarmIsValid(this IEnumerable<Alarm> alarms)
    {
        return alarms.Where(alarm => alarm.State != StateValue.Unknown);
    }
    public static IEnumerable<Alarm> AlarmIsRelated(this IEnumerable<Alarm> alarms, string prefix)
    {
        return alarms.Where(alarm => alarm.Name.Contains(prefix));
    }
    public static IEnumerable<string> AlarmNames(this IEnumerable<Alarm> alarms)
    {
        return alarms.Select(alarm => alarm.Name).ToList();
    }
}
var validAlarms = alarms.AlarmIsValid();
var relatedAlarms = validAlarms.AlarmIsRelated(prefix).AlarmNames();
return relatedAlarms;
```
Looking up the same thing twice in the same method (describe the group, then describe it again) is the same smell. Fetch once.
## Naming
A `string` named after the object convention misleads the reader.

Bad.
```csharp
Task Trigger(string autoScalingGroup)
```

Good.
```csharp
Task Trigger(string autoScalingGroupName)
```

## Dependency and architecture violations
Service locator calls deep in business logic, `LogManager.GetLogger` or static loggers inside services, `Null*` or no-op fallback classes, `configuration["Key"]` inside methods, `record` types, dynamic, public fields on DTOs, private classes, `Process.Start`, a service that builds its own un-injectable dependency. Each has a fix in write-csharp-code; flag them here and link the rule.
Silent fallbacks are failures in disguise. If a required value is absent the code should fail or the item should be filtered out with a log line, not continue with an empty string.
Constants on a business logic class that could reasonably change per environment/deployment, constructed inline (`new Config1()`) instead of injected - these belong on a dedicated `XxxConfiguration` class behind an interface (eg `IConfig1`), injected via DI, so the business logic class stays unit testable without needing a real configuration instance.

## Tests

Check these in test code:
The words mock, fake, dummy in type and variable names (NUnit method names are exempt).
Near-duplicate tests differing by a value. Merge into `[TestCase]` rows, one trailing comment per row when rows need different explanations.
Ternaries or `if` computing arranged or expected values. eg
bad

```csharp
var expected = condition ? value1 : value2;
```
good
```csharp
var expected = ComputeExpectedValue();
```
`Task.Delay`, `Stopwatch` and other timing-based assertions, `DoesNotThrow` as the only assertion, `[Explicit]` and environment-variable gating.
Copy-pasted arrange code. Move it to a shared data generator or `[SetUp]`.
Fixtures that are not the real shape. A test that builds an object the real API could never return forces production code to defend against it. Build the realistic shape and delete the defensive branch, and delete the test that exercised the defensive branch.
A test deleted because it exercised removed code is fine. Say so in the review.
where `[TestCaseSource]` can be used to replace repeated `[TestCase]` rows with a shared data source. if a unit test has more than 3 testcase is it a candidate for [TestCaseSource].
## Output of a review
Report findings grouped by pattern, each with file, line and the rewrite. List what was changed, what was deliberately left and why, and any behaviour change the cleanup causes (for example, items that no longer pass an eligibility filter), because filtering earlier changes which items reach downstream code.
After changes, build and run the full test suite, then search again for the operators above to confirm none remain in production code.
