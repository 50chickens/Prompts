# Briefs

A brief is the unit of instruction, written as a file so that it survives the lane, can be compared with what was reported, and can be handed to a replacement unit unchanged. The launch message points at the brief and does not restate it.

## What every brief contains

1. **Model identifier** on the first line, spelled exactly as mandated, echoed as the first line of the report stub.
2. **Goal** - one paragraph, in terms of the outcome rather than the activity.
3. **Established facts, measured - do not re-derive.** What the lane would otherwise rediscover, with source and measured date.
4. **What to establish**, in priority order, with the deliverable named, saying so if the census matters more than the single fix.
5. **What to measure and report**, with exact quantities, units, and any new boundary named explicitly.
6. **Standards** - what counts as evidence, what must not regress, and the mistakes this project has already made here.
7. **Ownership** - the two lists, plus the rule about stopping rather than editing.
8. **Output** - the report path, and the instruction to append as you go.
9. **Constraints** - languages allowed, tools forbidden, where the primary sources live, and the cost expectation.
10. **Reuse** - the `TOOLS.md` entries the lane invokes, named by path, or a statement that none exist. A lane that needs a missing tool reports it rather than writing a private script.

## Pre-flight the brief

Every path the brief names exists in the form given, the report path's parent is writable, the model identifier is the mandated one spelled exactly, the toolkit named is reachable from the lane type being launched, and the corpus is bounded by a name, a count or an address range rather than by "everywhere". A brief with a dead path wastes a lane.

## Standing rules in every brief

- **You are one lane and you do not spawn lanes.**
- **The gate belongs to the orchestrator.** Run a scoped check on your own change only.
- **Create the report file as a stub within your first few tool calls**, and update it after every measurement.
- **Never adjust an expected value to make a change pass.** If your change moves a pinned value it is wrong until shown otherwise, and arguing the expectation was wrong requires the evidence.
- **A fixture is not evidence.** Settle a disagreement with the implementation from the primary source.
- **Name what you could not determine**; a guess presented as a finding is a defect the next unit inherits.
- **A clear negative is a good result**; do not chase a positive.
- **Report disagreements rather than reconciling them**: say which source is right and do not average them.
- **PowerShell for orchestration, a compiled statically typed language for calculation**, branching only when the artefact must be written in that tool's own language.
- **Do not enumerate whole trees, redirect output, or filter command output for display**; output volume is bounded by the question.
- **Stop and report rather than working around a missing input.**
- **A bare relative path in a brief is a shorthand**; resolve it before reporting anything as missing.
- **Cite the settled negatives rather than re-deriving them.**
- **Stop every shell session you start**, leave no background or detached process, and say so in the report if a command had to outlive a call.

## The three sentences in every brief

State these even when the template states them: do not run the gate; create the report stub within the first few tool calls and label theories as theories; stop at once if a toolkit the brief names is unreachable, rather than substituting a slower method.

## Context economy: one document, not a folder

A brief names the one specification file the unit needs, not the folder. For every input, ask whether the unit needs the whole thing or the part that answers its question.

## State the prohibitions explicitly

The most common failure is a unit wandering into a neighbouring subsystem, so list the prohibitions and prefer specific ones:

```text
Do not build.
Do not edit the shared configuration.
Do not re-derive the settled negatives.
Do not widen the table to make a check pass.
Do not touch <file1>; if the fix needs it, stop and say so.
```

## Sizing a brief

Specific about the deliverable and generous about the facts. Too vague and the lane picks its own scope; too prescriptive and it follows the brief, so the measurement that would have contradicted it never happens. State the outcome, the evidence standard and the constraint, then let the lane choose the method.

Name the artefact and its path; one question, one file list, one report; size to the request cap, since a unit that cannot finish inside it is two units; scope the corpus numerically, because "across the whole of..." is an instruction to enumerate; pre-answer the discoverable; state the stop condition, that a partial answer with named gaps is a complete delivery; batch the same shape and ask for the cost line, which sizes the next brief; and watch time to first artefact rather than elapsed time.

## Including the answer, and knowing when not to

A known fact goes in established facts with its source. A reasoned guess is marked as a guess with what would confirm it, and the brief says a lane disproving it is doing its job. With no idea, ask the question, not a route to the answer.

## Continuation briefs

A relaunch is a brief whose deliverable is "finish the work at this path". It names the report path, what is already established there, and the last completed step, and writes to the same path so the evidence accumulates in one place. It never restates the original brief, because restating invites a restart that pays for the first attempt's discoveries twice.

## Correcting the template

A correction to a lane's behaviour goes into the brief template, not into the next brief's prose.

```text
Brief rule N. <the correction, stated as an instruction>
Rationale: <one line, only if the rule looks arbitrary>
```

## Template

```markdown
# <Outcome, stated as a noun phrase>

Model: <identifier, exactly as mandated>

## Goal

<One paragraph. What will exist when this is done, and what it is for. State the outcome, not the activity.>

## Established facts, measured - do not re-derive

- <Fact>. <Source>. <Measured date>.
- <Fact that contradicts a plausible assumption>. <Why the assumption is wrong>.
- <Path the lane will need>. <The absolute form, since relative paths in a brief go stale>.

## What to establish

1. <Primary question and its deliverable.>
2. <The siblings that must not change, and the words to check them with.>
3. <What may legitimately be left undone, and the wording it should be left with.>

## What to measure and report

Per <subject>, report: <quantity>, <unit>; <quantity>, <unit>; and <the new stopping point, named explicitly>.

## Standards

The standing rules above, plus: a check that cannot fail is a defect, so say what change would break every test you add or touch; a disagreement is the valuable output, so say which source is right rather than averaging them; and a refuted prediction is reported prominently, as a good outcome.

## What must not regress

<The checks that own the current behaviour, and the rule: a change that moves a pinned value is a regression
until explained.>

## Ownership

You own: `<paths>`.

You do not own: `<paths>`. If a fix needs one of these, **stop and say so** rather than editing it.

## Output

Append to `<report path>` **as you establish each fact, not at the end**. Mark a theory as a theory.

## Constraints

- Write in <allowed languages> only. <Exception, where the artefact must be written in a specific tool's language.>
- <Primary sources and where they live, in absolute form.>
- <Tool or resource restrictions.>
- Do not run the project gate; the orchestrator owns it and runs it after handover.
- Stop every shell session you start; leave no background or detached process.

## Reuse

<The `TOOLS.md` entries this lane invokes, by path, or a statement that none exist.>

## Cost expectation

<How many iterations this needs, and which instrument each should use. Say whether a long confirmation run is
authorised and what would justify it.>
```
