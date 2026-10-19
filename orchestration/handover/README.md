# Handover

You are taking over management of this project. This document is about **how to run the work**: what you own,
which document answers which question, how a unit is written, launched and reviewed, and what units reliably get
wrong.

It deliberately does **not** carry the project's technical content or its current state. Those live in the
project's own handover, specifications and status map, which take precedence over this document wherever the two
differ.

The orchestration pattern you are working inside - lanes, briefs, a queue, a single gate, adversarial validation
- is documented in its own set of documents. This handover assumes you have it and builds on it rather than
repeating it. Names below are shapes; the project handover supplies the concrete paths.

## 1. Where each kind of information lives

Read in roughly this order. Every path is relative to the project root.

| Question | Document |
|----------|----------|
| What does "done" mean, and what is explicitly not acceptable? | the goals document |
| Which capabilities are reachable, in what order? | the milestone and roadmap documents |
| What are the parts, what does each enable, and what would shortcut building it? | the deliverables index and one file per part |
| What is built, what depends on what, and what is its state? | the component map, one file per section |
| When did each piece start and finish, and where does its source live? | the timeline |
| Which choices were deliberate, what do they cost, and what would overturn them? | the decisions document |
| How does a subsystem actually work, with its measurements? | the specification for that subsystem |
| Which primary sources are held, and what was extracted from each? | the source documents index |
| What is the reasoning and evidence behind one unit's conclusion? | that unit's report |
| Which rules govern every unit? | the memories folder |
| How is work queued, and what state is each item in? | the task queue |
| What does a brief look like? | the project's brief template |
| How does the operating protocol work? | the project's coordination document |
| What has been measured and is not to be re-derived? | the refuted-claims file |

**Only the component map records state.** If you find yourself wanting to write "currently" or "so far" into
any other document, it belongs in the map or in a timeline. That separation is what keeps the definition
documents readable regardless of progress and stops the state from going stale inside a document nobody thinks
to refresh.

The memories folder is small and each file is short. They are the rules that a fresh unit would otherwise
break:

- assumptions - what a fresh unit may take as true without spending calls verifying it.
- refuted claims - settled negatives. Cite the entry and move on; do not re-derive one.
- measurement rules - how a measurement has to be taken to count.
- build isolation - the shared-output rules, including the private-output pattern.
- command errors and hints - the command-line specifics that cost a diagnostic cycle to find.
- document map and workflow - orientation, and the process that works.

## 2. Your job

You are not a coordinator only. You own:

- **The plan** - the queue, what is in flight, what is next, and what is deliberately not being done.
- **The documents** - the ones in the table above, and the habit of updating them once there is material
  progress rather than saving it up. Do not ask permission to refresh a document you own; that spends a turn
  confirming a preference that was never in question.
- **The briefs** - written before a lane launches, and the place where corrections accumulate.
- **The gate** - you are the only party that runs it, and you run it after a handover.
- **Policy** - any decision that a lane must not make silently. Those go in the decisions document with
  their cost and with what would overturn them.

What you delegate is everything else. A unit that owns a decision, a build or an artifact you have to sign off
is yours to brief and theirs to execute.

## 3. The operating loop

1. **Write a brief** from the project's brief template, and put it in the queue. The brief,
   not the launch message, is the unit's authoritative description - the message points at it.
2. **Launch one lane per brief**, naming the files it owns and the files it does not.
3. **Read the report as it is written**, not only when the lane finishes. If it has not changed in about fifteen
   minutes, send a short steering message: what to write down, and the next concrete step. Units in this project
   are slow to record rather than slow to work, and intervening early has recovered stalled units within minutes
   every time it was tried.
4. **Verify the claims.** Reports are claims, not facts. Verify the specific numbers a decision rests on - the
   headline is usually right and the supporting statements are where it breaks. For anything load-bearing, run a
   second read-only unit whose job is to attack it.
5. **Run the gate** once the tree is quiet. Compare counts, not just statuses.
6. **Fold the durable parts into the documents** - a measurement into the specification, a decision into
   `decisions.md`, a state change into the component map, a start or finish into the timeline.
7. **Retire the item** into the completed state, re-queue it with the new question, or move it to
   the ignored state with the reason.

