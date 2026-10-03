test scenario:

verify audio using .wav file. 
use the DI metal guitars.wav file
use the NoopLv2plugin.
start the audio stream. 
when the .wav file ends the audio device should close. 
verify the audio file versus the original. it should be the same due to the NoopLV2Plugin.

verify audio using .wav file. 
use the DI metal guitars.wav file
use the TinyGain plugin.
start the audio stream. 
when the .wav file ends the audio device should close. 
verify the audio file versus the original. it should be almost the same due to the 20hz low pass filter.

verify audio using .wav file. 
use the DI metal guitars.wav file
use the TinyGain plugin. set the preset as 'default'.
start the audio stream. 
when the .wav file ends the audio device should close. 
verify the audio file versus the original. it should be almost the same due to the 20hz low pass filter.


verify audio using soundflow.
use the TinyGain plugin. set the preset name as default.
start the audio stream. 
run the audio test for 1 seconds. 
use this pattern:
<code>
TimeSpan timeToFinishTest = DateTime.Now.Add.Seconds(1)
while (DateTime.Now > timeToFinishTest)
{
    //use some technique to return control to this thread.
}
//stop audio stream
</code>

verify the audio file versus the original. it should be almost the same due to the 20hz low pass filter.


verify audio using soundflow.
use the RataRatatouille plugin. set the preset name as Ratatouille-Nam-chug-preset. create it under ~/.lv2/Ratatouille if it does not exist.
Start the audio stream. 
run the audio test for 1 seconds. 
use this pattern:
<code>
TimeSpan timeToFinishTest = DateTime.Now.Add.Seconds(1)
while (DateTime.Now > timeToFinishTest)
{
    //use some technique to return control to this thread.
}
//stop audio stream
</code>

do not verify the audio.