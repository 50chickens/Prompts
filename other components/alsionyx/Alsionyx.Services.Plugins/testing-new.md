# Alsionyx.ConsoleApp.Lv2Loader Test Plan

## Test 1: Offline Audio Verification with Noop Plugin
Run the console app with --verify-audio option. Uses managed noop plugin for pass-through verification.
Timeout is determined by the input WAV file duration (no explicit timeout needed).

Command:
```
cd /home/pistomp/git/internal/Alsionyx/Alsionyx
dotnet run -c Release --project src/Alsionyx.ConsoleApp.Lv2Loader -- \
  --verify-audio "/home/pistomp/git/internal/Setup/Alsionyx/src/Alsionyx.Library.Audio/Metal Guitar DI.wav"
```

Expected: Processes the WAV file through noop plugin, generates output, shows PASS/FAIL results.

## Test 2: Real-time Audio Routing with TinyGain
Load the tinygain plugin and route microphone input through it.
Exits automatically after 10 seconds.

Command:
```
cd /home/pistomp/git/internal/Alsionyx/Alsionyx
dotnet run -c Release --project src/Alsionyx.ConsoleApp.Lv2Loader -- \
  --load-plugin tinygain --timeout 10
```

Expected: Loads tinygain plugin, routes audio for 10 seconds, then exits cleanly.

## Test 3: Real-time Audio Routing with Ratatouille and Preset
Load the Ratatouille plugin with the Nam chug preset.
Exits automatically after 10 seconds.

Command:
```
cd /home/pistomp/git/internal/Alsionyx/Alsionyx
dotnet run -c Release --project src/Alsionyx.ConsoleApp.Lv2Loader -- \
  --load-plugin Ratatouille --plugin-preset Ratatouille-Nam-chug-preset --timeout 10
```

Expected: Loads Ratatouille plugin with preset applied, routes audio for 10 seconds, then exits cleanly.
