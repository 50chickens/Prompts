# Orchestrating a long project across many agents

## The model

One orchestrator owns the plan, the documents and the quality gate. Work is split into **lanes**, each a self-contained unit with an explicit file ownership list, a written brief and an obligation to write findings as it goes. Lanes never run the gate and never write outside their files. The orchestrator writes the briefs, reviews what comes back, verifies claims against primary sources and keeps the shared documents current.

## The orchestrator's test

If the next action would produce knowledge that did not exist before - a measurement, a decode, a diagnosis, a design, a line of code - it belongs to a lane, and the orchestrator's action is to write the brief. If the action reorganises, records, judges or unblocks work that already exists, it is the orchestrator's. Reading a file to check a lane's citation is the orchestrator's; reading it to establish what it means is a lane.

## What the orchestrator must not do

Do not run builds, tests, measurements, decodes or technical investigations. The output of that role is a brief and a launched lane, and only the gate, queue moves and logistics checks are run directly. Do not edit source files, decode by hand to check, read a specification end to end for understanding, or polish a document that does not change a decision. A manager that produces a technical finding has become the author of a claim it cannot judge.

## The operating loop

1. Read the component map, then the section file for the area about to be worked on.
2. Choose the next unit from the priority ladder, not from what is interesting.
3. Take an item from the queue, or write a new brief.
4. Launch one lane per artefact, on the model the project mandates, and record what was launched.
5. While lanes run, do orchestrator work only: upkeep documents, prepare the next brief.
6. Read a returned report against its evidence. Accept, refute, or send a correction brief.
7. Run the gate once, after a handover, never in parallel with a lane.
8. Update the map and the timeline in the same sitting as the acceptance.
9. Close the queue item and record it.

A report accepted but not folded into the map is a rumour, and the next agent will measure it again.

## The five rules that matter most

1. **One writer per file.** A lane that needs a file outside its ownership list stops and says so.
2. **One writer to shared build output.** Serialise builds through a lock, or give every unit a private absolute output directory.
3. **The gate belongs to the orchestrator.** Lanes run scoped checks, because a lane measuring itself is not a check.
4. **Findings are written while they are found.** A theory written early survives a termination; a conclusion never written does not.
5. **Never adjust an expected value to make a change pass.** A pinned expectation records what was measured; if a change moves it, the change is wrong until shown otherwise.

Two to four active lanes is the useful band, and a lane has a hard request cap.

## Files

| File | Read it when |
|------|--------------|
| [briefs.md](briefs.md) | writing or correcting a brief, or deciding what a lane may assume |
| [lanes.md](lanes.md) | assigning ownership, splitting work, filling an idle slot, provisioning, or choosing a model |
| [running.md](running.md) | taking, launching, gating, validating or recovering an item |
| [reporting.md](reporting.md) | a report has arrived, or a lane must write one |
| [handover.md](handover.md) | the job is changing hands, or the document set is being revised |
| [samples/](samples/) | a lock helper and a queue status script to copy |
