# V4 PRE 1 updated July xx, 2026

**[Download plugin](https://github.com/FocusPointsLrC/Focus-Points/releases/download/v3.5_pre1/Focus-Points-3.5_pre1.zip)** and see detailed **[installation instructions]( https://FocusPointsLrC.github.io/Focus-Points/docs/Focus-Points.html#21-installation)**.

## Feature Pre-Release

### New features and changes:

* **User Interface**
  * Second Screen mode: Enable the plugin to run alongside Lightroom operations
 [#379](https://github.com/FocusPointsLrC/Focus-Points/issues/379)
  * Support multiple display modes on both Windows and macOS [#388](https://github.com/FocusPointsLrC/Focus-Points/issues/388)

  For a detailed description of the new features, see **[Focus Points V4: What's New](https://FocusPointsLrC.github.io/Focus-Points/docs/V4%20New%20Features.html)**.<br>

### Current Limitations
  * **Second Screen does not work on macOS secondary display with LrC 15.4 or earlier**.  
  When an image is switched, the plugin does not retain its position on the secondary display, instead swapping back to the main display on which LrC is running. A bug report has been filed with Adobe. <br>
If this feature is important to you, **please consider voting** for the Adobe bug report below. Community votes help increase its visibility.<br>
  https://community.adobe.com/bug-reports-674/p-mac-sdk-floating-dialog-does-not-reopen-on-second-screen-1628255
  <br><br>
  * **Direct View display mode has known display issues on Windows with LrC 15.4 or earlier**.  
    'Direct View' has been the default display mode on macOS. It is fast because it doesn't require JPG images to be written to disk and enhanced by drawing visualization rectangles onto them. Direct View also features live updates of the current photo. Any edits to the photo are immediately reflected in the plugin's display, which is useful in Second Screen mode.<br><br> 
    On Windows, the corner icons that visualize focus points, face or subject detection by overlaying the photo do not reveal the underlying image. Instead, transparent pixels are rendered using the background color of the Lightroom dialog box, resulting in visible rectangular artefacts around the overlay image.  A bug report has been filed with Adobe.<br>
If this feature is important to you, **please consider voting** for the Adobe bug report below. Community votes help increase its visibility.<br>
  https://community.adobe.com/bug-reports-674/p-windows-sdk-transparent-png-overlays-do-not-composite-correctly-in-overlapping-layouts-1628087
<br><br>
* **Preview Image and Exported Image display modes are not yet available on macOS**.  
These features require the integration of ImageMagick/Mogrify for macOS. This is planned for one of the upcoming pre-releases. Once these display modes are available on macOS, users will benefit from clearer focus point markings and face and subject detection rectangles instead of corners by choosing one of these two modes instead of 'Direct View'. 

General user information (not yet updated to reflect the contents of this pre-release):

See [README](https://FocusPointsLrC.github.io/Focus-Points) for an overview of the plugin functionality.<br> 
See [User Manual](https://focuspointslrc.github.io/Focus-Points/docs/Focus-Points.html) for more detailed information.
