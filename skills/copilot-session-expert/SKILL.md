---
name: copilot-session-expert
description: Read, search, export, import and repair GitHub Copilot chat session storage on Windows. Use when a chat or session will not open, when sessions must be inspected, backed up, restored or deleted, when searching session history by keyword or property, or when writing a script against ~/.copilot or the VS Code agent-host catalogue.
---

# Copilot session expert

Everything here was verified on Windows against VS Code 1.142.0 with the bundled Copilot Chat 0.70.0 and the
Copilot CLI, October 2026. Schemas drift between releases: re-check a column or a JSON key before you rely on
it, and prefer reading to guessing.

## 1. Where the data lives

Two stores exist and they are not copies of each other. The CLI owns the transcript; VS Code owns a catalogue
that points at it.

```text
%USERPROFILE%\.copilot\                     CLI home
  settings.json                             absent means remote sync on: "remote":"on", "remoteExport":true
  session-state\<session-id>\               one folder per CLI session, the real transcript and its files
  session-store.db                          CLI session catalogue (sessions table) plus -wal and -shm
  chats\  logs\  ide\  servers\             CLI runtime data
  installed-plugins\  plugin-data\          plugin state
  sidebar-sessions-state\                   sidebar session state
  .restore-backups\                         written by Restore-CopilotSession.ps1 before it replaces anything

%APPDATA%\Code\User\                        VS Code user data
  globalStorage\agent-host.db               agent-host catalogue: sessions, chats, per-session state
  globalStorage\agent-host-storage.json     small key-value file: reconciliation cursors, recent sessions
  globalStorage\agent-host-config.json      agent-host configuration
  globalStorage\state.vscdb                 global state, ItemTable(key, value)
  globalStorage\emptyWindowChatSessions\    legacy local chats opened with no folder, one .jsonl per chat
  globalStorage\storage.json                profile associations, workspace ids
  workspaceStorage\<id>\state.vscdb         per-workspace state, ItemTable(key, value)
  workspaceStorage\<id>\chatSessions\       legacy local chat oplogs, one .jsonl per chat
  profiles\<id>\settings.json               per-profile settings, override the default User file
```

`~/.copilot/session-state/<id>/` holds the transcript, a `files/` subtree of copied workspace files, and
`workspace.yaml`. Resume state also leaves `inuse.*` and `*.workspace-fork.lock` files, which must be deleted
before a restored session will load.

## 2. Session identity: URI schemes

A session or chat is addressed by a URI, and the scheme decides which agent answers for it. This is the single
most useful fact in the whole format, because a wrong scheme is exactly what "no agent" errors mean.

| URI form | Meaning |
|---|---|
| `copilotcli:/<uuid>` | session owned by the Copilot CLI, bridged through the agent host |
| `ahp-session:/<uuid>` | agent-host protocol session |
| `ahp-chat:/<uuid>` | a chat inside such a session, usually a subagent or peer chat |
| `ahp-chat://default/<base64>` | the default (root) chat of a session |
| `vscode-chat-session:` | legacy local chat, the format behind `chatSessions\*.jsonl` |
| `file:///` | placeholder, not an agent scheme: an empty-window workspace URI, and the value that breaks a chat |

The default chat URI is derived, never invented:

```text
ahp-chat://default/ + Base64(UTF8(session-uri)), '=' padding trimmed
copilotcli:/56294529-702b-40a6-b5a0-880440be6541
  -> ahp-chat://default/Y29waWxvdGNsaTovNTYyOTQ1MjktNzAyYi00MGE2LWI1YTAtODgwNDQwYmU2NTQx
```

Workspace URIs inside stored JSON are percent-encoded, lower-cased drive letter:
`file:///c%3A/git/internal/Prompts`.

## 3. The agent-host catalogue: agent-host.db

SQLite. Tables observed:

`sessions`, `sessions_v2`, `session_chat_catalogs`, `session_chats`, `chats_v2`, `session_state`,
`session_state_values`, `session_folder_state`, `session_chat_state`, `chat_row_mirror`,
`worktree_co_owners`, `pending_worktree_removals`, `metadata`.

