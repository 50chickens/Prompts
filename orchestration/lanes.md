# Lanes

A **lane** is one agent unit with a bounded objective, an explicit file ownership list, and a report it is obliged to write. The orchestrator launches lanes; lanes never launch lanes. A lane rather than a task is what makes several units safe to run at once: collisions come from shared files and shared build output, never from concurrent thinking.

## Ownership

Every brief names **you own** - the files and folders this lane may write - and **you do not own**. If you need a change in a file you do not own, **stop and say so rather than editing it**.

```text
lane1  owns: src/component1/**, tests/component1/**
       does not own: src/component2/**, scripts/pipeline/**
lane2  owns: nothing writable; writes report2.md only
```

A lane that needs configuration adds its own file beside the existing ones rather than editing shared configuration, and a lane that needs a change in a shared document describes it in its report rather than making it.

## Archetypes

| Shape | Owns | Runs beside | Verified by |
|-------|------|-------------|-------------|
| **Implementation** | files under the source tree | nothing else that writes build output | scoped tests; the orchestrator runs the gate |
| **Investigation** | one report under the coordination folder | anything | its own citations and measurements |
| **Authoring** | documents and generated data | anything | the artefact it produced, cited in its report |
| **Review** | nothing, or one named document | anything | a named document another unit can attack |
| **Research** | a scratch area outside the source tree | anything | its own notes, with the versions it read |

Only the implementation shape writes build output, so only it needs serialising; every other shape runs alongside an implementation lane.

## Splitting work so lanes do not collide

Split by file, not by concept: two units in "the same subsystem" in different files are fine, two units in one file are not. Split by evidence, not by effort: two questions needing the same measurement are one lane with one run. Split by what can be discarded: a document output can be wrong cheaply and a code output cannot.

## Delegating

Delegate the lightweight work: research, cloning a repository, reading one to answer a question, checking one claim. The orchestrator writes the brief, judges what comes back and corrects the documents. Direct execution is for work that owns a decision, a build, or an artefact the delegator signs off.

Before delegating, answer in writing whether the unit is on the path to the delivery and is the highest-value unit available. Rank it against the critical path and name the node it unblocks; a unit that unblocks none goes in the queue, not in a slot. When a lane's own evidence contradicts the reason it was launched, stop it and say which reasoning failed.

Clone repositories with `gh` rather than reading individual files through the GitHub content API: one clone answers every later question from local files, and the next agent inherits the evidence.

## Keeping the roster running

**Never more than four lanes at once.** Four is a ceiling, not a target: a larger roster produces silent crashes faster than it produces work.

**Poll every five minutes rather than waiting for notifications.** A cancelled or failed agent produces no notification. Compare the running list against the number launched: anything in neither list nor the completed results has died, so release its lock, keep what its stub holds, and relaunch it.

**Idle is never the expected state.** When nothing is running, list the queue and launch the next deliverable; if the queue is empty, take the next incomplete item from the prioritised list, write a brief and launch that. An empty roster is acceptable only when the project is complete, or when a decision needs the user and every other line of work is blocked behind it. When work is serialised by a single-owner file, fill the spare slot with read-only work or work on disjoint files.

**Fill an idle slot with evidence.** When the build lane is the bottleneck, convert a queued implementation unit into a read-only unit that produces the evidence that implementation will need. Work measured in arrival time rather than effort - a capture needing hardware, an approval, access that must be requested - starts on day one and is recorded where the queue can see it.

## What a lane actually has

Inheritance is not automatic: the tool surface is resolved per unit by the runtime and the unit's declared type, so a unit that cannot find a tool reports it missing after spending its budget.

| Capability | Assume before measuring |
|------------|-------------------------|
| Shell, file read and write, search, glob | present |
| Repository instruction files | likely present, being scoped to the workspace |
| Skills and plugin-supplied tools | unverified, resolved per agent |
| Domain MCP servers | absent until measured |
| Agent-launching tools | may be present, so every brief forbids their use explicitly |

Probe with one lane asked four questions and nothing else: which model identifier are you on, which servers are in your tool list, can you read a project file, and which tools are missing. Record the answers with the date in the environment document.

## Provisioning: the orchestrator installs, the lane builds

**The orchestrator provisions** anything system-level, shared or needed by more than one lane: one script, installed once before the lanes that need it, pinned and reproducible on another host. A version number belongs here and nowhere else.

**A lane builds** a tool it needs, provided the tool is a file it owns: a script under its own work folder, a single-file program run directly, a compiled inner loop. The report cites the tool, not only its output.

For everything else, **a lane does not install**: an install is unpinned, mutates shared state while other lanes assume stability, and turns a bounded unit into an open-ended one. A lane that believes it needs one reports the tool, why, and what it would have bought, then stops; the orchestrator provisions it and relaunches. An installation step is a script, not a sequence of manual actions.

## No live peer channels by default

Two lanes talking produce agreement, and agreement is not evidence: the record shows two lanes that concur without showing why, and a validator that talks to the author becomes a co-author. Keep the channel off; use an append-only questions file the orchestrator relays when coordination is needed, or have the orchestrator write the contract for an interface two lanes sit on opposite sides of.

## Contention

The two collision surfaces are shared files and shared build output; ownership lists handle the first. Shared output produces a "file in use" error naming a path, a test host whose assemblies were replaced mid-run, an intermittent failure that disappears on retry, or generated files in the wrong folder.

**Serialise through a lock.** Wrap the whole operation in one lock file held for its duration, so no caller reasons about it; see [samples/lock.ps1](samples/lock.ps1) for a file handle rather than a marker, a timeout that throws, and a recorded wait.

**Isolate the output** instead, so contention is impossible rather than unlikely:

```powershell
dotnet build -p:ArtifactsPath="C:\git\project1\artifacts\lane1"
```

Always pass an absolute path: a relative `ArtifactsPath` silently resolves under the source folder and produces duplicate-generated-file errors naming the wrong location. Isolated output is cold, so prefer the lock for the ordinary case.

**Any other shared resource takes the same treatment**: a serial port, a rate-limited service, a single-instance tool, a generated document many lanes read while one writes. A rate-limited service needs backoff with a growing interval and a bounded attempt count, recorded in the report.

**Diagnosing a suspected collision:** check the queue's `in_progress` folder rather than the filesystem for a second writer, find which lane writes the path the failure named, and treat a failure that vanishes on retry as a collision.

## Models

**If the project's own instructions name the model, that name is mandatory.** Every lane runs on that exact identifier, the brief names it on the first line, and the lane echoes it in the report stub. Do not substitute another model for a difficult unit, and do not treat the mandate as a default a unit may exceed; changing it is the project owner's decision. A mismatch between the identifier in the brief and the one in the report is a configuration fault: record it and rerun a load-bearing unit on the mandated model.

**With no mandate, leave the model unset** unless something external requires a forced one: a standards copy that must run on a specific model, a measured cost or latency problem for a class of unit, or a capability gap such as context size. Record the reason.

Match the model to the archetype: read-only review and cheap investigation give the best value per token, and implementation is serialised behind the build lock anyway. Escalate when a cheap unit returns work that has to be redone, de-escalate when an expensive unit is doing enumeration, and never escalate to fix a bad brief.

```text
lane1   mandated: <identifier>   (project rule)
lane2   mandated: <identifier>   (project rule)
lane3   default                  -
lane4   forced: <model2>         reason: needs long context for <document1>
```
