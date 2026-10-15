# Reporting

A lane's report is the only durable thing it produces. Code can be re-read, but the reasoning that led to it
cannot be recovered from the code, and it is the reasoning the next unit needs.

## Write as you go, not at the end

This is the single most important reporting rule, and it has a measured payoff: several units in a long project
have been terminated mid-investigation and the ones with incremental reports cost nothing to resume, while the
ones without cost their entire budget.

Practical form:

- **Create the report file within the first few tool calls, as a stub.** Not after the first finding - first.
  A unit whose report file does not exist yet is a unit at risk, and this single rule has repeatedly turned a
  total loss into minutes lost. Units are cancelled mid-run by the environment, sometimes in batches.
- **Update it after every measurement**, not after every milestone.
- **Append a section the moment a fact is established.** Not a summary at the end.
- **Write theories as theories.** Maturity is expensive to wait for and worthless if the unit dies first.
- **Mark clearly which statements are established and which are suspected.** A theory nobody can distinguish
  from a finding is worse than no theory.
- **Record what you checked and found nothing.** A bounded negative result stops the next unit repeating it.
- **Date or mark the state of each claim**, because a report's facts go stale exactly as a document's do.

## The report skeleton

```markdown
# <lane name>

## State
<one line: what this lane has established so far, updated in place>

## Established
- <fact>. <how it was established>. <source>.

## Theories
- <theory>. <what would confirm or refute it>.

## Measurements
| subject | before | after | unit |
|---------|--------|-------|------|

## Could not determine
- <question>. <why it is unresolved>.

## Negative results
- <what was looked for>. <where>. <what was found instead>.
```

## What belongs in a report

- **Numbers with units.** "Executed 88 instructions" beats "ran a little further".
- **The command or method used**, so the measurement is reproducible.
- **The primary source for every claim that rests on a document**, cited precisely enough to be found.
- **The names of files and symbols touched**, so a reviewer knows where to look.
- **Before and after values**, for any change, including for the things that were supposed to stay the same.
- **A named new state** wherever a change moves a boundary - the new stop, the new count, the new address. A
  boundary described as "moved" cannot be pinned by whoever follows.

## What does not belong

- A restatement of the brief.
- Prose that describes activity rather than outcome.
- Confidence without a basis. If you are unsure, say what would settle it.
- A conclusion whose supporting measurement was not taken. Say it as a suspicion instead.
- Anything you cannot source.

## Reporting a refuted prediction

If the brief stated an expectation and the measurement contradicts it, **report the refutation prominently**.
This is a good outcome and should be written as one:

```markdown
## Prediction refuted

The brief expected <X>. Measured <Y>, at <where>, with <how>. So the expected value was wrong twice over:
<the two ways>. What this changes: <the next question>.
```

A lane that quietly works around a wrong prediction has wasted the correction, and the next brief will repeat
the error.

## Reporting a disagreement with the brief

Same treatment. State what the brief said, what is true, and the evidence. Do not silently do something else.

## Reporting a defect you caused

Also the same treatment, and it should be routine rather than embarrassing:

- **Say what you changed, what it broke, and how you found out.**
- **Say what you did about it** - reverted, fixed, or left for the owner of the affected file.
- **Correct your own earlier claims explicitly** rather than editing them quietly. A report that says "an
  earlier section of this report said nothing had moved; that was wrong because the filter excluded the suite
  that moved" is far more useful than one that is silently consistent.

## Distinguishing your breakage from someone else's

When something in the shared tree is broken, do not adopt it and do not hide it:

- **If it is yours**, say so and fix it.
- **If it is not yours**, say so with the evidence - a reproduction, a timestamp, a file that is not in your
  ownership list - and name the likely owner.
- **Never absorb a wrong attribution.** A workstream that quietly takes the blame for another's breakage hides
  a real defect and misleads the orchestrator about what is stable.

## One findings file, one owner

**Every unit has exactly one report file, and exactly one owner.** Disagreement with a document is recorded as a
new section that names the file disagreed with - never by editing it. This keeps a load-bearing document
load-bearing: a passer-by that "fixes" one while passing through is how a document gets corrupted, and it is
also how two units lose each other's changes.

Practically: the report is where you disagree, and the orchestrator is who applies the change.

## Costs, reported honestly

A report should say what the work cost, because that is what makes the next estimate possible:

```text
wall clock:  <duration per distinct kind of run>
long runs:   <how many, and what each was for>
iterations:  <cheap iterations vs expensive confirmations>
```

This is how an orchestrator learns which investigation method is worth funding. A method that confirms a
promise in seconds is worth far more than one that confirms it in half an hour, and only the lane sees the
difference.
