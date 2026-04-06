# Phase: application_gui

## Goal

An Avalonia desktop application (`AudioLevels.Comparison.ConsoleApp`) with three analysis modes: Static, Real-time, and Snapshot. The app provides GUI equivalents of all `AudioLevels.Simple.ConsoleApp` command-line options and visualises audio metrics using rolling time-series charts and frequency-spectrum views. The primary goal of the Snapshot mode is comparing "bad sound" vs "good sound" FM3 settings: play the same reference WAV through each scenario, capture the return signal, and produce a per-bin EQ-difference chart showing exactly how the bad setting shapes the frequency response differently.

## Existing Assets Used

`AudioLevels.Comparison.ConsoleApp`: Avalonia application shell (net10.0, Avalonia 11.3.12). Currently an empty window.
`Alsionyx.Library.Audio.Analysis`: FFT, THD, RMS, dBFS, LatencyCalculator, SpectrumDiff, FrequencyAxis, SpectrumDbConverter, BlockAccumulator.
`Alsionyx.Library.Audio.Visualization`: MetricsHistory, MetricsSnapshot, SpectrumOverlay, SpectrumDiff, SpectrumNormalizer, StreamSpectrumSession, ISpectrumSource.
`Alsionyx.Library.NAudio.Asio`: IAsioDeviceEnumerator, IAsioInputDevice (StartWithPlayback, Start, Stop).
`Alsionyx.Library.Audio.WavFile`: IWavFileReader, IWavFileWriter.
SkiaSharp: already referenced in AudioLevels.Simple.ConsoleApp for DiffSpectrogramExporter.
SpectrumNet (c:\git\external\audio_visualization\SpectrumNet): SpectrumMath gain-normalisation pattern and ISpectrumRenderer abstraction — reuse for SpectrumView rendering math.
Csharp-Data-Visualization (c:\git\external\audio_visualization\Csharp-Data-Visualization): rolling circular buffer + ScottPlot scrolling signal pattern — reuse for RollingMetricsView.

## New Project: Alsionyx.Library.Audio.Visualization.Avalonia

net9.0. Dependencies: Alsionyx.Library.Audio.Visualization, Avalonia, SkiaSharp.Views.Avalonia, ScottPlot.Avalonia, CommunityToolkit.Mvvm.

Reusable Avalonia controls:

`DeviceSelectorView` (UserControl): lists ASIO driver names from IAsioDeviceEnumerator. Checkbox list of channels per device. Exposes `SelectedInputs` (IReadOnlyList of DeviceName + int[] Channels) as observable property. Dynamically updates when devices are added or removed.

`SpectrumView` (UserControl): SKCanvasView (SkiaSharp.Views.Avalonia). Accepts `IReadOnlyDictionary<string, double[]>` from SpectrumOverlay.GetLatest. Renders one polyline per named source. Log-frequency X axis (20 Hz–Nyquist), dB Y axis. Distinct colour per source key. Dynamically adds or removes lines as keys appear or disappear. Gain normalisation via SpectrumMath pattern from SpectrumNet.

`RollingMetricsView` (UserControl): AvaPlot (ScottPlot.Avalonia). SignalPlotHighPerformance series for dBFS, RMS, THD, Latency. Scrolling window of last N seconds (configurable, default 30 s). Refreshed via DispatcherTimer at UpdateRateHz. One dBFS series per input channel.

`SnapshotSpectrumView` (UserControl): SKCanvasView. Renders two averaged spectra (Source A and Source B in dB) and their per-bin difference. Log-frequency X axis. Three labelled polylines. Horizontal zero-line on the diff series. Amplitude range auto-ranged to data, rounded to nearest 10 dB.

## AudioLevels.Comparison.ConsoleApp

Add project reference to Alsionyx.Library.Audio.Visualization.Avalonia. Target net10.0 (unchanged).

MVVM via CommunityToolkit.Mvvm. ObservableProperty, RelayCommand, no code-behind logic.

`DeviceConfigViewModel`: OutputDeviceName, SelectedInputs (list), SourceWavPath, DurationSeconds, UpdateRateHz (default 20), BlockSize (default 4096).

`MainViewModel`: SelectedMode (enum Static/Realtime/Snapshot), SessionActive, Start and Stop RelayCommands, DeviceConfig property. Start command validates: device names found by IAsioDeviceEnumerator, WAV file exists, at least one input channel selected. Disabled when SessionActive is true.

