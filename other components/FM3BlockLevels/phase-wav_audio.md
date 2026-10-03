# Phase: wav_audio

## Scope
Replace all NAudio WAV file I/O with CSCore. Build Alsionyx.Library.Audio.Wav. Remove corrupt NAudio WaveFileWriter usage from PlayWavRunner. All live audio card operations remain on NAudio/ASIO.

## CSCore API (NuGet: CSCore)
Reading WAV files:
WaveFileReader(string fileName) — opens file.
WaveFileReader.WaveFormat.SampleRate / Channels / BitsPerSample for format detection.
WaveFileReader.ToSampleSource() returns ISampleSource.
ISampleSource.Read(float[] buffer, int offset, int count) — returns samples read.

Writing WAV files:
WaveWriter(string fileName, WaveFormat format) — creates file.
WaveWriter.WriteSamples(float[] samples, int offset, int count).
WaveFormat constructor: new WaveFormat(sampleRate, 32, 1, AudioEncoding.IeeeFloat) for IEEE float mono.

## Alsionyx.Library.Audio.Wav
New net9.0 project. Depends on CSCore NuGet only.

IWavFileReader (interface in this library):
WaveFileInfo ReadInfo(string path) — returns format metadata.
IEnumerable<float[]> ReadBlocks(string path, int blockSize) — reads file in blocks.

IWavFileWriter (interface in this library):
void Write(string path, int sampleRate, int channels, IEnumerable<float[]> blocks).

WaveFileInfo: plain class. SampleRate, Channels, BitsPerSample, Duration.
CsWavFileReader: implements IWavFileReader using WaveFileReader + ToSampleSource().
CsWavFileWriter: implements IWavFileWriter using WaveWriter.

## PlayWavRunner Changes
Remove WaveFileWriter (NAudio) and AudioFileReader (NAudio) usage.
Replace with IWavFileReader for reading source WAV format and sample blocks.
Replace with IWavFileWriter for writing recorded channel output.
For ASIO playback: load samples via IWavFileReader.ReadBlocks(), provide to ASIO output via a buffered IWaveProvider adapter. All ASIO device operations remain on NAudio.
Output files written to recordings/ subfolder. Log files in logs/ subfolder.

## WaveFileDataFactory
Static class in AudioLevels.Tests. Generates synthetic float[] audio for unit tests without real WAV files.
float[] GenerateSine(int sampleRate, double frequencyHz, double amplitudeDbfs, int sampleCount).
float[] GenerateNoise(int sampleCount, double amplitudeDbfs).
double[] GeneratePsd(int binCount, int fundamentalBin, double harmonicDecayDb).
No CSCore dependency — returns raw float[] using Math.Sin only.

## File Naming
Source WAV copied: {basename}_Input_{timestamp}.wav in recordings/ subfolder.
Recorded output per channel: {basename}_Output_{deviceName}_ch{N}_{timestamp}.wav in recordings/ subfolder.

## Unit Tests
CsWavFileReader: write a temp IEEE float WAV using CsWavFileWriter, read it back, verify sample count and values round-trip.
CsWavFileWriter: write known float[] to temp file, verify file is readable by CsWavFileReader and matches.
WaveFileDataFactory: GenerateSine returns correct sample count; peak amplitude within expected range.

## Success Criteria
play verb produces a valid non-corrupt WAV file per recorded channel, verifiable by ffmpeg -i <file> -f null NUL returning no errors. do not add any references to ffmpeg or other command line tools in the unit or integration tests. 
No NAudio WAV reading or writing code remains.
IWavFileReader and IWavFileWriter unit tests pass with synthetic data only.
CI passes.
