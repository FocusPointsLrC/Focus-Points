# V4 PRE 1 updated July xx, 2026

**[Download plugin](https://github.com/FocusPointsLrC/Focus-Points/releases/download/v3.5_pre1/Focus-Points-3.5_pre1.zip)** and see detailed **[installation instructions]( https://FocusPointsLrC.github.io/Focus-Points/docs/Focus-Points.html#21-installation)**.

See also [How to make V3.4 and V4 PRE coexist in Lightroom](#how-to-make-v34-and-v4-pre-coexist-in-lightroom) near the end of this release note.

## Feature Pre-Release

Version 4 is the largest update since the project was revived. Second Screen changes the way you use the plugin by keeping it available while you continue editing in Lightroom. It also adds multiple display modes and brings the high-performance Direct View renderer to Windows, making the plugin significantly faster and more responsive.

Unlike previous releases, Version 4 is planned to undergo a longer pre-release phase. The new workflow affects nearly every aspect of using the plugin, so I'd really appreciate long-term feedback from real-world use to help refine the experience.

Two remaining Lightroom SDK issues are outside the plugin's control and currently require Adobe's attention. If these features matter to you, your vote on the corresponding bug reports really helps increase their visibility.

### Is Version 4 for you?

If you frequently inspect focus points while editing images, especially on a second monitor, Version 4 offers a much smoother workflow and is exactly the type of feedback I'm looking for.


### New features and changes:

* **User Interface**
  * Second Screen mode: A new workflow that keeps the plugin available while editing.
 [#379](https://github.com/FocusPointsLrC/Focus-Points/issues/379)
  * Multiple display modes on both Windows and macOS [#388](https://github.com/FocusPointsLrC/Focus-Points/issues/388)

  For a detailed description of the new features, see **[Focus Points V4: What's New](https://FocusPointsLrC.github.io/Focus-Points/docs/V4%20New%20Features.html)**.<br>

### Current Limitations
  * **Second Screen does not work on macOS secondary display with LrC 15.4 or earlier**.  
  When an image is switched, the plugin does not retain its position on the secondary display, instead swapping back to the main display on which LrC is running. A bug report has been filed with Adobe. <br>
  https://community.adobe.com/bug-reports-674/p-mac-sdk-floating-dialog-does-not-reopen-on-second-screen-1628255<br>
If this feature is important to you, **please consider voting**. Community votes help increase its visibility.
  <br><br>
  * **Direct View display mode has known display issues on Windows with LrC 15.4 or earlier**.  
    'Direct View' has been the default display mode on macOS. It is fast because it doesn't require JPG images to be written to disk and enhanced by drawing visualization rectangles onto them. Direct View also features live updates of the current photo. Any edits to the photo are immediately reflected in the plugin's display, which is useful in Second Screen mode.<br><br> 
    On Windows, the corner icons that visualize focus points, face or subject detection by overlaying the photo do not reveal the underlying image. Instead, transparent pixels are rendered using the background color of the Lightroom dialog box, resulting in visible rectangular artefacts around the overlay image.  A bug report has been filed with Adobe.<br>
  https://community.adobe.com/bug-reports-674/p-windows-sdk-transparent-png-overlays-do-not-composite-correctly-in-overlapping-layouts-1628087<br>
  If this feature is important to you, **please consider voting**. Community votes help increase its visibility.<br><br>

* **Preview Image and Exported Image display modes are not yet available on macOS**.  
These features require the integration of ImageMagick/Mogrify for macOS. This is planned for one of the upcoming pre-releases. When these two display modes are available on macOS, users will benefit from clearer focus point markings and face and subject detection rectangles instead of just corners. It will be possible to switch between display modes directly in the UI; there will be no need to go to plugin settings. 

### How to make V3.4 and V4 PRE coexist in Lightroom

You don't need to replace your existing installation. Version 3.4 and Version 4 PRE can coexist in Lightroom, making it easy to switch between them whenever you like.
 
The 'trick' is to install both versions of the plugin in separate folders, for instance:
- V3.4 in 'focuspoints.lrplugin'
- V4 PRE in 'focuspoints.v4.lrplugin'

You add both plugins to Lightroom's Plugin Manager from the two different folders. Since both plugins use the same Lightroom plugin identifier, Lightroom allows only one of them to be enabled at a time.

Inspect the 'Version' information and enable the version with which you want to work. If the other version has been enabled, it will be disabled automatically. To switch back, follow the same procedure.

This method allows you to have as many versions of the plugin as you want available in Lightroom.

<img src="docs/images/Plugin Coexistence.jpg" alt="Screenshot" style="width: 700px;"/>

<br>

Please join the discussion by clicking the button below and sharing your questions, comments and feedback on this pre-release.
