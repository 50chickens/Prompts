# Documents

Documents are the project's memory, and they are also where a long project accumulates its worst defects. A
wrong statement in a document is read by every later unit and inherited silently.

## The document set

| Document | Answers | Owner |
|----------|---------|-------|
| Goals | What does "done" mean? | Orchestrator |
| Milestones | Which capabilities are reachable, and in what order? | Orchestrator |
| Deliverables, one per part | What is this part, what does it enable, and what would shortcut building it? | Orchestrator |
| Component map, one file per section | What are the pieces, and how do they depend on each other? | Orchestrator, or the lane that changed it |
| Decisions | Which choices were deliberate, what do they cost, and what would overturn them? | Orchestrator |
| Timeline | When did each piece start and finish? | Orchestrator |
| Specifications | How does the thing actually work? | The lane that established it |
| Coordination rules | How do lanes operate? | Orchestrator |
| Lane reports | What a unit established, suspected and could not determine | The lane |

Three conventions make this set work:

- **State and definition live in different documents.** A deliverables document defines a part and should be
  readable regardless of how far along it is. A component map records state and changes constantly. Mixing them
  means the state goes stale inside a document nobody thinks to update.
- **The map is the thing to update after progress**, and it should be small enough that updating it is cheap.
  A single large map becomes a document nobody refreshes.
- **Facts go in one place.** A second copy is a second source of truth, and it will drift.

## The stale-fact problem

The most common defect in a long project is not a wrong calculation. It is a statement that was true when
written and is false now, with nothing in the text to say so. Measured across one project, this class accounted
for the majority of defects found by review.

Its shapes, all of which were found in practice:

- **A number that moved.** A count, an address, a test total.
- **A symbol or file name that was renamed.**
- **A citation pointing at the wrong location** - a page that names a footer, a line number that decodes nothing.
- **An attribution to the wrong function or module.**
- **A table row from a different edition or generation** read as a statement about this one.
- **A headline count contradicting the table beneath it.**
- **A claim reversing its source** - saying a reference reads one way when it reads the other.
- **A sentence whose stated reason is no longer the reason.**

Rules that prevent most of them:

- **A fact that names a moving quantity should say when it was measured.** Ten words of provenance prevent a
  reader from trusting a stale number.
- **Cite precisely enough to be found.** Document, edition, page and line if the source has lines.
- **Do not put an expectation in prose.** Expectations belong in an executable check.
- **When correcting a claim, record the correction rather than editing quietly**, when the wrong version was
  already propagated. "This was attributed to the wrong document; the value is unchanged" is worth a sentence.
- **Correct your own earlier section visibly rather than leaving it to be re-derived.** A report or a
  specification that says "an earlier section of this document said X; that was wrong because Y" is far more
  useful than one that is quietly consistent, because the reader who saw X needs to know it changed.
- **Check a citation by opening the source**, not by re-reading the sentence that cites it. An extraction artefact
  repeated across several figures looks exactly like corroboration.

## Keeping a map current

The map is the document most likely to be abandoned, because it is the one that must change every time anything
does. Keep it cheap:

- **One file per section**, with a diagram and a short description. A section is updated by whoever changed it.
- **Colour is state.** A reader sees the state without reading prose.
- **No history in the map.** History belongs in a timeline and reasoning belongs in decisions.
- **A timeline table is metadata, not a narrative.** Node, state, started, completed, source file. Nothing else.

## The decisions document

This is where judgement is recorded, and it is the document that most repays discipline. Each entry should
carry:

- **The decision**, stated as a sentence somebody could disagree with.
- **The evidence it rests on.**
- **Its cost if wrong.**
- **What would overturn it.**

An entry without the last two is a preference recorded as a fact.

## Two documents that stop repeated work

**An assumptions document lists what a fresh unit may take as true without spending calls verifying it.** Every
long project accumulates facts that are true, cheap to state and expensive to re-establish - a path, a version, a
format detail, a settled convention. Written down once, they save every unit the first few turns of a brief.
Without it, each unit re-verifies the same handful of things and reports them as findings.

**A refuted-claims document lists settled negatives.** These are more valuable than the assumptions, because a
negative is what a unit will otherwise re-derive: it will see the same absence, reach the same conclusion, and
spend a unit confirming something already known. The rule for a reader is *cite the entry and move on*, and the
rule for a writer is to add to it rather than to argue with it in a report.

Both documents must be short to survive. An assumptions document nobody reads is worse than none, because it
implies the answers are recorded.

## Decisions the orchestrator cannot make alone

Some decisions are the human's, not the orchestrator's, because they change scope, cost or the shape of the
project rather than the work inside it. Typical examples:

- Whether to put the project under version control, which changes the directory's shape and needs an ignore file
  first.
- Whether to acquire hardware, credentials, licences or access that cost money or time.
- Whether to widen or narrow what the project is for.

**Record these once, with the question stated precisely enough that a one-line answer is possible, and ask
once.** Re-asking spends a turn; assuming an answer to a scope question is worse, because the work built on the
assumption may be discarded. Distinguish them from ordinary decisions: if the answer changes only *how* a part is
built, it is the orchestrator's; if it changes *which parts exist*, it is the human's.

## Maintenance as a standing duty

The orchestrator maintains its own documents rather than asking permission to update them. Offering to update a
map, a status table or a checklist is the same mistake as asking to: it spends a turn confirming a preference
that was never in question. If a document is yours and progress has been made, update it.

The corollary is that a document owned by a lane should not be edited by a passer-by. Several documents are
load-bearing for other units, so a runner that wants a change in one describes it in its report instead.
