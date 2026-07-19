# V4 – Frequently Asked Questions (FAQ)

Version 4 is the largest update since the project was revived. It fundamentally changes how Focus Point Viewer integrates with Lightroom. You can now keep the viewer open while continuing to work in Lightroom, choose between multiple rendering methods depending on your workflow, and benefit from significantly faster image display.

These new capabilities also introduce new interactions between the plugin and Lightroom. As a result, you may occasionally notice behavior that differs from what you would normally expect from a native Lightroom feature. In most cases, this is due to limitations of the Lightroom SDK rather than the plugin itself.

This FAQ explains the most common questions about Focus Point Viewer in Second Screen mode, the reasons behind certain behaviors, and the available workarounds where applicable.



## Questions

Display modes:

* [Why does `Direct View` display grey boxes around the AF corner markers on Windows? Is my GPU the cause?](#why-does-direct-view-display-grey-boxes-around-the-af-corner-markings-on-windows-is-my-gpu-the-cause)

* [Why are the `Preview Image` and `Export Image` display modes unavailable on macOS?](#)

Second Screen mode:

* How can I stop Focus Point Viewer from switching back to the primary screen on macOS?

* How can I prevent Focus Point Viewer from automatically becoming the active window whenever a new photo is loaded in `Follow` mode?

* Why doesn't Focus Point Viewer accept keyboard input immediately after opening in `Interactive` mode on Windows?

* Why does the Focus Point Viewer window always stay on top in Windows?

* Why do the Left and Right Arrow keys sometimes stop working in Lightroom when Focus Point Viewer is running in `Follow` mode?

* Why do I have to click twice to open a photo in Focus Point Viewer from Grid view, while a single click is enough in Filmstrip view?
  
* Why do empty margins appear on the right or bottom of the Focus Points Viewer window when I change its size in 'Second Screen' mode?  

General:

* How can I set up a hotkey to open the Focus Points Viewer? 



## Q&A


#### Why does `Direct View` display grey boxes around the AF corner markings on Windows? Is my GPU the cause?

`Direct View` on Windows produces corner markings with rectangular artifacts around the overlay images:

<img src="images/Display%20Modes.jpg" alt="Direct View on Windows" style="width:600px;"/><br>

This is due to inconsistent behavior of the underlying Lightroom SDK function when using transparent PNG overlays in overlapping layouts on Windows vs macOS. See xxx for more details and what you can do to get this issue fixed.



### Why are the `Preview Image` and `Export Image` display modes unavailable on macOS?

The `Preview Image` and `Export Image` display modes require the third-party tool ImageMagick to be integrated with the plugin on macOS. This is not available in V4 PRE 1, but it is planned for an upcoming pre-release. See xxx for more information. 







### How can I stop Focus Point Viewer from switching back to the primary screen on macOS?

### How can I prevent Focus Point Viewer from automatically becoming the active window whenever a new photo is loaded in `Follow` mode?

### Why doesn't Focus Point Viewer accept keyboard input immediately after opening in `Interactive` mode on Windows?

### Why does the Focus Point Viewer window always stay on top in Windows?

### Why do the Left and Right Arrow keys sometimes stop working in Lightroom when Focus Point Viewer is running in `Follow` mode?

### Why do I have to click twice to open a photo in Focus Point Viewer from Grid view, while a single click is enough in Filmstrip view?
  
### Why do empty margins appear on the right or bottom of the Focus Points Viewer window when I change its size in 'Second Screen' mode?  

### How can I set up a hotkey to open the Focus Points Viewer? 

