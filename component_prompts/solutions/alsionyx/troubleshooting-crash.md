# LV2 Plugin SIGSEGV Troubleshooting (C# Host via lilv)

Important: keep updating this document as you try things and if they work or not.
Keep adding logging to the ratatouille plugin until you discover the reason.

## Context

This documents a SIGSEGV (exit 139) experienced when loading an LV2 plugin from a
C# console app that uses lilv (via P/Invoke) as its plugin host. The techniques and
findings apply to any C# LV2 host, not just this project. Plugin-specific observations
for **Ratatouille** are called out where they differ from general LV2 behaviour.

**Stack**: .NET 9 · lilv (C, P/Invoke) · liblv2worker (C) · ARM64 Linux

**Plugin under test**: Ratatouille (`urn:brummer:ratatouille`) — a convolver with FFT
processing that requires `LV2_BUF_SIZE__maxBlockLength` via the options feature. Other
plugins that do not use options or that tolerate a zero block size will not exhibit
Problem 2.

---

## External Source Directories

| Repo | Path |
|------|------|
| ALSA | `/home/pistomp/git/external/alsa-lib` |
| jalv (LV2 host reference) | `/home/pistomp/git/external/jalv` |
| lilv | `/home/pistomp/git/external/lilv` |
| lilv-sharp (.NET wrapper) | `/home/pistomp/git/external/lilv-sharp` |
| lv2 (spec headers) | `/home/pistomp/git/external/lv2` |
| Ratatouille.lv2 | `/home/pistomp/git/external/Ratatouille.lv2` |
| SoundFlow | `/home/pistomp/git/external/SoundFlow` |
| mod-host (LV2 host reference) | `/home/pistomp/git/external/mod-host` |

---

## Symptoms

- Console app running `--load-plugin Ratatouille --timeout 3` exits with code **139** (SIGSEGV).
- No .NET exception is thrown — the process is killed by the OS signal handler.
- All 15 consumer unit tests pass, including a test that explicitly calls `DiscoverAll()` then `Load()`.
- Identical `.so` / `.dll` files are used by both the test runner and the console app (MD5 verified).
- The crash occurs both in realtime SoundFlow mode and in offline WAV mode — it is not a scheduling issue.

Console output at the point of crash:

```
... INFO AppRunner LV2 Loader starting
... INFO PluginDiscoveryService Discovering LV2 plugins...
[Lv2PluginLoader] Creating world
[Lv2PluginLoader] World created: XXXX
... INFO Lv2PluginLoader Discovered 6 LV2 plugins
... INFO PluginDiscoveryService Found 6 LV2 plugin(s)
Found plugin: Ratatouille (urn:brummer:ratatouille)
... INFO PedalboardCommandService Created pedalboard 'main' ...
[Lv2PluginLoader] Reusing world: XXXX
ParallelThread:Convolver fail to set priority
ParallelThread:Convolver fail to set priority

Command exited with code 1
```

The two `ParallelThread:Convolver fail to set priority` lines are non-fatal — they come
from Ratatouille's background threads calling `pthread_setschedparam` without root
privileges. They are printed to unbuffered native `fprintf(stderr)` and appear in both
the passing tests and the crashing console app. They do **not** indicate the thread
startup failed.

---

## How to Reproduce

```sh
# Crash (console app):
cd /home/pistomp/git/internal/Alsionyx/Alsionyx/src/Alsionyx.ConsoleApp.Lv2Loader
dotnet run -- --load-plugin Ratatouille --timeout 3 2>&1
# Expected exit code: 1 (signal 139)

# Passing (unit tests):
cd /home/pistomp/git/internal/Alsionyx/Alsionyx
dotnet test src/Alsionyx.sln
# Expected: all 15 tests pass
```

---

## Key Source Files

### C# host
- Plugin loader (IDisposable, shared world): `Alsionyx.Library.Plugins.Lv2/Native/Lv2PluginLoader.cs`
- Host features and URID map: `Alsionyx.Library.Plugins.Lv2/Native/Lv2HostFeatures.cs`

### Ratatouille plugin (Ratatouille-specific)
- instantiate entry point: `/home/pistomp/git/external/Ratatouille.lv2/Ratatouille/lv2/Ratatouille.cpp` line ~543
- Engine constructor (thread startup): `/home/pistomp/git/external/Ratatouille.lv2/Ratatouille/engine/engine.h` lines ~182-230

### lilv
- `lilv_plugin_instantiate()`: `/home/pistomp/git/external/lilv/src/instance.c`
- DSO open/close (dlopen/dlclose): `/home/pistomp/git/external/lilv/src/lib.c`
- World init/free: `/home/pistomp/git/external/lilv/src/world.c`

