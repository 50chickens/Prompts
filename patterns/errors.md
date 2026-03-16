
## Error handling.
DO NOT create empty or low-value try-catch blocks. Let exceptions propagate unless specifically handling expected conditions.
Use ArgumentNullException.ThrowIfNull(x) for null checks.
Use string.IsNullOrWhiteSpace(x) for strings.
Guard early. Avoid blanket !.
Choose precise exception types: ArgumentException, InvalidOperationException.
No silent catches. Don't swallow errors. Log and rethrow or bubble up.
