# What a unit can actually do

A brief is a promise about capability. This file is about making that promise true, and about the three questions
that decide it: what a unit inherits, what it may provision for itself, and whether units should talk to each
other.

## Inheritance is not automatic

Never assume a unit has the orchestrator's tool surface. The surface is resolved per unit by the runtime and by
the unit's declared type, and the failure is silent in the worst possible way: the unit does not error, it reports
that it could not find the tool, and its whole budget is gone.

Assume nothing, and probe once per host.

| Capability | Expected | Why |
|------------|----------|-----|
| Shell, file read and write, search | present | the unit type is defined by this |
| Project instruction files | usually applied | they are scoped to the workspace rather than to the agent |
| Skills and plugin-supplied tools | unverified | resolved per agent rather than inherited |
| Servers (MCP and similar) | **absent until measured** | this is the one that breaks briefs. A measured case had a unit receive none of a server's tools while the orchestrator held all of them |
| Ability to launch further agents | sometimes present, always forbidden | a child is launched on a model nobody chose and writes files nobody scoped |

The probe costs one unit and five minutes. Brief a unit to answer four questions and nothing else: which model
identifier it is on, whether its tool list contains server1, whether it contains server2, and whether it can read
a file in the project. Record the four answers with the date in the environment document. Every later brief is
written against measured facts instead of plausible ones.

The reason to record rather than remember is that the answer changes with the client version and with the host,
and a wrong assumption here is invisible until a unit has already been spent.

## Provision, build, or install

Three different actions that a brief tends to conflate.

**Provision, by the orchestrator.** Anything system-level, shared, or needed by more than one unit is installed
once, by a script, before the units that need it. A provisioned tool is pinned, reproducible on another machine,
and identical for everyone. This is also the only place a version number should appear.

**Build, by the unit.** A unit may write a tool it needs, provided the tool is a file it owns: one source file
run directly, a script in its own work folder, a compiled inner loop. This should be encouraged rather than
tolerated, because the alternative is a unit spending its budget on a manual traversal that twenty lines would
have done. Two conditions: it lives within the unit's file ownership, and the report cites the tool rather than
only its output, so the result can be regenerated.

**Do not install, by the unit.** No package manager, no runtime, no system component. An install made mid-unit is
unpinned and therefore not reproducible, it mutates shared state while other units assume a stable environment,
it silently violates the project's language or dependency rules, and it converts a bounded unit into an
open-ended one.

The mechanism that makes the prohibition workable is a request channel rather than a refusal. A unit that believes
it needs an install reports what it needed, why, and what it would have bought, and stops. That report costs one
turn and produces the shopping list; the orchestrator provisions and relaunches. The alternative - a unit that
quietly installs - costs the unit, changes the host, and cannot be reproduced.

Put the request field in the report stub so a unit that is killed has still asked.

## Units talking to each other

The runtime may offer a live channel between units. On most projects it should be off by default, and the
reasoning is worth stating because it is counter-intuitive: the thing that makes a multi-unit project reliable is
that each unit's output is durable, attributable and independently checkable, and a conversation is none of the
three.

What a live channel costs:

**It leaves no record.** The quality mechanism is that a claim arrives in a file with a citation and is judged by
someone else. A conversation produces agreement, and agreement is not evidence. The record afterwards shows two
units that concur, without showing why either believes anything.

**It destroys independent validation.** If the author and the validator talk, the validator becomes a co-author.
Two agents negotiating an answer is precisely what makes "trust but verify" meaningless, and it happens through
goodwill rather than malice: neither party intends to collude.

**It invites negotiation instead of specification.** Two units that can talk will agree a boundary between their
work. That boundary is then unauthored - nobody decided it, no brief covers it, and the ownership lists overlap
in a way the orchestrator never sees.

**It converges rather than corrects.** The dominant failure is not disagreement, it is two agents arriving at a
shared wrong answer with neither holding the standing to contradict it. Cost and latency are secondary; this one
is fatal because it manufactures false confidence.

Where it is genuinely useful is narrow: two units in flight at once on opposite sides of one interface that is
itself being designed. Even there the better instrument is a file. The orchestrator writes the contract - names,
units, error behaviour - as a document both units are briefed against. That is durable, reviewable, and it forces
the decision to happen once, in the open, by the party who owns it.

If coordination is genuinely needed, use an append-only questions file read and relayed by the orchestrator at
fixed intervals. It is asynchronous, it cannot deadlock, it leaves a record, and the relay keeps the decision
where it belongs.

## The levers that make a unit finish

In rough order of what each buys.

**Pre-flight the brief.** Check that every path exists, every identifier is real, the model name is valid and the
report path is writable. Seconds of work, and it prevents the most expensive failure there is, which is a brief
that sends a unit somewhere that is not there.

**Name the artefact and its path.** A unit that knows the file it must produce in the first minutes spends its
budget on the question.

**One question, one file list, one report.** Two questions return a document that answers neither cleanly.

**Size to the request cap.** A unit is cut off silently at a fixed request count. If you cannot say what it will
have produced ten minutes in, it is two units.

**Scope the corpus numerically.** Name the file, the range, the release, the count. "Across the whole of..."
is an instruction to enumerate.

**Pre-answer the discoverable.** Put the roots, the identifiers and the entry points in the brief. A unit
rediscovering something the orchestrator already knows is pure loss.

**State the stop condition.** Say that a partial answer with named gaps is a complete delivery. Units that
believe they must finish improvise; units allowed to stop report the blocker, which is worth more.

**Forbid enumeration and agent-spawning in plain words, every time.** Both are what a unit does when it is lost.

**Ask for the cost line.** A unit that reports which loop dominated its run tells you where the budget went and
sizes the next brief correctly.

**Watch time to first artefact, not elapsed time.** A unit that has written nothing after several tool calls is
lost, not thinking. A unit whose report stub has grown twice is working even if it is slow.

**Intervene at around fifteen minutes of silence.** The dominant failure is silence. A short steering message is
cheap; waiting is not.

**Kill and requeue rather than supervise.** A unit at three times its estimate with nothing durable is not coming
back. Release the claim, keep the stub, relaunch as a continuation.

**Continue, never restart.** The stub is the asset. A restart pays for the first attempt's discoveries twice.

**Batch the same shape.** Five variations of one operation are one unit with a list, not five units that each
rediscover the same primitives.

**Cap the count at what your attention can hold.** Throughput is bounded by review capacity and by any serialised
shared resource, not by how many agents can be named at once.