Two habits inside that loop are worth stating separately because they are the ones that get skipped:

- **Never let a read-only slot sit idle while a builder is queued.** If the bottleneck is the build lane - and
  it usually is - convert a queued implementation unit into a read-only unit that produces the evidence that
  implementation will need. That has paid for itself repeatedly here.
- **Keep exactly one builder in flight**, and fill the other slots with units that cannot write build output.

## 4. Standing constraints in this project

**One agent writes shared build output at a time.** Two units building the same solution fail each other in ways
that look like defects in the code rather than collisions between units. Serialise the build lane through a lock,
or give a unit its own absolute output directory. The full rules are in the memories folder.

**The gate belongs to you.** Units run a scoped check on their own change. They do not run the full gate and do
not run a solution-wide build. Where the project splits the gate into stages, each stage has its own lock and the
orchestrator runs them in a fixed order after handover.

**Language rules.** PowerShell for orchestration, a compiled statically-typed language for calculation. Do not
branch to another language because it is natural for the problem. The one exception is when the artifact is
hosted inside a specific tool, in which case write it in that tool's own language.

**A brief names one specification file, not a folder.** Pointing a unit at the whole specification folder spends
its context on subsystems that cannot answer its question.

**Cite settled negatives rather than re-deriving them.** `refuted-claims.md` exists so a unit can read an entry
and move on.

**Do not let a claim outrun its evidence.** Where behaviour cannot be established, a stated limitation is the
acceptable answer and a fabricated value is not. This standard should never be traded for a tidier result.

## 5. What units reliably get wrong here

Seven classes, each found repeatedly. Expect them, and write the guards into the brief rather than relying on
the lane to avoid them.

**A fact that was true when written and is false now.** The single most common defect in this project, and it
appears in documents, in briefs and in reports. Its shapes: a number that moved, a renamed symbol, a citation
pointing at the wrong location, an attribution to the wrong function, a table row from a different edition read
as a statement about this one, a headline count contradicting the table beneath it, and a claim that reverses
its source. Any fact that names a moving quantity should carry when it was measured.

**A rule written for one case and applied to the whole class.** This has been wrong repeatedly, each time
leaving most of a stage unimplemented behind one exception. When a lane reports "stage X is not implemented",
ask which sub-case is genuinely unsupportable and which are merely unclassified.

**A fix applied to one site while a sibling keeps the old behaviour.** When a class of defect is fixed, search
for the same pattern elsewhere before declaring it closed, and require the lane to name the sibling words it
checked. Two real defects have been caught this way, one of them inside the fix that introduced it.

**A check that cannot fail.** Ask, of every assertion a lane adds or touches, what change would break it. A
relational assertion cannot show a reason change at all, which is exactly what a test of a stopping condition
needs to see.

**A change that breaks an expectation, and a lane that reverts the change to make the expectation pass.** This
is the most expensive failure in this project because it reverses the roles of evidence and conclusion. **The
fixture is not evidence** - it was authored to match the implementation, so it says nothing about which side is
wrong. Settle the question from the primary source, then fix whichever side was wrong.

**A filter that excludes the tests that matter.** A lane that reported "nothing measured moved" had excluded the
one suite that moved. Check what a filter selects before trusting its silence.

**A measurement reported as a fact without its instrument.** "The run stops at X" is worth much less than "the
run stops at X, measured by this command, costing this much". Ask for the method, and prefer the lane that says
what its evidence cost.

## 6. First actions

1. Read the memories folder and the goals document. Do not start work before this; the refuted claims in
   particular will otherwise cost a unit each to rediscover.
2. Read the brief template and the last few lane reports to see how the recent units were written.
3. Check the queue. A large to-be-validated count is the signal that unverified claims are accumulating -
   schedule an adversarial batch rather than adding more.
4. Look for a surviving stub or report before re-briefing anything. A stub written before a unit died is the
   cheapest possible resume point, because it holds both the brief and the state of thinking.
5. Run the gate once, on the current tree, so you know what "green" means before you change anything.
6. Confirm which documents are yours to refresh, and refresh the ones that progress has already dated rather
   than waiting to be asked.
