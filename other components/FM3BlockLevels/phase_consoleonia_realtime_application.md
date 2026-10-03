High‑Level Structure
The FM3‑Edit interface can be decomposed into three major regions:
1. 	Top Bar / Preset Header
2. 	Signal Chain Grid (Block Layout)
3. 	Parameter Editor Panel (Context‑Sensitive Inspector)
This is a very common pattern:
Navigation / Workspace / Inspector

🧱 1. Top Bar / Preset Header
Purpose
Displays the current preset, scene, and global actions.
UI Elements
• 	Preset name dropdown
• 	Scene selector
• 	Save / Revert / Layout buttons
• 	Status indicators (CPU usage, connection status, etc.)
C# Implementation Notes
• 	A  or  with fixed-height row.
• 	Use  for preset/scene selection.
• 	Use  for actions.
• 	Use  for status indicators.

🔌 2. Signal Chain Grid (Node‑Based Layout)
Purpose
Shows the blocks (Pitch, Drive, Amp, Cab, Delay, etc.) and how they connect.
Visual Characteristics
• 	A grid-like canvas with rectangular block elements.
• 	Blocks have:
• 	A label (e.g., “PIT 1”)
• 	A channel indicator (“A”, “B”)
• 	A bypass state (color change)
• 	Lines connecting blocks left‑to‑right.
C# Implementation Notes
This is essentially a node graph editor.
You’d likely use:
• 	Canvas for absolute positioning
• 	Or a UniformGrid if you want fixed columns
• 	Each block is a UserControl with:
• 	Border
• 	Label
• 	Channel indicator
• 	Click event to select
• 	Connections drawn using:
• 	 or  elements
• 	Or a custom  layer
If using WPF, this is a perfect use case for:
• 	 bound to a collection of blocks
• 	 as the 
• 	A second  for connection lines

🎚️ 3. Parameter Editor Panel (Inspector)
Purpose
Shows detailed parameters for the selected block.
In your screenshot, the Pitch block is selected, so the right panel shows:
• 	Whammy settings (Start, Stop, Control)
• 	Tracking settings
• 	Input Gain, Mix, Level, Balance
• 	Low/High Cut
• 	Toggle buttons (Thru, Kill Dry, Scene Ignore, Bypass)
UI Elements
• 	GroupBoxes or Expander sections
• 	Sliders with numeric textboxes
• 	ComboBoxes for modes
• 	ToggleButtons for on/off states
• 	Labels for parameter names
C# Implementation Notes
• 	Use a  with multiple rows for clean alignment.
• 	Bind controls to a .
• 	Use  to swap parameter layouts depending on block type (Pitch, Amp, Cab, etc.).
This is a classic property inspector pattern.


Instructions for coding agent. 

1. Remove all non‑UI code
Delete any files, classes, or logic that are not directly involved in:
- Rendering the UI
- Providing ViewModels for UI binding
- Supporting the ASCII signal‑chain renderer
- Basic application startup
This includes:
- Old sample classes
- Placeholder business logic
- Unused services
- Any networking, audio processing, or unrelated utilities
- Any unused models or viewmodels not referenced by the UI

2. Keep only the UI‑critical components
Ensure the project contains only:
- MainWindow.axaml
- MainWindow.axaml.cs
- MainViewModel
- BlockViewModel
- SignalChainRenderer
- Program.cs (minimal Avalonia/Consolonia bootstrap)
- The .csproj file
Everything else should be removed unless it is required for Avalonia/Consolonia to compile.

3. Ensure ViewModels are clean and testable
The coding agent should:
- Strip out any UI‑unrelated logic from ViewModels
- Ensure ViewModels expose only properties used in bindings
- Ensure ViewModels do not depend on Avalonia types
- Ensure ViewModels do not reference console rendering directly
- Make all ViewModel logic deterministic and unit‑testable

4. Ensure the ASCII renderer is isolated and testable
The agent should:
- Keep SignalChainRenderer as a pure class with no UI dependencies
- Ensure it takes simple inputs (list of blocks, selected index)
- Ensure it returns a string only
- Ensure it has no side effects
- Ensure it can be unit‑tested independently

5. Clean up the project structure
The coding agent should:
- Remove unused folders
- Organize remaining files into:
- /Views
- /ViewModels
- /Rendering (for the ASCII renderer)
- /Models (if needed)
- Ensure namespaces match AudioLevels.ConsoleApp

6. Prepare the project for unit testing
The coding agent should:
- Add a test project if not present
- Reference the main project
- Ensure tests can cover:
- SignalChainRenderer output
- ViewModel property behavior
- Any simple logic in the UI layer
- Avoid UI‑framework dependencies in tests
- Ensure no Avalonia/Consolonia types leak into testable logic

7. Remove any runtime logic not required for UI startup
The agent should:
- Keep only the minimal Avalonia/Consolonia bootstrap
- Remove any custom initialization not required for the UI
- Remove any unused DI containers, logging frameworks, or config systems

8. Verify bindings
The coding agent should:
- Ensure every binding in .axaml corresponds to a real property
- Remove any bindings that point to missing or unused properties
- Ensure no binding errors occur at runtime

9. Ensure the project builds cleanly
The agent should:
- Resolve missing references
- Remove unused using statements
- Ensure the .csproj references only Avalonia/Consolonia packages
- Ensure no warnings about missing types or unused code
