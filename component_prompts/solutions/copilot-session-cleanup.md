# Copilot session cleanup

Local deletion does not remove the synced copy. Delete it with `/session delete <SESSION-ID> --yes` in `copilot` (not `gh copilot`), answering yes to also delete the synced copy.

## Disable sync first

`~/.copilot/settings.json`, absent meaning `remote: "on"` and `remoteExport: true`:

```json
{ "remote": "off", "remoteExport": false }
```

VS Code `"github.copilot.chat.sessionSync.enabled": false`; profiles override the user file. Per launch: `copilot --no-remote`.

```powershell
Get-Content "$env:USERPROFILE\.copilot\settings.json" -ErrorAction SilentlyContinue
Get-ItemProperty 'HKLM:\SOFTWARE\Policies\GitHubCopilot' -ErrorAction SilentlyContinue
```

## Restore a session locally

```powershell
$src = 'C:\git_temp\_extracted\.copilot-nuc-pc2\.copilot\session-state\<SESSION-ID>'
$dst = Join-Path $env:USERPROFILE '.copilot\session-state\<SESSION-ID>'
Copy-Item -LiteralPath $src -Destination $dst -Recurse -Force
Get-ChildItem -LiteralPath $dst -Filter 'inuse.*' -Recurse -Force | Remove-Item -Force
Get-ChildItem -LiteralPath $dst -Filter '*.workspace-fork.lock' -Recurse -Force | Remove-Item -Force
```

Drop the cloud identity so a resume cannot reattach:

```powershell
$y = Join-Path $dst 'workspace.yaml'
(Get-Content -LiteralPath $y) | Where-Object { $_ -notmatch '^(mc_task_id|mc_session_id|mc_last_event_id|remote_steerable):' } | Set-Content -LiteralPath $y
```

## Decisions

Task pages are `https://github.com/<owner>/<repo>/tasks/<mc_task_id>`; `mc_task_id` is in `session-state/<id>/workspace.yaml` and a deleted record 404s.
`/session delete-all` and `/session prune --older-than N` are local only; synced copies survive.
`/chronicle reindex` re-syncs sessions when authenticated; do not run it after restoring a batch.
Cloud agent sessions can only be archived, and `gh agent-task` has no delete; locally run sessions can be deleted.
`copilot update` changes the version only after every Copilot process and terminal is closed and relaunched.
