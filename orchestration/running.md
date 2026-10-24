# Running the work

## The gate

The gate is the project's whole-system check, and exactly one party runs it: the orchestrator. A lane measuring its own change is not a check, several lanes running the gate is a contention problem, and its answer is only meaningful for a tree nobody is writing. So **lanes run scoped checks on their own change; the orchestrator runs the gate after a handover.** It covers the build with its warning count reported rather than tolerated, every suite plus a count of projects validated against the solution, an end-to-end lane that exercises the assembled system, and the exit criterion scored mechanically from a produced artefact. Confirm no lane is mid-write before starting, compare counts with the previous run rather than statuses alone, attribute a failure before fixing it, and record the result where the next reader will look.

```text
gate <date>
  build            clean, <n> warnings, <n> projects validated
  suites           <n>/<n> passed across <n> suites
  end-to-end       <result>
  exit criterion   <pass>/<fail>/<unknown> of <total>
  verdict          green | red, with the attributions
```

Record the **unknown** count as well as the pass count. A green gate with a falling test count is a failure, so compare counts and not only statuses. A red gate after a handover is information rather than blame: the question is whether the failure predates the hand-in, and a failure in a file nobody touched is the previous writer's. Never pin a moving value to make the gate pass, and when behaviour improves rewrite a staged expectation to the stronger claim - "the unit fails with reason X" becomes "the unit completes with no failure at all".

## Validation is a lane, not the manager's work

Do not run tests, do not run the application to check that it works, and do not treat a command run by hand as evidence that a feature is delivered. Validation goes to a subagent with the tightest possible scope: one claim, one command or one test, one report.

Behaviour that must hold is proved by a test rather than by a transcript. Unit tests first; where a unit test cannot reach the behaviour, an integration test, and for an HTTP surface that means an in-process host such as Microsoft.AspNetCore.TestHost over a real HttpClient, never `curl` against a server somebody started by hand. Behaviour that genuinely cannot be exercised in-process, such as a process boundary or a container image, is still a validation lane: it runs a script that exits non-zero on failure and reports the exit code.

Builds and test runs that gate a commit follow the same rule: a lane runs them and reports, the manager reads the report. A red gate in files the brief did not own is a collision, not a defect in the unit.

## The queue

```text
tasks/
  queued/           briefs written and not yet started
  in_progress/      one brief per running lane, with its lane id recorded
  to_be_validated/  finished work whose claims have not been checked
  completed/        work that has been reviewed and accepted
  ignored/          work deliberately not done, with the reason
```

```text
idea -> queued -> in_progress -> to_be_validated -> completed
                       |                |
                       +-> ignored <----+   (deliberately not done)
```

The queue lives on disk so it survives a session, a crash or a change of orchestrator. The `ignored` folder records what was considered and rejected, so the same idea is not proposed again.

- **A finished item moves forward in the same sitting.** Left in `queued/` it reads as available work and gets run twice.
- **Validation is a separate stage.** Work stays in `to_be_validated` until something adversarial has looked at it, and the validator is a different agent from the author.
- **An item is retired with a reason.** "Not worth doing because X" is a complete answer.
- **Taking an item is one atomic operation**, so two lanes cannot take the same item. Never write to a claimed item, and never release a claim on a lane's behalf while it is running.
- **Release a stale claim only after confirming the lane is gone**, because a claim with no running agent blocks the item forever.
- **Never edit a brief in flight.** If it is wrong, let the lane finish or stop it, then handle the report.
- **Record dependencies explicitly** rather than inferring them from list order:

```text
task1 -> task2      task2 needs task1's artefact
task3 -> task4      task4 needs a decision task3 will make
task5               independent
```

Select next by unblocking something already running, since a lane waiting on a decision or a file is the cheapest thing to fix; then the highest-value item whose dependencies are met, not the oldest; then the item that produces evidence for a queued item; only then a fresh item.

Between three and six active items is usually right: beyond that, briefs go stale faster than they are consumed. Re-read a queued brief before launching it and check its stated facts against the tree if it is more than a few hours old, and annotate an item that is not worth taking yet.

Run [samples/queue-status.ps1](samples/queue-status.ps1) rather than maintaining a document of counts:

```text
queued           12   (2 annotated as not yet worth taking)
in_progress       3
to_be_validated  19   <- the number to watch
completed        47
ignored           6
```

**A growing `to_be_validated` count is the signal that the project is accumulating unverified claims.** `in_progress` above a handful usually means the build lane is oversubscribed; `queued` deep and old means briefs are going stale.

## Failures

**Balance and quota failures** kill a unit before any work is done: zero turns and a service error. Nothing needs recovering, so a fresh task is correct. A cluster of them in one window is an infrastructure signal: stop launching and wait.

**Stalls** end a turn after a sentence or two with nothing done. The lane is idle, not finished, and its state is intact, so wake it rather than re-briefing it:

```text
Your turn ended after a single line with no tool calls. Continue now and do the work rather than describing
it. Concretely: read <file1> and <file2>, then <first concrete step>. If something blocks you, say what and
stop, rather than ending silently.
```

**The dominant failure is silence rather than slowness.** Use the report file as a liveness signal: if it has not changed in about fifteen minutes, send a steering message naming a concrete next action and an obligation to write. A unit at three times its estimate with nothing durable is not coming back, so release the claim, keep the stub and relaunch as a continuation.

```text
Your report has not changed in <duration>. Write down what you have established, then <next concrete step>.
If something blocks you, say what and stop.
```

**An incomplete installation looks like a configuration fault**: the launcher starts normally and reports a missing class or module, which reads as a bad path, a broken extension or a wrong version. Verify the installation rather than the launcher's message, by opening every member of the archive and comparing entry counts against the published one.

**Network and service interruption is transient.** Tell lanes to stop and report on a hard infrastructure failure rather than retrying indefinitely, and expect partial output.

**A lane that leaves a process running leaves it on the host.** Take a process-count baseline before a batch and compare it after; if the count grew by the number of lanes run, identify by id and start time, not by name, and stop that process. A long-running command that exceeded its initial wait is not a leak: read its output rather than starting a second copy.

**Contained failure.** A lane that cannot proceed stops and reports rather than improvising around a missing input; a lane that breaks a check reports it rather than reverting to make the check pass; a lane that finds work outside its ownership names the file. A unit may fail, and may not hide that it failed.

### Recovery checklist

1. **Which mode is it?** Turn count and error text distinguish them; an environment outage reports nothing at all, where a blocked lane reports a blocker.
2. **Is there a stub or report?** Resume from it if so.
3. **Was the brief stale?** If more than a few hours old, re-read its stated facts.
4. **Was another writer active?** Check the in-progress records, not the filesystem.
5. **Relaunch with "continue, do not restart"** if partial work exists.
6. **Record the failure in the lane's report**, so the next reader knows what was lost.

Two failures on the same unit mean the brief is wrong, not the lane: rewrite it narrower, name the one file, supply the path the lane could not find, or split it. Three failures mean the unit is not ready: retire it with the reason, or write the preceding unit that supplies what the failing one kept needing. What never happens is the orchestrator taking the unit over.
