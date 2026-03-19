FM3 Audio Problem Analysis

Files compared:
bad_sound: FM3-260307-165216-system+gb+fc.syx (Mar 7 2026, bad audio, taken on firmware 10.x)
good_sound: FM3-260312-223321-system+gb+fc.syx (Mar 12 2026, good audio, taken after parameter reset on firmware 12.x)

Symptom reported:
Audio level/gain/drive significantly reduced. Not silent but noticeably lower volume such that the signal hitting the FM3 input was affecting the frequency content passing through the signal chain - typical behaviour when a signal is run too hot or too quiet through a modelled amp, causing the amp model to respond differently due to headroom.

Firmware version context:
The bad_sound backup was created on firmware 10.x and the good_sound backup on firmware 12.x. This difference is NOT the cause of the problem. The bad sound persisted through all firmware upgrades between 10.x and 12.x. Firmware upgrades on the FM3 preserve all user system settings, presets, and FC assignments intact. The bad settings were carried forward unchanged through every upgrade because they live in user configuration blocks, not firmware code. The good_sound backup was simply the first backup taken after the user reset the footswitch/MIDI/CC settings on firmware 12.x. The firmware version difference between the two files is therefore irrelevant to diagnosing the audio problem.

Root cause confirmed:
The user confirmed the bad sound was fixed by resetting footswitch, MIDI, and CC settings on the FM3. This directly identifies blocks 2, 3, 5, and 8 (FC switch CC assignments) as the definitive source of the problem. The FC was configured with switches assigned to send MIDI CC#7 (Main Volume) and CC#11 (Expression/Volume). When the FC transmitted these CCs to the FM3 at low values, the FM3 applied corresponding volume reduction to its audio output. The FM3 holds the last received CC#7 and CC#11 values persistently. Every time the FC reconnected after a reboot or firmware upgrade, it re-sent those CC values from the current switch states, reapplying the volume reduction immediately on startup. This is how the problem persisted for many firmware versions without any firmware change causing or fixing it.

Summary of all changes found:
1302 bytes differ across 15 of 66 messages. The 64 data blocks split into two symmetric 32-block sections. Blocks 0-14 and their mirrors 32-46 both change, confirming both sections hold the same types of data. Blocks 15-31 and 47-63 have 0x7F 0x7F discriminator bytes and are empty padding with no changes.

Changed blocks by section:
section 1: blocks 0, 1, 2, 3, 5, 8, 14
section 2 (mirrors): blocks 32, 33, 34, 35, 37, 40, 46


Block 14 - highest relevance to audio problem

Block 14 has only 5 parameter changes out of 1023 total. This is the most targeted change in the file - not a bulk reset of CC assignments but a small number of specific values. This makes it the strongest candidate for a direct audio parameter.

The surrounding context of the changed params shows a record structure using sentinel value 65411 (0xFF83) as empty-slot markers. Params p[548] onwards are all 65411 in both files - these are unfilled slots. Params p[544-547] are 65411 in the bad file (empty) but hold real values in the good file. This means the bad file is missing one record that the good file has.

Params 537-547 in detail:
p[537]: BAD=7040, GOOD=12416
p[538]: 65408 (same both - record header/type marker)
p[539]: 65409 (same both - record header continuation)
p[540]: 259 (same both)
p[541]: 128 (same both)
p[542]: 0 (same both)
p[543]: 640 (same both)
p[544]: BAD=65411 (empty slot), GOOD=0
p[545]: BAD=65411 (empty slot), GOOD=0
p[546]: BAD=65411 (empty slot), GOOD=16384
p[547]: BAD=65411 (empty slot), GOOD=65408

p[537] as a level parameter:
7040 = 55 * 128 = 10.74% of the 0-65534 range
12416 = 97 * 128 = 18.94% of the 0-65534 range
The bad value is 43% lower than the good value. This is a significant reduction. If this parameter controls input sensitivity, output level, amp drive level, or a gain-staging trim anywhere in the signal chain, a 43% reduction of the configured value would produce the reported symptom.

