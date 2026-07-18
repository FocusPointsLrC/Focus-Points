# V4 – Frequently Asked Questions (FAQ)

Version 4 is the largest update since the project was revived. It fundamentally changes how Focus Point Viewer integrates with Lightroom. You can now keep the viewer open while continuing to work in Lightroom, choose between multiple rendering methods depending on your workflow, and benefit from significantly faster image display.

These new capabilities also introduce new interactions between the plugin and Lightroom. As a result, you may occasionally notice behavior that differs from what you would normally expect from a native Lightroom feature. In most cases, this is due to limitations of the Lightroom SDK rather than the plugin itself.

This FAQ explains the most common questions about Focus Point Viewer in Second Screen mode, the reasons behind certain behaviors, and the available workarounds where applicable.



## Questions

Display modes:

* Why does `Direct View` display grey boxes around the AF corner markers on Windows? Is my GPU the cause?

* Why are the `Preview Image` and `Export Image` display modes unavailable on macOS?

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


### Why does `Direct View` display grey boxes around the AF corner markings on Windows? Is my GPU the cause?

`Direct View` on Windows produces corner markings with rectangular artifacts around the overlay images:

<img src="images/Display%20Modes.jpg" alt="Direct View on Windows" style="width:600px;"/><br>

This is due to inconsistent behavior of the underlying Lightroom SDK function when using transparent PNG overlays in overlapping layouts on Windows vs macOS. See xxx for more details and what you can do to get this issue fixed.



### Why are the `Preview Image` and `Export Image` display modes unavailable on macOS?

The `Preview Image` and `Export Image` display modes require the third-party tool ImageMagick to be integrated with the plugin on macOS. This is not available in V4 PRE 1, but it is planned for an upcoming pre-release. See xxx for more information. 







---
### <sup>1)</sup> Focus Point Viewer does not remember its position on a secondary monitor on macOS

**Effect:** On macOS, the Focus Point Viewer remembers the correct position on the screen when reopening, but not the correct screen. When you drag the plugin window to a secondary screen and select another image it will reopen on the primary screen.

**Reason:** Inconsistent behavior of the underlying SDK function to open a floating dialog on Windows vs macOS.

