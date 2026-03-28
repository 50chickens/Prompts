# Solution Refinement Loop

A loop pattern for iterating on a solution design across three files: `todo.md`, `prompt.md`, and `plan.md`. Each file has a distinct role and must not bleed into the others.

## File Roles

| File | Contains | Does Not Contain |
|------|----------|------------------|
| `todo.md` | Open questions and unknowns with enough context to reason about them later | Decisions, constraints, or implementation detail |
| `prompt.md` | Constraints, mechanisms, and decisions — the *what* and *why not alternatives* | Implementation steps, file names, script logic |
| `plan.md` | Implementation detail — the *how*, sequence, file structure, script behaviour | Reasoning about alternatives, ruled-out options |

---

## The Loop

```
1. IDENTIFY
   An unknown or open question is found during planning or review.
   Add it to todo.md with enough context that it can be reasoned about
   independently — include the options considered and why the answer matters.

2. SOLVE
   Research, reason, or decide. Pick one answer. Do not leave it open-ended.

3. UPDATE prompt.md
   Add the decision as a constraint or mechanism.
   Write what is required and why alternatives were ruled out.
   No implementation detail — prompt.md describes requirements, not steps.

4. UPDATE plan.md
   Add the implementation detail that flows from the decision:
   which script does it, in which phase, with what behaviour.
   Reference values from config files rather than hardcoding.

5. CLOSE
   Remove the item from todo.md. If todo.md is now empty, write "No open items."

6. REPEAT
   Review prompt.md and plan.md for consistency gaps or new unknowns.
   If any are found, go to step 1.
```

---

## Rules

- **Solve, don't defer.** An item added to todo.md should be resolved in the same session where possible. todo.md is a work-in-progress list, not a backlog.
- **Decisions go in prompt.md first.** If a decision is only in plan.md it is invisible to future constraint checks.
- **prompt.md stays mechanism-level.** It should describe what a script does (e.g. "retrieves credentials from Secrets Manager and connects as master user") not how it does it (e.g. "calls `Invoke-SSMGetParameter` then pipes to `ConvertFrom-Json`").
- **plan.md stays implementation-level.** It should not re-explain why a decision was made — just describe what happens.
- **No new unknowns without closing old ones first.** Keep todo.md short. A long todo.md is a sign the design is not converging.

---

## Example

**Unknown found:** The Mac scenario cannot use IAM credentials to authenticate a SQL Server connection. The auth mechanism for scenario 2 is unresolved.

**todo.md entry:**
```
- Mac SQL auth mechanism (scenario 2). IAM database auth is not available for SQL Server.
  Options: (a) Kerberos via kinit + ODBC Driver Trusted_Connection=Yes,
  (b) SQL Server Auth username/password login.
  Determines whether an additional SQL login must be provisioned on RDS.
```

**Decision:** Kerberos. It exercises the trust cross-platform and reuses the same Windows Auth login already provisioned for scenario 1.

**prompt.md addition:**
```
scenario 2 uses Kerberos. The Mac user obtains a TGT for pbs.ipscminet.com via kinit.
ODBC Driver 18 connects with Trusted_Connection=Yes. No SQL Server Auth login is required —
the same [PBS\user] Windows Auth login covers both scenarios.
```

**plan.md addition** (in `configure-managed-member` instance script description):
```
Both scenario 1 (Windows, automatic Kerberos) and scenario 2 (Mac, kinit TGT,
Trusted_Connection=Yes) use the same [PBS\user] Windows Auth login. No additional
SQL Server Auth login is provisioned.
```

**todo.md:** item removed.
