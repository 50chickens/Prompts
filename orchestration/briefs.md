# Briefs

A brief is the unit of instruction. It is a file, not a message, because a file survives the lane, can be
re-read by a reviewer, and can be handed to a replacement unit unchanged.

## Why a file

- **It is resumable.** A lane that dies can be relaunched from its own brief plus whatever it wrote.
- **It is reviewable.** A reviewer can compare what was asked with what was reported.
- **It is reusable.** The same brief shape becomes the project's standard, which is what makes the standing
  rules accumulate instead of being restated.

The launch message should point at the brief rather than restating it. Two descriptions of the same work is one
description too many, and the message is the one that goes stale first.

## What every brief contains

1. **Goal** - one paragraph, in terms of the outcome rather than the activity.
2. **Established facts, measured - do not re-derive.** Everything the lane would otherwise spend its first turns
   rediscovering, each with its source. This section is usually the longest and is the one that pays.
3. **What to establish**, in priority order, with the deliverable named. If the census matters more than the
   single fix, say so here.
4. **What to measure and report**, with the exact quantities and their units.
5. **Standards** - what counts as evidence, what must not regress, and which mistakes this project has already
   made in this area.
6. **Ownership** - the two lists, plus the rule about stopping rather than editing.
7. **Output** - the report path, and the instruction to append as you go.
8. **Constraints** - languages allowed, tools forbidden, and where the primary sources live.
9. **Reuse** - the `TOOLS.md` entries the lane invokes, named by path, or a statement that none exist. A lane that needs a missing tool reports it rather than writing a private script.

The model identifier belongs at the top of the brief, spelled exactly as the project mandates it, with the
instruction to echo it as the first line of the report stub.

## Pre-flight the brief

Check in seconds what would otherwise cost a lane:

- Every path the brief names exists, in the form the brief gives it.
- The report path's parent exists and is writable.
- The model identifier is the project's mandated one, spelled exactly.
- The toolkit the brief names is reachable from the lane type being launched.
- The corpus is bounded by a name, a count or an address range rather than by "everywhere".

A brief with a dead path wastes an entire lane, and the check is the highest-value habit in this file.

## Standing rules worth putting in every brief

These are the ones that have proved load-bearing. Keep them in the template rather than rewriting them per lane.

- **You are one lane and you do not spawn lanes.**
- **The gate belongs to the orchestrator.** Run a scoped check on your own change only.
- **Create your report file as a stub within your first few tool calls**, then update it after every
  measurement. Write theories as well as findings. A theory written early survives a termination; a conclusion
  never written does not.
- **Never adjust an expected value to make a change pass.** A pinned expectation is a record of what was
  measured. If your change moves it, your change is wrong until shown otherwise, and if you believe the
  expectation was wrong, say so with the evidence instead of silently replacing it.
- **A fixture is not evidence.** A test authored to match the implementation says nothing about which side is
  wrong when the two disagree. Settle it from the primary source.
- **Name what you could not determine.** An honest unknown is a result; a guess presented as a finding is a
  defect the next unit will inherit.
- **A clear negative is a good result.** Several of a project's most useful outputs are negatives. Say so in
  the brief, because the default instinct is to chase a positive.
- **Report disagreements rather than reconciling them.** Where two sources conflict, say which is right and on
  what evidence. Do not average them.
- **Prefer a scripting language for orchestration and a compiled, statically typed language for calculation.**
  Do not branch to another language because it is natural for the problem. The narrow exception is when the
  artifact is hosted inside a specific tool, in which case write it in that tool's own language.
- **Do not enumerate whole trees, redirect output, or filter command output for display.** Ask for the specific
  thing you need. Output volume should be bounded by the question, not by the size of the filesystem.
- **Stop and report rather than working around a missing input.** A blocked lane that says why is useful.
- **Path facts in briefs go stale.** A bare relative path in a brief should be treated as a shorthand; resolve
  it before reporting anything as missing.
- **Cite the settled negatives rather than re-deriving them.** A project that keeps a refuted-claims document
  expects a lane to check it and move on, not to spend a unit rediscovering a settled no.

