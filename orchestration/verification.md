# Verification

A lane reporting success is not evidence of success. Verification is a separate stage with a separate unit whose
job is to break the claim, and it exists because it keeps finding real defects.

## The validation batch

A periodic unit whose only job is to attack finished work. It reads the claims, reads the code and the primary
sources, and reports what does not hold up.

What makes a batch useful:

- **It is adversarial by construction.** The brief says it is expected to find defects, and that returning
  nothing is a result but a lazy one.
- **It has a budget for a few items, not for all of them.** A batch that tries to check everything checks
  nothing properly. Prioritise the claims that other work already depends on.
- **It writes findings as it establishes them**, so a terminated batch still returns value.
- **It reports contradictions, not just errors.** A source that disagrees with a document is a finding even when
  neither is obviously wrong.

## What a defect looks like

A useful taxonomy, because "the report was wrong" is not actionable:

| Class | Example | How it is caught |
|-------|---------|------------------|
| **Stale fact** | A document states a value that a later change moved | Compare against the tree, not against memory |
| **Wrong source** | A citation names a document that does not contain the claim | Open the cited document at the cited page |
| **Backwards claim** | A source is said to say the opposite of what it says | Read the source, not a summary of it |
| **Test that cannot fail** | An assertion that is true for any input | Ask what change would break it |
| **Unmeasured pass** | A criterion scoring an absent record as satisfied | Check what a missing input scores as |
| **Wrong attribution** | Work attributed to the wrong file or function | Find the real location |
| **Stale count** | A total that no longer matches reality | Recount |
| **Missing sibling** | A class of fix applied to one site, leaving another | Search for the same pattern elsewhere |
| **Duplicate truth** | Two copies of the same fact that can drift | Check whether a fact lives in one place |

The last three are the ones a reviewer most often has to find and the least often looks for. Search for the same
pattern elsewhere in the tree, and count how many places a fact lives.

## Where a report breaks: the headline survives, the support does not

Measured across one project: every load-bearing claim that turned out to be wrong had **a right headline and a
wrong supporting statement**. The pattern is consistent enough to shape the review:

- A count in the summary was wrong while the artefact was found and described correctly.
- A claim that a region decodes cleanly was wrong in its scope, and contradicted the word list printed beside
  it in the same report.
- A proposed cause was measured false while the symptom it explained was real.
- An "each value matches exactly one view" was false for half the values, and its stated chance floor was
  understated by a factor of about 2.6.

So:

- **Verify the specific numbers a decision rests on**, not the shape of the claim.
- **Check the report against itself.** A summary that contradicts a table printed below it is a defect, and it
  is cheap to find.
- **Check chance floors arithmetically.** An overstated likelihood is how a coincidence gets promoted to a
  finding.
- **A review that confirms its target is still useful.** The best of these reviews did not break its target and
  still corrected how the claim could be stated, which is a real improvement to the record.

## Trust but verify

When a valuable artifact arrives from outside the project - a reference implementation, a specification, a
generated table - the instinct is to adopt it wholesale. The right move is to split it:

- **What transfers is coverage.** Existing work usually encodes a great deal of knowledge that would cost a
  great deal to rediscover.
- **What must be earned locally is correctness.** Any artifact can be internally inconsistent, can accept inputs
  it should reject, or can encode a misreading of the source it came from.

So adopt the coverage and verify the correctness. Concretely:

1. **Measure agreement on cases you already know.** Feed it inputs whose correct answer is established
   independently and count the matches. Score it before trusting it.
2. **Add a control.** Confirm that the artifact reproduces the known answers only under the correct conditions.
   An implementation that reproduces them under any conditions is not evidence that it works.
3. **Look for over-acceptance specifically.** Give it inputs that should be rejected and see whether it accepts
   them.
4. **Say what it cannot do** in the same report that says what it can.

An artifact that agrees on the cases you know is credible. One that disagrees is not, and either answer changes
the plan.

## Reconcile, then apply

Where the artifact and the project disagree:

1. **Establish the truth from the primary source.** Not from either implementation.
2. **State which side was wrong and how you know.**
3. **Fix the wrong side - including the project's own side.**
4. **Never average the two positions, and never keep both.**

If the fix lands in a file the lane does not own, the lane names the file rather than editing it.

## The trap: reverting to make a test pass

The most expensive failure in this area is a change that breaks an existing expectation, and a lane that reverts
the change so the expectation passes again. That reverses the roles of evidence and conclusion.

The rule that prevents it: **the fixture is not evidence.** An expectation authored to match the current
behaviour says nothing about whether that behaviour is right. When a change and an expectation disagree:

- establish which is correct from an independent source;
- if the change was correct, **fix the expectation** and never adjust it to match a wrong encoder or a wrong
  decode;
- if the change was wrong, revert it and say why.

A related discipline: when a change must alter many expectations, prefer a **semantic helper** over edited
literals, so the intent is visible and the numbers stay unchanged. A test that had nine hand-encoded words
should, after such a change, have nine unchanged assertions built through a named constructor.

## Coverage of the gate

The gate is the orchestrator's, and it runs after a handover. What it should cover:

- A build with warnings treated as noise only if they are genuinely noise.
- Every test suite, and the count of suites validated against the solution.
- A long-running end-to-end check that exercises the assembled system rather than a unit.
- The exit criterion, scored mechanically from a produced evidence file.

An end-to-end lane that is skipped because it is slow is how a system quietly stops working as a whole while
every unit stays green.

## Recording the outcome

Each validation batch should leave, at minimum:

- The number of claims checked, confirmed, contradicted and left undetermined.
- The defects found, with file, line, what was claimed, what is true, and the source used to decide.
- Anything the batch could not settle, recorded as unresolved rather than guessed.

The count of **undetermined** items is the useful measure of how much of the project rests on unverified
assertion. It should go down over time, and it will not go down by itself.

## Judging a report: three checks, in order

1. **Is the deliverable present at the path the brief named?** If not, the report describes intentions rather
   than work.
2. **Does every claim carry a source, and does the source say what the claim says?** Spot-check one
   load-bearing claim by opening the cited text. The headline is usually right; the supporting statement is
   where a claim breaks.
3. **Does the report state what it could not determine?** A report with no gaps is more likely to be
   overclaiming than complete.

Only then run the gate. A red gate in files the brief did not own is a collision, not a defect in the unit.

## Ask for a rate, not a verdict

A review that reports "11 of 13 cases, field-exact, control accepted both orders" can be attacked and compared.
"Looks correct" cannot. Require the measured rate, the sample, and the control. A verdict without a rate is an
opinion with a confident tone.

## A moved number is not progress

A unit that reports "124 units processed" has reported a number, not an advance. Ask for the identity of the
thing that stopped it - the form, the address, the input class - and read the number second. A unit that removes
a failure class is progress. A unit that moves a boundary without changing the class is noise.
