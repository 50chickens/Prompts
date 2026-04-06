there are a number of libraries related to audio under C:\git\internal\fm3_analysis\src\FM3BlockLevels.

The goal here is to only use real-time audio sources. i want to be able to view the real-time frequency spectrum of one or more channels from one or multiple asio devices using a checkbox to enable/disable the audio source. 
i don't want any .wav sources. only real-time audio with a stop/start button. 
add a file -> exit menu in the avalonia app.
use libraries/code from C:\git\internal\fm3_analysis\src\FM3BlockLevels but some of these libraries will available as nuget packages. read the nuget packages pattern.
i want this application only in C:\git\internal\Alsionyx.UI\src\Alsionyx.UI so it is fast to compile. 
Detemine the bitrate/frequency of the asio device when you enumerate the devices. some devices might only be able to use certain bitrates and we need to query for that. 
Add unit tests to make sure the asio audio sources are not empty/null.
add an integration test which:
Uses the fm3 channel 1 and 3 as input sources. it starts the frequency spectrum analysis for this. 
It captures timestamped images into the Directory.GetCurrentDirectory()}\\screenshots folder. 
Add unit tests to make sure that you an add the fm3 channel 1 and channel 3 input sources and those channels data for the visualization are present are non zero. Add an integration test where  so i can confirm it is showing the correct frequency spectrum. 
The X and Y axis have the dbfs level for the vertical axis and the horizontal contains the frequency in hz or khz. 


1. **A complete Avalonia UI Control** (XAML + C# code‑behind + rendering pipeline)  
2. **A JSON Schema** describing the spectrum data format  

Everything is self‑contained and implementation‑ready.

---

# 🎨 **1. Avalonia UI Control — `FrequencySpectrumView`**

This control:

- Accepts a list of frequency/amplitude points  
- Maps frequency → X (log scale)  
- Maps dBFS → Y (linear scale)  
- Smooths the line  
- Draws a polyline on the canvas  