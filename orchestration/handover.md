# Handover

A handover is the document that lets a different agent, with none of your context, take over the job and be effective in its first hour. It is a job description plus a map: not a project description, not a status report, and not a second authority for rules that live elsewhere.

Write the first paragraph as an instruction, not as context: not "this project concerns X" but "you are the orchestrator; your product is a queue that moved, and technical work is not yours". Without a named role the most obvious next action is the technical one. If one agent must do two jobs, write two handovers.

## The test of a good handover

Give it to a fresh agent with no history and ask four questions before it does any work.

| Question | What it produces |
|----------|------------------|
| What are your first three actions? | Concrete, in order, none of them technical if the role is management |
| What is the priority now, and what is explicitly not? | Your answer, with the parked work named |
| Which document answers question X? | A path, not a folder |
| What are you forbidden to do? | The prohibitions, in your own words |

Any vague answer means the handover is a description rather than a handover, and an untested one is a draft.

## The environment section

The section almost always missing is the environment: a table of tools, servers, skills, instruction files, settings and absolute roots, with a line on how to check each. Two entries are worth more than the rest: how to tell whether a unit is running on the model you intended, and how to find work left running by a unit that died.

What must not appear anywhere in the document: a project summary, a dated plan, a directory listing, a status table, tool tutorials, a copy of the brief template, a restatement of the queue rules, or secrets and credentials. If a sentence becomes false when the next unit lands, it is status and belongs in the state document.

Link, do not duplicate: if a fact already lives in its own document, the handover names it and does not restate it. The prohibitions matter more than the duties, because an agent will do the obvious action reasonably well and cannot infer the action that looks obvious and is wrong here: measuring something itself, touching a shared file, re-running a gate that is already green. Write each in the imperative with its reason and the cost of ignoring it, and name the previous holder's specific mistakes, since "a previous holder did a unit's work itself and stalled the queue" prevents a repeat where "delegate well" does not.

## The document set

| Document | Answers | Owner |
|----------|---------|-------|
| Goals | What does "done" mean? | Orchestrator |
| Milestones | Which capabilities are reachable, in what order? | Orchestrator |
| Deliverables, one per part | What is this part, what does it enable, what would shortcut building it? | Orchestrator |
| Component map, one file per section | What are the pieces, how do they depend on each other, what is their state? | Orchestrator, or the lane that changed it |
| Decisions | Which choices were deliberate, what do they cost, what would overturn them? | Orchestrator |
| Timeline | When did each piece start and finish, where does its source live? | Orchestrator |
| Specifications | How does the thing work, with its measurements? | The lane that established it |
| Sources index | Which primary sources are held, what was extracted from each? | Orchestrator |
| Coordination rules | How do lanes operate? | Orchestrator |
| Lane reports | What a unit established, suspected and could not determine | The lane |

State and definition live in different documents: a deliverables document defines a part and stays readable regardless of progress, while the component map records state and changes constantly. **Only the map records state**; "currently" and "so far" belong there or in the timeline. Keep the map cheap to update: one file per section with a diagram and a short description, colour as state, no history, and a timeline table of node, state, started, completed, source file.

The decisions document carries, per entry, the decision stated as a sentence somebody could disagree with, the evidence it rests on, its cost if wrong, and what would overturn it.

**An assumptions document** lists what a fresh unit may take as true without verifying it. **A refuted-claims document** lists settled negatives; a reader cites the entry and moves on, and a writer adds to it. A claim that dies goes into the refuted list first and is removed from whatever asserted it second.

## The stale-fact problem

The most common defect in a long project is a statement that was true when written and is false now. A fact that names a moving quantity says when it was measured. Cite precisely enough to be found. Do not put an expectation in prose - expectations belong in an executable check. When correcting a propagated claim, record the correction rather than editing quietly. Check a citation by opening the source, not by re-reading the sentence that cites it.

## References that do not rot

Choose the highest rung that is still precise enough to identify the thing.

| Rung | Anchor | Survives | Fails when |
|------|--------|----------|------------|
| 1 | An identifier the world maintains: document number with revision, commit hash, release version, artifact digest, package version, configuration key, public symbol | Everything except a rename of the thing itself | The identifier is not carried where the reader can look it up |
| 2 | An exact quoted string plus the file or document carrying it | Reflow, reordering, insertion, reformatting | The text itself is edited |
| 3 | A named heading or section title | Most edits | The document is restructured |
| 4 | A path relative to one declared root | Content edits | The file or folder moves |
| 5 | A line number, paragraph ordinal, "the third table", "the snippet above" | Nothing | The first edit above it |

Rung 5 is legitimate in exactly one case: the target is frozen, such as a tagged commit, a generated report with a recorded digest, or a PDF whose page labels are printed on the page.

Quote and cite rather than point and cite: `"the writer that satisfies its own pollers" - document1` survives every edit above it and can be found by searching, where `document1:356` survives nothing. Cite the identity before the location - revision and figure or table number for a published document, release or commit then symbol for code. Declare one root once in the environment inventory and let briefs name the declaration; a filesystem-absolute path inside the project is a defect even while it is correct.

Never write a live count in prose: write the command that counts it, or the number with the date and the command beside it. Generate what can be generated and cite the generator rather than its output. Append rather than renumber.

When a document moves, leave a one-line stub at the old path naming the successor and fix the pointers in the same sitting. Repairing a dead citation is a unit, not a pass-through edit. Before handing over, run a link check over every relative link, then look for absolute paths outside the declaration site, live counts in prose, line numbers into edited documents, and quotations that have lost their source.

## Decisions the orchestrator cannot make alone

Some decisions are the human's, because they change scope, cost or the shape of the project rather than the work inside it: putting the project under version control, acquiring hardware, credentials, licences or access, and widening or narrowing what the project is for. Record each once, with the question stated precisely enough that a one-line answer is possible, and ask once. If the answer changes only how a part is built it is the orchestrator's; if it changes which parts exist it is the human's. Maintain your own documents rather than asking permission, and do not edit a document a lane owns. Acceptance and the record are one sitting: a report accepted but not written into the status map is a rumour, and the next agent measures it again.

## Skeleton

```markdown
# Handover: you are <role>

<One paragraph. What the agent is, what its product is, and the single prohibition.>

## Read these, in this order
<Five rows at most: document, why.>

## What you own
<Table: duty, why it is yours.>

## What you must not do
<List, each with a reason and a cost.>

## The operating loop
<Numbered steps, from reading state to closing an item.>

## Where everything is
<Table: question, relative path, owner.>

## Priority
<The rule, the parked work, and the tells for wrong work.>

## Running units
<Launch mechanics, model enforcement, concurrency ceiling, stopping and cleanup.>

## Briefs and the queue
<The shape, the three sentences, and links to the authoritative documents.>

## Mistakes that have already been made
<Second-person, no names, each with the cost.>

## Environment
<Tools, servers, skills, settings, absolute roots, and how to verify each.>

## Lessons that are not guessable
<The expensive ones, one short paragraph each.>
```

Before handing over, delete anything that describes the state of the project rather than the job, run the four-question test with a fresh agent, and check every link.
