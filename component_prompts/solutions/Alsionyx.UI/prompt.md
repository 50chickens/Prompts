goal:

read requirements.md for the goal.

additional instructions/clarifications.

The goal of this app is to only use real-time asio input devices and show the frequency spectrum. there might be other information in other patterns documents but we are not implementing those. this document and requirements.md in this folder are the authoritive source of requirements of what i want you to do. other info in other documents may help you to build the solution, or provide extra context/techniques/patterns for things but the thing youre building is in the requirements.md document. 

constraints. do not violate these.

The goal here is to only use real-time audio sources. i want to be able to view the real-time frequency spectrum of one or more channels from one or multiple asio devices using a checkbox to enable/disable the audio source. 
i don't want any .wav sources. only real-time audio with a stop/start button. 
add a file -> exit menu in the avalonia app.
use libraries/code from C:\git\internal\fm3_analysis\src\FM3BlockLevels but some of these libraries will available as nuget packages. read the nuget packages pattern.
i want this application only in C:\git\internal\Alsionyx.UI\src\Alsionyx.UI so it is fast to compile. 
Add unit tests to make sure the asio audio sources are not empty/null.
Add unit tests to make sure that you an add the fm3 channel 1 and channel 3 input sources and those channels data for the visualization are present are non zero. add an integration test where it uses teh avalonia screenshoting feature so i can confirm it is showing the correct frequency spectrum. 

supporting code:
there are a number of libraries related to audio under C:\git\internal\fm3_analysis\src\FM3BlockLevels.
supporting documentation. 
Go and read 

C:\git\internal\Prompts\patterns
C:\git\internal\Prompts\component_prompts\solutions\FM3BlockLevels\
