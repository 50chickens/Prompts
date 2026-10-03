FM3 SysEx File Format

MIDI SysEx framing

All SysEx messages begin with F0 and end with F7.
Between these delimiters: manufacturer ID bytes, device ID byte, command byte, data bytes, checksum byte, then F7.
7-bit clean: every data byte in the payload must have the high bit clear (0x00-0x7F).

Fractal Audio identification

Manufacturer ID: 00 01 74 (3 bytes, assigned by MMA)
Device IDs: FM3=0x11, Axe-Fx III=0x10, Axe-Fx II=0x03, AX8=0x05

Checksum algorithm

XOR every byte from F0 through the last data byte (inclusive), then AND the result with 0x7F.
The checksum byte is the second-to-last byte before F7.

Standard frame layout:
F0 00 01 74 [device_id] [command] [data...] [checksum] F7

Parameter encoding (16-bit values)

16-bit parameters are encoded as 3 bytes in little-endian 7-bit packed format:
byte0 carries bits 0-6, byte1 carries bits 7-13, byte2 carries bits 14-15 (only low 2 bits used).

decode: val = (byte0 & 0x7F) | ((byte1 & 0x7F) << 7) | ((byte2 & 0x03) << 14)
encode: byte0 = val & 0x7F; byte1 = (val >> 7) & 0x7F; byte2 = (val >> 14) & 0x03

Valid range: 0 to 65534 (65535 = 0xFFFF is typically unused/invalid).
Percentage mapping: pct = 100.0 * val / 65534

String parameters store 2 ASCII chars per 16-bit value:
lo_char = val & 0x7F; hi_char = (val >> 7) & 0x7F
A string of N characters uses ceil(N/2) parameter slots.
Null termination: the first param with lo_char=0 ends the string (hi_char may still hold a char).

Known command bytes

0x02 GET/SET_BLOCK_PARAMETER_VALUE
0x08 GET_FIRMWARE_VERSION
0x0A EFFECT_BYPASS
0x0B EFFECT_CHANNEL
0x0C SCENE_NUMBER
0x0D PRESET_INFO
0x0E PRESET_BLOCKS_DATA
0x0F LOOPER_STATUS
0x10 TAP_TEMPO_PULSE
0x11 TUNER_STATUS
0x13 EFFECT_DUMP
0x14 GET_PRESET_NUMBER
0x51 SYSTEM_BACKUP_START
0x52 SYSTEM_BACKUP_DATA
0x53 SYSTEM_BACKUP_END
0x64 MULTIPURPOSE_RESPONSE

System backup file format (.syx)

Filename convention: FM3-YYMMDD-HHMMSS-system+gb+fc.syx
system = FM3 system settings
gb = global block settings
fc = FC footcontroller settings

File structure (total 197,270 bytes for firmware ~4.x):
1 x 0x51 message = 11 bytes
64 x 0x52 messages = 64 * 3082 = 197,248 bytes
1 x 0x53 message = 11 bytes
Total = 197,270 bytes

0x51 START message (11 bytes):
F0 00 01 74 11 51 [b6] [b7] [b8] [b9] F7
b6=0x00 b7=0x00 (constant, possibly reserved)
b8=0x04 b9=0x41 (format version or file type marker, same in all observed files)
No checksum in the 0x51 message.

0x52 DATA BLOCK message (3082 bytes):
F0 00 01 74 11 52 [b6] [b7] [b8] [b9] [payload: 3070 bytes] [checksum] F7
b6=0x00 b7=0x08 (constant across all 64 blocks, payload size high indicator)
b8, b9 = block-type discriminator bytes (see block types below)
payload = 3070 bytes of 7-bit parameter data, decoded as 1023 three-byte parameter groups + 1 unused byte
Each 0x52 message holds 1023 decoded 16-bit parameter values.
byte index 3080 = checksum (XOR of all bytes from F0 through byte 3079, AND 0x7F)
byte index 3081 = F7

0x53 END message (11 bytes):
F0 00 01 74 11 53 [b6] [b7] [b8] [b9] F7
b6-b9 = 4-byte file integrity value (28-bit, encoded as 4 x 7-bit bytes)
Differs between files with different content; function is likely a cumulative checksum or block count.
No trailing checksum byte before F7 in the 0x53 message.

Block layout within the 64 data blocks

The 64 blocks are divided into two sections of 32 each:
Blocks 0-31 = first section (likely FM3 system + global block settings)
Blocks 32-63 = second section (likely FC footcontroller settings)

Both sections have identical block-type discriminator patterns, offset by 32.
The two sections share the same structure and parallel parameters.

Block-type discriminator (b8, b9) values observed:

Blocks 0, 32: b8=0x08 b9=0x20
Blocks 1-6, 12-14, 33-38, 44-46: b8=0x00 b9=0x00
Blocks 7-8, 39-40: b8=0x01 b9=0x00
Block 9, 41: b8=0x20 b9=0x62
Block 10, 42: b8=0x63 b9=0x68
Block 11, 43: b8=0x53 b9=0x4A
Blocks 15-31, 47-63: b8=0x7F b9=0x7F (empty/padding, all payload bytes = 0x00)

