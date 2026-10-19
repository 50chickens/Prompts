# The queue

The queue is the project's work-in-progress state, kept on disk so it survives a session, a crash or a change
of orchestrator.

## Folder layout

```text
tasks/
  queued/           briefs written and not yet started
  in_progress/      one brief per running lane, with its lane id recorded
  to_be_validated/  finished work whose claims have not been checked
  completed/        work that has been reviewed and accepted
  ignored/          work deliberately not done, with the reason
```

The `ignored` folder matters more than it looks. A queue that only grows teaches the next reader nothing about
what was considered and rejected, and the same idea will be proposed again.

## The lifecycle

```text
idea -> queued -> in_progress -> to_be_validated -> completed
                       |                |
                       +-> ignored <----+   (deliberately not done)
```

Rules that make the lifecycle real rather than ceremonial:

- **A brief is written before a lane is launched**, and the file is the lane's authoritative description. The
  launch message points at it rather than restating it, so there is one description and not two.
- **A completed lane moves its brief forward itself**, or the orchestrator moves it at handover. Moving it is
  cheap; leaving it in `queued/` while it runs is how a queue becomes fiction.
- **Validation is a separate stage, not a formality.** Work lands in `to_be_validated` and stays there until
  something adversarial has looked at it. See [verification.md](verification.md).
- **An item is retired with a reason.** "Not worth doing because X" is a complete answer.
- **Taking an item is one atomic operation.** A rename or a move into the in-progress state must be atomic, so
  two lanes cannot take the same item. Never write to an item that is claimed, and never release a claim on a
  lane's behalf while the lane is still running.
- **Never edit a brief in flight.** If it is wrong, let the lane finish or stop it, then handle the report. A
  brief edited underneath a running lane produces work that matches neither version.
- **Release a stale claim only after confirming the lane is gone.** A claim with no running agent behind it
  blocks the item forever; a claim released under a live lane collides with it.
- **The validator is a different agent from the author.** An agent validating its own work is not a validation.
- **Move a finished item in the same sitting.** A finished item left in the queue reads as available work and
  gets run twice.

## Selecting the next item

In order:

1. **Unblock something already running.** A lane waiting on a decision or a file is the cheapest thing to fix.
2. **Take the highest-value item whose dependencies are met**, not the oldest. A queue is not a queue.
3. **Prefer the item that produces evidence for a queued item.** This is the same habit as filling an idle
   lane with read-only work, applied to the backlog.
4. **Only then start a fresh item.**

## Keeping the queue shallow

A deep queue is a liability: it is a list of decisions made before the information that would change them
arrived. Between three and six active items is usually right. Beyond that, briefs go stale faster than they are
consumed, and a lane launched on a stale brief spends its first turns rediscovering why the brief no longer
applies.

Two habits keep it honest:

- **Re-read a queued brief before launching it.** If it was written more than a few hours ago, check its stated
  facts against the tree. Numbers in briefs go stale exactly as numbers in documents do.
- **Mark items not worth taking.** A brief explicitly annotated as "not worth taking until X settles" is doing
  its job. One silently queued is a trap.

## Dependencies

Record dependencies explicitly rather than inferring them from order in a list. A short table is enough:

```text
task1 -> task2      task2 needs task1's artifact
task3 -> task4      task4 needs a decision task3 will make
task5               independent
```

Anything with no unmet prerequisite is startable, regardless of position. When you are unsure whether two items
conflict, the question is not "do they overlap in subject" but "do they write the same file".

## Queue status at a glance

A script that prints the counts and the blocked items is worth more than a document listing them, because it
cannot go stale. See [samples/queue-status.ps1](samples/queue-status.ps1).

What the report should show:

```text
queued           12   (2 annotated as not yet worth taking)
in_progress       3
to_be_validated  19   <- the number to watch
completed        47
ignored           6
```

**A growing `to_be_validated` count is the signal that the project is accumulating unverified claims.** It is
the most useful single number in the queue and the one most likely to be ignored.
