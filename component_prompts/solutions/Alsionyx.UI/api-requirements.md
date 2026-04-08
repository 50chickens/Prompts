Developer API Contract (Non‑Code, Behavioral Spec)
2.1 Input Device API
- The system must expose a list of available input devices.
- Each device must expose:
- Device name
- Channel count
- Channel identifiers
- The API must allow:
- Selecting/deselecting channels
- Querying active channels
- Subscribing to channel activity events
2.2 Output Device API
- The system must expose a list of output devices.
- The API must allow:
- Selecting an output device
- Selecting mono/stereo mode
- Sending audio buffers to the device
- Looping playback for .wav files
- Switching between:
- File playback
- Sine wave generator
2.3 Spectrum Data API
- The API must provide:
- Frequency bins (log‑spaced)
- Amplitude values (dBFS)
- Timestamped frames
- The API must support:
- Real‑time streaming
- Snapshot capture
- Comparison mode (input vs output)
2.4 Comparison Mode API
- The system must compute:
- ΔdBFS per frequency bin
- Peak mismatch
- Band‑averaged deviation
- The API must expose:
- Raw input spectrum
- Raw output spectrum
- Computed difference spectrum
2.5 UI Integration API
- The UI must subscribe to:
- Spectrum updates
- Device list changes
- Playback state changes
- The UI must publish:
- Channel selection changes
- Output routing changes
- Compare mode toggles
