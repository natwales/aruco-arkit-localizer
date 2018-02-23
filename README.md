# Aruco-arkit-localizer

Barebones example of using Aruco markers and opencv to localize ARKit and persist objects between AR Sessions. 

## Getting Started

Print marker23.png in the build and measure the printed asset. Enter that measurement in meters at line 13 in ARViewController.swift. You can print additional markers using OpenCVWrapper.getMarkerForId(). See line 58 in ARViewController.swift.

Build to a device. Once ARkit has established tracking you can localize to a marker. You should see a beautiful blue pyramid overlaid over the marker. Once localized you can drop objects into the scene and save them locally to the device. Relaunch the app, localize to the marker and then load in the objects you previously saved.