### LV2 spec
- Options struct: `/home/pistomp/git/external/lv2/include/lv2/options/options.h`
- Buf-size URIs: `/home/pistomp/git/external/lv2/include/lv2/buf-size/buf-size.h`

### mod-host reference (working C host)
- Single global world + options array: `/home/pistomp/git/external/mod-host/src/effects.c` lines ~4689-4750

---

## What We Tried

### TRIED — Shared lilv world (FIXED Problem 1)

**Problem**: The loader originally created a new `LilvWorld` for each call.
`DiscoverAll()` → `lilv_world_free()` → `Load()` → new world → `lilv_plugin_instantiate()`.

**Why it crashed**: `lilv_world_free()` calls `dlclose()` on every plugin DSO cached in
`world->libs`. On the next `Load()`, `dlopen()` re-ran the plugin's C++ static constructors
into memory that was never fully reset, corrupting global state → SIGSEGV.

**Fix**: `Lv2PluginLoader` refactored to `IDisposable` with a single persistent `_world`
field, created once and freed only in `Dispose()`. This matches the mod-host pattern
(`g_lv2_data` global world, never freed mid-session).

**Result**: ✅ All 15 unit tests pass including `Ratatouill_DiscoverAllThenLoad_ShouldNotCrash`.
❌ Console app still crashes.

---

### TRIED — Verified single world is in use (CONFIRMED, not the cause)

Added `Console.Error.WriteLine` to `GetWorld()` to print the world pointer address.
Confirmed "Reusing world: XXXX" appears in console output — the same world pointer is
used for both `DiscoverAll()` and `Load()`. World create/destroy is not the remaining cause.

**Result**: ✅ Confirmed. ❌ Not the cause of the remaining crash.

---

### TRIED — Verified identical binaries between test and console (CONFIRMED, not the cause)

MD5 hash of `liblv2worker.so` and `Alsionyx.Library.Plugins.Lv2.dll` verified to be
identical between the test runner's package cache and the console app's package cache.

**Result**: ✅ Confirmed identical. ❌ Binary mismatch is not the cause.

---

### TRIED — .NET Console.Error logging to locate the crash (PARTIALLY USEFUL)

Added `Console.Error.WriteLine` immediately before `Lv2HostFeatures.BuildWithWorker()`
and inside `BuildWithWorker()` itself. None of those log lines appeared in crash output.

**Discovery**: `Console.Error` in .NET is a **buffered** `StreamWriter`. When the process
dies from SIGSEGV, the managed buffer is never flushed. Native `fprintf(stderr)` is
unbuffered and survives the crash.

