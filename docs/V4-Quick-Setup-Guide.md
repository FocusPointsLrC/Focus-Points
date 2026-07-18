# V4 – Quick Setup Guide

This document describes the basic steps for setting up the plugin in Second Screen mode.

Some steps are specific to the operating system (OS) you are running. To keep things simple, there are separate sections for **[Windows](#setup-on-windows)** and **[macOS](#setup-on-macos)**.


## Setup on Windows

1. Download and install the plugin [↗](Focus-Points.md#21-installation)
2. Load the AutoHotkey companion script [↗](V4-New-Features.md#6-autohotkey-companion-script-for-windows)<br>
   This script works around current Lightroom SDK limitations to provide a smoother experience in `Follow` and `Interactive` mode.
3. Optional: Load the AutoHotkey script to use a keyboard shortcut to run the plugin [↗](Focus-Points.md#windows)
4. Configure plugin settings:<br>
   Select `Focus Point Viewer` from the list of installed plugins (_Library → File → Plug-in Manager_) and check the `User Interface` section:<br><br><img src="images/Quick%20Setup%20WIN.jpg" alt="Second Screen 1" style="width: 600px;"/><br>
 
   1. `Second Screen` mode and behavior [↗](V4-New-Features.md#13-configuration):<br>
      1. Set `Second Screen` to `On` to continue working in Lightroom while the Focus Points window remains open.
      2. Choose whether you want Focus Point Viewer to `Follow` while you're working in Lightroom or if you want to use it interactively.
      3. Select the aspect ratio used in Second Screen mode.<br><br>     
   1. `Controls for flagging, rating and coloring a photo` [↗](Focus-Points.md#enable-controls-for-flagging)<br>
      1. These controls were originally introduced because Lightroom could not be accessed while Focus Points Viewer was open. This is normally not required in second screen mode. You can set it to `Off`, which will make the control bar look less cluttered.
      2. If you also want to use these controls in Second Screen mode, select your keyboard layout. [↗](Focus-Points.md#keyboard-layout)<br><br> 
   1. `Display mode` [↗](V4%20New%20Features.md#2-display-modes)<br>
      1. In `Interactive` mode, `Preview Image` is a strong recommendation. The use of `Direct View` is currently impaired by a Lightroom SDK limitation [↗](V4%20New%20Features.md#5-direct-view-corner-icons-do-not-seamlessly-blend-with-the-photo-when-used-on-windows).
      2. In `Follow` mode, you may consider `Direct View`, particularly if you are not interested in viewing every photo but only specific ones. `Direct View` is fast and runs entirely in-memory. `Preview Image` involves disk operations that may slightly impair the user experience in Lightroom.   
      When you want to inspect a particular photo, you can temporarily switch the display mode to update the image. [↗](V4%20New%20Features.md#21-changing-the-active-display-mode-on-the-fly)<br><br> 
   1. Optional: `Preview Image` performance settings [↗](Focus-Points.md#how-to-reduce-long-wait-times-when-opening-the-plugin-window-on-windows)<br>
      In `Preview Image` display mode, the time to open Focus Points Viewer largely depends on whether a preview of the selected photo is available in Lightroom. If a preview is available, it can be obtained instantly. Otherwise, it can take several seconds for the plugin window to appear. <br>
   You can control how long to wait for a preview. If Lightroom cannot provide one within the given time frame, `Export Image` is used instead. If you are not satisfied with the results produced by the default setting of 0.5 seconds, the user manual provides detailed information on how to determine the best value for your setup. [↗](Focus-Points.md#how-to-reduce-long-wait-times-when-opening-the-plugin-window-on-windows)<br><br>
2. You're done!<br> 
   **You're ready to use Focus Point Viewer.** You can start it either by pressing the hotkey `NumPad *` (if configured in step 3) or by selecting `File → Plug-in Extras → Show Focus Point`.

<br>

## Setup on macOS

The macOS version currently requires less configuration because some V4 features are still under development or limited by the Lightroom SDK.

1. Download and install the plugin [↗](Focus-Points.md#21-installation)
2. Optional: Assign a shortcut to run the plugin [↗](Focus-Points.md#macos)
3. Configure plugin settings:<br>
   Select `Focus Point Viewer` from the list of installed plugins (_Library → File → Plug-in Manager_) and check the `User Interface` section:<br><br><img src="images/Quick%20Setup%20MAC.jpg" alt="Second Screen 1" style="width: 600px;"/><br>
 
   1. `Second Screen` mode and behavior [↗](V4%20New%20Features.md#13-configuration):<br>
      1. Set `Second Screen` to `On` to continue working in Lightroom while the Focus Points window remains open.
      1. Currently, `Interactive` is the recommended mode for macOS. Current Lightroom SDK limitations significantly limit the usability of `Follow` mode because the plugin window<br>
         - will not keep its position on a secondary display but switch back to the primary screen [↗](V4%20New%20Features.md#1-focus-point-viewer-does-not-remember-its-position-on-a-secondary-monitor-on-macos) 
         - will become the active window when opened, thus interrupting user operations in Lightroom [↗](V4%20New%20Features.md#2-focus-point-viewer-always-becomes-the-active-window-when-opened-)
   
         If the `Follow` workflow is important to you, **please vote** for the linked Adobe bug reports. Community votes help increase its visibility.
   
      3. Select the aspect ratio used in Second Screen mode.<br><br>     
   1. `Controls for flagging, rating and coloring a photo` [↗](Focus-Points.md#enable-controls-for-flagging)<br>
      1. These controls were originally introduced because Lightroom could not be accessed while Focus Points Viewer was open. This is normally not required in second screen mode. You can set it to `Off`, which will make the control bar look less cluttered.
      2. If you also want to use these controls in Second Screen mode, select your keyboard layout. [↗](Focus-Points.md#keyboard-layout)<br><br>
      
   **Remark:** V4 PRE 1 only supports `Direct View` on macOS. With the addition of `Preview Image` and `Export Image` in an upcoming pre-release, the `Display mode` settings  and the `Preview Image` performance control settings will also become available on macOS.<br><br>

4. You're done!<br> 
   **You're ready to use Focus Point Viewer.** You can start it either by pressing the hotkey `NumPad *` (if configured in step 2) or by selecting `File → Plug-in Extras → Show Focus Point`.
