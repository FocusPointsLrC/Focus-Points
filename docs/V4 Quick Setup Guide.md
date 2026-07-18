# V4 – Quick Setup Guide

This document describes the basic steps for setting up the plugin in Second Screen mode.



Some steps are specific to the operating system (OS) you are running. To keep things simple, there are separate sections for Windows and macOS.


## Setup on Windows

1. Download and install the plugin [↗](Focus-Points.md#21-installation)
2. Load the AutoHotkey companion script [↗](V4%20New%20Features.md#6-autohotkey-companion-script-for-windows)<br>
   This script provides a solution to the Lightroom SDK limitations that cause issues with the user experience in Follow and Interactive modes.
3. Optional: Load the AutoHotkey script to use a keyboard shortcut to run the plugin [↗](Focus-Points.md#how-to-use-a-keyboard-shortcut-to-run-the-plugin)
4. Configure plugin settings:<br>
   Select `Focus Point Viewer` from the list of installed plugins (_Library → File → Plug-in Manager_) and check the `User Interface` section:<br><br><img src="images/Quick%20Setup%201.jpg" alt="Second Screen 1" style="width: 600px;"/><br>
 
   1. Configure `Second Screen` mode and behavior [↗](V4%20New%20Features.md#13-configuration):<br>
      1. Select `On` to continue working in Lightroom while the Focus Points window remains open.
      2. Choose whether you want Focus Point Viewer to `Follow` while you're working in Lightroom or if you want to use it interactively.
      3. Select the aspect ratio which is fixed in Second Screen mode<br><br>     
   1. Configure `Controls for flagging, rating and coloring a photo` [↗](Focus-Points.md#enable-controls-for-flagging)<br>
      1. These controls have been introduced to enable flagging, rating and coloring when Focus Points Viewer did not allow access to Lightroom while it was open. This is normally not required in second screen mode. You can set it to 'Off', which will make the control bar look less cluttered.
      2. If you want to keep and work with it also in Second Screen mode, select your keyboard layout  [↗](Focus-Points.md#keyboard-layout)<br><br> 
   1. Configure `Display mode` [↗](V4%20New%20Features.md#2-display-modes)<br>
      1. In `Interactive` mode, `Preview Image` is a strong recommendation. The use of `Direct View` is currently impaired by a Lightroom SDK limitation [↗](V4%20New%20Features.md#sup5sup-direct-view-corner-icons-do-not-seamlessly-blend-with-the-photo-when-used-on-windows).
      2. In `Follow` mode, you may wish to consider `Direct View`, particularly if you are not interested in viewing every photo but only specific ones. `Direct View` is fast and runs entirely in-memory. `Preview Image` involves disk operations that may slightly impair the user experience in Lightroom.   
      When viewing a photo of interest, the imperfect display of `Direct View` can be updated by changing the active display mode on the fly. [↗](V4%20New%20Features.md#21-changing-the-active-display-mode-on-the-fly)<br><br> 
   1. Optional: Configure `Preview Image` performance settings [↗](Focus-Points.md#how-to-reduce-long-wait-times-when-opening-the-plugin-window-on-windows)<br>
      In `Preview Image` display mode, the time to open Focus Points Viewer largely depends on whether a preview of the selected photo is available in Lightroom. If a preview is available, it can be obtained instantly. Otherwise, it can take several seconds for the plugin window to appear. <br>
   Versions 3.4 and 4 introduce a feature that allows control how long to wait for a preview. If Lightroom cannot provide one within the given time frame, `Export Image` is used instead. If you are not satisfied with the results produced by the default setting of 0.5 seconds, the user manual provides detailed information on how to determine the best value for your setup. [↗](Focus-Points.md#how-to-reduce-long-wait-times-when-opening-the-plugin-window-on-windows)
