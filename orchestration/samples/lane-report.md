# Lane report skeleton

Copy this file to `coordination/reports/<lane>/report.md` and **append to it as you go**, not at the end. A
report written at the end is lost whenever the lane is interrupted, and interrupted lanes are normal.

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

<Include this section only if this brief's stated expectation was contradicted. State what was expected, what
was measured, where, and what it changes. This is a good outcome - write it as one.>

## Defects found, including my own

- <What was claimed>. <What is true>. <How I know>. <What I did about it>.

## Could not determine

- <Question>. <Why it is unresolved, and what would settle it>.

## Negative results

- <What was looked for>. <Where>. <What was found instead>.

## Cost

```text
wall clock:  <duration per distinct kind of run>
long runs:   <how many, and what each was for>
iterations:  <cheap iterations vs expensive confirmations>
```
```

## Why each section exists

- **State** is the only part a reader is guaranteed to see. Keep it current and keep it to one line.
- **Established** is what the next unit inherits. If a fact is not here, it will be rediscovered.
- **Theories** exist because a theory written early survives a termination and a conclusion never written does
  not. Mark them so they cannot be mistaken for findings.
- **Measurements** in a table, because before-and-after is the shape a reader needs and prose hides the deltas.
- **Prediction refuted** is separated because the default instinct is to work around a wrong prediction rather
  than report it. Making it a named section makes it a deliverable.
- **Defects including my own** is routine rather than embarrassing. A lane that found and fixed its own
  regression has done more than one that never mentions it, and correcting an earlier claim in the same report
  is far better than quietly making the report consistent.
- **Could not determine** is a result. An honest unknown stops the next unit guessing.
- **Negative results** are the cheapest thing to record and the most often skipped. They stop the next unit
  repeating a search.
- **Cost** is what makes the next estimate possible, and it is the first thing lost when a session ends.
