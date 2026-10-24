---
name: csharp
description: "Use when a task touches C# in this repository: adding or wiring services, changing a project file or target framework, P/Invoke, NuGet, NUnit fixtures, Avalonia UI, or code the compiler accepts but the runtime rejects. Reads the owning pattern files first, then builds and tests."
---

# C#

`C:\git\internal\Prompts\patterns\csharp.md` owns the language, structure, logging, test and package rules. Read it before the first edit. It is the only place those rules are stated; this skill says what order the work runs in.

## Order of work

1. Glob `*.csproj`, read every project the change touches. Target framework, nullable, implicit usings, language version and version are written in the csproj; there is no props file above them.
2. Read `C:\git\internal\Prompts\patterns\csharp.md`. Avalonia work also reads `patterns\avalonia.md`; a refactor of an existing solution reads `patterns\solution-refinement-loop.md`.
3. Read the code around the edit before editing, and reuse the service, extension method or test factory that already does the work.
4. Package changes go through `dotnet add` or `dotnet remove`, then restore.
5. Build the project that changed, then the solution. Read the warning codes, not only the exit status.
6. Extend an NUnit fixture and run it with a filter that reaches only the affected tests. A green build is not evidence that the application starts; run it once when composition or an output type changed.
7. Re-read the diff against the banned shapes in `patterns\csharp.md`, and check the siblings of every method you fixed for the same defect.

## Where the detail lives

| Topic | File |
| --- | --- |
| Language, structure, DI, logging, tests, packages, banned shapes | `patterns\csharp.md` |
| Avalonia views, view models, headless journey tests | `patterns\avalonia.md` |
| Refactoring an existing solution | `patterns\solution-refinement-loop.md` |
| Worked solution: console composition root, Core, Infrastructure, Application, NUnit suites | `skills\csharp\solution` |
| Shapes refused in review | `skills\csharp\bad.cs` |
