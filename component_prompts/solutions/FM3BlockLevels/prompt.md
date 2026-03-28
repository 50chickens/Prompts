background:

Important: for soundflow - use the nuget package. this is available in nuget.org. DO NOT touch the existing nuget feed configuration on this host. the nuget.org feed is already enabled:

PS C:\git\internal\fm3_analysis\ci> dotnet nuget list source
Registered Sources:
  1.  nuget.org [Enabled]
      https://api.nuget.org/v3/index.json
  2.  LocalRepo [Enabled]
      c:\dev\nuget-local-repo
  3.  github [Enabled]
      https://nuget.pkg.github.com/50chickens/index.json
  4.  Microsoft Visual Studio Offline Packages [Disabled]
      C:\Program Files (x86)\Microsoft SDKs\NuGetPackages

general guidelines:

When making changes to the plan the plans should only mention the final state. Do not keep the original state and mention that it is depreciated etc. Keep decorations to a minimum.
enabling the CI pipeline is the the first priority. the solution should build and the primary executable should run without errors before moving onto the second phase. 

supporting code/existing patterns:

Look in C:\git\external\audio_visualization. there are several c# audio visualization libraries that already have implementations and would be prefereable to writing your own. also review the soundflow project under C:\git\external\SoundFlow. it is a high quality audio framework and may have some audio visualization code that is useful. do not create our own implementation if a superior implementation exists in one of those. 
C:\git\external\audio has repos related to audio. specifically naudio and cscore.


Application guidelines.
don't touch AudioLevels.ConsoleApp. 
use AudioLevels.Simple.ConsoleApp for the initial scaffolding. use this to build the first phase of the DI & audio libraries for testing. 
for the console app if the --duration period is not specified use a default timeout of 5 seconds. the reason for this is so that we can add the console app as an integration test in the pipeline. 
Except for audio metering logs keep other console log output to a minimum. 
Use a (configurable) period of 20% of the test interval to show a running log. 
include log output both to the console and json log file of the test run. 
use netcore 9 for all csproj files. 


application options.

A command line parameter to set the output device dbfs level. default to -18dbfs. 
A level spread option.  default should be -36 to -18 dbfs on the output device. split the test duration into 5. create 5 levels between the max and min dbfs and use each of the 5 levels for 20% of the test duration. add the output volum level to the console log. 
A loopback test option. the user should be able to select a .wav file and the output device(s) and channels(s) and the .wav file should be sent to those audio interfaces/channels. optionally the user can use the --record flag and specify an input device or devices and channel or channels and the recorded audio is then written to a .wav file. 


application features.
Application profiles. 

Code location guidelines.

Testing guidelines.

use unit tests only for things that can be mocked. do not include any tests that could be considered as integration - eg audio. no unit tests should be skipped or ignored 

Instructions.

Read C:\git\internal\Prompts\agents.md and C:\git\internal\Prompts\workflow.md for guidelines for writing c# and how to iterate the software. it contains information and references about cross cutting concerns - eg logging. Code here is available as nuget packages but i have provided the original source code.

Application workflow. 

opens up an input device using naudio using asio to open a back end connection to a named input device. the default should be the HXStomp using channel 1. 
Opens up an naudio using asio connection to a named output device. the default should be the Fm3 using Channel 1 and channel 3.
if there are multiple input channels specified - dont do seperate measurement cycles for them. we should be processing both input audio signals at teh same time from both channels and processing them at the same time.
plays a sample signal on the output device and analyze it on the input device. 

allow me to choose the sending device. 
allow me to choose multiple input devices and channels. do this via --input-device FM3:1,3 where 1 represents input channel and 3 represents input channel 3.

Application testing. 

Create the console application first. you are complete when:
You can send a THD test signal to the audio device (hx stomp on channel 1).
It is received by the FM3 audio input device on both channels 1 and 3. note the levels & THD values can/will be different. 
You can generate latency, levels, RMS and THD values. 

Development phases.

* Phase basic.

A basic console application using naudio & asio that find each audio device by name. A functional CI pipeline. 

* phase audio_foundation.

