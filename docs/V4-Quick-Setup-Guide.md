# Quick Setup Guide

### [Getting started with V3.x](#v3x-quick-setup-guide)

### [Getting started with V4](#v4-quick-setup-guide)

---

<br>

# V3.x Quick Setup Guide

Focus Point Viewer works well with its default settings. This guide only covers the few options you may want to adjust before using the plugin.

Some steps are specific to the operating system (OS) you are running.   
To keep things simple, there are separate sections for **[Windows](#setup-on-windows)** and **[macOS](#setup-on-macos)**.

<br>

## Setup on Windows

1. Download and install the plugin [↗](Focus-Points.md#21-installation)<br>
1. Optional: Configure a keyboard shortcut [↗](Focus-Points.md#windows) to launch Focus Point Viewer.<br>
1. Configure plugin settings:<br>
   Select `Focus Point Viewer` from the list of installed plugins (_Library → File → Plug-in Manager_) and check the `Screen Scaling` and `User Interface` sections:<br><br>
    <img src="images/Quick%20Setup%20V3x%20WIN.jpg" alt="Second Screen 1" style="width: 600px;"/><br>
    _The highlighted settings are the only ones that normally require attention. All other settings can safely remain at their defaults._<br><br>

   1. Set your preferred plugin window size.<br><br> 
      1. If you are using the Windows Display Settings to scale your display, you can use the `Screen Scaling` setting to apply the same or a similar setting for the plugin window. Otherwise the plugin window may exceed the dimensions of your screen. [↗](Focus-Points.md#screen-scaling)
      1. While the `Screen Scaling` setting can be used to normalize the plugin window size, the `Size of plugin window` setting can be used to define its dimensions. There are eleven sizes to choose from, ranging from `4XL` (90%) down to `XS` (40%). The percentage determines the size of the displayed photo relative to the dimensions of the Lightroom application window. [↗](Focus-Points.md#size-of-plugin-window)  
       You can also change the plugin window size later by using `<` and `>` keyboard shortcuts to make it bigger or smaller.<br><br>
   1. `Controls for flagging, rating and coloring a photo` [↗](Focus-Points.md#enable-controls-for-tagging)<br><br>
      1. If you want to use Focus Point Viewer in your image culling process, you can use these controls to tag images. If you don't, you can set it to `Off`, which will make the control bar look less cluttered.
      1. If you also want to use them, select your keyboard layout. This is required because the Shift-0..9 key combinations usually produce codes that depend on the keyboard layout. [↗](Focus-Points.md#keyboard-layout)<br><br> 
   1. `Preview Image` performance settings [↗](Focus-Points.md#how-to-reduce-long-wait-times-when-opening-the-plugin-window-on-windows)<br><br>
      On Windows, the time to open Focus Point Viewer largely depends on whether a preview of the selected photo is available in Lightroom. If a preview is available, it can be obtained instantly. Otherwise, it can take several seconds for the plugin window to appear. <br>
   You can control how long to wait for a preview. If Lightroom cannot provide one within the given time frame, `Export Image` is used instead. If you are not satisfied with the results produced by the default setting of 0.5 seconds, the user manual provides detailed information on how to determine the best value for your setup. [↗](Focus-Points.md#how-to-reduce-long-wait-times-when-opening-the-plugin-window-on-windows)<br>

1. **That's it! You're ready to use Focus Point Viewer.**<br> 
   You can start it either by pressing the hotkey `NumPad *` (if configured in step 2) or by selecting `File → Plug-in Extras → Show Focus Point`.

<br>

## Setup on macOS

The macOS version has fewer settings than the Windows version. The plugin does not depend on an OS display scaling factor. It uses the `Direct View` display mode, so there is no need to handle `Preview Image`. [↗](V4-New-Features.md#2-display-modes)

1. Download and install the plugin [↗](Focus-Points.md#21-installation)<br>
1. Optional: Assign a shortcut to run the plugin [↗](Focus-Points.md#macos)<br>
1. Configure plugin settings:<br>
   Select `Focus Point Viewer` from the list of installed plugins (_Library → File → Plug-in Manager_) and check the `User Interface` section:<br><br><img src="images/Quick%20Setup%20V3x%20MAC.jpg" alt="Second Screen 1" style="width: 600px;"/><br>
    _The highlighted settings are the only ones that normally require attention. All other settings can safely remain at their defaults._<br><br>

   1. `Controls for flagging, rating and coloring a photo` [↗](Focus-Points.md#enable-controls-for-tagging)<br>
      1. If you want to use Focus Point Viewer in your image culling process, you can use these controls to tag images. If you don't, you can set it to `Off`, which will make the control bar look less cluttered.
      1. If you also want to use them, select your keyboard layout. This is required because the Shift-0..9 key combinations usually produce codes that depend on the keyboard layout.  [↗](Focus-Points.md#keyboard-layout)<br>  

1. **That's it! You're ready to use Focus Point Viewer.**<br> 
   You can start it either by pressing the hotkey you configured in step 2 or by selecting `File → Plug-in Extras → Show Focus Point`.

<br>

# V4 Quick Setup Guide

This guide helps you configure the main new features introduced in V4, particularly Second Screen mode and the available display modes.

Some steps are specific to the operating system (OS) you are running.   
To keep things simple, there are separate sections for **[Windows](#setup-on-windows)** and **[macOS](#setup-on-macos)**.

## Setup on Windows

1. Download and install the plugin [↗](Focus-Points.md#21-installation)<br>
1. Load the AutoHotkey companion script [↗](V4-New-Features.md#6-autohotkey-companion-script-for-windows) to work around current Lightroom SDK limitations and provide a smoother experience in the `Follow` and `Interactive` modes.<br>
1. Optional: Configure a keyboard shortcut [↗](Focus-Points.md#windows) to launch Focus Point Viewer.<br>
1. Configure plugin settings:<br>
   Select `Focus Point Viewer` from the list of installed plugins (_Library → File → Plug-in Manager_) and check the `Screen Scaling` and `User Interface` sections:<br><br>
    <img src="images/Quick%20Setup%20V4%20WIN.jpg" alt="Second Screen 1" style="width: 600px;"/><br>
    _The highlighted settings are the only ones that normally require attention. All other settings can safely remain at their defaults._<br><br>
 
   1. `Second Screen` mode and behavior: [↗](V4-New-Features.md#13-configuration)<br>
       1. Set `Second Screen` to `On` to continue working in Lightroom while Focus Point Viewer remains open.<br>
       Set it to `Off` to use the plugin in its legacy mode, as in previous versions, where Lightroom could not be used while the plugin was open. 
       1. Choose whether you want Focus Point Viewer to `Follow` while you're working in Lightroom or if you want to use it interactively.
       1. Select the aspect ratio used in Second Screen mode.<br><br>     
   1. `Display mode` [↗](V4-New-Features.md#2-display-modes)<br>
      1. In `Interactive` mode, `Preview Image` is generally the recommended display mode. The use of `Direct View` is currently impaired by a Lightroom SDK limitation. [↗](V4-New-Features.md#5-direct-view-corner-icons-do-not-seamlessly-blend-with-the-photo-when-used-on-windows)
      1. In `Follow` mode, you may consider `Direct View`, particularly if you are not interested in viewing every photo but only specific ones. `Direct View` is fast and runs entirely in-memory. `Preview Image` involves disk operations that may slightly impair the user experience in Lightroom.  
      When you want to inspect a particular photo, you can temporarily switch the display mode to update the image. [↗](V4-New-Features.md#21-changing-the-active-display-mode-on-the-fly)<br><br> 
   1. Set your preferred plugin window size.<br>
       1. If you are using the Windows Display Settings to scale your display, you can use the `Screen Scaling` setting to apply the same or a similar setting for the plugin window. Otherwise the plugin window may exceed the dimensions of your screen. [↗](Focus-Points.md#screen-scaling)
       1. If you have a multiple-display setup and you want to run the plugin on another display than Lightroom, use the `Second Screen display` setting to select the display.
       1. While the `Screen Scaling` setting can be used to normalize the plugin window size, the `Size of plugin window` slider can be used to define its dimensions. There are eleven sizes to choose from, ranging from `4XL` (90%) down to `XS` (40%). The percentage determines the size of the displayed photo relative to the dimensions of the selected display in Lightroom. [↗](Focus-Points.md#size-of-plugin-window)<br><br>
   1. `Controls for flagging, rating and coloring a photo` [↗](Focus-Points.md#enable-controls-for-tagging)<br>
      1. These controls were originally introduced because Lightroom could not be accessed while Focus Point Viewer was open. This is normally not required in second screen mode. You can set it to `Off`, which will make the control bar look less cluttered.
      1. If you also want to use these controls in Second Screen mode, select your keyboard layout. [↗](Focus-Points.md#keyboard-layout)<br><br> 
   1. `Preview Image` performance settings [↗](Focus-Points.md#how-to-reduce-long-wait-times-when-opening-the-plugin-window-on-windows)<br>
      In `Preview Image` display mode, the time required to display a photo largely depends on whether a preview of the selected photo is available in Lightroom. If a preview is available, it can be obtained almost instantly. Otherwise, it can take several seconds for the image to become available. <br>
   You can control how long to wait for a preview. If Lightroom cannot provide one within the given time frame, `Export Image` is used instead. If you are not satisfied with the results produced by the default setting of 0.5 seconds, the user manual provides detailed information on how to determine the best value for your setup. [↗](Focus-Points.md#how-to-reduce-long-wait-times-when-opening-the-plugin-window-on-windows)<br>
1. **That's it! You're ready to use Focus Point Viewer.**<br> 
   You can start it either by pressing the hotkey `NumPad *` (if configured in step 3) or by selecting `File → Plug-in Extras → Show Focus Point`.

<br>

## Setup on macOS

The macOS version currently requires less configuration because some V4 features are still under development or limited by the Lightroom SDK.

1. Download and install the plugin [↗](Focus-Points.md#21-installation)<br>
1. Optional: Assign a shortcut to run the plugin [↗](Focus-Points.md#macos)<br>
1. Configure plugin settings:<br>
   Select `Focus Point Viewer` from the list of installed plugins (_Library → File → Plug-in Manager_) and check the `User Interface` section:<br><br><img src="images/Quick%20Setup%20V4%20MAC.jpg" alt="Second Screen 1" style="width: 600px;"/><br>
     _The highlighted settings are the only ones that normally require attention. All other settings can safely remain at their defaults._<br><br>

   1. `Second Screen` mode and behavior: [↗](V4-New-Features.md#13-configuration)<br>
       1. Set `Second Screen` to `On` to continue working in Lightroom while Focus Point Viewer remains open.<br>
       Set it to `Off` to use the plugin in its legacy mode, as in previous versions, where Lightroom could not be used while the plugin was open.<br>
       1. Currently, `Interactive` is the recommended mode for macOS. Current Lightroom SDK limitations affect the usability of `Follow` mode because each time the plugin window is refreshed (closed and reopened), it becomes the active window and takes focus away from Lightroom, interrupting ongoing operations. [↗](V4-New-Features.md#2-focus-point-viewer-always-becomes-the-active-window-when-opened)
        If the `Follow` workflow is important to you, please vote for the linked Adobe bug report. Community votes help increase its visibility.<br>
       1. Select the aspect ratio used in Second Screen mode.<br><br>   
   1. Set your preferred plugin window size.<br>
       1. If you have a multiple-display setup and you want to run the plugin on another display than Lightroom, use the `Second Screen display` setting to select the display.<br>
       1. Use the `Size of plugin window` slider to define the dimensions of the plugin window. There are eleven sizes to choose from, ranging from `4XL` (90%) down to `XS` (40%). The percentage determines the size of the displayed photo relative to the dimensions of the selected display in Lightroom. [↗](Focus-Points.md#size-of-plugin-window)<br><br>

   1. `Controls for flagging, rating and coloring a photo` [↗](Focus-Points.md#enable-controls-for-tagging)<br>
      1. These controls were originally introduced because Lightroom could not be accessed while Focus Point Viewer was open. This is normally not required in second screen mode. You can set it to `Off`, which will make the control bar look less cluttered.<br>
      1. If you also want to use these controls in Second Screen mode, select your keyboard layout. [↗](Focus-Points.md#keyboard-layout)<br><br>
      
   **Note:** V4 PRE 5 only supports `Direct View` on macOS. With the addition of `Preview Image` and `Export Image` in an upcoming pre-release, the `Display mode` settings and the `Preview Image` performance control settings will also become available on macOS.<br>

1. **That's it! You're ready to use Focus Point Viewer.**<br>
   You can start it either by pressing the hotkey you configured in step 2 or by selecting `File → Plug-in Extras → Show Focus Point`.