This is why `[Load] Calling BuildWithWorker` never appears, but `ParallelThread:Convolver fail to set priority`
(native fprintf from inside Ratatouille's `instantiate()`) does appear.

**Implication**: `BuildWithWorker` WAS called and `lilv_plugin_instantiate` WAS entered.
The crash is inside `lilv_plugin_instantiate()`.

**Result**: ⚠️ Partially useful — identified buffering issue. Crash is now pinpointed to
inside `instantiate()`.

---

### HYPOTHESIS — URID mismatch causes bufsize == 0 (UNCONFIRMED, most likely)

**Ratatouille-specific**: Ratatouille's `instantiate()` scans the LV2 options feature
array for `LV2_BUF_SIZE__maxBlockLength`. If not found, `bufsize` stays 0, and
`engine.init()` attempts to allocate zero-sized DSP buffers → SIGSEGV.

The `using block size: 512` message (native fprintf, survives crashes) appears in passing
unit tests but is **absent** from the console app crash output. This confirms `bufsize == 0`
in the console app path.

`Lv2HostFeatures` static constructor pre-registers 6 URIs in fixed order:

| Expected URID | URI |
|------|-----|
| 1 | `LV2_PARAMETERS__sampleRate` |
| 2 | `LV2_BUF_SIZE__minBlockLength` |
| 3 | `LV2_BUF_SIZE__maxBlockLength` |
| 4 | `LV2_BUF_SIZE__sequenceSize` |
| 5 | `LV2_ATOM__Float` |
| 6 | `LV2_ATOM__Int` |

The options array writes `key = uridMaxBlock = 3`. But if any code path (e.g.
`DiscoverAll()` indirectly triggering a static initialiser) calls `GetUrid()` for
other URIs before `Lv2HostFeatures` static constructor has run, those URIs get URIDs 1–N
and `maxBlockLength` gets URID N+3. The options array key stays 3, Ratatouille's
`map->map()` returns N+3 — no match — `bufsize == 0`.

**Result**: ❌ Unconfirmed — C# debug logs lost to buffer before the crash. Next action
required to confirm (see below).

---

### NOT THE CAUSE — ARM64 struct padding for LV2_Options_Option

Verified manually and against the spec header:

```c
typedef struct {
  LV2_Options_Context context; // uint32_t  offset  0
  uint32_t            subject; // uint32_t  offset  4
  LV2_URID            key;     // uint32_t  offset  8
  uint32_t            size;    // uint32_t  offset 12
  LV2_URID            type;    // uint32_t  offset 16
  //                  padding              offset 20 (4 bytes)
  const void*         value;   // pointer   offset 24
} LV2_Options_Option;          // total: 32 bytes
```

`OptionEntryBytes = 32` and `Marshal.WriteIntPtr` at offset 24 are correct.
**Result**: ✅ Not the cause.

---

### NOT THE CAUSE — Real-time audio scheduling

The crash also occurs with `--wav-file` (offline processing, no real-time audio thread).
**Result**: ✅ Not the cause.

---

### NOT THE CAUSE — DI container (Autofac SingleInstance)

`Lv2PluginLoader` is registered as `SingleInstance`; both `DiscoverAll()` and `Load()`
resolve the same instance — consistent with how the diagnostic unit test uses it directly.
**Result**: ✅ Not the cause.

---

## Output Reference Table

| Message | Source | Unit test | Console app |
|---------|--------|-----------|-------------|
| `[Lv2PluginLoader] Reusing world: XXXX` | C# buffered | ✅ | ✅ (flushed before crash) |
| `[Load] Calling BuildWithWorker ...` | C# buffered | ✅ | ❌ lost to buffer |
| `[URID] map(...) = ...` | C# buffered | ✅ | ❌ lost to buffer |
| `using block size: 512` (Ratatouille) | native fprintf | ✅ | ❌ absent (bufsize==0) |
| `ParallelThread:Convolver fail to set priority` x2 | native fprintf | ✅ | ✅ |
| `[lv2worker] activate: ...` | C# buffered | ✅ | ❌ lost / not reached |
| Exit code | — | 0 | 139 |

---

## Next Steps

### Step 1: Make .NET logs survive a crash

Set `AutoFlush = true` on `Console.Error` at app startup so all buffered writes flush
immediately. Add to `Program.cs` or `AppRunner` before any other code runs:

```csharp
((StreamWriter)Console.Error).AutoFlush = true;
```

This requires no package rebuild — only a change in the consumer app.

### Step 2: Confirm or rule out URID mismatch

With auto-flush enabled, run the console app again. The `[URID] map(...)` lines already
in `MapUri` will now survive. Check:

- What URID does Ratatouille get for `LV2_BUF_SIZE__maxBlockLength`?
- What value is in options array entry at index 2 (`key` field)?

If they differ → URID mismatch confirmed → apply Step 3.
If they match → `bufsize` is set correctly and the crash is elsewhere → read Ratatouille
source past the options scan for the real crash site.

### Step 3 (if URID mismatch confirmed): Fix options key registration

Stop relying on static constructor execution order. Write option `key` fields in
`BuildWithWorker()` using live `GetUrid()` values at call time rather than at static
init time:

```csharp
// Overwrite key fields just before passing features to lilv_plugin_instantiate:
Marshal.WriteInt32(optArrayPtr + 0 * OptionEntryBytes + 8, (int)GetUrid("http://lv2plug.in/ns/ext/parameters#sampleRate"));
Marshal.WriteInt32(optArrayPtr + 1 * OptionEntryBytes + 8, (int)GetUrid("http://lv2plug.in/ns/ext/buf-size#minBlockLength"));
Marshal.WriteInt32(optArrayPtr + 2 * OptionEntryBytes + 8, (int)GetUrid("http://lv2plug.in/ns/ext/buf-size#maxBlockLength"));
Marshal.WriteInt32(optArrayPtr + 3 * OptionEntryBytes + 8, (int)GetUrid("http://lv2plug.in/ns/ext/buf-size#sequenceSize"));
```

### Alternative: Add debug prints directly to Ratatouille source (Ratatouille-specific)

In `Ratatouille.cpp` at the options scan loop (~line 589) to get native-side URID values:

```cpp
LV2_URID bufsz_max = self->map->map(self->map->handle, LV2_BUF_SIZE__maxBlockLength);
fprintf(stderr, "[Ratatouille] bufsz_max=%u atom_Int=%u\n", bufsz_max, atom_Int);
for (const LV2_Options_Option* o = options; o->key; ++o)
    fprintf(stderr, "[Ratatouille] option: key=%u type=%u size=%u\n", o->key, o->type, o->size);
```

```sh
cd /home/pistomp/git/external/Ratatouille.lv2
make
cp Ratatouille.lv2/Ratatouille.so ~/.lv2/Ratatouille.lv2/
```
