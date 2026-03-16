# Phase: audio_metrics

## Scope
Full audio metrics pipeline: THD, latency, dBFS, RMS per channel. run verb operational with level sweep and JSON log output.

## Implementation
Implement SineWaveProvider (IWaveProvider, float32 PCM, 48kHz, configurable amplitude/frequency).
Implement IAsioOutputDevice and IAsioInputDevice with AudioAvailable callback and per-channel deinterleaving.
Port FftProcessor from audiosignalanalyzer fft.cpp (radix-2 Cooley-Tukey, in-place).
Implement PsdCalculator (dual-FFT from thd_analyzer.cpp).
Implement ThdCalculator, RmsCalculator, DbfsCalculator, LatencyCalculator.
Implement BlockAccumulator.
Implement ThdTestRunner.
Implement run verb.

## ThdTestRunner
Constructor: IAsioOutputDevice, IAsioInputDevice, BlockAccumulator, ThdCalculator, RmsCalculator, DbfsCalculator, LatencyCalculator, PsdCalculator, ILog<ThdTestRunner>.
async Task<ThdTestResult> RunAsync(RunOptions, CancellationToken).
Computes 5 evenly-spaced output levels between OutputMinLevelDbfs and OutputLevelDbfs.
Each level runs for duration/5 seconds. SineWaveProvider.Amplitude mutated atomically between segments.
OnBlockReady: run analysis pipeline, stamp OutputLevelDbfs on AnalysisResult, accumulate, log.
CancellationToken stop: exits level loop, stops and disposes devices, returns ThdTestResult.
Same-device full-duplex via IAsioInputDevice.StartWithPlayback; separate devices via IAsioOutputDevice.StartWithProvider + IAsioInputDevice.Start.

## run verb options
--output-device (required)
--input-device "FM3:1,3" (required, name:comma-separated channel indices)
--duration (default 5s)
--frequency (default 1000)
--log-interval-pct (default 20)
--output-level (default -18dBFS)
--output-min-level (default -36dBFS)
--output-channel (1-based, default 1)

## Unit Tests
DI container resolves all registered services.
FftProcessor: unit impulse input produces expected frequency domain output.
ThdCalculator: pure sine PSD returns THD near zero; synthetic PSD with harmonics returns expected ratio.
RmsCalculator: constant amplitude signal returns expected value.
DbfsCalculator: full-scale RMS (1.0) returns 0dBFS; half-scale returns expected negative value.
LatencyCalculator: correlated signals with known offset returns correct latency in ms.
BlockAccumulator: frames smaller than block size do not raise event; exact block size raises event.
SineWaveProvider: Read() fills buffer with float32 matching expected amplitude and frequency.

## Success Criteria
run verb with --output-device "ASIO HX Stomp" --input-device "FM3 USB Audio Device:1,3" runs for 5 seconds and produces latency, dBFS, RMS and THD for channels 1 and 3. JSON log written. CI passes.
