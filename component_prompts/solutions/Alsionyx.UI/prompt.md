i have created a new stich project called "Audio Spectrum Comparator". it's link is https://stitch.withgoogle.com/projects/5792669916453817878. 
i have done the UI design and it is now time to code things. 

review these patterns/existing code bases:
patterns - C:\git\internal\Prompts\patterns
 - there are patterns for writing c#, an orchestration script and coding guidelines and a collection of existing patterns for things. 

existing designs. 

the overall UI design i want you to use is under C:\git\external\awesome-design-md\design-md\spacex. 
the spectrum analysis graph is based on the C:\git\external\DevWinUI\dev\DevWinUI.Controls\Controls\Native\SpectrumAnalyzer folder (there will be a corrosponding xaml file somewhere). i want you to reimplement SpectrumAnalyzer as an Avalonia control in the Avalonia.UI application. 
the stitch design is under C:\git\internal\Alsionyx.UI\src\Alsionyx.UI\Alsionyx.UI\Media\stitch\stitch. i want you to use the application layout (eg what menu items/buttons/panels/labels) from stitch but the design elements (eg button sizing/colours/fonts from the spacex design).

the plan:

i want to take the implementation from design to implementation. 

implementation. 

there is an existing avalonia application in C:\git\internal\Alsionyx.UI\src\Alsionyx.UI\Alsionyx.UI. the UI needs to be updated to match the design. 
the goal of this application is:

The ability to show the difference between two real-time audio streams in terms of dbfs difference for each frequency. the audio source can be a file, multiple existing audio sources, or a loopback device where one source is the audio being sent to the loopback device and comparison is from the returned audio. 

Features.

ASIO Audio Device Support - Enumerates and manages ASIO (Audio Stream Input/Output) audio devices with support for multiple simultaneous devices at different sample rates. Allows real-time audio capture from hardware devices using the NAudio library.
Multi-Channel Audio Capture - Supports selecting and capturing audio from multiple channels (up to 4 per device) across different ASIO devices simultaneously. Includes device-level selection with "Select All" and "Select None" controls for each device.
Real-time FFT Spectrum Analysis - Performs Fast Fourier Transform (FFT) analysis with a 4096-point window on incoming audio streams to generate power spectral density (PSD) data. Updates spectrum visualization in real-time as audio is captured.
Interactive Frequency Spectrum Visualization - Renders spectrum graphs with logarithmic frequency scale (20 Hz to Nyquist frequency) and dBFS magnitude scale (-120 to 0 dB). Includes hover tooltips showing precise frequency and amplitude at cursor position.
Channel Signal Detection - Monitors and displays signal presence for each selected audio channel, indicating whether the channel is actively receiving audio with visual indicators (HasSignal flag updated dynamically).
Spectrum Display Freeze Control - Allows users to pause and resume the real-time spectrum visualization without stopping the underlying audio capture session, enabling detailed analysis of captured spectral data at specific moments.

constraints.
build a .netcore 9 application.
use the orchestration-script pattern to build the application.
adhere to all of the existing constrains in the patterns folders. especially the pre-existing-patterns document. this will save you from re-implementing existing patterns/code. 
assume windows. 
This machine does not have any asio audiosources. You will need to create an abstraction for audio sources. Don't use the word mock/fake/test/dummy in the code anywhere. 
I want one UI - it needs to have a collapsible audio configuration page so that i can change audio options and then hide/collapse it out of the way. 

phases.
this section describes the phases of building the application. 

phase basic. 

update AvaloniaApplication1. this is a skeleton application we should first apply the design to. it does not have any real functionality - we just need to scaffold the design into this application. don't add any functionality yet. just get the design in place. 
the list of audio cards, the incoming audio sources, the spectrum graph, the channel signal detection, and the spectrum display freeze control should all be visible. you can use a datafactory to provide similulation data to the controls in this application to get the design in place. 

Check for existng abstractions for the data (eg list of audio cards, audio data, visualizations) but create datafactory classes to supply simulated data to the AvaloniaApplication1 class. datafactory/simulated data classes should only live in AvaloniaApplication1. 