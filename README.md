# Aruco-arkit-localizer

Bare-bones Arkit demo using opencv ArUco markers to obtain camera pose as a means of registering ARKit to real world space in order to persist objects between AR sessions. 

## Getting Started

1. Print marker23.png included in the build and measure the printed asset. Enter that measurement in meters at line 13 in ARViewController.swift. You can print additional markers using OpenCVWrapper.getMarkerForId(). See line 58 in ARViewController.swift. Build to a device.

2. Launch app and once ARkit has established tracking a 'localize' button will appear.  Point your camera at the printed marker and click the localize button. Once sucessfully localized you should see a beautiful blue pyramid placed over the marker. 

3. Now you can add AR objects (red boxes) around your physical enviornment. 

4. Hit save. 

5. Relaunch the app, and again localize to the marker. Assuming the marker has not been moved, you can now load in the objects previously saved at the same positions in real world space.

## Known Issues & Improvements

This demo has so far worked on a iphone 6s+ and 7s. I have not tested on any other devices. 

I am not sure exactly why, but every once and a while the pose estimation can be slightly off. Often this occurs between successive attempts with almost no change in camera image. 

Instead of a obtaining camera pose as a one-time event it might be benefitial to perform pose estimation over multiple frames  to update or average out an ongoing transformation offset.

Unity demo coming soon.

## Aknowledgements

I found the following sources particularly helpful in getting this demo working.

http://ksimek.github.io/2012/08/14/decompose/

https://docs.opencv.org/3.1.0/d5/dae/tutorial_aruco_detection.html

https://stackoverflow.com/questions/44257592/scenekit-3d-marker-augmented-reality-ios
