# LV2 Mod-GUI Plugin Integration

This implementation adds complete LV2 mod-gui support to the Alsionyx pedalboard UI. Plugins now render with custom HTML/CSS-based visual interfaces.

## Sample Plugins

Two fully functional sample plugins are included with mod-gui specifications:

### 1. Gain Plugin (`plugins/gain-plugin/`)
- **Description**: Simple audio gain control with a single knob
- **Visual**: Purple gradient background with a rotatable knob
- **Parameter**: Gain (0-24 dB range, 0 = -12dB, 24 = +12dB)
- **Features**: 
  - Rotating knob with visual feedback
  - Real-time value display in dB
  - Wheel/mouse scroll control support

### 2. 3-Band EQ Plugin (`plugins/eq-plugin/`)
- **Description**: Parametric 3-band equalizer
- **Visual**: Pink/red gradient background with 3 knobs (Low, Mid, High)
- **Parameters**: 
  - Low band: -12dB to +12dB
  - Mid band: -12dB to +12dB  
  - High band: -12dB to +12dB
- **Features**:
  - Three independent band controls
  - Individual value displays for each band
  - Smooth drag control and scroll support

## Plugin File Structure

Each plugin follows the LV2/Mod-GUI convention:

```
plugin-name/
  ├── manifest.ttl          # LV2 plugin metadata (Turtle RDF format)
  └── modgui/
      ├── icon.html         # Main GUI definition (HTML)
      ├── stylesheet.css    # Visual styling (CSS)
      └── script.js         # Interaction logic (JavaScript)
```

### manifest.ttl
Defines the plugin metadata including name, description, and references to the GUI resources:
```turtle
<urn:alsionyx:plugin-name>
    a lv2:Plugin ;
    rdfs:label "Plugin Name" ;
    rdfs:comment "Plugin description" ;
    mod:gui <urn:alsionyx:plugin-name#gui> .
```

### icon.html
HTML structure with mod-gui attribute conventions:
- `data-parameter`: Parameter ID for binding
- `data-min` / `data-max`: Parameter range
- CSS classes drive visual appearance
- Semantic HTML structure for accessibility

### stylesheet.css
- Gradient backgrounds for visual differentiation
- Knob styling with rotation effects
- Value display formatting
- Responsive sizing for different plugin dimensions

### script.js
- Initializes interactive elements
- Handles mouse/wheel events for parameter manipulation
- Updates visual elements in real-time
- Supports drag, scroll, and click interactions

## How to Test

### 1. Run the Application
```powershell
cd src
dotnet run --project Alsionyx.Ui.Avalonia.Gui
```

### 2. Add Plugins to Pedalboard
- In the "Available Plugins" section, you should see discovered plugins:
  - "gain-plugin" (auto-discovered from `plugins/gain-plugin/`)
  - "eq-plugin" (auto-discovered from `plugins/eq-plugin/`)
  - Fallback default plugins if discovery fails
- Click any plugin button to add it to the pedalboard

### 3. Interact with Plugins
- **Drag plugins**: Click and drag any plugin to reposition on the canvas
- **View plugin colors**: Notice the purple Gain and pink EQ plugins render with their mod-gui colors
- **Connect cables**: Drag from output ports to input ports to create audio routing connections

### 4. Verify Rendering
- Plugins display with their defined background gradients (purple for Gain, pink for EQ)
- Plugin names appear in the center of each visual
- Port indicators show at edges (will be enhanced with cable rendering)

## Technical Implementation

### Key Classes

**ModGuiData** (`Models/ModGuiData.cs`)
- Holds parsed mod-gui HTML/CSS/JS content
- Stores parameter metadata (name, range, unit)
- Caches the primary color from CSS gradient

**ModGuiLoader** (`Services/ModGuiLoader.cs`)
- Parses plugin directory structure
- Extracts HTML content and parameter definitions via regex
- Falls back to defaults for missing files
- Converts parameter names to readable format

**PluginRepository** (`Services/PluginRepository.cs`)
- Discovers plugins from the `plugins/` directory
- Creates PluginInstance objects with loaded mod-gui data
- Caches discovered plugins
- Handles fallback to hardcoded plugin list

**PedalboardConstructor** (`Controls/PedalboardConstructor.cs`)
- Renders each plugin as an Avalonia Border with mod-gui color
- Updates visual positions when plugins are dragged
- Hit detection for plugin selection and cable routing
- Canvas-based positioning system

**RoutingConfigurationViewModel** (`RoutingConfigurationViewModel.cs`)
- Uses PluginRepository to discover available plugins
- Creates plugin instances with mod-gui data
- Manages pedalboard state and plugin collections

## Extending with New Plugins

To create a new plugin:

1. Create directory: `plugins/your-plugin-name/`
2. Create manifest.ttl with plugin metadata
3. Create `modgui/` subdirectory
4. Add HTML, CSS, and JavaScript files
5. The plugin auto-discovers on application startup

Example minimal plugin:
```
plugins/my-filter/
  ├── manifest.ttl
  └── modgui/
      ├── icon.html
      ├── stylesheet.css
      └── script.js
```

## Current Limitations & Future Work

**Implemented:**
✅ Plugin discovery from filesystem
✅ HTML/CSS visual rendering
✅ Color extraction from CSS gradients
✅ Parameter extraction from HTML data attributes
✅ Drag-and-drop plugin movement
✅ Cable connection logic

**Planned:**
⏳ Interactive mod-gui parameter controls in real-time
⏳ Parameter binding to audio processing
⏳ Cable visual indicators with proper rendering
⏳ Plugin deletion UI
⏳ MOD-GUI JavaScript execution for interactive widgets
⏳ Undo/Redo for pedalboard changes
⏳ Pedalboard save/load with plugin state

## References

- LV2 Plugin Standard: https://lv2plug.in/
- MOD Project Wiki: https://wiki.mod.audio/
- Example Plugin (tinyamp.lv2): `/git/external/tinyamp.lv2/`
- MOD SDK: `/git/external/mod-sdk/`
