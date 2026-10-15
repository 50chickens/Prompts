# Contention

Two agents in one repository collide in ways that are hard to diagnose, because the symptoms look like defects
in the code rather than collisions between writers. This file is about preventing that.

## The two collision surfaces

1. **Shared files.** Two lanes editing one file produce a lost update: the second writer's save succeeds and
   the first writer's change is gone, with no error.
2. **Shared build output.** Two lanes building into one output directory produce failures that name the wrong
   cause entirely.

The first is prevented by ownership lists. The second needs either a lock or isolation, and it is the one that
wastes the most time.

## Shared build output: the failure mode

When two builds write the same intermediate and output paths, the symptoms include:

- A "file in use" style error naming a path, which reads as a defect in the build rather than a collision.
- A test host whose assemblies were replaced while it was running, producing failures in tests that are fine.
- An intermittent failure that disappears when retried, and therefore never gets diagnosed.
- Generated files that appear in the wrong folder, with the error pointing at a different project than the one
  that wrote them.

The expensive part is that all four look like real problems. An hour of a green pipeline has been lost to this
in a project that knew about it.

## Two solutions, in order of preference

### Serialise through a lock

A single lock file held for the duration of a build. Simple, and it makes the bottleneck explicit.

```powershell
function Invoke-Exclusive {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][scriptblock]$Action
    )

    $stream = $null
    $attempt = 0
    while ($null -eq $stream) {
        try {
            $stream = [System.IO.File]::Open(
                $Path,
                [System.IO.FileMode]::OpenOrCreate,
                [System.IO.FileAccess]::ReadWrite,
                [System.IO.FileShare]::None)
        }
        catch [System.IO.IOException] {
            $attempt++
            if ($attempt -gt 120) { throw "Could not acquire $Path after $attempt attempts." }
            Start-Sleep -Seconds 5
        }
    }

    try { & $Action }
    finally { $stream.Dispose() }
}
```

Callers pass the lock path and the work, and never reason about the lock themselves. See
[samples/lock.ps1](samples/lock.ps1).

### Isolate the output

Give each lane its own output directory, so contention is impossible rather than unlikely:

```powershell
dotnet build -p:ArtifactsPath="$PSScriptRoot/../$laneId-artifacts"
```

**Isolation has its own trap: a relative path silently resolves under the source folder** and produces
duplicate-generated-file errors naming the wrong location. Always pass an absolute path, and verify where the
output actually landed the first time you use the flag.

The trade-off is that isolated output is cold: a build that would be incremental becomes full. Prefer the lock
for the ordinary case and isolation for a lane that genuinely cannot wait.

## Locks that are not about the build

Any long-running resource shared between lanes needs the same treatment:

- A serial port or hardware device.
- A rate-limited remote service or API.
- A single-instance analysis tool.
- A generated document many lanes want to read while one writes.

For a rate-limited service, the lock should also handle **backoff**: on a rate-limit response, sleep and retry
with a growing interval, and stop after a bounded number of attempts rather than hammering. Record the attempt
count in the report so the orchestrator knows the service was the constraint.

## Cheap conventions that prevent most contention

- **One writer per file, stated in the brief.** Not "avoid touching X" but "you do not own X".
- **Add a file rather than editing a shared one.** A lane that needs configuration adds its own config file
  beside the existing ones.
- **Describe rather than edit.** A lane that wants a change in a shared document writes the change in its report
  and lets the owner apply it. A runner passing through a load-bearing document is how a document gets corrupted.
- **Never enumerate shared state to decide what to do.** Reading a directory to infer another lane's progress is
  both a race and a bad source of truth; use the queue instead.
- **An installation step should be a script, not a sequence of manual actions.** A tool upgrade can wipe its own
  tree, and a manual step that has to be repeated from memory will be repeated wrongly.

## Recording the bottleneck

The build lane is usually the constraint, not the number of lanes. Make that visible rather than assumed:

- **Record how long each unit waited for the lock**, and say so in the report when the wait dominated the run.
- **If most units are waiting, add read-only lanes rather than more writers.** A unit that cannot write build
  output cannot contend.
- **Isolated output trades contention for build time.** Say which was chosen and why, so a slow full build is
  not later blamed on something else.

## Diagnosing a suspected collision

In order:

1. **Was a second writer active?** Check the queue's `in_progress` folder, not the filesystem.
2. **Did the failure name a path?** Look for a path in the output directory, then work out which lane writes
   there. A path outside every ownership list is the giveaway.
3. **Does a retry succeed?** A failure that vanishes on retry is a collision far more often than a flaky test,
   and should be recorded as such rather than dismissed.
4. **Do the timestamps overlap?** A file whose last-write time falls inside another lane's active window is
   strong evidence, and cheap to check.