p[544-547] as level or offset parameters:
The good file has values 0, 0, 16384, 65408 where the bad file has empty-slot sentinels.
65408 as a signed offset = -128 (65408 - 65536 = -128).
16384 = 25% of full range.
If this group represents a 4-field record (e.g. min/max/current/default for a level control), the good file has a fully configured record while the bad file has it entirely absent. The most likely interpretation: the good file has a level parameter with a defined range and position, while the bad file has no such record - meaning the parameter defaults to some lower or uncontrolled value.

What the bad file is missing: one complete level-control record at the boundary where filled records end (p548+) and the last real record begins. The bad file has that last record absent or shifted, and p[537] has a lower anchor value. This is consistent with a level trim, output compensation, or cab/amp drive parameter having been set lower or removed.


Block 0 - global system parameters with possible level relevance

p[1]: BAD=37378, GOOD=43906
As percentage: bad=57.0%, good=67.0%
As +-20dB equivalent: bad=+2.8dB, good=+6.8dB (difference of ~4dB)
A 4dB difference in a master output level or input gain parameter is clearly audible and would change how the FM3 amp model responds to the input signal. If this is the FM3 system input level or output level trim, the bad file being ~4dB lower matches the reported symptom precisely.

p[2]: BAD=7425, GOOD=8192
8192 = 0x2000 - a round power-of-two, typical of a factory default.
As percentage: bad=11.3%, good=12.5% (about 10% lower in bad file).
Possibly a secondary gain stage or related system threshold.

p[47]: BAD=0, GOOD=128
p[59]: BAD=128, GOOD=0
These two single-bit flags (128 = 0x80, bit 7 set) swap state between files. One feature is enabled in bad that is off in good, and vice versa. Candidates: input pad, output limiter enable, noise gate on/off, global EQ bypass. If the flag at p[59] being 128 in bad represents an active setting like a global noise gate or input attenuator, and p[47] being 128 in good represents its complement or bypass, this swap could explain a level or tone difference.

p[122-127]: Multiple values changed from 0 or 30466 to 21634 or 2.
30466 = 0x7702. 21634 = 0x5482. Both are non-standard values, not simple percentages or CC numbers. These may be calibration or state parameters - possibly FM3 system-level calibration for input sensitivity or DAC/ADC gain stages. The transition from 30466 to 21634 is a reduction of ~29% in the parameter value.


Block 2 and 3 - FC switch CC assignments (indirect audio pathway)

