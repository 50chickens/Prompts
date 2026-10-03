these are things we tried but have not worked. 

phase fm3-library_real_time_levels

i have moved FakeFm3RealtimeService to the unit test project. you probably need to check references. the goal now is to create the library that can connect to the fm3 and get the real time levels of all of teh blocks in the signal chain. i am not sure if it was usb midi or usb serial that we used last time. go and read the documentation under C:\git\internal\fm3_analysis\documentation about how to do this. 

library the library first - then re-wire the console application to use this library. then in the AudioLevels.ConsoleApp.Tests project create an integration test that passes if we can get atleast 1 level from 1 block on the fm3. 

some of the original analysi was trying to reverse engineer the firmware backups to see what we could derive from those. is there anything under C:\git\internal\fm3_analysis\other\firmware or C:\git\internal\Prompts\component_prompts\solutions\FM3SyxTool that can help. there is also the C:\git\internal\fm3_analysis\src\FM3SyxTool tool we wrote. note there are two use cases to .syx - one is for device backups and the other is for firmware updates but both are .syx. the goal here to is figure out if we can get real time block levels from the device in any way - serial, usb, other. 

phase consolonia_nunit_test

go and read C:\git\internal\Prompts\component_prompts\solutions\FM3BlockLevels\phase_consoleonia_realtime_application.md.. ths is an analysis of the fm3-edit UI. i want to rebuild it in consolonia which is a text version of avalonia. 

i have a sample csproj - C:\git\internal\fm3_analysis\src\FM3BlockLevels\AudioLevels.ConsoleApp which it has given me some code to start with (and is not complete). under phase_consoleonia_realtime_application.md it has instructions on what would be required for the application and unit tests. 

for the unit tests read the documention on the correct Nunit implementation - C:\git\external\Consolonia\src\Consolonia.NUnit\readme.md the problem we had before with the avalonia UI you built is that i asked unit tests but the UI you built was empty. none of the real time data from the fm3 was there. the goal here is to use the Alsionyx.Library.Fm3.Realtime and a corrosponding Alsionyx.Services.Fm3.Realtime (yet to be created) to show real time levels of each of the blocks in the fm3 signal chain. 
Go and implement the UI and the tests. the success criteria is that the ConsoleApp shows the real time block levels in the console app. 

The fm3 is connected on COM7 in this environment but if the tests fail that is ok. 

What tests to the ConsoleApp.Tets perform? what im after is that the fm3 block levels are working and streaming data from the fm3 (eg updating in real time). do these tests validate that? 

block levels where we are querying the fm3 for might be difficult to unit test as they represent a value at a point in time. maybe you can add a start/stop/pause workflow into the application and check for a non zero value for some block levels. 

most importantly - there is a 4 x 12 grid in the fm3-edit that the console app should also have. this  4 x 12 grid should have the same blocks that the fm3 has and show the connections and block levels. the consolonia nunit test projects allow for us to test to ensure that text UI is showing both of those things. 