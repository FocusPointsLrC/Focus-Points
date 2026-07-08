## V4 – What's New?

Version 4 is the largest update since the project was revived. It introduces the new Second Screen mode, adds multiple display modes, brings the high-performance Direct View renderer to Windows and the Preview and Export Image renderers to macOS for improved markings. 

These changes make the plugin considerably faster and much more convenient to use while working in Lightroom.

### Content
- #### [Second Screen Mode](#1-second-screen-mode)
- #### [Display Modes](#2-display-modes)
- #### [Direct View on Windows](#3-direct-view-on-windows)
- #### [Preview Image and Export Image on macOS](#4-preview-image-and-export-image-on-macos)
- #### [Limitations](#5-limitations)
<br>

### General Remark

The current implementation has certain functional limitations due to restrictions in the behavior of the underlying Lightroom SDK functions. Any limitations are indicated by footnotes in the feature descriptions. 

**See section [Limitations](#5-limitations) for a summary explaining the problem, its effect, how to proceed and how you can help!**

<br>

### 1. Second Screen Mode

Second Screen mode lets you continue working in Lightroom while the Focus Points window remains open. Selecting another photo automatically updates the displayed focus points without reopening the plugin.

Previous versions opened the plugin as a modal dialog attached to Lightroom. While the plugin was open, Lightroom could not be used. Second Screen mode removes this limitation by opening Focus Points in an independent window detached from Lightroom that automatically follows the current Lightroom selection.

The detached window supports two different workflows (behaviours):
- Follow Lightroom
- Interactive



#### Follow Lightroom

This feature is particularly useful in a **multi-screen setup**.

For example, Lightroom could be used on one screen while Focus Points is displayed on another <sup>1</sup>. The displayed focus points would automatically update as you change the Lightroom selection.  
In this mode, Lightroom remains the active window unless you activate Focus Points Viewer by clicking it <sup>2</sup>.

<img src="images/SecondScreen%201.jpg" alt="Second Screen 1" style="width: 1000px;"/><br>

#### Interactive

Second Screen mode can also be useful for a **single-monitor setup**.

When checking the focus points for multiple photos, you are not restricted to using the Previous and Next keys to select the photos. Instead, you can scroll through your Lightroom filmstrip or grid and select the photos you want. You can also alter the plugin settings without having to close and restart the plugin explicitly.  
In this mode, Focus Points Viewer remains the active window unless you click anywhere else <sup>2, 3, 4</sup>.


<img src="images/SecondScreen%202.jpg" alt="Second Screen 2" style="width: 1000px;"/><br>

#### Configuration ####

You can enable Second Screen mode from the Plugin Manager. You can also customize the behavior (Interactive or Follow) and the fixed aspect ratio reserved for photo display:

<img src="images/SecondScreen Options.jpg" alt="Second Screen Options" style="width: 600px;"/>

In Second Screen mode, the window keeps a fixed layout so it does not resize when switching between landscape and portrait photos on a secondary screen. Images are centered within the reserved display area while the information panel stays aligned on the right.

Note: The Second Screen window remembers its last position and size. When changing the display size (S / M / L / XL / XXL), the dialog content may temporarily occupy less space than the current window size. This can result in additional empty margins on the right or bottom of the window. These can be removed by simply resizing the window manually once. The adjusted size will again be remembered automatically.

When the Second Screen option is disabled (the default setting), the plugin continues to operate in Single Screen mode as before.


### 2. Display Modes

*How images are displayed*

In short, the display mode determines how the photo is displayed and how focus point overlays are added.

The following display modes are supported in V4:

**Direct View**. Displays the photo directly through Lightroom's internal Develop rendering engine, overlaying it with icons that visualize the corners of the marking rectangles. Direct View automatically reflects Lightroom edits in real time. It acts as a mirror to what Lightroom displays in the Develop module.

**Preview Image**. Retrieves a preview image from Lightroom's preview cache, writes it to a temporary JPEG file, and enhances the image with markings. This mode depends on Lightroom's preview cache and may therefore be affected by the availability of previews or the timing of their refresh.

**Export Image**.  Uses Lightroom's Export feature to save an image as a JPEG file to the hard drive. It's not the fastest, but it's rock-solid and reliable.


The following table summarizes the characteristics of the available display modes:

| Mode                        | Platform | Advantages | Limitations |
|-----------------------------|----------|------------|-------------|
| **Direct&nbsp;View*** | macOS, Windows<sup>5</sup> |  Fastest startup, live updates while editing | In Library, the image may appear after a short rendering delay while Lightroom renders it |
| **Preview&nbsp;Image****    | Windows, macOS<sup>6</sup> |  Usually fast when a Lightroom preview already exists | Performance depends on Lightroom's preview cache |
| **Export&nbsp;Image****     | Windows, macOS<sup>6</sup> | Always produces a reliable image | Typically slower when a Lightroom preview already exists, but often faster when Lightroom first needs to build a preview. |

&nbsp;*&nbsp; Uses corner markers for focus points.<br> 
&nbsp;** Uses full rectangle overlays.<br> 

**Tip:** Each display mode has its own strengths. Direct View provides the fastest, most responsive display while editing. Preview Image and Export Image provide full rectangle overlays. The long-term goal is to make all three modes available on both macOS and Windows, allowing you to switch between them at any time and use the mode that best suits your current task.<br>

#### Changing the active display mode on the fly

Although Direct View offers the fastest start-up times, the use of corner markers to indicate focus points, detected faces and subjects can be confusing, particularly if there are multiple marked areas in the photo. Preview Image and Export Image use full rectangle overlays which can improved visual clarity.

To enable you to easily get out the best of both worlds you can select the display mode right from the user interface. Either by clicking with the mouse, or by using a keyboard shortcut. 
Press:
- D for Direct View
- V for PreView Image
- E for Export Image

After selecting a different display mode, the window will automatically refresh (close and reopen).

<img src="images/Display%20Modes.jpg" alt="Direct View on Windows" style="width: 1000px;"/><br>

#### How display modes affect the Focus Point Viewer performance

The following chart compares the typical startup time of each display mode on different camera models:

<img src="images/Time%20to%20Open%20Plugin%20Window.jpg" alt="User Interface" style="width: 1000px;"/>


### 3. Direct View on Windows

V4 introduces Direct View to Windows users <sup>5</sup>. Direct View has been available on macOS since earlier versions. Unlike the Preview Image and Export Image modes, Direct View displays Lightroom's own rendered image directly, without creating a temporary JPEG on disk. This has two major advantages:

- significantly faster window opening
- immediate updates while editing the photo

These characteristics make Direct View particularly useful when using the plugin in Second Screen mode.


### 4. Preview Image and Export Image on macOS

This is not included in PRE 1, but is planned for inclusion in a future pre-release version.


## 5. Known Limitations

The following limitations (except 6) are caused by current Lightroom Classic SDK behavior and affect Focus Point Viewer. They are outside the plugin's control and will be removed from this list as Adobe addresses the underlying SDK issues.

In the following, Focus Point Viewer is abbreviated as 'FPV'.


### <sup>1</sup> FPV does not remember its position on a secondary monitor on macOS

**Effect:** On macOS, the FPV remembers the correct position on the screen when reopening, but not the correct screen. When you drag the plugin window to a secondary screen and select another image it will reopen on the primary screen.

**Cause:** Inconsistent behavior of the underlying SDK function to open a floating dialog on Windows vs macOS.

**How to solve:** A bug report has been filed with Adobe.  
[https://community.adobe.com/bug-reports-674/p-mac-sdk-floating-dialog-does-not-reopen-on-second-screen-1628255](https://community.adobe.com/bug-reports-674/p-mac-sdk-floating-dialog-does-not-reopen-on-second-screen-1628255)

If this feature is important to you, **please consider voting** for the Adobe bug report below. Community votes help increase its visibility.


### **<sup>2</sup> FPV always becomes the active window when opened on macOS**  

### **<sup>3</sup> Keyboard shortcuts do not work immediately after opening Focus Point Viewer in Interactive mode on Windows.** 

### **<sup>4</sup> FPV windows is always on top in Second Screen mode**   OS dependency ??? 

### **<sup>5</sup> Direct View corner icons do not seamlessly blend with the photo when used on Windows**

### **<sup>6</sup> Preview Image and Export Image are not yet available on macOS**

