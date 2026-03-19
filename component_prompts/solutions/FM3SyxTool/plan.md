FM3SyxTool - plan.md

Goal
Identify which FM3 system setting changed between bad_sound and good_sound syx backups to cause an audio quality difference.

Resources researched

External repos (C:\git\external\fm3):
AxeFxControl - C++ Arduino library implementing Fractal SysEx protocol. Source of truth for checksum algorithm, manufacturer ID, device IDs, all command bytes.
axeiiloader - C preset loader for Axe-Fx II. Confirms start/data/end message structure for backup files.
VController_v3 - Firmware for MIDI foot controller that drives Fractal devices. Contains Axe-Fx III model constants and snooped protocol data.
syxpack-rs - Rust SysEx parsing library. Confirms manufacturer ID 00 01 74 for Fractal Audio.
fractal-wiki - Saved copy of wiki.fractalaudio.com MIDI SysEx page. Documents Axe-Fx II command set, parameter encoding, checksum algorithm, preset block data format.
Fractal-Audio-FM3-Midi-Controller - Arduino MIDI controller firmware, limited protocol detail.
fractal-ai-builder - AI chat assistant for Fractal, no protocol detail.
fm3-midi-controller - PlatformIO project, no protocol detail.

Internal repos:
FM3FirmwareAnalyzer - Previous C# attempt to analyze FM3 firmware image. Confirmed FM3 device ID 0x11 and mapped known command bytes.
fm3_analysis/documentation - Existing research notes. SYSEX_EFFECT_DUMP_GUIDE.md documented 3-byte effect status encoding. FM3_ANALYSIS_SUMMARY.md contained prior protocol notes.

Binary analysis performed
Both .syx files are 197,270 bytes each.
Message boundaries parsed: 66 messages per file (1 x 0x51, 64 x 0x52, 1 x 0x53).
Binary diff: 1,302 byte positions differ.
Diff clusters: 168 contiguous runs.
Messages with changes: 15 out of 66.

What the research revealed

1. The 64 data blocks are split into two 32-block sections. The block-type discriminator (bytes 8-9 of each 0x52 header) repeats identically in the second section, offset by 32 blocks. The filename system+gb+fc indicates: system settings + global block + FC footcontroller. The two sections most likely correspond to (system+global block) and (FC footcontroller) data.

2. The changed blocks are 0, 1, 2, 3, 5, 8, 14 in both sections symmetrically. Blocks with discriminator 7F 7F are empty padding and unchanged.

3. Block 1 param region 345+ contains FC layout names packed as 2 ASCII chars per 16-bit parameter. The bad_sound file has custom names: PRESETS, SCENES, EFFECTS, CHANNELS, LOOPER, PER-PRESETS, PERFORM, UTILITIES. The good_sound file has factory defaults: Layout 1 through Layout 8. This is the most clearly identified difference.

4. Blocks 2, 3, 5, 8 contain FC switch and CC assignment parameters. The bad_sound file has many non-zero values (ranging from 128 to 10752, often multiples of 128). The good_sound file has all zeros in these regions. This indicates the bad_sound file had custom FC footswitch assignments and the good_sound file has them cleared to defaults.

5. Block 0 has 10 parameter differences. Params 1 and 2 are large numeric values that likely represent state counters or version tracking. Params 47 and 59 are single-bit flags (128 vs 0). Params 122-127 changed to specific values (21632, 21634, 2) from 0 or 30466. These may be system state fields that changed over time rather than intentional audio settings.

6. Block 14 has 5 changes in params 537-547. High values (65408, 65411) in the bad file suggest a near-maximum parameter value or a special sentinel. These may represent an important audio configuration setting.

Assessment of audio impact
The dominant visual pattern in the diffs is FC footcontroller configuration (layout names and CC assignments). These are unlikely to cause audio quality changes directly unless the FC was sending MIDI CC messages that were modifying FM3 parameters in real time.

The block 0 and block 14 changes are fewer but more relevant to audio. Block 0 contains global system parameters. Block 14 contains an unknown section (discriminator 0x00 0x00) with a small number of changed parameters at high indices, one of which (p[537]) changed from 7040 to 12416 (a meaningful mid-range value change), and others have extreme values.

To definitively identify which parameter caused the audio change, a parameter-to-function mapping for the FM3 system backup format is needed. This mapping is not publicly documented. The next step (write_syx_tool) would implement a tool to enumerate all changed parameters with their decoded values, attempt cross-reference against the fractal-wiki command documentation, and optionally send individual parameter SysEx queries to the FM3 to identify parameters by name.

Plan for write_syx_tool phase

Create C:\git\internal\fm3_analysis\src\FM3SyxTool as a .NET Core console app.
Command: compare <bad.syx> <good.syx>
Output: table of all changed parameters with block index, param index, decoded value in bad, decoded value in good.
Also output string-decoded regions where values appear to be ASCII.
Optionally: verify checksums for all messages in both files.
Optionally: dump a specific block as decoded params to a text file for inspection.
Use the existing fm3_analysis project patterns (from C:\git\internal\Prompts\patterns\c-sharp-testing.md and the ci/ orchestration scripts).

Open questions for user

1. Do you know which FM3 firmware version these backups were made on? The 0x51 header has bytes 0x04 0x41 which may encode a format version.

2. When you say "reset parameters" to get the good sound - do you know which menu or section in FM3-Edit you used? This would help narrow the search to specific blocks.

3. Is the audio difference in tone/timbre, volume, noise floor, or something else? If volume or noise floor, it may correlate with a specific gain or input level parameter in block 0.

4. Did the FC footcontroller have any MIDI learn assignments active that could have been sending CC messages to modify audio parameters live? If so, that could explain why clearing the CC assignments (zeroing blocks 2-3) fixed the sound.
