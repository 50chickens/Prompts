# Orchestrating a long project across many agents

This folder describes how to run a multi-day project as a set of independent agent units coordinated by one
orchestrator. It is written to be reusable: everything here is generic, and where a concrete thing is needed it
is called `project1`, `product1`, `component1`, `technology1`, `tool1`, `resource1`, `document1`, `lane1`,
`task1` or `agent1`.

## The one-paragraph model

A single orchestrator owns the plan, the documents and the quality gate. Work is split into **lanes**, each a
self-contained unit with an explicit file ownership list, a written brief, and an obligation to write findings
as it goes. Lanes never run the gate and never write outside their files. The orchestrator writes the briefs,
reviews what comes back, verifies claims against primary sources, and keeps the shared documents current. The
point of the structure is not parallelism for its own sake: it is that a multi-day task is too large for one
context window, and the only way to survive that is to make each unit's output durable, reviewable and
resumable.

## What the structure buys

- **Resumability.** A unit that dies leaves a report on disk. The next unit reads it instead of redoing it.
- **Reviewability.** Every claim arrives with a citation, a measurement or a file, so it can be checked.
- **Contention-free concurrency.** Ownership lists and a serialised build lane mean several units really can
  run at once.
- **Honest state.** Documents record what was measured, by whom, and what is still unknown, so a stale claim is
  visible rather than silent.

## Files

| File | What it covers |
|------|----------------|
| [lanes.md](lanes.md) | The lane model, ownership, and how to split work so units do not collide |
| [queue.md](queue.md) | The task folder lifecycle and how work is selected and retired |
| [briefs.md](briefs.md) | Writing a brief, and the standing rules every brief carries |
| [contention.md](contention.md) | Locks, shared output, and the failure modes of concurrent builds |
| [verification.md](verification.md) | Adversarial validation, trust but verify, and what a defect looks like |
| [reporting.md](reporting.md) | Writing findings incrementally, and reporting theories as well as conclusions |
| [models.md](models.md) | Choosing a model per unit, and why a forced model is sometimes required |
| [failures.md](failures.md) | Service failures, stalls, rate limits, and how to resume cheaply |
| [measurement.md](measurement.md) | The economics of a unit: what a run costs and what it buys |
| [gate.md](gate.md) | The quality gate, and why exactly one party runs it |
| [documents.md](documents.md) | Which documents to keep, who owns each, how they go stale, and which decisions are the human's |
| [templates/task-brief.md](templates/task-brief.md) | A blank brief to copy |
| [samples/](samples/) | Small worked examples: a lock helper, a queue status script, a report skeleton |

## The five rules that matter most

1. **One writer per file.** Every lane carries an explicit ownership list, and a lane that needs a file outside
   it stops and says so rather than editing it.
2. **One writer to shared build output.** Builds are serialised through a lock, or every unit gets a private
   output directory. The failure mode is subtle and expensive.
3. **The gate belongs to the orchestrator.** Lanes run scoped checks; the orchestrator runs the full gate after
   a handover, because a lane measuring itself is not a check.
4. **Findings are written while they are found.** A theory written early survives a termination; a conclusion
   never written does not.
5. **Never adjust an expected value to make a change pass.** A pinned expectation is a record of what was
   measured. If a change moves it, the change is wrong until shown otherwise.

## How to start

1. Read this file and [briefs.md](briefs.md).
2. Establish the ownership map before writing any brief, or the first two lanes will collide.
3. Write one brief, launch one lane, read its report, and only then write the next. The first pass calibrates
   the brief template for the project.
4. Keep the queue non-empty but shallow. Between three and six active lanes is usually the useful band.
5. Record every standing correction in the brief template rather than repeating it in prose each time.

## The habits that turn out to matter most

Each of these is expanded in the file it belongs to, and each came from a failure rather than from theory.

- **The report file exists within the first few tool calls**, not after the first finding. Units are cancelled
  mid-run, and a stub is the difference between losing minutes and losing everything.
- **Intervene early when a unit goes quiet.** The dominant failure is silence rather than slowness, so a report
  that has not changed in about fifteen minutes is a signal to send a short steering message.
- **Use the cheap instrument to find the next question, and the expensive one only to confirm a milestone.**
  This is usually a factor of a hundred on the right task.
- **A fixture is not evidence.** A check authored to match the implementation says nothing about which side is
  wrong when the two disagree, and reverting a change to make a check pass reverses the roles of evidence and
  conclusion.
- **Verify the specific numbers a decision rests on.** The headline is usually right and the supporting
  statements are where a claim breaks.
- **A clear negative is a good result**, and a unit will chase a positive unless the brief says so.