`StaticAnalysisViewModel`: consumes MetricsReady events. Owns MetricsHistory. Passes snapshots to RollingMetricsView. Rolling window duration is configurable from UI.

`RealtimeAnalysisViewModel`: consumes SpectrumReady and MetricsReady events. Owns StreamSpectrumSession. Passes spectrum overlay to SpectrumView. Passes per-channel dBFS (plus source WAV dBFS reference line) to RollingMetricsView.

`SnapshotAnalysisViewModel`: after session stop, holds averaged PsdA and PsdB (accumulated per BlockAccumulator during session). SourceAKey and SourceBKey dropdowns (populated from selected input channels). NormalizeB flag (applies SpectrumNormalizer.Apply before diff). Passes built SpectrumReport to SnapshotSpectrumView.

Main layout: TabControl with three tabs: Static | Real-time | Snapshot. Shared header bar: device config panel (DeviceSelectorView), WAV file picker button, Start/Stop buttons, status label (idle/running/error). Metric status bar visible when SessionActive: four TextBlock displays for Latency (ms), dBFS, RMS, THD refreshed at UpdateRateHz.

`AudioSessionService`: starts and stops the ASIO session. Fires MetricsReady(AnalysisResult) and SpectrumReady(string key, double[] psd) events. Source WAV played via IAsioInputDevice.StartWithPlayback. Multi-channel capture deinterleaved per channel — one BlockAccumulator per channel. Registered as singleton. Injected into all ViewModels.

## Analysis Mode Details

### Static Analysis

Play baseline WAV to output device. Capture N input channels. Chart: RollingMetricsView scrolling window showing Latency, dBFS, RMS, THD. One dBFS series per input channel plus one reference dBFS line tracking source WAV playback level. Data point per block, chart refresh at UpdateRateHz.

### Real-time Analysis

Chart 1: RollingMetricsView — dBFS per channel plus source WAV reference. All series on same chart. Chart 2: SpectrumView — live frequency spectrum overlay of all active channels simultaneously. Diff toggle: checkbox to also show (channel A − channel B) diff polyline using SpectrumDiff.Compute. StreamSpectrumSession.SnapshotReady drives both charts.

### Snapshot Analysis

Full session captured until Stop. After Stop, AudioSessionService publishes final accumulated PsdA and PsdB per channel pair. SnapshotAnalysisViewModel computes averaged spectra, applies optional normalisation, calls SpectrumDiff.Compute per bin. SnapshotSpectrumView renders the result as a standard EQ-style chart: Source A (dB), Source B (dB), Diff (A − B dB). Frequency range 20 Hz – Nyquist, log scale. This is the primary visualisation for comparing "bad setting" and "good setting" FM3 scenarios.

## NuGet Additions

Alsionyx.Library.Audio.Visualization.Avalonia: Avalonia, ScottPlot.Avalonia, SkiaSharp.Views.Avalonia, CommunityToolkit.Mvvm.
AudioLevels.Comparison.ConsoleApp: ScottPlot.Avalonia, SkiaSharp.Views.Avalonia, CommunityToolkit.Mvvm.

## Unit Tests

`AudioLevels.Visualization.Avalonia.Tests` (net9.0, NUnit, NSubstitute, Avalonia.Headless for headless ViewModel testing — no rendering assertions):

DeviceConfigViewModelTests: empty OutputDeviceName → Start command not executable. Empty SourceWavPath → Start not executable. All fields valid → Start executable.

StaticAnalysisViewModelTests: MetricsReady event fires N times → MetricsHistory contains N snapshots. GetWindow(full duration) returns N results.

RealtimeAnalysisViewModelTests: SpectrumReady fires for two keys → OverlayViewModel.Keys contains both. SpectrumReady fires for unknown key → new key added dynamically.

SnapshotAnalysisViewModelTests: after session stop with N blocks per channel, AveragedPsdA and AveragedPsdB are non-empty with length blockSize/2. NormalizeB applied when flag set — SnapshotSpectrumView receives shifted values. SourceAKey = SourceBKey → diff series is all zeros.

## Success Criteria

`AudioLevels.Comparison.ConsoleApp` launches without error.
All three mode tabs are present and selectable.
Start and Stop commands are enabled and disabled correctly based on validation and session state.
Metric bar updates at 20 Hz when session is active.
Static tab: rolling chart scrolls with latency, dBFS, RMS, THD series.
Real-time tab: live spectrum polylines and dBFS rolling chart update.
Snapshot tab: averaged EQ-diff chart rendered after session stop.
All unit tests pass. CI passes.