These blocks store FC footswitch and expression pedal MIDI CC assignments. In the bad file, numerous parameters hold CC number assignments (value = CC# * 128). In the good file, all are zero (no assignments). All values in bad are exact multiples of 128 confirmed.

CC numbers assigned in block 2 bad file (by count):
CC#1 (Modulation) = 67 occurrences
CC#10 (Pan) = 46 occurrences
CC#6 (Data Entry) = 22 occurrences
CC#9 (Undefined) = 9 occurrences
CC#3 (Undefined) = 9 occurrences
CC#7 (MIDI Main Volume) = 8 occurrences
CC#2 (Breath) = 11 occurrences
CC#5 (Portamento Time) = 4 occurrences
CC#4 (Foot Controller Pedal) = 4 occurrences
CC#11 (Expression / Volume) = 1 occurrence

CC numbers assigned in block 8 bad file:
CC#1 (Modulation) = 121 occurrences
CC#65 (Portamento Switch) = at least 16 occurrences (one per step-16 record)
CC#58 = 8 occurrences
Various others: CC#7, CC#8, CC#10, CC#11, CC#22, CC#26, CC#32, CC#48-58, CC#65-66, CC#68, CC#73-118

The critical CC numbers for audio levels:
CC#7 = MIDI Main Volume. This controls the overall output level of the FM3 to its audio outputs. A value of 0 over CC#7 would mute the FM3 completely. A value of 50 out of 127 would reduce output to about 39% of full. If any FC switch assigned to CC#7 was in the low position and sending continuously, the FM3 would apply that volume reduction to all audio output.

CC#11 = MIDI Expression. This acts as a secondary volume multiplier after CC#7. Often used for volume swells via expression pedal. Low value = low volume. If assigned to an expression pedal that was sitting at toe-back position, CC#11=0 would silence the output entirely. Even a partially-back pedal position (CC#11=40) reduces output to about 31%.

How FC assignments cause persistent audio level reduction:
When the FM3 receives a CC#7 or CC#11 value, it stores that level and applies it to audio output until a new CC value is received. If the FC footcontroller sends CC#7=50 when a switch is toggled, the FM3 holds that value even after the switch is released. When the FM3 is then backed up, the system settings are saved but the CC value position effect persists in the hardware state. On reload of the bad_sound backup, if the FC is connected, those same CC assignments would resume transmitting based on current pedal/switch positions.

Block 2 sequential CC assignment record (params 293-359, step=6):
Twelve consecutive switch slots have sequential CC numbers 1-12 assigned one per slot:
param 293 = CC#1 (Modulation) - bad=128, good=0
param 299 = CC#2 (Breath) - bad=256, good=0
param 305 = CC#3 - bad=384, good=0
param 311 = CC#4 (Foot Controller) - bad=512, good=0
param 317 = CC#5 (Portamento Time) - bad=640, good=0
param 323 = CC#6 (Data Entry) - bad=768, good=0
param 329 = CC#7 (MAIN VOLUME) - bad=896, good=0
param 335 = CC#8 (Balance) - bad=1024, good=0
param 341 = CC#9 - bad=1152, good=0
param 347 = CC#10 (Pan) - bad=1280, good=0
param 353 = CC#11 (Expression) - bad=1408, good=0
param 359 = CC#12 (Effect Control 1) - bad=1536, good=0
This is a systematic assignment of 12 FC switches to send the first 12 standard MIDI CCs. Slot at param 329 = CC#7 Main Volume and slot at param 353 = CC#11 Expression are directly in this chain. If either switch was in a position transmitting CC#7 or CC#11 at a low value, that would set the FM3 audio output level down.


Block 8 - FC per-switch level/CC configuration

Records at 16-param intervals (step = 16). Each record is structured as:
field[0] = CC assignment (the changed field, e.g. 8320 = CC#65)
field[1] = 9856 (CC#77, same in both files)
field[2] = 10240 (CC#80, same in both files)
fields[3-15] = 0

In the bad file, field[0] = 8320 (CC#65 = Portamento Switch / in Fractal context: effect bypass toggle).
In the good file, field[0] = 0 (no CC assignment).
This repeats at params 136, 152, 168, 184, 200, 232, 248, 264, 296, 312, 328, 344, 360, 392, 408, 424 = 16 records.

CC#65 in Fractal context controls bypass state of individual effects. Having 16 switches all assigned to CC#65 means the FC had a set of bypass/enable controls configured. While CC#65 itself is not a direct level/volume control, if any of those 16 switches were toggling an effect that provides gain (e.g. a clean boost, drive block, or output level block) and a switch was in the engaged state during the bad period, that could result in the FM3 signal chain missing a gain stage.

Also in block 8 at params 106-134, additional CC-flagged assignments (CC#1=128, CC#58=7424) exist only in the bad file. CC#58 in Fractal's extended CC map is used for specific per-block controls. Value 7424 = CC#58. These suggest further FC switch-to-effect mappings that were active in the bad configuration.


Block 1 - FC layout names (cosmetic, not audio)

The bad file has custom performance layout names: PRESETS, SCENES, EFFECTS, CHANNELS, LOOPER, PER-PRESETS, PERFORM, UTILITIES. The good file has factory defaults: Layout 1 through Layout 8. This is cosmetic and does not affect audio. However, it confirms the bad file was a heavily customized FC configuration, strongly suggesting the audio-affecting CC assignments were intentional production setups rather than accidental settings.


Block 5 - additional FC performance data

Params 482-595 (bad file): values at 10240-10880 range = CC#80-85. These are Fractal extended CCs used for effect-specific controls. Params 915-976: additional CC assignments at CC#3-CC#9 range. All zero in good file. Block 5 mirrors blocks 2 and 3 in purpose - more FC switch-to-CC mappings.


Ranking of suspects for the audio level reduction

Rank 1: Block 14 p[537] - level or control target value
The single clearest numerical evidence. Bad=7040 (10.7%), Good=12416 (18.9%). Pure numeric difference. No CC mapping ambiguity - this is a stored parameter value, not a CC assignment. Whatever parameter this controls, it was set 43% lower in the bad file. Combined with p[544-547] being absent in bad (empty-slot sentinels) where good has a full record, this block has had a level-related record deleted or shifted lower in the bad file.

Rank 2: Block 0 p[1] - global system parameter
Bad=37378 (57%), Good=43906 (67%). ~4dB difference if +-20dB range. Consistent with an FM3 system input level, global output level, or amp drive parameter being set lower in the bad file. Round values in the good file (43906 is not particularly round, but both differ by 6528 = 51*128, which is exactly one CC-step increment, suggesting this may also encode a level as a multiple of 128).

Rank 3: Block 2/3 CC#7 assignments (8 occurrences)
CC#7 (MIDI Main Volume) assigned to 8 FC switches in the bad file, all cleared in good. If any switch was transmitting CC#7=low, the FM3 output was reduced at the hardware level regardless of all other settings. This would affect the signal globally, consistent with the symptom affecting the input to the recording device downstream.

Rank 4: Block 2 CC#11 assignment + block 8 CC#65 assignments
CC#11 (Expression/Volume) assigned to at least one switch. CC#65 (Fractal effect bypass) assigned to 16 switches. If CC#65 was toggling a gain block into bypass, or CC#11 was holding a low expression value, either would reduce level.

Rank 5: Block 0 p[47]/p[59] flag swap
One feature enabled in bad that is off in good. Without a parameter name map these cannot be identified further, but a flag controlling input pad, output limiter, noise gate, or global EQ is possible.


What changed in the syx to cause the audio problem

The bad_sound file has two categories of changes from factory/good state:

Category A: FC footcontroller MIDI CC assignments were fully programmed
Dozens of FC switches had CC numbers assigned (CC#1 through CC#12 in one group, CC#65 across 16 switches in another, assorted others in block 5). The CM assignments for CC#7 (Main Volume, 8 instances) and CC#11 (Expression, 1+ instance) are the most likely direct cause of the volume reduction. When a Fractal FM3 receives CC#7 at any value below 127, it scales the master output accordingly. When CC#7=55 (for example, if a switch was at mid-travel), the FM3 would output at 55/127 = 43% level. The 16 CC#65 assignments controlling effect bypass could additionally explain why the frequency content changed - if a drive block, boost, or EQ was bypassed by one of those switches, the signal chain response would change.

Category B: Block 14 and block 0 have lower stored numeric values
Independent of the CC assignments, block 14 p[537] is stored 43% lower in bad than good, and block 0 p[1] is stored ~4dB lower (if a gain-stage parameter). These are stored configuration values in the system settings, not runtime CC positions. They would persist across power cycles regardless of FC state and would affect audio even without the FC connected.

How the problem persisted through firmware upgrades:
The FM3 firmware upgrade process does not touch user system settings or FC configuration. Every upgrade from 10.x to 12.x preserved the FC switch assignments intact. Each time the FC reconnected after a reboot or firmware upgrade, it re-transmitted its current switch states as MIDI CC messages. Any switch assigned CC#7 in a "latched on" or "value" state would immediately resend CC#7=low_value to the FM3, which would hold that level until it received a higher value. This is why the bad sound appeared unchanged regardless of firmware version. The FM3 was operating normally - it was simply obeying the MIDI CC values its own FC was sending.

Most likely sequence of events:
At some point the FC was extensively configured with custom layout names, 8 switches assigned CC#7, 12 switches assigned sequential CC#1-12, and 16 switches assigned CC#65. When any of the CC#7-assigned switches were active they sent CC#7=low into the FM3. The FM3 stores the last received CC#7 position as its output level. Every subsequent reboot, firmware update, and backup restore preserved this FC configuration and thus preserved the condition causing the volume reduction. Block 14 p[537] being lower in bad (10.7% vs 18.9%) and block 0 p[1] also being lower (57% vs 67%) may reflect additional system-level parameters that were reduced by the same CC interaction or MIDI Learn event.


What you will see in FM3-Edit after restoring the bad_sound.syx

These are the specific screens and fields that will show the problem configuration.

FC > Layouts tab
Layout names will read: PRESETS, SCENES, EFFECTS, CHANNELS, LOOPER, PER-PRESETS, PERFORM, UTILITIES
Factory default names are: Layout 1, Layout 2, Layout 3, Layout 4, Layout 5, Layout 6, Layout 7, Layout 8
Seeing the custom names immediately confirms the bad backup is loaded. The good backup would show Layout 1 through Layout 8.

FC > [any layout] > switch list - the CC#7 volume assignments
In at least one layout, open each switch's settings and look at its MIDI tab or CC field.
Eight switches will show CC 7 (MIDI Main Volume) in their CC assignment field.
This is the primary problem: any switch with CC 7 assigned that is in an active/latched state will be transmitting a volume command to the FM3 on reconnect.
The sequential 12-switch bank (one full layout) will show CC 1, CC 2, CC 3, CC 4, CC 5, CC 6, CC 7, CC 8, CC 9, CC 10, CC 11, CC 12 assigned one per switch in order.
Switch in that bank at position 7 (CC 7) and position 11 (CC 11) are the volume-affecting ones.
CC 11 (Expression/Volume) assigned to one switch is particularly dangerous - if that switch was in an "on" state sending CC 11 = 0, the FM3 would be completely silenced via its expression volume.

FC > [any layout] > switch list - the CC#65 bypass assignments
Sixteen separate switches will show CC 65 in their CC assignment field.
CC 65 in Fractal context controls the bypass state of individual effect blocks.
If any of those 16 CC#65 switches were toggling a gain block (drive, amp, clean boost, output level) into bypass, the signal chain would lose a gain stage. This explains the frequency-content change in addition to the volume reduction - a bypassed amp model or drive block changes the tonal character, not just the level.

Setup > MIDI/Remote > External Controllers (or Controllers tab)
The FM3 maps incoming MIDI CCs to internal modifiers. Check whether CC 7 or CC 11 appear as External Controller sources.
If CC 7 is assigned as a controller source and its current value is shown in the UI, it would read below 127 (e.g. 55 or 64) indicating the FM3 had received and stored a lower volume level.
After restoring the bad backup and connecting the FC, watch this screen - the value may update immediately when the FC re-sends the CC on connect.

Setup > Audio (or Setup > I/O > Audio)
Check Input 1 Level or Output 1/2 Level.
Block 0 p[1]: bad file = 37378 (57% of range), good file = 43906 (67% of range)
If this parameter corresponds to a level slider here, the bad file's slider would sit noticeably lower than the good file's.
Block 0 p[2]: bad file = 7425, good file = 8192. The good file value 8192 = 0x2000 is a clean power-of-two, typical of a factory reset default. The bad file value is 7425 = 0x1D01, which does not pattern-match any standard default - it may be a corrupted or drifted value.

Summary of visual indicators that confirm the bad backup is loaded
1. FC Layout names show PRESETS / SCENES / EFFECTS / CHANNELS / LOOPER / PER-PRESETS / PERFORM / UTILITIES instead of Layout 1-8
2. Multiple FC switches show CC 7 in their MIDI CC field (confirm in at least two different layouts)
3. One FC switch shows CC 11 in its MIDI CC field (the expression volume controller)
4. Sixteen FC switches show CC 65 in their MIDI CC field (effect bypass toggles)
5. In one complete layout, twelve consecutive switches show CC 1 through CC 12 in sequence
6. Setup > Audio level parameter corresponding to block 0 p[1] reads approximately 57% instead of 67%
7. If FC is connected when the bad backup is loaded, the FM3 output volume may immediately drop when the FC re-sends its switch states on connection
