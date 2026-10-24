# Reporting

A lane's report is the only durable thing it produces: the code can be re-read, but the reasoning that led to it cannot be recovered.

Create the report file within the first few tool calls, before the first finding, and update it after every measurement rather than after every milestone. Append a section the moment a fact is established, mark a theory as a theory, record what you checked and found nothing, and date or mark the state of each claim.

## The skeleton

```markdown
# <lane name>

## State
<One line, updated in place, saying what this lane has established so far. A reader who stops here should know
whether the lane is done.>

## Established
- <Fact>. <How it was established>. <Source, cited precisely enough to be found, with the date if it names a
  moving quantity>.

## Theories
- <Theory, marked as a theory>. <What would confirm or refute it>.

## Measurements
| subject | before | after | unit |
|---------|--------|-------|------|
| <subject> | <value> | <value> | <unit> |

## Prediction refuted
<Only if this brief's stated expectation was contradicted: what was expected, what was measured, where, and
what it changes.>

## Defects found, including my own
- <What was claimed>. <What is true>. <How I know>. <What I did about it>.

## Could not determine
- <Question>. <Why it is unresolved, and what would settle it>.

## Negative results
- <What was looked for>. <Where>. <What was found instead>.

## Cost
wall clock:  <duration per distinct kind of run>
long runs:   <how many, and what each was for>
iterations:  <cheap iterations vs expensive confirmations>
```

`State` is the only part a reader is guaranteed to see, so it stays one line. `Measurements` is a table because prose hides the deltas.

## What belongs, and what does not

Numbers with units ("executed 88 instructions", not "ran a little further"); the command or method used; the primary source for every claim resting on a document; the files and symbols touched; before and after values for any change, including the things supposed to stay the same; and a named new state wherever a change moves a boundary.

Not: a restatement of the brief, prose describing activity rather than outcome, confidence without a basis, a conclusion whose supporting measurement was not taken, or anything you cannot source.

## Disagreement, refutation and your own defects

A refuted prediction is reported prominently, because a lane that quietly works around one has wasted the correction:

```markdown
## Prediction refuted

The brief expected <X>. Measured <Y>, at <where>, with <how>. So the expected value was wrong twice over:
<the two ways>. What this changes: <the next question>.
```

A disagreement with the brief gets the same treatment: what the brief said, what is true, and the evidence. A defect you caused likewise: what you changed, what it broke, how you found out, and what you did, correcting your own earlier claims explicitly rather than editing them quietly.

When something in the shared tree is broken, do not adopt it and do not hide it: say it is yours and fix it, or say it is not with a reproduction, a timestamp and a file outside your ownership list, and name the likely owner. Never absorb a wrong attribution.

Every unit has exactly one report file and one owner. Disagreement with a document is recorded as a new section naming the file disagreed with, never by editing it: the report is where you disagree, and the orchestrator applies the change.

## Judging a report

1. **Is the deliverable present at the path the brief named?** If not, the report describes intentions rather than work.
2. **Does every claim carry a source, and does the source say what the claim says?** Spot-check one load-bearing claim by opening the cited text: the headline is usually right and the supporting statement is where a claim breaks.
3. **Does the report state what it could not determine?** A report with no gaps is more likely to be overclaiming than complete.

Ask for a rate, not a verdict: "11 of 13 cases, field-exact, control accepted both orders" can be attacked and compared, while "looks correct" cannot. A unit reporting "124 units processed" has reported a number, not an advance: ask for the identity of the thing that stopped it, and read the number second. Check chance floors arithmetically, and check a report against itself, since a summary contradicting the table below it is a cheap defect to find.

## The validation batch

A periodic unit whose only job is to attack finished work. Its brief says that returning nothing is a result but a lazy one, and it has a budget for a few items rather than all of them, prioritising claims other work already depends on. It writes findings as it establishes them. Each batch leaves the number of claims checked, confirmed, contradicted and undetermined, plus each defect with the file, what was claimed, what is true, and the source used to decide.

| Class | How it is caught |
|-------|------------------|
| **Stale fact** - a value a later change moved | Compare against the tree, not memory |
| **Wrong source** - a citation that does not contain the claim | Open the cited document at the cited page |
| **Backwards claim** - a source said to say the opposite | Read the source, not a summary |
| **Test that cannot fail** - an assertion true for any input | Ask what change would break it |
| **Unmeasured pass** - an absent record scored as satisfied | Check what a missing input scores as |
| **Wrong attribution** - work attributed to the wrong file | Find the real location |
| **Missing sibling** - a class of fix applied to one site | Search for the pattern elsewhere |
| **Duplicate truth** - two copies of one fact that can drift | Check that a fact lives in one place |

## Trust but verify, then reconcile

What transfers from an external artefact is coverage; what must be earned locally is correctness, so measure agreement on cases whose correct answer is established independently and give it inputs that should be rejected to look for over-acceptance. Where it and the project disagree, establish the truth from the primary source, fix the wrong side including the project's own, and never average the two positions. If the fix lands in a file the lane does not own, the lane names the file.

## The fixture is not evidence

A change that breaks an existing expectation is not made right by reverting it: the expectation was authored to match the implementation, so it says nothing about which side is wrong. Establish which is right from an independent source, fix the wrong side, and when a change must alter many expectations prefer a semantic helper over edited literals.

## Measurement

Every investigation has a cheap iterator - a probe, a static walk, a decode over a region, a query - and an expensive confirmation - a full run, a long build, a whole suite. **The mistake is using the expensive instrument to find the next question**: the brief answers how many iterations this takes and which instrument each needs.

Before implementing a list of things, establish how many there are, whether it is ordered and by what, and whether it is still valid. Confirming a milestone is the one thing worth an expensive run: price it with the expected count, wall clock and memory, take it once, and record what it bought.

Cost is a design input: a per-operation log record that allocates and formats text, allocation per step, and boxing in a hot path can change cost by an order of magnitude. Prove a performance change preserved behaviour with an **output hash identical across builds**, because a passing suite cannot show it.

```text
per unit of work:  time, allocation, and the thing that dominates it
per full run:      wall clock, peak memory, and the count of units processed
per iteration:     the number of iterations a fix needs before it is confirmed
```

Every negative needs a positive control in the same run, because "nothing was found" is evidence only if the same instrument finds something where something is known to be. Count against the documentation and name any disagreement. Report the cost of the dominant loop, and never report a zero where a value was not observed. Count units rather than timing them, prefer the deterministic instrument, and report which instrument produced a number.

## Probes

Do not commit a diagnostic probe. A test whose body exists to print a value is deleted once it has printed, because a probe left in the suite fails every other lane's run and reports as somebody else's defect. When a probe's output is the evidence, quote it in the report and remove the probe in the same unit.
