# The gate

The gate is the project's whole-system check. Exactly one party runs it, and that party is the orchestrator.

## Why not the lanes

Three reasons, and each has cost a project real time:

1. **A lane measuring its own change is not a check.** It runs the checks it expects to pass.
2. **Concurrency.** The gate touches every suite and the whole build output, so several lanes running it is a
   contention problem, not a verification one.
3. **One consistent state.** The gate's answer is only meaningful for a tree that is not being written while
   it runs. The orchestrator is the one party who can hold still.

So the division is: **lanes run scoped checks on their own change; the orchestrator runs the gate after a
handover.**

## What the gate covers

- **The build**, with the warning count reported rather than merely tolerated.
- **Every test suite**, and a count of projects validated against the solution - a project that is not in the
  solution is not being tested, which is a silent hole.
- **A long-running end-to-end lane** that exercises the assembled system, kept even though it is the slowest
  part. Skipping it is how a system stops working as a whole while every unit stays green.
- **The exit criterion**, scored mechanically from a produced artifact rather than read by a person.

## Reading the result

- **A green gate with a falling test count is a failure**, not a pass. Compare counts, not just statuses.
- **A red gate after a handover is information, not blame.** The question is whether the failure predates the
  hand-in.
- **Attribute before fixing.** A failure in a file nobody touched is usually the previous writer's, and saying
  so costs one sentence.
- **Never pin a moving value to make the gate pass.** A boundary that tracks several workstreams' progress
  should be recorded as an observation rather than asserted.

## Staged expectations go stale in a specific way

When behaviour improves, the gate's own expectations must be rewritten to the stronger claim. A check that
pinned "the unit fails with reason X" should become "the unit completes with no failure at all", not be deleted.
The tell that this was missed is a gate that passes while the reported behaviour is obviously out of date.

The same applies to a criterion: when a criterion's expectations are corrected, **the count may go down** and
that is the instrument becoming honest. A pass awarded for an absent record is worse than a failure.

## Running the gate

```text
1. Confirm no lane is mid-write. The gate is meaningless on a moving tree.
2. Run the full gate. Record: build result, warning count, each suite's passed/failed, and the exit criterion.
3. Compare the counts with the previous run, not just the status.
4. Attribute any failure before fixing it.
5. Record the result where the next reader will find it.
```

## What to record

```text
gate <date>
  build            clean, <n> warnings, <n> projects validated
  suites           <n>/<n> passed across <n> suites
  end-to-end       <result>
  exit criterion   <pass>/<fail>/<unknown> of <total>
  verdict          green | red, with the attributions
```

Recording the **unknown** count matters as much as the pass count, because it is the measure of how much of the
project rests on unverified assertion.
