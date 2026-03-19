background: we are trying to figure out what setting in my fractal fm3 has given me good sound.
under C:\git\internal\fm3_analysis\syx_files\bad_sound there is a .syx file which is a backup of the system settings created by fm3-edit. these settings have something that gives me a bad sound in my fm3. i do not know what makes it sound better. my guess is that there is a non standard default in this file. 
under C:\git\internal\fm3_analysis\syx_files\good_sound there is a .syx file which is a backup of the system settings created by fm3-edit. these settings have something that gives me a good sound in my fm3. 
the only thing that is changed between the good sound and the bad sound is i reset a number of paramaters. once i did this the sound was fine and i took a backup which is the C:\git\internal\fm3_analysis\syx_files\good_sound folder. 
the bad_sound .syx backup file was created with firmware 10.x. i think it was 10.0.
the good_sound .syx backup file was created with firmware 12.x. i think it was 12.0.
the bad sound still persisted when i upgraded from 10.0 to 12.0. it was not until i reset a large number of settings including footswitch settings that the sound went back to the good setting.

also - this bad sound setting has persisted for many versions of the firmware. it does not look like anyhign that is specific to the firmware version, but instead a bad setting or settings which have been carried all of the way through early firmware versions until 12.0. it was not until i reset many parameters via teh fm3 - include footswitch/midi/cc settings that the sound went back to normal.

the goal here is to figure out what setting gave me the bad sound.
file formats. 
you need to understand fractal fm3 syx file formats. i have cloned several repos and previously built source code used on understanding the fractal syx format. 

resources/folders: 
C:\git\internal\Prompts\patterns - existing patterns/guidelines for writing code. 
C:\git\internal\fm3_analysis\audio - raw DI guitar tracks that can be run through the signal chain and then measured. 
C:\git\external\fm3 - this contains a number of github repos related to the fractal or fractal fm3 products. they were not created by me but can contain information about the fractal range of multi-fx pedals.
C:\git\internal\FM3FirmwareAnalyzer - this is a previous attempt at decompiling the fm3 firmware and analyzing it. we had limited success here. 
C:\git\internal\fm3_analysis - this is a tooling folder based on the patterns in this folder - C:\git\internal\Prompts\patterns. there is an orchestration script which is used to iterate and provide a high-quality framework for debugging or troubleshooting. it is based on powershell and has either a build (used for software compilation) or tooling function (the one where are using here.). the main file is C:\git\internal\Prompts\agents.md which is the starting point for understanding all of the patterns/practises/guidelines.

there is the fractal wiki: https://wiki.fractalaudio.com/wiki/index.php?title=Fractal_Audio_Wiki_Home. i have saved a file as C:\git\external\fm3\fractal-wiki. the https://wiki.fractalaudio.com/wiki site is an excellent technical resource although it may not have all of the information required to complete the task.

create a document per phase - eg phase-#{phase-name}.md which contains the implementation plan for the plan phase. 
eg 
phase plan = plan.md
phase write_syx_tool = plan-write_syx_tool.md

Here are the phases of the task:

phase: plan.
go into the following folders and find out everything you can about syx formats. if you have questions tell me and i will try & help you.

phase: write_skills.
write a skills file about everything that you can derive about the syx file format. 

phase: write_fm3_configuration_tool.

under the C:\git\internal\fm3_analysis\src\FM3Config folder - we need to write a fm3 config tool. it should fit into the C# & orchestration scripts patterns mentioned under the patterns folder. The primary purpose of this is to get and/or verify the following system parameters on the Fractal FM3 -
Input 1. the input 1 source can be set to either analog or usb input 3/4. analog represents the physical input 1 on the fm3 where you would plug your guitar into. usb input 3/4 on the fm3 corrospond the fm3 audio output channels 3/4 on this machine. it effectively lets us send audio directly to the fm3 via usb audio output instead of audio via guitar cable from another device. when set to usb channels 3/4 this corrosponds to an input 1 block in the fm3 signal chain. 
USB 3/4 record source. this corrosponds to the output 2 block at the end of the signal chain. if we use the usb output 3/4 channel we can monitor what has been sent to the input 1 block via the usb input 3/4 option. this gives us effectively a loopback interface that we can send a known signal to the fm3 output audio device on channel 3/4 on the host machine and then record the fm3 input audio device on channel 3/4 on the hostname. if we have no effects loaded in the signal path the output should match the input very closely as there is only digital processing involved here. 
i don't want any code that would write to the fm3. i will do the configuration on the device and we can use it to verify the changes in fm3_configuration_tool. 


phase: audio_compare.

under C:\git\internal\fm3_analysis\src\FM3BlockLevels we have written audio code related to measuring the sonic qualities of audio. i want to extend this to being able create a visualization for the good/bad audio scenarios. the goal here is to use input audio 3/4 channels on the fm3 to send a known signal (the files referenced in the audio folder containing the raw guitar DI tracks.) and then record the same audio on input channel 3/4 on the host machine. we can build a visualization for the baseline and then use it to test different presets/settings on the fm3.

some/most of this code already exists in the C:\git\internal\fm3_analysis\src\FM3BlockLevels repo. we need to extend it to generate visualization data now. this should fit into the existing CI pattern for FM3BlockLevels.
update the console app we need to support the following workflow. 

i want to use a reference file to generate output .wav files for different settings/scenarios. eg add a command line parameter that uses the command line option:

-RunTestScenario "scenario1" - this is json file that defines each of the test scenario. it has an input .wav file and a named output .wav file.  this will allow me to generate a named .wav file & metadata about the test. 
and
-scenariosToCompare ["scenario1","scenario2","scenario3"] -referenceAudio .wav . this will compare all of the .wav files generated during each scenario and use the visualization library to create each of the EQ /frequency spectrum charts. note the reference .wav will be unprocessed audio so its EQ/frequency spectrum is expected to be significantly different than the ones generated during the scenario.
-excludeRererenceFile. defaults to false. this shows the EQ/spectrum of the original reference file. 
-showDiff. calculate the volume difference between the two of the selected spectrums. eg i can show the diff between 
    - the reference file and scenario 1
    - the reference file and scenario 2
    - the scenario 1 and scenario 2 output files.
    - the scenario 1 and scenario 3 output files.

i shoud be able to enable/disable visibility in the .html report each of the combinations of frequency spectrum reports and the selected options. eg if i uncheck either a frequency spectrum display or a comparison it should be disabled in the chart. i can then re-enable any of all of the datasets. 

 
phase: write_fm3_loopback_audio_testing.

don't write any plan/code yet for this.

phase: syx_tool.

Create a netcore console app under C:\git\internal\fm3_analysis\src\FM3SyxTool. this is a tool that that can be used to tell me what setting has changed in the good_sound & bad_sound folders to give the change in the audio from my fm3. 

Initially we only want to do the plan & write-skills phase. first - go and research of the resources/folders, then do the analysis on what each of the codebases can tell you about the fm3 syx file format. once we have that we we can write a skills document that is a guide to what the syx file contains. 

important: go and do the research first. 
don't do any commands line operations except to research the problem. But importantly a) use the tooling pattern to create any a command line tools or powershell functions that help you do the research, and do the research first & write a skills document. write the skills document to C:\git\internal\Prompts\component_prompts\solutions\FM3SyxTool\syx_file-format.md. use plaintext here. no decoration, annotations or indenting please. 


