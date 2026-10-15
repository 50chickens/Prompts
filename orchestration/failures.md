# Failures

Long projects fail in ways that have nothing to do with the work. Recognising the failure mode quickly is worth
more than diagnosing it thoroughly, because the fixes are different for each.

## The failure modes, and how each is cured

| Symptom | Cause | Cure |
|---------|-------|------|
| Lane ends immediately with an account or quota error | Service balance exhausted | Nothing to fix in the work; resume when the service is available |
| Lane returns one line and no tool calls | Stalled turn, often following an interruption | Wake it with a specific instruction; do not re-brief |
| Lane returns a plausible-looking summary with no measurements | Brief too vague, or wrong model for the shape | Tighten the brief first |
| Lane returns work that has to be redone | Brief's facts were stale | Re-read briefs before launching them |
| Two lanes fail each other intermittently | Shared build output | Lock or isolate; see [contention.md](contention.md) |
| Lane writes findings nowhere and dies | No incremental reporting | Make incremental reporting a standing rule |
| Lane reports a network or DNS failure | Transient infrastructure | Record it; relaunch with "continue, do not restart" |
| Lane edits a file it does not own | Ownership list unclear or absent | State both lists explicitly |

## Balance and quota failures

These kill a unit before any work is done: the lane reports zero turns and a service error. Two consequences:

- **Nothing needs recovering.** A unit that never started has no partial state, so a fresh task is correct and
  there is no need to hunt for a stub.
- **A cluster of them is an infrastructure signal, not a work signal.** If several lanes fail this way in the
  same window, stop launching and wait rather than burning attempts.

Distinguish it from the next mode by the turn count. Zero turns means it never ran.

## Stalls

A stalled lane ends its turn after a sentence or two, having done nothing. It is idle, not finished, and its
state is intact.

**Wake it rather than re-briefing it.** A short message naming the first concrete step is enough:

```text
Your turn ended after a single line with no tool calls. Continue now and do the work rather than describing
it. Concretely: read <file1> and <file2>, then <first concrete step>. If something blocks you, say what and
stop, rather than ending silently.
```

Re-briefing a stalled lane loses whatever context it had built and is the wrong default.

## Nudge early: the dominant failure is silence, not slowness

The most common way to lose a unit's work is not that it is slow. It is that it works without recording
anything and then stops. **The observed pattern is that units are slow to record, not slow to work.**

So use the report file as a liveness signal:

- **If the report has not changed in about fifteen minutes, send a short steering message** that says what to
  write down and what to do next.
- This has recovered stalled units within minutes every time it was tried. It costs one message.
- Do not wait for the unit to finish before intervening; by then the work is gone.

A steering message should name a concrete next action and an obligation to write, not restate the goal:

```text
Your report has not changed in <duration>. Write down what you have established so far, then <next concrete
step>. If something blocks you, say what and stop.
```

## An incomplete installation that looks like a configuration fault

A truncated or half-extracted toolchain fails in a way that blames the wrong thing. The launcher starts
normally and then reports that a class or module is missing, which reads as a bad path, a broken extension or a
wrong version.

Verify the installation rather than the launcher's message:

- **Open every member of the archive** and confirm it reads. A file that will not open is the tell.
- **Check a specific known artifact exists** inside the installation, by name.
- **Compare counts** against the published archive.
- **Reproduce with extensions removed**, so the extension is not blamed for a truncated base install.

Two further cautions. An archive that was copied to a machine may be **byte-identical to the stock release** -
compare checksums and entry counts before assuming customisations were included in it. And an upgrade may wipe
an installation, so any step that installs into a tool's own tree should be re-runnable as a script.

## Network and service interruption

Transient. The useful habit is in the brief rather than in the recovery:

- **Tell lanes to stop and report on a hard infrastructure failure** rather than retrying indefinitely.
- **Relaunch with "continue, do not restart"** so the surviving report is used rather than repeated.
- **Expect partial output in the report**, which is what incremental reporting buys.

## A surviving stub is the cheapest resume point

If a unit was cancelled after writing only an opening section, that section holds both the brief and the state of
thinking. **Look for a stub before re-briefing from scratch**, and prefer resuming from it.

## Contained failure

The project should fail in units, not as a whole:

- A lane that cannot proceed stops and reports; it does not improvise around a missing input.
- A lane that changes behaviour and breaks a check reports it rather than reverting to make the check pass.
- A lane that finds work outside its ownership names the file rather than editing it.

The general rule: **it is acceptable for a unit to fail, and unacceptable for a unit to hide that it failed.**
A blocked lane that says why is a useful lane.

## Recovery checklist

1. **Which mode is it?** Turn count and error text distinguish them.
2. **Is there a stub or report?** Resume from it if so.
3. **Was the brief stale?** If more than a few hours old, re-read its stated facts.
4. **Was another writer active?** Check the in-progress records, not the filesystem.
5. **Relaunch with "continue, do not restart"** if partial work exists.
6. **Record the failure in the lane's report**, so the next reader knows what was lost and what was not.
