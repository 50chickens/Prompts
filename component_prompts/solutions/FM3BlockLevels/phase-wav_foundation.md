# Phase: wav_foundation

## Scope
Improve robustness of the audio library layer. Applies to Alsionyx.Library.NAudio.Asio, Alsionyx.Library.Audio.Analysis, and Alsionyx.Library.Audio.WavFile. Not audio visualization. CSCore source at C:\git\external\audio\cscore is the reference for patterns.

## CSCore Patterns to Apply

WriteableBufferingSource pattern (CSCore\Streams\WriteableBufferingSource.cs):
Cross-thread safe ring buffer for audio data. ASIO AudioAvailable callback writes bytes via Write(); downstream reads via IWaveSource.Read(). Eliminates lock contention between the ASIO thread and processing thread. Apply in BlockAccumulator — replace direct float[] hand-off with a WriteableBufferingSource-style ring buffer.

SoundInSource pattern (CSCore\Streams\SoundInSource.cs):
Bridges event-driven audio capture (DataAvailable handler) to a pull-model IWaveSource. Our current ASIO capture raises FramesCaptured events; consumers pull via BlockAccumulator. Review current BlockAccumulator wiring and ensure the hand-off matches this pattern — event fires, writes to buffer, consumer reads at its own rate.

SingleBlockNotificationStream pattern (CSCore\Streams\SingleBlockNotificationStream.cs):
Fires a SingleBlockRead event per block (channels × 1 frame) on every Read(). Informs BlockAccumulator design: block boundaries should align with channel count × blockSize, not with arbitrary Read() call sizes.

FftProvider (CSCore\DSP\FftProvider.cs):
Thread-safe, lock-protected FFT with configurable WindowFunction. Our FftProcessor is a static in-place method. Replace with an instance FftProvider per channel in ThdTestRunner. WindowFunction defaults to None; apply Hann window (WindowFunctions.Hann) for improved THD accuracy.

LoopStream (CSCore\Streams\LoopStream.cs):
IWaveSource wrapper that resets Position = 0 at end-of-stream. Apply in PlayWavRunner so a WAV source loops if the ASIO session duration exceeds the file length. EnableLoop = false terminates naturally.

FluentExtensions.AppendSource (CSCore\FluentExtensions.cs):
Chain composition helper. Use to document and structure the WAV playback source chain: WaveFileReader → ToSampleSource() → GainSource → LoopStream → ToWaveSource().

GainSource (CSCore\Streams\GainSource.cs):
Wraps ISampleSource with float Volume (any value including > 1.0, clipped or unclipped). Use in PlayWavRunner to apply the --level dBFS parameter to the WAV source before handing it to ASIO output. Converts dBFS to linear: Math.Pow(10, dbfs / 20.0).

## Alsionyx.Library.Audio.Analysis Changes

FftProcessor: replace static void Process(double[], double[], int) with an instance FftProcessor class that holds a pre-allocated Complex[] workspace per instance. Reduces GC pressure on per-block processing. Keep the same radix-2 Cooley-Tukey algorithm.
Add HannWindow: static float[] Compute(int size) returning the Hann window coefficients. Apply before FFT in ThdTestRunner.

BlockAccumulator: add a WriteableBufferingSource-style internal ring buffer (float[], not byte[]) to decouple the ASIO callback thread from the processing thread. The ASIO callback writes to the ring; BlockReady fires from the consumer side only when a full block is available.

## Alsionyx.Library.NAudio.Asio Changes

IAsioInputDevice.FramesCaptured event: add channel index to event args so consumers do not need to de-interleave manually. IAsioInputDevice already accepts int[] channelIndices; raise one event per channel index with the de-interleaved float[].
No CSCore dependencies in this library.

## Unit Tests

FftProcessor: instantiate, apply Hann window, process known frequency signal, verify fundamental bin is maximum.
BlockAccumulator: write samples in small chunks; verify BlockReady fires only at blockSize boundary and delivers correct sample count.
GainSource dBFS conversion: -18 dBFS → linear ≈ 0.126; 0 dBFS → 1.0. Verify via WaveFileDataFactory sine + GainSource applied.

## Success Criteria
BlockAccumulator passes unit test for boundary alignment.
FftProcessor applies Hann window; unit test confirms fundamental bin dominates.
PlayWavRunner uses GainSource for level control; no direct amplitude multiplication on raw samples.
CI passes.
