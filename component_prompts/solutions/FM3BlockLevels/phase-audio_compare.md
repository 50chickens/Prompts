# Phase: audio_compare (v2 — interactive HTML report)

## Goal

Extend the FM3BlockLevels `compare` verb to generate a self-contained HTML visualization report showing the frequency spectrum and EQ difference between two WAV files. The primary use case is comparing a DI source recording against an FM3 loopback-recorded version, or comparing two FM3 loopback recordings under different profiles (e.g. bad-sound CC#7 assignment vs good-sound reset state).

## Context

The bad audio scenario is caused by FC footswitches assigned CC#7 (MIDI Main Volume) and CC#11 (Expression) transmitting low values to the FM3 on reconnect, reducing output level and changing how the amp model responds to the input signal. The workflow is: play a known DI signal through FM3 USB channels 3/4 (`play` verb with `--record`), then compare the DI source against the recorded output to visualize the EQ/level change.

The `compare` verb and `WavFileComparator` already exist and compute per-block FFT spectrum diff. This phase adds dB conversion, frequency axis labelling, averaged spectrum accumulation per file, and HTML export.

## Existing Code Used

WavFileComparator: per-block PsdCalculator.Compute, SpectrumDiff.Compute, returns ComparisonResult with SpectrumDiffFrame[].
CompareCommandHandler: compare verb handler — currently builds a summary but writes no output file.
SpectrumDiff.Compute: per-bin dB difference.
SpectrumNormalizer.Apply: gain offset.
PsdCalculator.Compute: returns raw power (re^2 + im^2) per bin.

## New Components

### Alsionyx.Library.Audio.Analysis

SpectrumDbConverter: static double[] ToDb(double[] psd) — converts raw FFT power to dB using 10 * Math.Log10(Math.Max(v, 1e-12)) per bin. -120dB floor (1e-12 maps to -120dB).

FrequencyAxis: static double[] Compute(int blockSize, int sampleRate) — returns blockSize/2 values; bins[k] = (double)k * sampleRate / blockSize.

Extend ComparisonResult: add double[] AveragedPsdA, double[] AveragedPsdB, int SampleRate, int BlockSize. All default to empty/zero so existing callers are unaffected.

### Alsionyx.Library.Audio.Visualization

SpectrumReport: plain data class. Fields: string FileA, string FileB, double[] FrequencyHz, double[] SpectrumADb, double[] SpectrumBDb, double[] DiffDb, double MaxDiff, double MinDiff, double MeanDiff, double MedianDiff, int SampleRate, int BlockSize.

SpectrumReportBuilder: SpectrumReport Build(ComparisonResult result, string fileA, string fileB). Applies SpectrumDbConverter.ToDb to AveragedPsdA and AveragedPsdB, calls FrequencyAxis.Compute, trims to N/2 positive-frequency bins. Copies diff stats from ComparisonResult. Bin 0 (DC, 0Hz) is excluded.

SpectrumHtmlExporter: void Export(SpectrumReport report, string outputPath). Generates a self-contained HTML file (no CDN, no external dependencies). Writes two SVG charts inline: spectrum overlay (File A and File B in dB vs log-frequency Hz) and EQ diff (A-B dBdelta vs log-frequency Hz). Frequency axis spans 20Hz to Nyquist, log scale. Includes a summary stats table.

### AudioLevels.Simple.ConsoleApp

Extend WavFileComparator.CompareAsync: accumulate running sum of psdA and psdB per block. Divide by frame count at end and assign to ComparisonResult.AveragedPsdA, AveragedPsdB, SampleRate, BlockSize.

Extend CompareOptions: add [Option("report")] optional string. When set, an HTML file is written to that path.

Update CompareCommandHandler: complete JSON summary output (was missing File.WriteAllText). If options.Report is set, call SpectrumReportBuilder.Build then SpectrumHtmlExporter.Export.

Update ServiceRegistration: register SpectrumReportBuilder and SpectrumHtmlExporter.

## SVG Chart Approach

SpectrumHtmlExporter generates SVG elements directly in C# — fully self-contained, no internet required, no NuGet additions.

Each chart: 900x360 SVG, margins left=70, right=20, top=20, bottom=44.
Frequency x-axis: log10 scale over 20Hz to Nyquist. Grid lines at standard octave points: 31, 63, 125, 250, 500, 1k, 2k, 4k, 8k, 16k Hz.
Y-axis: linear dB, auto-ranged to data min/max rounded to nearest 10dB.
Spectrum overlay chart: two polylines, one per file, distinct colours.
Diff chart: one polyline (A minus B), horizontal zero line, positive region implies A is louder at that frequency.
Bin 0 skipped. Bins above 20kHz clipped.

## Unit Tests

SpectrumDbConverterTests:
- ToDb: input 1e-12 returns -120.0.
- ToDb: input 1.0 returns 0.0.
- ToDb: all values transformed, length preserved.

FrequencyAxisTests:
- Compute(4096, 48000): bin[1] ≈ 11.72Hz (48000/4096), length = 2048.
- Compute(4096, 44100): bin[1] ≈ 10.77Hz.

SpectrumReportBuilderTests:
- Given ComparisonResult with 2-bin AveragedPsdA and AveragedPsdB, Build returns FrequencyHz of correct length, SpectrumADb values in dB range.
- DiffDb values are copied through correctly.

## CI

No new NuGet packages. No new project files. All new code in existing projects. Fits existing CI pattern — dotnet test passes.

## Success Criteria

audiolvls compare --file-a di.wav --file-b recorded.wav --report report.html produces an HTML file.
Open report.html in any browser offline: shows spectrum overlay chart and EQ diff chart, frequency on X axis (log, labelled in Hz), amplitude on Y axis (dB).
All unit tests pass. CI passes.

---

## Extension: Scenario Capture and Multi-Scenario Comparison

### Purpose

Support a workflow where a named scenario definition (JSON) drives a play+record session, producing a labelled output WAV. Multiple scenarios can then be compared against each other and against a reference audio file, generating a multi-spectrum overlay HTML report.

### Scenario JSON format

ScenarioDefinition — file written by the user, read by the `scenario` verb:
```json
{
  "name": "bad-sound",
  "inputWav": "audio/Metal Guitar DI.wav",
  "outputWav": "scenarios/bad-sound.wav",
  "outputDevice": "FM3 USB Audio Device",
  "inputDevice": "FM3 USB Audio Device:3",
  "outputChannel": 3
}
```
Fields: name (label), inputWav (DI source), outputWav (where the recorded file is written), outputDevice, inputDevice (DeviceName:channels format), outputChannel (1-based).

ScenarioMetadata — written alongside the output WAV by the `scenario` verb, {name}.meta.json:
```json
{
  "name": "bad-sound",
  "scenarioFile": "bad-sound.json",
  "inputWav": "audio/Metal Guitar DI.wav",
  "outputWav": "scenarios/bad-sound.wav",
  "timestamp": "2026-03-19T12:00:00Z",
  "sampleRate": 48000,
  "durationSeconds": 12.5
}
```

### New verbs

`scenario` verb — plays input WAV to output device and records from input device. Driven by a scenario JSON file.
Options: --scenario-file (required).
Reuses PlayWavRunner. Writes output WAV to outputWav path in JSON. Writes .meta.json sidecar.

`scenarios-compare` verb — generates a multi-scenario spectrum overlay HTML report.
Options: --scenario-files scenario1.json,scenario2.json,... (required); --reference-audio path (optional, shown as baseline); --report path (required); --block-size (default 4096).
For each scenario, reads outputWav and computes averaged PSD via WavFileSpectrumAnalyser. Builds MultiSpectrumReport. Exports to HTML.

### New components

#### AudioLevels.Simple.ConsoleApp

ScenarioDefinition: plain class, deserialised from JSON.
ScenarioMetadata: plain class, serialised to JSON sidecar.
ScenarioOptions: CommandLine [Verb("scenario")] options class. --scenario-file string.
ScenarioCommandHandler: reads ScenarioDefinition, builds PlayWavOptions (with Record=true), calls PlayWavRunner. Writes ScenarioMetadata sidecar.
ScenariosCompareOptions: CommandLine [Verb("scenarios-compare")] options. --scenario-files (comma-separated), --reference-audio, --report, --block-size.
ScenariosCompareCommandHandler: loads each scenario's outputWav. Calls WavFileSpectrumAnalyser.AnalyseAsync per file. Builds MultiSpectrumReport. Writes HTML via MultiScenarioHtmlExporter.

#### Alsionyx.Library.Audio.Analysis

WavFileSpectrumAnalyser: Task<double[]> AnalyseAsync(string path, int blockSize, CancellationToken). Reads WAV file with NAudio AudioFileReader, accumulates per-block PSD using PsdCalculator, averages across all blocks. Returns averaged PSD array and SampleRate via SpectrumAnalysisResult.
SpectrumAnalysisResult: double[] AveragedPsd, int SampleRate, int BlockSize, int FrameCount, double DurationSeconds.

#### Alsionyx.Library.Audio.Visualization

NamedSpectrum: string Name, double[] FrequencyHz, double[] SpectrumDb. One per scenario.
MultiSpectrumReport: List<NamedSpectrum> Scenarios, NamedSpectrum? Reference, string Title.
MultiScenarioHtmlExporter: void Export(MultiSpectrumReport report, string outputPath). Generates self-contained HTML with: one spectrum overlay chart (all scenarios + reference, each a distinct colour), one diff chart per scenario vs reference (if reference provided). Uses same SVG approach as SpectrumHtmlExporter.
SpectrumReportBuilder is extended: SpectrumAnalysisResult -> NamedSpectrum Build(SpectrumAnalysisResult result, string name).

### Unit Tests

WavFileSpectrumAnalyserTests: uses WaveFileDataFactory to write a temp WAV, asserts AnalyseAsync returns non-empty AveragedPsd of expected length. FrameCount > 0. DurationSeconds > 0.
ScenarioDefinitionTests: round-trip JSON serialise/deserialise preserves all fields.
MultiScenarioHtmlExporterTests: Export with one scenario and no reference writes a file containing "svg" and the scenario name.

### Success Criteria

audiolvls scenario --scenario-file bad-sound.json runs play+record and writes bad-sound.wav + bad-sound.meta.json.
audiolvls scenarios-compare --scenario-files bad-sound.json,good-sound.json --reference-audio di.wav --report comparison.html writes an HTML file with all three spectra overlaid and diff charts.
All unit tests pass. CI passes.

---

## Extension v2: Interactive HTML Report with Diff Series

### Updated requirements

--exclude-reference (bool, default false). Exclude the reference spectrum polyline from the overlay chart. Reference data is still loaded and used for diff computation when --show-diff is active.

--show-diff (bool, default false). Compute diff series for all pairs: every scenario[i] vs scenario[j] (i < j), and each scenario vs reference (if reference was provided). Each diff series is independently togglable in the HTML report.

Interactive HTML. Every spectrum polyline and every diff polyline has a named toggle mechanism (checkbox) in a controls panel. Unchecking hides the line; re-checking shows it. All series start visible. No external dependencies or CDN. Zero-dependency inline JavaScript.

### New fields on MultiSpectrumReport

ShowReference (bool, default true). When false, the reference polyline is not rendered in the overlay chart even if Reference is non-null. Set by the handler from --exclude-reference.

Diffs (List<NamedSpectrum>, default empty). Pre-computed diff series. Each entry has Name (e.g. "scenario1 - scenario2"), FrequencyHz, and SpectrumDb (values are A[i] - B[i], so positive = A louder). Populated by the handler when --show-diff is active.

### New options on ScenariosCompareOptions

--exclude-reference. Bool, default false. Maps to MultiSpectrumReport.ShowReference = !ExcludeReference.
--show-diff. Bool, default false. When true, computes all pair diffs and adds to MultiSpectrumReport.Diffs.

### Diff computation in ScenariosCompareCommandHandler

When ShowDiff is true:
- For each pair (i, j) where i < j: diff = scenario[i].SpectrumDb[k] - scenario[j].SpectrumDb[k]. Name = "{s[i].Name} - {s[j].Name}". FrequencyHz from s[i].
- If reference is non-null: for each scenario[i]: diff = scenario[i].SpectrumDb[k] - reference.SpectrumDb[k]. Name = "{s[i].Name} - {reference.Name}". FrequencyHz from s[i].
ComputeDiff is a private static helper method.

### MultiScenarioHtmlExporter rewrite

Generate self-contained HTML with inline SVG and JavaScript. No external dependencies.

Structure:
1. Controls panel div. Two sub-groups: Spectra (one checkbox per scenario, one for reference if ShowReference is true) and Differences (one checkbox per Diffs entry, only shown if Diffs.Count > 0). Each checkbox calls toggleLine(id, checked) via onchange. Each row has a colour swatch matching the polyline colour.
2. Spectra SVG (id="svg_overlay"). One polyline per scenario with id="line_s{i}", colour from ScenarioPalette. One dashed polyline for reference with id="line_ref" in ReferenceColor (#e0e0e0), only if ShowReference. Y-axis range: auto from all visible spectra data. X-axis: log 20Hz-20kHz.
3. Diff SVG (id="svg_diff"), only rendered if Diffs.Count > 0. One polyline per diff entry with id="line_d{i}", colour from DiffPalette. Y-axis: symmetric around 0, driven by max abs value. Horizontal zero line. X-axis: same log scale.
4. Inline JavaScript. toggleLine(id, visible) sets document.getElementById(id).style.visibility. Applied immediately via onchange.

Palettes:
ScenarioPalette: ["#4fc3f7", "#ff8a65", "#a5d6a7", "#ce93d8", "#ffcc80", "#80cbc4"]
DiffPalette: ["#ef5350", "#ab47bc", "#26c6da", "#9ccc65", "#ff7043", "#66bb6a"]
ReferenceColor: "#e0e0e0"

CSS for controls panel: dark theme, flex-wrap layout, grouped into labelled sections with border.

### Updated unit tests

Export_WithScenarios_ContainsCheckboxAndPolylineIds: polylines have id="line_s0", checkboxes reference them.
Export_WithReference_ShowReferenceTrue_ReferenceLinePresent: id="line_ref" present when ShowReference=true.
Export_WithReference_ShowReferenceFalse_ReferenceLineAbsent: id="line_ref" absent when ShowReference=false.
Export_WithDiffs_ContainsDiffSvgAndPolylines: when Diffs has entries, id="line_d0" present and a diff svg section exists.
Export_ContainsToggleJavascript: content contains "toggleLine".
Existing tests updated: remove check for "Difference vs Reference" heading (diff section now requires Diffs to be populated).

### Success Criteria

audiolvls scenarios-compare --scenario-files s1.json,s2.json --reference-audio di.wav --show-diff --report comparison.html produces HTML with all spectra and all diffs (scenario1-scenario2, scenario1-ref, scenario2-ref), each independently togglable.
audiolvls scenarios-compare --scenario-files s1.json,s2.json --reference-audio di.wav --exclude-reference --report comparison.html produces HTML without the reference spectrum polyline but still computes diffs vs reference when --show-diff is also set.
Open report in any offline browser, toggle checkboxes — individual lines appear and disappear.
All unit tests pass. CI passes.
