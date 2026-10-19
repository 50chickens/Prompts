# Writing a handover

A handover is the document that lets a different agent, with none of your context, take over your job and be
effective in its first hour. It is not a project description and not a status report. It is a job description
plus a map, and the two are separate artefacts that usually get merged by mistake.

This file is about writing one. The rest of this folder is about the work the handover hands over.

## The test of a good handover

Give it to a fresh agent with no history and ask four questions before it does any work.

| Question | What a good handover produces |
|----------|-------------------------------|
| What are your first three actions? | Concrete, in the right order, and none of them is technical work if the role is management |
| What is the priority right now, and what is explicitly not? | The same answer you hold, with the parked work named |
| Which document answers question X? | A path, not a folder |
| What are you forbidden to do? | The prohibitions, in the same words you would use |

If any answer is vague, the handover is a description rather than a handover. This test costs one short session
and it is the only reliable way to find out whether the document works. A handover that has never been tested
is a draft.

## Prime the role first, and prime one role

The first paragraph is the highest-leverage sentence in the whole document. It tells the arriving agent what it
is. Write it as an instruction, not a context: not "this project concerns X" but "you are the orchestrator; your
product is a queue that moved, and technical work is not yours".

Two failure modes follow from getting this wrong.

**Role drift.** An agent told only about the project will start doing the project's work. It is not
disobedience: without a role, the most obvious next action is the technical one, because that is what the
artefacts in front of it are about. Naming the role and the prohibition explicitly is what stops it, and it must
be repeated in the section about each duty, because a single mention at the top gets lost by the fourth tool
call.

**Two roles in one document.** A manager's handover and an implementer's handover share almost nothing except
the map. If the incoming agent must do both, write two handovers and say which applies when. Merged, the
prohibitions contradict the duties and the agent will resolve the contradiction in whichever way is easiest.

## What goes in, and what must not

| Section | Contents | What must not appear |
|---------|----------|----------------------|
| Role | Who the agent is, what its output is, the one-line test for telling its work from a unit's work | A project summary |
| First hour | A short ordered reading list, and the first three actions | Everything you know |
| Map | Question to document, with relative paths | A directory listing |
| State authority | The one document that records state, and the rule that no other document carries status | A status table anywhere else |
| Priority rule | How to choose the next unit, what is parked, and the tell for wrong work | A dated plan |
| Orchestration | How units are launched, on what, how many, and how they are stopped | Tool tutorials |
| Briefs | The shape of a brief and the three sentences every one carries | A copy of the brief template |
| Queue and memory | Where work lives, how it is claimed, and where lessons live | A restatement of the rules |
| Failure modes | What the previous holder got wrong, in the second person | Blame attached to a name |
| Environment | Tools, servers, settings, paths, and how to re-verify each | Secrets, tokens, credentials |
| Lessons | The expensive, non-obvious things that change how a report is read | Anything guessable from the code |

Two rules govern this table.

**Link, do not duplicate.** A handover that restates the queue rules becomes a second authority for them, and
the two drift within a week. Point at the document and say what it is for.

**One authority per fact.** If a fact already lives in its own document, the handover may name it and must not
restate it. When you find yourself writing the same sentence in two places, one of them is becoming wrong.

## The prohibitions matter more than the duties

An agent will usually do the obvious action reasonably well. What it cannot infer is the action that looks
obvious and is wrong for this project: measuring something itself, touching a shared file, re-running a gate
that is already green, fixing a symptom rather than a unit, working on the interesting thing.

Write prohibitions in the same imperative form as duties, and give each one the reason and the cost of ignoring
it. "Do not edit files outside your ownership list" is a rule. "Do not edit files outside your ownership list;
two units editing one file fail each other, and the failure arrives looking like a defect in the code" is a rule
that survives contact with a confident agent.

Name the specific mistakes the previous holder made. A handover that says "a previous holder did a unit's work
itself and stalled the queue" prevents a repeat; a handover that says "delegate well" does not.

## Write for a reader with your access and none of your context

The incoming agent can read every file you can. It cannot read your intent. Three consequences.

Give absolute roots for anything outside the working tree, because a shorthand that is obvious after a day is
invisible on the first hour and will be mistyped.

Do not explain how to use the tools. Explain which tool for which job, and the traps that are specific to this
environment. A tool tutorial is the fastest way to make a document long and useless.

State what is verified and when. "Measured on date1 on host1" ages honestly; an unqualified fact becomes a
false one silently.

## The environment section, which is almost always missing

Handovers routinely describe the work and omit the instruments. The arriving agent then spends its first hour
rediscovering which servers are registered, which skills exist, which settings change behaviour, and which paths
are outside the tree.

Include a table of tools, servers, skills, instruction files and settings, with a line on how to check each one.
Two entries are worth more than the rest: how to tell whether a unit is running on the model you intended, and
how to find work that was left running by a unit that died.

## Status is a wart

A handover is a document about a job, and a job does not change when the project advances. Status belongs in the
state document and nowhere else. The test: if a sentence becomes false when the next unit lands, it is status
and it does not belong in the handover.

The one exception is a first-hour section that says where to look, which is not status because it points rather
than reports.

## References that do not rot

Every reference decays. The question is whether it decays into something a reader can repair or into something
that reads as verified and is not. A line number into a document that is still being edited is the second kind:
it resolves, it looks precise, and it silently points at different text.

### The ladder

Choose the highest rung that is still precise enough to identify the thing.

