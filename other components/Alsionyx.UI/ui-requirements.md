UI Requirements (Rewritten as Forward‑Looking Specifications)
1. Typography & Layout Requirements

- All text must remain on a single line with ellipsis if truncated; wrapping is not permitted.


2. Device & Channel List Requirements
- Each audio device must be represented as a collapsible section, collapsed by default.
- Each device section must contain a compact horizontal row of channel checkboxes (e.g., Ch1–Ch4).
- Channels must be indented under their device header to reinforce hierarchy.

3. Interaction & Behavior Requirements
- Toggling a channel checkbox must immediately update the active input set without requiring a restart.
- Checkbox interactions must be debounced to prevent rapid reinitialization or instability.
- Devices with no selected channels must appear visually inactive (e.g., dimmed).
- Clicking a device header must expand/collapse its channel list.
- A “Select All Channels” and “Select None” option must be available for each device.

4. Status & Feedback Requirements
- The analyzer’s running state must be represented by a compact status indicator (e.g., green/yellow/red dot).
- Start/Stop controls must use icons or compact buttons to reduce toolbar size.
- Each channel must display a small signal‑present indicator (e.g., LED‑style activity light).
- Hovering over the spectrum must show a tooltip with frequency and dBFS at the cursor position.

5. Spectrum Graph Requirements
- The graph must not wrap or resize unpredictably when the left panel changes.
- A “Freeze Graph” control must be available to pause visualization without stopping audio capture.

6. Toolbar & Navigation Requirements
- The top toolbar must be compact, with minimal padding and icon‑based controls.
- A “Rescan Devices” button must be provided to refresh device lists without UI flicker.
- The UI must preserve the user’s last configuration (selected devices/channels) on startup.

7. Stability & Performance Requirements
- FFT computation must run off the UI thread to maintain responsiveness.
- Rendering must be frame‑rate limited (e.g., 30 FPS) to avoid unnecessary redraws.
- Device list updates must not trigger layout shifts or cause the graph to resize.
- All audio engine reinitialization must occur through a safe, atomic restart mechanism.