**Current status:** Adobe has acknowledged the issue and a bug report has been filed.  
[https://community.adobe.com/bug-reports-674/p-mac-sdk-floating-dialog-does-not-reopen-on-second-screen-1628255](https://community.adobe.com/bug-reports-674/p-mac-sdk-floating-dialog-does-not-reopen-on-second-screen-1628255)

**Workaround:** Use the Focus Point Viewer alongside Lightroom on the primary screen.

**How you can help:** If this issue affects your workflow, **please vote** for the Adobe bug report. Community votes help increase its visibility.

<br>

---

### **<sup>2)</sup> Focus Point Viewer always becomes the active window when opened**  

**Effect:** This prevents a smooth 'Follow Lightroom' behavior. Whenever Focus Point Viewer opens or refreshes after selecting another photo, it becomes the active window and receives keyboard input. This interrupts keyboard-driven Lightroom workflows until Lightroom is clicked again.  

**Reason:** Lightroom SDK does not allow to specify whether a floating dialog should be activated or not when opened. 

**Current status:** Adobe has acknowledged the issue and a bug report has been filed.   
[https://community.adobe.com/bug-reports-674/p-keyboard-input-routing-of-floating-dialogs-depends-on-prior-sdk-calls-1631366](https://community.adobe.com/bug-reports-674/p-keyboard-input-routing-of-floating-dialogs-depends-on-prior-sdk-calls-1631366)

**Workaround:** Use [AutoHotkey companion script](#6-autohotkey-companion-script-for-windows) on Windows.

**How you can help:** If this issue affects your workflow, **please vote** for the Adobe bug report. Community votes help increase its visibility.

<br>

---

### **<sup>3)</sup> Keyboard shortcuts do not work immediately after opening Focus Point Viewer in Interactive mode on Windows.** 

**Effect:** In Second Screen Interactive mode, the Focus Point Viewer is the active window but keyboard input is not received until the user presses Tab, Left Arrow, Down Arrow or clicks a UI control.   

**Reason:** Inconsistent behavior of the underlying SDK function on Windows vs macOS.

**Current status:** Adobe has acknowledged the issue and a bug report has been filed.  
[https://community.adobe.com/bug-reports-674/p-floating-dialogs-are-opened-without-initial-keyboard-focus-1631363](https://community.adobe.com/bug-reports-674/p-floating-dialogs-are-opened-without-initial-keyboard-focus-1631363)

**Workaround:** Use [AutoHotkey companion script](#6-autohotkey-companion-script-for-windows) on Windows.

**How you can help:** If this issue affects your workflow, **please vote** for the Adobe bug report. Community votes help increase its visibility.

<br>


--- 

### **<sup>4)</sup> Focus Point Viewer windows is always on top in Second Screen mode on Windows**

**Effect:** In Second Screen mode on Windows, the Focus Point Viewer is always displayed at the top of all visible windows on the screen. It is not possible to bring other windows to the top. This limits usability, particularly when the Focus Point Viewer overlaps with applications that the user wants to run simultaneously. 

**Reason:** Recent changes by Adobe with respect to handling of floating dialogs. Earlier, floating dialogs were always in back, never in front. Now it's the opposite:  
[https://community.adobe.com/bug-reports-674/p-sdk-floating-dialogs-always-in-back-never-in-front-in-screen-mode-full-screen-on-windows-664457](https://community.adobe.com/bug-reports-674/p-sdk-floating-dialogs-always-in-back-never-in-front-in-screen-mode-full-screen-on-windows-664457)

**Current status:** New bug report to be filed with Adobe (by user aboswrt)

**Workaround:** None.

**How you can help:** If this issue affects your workflow, **please vote** for the Adobe bug report. Community votes help increase its visibility.

<br>

--- 

--- 

### **<sup>6)</sup> Preview Image and Export Image are not yet available on macOS**

**Effect:** macOS users are limited to using Direct View. While this display mode has many advantages, its use of corner markers may lack visual clarity to indicate focus points, detected faces and subjects, particularly if there are multiple marked areas in the photo. Preview Image and Export Image use full rectangle overlays which can improve visual clarity. 

**Current status:** Prepare work on integration of ImageMagick for macOS.






## 6. AutoHotkey Companion Script for Windows

**Windows users:** Focus Point Viewer now includes an optional AutoHotkey companion script that automatically works around two current Lightroom SDK limitations affecting Second Screen mode.

Limitations 2) and 3) prevent a smooth user experience in Follow and Interactive modes. As this would significantly reduce the plugin's effectiveness when used in these modes, considerable effort has been invested in finding workarounds.  

These workarounds have been implemented in an AutoHotkey script called `FixSecondScreen`, which is included in the plugin installation package. The script is provided in both source code and compiled executable formats.  




### Installation

The `FixSecondScreen.exe` file can be found in the `ahk` folder of the `focuspoints.lrplugin` folder.  
To activate the fix, run the executable and drag it to your Windows Startup folder, so that it is automatically available each time you start Windows. A green icon in the system tray indicates that the script is active.




#### **<sup>2)</sup> Focus Point Viewer always becomes the active window when opened**  
While Follow mode is open, the watcher keeps Lightroom as the active application so that keyboard navigation continues to work. The watcher virtually clicks into Lightroom as soon as a window with the title 'Focus Points Follow ...' becomes the active window. 

Consequently, minimizing Lightroom while the Follow window is visible immediately restores Lightroom. Minimize or close the Follow window first if you want to minimize Lightroom.

Also, it is not possible to operate the plugin using keyboard shortcuts with the fix enabled.


#### **<sup>3)</sup> Keyboard shortcuts do not work immediately after opening Focus Point Viewer in Interactive mode on Windows.**

While Interactive mode is open, the watcher ensures that the Focus Points dialog receives keyboard input. As soon as a window with the title 'Focus Points Interactive ...' is detected, the watcher activates this window and virtually presses the Down Arrow key, causing the keyboard shortcut entry field to receive keyboard input.   

<br>

Note: The content of `FixSecondScreen` could also have been included in the `FocusPointsHotkey` script, but it has been deliberately separated to allow users to run either script independently or both together.