| Rung | Anchor | Survives | Fails when |
|------|--------|----------|------------|
| 1 | An identifier the world maintains: document number with revision, commit hash, release version, artifact digest, package version, configuration key, public symbol | Everything except a rename of the thing itself | The identifier is not carried anywhere the reader can look it up |
| 2 | An exact quoted string plus the file or document carrying it | Reflow, reordering, insertion, reformatting | The text itself is edited |
| 3 | A named heading or section title | Most edits | The document is restructured or renamed |
| 4 | A path relative to one declared root | Content edits | The file or folder moves |
| 5 | A line number, paragraph ordinal, "the third table", "the snippet above" | Nothing | The first edit above it |

Rung 5 is legitimate in exactly one case: the target is frozen. A tagged commit, a generated report with a
recorded digest, a PDF whose page labels are printed on the page. A line number into a document that lanes are
still editing is not a reference, it is a guess with a number attached.

### The techniques

**Quote and cite, rather than point and cite.** `"the writer that satisfies its own pollers" - document1` survives
every edit above it and can be found by searching for the phrase. `document1:356` survives nothing and cannot be
repaired without knowing what was there. Quoting also makes the citation checkable by a reader who never opens
the file.

**Cite the identity before the location.** For a published document, revision and figure or table number. For
code, the release or commit and then the symbol. For a report, its date and its own heading. A claim whose
validity depends on a version says which version.

**Declare one root, once.** Relative paths inside a tree; absolute paths only for things outside it, and then in
one declaration site that everything else names rather than repeats. An absolute path repeated across twenty
documents is twenty edits when the tree moves, and it will move.

**Do not enumerate what an index already lists.** Link the index. A hand-written list of files is a fact about a
folder on the day it was written, and it is wrong the moment anyone adds one.

**Never write a live count in prose.** "There are seventeen of them", "nine stages", "1079 checks". A count is
the most silently-wrong number a document can hold: nothing fails, and every reader believes it. Write the query
that produces the count, or write the count with the date and the command.

**Date and scope every measurement.** "Measured on date1 on host1" ages honestly. An unqualified number is read
as current forever, and the reader has no way to know it is a year old.

**Use the tense the durability deserves.** "X is specified in ..." for a stable fact, "X was measured on ..." for
an observation, "X is true as of ..." for anything that moves. Never "currently" without a date.

**Leave a tombstone.** When a document moves or is replaced, leave a one-line stub at the old path that names the
successor, and fix the pointers in the same sitting. A dead link teaches the arriving reader that the whole map
is unreliable, and it will then ignore the entries that are good. This is worth the small clutter: the stub costs
one line and pays for the citation that would otherwise rot.

**Append rather than renumber.** Sections keep their location and their headings, and superseded material keeps
a pointer rather than being deleted while other documents cite it. A document renumbered for tidiness breaks
every citation into it.

**Generate what can be generated.** A table of contents, a link list, an inventory produced by a script cannot
drift from the thing it describes. A hand-maintained equivalent is a maintenance promise nobody keeps.

**Cite the generator, not its output.** If a report can be regenerated from a script and a configuration, cite
those two. The output is scratch, and a document that cites scratch inherits the scratch's lifetime.

**Keep one authority per fact.** A fact stated in two documents is a fact that will disagree with itself. The
reference from the second document is a link, not a copy.

### Before handing over

Run a link check over every relative link in the document set, and repair in the same sitting. Then look for the
other four: absolute paths outside the single declaration site, live counts in prose, line numbers into edited
documents, and quotations that have lost their source.

## Anti-patterns, with the symptom each produces

| Anti-pattern | Symptom in the arriving agent |
|--------------|-------------------------------|
| The project summary | It starts working on the project instead of on the job |
| The historical narrative | It re-litigates decisions already taken |
| The unqualified fact | It inherits a wrong claim and spends a unit killing it |
| The line-number citation | The citation resolves to different text and it believes the wrong thing without noticing |
| The live count | It plans against a number that was true once |
| The duplicated rule | It follows the handover's version and contradicts the authoritative document |
| The folder reference | It lists the folder and reads the wrong six files |
| The priority vacuum | It picks the most interesting unit |
| The missing prohibition | It edits a shared file "just to wire it up" |
| The untested document | Every one of the above, discovered after a day |

## How to maintain one

A handover decays in a predictable order. The first-hour reading list rots when documents move. The priority
rule rots when the milestone changes. The environment inventory rots when a client updates. The role and the
prohibitions decay slowest, because they are about the job rather than about the project.

So review in that order, and treat the reading list as a link check rather than a rewrite. When a document is
moved or superseded, fix every pointer in the same sitting; a handover with one dead link teaches the arriving
agent that the map is unreliable, and it will then ignore the good entries too.

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
<Table: question, relative path.>

## Priority
<The rule, the parked work, and the tells for wrong work.>

## Running units
<Launch mechanics, model enforcement, concurrency ceiling, stopping and cleanup.>

## Briefs and the queue
<The shape, the three sentences, and a link to the authoritative documents.>

## Mistakes that have already been made
<Second-person, no names, each with the cost.>

## Environment
<Tools, servers, skills, settings, absolute roots, and how to verify each.>

## Lessons that are not guessable
<The expensive ones, one short paragraph each.>
```

## Before you hand over, do these three things

Delete anything that describes the state of the project rather than the job. If the reader needs status, the
state document has it and the handover should point at it.

Run the four-question test with a fresh agent. Fix what it got wrong, not what it might get wrong.

Check every link. A handover whose first link is broken has already taught the reader not to trust it.
