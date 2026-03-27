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

i want to use a reference file to generate output .wav files for different settings/scenarios and group them into a single dataset. eg add a command line parameter that uses the command line option:

-dataSet "dataset1" dataset is a folder underneath the running binaries folder. create it not exist. the folder name is the name of the dataset. each dataset folder should contain seperate timestamped testscenario json files for each of the test scenarios. individual runs of the test scenario should create a new timestamped .json file under the dataset folder. The default dataset name is DataSet1 if it's not supplied. 
-RunTestScenario "scenario1" - this is defines each of the test scenarios. it has an input .wav file and a named output .wav file a description, timestamp and other useful metadata.  this will allow me to generate a named .wav file & metadata about the test. 

Remove any code that relates to generating a .html file in this phase. do not mark it decomissioned or add comments about it. remove it entirely. we will re-add it later on. 

phase audio_compare_test_requirements
i have reset the speaker impulse curve under FM3-260321-080610-system+gb+fc.syx

i now want to use the FM3BlockLevels console app to measure the impulse response of the FM3. i have reset all of the audio settings and also removed all of the effects blocks in the signal chain. in the signal chain there is a connection from the input 1 block to the output 1 and output 2 blocks. 
i have also set the input 1 source to be usb 3/4. 

if you send a known signal to the FM3 audio card output on the host device on channel 3/4 you can then record the fm3 audio card input on the host device on channel 3/4 (which corrosponds to the output block 2 in the fm3 signal chain). this will be able to give an impulse response of the signal chain which i expect to be 0 but we should measure it. 

can you use FM3BlockLevels to do this. create a testing scenario for this and then run the test. 
rerun the test - im expecting that the THD values are also included. the usb buffer size on the fm3 was set to 192 for the last test. i have changed it to 96. 
was the source audio file set to C:\git\internal\fm3_analysis\audio\Metal Guitar DI.wav. this is the reference .wav file 

the usb playback levels are confirmed as 0.00 db. the input gain on the physical input 1 is confirmed as 1.00 (which i assume is 0 db gain, or some standard value)

it might also be possible to include getting the individual block levels (possibly even the audio) while running the test using Fm3SerialClient. there are only 4 blocks in the signal chain - input 1 -> pitch (disabled) -> output 1 and output 2 (there is a splitter so that the output from the pitch block goes to both ouput 1 and output 2 blocks).  so you can see if this is possible. add it to the test suite if you can.
phase test_setup.

i dont know if it's possible - but for the loop back test there are a few criteria:

1. input 1 must be connected to output 2 block. 
the preset called "straight thr" (preset number 496 has this). other presents can have some unknown/unusable signal chain. add a check that input 1 is connected to output 2 in the signal chain. fail the test if that is not the case. do not check for a preset name or number. is there any way to validate the active preset. 
2. in the system settings the source for input 1 must be set to usb channels 3/4. 
3. in the system settings the usb 3/4 record source must be set to output 2. 

i dont know if it's possible to verify those prior to the test. 

also - if Com7 is not able to be opened do not start the test. if we are able to show the block levels via the usb serial connection i want that included in the test so if you cannot open the usb serial connection do not start the test. for reference i have closed fm3-edit which would have been using it. 

lastly - have reset the physical output 2 dial on the device to around 66%. i do not know if this will affect the dbfs levels on output 2 (i have seen actual changes on the levels of audio being sent out the physical output 2 connection but i do not know if the digital output block 2 levels would be affected). other than that i have not changed any other setting since the last test. the physical settings for the output 1 and outpu 2 dials are available in the 

Recommended changes to the test runner
Replace the WAV THD step with:

Correlation + error RMS (reference vs captured, latency-aligned)
Log sweep at -18 dBFS → frequency response magnitude + phase

phase previous_implementation_review.

go and look in C:\git\internal\fm3_analysis\fm3_analysis\to_be_checked. there are two c# solutions that was created as a previous attempt we had at showing the block levels using usb serial and troubleshooting the audio problem. we created documentation and some csharp projects and reference code. is there anything from those original attempts that is useful here. once you have checked each file any new insights move it under C:\git\internal\fm3_analysis\fm3_analysis\has_been_checked. keep the same over file system layout. once completed im expecting to see teh same files in the same folders except that they now live under C:\git\internal\fm3_analysis\fm3_analysis\has_been_checked instead of C:\git\internal\fm3_analysis\fm3_analysis\to_be_checked.
dont write a plan but check the documentation folder. there might be documentation that is either wrong or these c# files contains new insight. go and update them if need be. be careful with adding new content. i dont want two versions of content that conflicts with each other.

phase fm3_wiki_download

there is the url: https://wiki.fractalaudio.com/wiki/index.php?title=Fractal_Audio_Wiki_Home

i have downloaded some of the content on this wiki but not all. there might be useful content within that site. can you write a script to download the entire of the wiki (or do it manually) into C:\git\internal\fm3_analysis\documentation\wiki

also - include all known block types for the fm3 under public static readonly IReadOnlyDictionary<int, string> KnownBlockNames = new Dictionary<int, string> if it's not already done. 

the focus should be rerunning the baseline audio tests. don't get distracted. if you have enough info to do this do the audio tests first. 


phase: audio_dataset_visualization


-dataSet "dataset1" -scenariosToCompare ["scenario1","scenario2","scenario3"] -referenceAudio .wav . this will compare all of the .wav files generated during each scenario and use the visualization library to create each of the EQ /frequency spectrum datasets. note the reference .wav will be unprocessed audio so its EQ/frequency spectrum is expected to be significantly different than the ones generated during the scenario.
-excludeRererenceFile. defaults to false. this shows the EQ/spectrum of the original reference file. 
-showDiff. calculate the volume difference between the two of the selected spectrums. eg i can show the diff between 
    - the reference file and scenario 1
    - the reference file and scenario 2
    - the scenario 1 and scenario 2 output files.
    - the scenario 1 and scenario 3 output files.

 
phase: write_fm3_loopback_audio_testing.

don't write any plan/code yet for this.

phase: syx_tool.

Create a netcore console app under C:\git\internal\fm3_analysis\src\FM3SyxTool. this is a tool that that can be used to tell me what setting has changed in the good_sound & bad_sound folders to give the change in the audio from my fm3. 

Initially we only want to do the plan & write-skills phase. first - go and research of the resources/folders, then do the analysis on what each of the codebases can tell you about the fm3 syx file format. once we have that we we can write a skills document that is a guide to what the syx file contains. 

important: go and do the research first. 
don't do any commands line operations except to research the problem. But importantly a) use the tooling pattern to create any a command line tools or powershell functions that help you do the research, and do the research first & write a skills document. write the skills document to C:\git\internal\Prompts\component_prompts\solutions\FM3SyxTool\syx_file-format.md. use plaintext here. no decoration, annotations or indenting please. 


Phase unknown_settings.

i have created a new backup. the settings in the sytem page and what i have done are in the notes.txt. C:\dev\music\fm3\backups\backups_with_broken_sound\copilot_testing\current_backup_for_analysis5
the goal here is to check if there are any bad settings left. the sound is very good but im wondering if there are any settings i have missed or anything that can cause problems in audio quality later. 

how can i test what this is:

Block 0, param 59 (BAD=128, GOOD=0) is the second half of the flag swap — not in the registry yet. Since param 47 is Input 1 Pad, param 59 could be Input 2 Pad or a related input section setting.

Is there something i can set it the UI and either you can check the runtime value, or i can do another backup to identify it. or are there any parameters of setting you don't know where we can try and identify it? 