Two generations coexist. `sessions` and `session_chats` are the older shapes; `sessions_v2` and `chats_v2`
carry the payload and are the ones that matter. The same session can be present in both, which is why a
targeted `UPDATE` must be scoped by `session_uri` or `owner_session_uri` and not by row identity.

| Table | Columns that matter |
|---|---|
| `sessions_v2` | `session_uri`, `provider`, `start_time`, `external`, `registration_source`, `session_generation`, `source_revision`, `payload_version`, `payload_hash`, `verified`, `payload`, `is_chat_backing`, `modified_time` |
| `sessions` | `session_uri`, `provider`, `start_time`, `external`, `registration_source`, `modified_time` |
| `chats_v2` | `chat_uri`, `owner_session_uri`, `chat_order`, `storage_resource`, `parent_chat`, `provider_data`, `origin`, `is_read`, `archived`, `inherited_turn_id`, `working_directories`, `metadata`, `metadata_hash`, `ownership_revision`, `metadata_revision`, `tombstoned`, `origin_session_uri` |
| `session_chat_catalogs` | `session_uri`, `revision`, `legacy_mirrored_revision`, `authority_version`, `default_chat_uri`, `session_generation`, `normalization_source_revision`, `normalization_payload_hash`, `projected_revision` |
| `session_chats` | `session_uri`, `chat_uri`, `chat_order`, `provider_data`, `origin`, `inherited_turn_id`, `archived`, `is_read` |
| `session_state_values` | `session_uri`, `key`, `value`, `revision` |
| `chat_row_mirror` | `session_uri`, `chat_uri`, `kind`, `base` - usually empty in current builds |

Two columns are routinely confused and must not be:

`chat_uri` is the chat's identity. `storage_resource` is where its turns live. For the root chat of a CLI
session, `storage_resource` equals the session URI, so a repair that rewrites `chat_uri` must not rewrite
`storage_resource` for that row.

Healthy root chat row of a CLI session:

```text
chat_uri         ahp-chat://default/Y29waWxvdGNsaTovNTYyOTQ1MjktNzAyYi00MGE2LWI1YTAtODgwNDQwYmU2NTQx
chat_order       0
storage_resource copilotcli:/56294529-702b-40a6-b5a0-880440be6541
parent_chat      (null)
```

`session_state_values.key` names observed: `agentHost.changes`, `configValues`,
`copilot.project.displayName`, `copilot.project.resolved`, `copilot.project.uri`, `isArchived`, `isRead`,
`multiRoot`, `sessionArtifacts`, `vscode.folderPicker`. `agentHost.changes` is the tile's diff stat,
`{"additions":26,"deletions":0,"files":1}`. `sessionArtifacts` is a JSON array whose entries carry a `chat`
field in the canonical `ahp-chat://default/...` form, which makes it a cheap witness of what the chat URI
should be.

## 4. JSON shapes

`sessions_v2.payload` (payloadVersion 2):

```json
{
  "data": {
    "_meta": { "git": { "baseBranchName": "main", "branchName": "main",
                        "defaultBranchName": "main", "defaultRemoteBranchName": "origin/main",
                        "githubHeadOwner": "<owner>", "githubOwner": "<owner>",
                        "githubRepo": "<repo>", "hasGitHubRemote": true } },
    "changes": { "additions": 26, "deletions": 0, "files": 1 },
    "chats": [
      { "archived": false, "interactivity": "full", "isRead": true, "kind": "default",
        "order": 0, "origin": { "kind": "user" },
        "summary": "<chat title>", "titleSource": "auto", "uri": "ahp-chat://default/..." }
    ],
    "isArchived": false,
    "isChatBacking": false,
    "isRead": true,
    "modifiedTime": 1792639636035,
    "project": { "displayName": "Prompts", "uri": "file:///c%3A/git/internal/Prompts" },
    "summary": "<chat title>",
    "titleSource": "auto",
    "workingDirectories": [ "file:///c%3A/git/internal/Prompts" ]
  },
  "payloadVersion": 2
}
```

`chats_v2.metadata`:

```json
{ "data": { "interactivity": "full", "summary": "<chat title>", "titleSource": "auto" }, "metadataVersion": 1 }
```

`chats_v2.origin`, for a chat a user started and for one a tool started:

```json
{ "kind": "user" }
{ "kind": "tool", "toolCallId": "call_00_xtJqBlIXEKtmYWfoRkX26490", "chat": "file:///" }
```