## The three sentences that must appear in every brief

State these even when the template states them, because a lane reads its own brief first:

- Do not run the gate; the orchestrator runs it once after handover.
- Create the report as a stub within your first few tool calls, and put theories in it as well as findings,
  labelled as theories.
- If a toolkit this brief names is unreachable, stop at once and say so rather than substituting a slower
  method.

The second is not ceremony: an unproved reading that turns out to be right is worth handing on, and the next
lane cannot recover it from a measurement alone.

## Context economy: name one document, not a folder

**A brief should name the one specification file the unit needs, not the folder that contains the
specifications.** A folder reference spends the unit's context on subsystems that cannot answer its question.

This generalises: for every input the brief names, ask whether the unit needs the whole thing or the part of it
that answers its question. The same applies to telling a unit to read a directory, run a full test suite, or
summarise a repository - each is a context cost with no matching benefit.

## State the prohibitions explicitly

**The most common failure is not a wrong answer; it is a unit wandering into a neighbouring subsystem.** A
brief that only says what to do will get work done somewhere else as well.

So list the prohibitions, and prefer specific ones over general:

```text
Do not build.
Do not edit the shared configuration.
Do not re-derive the settled negatives.
Do not widen the table to make a check pass.
Do not touch <file1>; if the fix needs it, stop and say so.
```


## Continuation briefs

A relaunch is a brief whose deliverable is "finish the work at this path". It names the report path, what is
already established there, and the last completed step. It never restates the original brief: restating invites
a restart, and a restart pays for the first attempt's discoveries twice. Write the continuation to the same
report path so the evidence accumulates in one place.

Two failures on one unit mean the brief is wrong. Rewrite it narrower, name the one file, supply the path the
lane could not find, or split it. Three failures mean the unit is not ready: retire it with the reason, or write
the preceding unit that supplies what it kept needing.

## Sizing a brief

**A good brief is specific about the deliverable and generous about the facts.** The failure modes are at both
ends:

- **Too vague** - the lane picks its own scope, and its report does not answer the question that prompted it.
- **Too prescriptive** - the brief specifies the implementation, the lane follows it, and the measurement that
  would have contradicted it never happens.

The middle ground is to state the outcome, the evidence standard and the constraint, then let the lane choose
the method.

## Including the answer, and knowing when not to

Sometimes the orchestrator already knows the answer. Say so, and say how confident it is:

- **Known fact** - put it in "established facts" with its source.
- **Reasoned guess** - mark it as a guess and say what would confirm it. Lanes that disprove a stated guess are
  doing their job; make that explicit or they will work around it instead.
- **No idea** - ask the question, not a route to the answer.

A lane that reports a refuted prediction has produced something valuable. Say in the brief that this is the
expected behaviour, because the default instinct is to make the stated guess true.

## Correcting the template

When the orchestrator corrects a lane's behaviour, the correction goes into the brief template, not into the
next brief's prose. This is what makes the standard accumulate. A rule that lives in the template applies to
every lane; a rule that lives in one brief applies to one lane and is forgotten.

```text
Brief rule N. <the correction, stated as an instruction>
Rationale: <one line, only if the rule looks arbitrary>
```

## Sample: the opening of a brief

```markdown
# <Outcome, stated as a noun phrase>

## Goal

<One paragraph. What will exist when this is done, and what it is for.>

## Established facts, measured - do not re-derive

- <Fact>. <Source>. <Date measured>.
- <Fact that contradicts a plausible assumption, with why the assumption is wrong>.

## What to establish

1. <The primary question, and the deliverable it should produce.>
2. <Sibling cases that must not change.>
3. <What may be left refused, and with what wording.>

## Report per <subject>, before and after

<Exact quantities, with units, and the new stopping point named explicitly.>

## Ownership

You own: <paths>.
You do not own: <paths>. If a fix needs one of these, stop and say so.

## Output

Append to `coordination/reports/<lane>/report.md` as you establish each fact.
```

A blank copy is in [templates/task-brief.md](templates/task-brief.md).
