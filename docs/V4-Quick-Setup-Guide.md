## ⚠️ Important update for users of V3.4 and V4 PRE 1<br><br>[CRITICAL: Update check fails to detect available updates in V3.4 and V4 PRE 1](https://github.com/FocusPointsLrC/Focus-Points/issues/405)


# Quick Setup Guide

### [Getting started with V3.x](#v3x-quick-setup-guide)

### [Getting started with V4](#v4-quick-setup-guide)

---

<br>

# V3.x Quick Setup Guide

Focus Point Viewer works well with its default settings. This guide only covers the few options you may want to adjust before using the plugin.

<br>

## Setup on Windows

1. Download and install the plugin [↗](Focus-Points.md#21-installation)<br><br>
1. Optional: Load the AutoHotkey script to use a keyboard shortcut to run the plugin [↗](Focus-Points.md#windows)<br><br>
1. Configure plugin settings:<br>
   Select `Focus Point Viewer` from the list of installed plugins (_Library → File → Plug-in Manager_) and check the `User Interface` section:<br><br><img src="images/Quick%20Setup%20V3x%20WIN.jpg" alt="Second Screen 1" style="width: 600px;"/><br>
    _The highlighted settings are the only ones that normally require attention. All other settings can safely remain at their defaults._<br><br>
 
   1. Set your preferred plugin window size. 
      1. If you are using the Windows Display Settings to scale your display, you can use the `Screen Scaling` setting to apply the same or a similar setting for the plugin window [↗](Focus-Points.md#screen-scaling).
      2. While the `Screen Scaling` setting can be used to normalize the plugin window size, the `Size of plugin window` setting can be used to define its dimensions. There are six sizes to choose from, ranging from 3XL to S. These correspond to 90% (3XL) to 40% (S) of the screen area used by Lightroom [↗](Focus-Points.md#size-of-plugin-window).<br><br>
   1. `Controls for flagging, rating and coloring a photo` [↗](Focus-Points.md#enable-controls-for-tagging)<br>
      1. If you want to use Focus Points Viewer in your image culling process, you can use these controls to tag images. If you don't, you can set it to `Off`, which will make the control bar look less cluttered.
      2. If you also want to use them, select your keyboard layout. This is required because the Shift-0..9 key combinations usually produce codes that depend on the keyboard layout.  [↗](Focus-Points.md#keyboard-layout)<br><br> 
   1. `Preview Image` performance settings [↗](Focus-Points.md#how-to-reduce-long-wait-times-when-opening-the-plugin-window-on-windows)<br>
      On Windows, the time to open Focus Points Viewer largely depends on whether a preview of the selected photo is available in Lightroom. If a preview is available, it can be obtained instantly. Otherwise, it can take several seconds for the plugin window to appear. <br>
   You can control how long to wait for a preview. If Lightroom cannot provide one within the given time frame, `Export Image` is used instead. If you are not satisfied with the results produced by the default setting of 0.5 seconds, the user manual provides detailed information on how to determine the best value for your setup. [↗](Focus-Points.md#how-to-reduce-long-wait-times-when-opening-the-plugin-window-on-windows)<br><br>

2. **That's it! You're ready to use Focus Point Viewer.**<br> 
   You can start it either by pressing the hotkey `NumPad *` (if configured in step 2) or by selecting `File → Plug-in Extras → Show Focus Point`.

<br>

## Setup on macOS

The macOS version has fewer settings than the Windows version. The plugin does not depend on an OS display scaling factor. It uses the `Direct View` display mode, there is no need to handle `Preview Images` [↗](V4-New-Features.md#2-display-modes).

1. Download and install the plugin [↗](Focus-Points.md#21-installation)
2. Optional: Assign a shortcut to run the plugin [↗](Focus-Points.md#macos)
3. Configure plugin settings:<br>
   Select `Focus Point Viewer` from the list of installed plugins (_Library → File → Plug-in Manager_) and check the `User Interface` section:<br><br><img src="images/Quick%20Setup%20V3x%20MAC.jpg" alt="Second Screen 1" style="width: 600px;"/><br>
    _The highlighted settings are the only ones that normally require attention. All other settings can safely remain at their defaults._<br><br>

   1. `Controls for flagging, rating and coloring a photo` [↗](Focus-Points.md#enable-controls-for-tagging)<br>
      1. If you want to use Focus Points Viewer in your image culling process, you can use these controls to tag images. If you don't, you can set it to `Off`, which will make the control bar look less cluttered.
      2. If you also want to use them, select your keyboard layout. This is required because the Shift-0..9 key combinations usually produce codes that depend on the keyboard layout.  [↗](Focus-Points.md#keyboard-layout)<br><br>  

4. **That's it! You're ready to use Focus Point Viewer.**<br> 
   You can start it either by pressing the hotkey you configured in step 2 or by selecting `File → Plug-in Extras → Show Focus Point`.

<br>

# V4 Quick Setup Guide

This guide helps you configure the main new features introduced in V4, particularly Second Screen mode and the available display modes.

Some steps are specific to the operating system (OS) you are running.   
To keep things simple, there are separate sections for **[Windows](#setup-on-windows)** and **[macOS](#setup-on-macos)**.

## Setup on Windows

1. Download and install the plugin [↗](Focus-Points.md#21-installation)
2. Load the AutoHotkey companion script [↗](V4-New-Features.md#6-autohotkey-companion-script-for-windows)<br>
   This script works around current Lightroom SDK limitations to provide a smoother experience in `Follow` and `Interactive` mode.
3. Optional: Load the AutoHotkey script to use a keyboard shortcut to run the plugin [↗](Focus-Points.md#windows)
4. Configure plugin settings:<br>
   Select `Focus Point Viewer` from the list of installed plugins (_Library → File → Plug-in Manager_) and check the `User Interface` section:<br><br><img src="images/Quick%20Setup%20V4%20WIN.jpg" alt="Second Screen 1" style="width: 600px;"/><br>
    _The highlighted settings are the only ones that normally require attention. All other settings can safely remain at their defaults._<br><br>
 
    1. `Second Screen` mode and behavior [↗](V4-New-Features.md#13-configuration):<br>
       1. Set `Second Screen` to `On` to continue working in Lightroom while Focus Points Viewer remains open.
       2. Choose whether you want Focus Point Viewer to `Follow` while you're working in Lightroom or if you want to use it interactively.
       3. Select the aspect ratio used in Second Screen mode.<br><br>     
   1. `Display mode` [↗](V4-New-Features.md#2-display-modes)<br>
      1. In Interactive mode, Preview Image is generally the recommended display mode. The use of `Direct View` is currently impaired by a Lightroom SDK limitation [↗](V4-New-Features.md#5-direct-view-corner-icons-do-not-seamlessly-blend-with-the-photo-when-used-on-windows).
      2. In `Follow` mode, you may consider `Direct View`, particularly if you are not interested in viewing every photo but only specific ones. `Direct View` is fast and runs entirely in-memory. `Preview Image` involves disk operations that may slightly impair the user experience in Lightroom.  
      When you want to inspect a particular photo, you can temporarily switch the display mode to update the image. [↗](V4-New-Features.md#21-changing-the-active-display-mode-on-the-fly)<br><br> 
   1. Set your preferred plugin window size. 
       1. If you are using the Windows Display Settings to scale your display, you can use the `Screen Scaling` setting to apply the same or a similar setting for the plugin window [↗](Focus-Points.md#screen-scaling).
       2. While the `Screen Scaling` setting can be used to normalize the plugin window size, the `Size of plugin window` setting can be used to define its dimensions. There are six sizes to choose from, ranging from 3XL to S. These correspond to 90% (3XL) to 40% (S) of the screen area used by Lightroom [↗](Focus-Points.md#size-of-plugin-window).<br><br>
   1. `Controls for flagging, rating and coloring a photo` [↗](Focus-Points.md#enable-controls-for-tagging)<br>
      1. These controls were originally introduced because Lightroom could not be accessed while Focus Points Viewer was open. This is normally not required in second screen mode. You can set it to `Off`, which will make the control bar look less cluttered.
      2. If you also want to use these controls in Second Screen mode, select your keyboard layout. [↗](Focus-Points.md#keyboard-layout)<br><br> 
   1. `Preview Image` performance settings [↗](Focus-Points.md#how-to-reduce-long-wait-times-when-opening-the-plugin-window-on-windows)<br>
      In `Preview Image` display mode, the time to open Focus Points Viewer largely depends on whether a preview of the selected photo is available in Lightroom. If a preview is available, it can be obtained instantly. Otherwise, it can take several seconds for the plugin window to appear. <br>
   You can control how long to wait for a preview. If Lightroom cannot provide one within the given time frame, `Export Image` is used instead. If you are not satisfied with the results produced by the default setting of 0.5 seconds, the user manual provides detailed information on how to determine the best value for your setup. [↗](Focus-Points.md#how-to-reduce-long-wait-times-when-opening-the-plugin-window-on-windows)<br><br>
2. **That's it! You're ready to use Focus Point Viewer.**<br> 
   You can start it either by pressing the hotkey `NumPad *` (if configured in step 3) or by selecting `File → Plug-in Extras → Show Focus Point`.

<br>

## Setup on macOS

The macOS version currently requires less configuration because some V4 features are still under development or limited by the Lightroom SDK.

1. Download and install the plugin [↗](Focus-Points.md#21-installation)
2. Optional: Assign a shortcut to run the plugin [↗](Focus-Points.md#macos)
3. Configure plugin settings:<br>
   Select `Focus Point Viewer` from the list of installed plugins (_Library → File → Plug-in Manager_) and check the `User Interface` section:<br><br><img src="images/Quick%20Setup%20V4%20MAC.jpg" alt="Second Screen 1" style="width: 600px;"/><br>
     _The highlighted settings are the only ones that normally require attention. All other settings can safely remain at their defaults._<br><br>

   1. `Second Screen` mode and behavior [↗](V4-New-Features.md#13-configuration):<br>
      1. Set `Second Screen` to `On` to continue working in Lightroom while Focus Points Viewer remains open.
      1. Currently, `Interactive` is the recommended mode for macOS. Current Lightroom SDK limitations significantly limit the usability of `Follow` mode because the plugin window<br>
         - will not keep its position on a secondary display but switch back to the primary screen [↗](V4-New-Features.md#1-focus-point-viewer-does-not-remember-its-position-on-a-secondary-monitor-on-macos) 
         - will become the active window when opened, thus interrupting user operations in Lightroom [↗](V4-New-Features.md#2-focus-point-viewer-always-becomes-the-active-window-when-opened)
   
         If the `Follow` workflow is important to you, **please vote** for the linked Adobe bug reports. Community votes help increase its visibility.
   
      3. Select the aspect ratio used in Second Screen mode.<br><br>     
   1. `Controls for flagging, rating and coloring a photo` [↗](Focus-Points.md#enable-controls-for-flagging)<br>
      1. These controls were originally introduced because Lightroom could not be accessed while Focus Points Viewer was open. This is normally not required in second screen mode. You can set it to `Off`, which will make the control bar look less cluttered.
      2. If you also want to use these controls in Second Screen mode, select your keyboard layout. [↗](Focus-Points.md#keyboard-layout)<br><br>
      
   **Note:** V4 PRE 1 only supports `Direct View` on macOS. With the addition of `Preview Image` and `Export Image` in an upcoming pre-release, the `Display mode` settings  and the `Preview Image` performance control settings will also become available on macOS.<br><br>

4. **That's it! You're ready to use Focus Point Viewer.**<br>
   You can start it either by pressing the hotkey you configured in step 2 or by selecting `File → Plug-in Extras → Show Focus Point`.