improve audio code robustness. review C:\git\external\audio\cscore to check if there are insights for improving reliability and support for things like handling multiple audio streams, duplex audio, improving round trip latency. pay attention to the architecture of the unit tests. 

* Phase audio_metrics. 

Add audio metrics - latency, THD, levels and RMS calculations. 

Phase application_profiles.

Create a --Profile option. the goal of this is to create a folder under the applications working directory containing a configuration file and results of test runs. This profile directorys should contain metadata of the profile - eg name, description. and enough details to complete the test. eg gain level, audio input and output devices and channels, or wave file for either using as source audio and/or recorded file. You should be able to rerun the test just by supplying the application profile name. the application should test the validity of the test parameters - eg if the profile folder exists, the profile settings file exists, the audio input & output devices and channels exist, the .wav file input or output folders/files exists. The test should not run if any of the dependencies for completing the test are not met. 

Phase wav_audio.

build a .wav file processing library for use in our application that uses cscore. the source code for cscore is under C:\git\external\audio\cscore
build these libraries and unit tests. don't use real .wavfiles. add a WaveFileDatafactory class for generating audio data for use in any of the unit tests in this class. WaveFileDatafactory should use the cscore nuget package. remove any old code that we wrote that deals with reading or writing .wav files replace it with leveraging the cscore library instead.

Add ability to play a wav file to the output device and then optionally record it from multiple interfaces (default is no). the .wav file that is used to play through the output device should be copied to the console apps running directory - but should be timestamped. The audio that is recorded from the input interface should also be written to the console apps running directory and given the same base name as the source .wav file and an identifier for the audio device name and channel and timestamp. 
eg source wav filename is Metal Guitar DI.wav
generated filenames: 
Source WAV copied to Metal Guitar DI_Input_20260314040236.wav
Recorded channel 1 to Metal Guitar DI_Output_FM3_USB_Audio_Device_ch1_20260314040236.wav
detect what frequency and bitrate the .wav file is using and then set the input & output audio devices as the same. don't resample the .wav file before sending. 
use the recordings subfolder of the console apps running directory for holding the .wav files. 
use the logs subfolder of the console apps running directory for holding log files. 

phase audio_stream_comparison

create a library to generate an EQ difference histogram for these scenarios:

Full period analysis. 
2 wav files. eg reference .wav with some .wav file that we have run through the signal chain. it should be a single chart that shows the EQ difference between two audio sources. 

Real time histogram. this is where we have a real-time frequency spectrum of one or more audio sources. 
Overlay of 2 audio sources in the real-time analysis. It should show frequency spectrum A and B simutaneously and optionally a real-time difference between the two. 
teh audio sources can be either 
live audio device streams - eg channel 1/2 and channel 3/4 an audio device (although this could be two seperate audio devices). 
2 x wav files. 

phase audio_stream_metadata
Used to generate live & historical data for scrolling histograms of the audio metrics - THD, latency, input levels, differences in dbfs levels from the original reference .wav file. it can show the various metrics for the previous 30, 60 seconds etc seconds (but this is configurable). 

phase audio_compare_app.

Full period histogram. This is where we use Spectrogram to show a visualization of EQ difference over time.
2 wav files. eg reference .wav with some .wav file that we have run through the signal chain. 

add a compare .wav file to the simple console app.  the goal is that i want to do these comparisons get the frequency differences between the set of .wav files in each comparison. 

The goal here is that i know to know if the .wav files produced in scenario 2 and 3 are different from each other.  i have changed a setting in between scenario 2 and 3 and kept the input .wav file the same. 
I have some some a/b testing and recorded some sample .wav files. the detail is in the prompt.md. first - add info the plan.md but make it generic for the future. 
I want to know if there is a difference between scenerio 2 and 3. I hear something different in the audio and want to confirm it via analyzing the audio. the analysis should be done via the console app rather than any manual/typed commands 

