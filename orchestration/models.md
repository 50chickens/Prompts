# Models

Which model a lane runs on is a scheduling decision with a cost, and it is one of the few settings an
orchestrator controls directly.

## The default

**Leave the model unset unless there is a reason to force it.** The runtime resolves a per-agent-type preference,
and overriding it changes the session's cost and behaviour profile. An orchestrator that overrides by habit is
paying for a preference it did not form.

## When to force a model

Force one only when something external requires it:

- **The task is a governance or standards copy** that the project has decided must run on a specific model.
- **A measured cost or latency problem** makes the default unusable for a particular class of unit.
- **A capability gap** - a unit needs a context size or a reasoning depth the default does not provide.

When you do force it, say so in the brief and record the reason. A forced model with no recorded reason is a
preference nobody can revisit.

## Matching the model to the shape

The useful heuristic is the lane archetype from [lanes.md](lanes.md), not the subject:

| Lane shape | Cost profile | Notes |
|------------|--------------|-------|
| Read-only review | Cheap per unit, high volume | Best value per token in the whole project |
| Investigation with a cheap instrument | Very cheap | Prefer this shape wherever possible |
| Implementation | Expensive, low volume | Serialised behind the build lock anyway |
| Research and triage | Cheap per repository | Most of the output is one line per item |

Two consequences worth acting on:

- **Route volume work to cheap models and depth work to capable ones.** Triaging twenty sources into "relevant
  or not" does not need the same model as reconciling two specifications.
- **The cheapest lane is often the most valuable.** A read-only unit that reconciles two sources can change the
  plan without touching a build.

## A forced model can be wrong for the work

If a lane's output reads like a summary of the brief rather than an investigation, the model may be the wrong
fit for the shape - or the brief may be too vague. Check the brief first; it is cheaper to fix and it is the more
common cause.

## Recording what was used

Keep a short record per unit, because it is what makes the decision reviewable:

```text
lane1   forced: <model1>   reason: <external requirement>
lane2   default            -
lane3   forced: <model2>   reason: needs long context for <document1>
```

## Escalating and de-escalating

- **Escalate** when a cheap unit returns work that has to be redone.
- **De-escalate** when an expensive unit is doing enumeration, transcription or triage.
- **Do not escalate to fix a bad brief.** A capable model working from a vague brief produces a confident
  answer to the wrong question.
