# Copilot session cleanup — command reference

Deleting local files does **not** remove the synced copy. Deleting a synced copy happens on GitHub.com or via `/session delete` in the Copilot CLI.

## 1. Check sync settings first

CLI (`~/.copilot/settings.json` — absent means defaults `remote: "on"`, `remoteExport: true`):

```powershell
Get-Content "$env:USERPROFILE\.copilot\settings.json" -ErrorAction SilentlyContinue
Get-ChildItem "$env:LOCALAPPDATA\copilot\managed-settings" | ForEach-Object { Get-Content $_.FullName -Raw }
Get-ItemProperty 'HKLM:\SOFTWARE\Policies\GitHubCopilot' -ErrorAction SilentlyContinue
```

VS Code (`chat.sessionSync.enabled`; profiles override the default user file):

```powershell
Select-String -Path "$env:APPDATA\Code\User\settings.json" -Pattern 'sessionSync'
Get-ChildItem "$env:APPDATA\Code\User\profiles\*\settings.json" | ForEach-Object {
  Select-String -Path $_.FullName -Pattern 'sessionSync' | ForEach-Object { "{0}: {1}" -f $_.Path, $_.Line }
}
```

Or: Settings UI → search `session sync` → **GitHub Copilot Chat: Session Sync** = off.

## 2. Disable sync (before restoring anything)

`~/.copilot/settings.json`:

```json
{
  "remote": "off",
  "remoteExport": false
}
```

VS Code `settings.json`:

```json
"github.copilot.chat.sessionSync.enabled": false
```

Per-launch belt-and-braces: `copilot --no-remote`.

## 3. Restore a session locally (inert — nothing syncs until resumed)

```powershell
$src = 'C:\git_temp\_extracted\.copilot-nuc-pc2\.copilot\session-state\<SESSION-ID>'
$dst = Join-Path $env:USERPROFILE '.copilot\session-state\<SESSION-ID>'

Copy-Item -LiteralPath $src -Destination $dst -Recurse -Force
Get-ChildItem -LiteralPath $dst -Filter 'inuse.*' -Recurse -Force | Remove-Item -Force
Get-ChildItem -LiteralPath $dst -Filter '*.workspace-fork.lock' -Recurse -Force | Remove-Item -Force
```

Optional hardening — drop the cloud identity so a resume cannot reattach:

```powershell
$y = Join-Path $dst 'workspace.yaml'
(Get-Content -LiteralPath $y) | Where-Object { $_ -notmatch '^(mc_task_id|mc_session_id|mc_last_event_id|remote_steerable):' } |
  Set-Content -LiteralPath $y
```

## 4. Delete a session and its synced copy

In `copilot` (not `gh copilot` — that extension only has explain/suggest):

```text
/session delete <SESSION-ID> --yes
```

Answer **yes** to "also delete the synced copy?". `--yes` skips only the preview.

## 5. Verify

```powershell
Get-ChildItem "$env:USERPROFILE\.copilot\session-state" -Directory | Select-Object Name
```

Task pages are `https://github.com/<owner>/<repo>/tasks/<mc_task_id>` (or `https://github.com/copilot/tasks/<mc_task_id>` when the session had no repo). `mc_task_id` lives in `session-state/<id>/workspace.yaml`. A deleted record 404s.

## Gotchas

- `/session delete-all` and `/session prune --older-than N` are **local only** — synced copies survive.
- `/chronicle reindex` **re-syncs** sessions when authenticated. Don't run it after restoring en masse.
- `gh agent-task list|view|create` — no delete; those are cloud agent tasks (archive-only).
- Cloud agent sessions can only be **archived**; locally-run sessions (CLI, VS Code, JetBrains, Copilot app) can be **deleted**.
- `copilot update` stages a new build; the version only changes after every Copilot process/terminal is closed and relaunched.