Peer and subagent chats appear in `chats_v2` with `kind` of `peer`, `order` above 0, `interactivity` of
`hidden`, and `parent_chat` pointing at the chat that spawned them. Their URIs are `ahp-chat:/<uuid>` and their
`storage_resource` mirrors the URI.

`agent-host-storage.json`:

```json
{
  "agentHost.catalogReconciliation.verificationVersion": 3,
  "agentHost.catalogReconciliation.lastVerification": 1792647375046,
  "agentHost.catalogReconciliation.chatMigrationCursor": "ahp-session:/<uuid>",
  "agentHost.catalogReconciliation.verificationCursor": "ahp-session:/<uuid>",
  "agentHost.catalogReconciliation.cursor": "copilotcli:/<uuid>",
  "recentLocalSessionUpdates": [
    { "session": "ahp-session:/<uuid>", "modifiedTime": 1792642908324 },
    { "session": "copilotcli:/<uuid>", "modifiedTime": 1792639636035 }
  ]
}
```

Legacy local chat oplog, first record only; later lines append the same shape with higher `kind` values:

```json
{"kind":0,"v":{"version":3,"creationDate":1792318422978,"initialLocation":"panel",
 "responderUsername":"GitHub Copilot","sessionId":"<uuid>","hasPendingEdits":false,
 "requests":[],"pendingRequests":[]}}
```

## 5. Encoding and invariants

`payload_hash` is the lower-case hex SHA-256 of the `payload` text, byte for byte. Any payload rewrite must
recompute it in the same transaction. `session_chat_catalogs.normalization_payload_hash` mirrors the same value
and must be moved with it when it matches the old hash.

`metadata_hash` follows the same idea for `chats_v2.metadata`.

Timestamps are epoch milliseconds: `modifiedTime`, `start_time`, `creationDate`, `lastVerification`.

Base64 for chat URIs is standard alphabet, `=` padding removed, of the UTF-8 session URI.

Percent-encoding applies to every workspace URI in stored JSON; a literal `:` and `\` never appear.

Ordinals matter: transcripts and payloads are JSON with numeric `order` fields, not append position.

## 6. Failure signatures

`No agent for session: <uri>`, shown as "Couldn't open session" in the Agents window: the chat or session URI
has no owning agent. Almost always a placeholder `file:///` written by a catalogue migration where the chat
should have carried `ahp-chat://default/...`. The rest of the session is usually intact.

A chat that opens with an empty transcript after a URI repair means the identity was fixed but
`storage_resource` no longer resolves; the turns still live under the CLI session id.

"Being used by another process" on `agent-host.db` means VS Code or the agent host holds it. Reads must open
shared; writes need the editor closed, because the catalogue is cached in memory and a write under a running
editor is lost or overwritten.

A session appearing twice with different fields is not corruption: it is the `sessions` and `sessions_v2`
generations, or two schema versions of the same row, after an upgrade.

## 7. Recipes

