# A queue status report

Print the counts and the items that are blocked, so the state of the queue cannot go stale the way a document
listing them would.

```powershell
$root = Join-Path $PSScriptRoot '..\tasks'

$stages = 'queued', 'in_progress', 'to_be_validated', 'completed', 'ignored'

foreach ($stage in $stages) {
    $path = Join-Path $root $stage
    $count = if (Test-Path -LiteralPath $path) {
        (Get-ChildItem -LiteralPath $path -File -Filter '*.md').Count
    }
    else { 0 }
    Write-Output ("{0,-16} {1}" -f $stage, $count)
}

$inProgress = Join-Path $root 'in_progress'
if (Test-Path -LiteralPath $inProgress) {
    Get-ChildItem -LiteralPath $inProgress -File | ForEach-Object {
        Write-Output ("running: {0}" -f $_.Name)
    }
}
```

What to watch in the output:

- **`to_be_validated` growing** is the signal that the project is accumulating unverified claims. It is the most
  useful number here and the one most often ignored.
- **`in_progress` above a handful** usually means the build lane is oversubscribed.
- **`queued` deep and old** means briefs are going stale faster than they are consumed. Re-read one before
  launching it.

## Annotating an item that should not be taken yet

Prefer a marker in the brief over moving it out of the queue, so the reason travels with the item:

```powershell
$brief = Join-Path $root 'queued\task1.md'
$text = [System.IO.File]::ReadAllText($brief)
if ($text -notmatch 'NOT WORTH TAKING YET') {
    $header = "# NOT WORTH TAKING YET`r`n`r`n<reason, and what would change it>.`r`n`r`n"
    [System.IO.File]::WriteAllText($brief, $header + $text)
}
```

The point is that the next reader learns what was considered and deferred, rather than rediscovering it.

## Determining the next startable item

Do not infer readiness from position in a list. Keep the dependencies explicit:

```powershell
$blocked = @{}

Get-ChildItem -LiteralPath (Join-Path $root 'queued') -File -Filter '*.md' | ForEach-Object {
    $first = Get-Content -LiteralPath $_.FullName -TotalCount 5
    $needs = $first | Where-Object { $_ -match '^Depends on:\s*(.+)$' } |
        ForEach-Object { $Matches[1] }
    if ($needs) { $blocked[$_.Name] = $needs }
}

Get-ChildItem -LiteralPath (Join-Path $root 'queued') -File -Filter '*.md' | ForEach-Object {
    if (-not $blocked.ContainsKey($_.Name)) { Write-Output ("startable: {0}" -f $_.Name) }
}
```

Anything with no unmet prerequisite is startable, regardless of where it sits in the list.
