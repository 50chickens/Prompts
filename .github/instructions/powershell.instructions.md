---
applyTo: '**/*.ps1'
---

# PowerShell rules

Iterate with the pipeline, not with the foreach statement. Banned is the `foreach (` keyword. Use `$collection |% { ... }`. A loop that must stop early or index positionally is the exception, and it says so on that line.

A script sets `Set-Location $PSScriptRoot` itself and takes no parameters.

Never use a `$PS*` variable except `$PSScriptRoot`.

Detail: C:\git\internal\Prompts\patterns\powershell.md.
