# Phase: audio_visualization

## Scope
Data library for rolling metrics history, frequency spectrum diff, gain normalization, and spectrum overlay. No GUI, no hardware dependencies. GUI rendering is covered in phase-application_gui.md.

## Existing Code Analysis
Spectrogram - C:\git\external\audio_visualization\Spectrogram. 
SpectrumNet (c:\git\external\audio_visualization\SpectrumNet) — .NET 8 WPF:
SpectrumMath: gain normalization with GainParameters (MinDb, MaxDb, AmplificationFactor) and scale conversion (Linear, Logarithmic, Mel, Bark, ERB). Reuse: normalization math pattern.
ISpectrumRenderer: pluggable renderer interface with SkiaSharp. Reuse: abstraction design for application_gui phase.
StereoProcessor: stereo-to-mono modes (Mid, Left, Right, Max, RMS). Reuse: channel mixing pattern.
FftSharp + FftSharp.Windows: FFT with windowing (Hann, Hamming, Blackman, Kaiser, FlatTop). Reuse: windowing dependency.
Dependencies: NAudio 2.2.1, FftSharp 2.2.0, SkiaSharp 3.119.1, CommunityToolkit.Mvvm.

Csharp-Data-Visualization (c:\git\external\audio_visualization\Csharp-Data-Visualization) — .NET 6 WinForms:
Rolling buffer pattern: fixed-size double[] rotated in place, ScottPlot Plot.AddSignal() for live scrolling. Reuse: rolling circular buffer pattern for MetricsHistory.
FftSharp examples for windowed FFT. Reuse: windowing approach.
Dependencies: NAudio 2.0.1, FftSharp 1.1.5, ScottPlot 4.1.45.

No existing repo provides: per-bin spectrum difference, multi-source overlay, or stored-slice WAV file comparison. These are custom implementations.
SkiaSharp rendering and ScottPlot integration are deferred to phase-application_gui.md.

## Alsionyx.Library.Audio.Visualization
net9.0. Depends on Alsionyx.Library.Audio.Analysis only. No GUI, NAudio, or CSCore dependencies.

MetricsHistory:
void Add(AnalysisResult result, DateTimeOffset timestamp) — appends to circular buffer.
IReadOnlyList<MetricsSnapshot> GetWindow(TimeSpan duration) — returns snapshots within duration from now.
MetricsSnapshot: DateTimeOffset Timestamp, AnalysisResult Result. Plain class.
Configurable window capacity (default 60 seconds at one snapshot per block).

SpectrumDiff:
static double[] Compute(double[] psdA, double[] psdB) — returns per-bin (psdA[i] - psdB[i]) in dB. Arrays must be same length.

SpectrumNormalizer:
static double[] Apply(double[] psd, double gainOffsetDb) — returns new array with gainOffsetDb added to every bin.

SpectrumOverlay:
void Update(string key, double[] psd) — stores latest spectrum for named source.
IReadOnlyDictionary<string, double[]> GetLatest() — current snapshot per source.

ISpectrumSource (interface):
string Key { get; }
event Action<double[]> SpectrumReady.

## Unit Tests
MetricsHistory: add N results, GetWindow covering all returns N; window covering only recent returns subset.
SpectrumDiff: psdA[i]=10.0, psdB[i]=9.0 returns result[i]=1.0.
SpectrumNormalizer: +6dB offset shifts all bins by 6.0.
SpectrumOverlay: two sources updated, GetLatest returns both with correct values.

## Spectrogram Diff Export

### Purpose

Generate a time×frequency PNG image showing the EQ difference between two WAV files. Colour intensity represents the magnitude of dB difference per frequency bin across the length of the recording. Uses SkiaSharp for PNG rendering (Windows-compatible, no GUI framework required). This covers the "use Spectrogram to generate a time based EQ difference" requirement referenced in the Spectrogram C# library at C:\git\external\audio_visualization\Spectrogram.

### Alsionyx.Library.Audio.Analysis

Extend SpectrumDiffFrame: add double[] DbDiffPerBin. Populated by WavFileComparator as 10*log10(psdA[b]) - 10*log10(psdB[b]) per bin per frame. DiffPerBin (linear) remains for existing callers.

### AudioLevels.Simple.ConsoleApp

DiffSpectrogramExporter: void Export(SpectrumDiffFrame[] frames, int sampleRate, int blockSize, string outputPath, double rangeDb = 20.0).
- Image dimensions: frameCount × binCount. Width = one column per FFT frame. Height = frequency bins from ~20Hz to Nyquist.
- Frequency range: bins above 20Hz (skip DC and sub-bass). Linear frequency scale.
- Colour: magnitude of dB diff per pixel mapped 0→black, rangeDb→white. Simple grayscale heatmap.
- Y axis: low frequency at bottom (row 0 = highest frequency bin).
- Writes PNG to outputPath. Creates parent directory if needed.
- NuGet: SkiaSharp 2.88.8.

WavFileComparator.CompareAsync: populate DbDiffPerBin for each frame using SpectrumDbConverter.ToDb on psdA and psdB before subtracting.

Extend CompareOptions: add [Option("spectrogram")] optional string. When set, an exported PNG is saved to that path.

Update CompareCommandHandler: inject DiffSpectrogramExporter. When options.Spectrogram is set, call Export after comparison.

Update ServiceRegistration: register DiffSpectrogramExporter.

### Unit Tests

DiffSpectrogramExporterTests:
- Export with empty frames does not throw.
- Export with two frames and non-zero diffs writes a file with non-zero length.
- Export with all-zero diffs (two identical files) writes a file (no exception).

WavFileComparatorDbDiffTests:
- After CompareAsync, Frames[0].DbDiffPerBin is non-empty and length equals BlockSize/2.
- Two identical WAV files produce DbDiffPerBin values all at or near 0.0.

## Success Criteria
Alsionyx.Library.Audio.Visualization builds with no GUI or hardware dependencies.
audiolvls compare --file-a di.wav --file-b recorded.wav --spectrogram diff.png produces a PNG file.
All unit tests pass using WaveFileDataFactory synthetic data only.
CI passes.