Tools already exist. `C:\git\internal\chat-import-specifications\scripts\` holds a module and a script per job,
all PowerShell 7, all using `winsqlite3.dll` through P/Invoke because Windows ships no `sqlite3.exe`. Read
`scripts\README.md` there first; do not write a new one-off.

| Job | Use |
|---|---|
| List sessions in a folder or archive, restore one or all, keep the original id | `Restore-CopilotSession.ps1` with `-List`, `-WhatIf`, `-Verify`, `-PathMap`, `-ExcludeFiles`, `-NoSessionStore`, `-NoAgentHost`, `-NoCaches`, `-RegisterCliInAgentHost`, `-UpdateWorkspaceCache` |
| Read or write one `ItemTable` key | `Get-ChatStateValue.ps1`, `Set-ChatStateValue.ps1`, `Get-ChatStateKeys.ps1` |
| Ad-hoc SQL | `Invoke-ChatSqlQuery.ps1` (read), `Invoke-ChatSqlCommand.ps1` (parameterised write, refuses while Code runs) |
| Print a local chat transcript | `Show-ChatSessionLog.ps1` |
| List CLI sessions and their metadata | `Get-CopilotCliSessions.ps1` |
| Give a broken chat its correct URI | `Repair-ChatSessionUri.ps1` |
| Export-only material into a local chat | `Convert-ChatExportToLocal.ps1`, `New-ChatSessionFromExport.ps1` |

Searching, without opening the editor:

```text
chats_v2.metadata LIKE '%term%'               chat titles
sessions_v2.payload LIKE '%term%'             session titles, project names, chat summaries
session_state_values.value LIKE '%term%'      diff stats, project uri, artifact references
~/.copilot/session-state/<id>/                files on disk: workspace.yaml, transcript, files/
```

Narrow to one session first, then read that session's rows. Never iterate the whole catalogue when a
`WHERE session_uri = ?` will do.

Export and import paths that do not touch the catalogue: "Chat: Export Chat..." in the Command Palette writes
the transcript as JSON; `Convert-ChatExportToLocal.ps1` rewrites per-request agent metadata
(`agent-host-copilotcli` to `github.copilot.editsAgent`, `vscode.agent-host` to `GitHub.copilot-chat`) so a
local chat can be created from it.

## 8. Repairing a chat whose URI has no agent

Worked example, verified end to end. The chat was recorded in `chats_v2` with `chat_uri = 'file:///'`, its 414
subagent chats had `parent_chat = 'file:///'`, and `session_chat_catalogs.default_chat_uri` was `file:///`.

1. Derive the replacement from the session URI, not from the chat row:
   `ahp-chat://default/` plus base64 of `copilotcli:/7f3e4a9f-bee0-46aa-a91a-3b50ecccd645`.
   Cross-check it against `sessionArtifacts` in `session_state_values`, which already held the same string.
2. Close VS Code, then copy `agent-host.db` to a timestamped `.bak` beside it.
3. In one transaction: set the root `chats_v2.chat_uri`, bump `metadata_revision`, set `parent_chat` on every
   child from the old URI to the new one, update `chat_row_mirror` if it has rows, and set
   `session_chat_catalogs.default_chat_uri` with `revision`, `legacy_mirrored_revision` and
   `projected_revision` each incremented. Do not touch `storage_resource`: for the root chat it is the session
   URI, not the chat URI, so the update matches nothing and that is correct.
4. Rewrite `sessions_v2.payload`: the chat's `uri` inside `data.chats[]`, plus any `origin.chat` pointing at the
   old URI. Reserialize, recompute `payload_hash`, and update `normalization_payload_hash` when it matched the
   old hash.
5. Rewrite `localAgentHost.cachedSessions.v4` in `globalStorage\state.vscdb` if it still holds the old URI.
6. Verify by reading back `default_chat_uri`, the root `chat_uri`, and a count of children whose `parent_chat`
   equals the new URI.

Row arithmetic from that repair, useful as a self-check: 416 changed rows is 1 root URI, 414 children,
1 catalogue default, and 0 for `storage_resource` and `chat_row_mirror`.

## 9. Session deletion and sync

Local deletion does not remove the synced copy. Inside `copilot`, `/session delete <id> --yes` deletes the
local session and asks to delete the synced one; `/session delete-all` and `/session prune --older-than N` are
local only. Cloud agent sessions can only be archived; `gh agent-task` has no delete. `/chronicle reindex`
re-syncs sessions when authenticated, so do not run it after restoring a batch. To keep a restored session
from reattaching to the cloud, strip `mc_task_id`, `mc_session_id`, `mc_last_event_id` and `remote_steerable`
from `workspace.yaml`.

## 10. Do not

Do not byte-patch a SQLite file. Replacement values differ in length, so an in-place edit corrupts pages; the
catalogue needs a real write.

Do not run a burst of SQLite P/Invoke work on a machine with Defender enabled. Heavy repeated
open/prepare/step across the catalogue is what triggers it here. Read narrowly, write once, and prefer the
existing scripts with their `-WhatIf` previews.

Do not write to the catalogue with the editor running, and do not trust a write that was made that way.

Do not treat the transcript as lost because the catalogue is broken. `~/.copilot/session-state/<id>/` survives
independently, and `copilot --resume <id>` reads it directly.

Do not assume a chat URI from a name. Titles are not unique; two chats can match one `LIKE` pattern. Resolve to
exactly one session URI before changing anything.
