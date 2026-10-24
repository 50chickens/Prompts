---
applyTo: '**/*.ps1'
---

# PowerShell rules

Iterate with the pipeline, not with the foreach statement.

Banned: the `foreach (` keyword in a .ps1 file.
Use: `$collection |% { $someVariable = $_ ; Invoke-DoSomethingWithSomeVariable $someVariable }`

A loop that must stop early or index positionally is the exception.
