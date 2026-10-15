# Measurement

A long project's units cost wall clock, compute and money. Only some of that buys information. This file is
about telling the two apart, because the difference is usually a factor of a hundred.

## The unit of progress

For any investigation there are usually two instruments:

- **A cheap iterator** - a probe, a static walk, a decode over a region, a query against a table. Seconds per
  iteration, no full run.
- **An expensive confirmation** - a full end-to-end run, a long build, a complete test sweep. Minutes to tens of
  minutes per iteration.

**The mistake is using the expensive instrument to discover the next question.** A cheap iterator should find
every remaining gap before an expensive run is spent confirming that a milestone was reached. A measured
example: one project spent fifteen minutes per run to learn about sixty units of progress, while the probe that
would have enumerated the whole remaining debt iterated in two seconds.

The discipline is a one-line question in the brief: **how many iterations will this take, and which instrument
does each one need?**

## Ordering: enumerate before implementing

Before implementing a list of things, establish:

- **How many there are.** A handful and a few hundred are different projects.
- **Whether the list is ordered and by what.** Occurrence count is usually the right order.
- **Whether the list is still valid**, because a list derived from a run goes stale the moment something lets
  the run go further.

An enumeration that reports "seventeen items" when the real answer is "three, plus data that a walk mistook for
code" is worth more than any amount of implementation. In one measured case a walk reported dozens of
outstanding refusals, and nearly all of them were data rather than code - a correction that removed an
open-ended amount of work.

## Confirming a milestone is the one thing worth an expensive run

Once the cheap instrument says the next boundary is within reach, a full run is the right purchase. But:

- **Price it first.** State the expected instruction count, wall clock and memory before taking it.
- **Take it once.** Iterating a full run per fix is the anti-pattern.
- **Say what it bought.** If the run confirmed the boundary, the cost was worth recording as a milestone cost
  rather than a per-iteration cost.

## Cost is a design input, not an afterthought

Instrumentation can dominate execution cost, and therefore decide what is affordable at all. Watch for:

- **A per-operation log record** that allocates, formats and stores text. Making the description lazy, or making
  it a value rather than a string, can change cost per operation by an order of magnitude.
- **Allocation per step**, which turns a long run into a memory problem rather than a time problem.
- **Boxing in a hot path**, which is invisible in the source and obvious in the profile.
- **A single record per unit of work pinned by tests as a design decision.** That is a legitimate decision, but
  it should be labelled so, because it is also the largest remaining optimisation.

A worked example of the shape: cost per operation fell from hundreds of bytes to tens, and from tens of
thousands of megabytes to low thousands, for a thirty per cent CPU saving, with no behaviour change. The proof
that nothing changed was an **output hash identical across builds** - which is the right way to demonstrate that
a performance change is behaviour-preserving, because a passing test suite cannot show it.

## What to measure, and keep

```text
per unit of work:  time, allocation, and the thing that dominates it
per full run:      wall clock, peak memory, and the count of units processed
per iteration:     the number of iterations a fix needs before it is confirmed
```

Keep the measurements in the report, not in the orchestrator's head. They are what makes the next estimate
possible, and they are the first thing lost when a session ends.

## Cheap habits that pay

- **Hash the output** to prove a performance change preserved behaviour.
- **Count the units** rather than timing them: "8.9 million units per second" is more portable than "it took a
  minute".
- **Prefer the deterministic instrument.** A measurement that reproduces exactly is worth more than a faster one
  that varies, because only the first can be compared across changes.
- **Measure the counterfactual once.** Knowing that an expensive path costs X is worth knowing even if that path
  is never taken, because it changes what you can afford to build.

## Rules for the measurements themselves

These are the ones most often skipped, and each has produced a wrong conclusion:

- **Every negative needs a positive control in the same run.** "Nothing was found" is only evidence if the same
  instrument finds something where something is known to be.
- **Count against the documentation and name the disagreement.** If a count and a specification differ, the
  count is not automatically right; state both and say which you used.
- **Report the cost of the dominant loop.** A scan that does not say what its hot loop cost cannot be judged, and
  the next unit will re-run it.
- **Do not report a zero where a value was not observed.** "Not observed" and "zero" are different facts and a
  reader cannot tell them apart afterwards.

## Choosing the weight of the instrument

A scripting-language loop and a compiled loop are not the same tool, and the difference is large enough to
change what is affordable:

- **A scripting-language indexed loop can be one to two hundred times slower than the same loop compiled.** On a
  shared machine that is holding a core hostage rather than merely being slow.
- **Find the break-even and record it.** A measured crossover point - the iteration count above which compiling
  the loop wins - turns a judgement call into a rule.
- **Compile the hot loop, keep the orchestration in the scripting language.** The scripting language is for
  sequencing, file handling and reporting; the arithmetic belongs in the compiled form.
- **Report which instrument a measurement used.** A number produced by the slow path is still a number, but the
  reader needs to know what it cost.