phase audio_visualization.
create a audio visualization library for use in our AudioLevels.Comparison.ConsoleApp. this is an avalonia based app. i want these UI panels which do the following.
cerate a unit test project for it so we can have some confidence that it works. 
1. one for showing the available audio devices and being able to select multiple channels audio from any of the input audio devices. 
2. one for showing the real-time frequency spectrum from all of the selected audio devices. this should dynamically add/remove frequency spectrums if/when they are added/removed from the 1st panel.

then use that library inAudioLevels.Comparison.ConsoleApp. 

phase comparison_scenarios.

generating the difference in frequency spectrum for two sets of data. eg the 1000hz frequency level in one sample is 10db and another .wav has the same frame as 11db. the output would be 1db. the goal here is to compare two output .wave files and generate a visualization that can show the differents in frequency spectrum at any point in the .wav file length (or for an entire file). an audio frame this sets of data could be either live audio or comparing two sets of  .wav files directly.
able to apply a normalization - eg if two audio input channels have two different gain levels - we should be able to adjust one so that we can compare levels. eg the channel 3 and channel 1 on the fm3 are ~ 18 dbfs different. 
it should be able to overlay multiple simultaneous input audio devices and simultaneous channels on the same device. 

check C:\git\external\audio_visualization\Spectrogram. it has a visualiztion for historical data. it is ambiguous in that it shows either an absolute dbfs level or a different in dbfs level between two sources. eg the reference di metal guitar.wav and the one we applied the 4 x EQ changes to. initial goal is to use Spectrogram to generate a time based EQ difference between the refernece DI metal guitar.wav and the 4 x EQ changes .wav. this will be constant between the two files over time but will give a good baseline library for presenting differences in EQ over time. eventually we want to create a real-time EQ difference library.

update plan.md for audio_visualization. C:\git\internal\Prompts\component_prompts\solutions\FM3BlockLevels\phase-audio_visualization.md. dont create any code yet. just create the plan.

Add a compare option to the simple console app that compares:
Metal Guitar DI.wav - the original .wav file.
scenario_1_output_copy_channel_1_to_channel_2\Metal Guitar DI_Output_FM3_USB_Audio_Device_ch3_fm3_output2_block_20260314115216.wav - this is when i use the 'copy audio output 1 to audio output 2' in the settings of the fm3. 
C:\git\internal\fm3_analysis\mp3_comparison\scenario_2_output_copy_none\Metal Guitar DI_Output_FM3_USB_Audio_Device_ch3_20260314115359.wav - this is when create 2 output blocks in the fm3 signal chain. one is output 1 (which is recorded by output device channel 1) and the other is recorded by channel 2 (which is output block 2 in the fm3 signal chain)
comparison 1: C:\git\internal\fm3_analysis\mp3_comparison\original\Metal Guitar DI.wav to C:\git\internal\fm3_analysis\mp3_comparison\scenario_1_output_copy_channel_1_to_channel_2\Metal Guitar DI_Output_FM3_USB_Audio_Device_ch3_fm3_output2_block_20260314115216.wav
comparison 2: C:\git\internal\fm3_analysis\mp3_comparison\original\Metal Guitar DI.wav to C:\git\internal\fm3_analysis\mp3_comparison\scenario_2_output_copy_none\Metal Guitar DI_Output_FM3_USB_Audio_Device_ch3_20260314115359.wav
comparison 3: C:\git\internal\fm3_analysis\mp3_comparison\scenario_1_output_copy_channel_1_to_channel_2\Metal Guitar DI_Output_FM3_USB_Audio_Device_ch3_fm3_output2_block_20260314115216.wav to C:\git\internal\fm3_analysis\mp3_comparison\scenario_2_output_copy_none\Metal Guitar DI_Output_FM3_USB_Audio_Device_ch3_20260314115359.wav

Phase Application_gui.

build a more complex gui application using avalonia for visualizing the audio metrics. 
include gui ui equivalents of the command line options that are available in the console app.

when they click start - create progress bar type UI elements in the console app which contains the following 3 running values: latency, dbfs, RMS and a THD. these should be updating at a configurable value per second (default to 20).
add a stop button. 



github repos for existing patterns:

cscore - audio processing.
C:\git\external\audio_visualization\ - repos containing audio visualization related code. 
C:\git\external\audio - repos related to audio. 