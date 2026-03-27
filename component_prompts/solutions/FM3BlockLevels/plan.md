# FM3BlockLevels THD Analysis - Plan

## Goal
A net9.0 console application that sends a 1kHz sine test signal via NAudio/ASIO to HX Stomp channel 1, captures input on FM3 channels 1 and 3 simultaneously, and computes latency, THD, RMS and dBFS per channel. CI pipeline operating correctly is the first completion gate.

## Phases
phase-basic.md
phase-audio_metrics.md
phase-application_profiles.md
phase-wav_foundation.md
phase-wav_audio.md
phase-audio_visualization.md
phase-audio_stream_comparison.md
phase-audio_compare.md
phase-application_gui.md

## Project Structure

FM3BlockLevels.slnx in c:\git\internal\fm3_analysis\src\FM3BlockLevels:

Alsionyx.Library.NAudio.Asio - net9.0. NAudio ASIO device enumeration, output playback and multi-channel capture. NuGet: NAudio (nuget.org).
Alsionyx.Library.Audio.Analysis - net9.0. FFT, THD, RMS, dBFS, latency. No external dependencies.
Alsionyx.Library.Audio.Wav - net9.0. WAV file read/write using CSCore. NuGet: CSCore.
Alsionyx.Library.Audio.Visualization - net9.0. Rolling metrics history, spectrum diff/normalizer/overlay, streaming session manager. No hardware dependencies.
AudioLevels.Simple.ConsoleApp - net9.0 console app. DefaultApplicationBuilder. NuGet: CommandLineParser, Ipscm.Library.Logging.
AudioLevels.Tests - net9.0 NUnit test project. Unit tests only.

Existing project AudioLevels.ConsoleApp is left as-is.

## Reference Source

alsa.net TestToneService (c:\git\internal\alsa.net\src\AlsaSharp\Library\Services\TestToneService.cs) — reference for sine wave generation. Port Math.Sin generation logic only; do not port ALSA interop.
audiosignalanalyzer (c:\git\external\audiosignalanalyzer\src) — reference for FFT and THD analysis. fft.cpp: radix-2 Cooley-Tukey. thd_analyzer.cpp: dual-FFT PSD method (Proakis & Manolakis).
CSCore source (c:\git\external\audio\cscore) — reference for WAV I/O patterns.
Audio visualization (c:\git\external\audio_visualization): SpectrumNet for spectrum rendering and gain normalization patterns; Csharp-Data-Visualization for ScottPlot rolling signal patterns.

## Layering

Alsionyx.Library.Audio.Analysis: zero external dependencies. Core interfaces defined here.
Alsionyx.Library.NAudio.Asio: depends on NAudio only. All audio card operations.
Alsionyx.Library.Audio.Wav: depends on CSCore only. All WAV file operations. CSCore must not be used for audio card access.
Alsionyx.Library.Audio.Visualization: depends on Alsionyx.Library.Audio.Analysis only. No hardware or GUI dependencies.
AudioLevels.Simple.ConsoleApp: application layer, wires all dependencies.

## Alsionyx.Library.NAudio.Asio

IAsioDeviceEnumerator: string[] GetDriverNames() via AsioOut.GetDriverNames().
IAsioOutputDevice: open device by name, accept IWaveProvider, Start/Stop/Dispose.
IAsioInputDevice: open device by name, expose FramesCaptured(float[] samples, int channelIndex) event, Start/Stop/Dispose. Accepts int[] channelIndices; deinterleaves in AudioAvailable callback.
StartWithPlayback(string deviceName, int[] channelIndices, int sampleRate, IWaveProvider provider) — same-device full-duplex.
Start(string deviceName, int[] channelIndices, int sampleRate) — input-only.
SineWaveProvider implements IWaveProvider. float32 PCM, 48kHz. Amplitude and frequency are constructor parameters; Amplitude is mutable for level sweep.

## Alsionyx.Library.Audio.Analysis

FftProcessor: static void Process(double[] re, double[] im, int log2N) — radix-2 Cooley-Tukey in-place.
PsdCalculator: double[][] Compute(double[] channel0, double[] channel1, int log2N) — dual-FFT method, returns psd per channel.
ThdCalculator: double Compute(double[] psd, int sampleRate, int blockSize, int fundamentalIndex).
RmsCalculator: double Compute(float[] samples).
DbfsCalculator: double Compute(double rms).
LatencyCalculator: double ComputeMs(float[] outputSamples, float[] inputSamples, int sampleRate) — cross-correlation peak.
AnalysisResult: double Thd, Rms, DbFs, LatencyMs, FundamentalHz, int ChannelIndex. Plain class, no records.
BlockAccumulator: buffers float[] frames per channel until full block (configurable, default 4096), raises BlockReady(double[] samples).

## AudioLevels.Simple.ConsoleApp

Program.cs wires DefaultApplicationBuilder. Minimal.
Service registration via extension methods: AddAsioAudio(), AddAudioAnalysis(), AddWavProcessing(), AddConsoleApp().
CommandLineParser verbs — no default behaviour, show help when no args provided.
Console output during run: minimal non-metering log. Metering line per channel per block: channel, dBFS, RMS, THD, latency. Periodic summary at configurable interval.
JSON log: one file per run, timestamped, written to logs/ subfolder. Contains metadata and per-interval metric snapshots.
WAV output files written to recordings/ subfolder.

## Testing

AudioLevels.Tests: unit tests only. No integration tests, no skipped tests, no hardware tests.
NUnit + NSubstitute. TestCase for multiple scenarios. No timing assertions. No Task.Delay. No DoesNotThrow tests.
DI container resolution test required for every registration change.

## CI

ci/configs/FM3BlockLevels.json: createNugetPackages: false, excludeCategories: [integration], build verbosity minimal.
Target framework: net9.0. Build config: Debug only.
gh.ps1 for local build: -NugetSourceName "local-nuget-repo".
build-test.ps1 called from GitHub Actions with default -NugetSourceName "github".
dotnet format run and verified before commit. No project-level nuget.config files.

## Signal Routing

ASIO driver names: output = "ASIO HX Stomp", input = "FM3 USB Audio Device". find by either regex or shortest match. use case insensitive. - eg FM3 would match Fractal audio FM3. HX would match HX Stomp.
SineWaveProvider sends 1kHz sine to ASIO HX Stomp channel 1. HX Stomp output jack is cabled to FM3 input jack.
FM3 USB Audio Device channel 1: processed signal after FM3 signal chain.
FM3 USB Audio Device channel 3: unprocessed direct signal at FM3 input jack.

