## V4 – What's New?

Version 4 is the largest update since the project was revived. It introduces the new Second Screen mode, adds multiple display modes, and brings the high-performance Direct View renderer to Windows. These changes make the plugin considerably faster and much more convenient to use while working in Lightroom.

### Content
- #### [Second Screen Mode](#1-second-screen-mode)
- #### [Display Modes](#2-display-modes)
- #### [Direct View on Windows](#3-direct-view)


### 1. Second Screen Mode

Second Screen mode lets you continue working in Lightroom while the Focus Points window remains open. Selecting another photo automatically updates the displayed focus points without reopening the plugin.

Previous versions opened the plugin as a modal dialog attached to Lightroom. While the plugin was open, Lightroom could not be used. Second Screen mode removes this limitation by opening Focus Points in an independent window that automatically follows the current Lightroom selection.

This feature is particularly useful in a multi-screen setup. For example, Lightroom could be used on one screen while Focus Points is displayed on another. The displayed focus points would automatically update as you change the Lightroom selection. 

<img src="images/SecondScreen%201.jpg" alt="Second Screen 1" style="width: 1000px;"/>

Second Screen mode is also useful for single-monitor setups. When checking the focus points for multiple photos, you are not restricted to using the Previous and Next keys. Instead, you can scroll through your Lightroom filmstrip or grid and select the photos you want. You can also alter the plugin settings without having to close and restart the plugin explicitly: 

<img src="images/SecondScreen%202.jpg" alt="Second Screen 2" style="width: 1000px;"/>

Although the plugin largely retains its look and feel in Second Screen mode, there are a few important differences worth noting:

- Interaction between the plugin and Lightroom can impact use of keyboard shortcuts  
In Second Screen mode, the plugin runs in an independent window. Whenever the displayed photo changes, Windows gives keyboard focus to the plugin window. To continue using Lightroom keyboard shortcuts, simply click once inside Lightroom.

- The plugin window has a fixed width  
The window keeps a fixed layout so it does not resize when switching between landscape and portrait photos on a secondary screen. Images are centered within the reserved display area while the information panel stays aligned on the right.

- Display mode  
When using the plugin in Preview Image mode, it will immediately use Export Image in the Develop module. This is necessary because Lightroom's preview generation is not sufficiently reliable in the Develop module for the plugin's requirements. 

**Configuration**

Second Screen mode can be enabled from the Plugin Manager. You can also choose the initial window size and the fixed aspect ratio reserved for the photo display.

<img src="images/SecondScreen Options.jpg" alt="Second Screen Options" style="width: 600px;"/>

Note: The Second Screen window remembers its last position and size. When changing the display size (S / M / L / XL / XXL), the dialog content may temporarily occupy less space than the current window size. This can result in additional empty margins on the right or bottom of the window. These can be removed by simply resizing the window manually once. The adjusted size will again be remembered automatically.

When the Second Screen option is disabled (the default setting), the plugin continues to operate in Single Screen mode as before.

**Limitation on macOS**

Second Screen mode can be chosen regardless of the operating system. On macOS however, the plugin currently remembers the correct position on the screen when reopening, but not the correct screen. When you drag the plugin window to a secondary screen and select another image it will reopen on the primary screen.  A bug report has been filed with Adobe.

If this feature is important to you, **please consider voting** for the Adobe bug report below. Community votes help increase its visibility.
[https://community.adobe.com/bug-reports-674/p-mac-sdk-floating-dialog-does-not-reopen-on-second-screen-1628255](https://community.adobe.com/bug-reports-674/p-mac-sdk-floating-dialog-does-not-reopen-on-second-screen-1628255)


### 2. Display Modes

*How images are displayed*

In short, the display mode determines how the photo is displayed and how focus point overlays are added.

The following display modes are supported in V4:

**Direct View**. Displays the photo directly through Lightroom's internal Develop rendering engine, overlaying it with icons that visualize the corners of the marking rectangles. Direct View automatically reflects Lightroom edits in real time. It acts as a mirror to what Lightroom displays in the Develop module.

**Preview Image**. Retrieves a preview image from Lightroom's preview cache, writes it to a temporary JPEG file, and enhances the image with markings. This mode depends on Lightroom's preview cache and may therefore be affected by the availability of previews or the timing of their refresh.

**Export Image**.  Uses Lightroom's Export feature to save an image as a JPEG file to the hard drive. It's not the fastest, but it's rock-solid and reliable.


The following table summarizes the characteristics of the available display modes:

| Mode | Platform | Advantages | Limitations |
|----------------|----------|------------|-------------|
| **Direct&nbsp;View<sup>1</sup>** | macOS, Windows<sup>3</sup> |  Fastest startup, live updates while editing | In Library, the image may appear after a short rendering delay while Lightroom renders it |
| **Preview&nbsp;Image<sup>2</sup>** | Windows, macOS<sup>4</sup> |  Usually fast when a Lightroom preview already exists | Performance depends on Lightroom's preview cache |
| **Export&nbsp;Image<sup>2</sup>** | Windows, macOS<sup>4</sup> | Always produces a reliable image | Typically slower when a Lightroom preview already exists, but often faster when Lightroom first needs to build a preview. |

<sup>1</sup> Uses corner markers for focus points.<br> 
<sup>2</sup> Uses full rectangle overlays.<br> 
<sup>3</sup> Currently experimental on Windows due to a Lightroom SDK issue affecting transparent overlays. [#393](https://github.com/FocusPointsLrC/Focus-Points/issues/393)<br>
<sup>4</sup> To be implemented on macOS [394](https://github.com/FocusPointsLrC/Focus-Points/issues/394)

**Tip:** Each display mode has its own strengths. Direct View provides the fastest, most responsive display while editing. Preview Image and Export Image provide full rectangle overlays. The long-term goal is to make all three modes available on both macOS and Windows, allowing you to switch between them at any time and use the mode that best suits your current task.


The following chart compares the typical startup time of each display mode on different camera models:

<img src="images/Time%20to%20Open%20Plugin%20Window.jpg" alt="User Interface" style="width: 1000px;"/>


### 3. Direct View on Windows

V4 introduces Direct View to Windows users. Direct View has been available on macOS since earlier versions. Unlike the Preview Image and Export Image modes, Direct View displays Lightroom's own rendered image directly, without creating a temporary JPEG on disk. This has two major advantages:

- significantly faster window opening
- immediate updates while editing the photo

These characteristics make Direct View particularly useful when using the plugin in Second Screen mode.

Direct View is now available on Windows, but there is currently one known limitation.   
Investigation indicates that transparent PNG overlays (the corner icons) are not composited correctly in overlapping SDK views, causing visible rectangular artefacts around overlay graphics. A bug report has been filed with Adobe. 

If this feature is important to you, **please consider voting** for the Adobe bug report below. Community votes help increase its visibility.
[https://community.adobe.com/bug-reports-674/p-windows-sdk-transparent-png-overlays-do-not-composite-correctly-in-overlapping-layouts-1628087](https://community.adobe.com/bug-reports-674/p-windows-sdk-transparent-png-overlays-do-not-composite-correctly-in-overlapping-layouts-1628087)

<img src="images/Direct%20View%20Windows.jpg" alt="Direct View on Windows" style="width: 1000px;"/>
