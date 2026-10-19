# Lanes

A **lane** is one agent unit with a bounded objective, an explicit file ownership list, and a report it is
obliged to write. The orchestrator launches lanes; lanes never launch lanes.

## Why lanes rather than tasks

A task is what you want done. A lane is everything the unit needs in order to do it without interfering with
anything else: its files, its verification method, its report location, and its stopping condition. Assigning
work as a lane rather than a task is what makes several units safe to run at once, because the collisions come
from shared files and shared build output, never from concurrent thinking.

## Ownership

Every brief names two lists, and both are load-bearing:

- **You own** - the files and folders this lane may write.
- **You do not own** - files that another lane holds, or that the orchestrator holds, with the rule: if you need
  a change in one of these, **stop and say so rather than editing it**.

Two habits keep this honest:

- A lane that needs configuration should add its own file beside the existing ones rather than editing a shared
  config, because shared configuration is a collision surface.
- A lane that needs a change in a shared document should describe the change in its report rather than making
  it. Several documents are load-bearing for other units, so their owner edits them, not a passer-by.

## Lane archetypes

Most units fall into one of a few shapes. Naming the shape in the brief sets expectations about verification.

| Shape | Owns | Runs beside | Verified by |
|-------|------|-------------|-------------|
| **Implementation** | specific files under the source tree | nothing else that writes build output | scoped tests; the orchestrator runs the gate |
| **Investigation** | one report under the coordination folder | anything | its own citations and measurements |
| **Authoring** | documents and generated data | anything | the artifact it produced, cited in its report |
| **Review** | nothing, or one named document | anything | a named document another unit can attack |
| **Research** | a scratch area outside the main source tree | anything | its own notes, recorded with the versions it read |

Two properties fall out of this table and are worth stating explicitly:

- **Only the implementation shape writes build output**, so it is the shape that must be serialised.
- **Every other shape is read-only with respect to the build**, so it can run alongside an implementation lane
  instead of queueing behind it.

## Splitting work so lanes do not collide

Three heuristics, in order of how often they are needed:

1. **Split by file, not by concept.** Two units working on "the same subsystem" in different files are fine;
   two units in one file are not, even for unrelated changes.
2. **Split by evidence, not by effort.** If two questions need the same measurement, they are one lane with one
   run, not two lanes with two runs.
3. **Split by what can be discarded.** A lane whose output is a document can be wrong cheaply. A lane whose
   output is code cannot. When a question is uncertain, have the lane produce the document first and the code
   second, sometimes as two lanes.

## Filling an idle slot

When the build lane is the bottleneck - and it usually is - the right move is almost always to convert a queued
implementation unit into a read-only unit that produces the evidence that implementation will need. Transcribing
a field model, enumerating a corpus, or reconciling two sources can all be done without the build lane, and each
of them turns a unit that would discover facts one at a time into a unit that implements a known list.

This pays repeatedly. It is the single highest-value scheduling habit in this document.

## Long lead times beat effort as a constraint

Some work is not measured in effort but in how long it takes to arrive, and it is usually someone else's work:

- A capture or measurement that needs physical hardware.
- A review or approval from a person.
- A source, credential or access that has to be requested.

**Start these early and in parallel, even when the project is not ready to use the result.** They cost the
build lane nothing, they are the longest lead time in the project, and they are what makes correctness
measurable rather than a matter of opinion. A dependency that takes a week to arrive and costs one hour to
consume should be requested on day one.

Record such items where the queue can see them, and check what a receiver has to confirm against the external
system before assuming the request is complete.

## Lane hygiene

- **A lane does not spawn lanes.** A child unit launched by a lane is unaccounted for: it is not in the queue,
  it does not have an owner, and its model is not the one the orchestrator chose. If the work is too large, the
  lane stops, writes what it knows and says so.
- **A lane does not run the full gate.** It runs a scoped check on its own change.
- **A lane writes its report as it goes**, not at the end. See [reporting.md](reporting.md).
- **A lane names what it could not determine.** An honest unknown is a result; a guess presented as a finding
  is a defect that will be inherited.
- **A lane that stops early says why.** "Blocked on a missing input" is a useful report. Silence is not.

## Sample ownership table

```text
lane1  owns: src/component1/**, tests/component1/**
       does not own: src/component2/**, scripts/pipeline/**

lane2  owns: docs/document1.md, work/extracted/**
       does not own: src/**, docs/document2.md

lane3  owns: nothing writable; writes report3.md only
       does not own: everything else
```

The third row is the cheapest lane to run and often the most valuable, because a read-only unit can run
alongside every implementation lane without contention.

## What a lane actually has

Do not assume a lane inherits the orchestrator's tool surface. Measure it once per host and write briefs against
what was measured:

| Capability | Assume before measuring |
|------------|--------------------------|
| Shell, file read and write, search, glob | present |
| Repository instruction files | likely present, because they are scoped to the workspace |
| Skills and plugin-supplied tools | unverified, resolved per agent |
| Domain MCP servers | absent until measured; a lane that cannot find the tool looks like a lane that gave up |
| Agent-launching tools | may be present, so every brief forbids their use explicitly |

The probe is one lane asked four questions and nothing else: which model identifier are you on, which servers
are in your tool list, can you read a project file, and which tools are missing. Record the answers with the date
before writing the next brief.

## Provisioning: the orchestrator installs, the lane builds

- **The orchestrator provisions** anything system-level, shared or needed by more than one lane: one script,
  installed once, before the lanes that need it, pinned and reproducible on another host.
- **A lane builds** a tool it needs, provided the tool is a file it owns - a script under its own work folder, a
  single-file program run directly, a compiled loop. The report cites the tool, not only its output, so the next
  unit can regenerate the result.
- **A lane does not install** packages, runtimes or system components. An install is unpinned, mutates shared
  state while other lanes assume stability, and turns a bounded unit into an open-ended one. A lane that believes
  it needs an install reports the tool, why it needed it, and what it would have bought; the orchestrator
  provisions it and relaunches.

## No live peer channels by default

Two lanes talking to each other produce agreement, and agreement is not evidence. The record then shows two lanes
that concur without showing why, and independent validation is destroyed at the point it matters: if the author
and the validator talk, the validator becomes a co-author.

Two lanes that can talk also negotiate scope. The boundary they agree is unauthored: no brief covers it, and the
ownership lists overlap in a way the orchestrator does not know about.

Where coordination is genuinely needed, use an append-only questions file that the orchestrator reads and relays
at fixed intervals. It is asynchronous, it leaves a record, it cannot deadlock, and the decision stays with the
party who owns it.

## Terminal hygiene

A lane that leaves a process running leaves it on the host, and the next lane inherits the damage: a stale build
server holding assemblies, a watcher holding the output directory, an idle shell holding a console.

Every brief says: stop every shell session you start, do not leave a background or detached process, and if a
command has to outlive a single call, say so in the report.

The orchestrator takes a process-count baseline before a batch and compares it after. If the count grew by the
number of lanes run, something was left behind. Identify by id and start time, not by name, and stop the
specific process. A long-running command that exceeded its initial wait is not a leak; it is still running and
its output is retrievable, so read it rather than starting a second copy.
