prompt.md is C:\git\internal\Prompts\component_prompts\solutions\FM3BlockLevels\prompt.md
plan.md is C:\git\internal\Prompts\component_prompts\solutions\FM3BlockLevels\plan.md 

read prompt.md. i have reformatted the prompt from numbered phases to named phases. the task is to first rewrite the plan.md file for the application.
note what are changes in prompt.md only deal with sections that are changed. 

update plan.md to re-use named files and not numbered. move phase information from plan.md into it's owned named file - eg phase-wav_audio.md which contains the implementation plan for the wav_audio phase. 
only leave generic guidelines in plan.md. plan.md should not contain any reference to numbered phases afterwards. dont mark them as moved or depreciated. just write new information into the new plan file. 

application_profiles - this is a new feature so we can use named profiles to store test configuration so that we need not need to have long command lines. 
wav_foundation. this is related to any audio library code and not audio visualization.

wav_audio - the .wav files we created are corrupt. remove any code that we use for processing .wav files. we should be reliant on the cscore nuget package which is a nuget package for audio processing. note that it can also access an audio interface. do not use cscore for this - we are still using naudio for any audio card operations. cscore is used for processing .wav files. the source code for csscode is under C:\git\external\audio

audio_visualization - there are several audio visualization source code repos under C:\git\external\audio_visualization. AVsharp is a wpf library for doing audio visualization. do the analysis on the audio visualization requirements and review all the code patterns under C:\git\external\audio_visualization to see if there is any existing source code that covers the visualization requirements. we should be using that intead of writing new code where possible. 

audio_compare - do not write any plans here yet.

application_gui. do not write any plans here yet. 