The discriminator bytes appear to identify the data section type within the backup.
Blocks with 0x7F 0x7F are empty placeholder slots with no meaningful data.

Known parameter regions (relative to block index, 1023 params per block)

Block 0 (first block in each section):
Params 0-127+ = top-level system/global configuration values
p[1]: unknown numeric (BAD=37378 GOOD=43906)
p[2]: unknown numeric (BAD=7425 GOOD=8192)
p[47]: flag (BAD=0 GOOD=128)
p[59]: flag (BAD=128 GOOD=0)
p[122]-p[127]: multiple values changed to 21634 or 2 in good (from 0 or 30466)

Block 1 (second block in each section):
Params 345-600+ = FC layout names (8 layouts, each name uses ~8 params as 2-char packed ASCII)
Name layout appears to be:
  p[345..352] = Layout 1 name (8 params = up to 16 chars)
  p[377..384] = Layout 2 name
  p[409..416] = Layout 3 name
  step = 32 params between names
In the bad_sound file, Layout names were overwritten with: PRESETS, SCENES, EFFECTS, CHANNELS, LOOPER, PER-PRESETS, PERFORM, UTILITIES
In the good_sound file, Layout names are factory defaults: Layout 1, Layout 2, ... Layout 8

Params 634-795 (approx) = FC footswitch CC assignments or performance mode settings
In the bad file, many of these have values 2-9 (non-zero).
In the good file, all are zero (default/off).

Block 2 and 3 (third and fourth data blocks):
Contains FC switch parameter data.
Changed params in bad file have values in range 128-7296, set to 0 in good file.
Many values are multiples of 128 (0x80=128, 0x180=384, 0x280=640, etc.).
The 0x7F00 pattern (65408) and 0x0003 in adjacent params may represent a signed or flag value.

Block 5:
Params 482-595 = appear to be FC performance data (names or CC assignments; values are multiples of 128 or 0x280/0x2A0 range).
p[878]: BAD=0 GOOD=128 (single flag flip)
params 915-976: similar CC or label data.

Block 8:
Params 106-136 = single-byte flag values (all 128=0x80 in bad, all 0 in good).
Params 136-424 (periodic pattern every 16 params): larger values (6144-10752) in bad, all 0 in good.
Spacing of 16 params = 16 * 3 = 48 raw bytes.

Block 14:
Only 5 params differ, in region 537-547.
p[537]: BAD=7040 GOOD=12416
p[544]-p[547]: BAD=65408/65411 GOOD=0/16384/65408
65408 = 0xFF00 masked to 14-bit = 65408 which in 7-bit context is actually 16256 & 3 flag bits.

Diff summary (files compared)

bad_sound file: FM3-260307-165216-system+gb+fc.syx (197270 bytes)
good_sound file: FM3-260312-223321-system+gb+fc.syx (197270 bytes)

Total differing byte positions: 1302
Diff clusters (contiguous runs): 168
Messages with changes: 15 out of 66

Changed messages (first section): 0x52[0], [1], [2], [3], [5], [8], [14]
Changed messages (second section, mirrors first): 0x52[32], [33], [34], [35], [37], [40], [46]
Footer also changed: 0x53 (expected, since content changed)
Header unchanged: 0x51 identical in both files

Checksum calculation (per message)

To validate a 0x52 message:
xor = 0
for byte in message[0..3079]: xor ^= byte
xor &= 0x7F
assert xor == message[3080]

To recalculate after editing payload bytes, repeat above and write result to byte 3080.
The 0x51 and 0x53 messages do not follow the same checksum pattern as 0x52.

PowerShell analysis snippets

Load files:
$bad = [IO.File]::ReadAllBytes("path\to\bad.syx")
$good = [IO.File]::ReadAllBytes("path\to\good.syx")

Count messages and verify structure:
$i=0; $msgs=@(); while($i -lt $data.Length){ if($data[$i] -ne 0xF0){$i++;continue}; $j=$i+1; while($j -lt $data.Length -and $data[$j] -ne 0xF7){$j++}; $msgs+=@{Start=$i;End=$j;Cmd=$data[$i+5];Len=$j-$i+1}; $i=$j+1 }
$msgs.Count  # should be 66

Decode params from block N:
$start=11+$N*3082; $ps=$start+10; $pe=$start+3079
$params=@(); $i=$ps; while(($i+2) -le $pe){$b1=$data[$i];$b2=$data[$i+1];$b3=$data[$i+2]; $params+=($b1-band 0x7F)-bor(($b2-band 0x7F)-shl 7)-bor(($b3-band 3)-shl 14); $i+=3}

Decode string from params starting at index P (packed 2 chars per param):
$s=""; foreach($v in $params[$P..($P+15)]){ $lo=$v-band 0x7F; $hi=($v-shr 7)-band 0x7F; if($hi){$s+=[char]$hi}; if($lo){$s+=[char]$lo}else{break} }

Compare two files param by param for block N:
for($i=0;$i -lt $pb.Count;$i++){if($pb[$i]-ne $pg[$i]){"p[$i]: BAD=$($pb[$i]) GOOD=$($pg[$i])"}}
