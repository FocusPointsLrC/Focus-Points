## ⚠️ Important update for users of V3.4 and V4 PRE 1<br><br>[CRITICAL: Update check fails to detect available updates in V3.4 and V4 PRE 1](https://github.com/FocusPointsLrC/Focus-Points/issues/405)


# Frequently Asked Questions (FAQ)

This FAQ explains the most common questions about Focus Point Viewer, the reasons behind certain behaviors, and the available workarounds where applicable.



## Browse by topic

### Camera Support

* [Is my camera supported?](#the-plugin-doesnt-seem-to-work-is-my-camera-not-supported)

### File Types

* [Supported file types](#is-the-plugin-only-compatible-with-raw-images)

### Keyboard Shortcuts

* [Using a keyboard shortcut to open Focus Point Viewer](#how-can-i-set-up-a-hotkey-to-open-focus-points-viewer)
* [Using keyboard shortcuts to operate Focus Point Viewer](#how-can-i-set-up-a-hotkey-to-open-focus-points-viewer)

### Display modes

* [`Direct View`: gray artifacts around corner markers (Windows)](#why-does-direct-view-display-gray-artifacts-around-the-af-corner-markings-on-windows-is-my-gpu-the-cause)

* [`Preview Image` / `Export Image`: why unavailable on macOS?](#why-are-the-preview-image-and-export-image-display-modes-unavailable-on-macos)

### Second Screen mode

* [Window switches back to the primary screen (macOS)](#how-can-i-stop-focus-point-viewer-from-switching-back-to-the-primary-screen-on-macos)

* [Viewer becomes the active window in `Follow Lightroom` mode](#how-can-i-prevent-focus-point-viewer-from-automatically-becoming-the-active-window-whenever-a-new-photo-is-loaded-in-follow-lightroom-mode)

* [Keyboard input after opening in `Interactive` mode (Windows)](#why-doesnt-focus-point-viewer-accept-keyboard-input-immediately-after-opening-in-interactive-mode-on-windows)

* [Window always in front (Windows)](#why-is-focus-point-viewer-always-in-front-on-windows)
  
* [`Export file` when `Preview Image` is selected](#why-does-lightroom-display-an-export-file-progress-bar-even-though-i-have-chosen-preview-image-display-mode)

* [Arrow keys stop working in filmstrip (`Follow Lightroom` mode, Windows)](#why-do-the-left-and-right-arrow-keys-sometimes-stop-working-in-lightroom-when-focus-point-viewer-is-running-in-follow-lightroom-mode)

* [Double-click required in Grid view (macOS)](#why-do-i-have-to-click-twice-to-open-a-photo-in-focus-point-viewer-from-grid-view-while-a-single-click-is-enough-in-filmstrip-view-on-macos)
  
* [Empty margins after resizing](#why-do-empty-margins-appear-on-the-right-or-bottom-of-the-focus-points-viewer-window-when-i-change-its-size-in-second-screen-mode)  
 
### Camera related

* [Fuji DNG files](#why-does-focus-points-viewer-not-display-focus-points-for-fuji-dng-files)

<br>

## Q&A

<br>

#### The plugin doesn't seem to work. Is my camera not supported?

There are various reasons why the plugin might not seem to work with your photos. A good starting point is to check the [compatibility list](Compatibility.md).

The autofocus display requires certain metadata to be available as part of the image file. If the camera does not record this metadata, the plugin will not be able to display a focus point [↗](Focus-Points.md#principle-of-operation).

The same applies to straightening images. Please note that this is independent of the ability to display focus points. For instance, a camera may record AF metadata but not roll angle information. This is why the [compatibility list](Compatibility.md) has separate sections.

There are also a number of specific reasons why Focus Points Viewer does not seem to work with  certain images. This is indicated by an error message in the `Focus Information` section. Clicking the blue link icon provides more information about the underlying problem [↗](Troubleshooting_FAQ.md).


<img src="images/FAQ%20Focus%20Info%20missing.jpg"><br>

<br>

#### Is the plugin only compatible with RAW images?

In general, displaying autofocus points and straightening images works with all image files containing the full set of metadata recorded by the camera. This applies to both RAW and JPG files straight out of the camera [↗](Focus-Points.md#principle-of-operation).

Converting RAW files to DNG format inside Lightroom does not necessarily retain all metadata. For instance, DNG converted from Fuji RAF is missing essential information [↗](#why-doesnt-the-focus-points-viewer-display-focus-points-for-fuji-dng-files).

<br>

#### How can I set up a hotkey to open Focus Points Viewer? 

There are different ways to do this on Windows and macOS. [↗](Focus-Points.md#how-to-use-a-keyboard-shortcut-to-run-the-plugin). 

<br>

#### Why does `Direct View` display gray artifacts around the AF corner markings on Windows? Is my GPU the cause?

`Direct View` on Windows produces corner markings with rectangular artifacts around the overlay images:

<img src="images/Display%20Modes.jpg" alt="Direct View on Windows" style="width:600px;"/><br>

This is due to inconsistent behavior of the underlying Lightroom SDK function when using transparent PNG overlays in overlapping layouts on Windows vs macOS. 

**See also:** [Known Limitations 5)](V4-New-Features.md#5-direct-view-corner-icons-do-not-seamlessly-blend-with-the-photo-when-used-on-windows) for background information, a possible workaround, and instructions on how to support the Adobe bug report.

_This limitation of the Lightroom SDK only affects Windows and does not indicate a problem with your GPU._

<br>

#### Why are the `Preview Image` and `Export Image` display modes unavailable on macOS?

The availability of `Preview Image` and `Export Image` display modes on macOS requires the integration of the third-party tool ImageMagick which is used on Windows to draw rectangular markings onto the image file.

_Support for macOS is planned for a future V4 pre-release._ 

<br>


#### How can I stop Focus Point Viewer from switching back to the primary screen on macOS?

Focus Point Viewer remembers its size and position when you close and reopen it. However, on macOS, it doesn't remember which screen the window was opened on. If you drag the window to a secondary display, it switches back to the primary display when you open another photo.     

**See also:** [Known Limitations 1)](V4-New-Features.md#1-focus-point-viewer-does-not-remember-its-position-on-a-secondary-monitor-on-macos) for background information, and instructions on how to support the Adobe bug report.

_This limitation of the Lightroom SDK only affects macOS and cannot currently be resolved by the plugin._

<br>

#### How can I prevent Focus Point Viewer from automatically becoming the active window whenever a new photo is loaded in `Follow Lightroom` mode?

Lightroom opens floating dialogs as active window by default. Once a dialog has been opened, keyboard input is accepted and processed by the dialog. While this is desired behavior in `Interactive` mode, it breaks the user workflow in `Follow Lightroom` mode. The Lightroom SDK lacks the option of a parameter controlling the window behavior.

A workaround has been implemented on Windows using an AutoHotkey script. While this is acceptable for a pre-release, it is not a viable solution for a public release.

A similar workaround for macOS has not been investigated because Follow mode is currently of limited practical use on macOS due to another [Lightroom SDK limitation](#how-can-i-stop-focus-point-viewer-from-switching-back-to-the-primary-screen-on-macos).  

**See also:** [Known Limitations 2)](V4-New-Features.md#2-focus-point-viewer-always-becomes-the-active-window-when-opened) for background information, how to install the available workaround, and instructions on how to support the Adobe bug report.

_A workaround is available on Windows for this limitation of the Lightroom SDK._

<br>

#### Why doesn't Focus Point Viewer accept keyboard input immediately after opening in `Interactive` mode on Windows?

While Focus Point Viewer becomes the active window after it has been opened, it doesn't accept and process keyboard input until the user presses Tab, Right Arrow, Down Arrow or clicks a UI control. This behavior is a limitation of the Lightroom SDK and affects Windows only.

A workaround has been implemented using an AutoHotkey script. While this is acceptable for a pre-release, it is not a viable solution for a public release.

**See also:** [Known Limitations 3)](V4-New-Features.md#3-keyboard-shortcuts-do-not-work-immediately-after-opening-focus-point-viewer-in-interactive-mode-on-windows) for background information, how to install the available workaround, and instructions on how to support the Adobe bug report.


<br>

#### Why is Focus Point Viewer always in front on Windows?

When running Lightroom in screen mode `Normal` or `Full Screen with Menubar`, Focus Point Viewer is always in front of all other open windows. While this is usually not a problem, it can be annoying if you want to temporarily send the window to the background.

Use Lightroom screen mode `Full Screen` and Focus Point Viewer `Interactive` to be able to switch between the two windows.

**See also:** [Known Limitations 4)](V4-New-Features.md#4-focus-point-viewer-is-always-in-front-in-second-screen-mode-on-windows) for background information.

_A limited workaround for Windows exists. macOS is not affected._ 

<br>

#### Why does Lightroom display an 'Export file' progress bar even though I have chosen `Preview Image` display mode?

Apart from an explicit choice of `Export Image`, Focus Point Viewer can choose this method in two situations:

1. In `Develop` module  
Lightroom cannot always generate or update previews quickly enough while you are working in `Develop` module. (that's also why Lightroom's `Build Previews` command is not accessible in `Develop`)
2. If a `Preview Image` timeout has been specified  
  In order to reduce long opening times of Focus Point Viewer (which is basically waiting for a preview to become available), you can specify a timeout after which Focus Point Viewer no longer waits for a preview but uses `Export` instead. [↗](Focus-Points.md#how-to-reduce-long-wait-times-when-opening-the-plugin-window-on-windows).

<br>

#### Why do the Left and Right Arrow keys sometimes stop working in Lightroom when Focus Point Viewer is running in `Follow Lightroom` mode?

Observed on Windows.

When using the left and right arrow keys to navigate in filmstrip view while the Focus Points Viewer is open in 'Follow' mode, the arrow keys may stop working after some time. 

The Ctrl+Left Arrow and Ctrl+Right Arrow keys continue to work and perform the same function.

_Sending Lightroom to the background and then back to the foreground will resolve the issue._

<br>

#### Why do I have to click twice to open a photo in Focus Point Viewer from Grid view, while a single click is enough in Filmstrip view on macOS?

_This is normal macOS behavior when any application is active and you click in the grid._   
  
<br>

#### Why do empty margins appear on the right or bottom of the Focus Points Viewer window when I change its size in 'Second Screen' mode?  

The Focus Point Viewer keeps a fixed layout so it does not resize when switching between landscape and portrait photos on a secondary screen. Choosing a smaller size for the plugin window can result in empty margins. Simply resize the window once to remove them. [↗](V4-New-Features.md#13-configuration)  

<br>

#### Why doesn't the Focus Points Viewer display focus points for Fuji DNG files?

The autofocus point information (x/y coordinates) recorded by Fujifilm cameras relates to the size of the preview image inside the RAF file, not the original RAW image size. The size of the preview image is stored in the tags `ExifImageHeight` and `ExifImageWidth`. 

Neither the standalone Adobe DNG Converter nor the Lightroom integration retains these tags when converting RAF to DNG. In fact, the converter creates custom-sized preview images and embeds them in the DNG file. Consequently, the DNG file in Lightroom contains all the AF information (e.g. the positions of the autofocus point, face and subject detection), but this cannot be linked to the photo because the plugin does not know what the original preview image size was.
