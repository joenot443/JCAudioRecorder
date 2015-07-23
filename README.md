###JCAudioRecorder

Simple audio recorder I built for iOS in Objective C using AFAudioFoundation.

##About

I built this for a previous project and thought it worked pretty effectively so I cleaned it up and made it good for general use. 

It's *heavily* commented, largely for the benefit of new users reading it who want to get more familiar with AFAudioFoundation.

##Usage

Just add the image files, JCAudioRecorder.h/.m and either copy the .xib from the Storyboard or build your own. 
Outlet as necessary. Be sure to add AFAudioFoundation.framework to your project too.

JCAudioRecorder has a .audioData NSData property which is populated upon tapping stopped. Use that to access the data. Alternatively, the track is saved as sound.caf in the NSDocumentsDirectory. 

##Example

![JCAudioRecorder](http://i.imgur.com/nTppRmO.gif)
