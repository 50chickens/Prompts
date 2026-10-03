# Phase: audio_stream_comparison

## Scope

Data library and console verb for per-block frequency spectrum comparison between two audio sources. Sources can be WAV files (streaming block-by-block) or live ASIO input channels. No GUI. Rendering is deferred to phase-application_gui.md.

## New Components

### Alsionyx.Library.Audio.Visualization

StreamSpectrumSession: manages N ISpectrumSource instances. Thread-safe; protects overlay and latest-PSD map with a lock.
- void AddSource(ISpectrumSource source) — subscribes to SpectrumReady event.
- void SetDiffPair(string keyA, string keyB, double gainOffsetDb = 0.0) — when both keys have fired, computes diff. gainOffsetDb applied to B via SpectrumNormalizer.Apply before SpectrumDiff.Compute.
- event Action<IReadOnlyDictionary<string, double[]>>? SnapshotReady — raised after each source fires, with the current overlay state.
- event Action<string, string, double[]>? DiffReady — raised when both diff-pair sources have data.
- IReadOnlyDictionary<string, double[]> GetLatest() — current overlay snapshot.
- Dispose() — unsubscribes all handlers.

### AudioLevels.Simple.ConsoleApp

WavFileSpectrumSource: implements ISpectrumSource. Reads WAV file block-by-block using IWavFileReader. Downmixes to mono (channel 0). Fires SpectrumReady with trimmed positive-frequency PSD (length blockSize/2) per block.
- Constructor: (string key, string path, IWavFileReader reader, PsdCalculator psdCalc, int blockSize).
- Task StartAsync(CancellationToken ct) — runs on background Task.

StreamCompareOptions: [Verb("stream-compare")]. Options: --source-a, --source-b (required), --block-size (default 4096), --gain-offset-db (default 0.0), --show-diff (default false).

StreamCompareCommandHandler: creates two WavFileSpectrumSource instances. Creates StreamSpectrumSession. Runs both sources via Task.WhenAll. Logs per-block diff max when --show-diff. Writes JSON log to logs/ subfolder.

## Unit Tests

StreamSpectrumSessionTests:
- AddSource: when source fires, SnapshotReady raised.
- AddSource: overlay contains key after source fires.
- SetDiffPair: DiffReady not raised until both sources have fired.
- SetDiffPair: both fired → DiffReady with correct per-bin diff.
- SetDiffPair with gainOffsetDb: normalisation applied to B before diff.
- Dispose: subsequent source fires do not reach session.

WavFileSpectrumSourceTests:
- Key property returns constructor value.
- StartAsync fires SpectrumReady at least once.
- PSD length per event equals blockSize/2.
- Number of events equals floor(monoSamples/blockSize).

## Success Criteria

All unit tests pass. Alsionyx.Library.Audio.Visualization and AudioLevels.Simple.ConsoleApp build. stream-compare verb accepts two WAV file paths and runs to completion. CI passes.
