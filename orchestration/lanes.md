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
