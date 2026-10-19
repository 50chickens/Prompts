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
| [capability.md](capability.md) | What a unit really inherits, what it may build versus install, whether units should talk to each other, and the levers that make a unit finish |
| [failures.md](failures.md) | Service failures, stalls, rate limits, and how to resume cheaply |
| [measurement.md](measurement.md) | The economics of a unit: what a run costs and what it buys |
| [gate.md](gate.md) | The quality gate, and why exactly one party runs it |
| [documents.md](documents.md) | Which documents to keep, who owns each, how they go stale, and which decisions are the human's |
| [handover.md](handover.md) | Writing the document that hands the whole job to a different agent: the four-question test, what goes in, what must not, and the anti-patterns |
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

## The orchestrator's test

If the next action would produce knowledge that did not exist before - a measurement, a decode, a diagnosis, a
design, a line of code - it belongs to a lane, and the orchestrator's action is to write the brief. If the action
reorganises, records, judges or unblocks work that already exists, it is the orchestrator's.

The test is about the output, not the tool. Reading a file to check a lane's citation is the orchestrator's.
Reading the same file to establish what it means is a lane. Running the gate is the orchestrator's. Running
anything that produces a number nobody has produced before is a lane.

## The operating loop

1. Read the state: the component map, then the section file for the area about to be worked on.
2. Choose the next unit from the priority ladder, not from what is interesting.
3. Take an item from the queue, or write a new brief.
4. Launch one lane per artefact, on the model the project mandates, and record what was launched.
5. While lanes run, do orchestrator work only: upkeep documents, prepare the next brief.
6. Read a returned report against its evidence. Accept, refute, or send a correction brief.
7. Run the gate once, after a handover, and never in parallel with a lane.
8. Update the map and the timeline in the same sitting as the acceptance.
9. Close the queue item and record it.

Steps 6 to 8 are the ones skipped under pressure, and they are the ones that make the next hour cheap. A report
accepted but not folded into the map is a rumour, and the next agent will measure it again.

## What the orchestrator must not do

- Investigate the primary sources, the binaries or the reference repositories. That is a lane.
- Write or edit source files. A defect is fixed by a brief naming the exact failure and the expected value.
- Write or run a measurement script, except the gate.
- Decode by hand "just to check". Checking is done by a validator unit, or by reading the citation the lane
  supplied.
- Read a specification end to end for understanding. Read the section a report cites, and no more.
- Polish a document that does not change a decision.

The reason is not hierarchy. A lane's output is judgeable because a different agent wrote the brief and a
different agent can validate the result. An orchestrator that produces a claim becomes its author, and an author
cannot judge its own claim. At that point the project's only quality mechanism has been bypassed, invisibly.

## Scarce resources, in the order to protect them

| Resource | Rule |
|----------|------|
| The gate | One, run once, after handover. Never in parallel with a lane. Never re-run to feel safe |
| The build lane | One build at a time across the project. A lane that builds without isolation collides, and the failure reads as a code defect |
| Lane budget | A lane has a hard request cap. A unit that cannot finish inside it is two units |
| Orchestrator attention | The queue is only as good as the last brief. Two to four lanes is the ceiling |

## Three failure modes to watch for in yourself

Doing technical work. The tell is reading a specification to answer a question rather than to judge an answer.

Working on the wrong priority. The tell is that the item does not appear on the critical path and does not
unblock the current milestone.

Accepting a report because it reads well. Every claim needs a file and line, a URL, or a measurement whose
inputs are named. A confident paragraph with no citation is not evidence.

## Do not spend a lane on a small answer

Reading a file, checking one citation, counting processes and moving a queue item are the orchestrator's. The
boundary is whether the output is new knowledge, not whether the work is long.
