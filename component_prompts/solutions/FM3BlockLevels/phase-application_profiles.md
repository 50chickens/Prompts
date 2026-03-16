# Phase: application_profiles

## Scope
Named profile system so test configuration can be stored and re-run without long command lines. A profile stores all parameters needed to execute a run or play command.

## Profile Storage
Profiles live in a profiles/ subfolder of the app working directory.
Profile name = directory name under profiles/.
Each profile directory contains:
profile.json: name, description, output device, output channel, input device, input channel indices, optional source WAV file path, output level dBFS, output min level dBFS, frequency, duration seconds.
runs/: subdirectory holding per-run result JSON files (datestamped).

## ConsoleApp Verbs
profile create --name <name> --description <text> [same options as run or play verbs]
profile run --name <name> [optional overrides for any stored setting]
profile list: prints all profile names and descriptions.
profile validate --name <name>: checks all dependencies, prints result. Does not execute the test.

## Validation Rules
Enforced on both profile run and profile validate before any test execution:
Profile directory exists.
profile.json exists and all required fields are present.
If source WAV file is specified: file exists.
ASIO device names exist in AsioOut.GetDriverNames().
If a validation check fails, report the specific dependency that failed and exit non-zero. No test runs if any check fails.

## Implementation
ProfileSettings: plain class. Name, Description, OutputDevice, OutputChannel, InputDevice, InputChannelIndices, SourceWavFile, OutputLevelDbfs, OutputMinLevelDbfs, Frequency, DurationSeconds.
ProfileStore: loads and saves ProfileSettings as JSON using System.Text.Json. Lives in AudioLevels.Simple.ConsoleApp.
ProfileValidator: validates ProfileSettings against filesystem and live ASIO device list.
ProfileCommandHandler: handles profile create/run/list/validate sub-verbs.
profile run deserialises the profile, merges any command-line overrides, runs validation, then delegates to ThdTestRunner or PlayWavRunner as appropriate.

## Success Criteria
profile create, run, list, and validate all work.
profile run with a valid stored profile executes the equivalent of running the underlying run or play command.
profile validate with a missing device or file reports the specific failing dependency and exits non-zero.
No profile run proceeds if any validation check fails.
CI passes.
