## ⚠️ Important update for users of V3.4 and V4 PRE 1<br><br>[CRITICAL: Update check fails to detect available updates in V3.4 and V4 PRE 1](https://github.com/FocusPointsLrC/Focus-Points/issues/405)

<br>

# Frequently Asked Questions (FAQ)

Got a question? Chances are you'll find the answer here.

This FAQ answers common questions about Focus Point Viewer, explains certain behaviors, and describes available workarounds where applicable.



## Browse by category

### Camera Support

* [Is my camera supported?](#the-plugin-doesnt-seem-to-work-is-my-camera-not-supported)

### Installation

* [Installing the Lightroom plugin](#i-have-never-worked-with-lightroom-plugins-what-do-i-need-to-install-focus-point-viewer)
* [Windows security alerts during download or installation](#why-am-i-getting-a-security-alert-by-windows-defender-and-virustotal) 

### Setup

* [Settings to be made before running Focus Point Viewer](#is-there-anything-i-need-to-do-after-installation-or-can-i-start-using-it-right-away)

### File Types

* [Supported file types](#is-the-plugin-only-compatible-with-raw-images)

### Keyboard Shortcuts

* [Using a keyboard shortcut to open Focus Point Viewer](#how-can-i-set-up-a-hotkey-to-open-focus-point-viewer)
* [Using keyboard shortcuts to operate Focus Point Viewer](#im-used-to-working-in-lightroom-using-keyboard-shortcuts-does-focus-point-viewer-support-this-way-of-working)

### Display Modes

* [`Direct View`: gray artifacts around corner markers (Windows)](#why-does-direct-view-display-gray-artifacts-around-the-af-corner-markings-on-windows-is-my-gpu-the-cause)

* [`Preview Image` / `Export Image`: why unavailable on macOS?](#why-are-the-preview-image-and-export-image-display-modes-unavailable-on-macos)

### Second Screen Mode

* [Window switches back to the primary screen (macOS)](#how-can-i-stop-focus-point-viewer-from-switching-back-to-the-primary-screen-on-macos)

* [Viewer becomes the active window in `Follow Lightroom` mode](#how-can-i-prevent-focus-point-viewer-from-automatically-becoming-the-active-window-whenever-a-new-photo-is-loaded-in-follow-lightroom-mode)

* [Keyboard input after opening in `Interactive` mode (Windows)](#why-doesnt-focus-point-viewer-accept-keyboard-input-immediately-after-opening-in-interactive-mode-on-windows)

* [Window always in front (Windows)](#why-is-focus-point-viewer-always-in-front-on-windows)
  
* [`Export file` when `Preview Image` is selected](#why-does-lightroom-display-an-export-file-progress-bar-even-though-i-have-chosen-preview-image-display-mode)

* [Arrow keys stop working in filmstrip (`Follow Lightroom` mode, Windows)](#why-do-the-left-and-right-arrow-keys-sometimes-stop-working-in-lightroom-when-focus-point-viewer-is-running-in-follow-lightroom-mode)

* [Double-click required in Grid view (macOS)](#why-do-i-have-to-click-twice-to-open-a-photo-in-focus-point-viewer-from-grid-view-while-a-single-click-is-enough-in-filmstrip-view-on-macos)
  
* [Empty margins after resizing](#why-do-empty-margins-appear-on-the-right-or-bottom-of-the-focus-point-viewer-window-when-i-change-its-size-in-second-screen-mode)  

### User Interface

* [Plugin window exceeds screen dimensions](#the-plugin-window-exceeds-the-dimensions-of-my-screen-how-can-this-be-avoided)
 
### Performance

* [Wait times when opening the plugin window on Windows](#is-there-anything-i-can-do-to-reduce-how-long-it-takes-to-open-the-plugin-window)

* [Impact of display modes on performance](#does-the-display-mode-affect-how-long-it-takes-to-open-the-plugin-window)

* [Why does Preview Image sometimes fall back to Export?](#why-does-preview-image-sometimes-revert-to-export)

### Known Camera Limitations

* [Fuji DNG files](#why-doesnt-the-focus-point-viewer-display-focus-points-for-fuji-dng-files)

<br>

## Q&A

<br>

#### The plugin doesn't seem to work. Is my camera not supported?

There are various reasons why the plugin might not seem to work with your photos. A good place to start is to check the [compatibility list](Compatibility.md). The plugin supports all camera models released by Canon, Nikon, Sony, Fujifilm, Olympus/OM, Panasonic and Pentax within the last 10 years, as well as significantly older models.

The autofocus display requires certain metadata to be available as part of the image file. If the camera does not record this metadata, the plugin will not be able to display a focus point. [↗](Focus-Points.md#principle-of-operation)

The same applies to straightening images. Please note that this is independent of the ability to display focus points. For instance, a camera may record AF metadata but not roll angle information. This is why the [compatibility list](Compatibility.md) has separate sections.

There are also a number of specific reasons why Focus Point Viewer does not seem to work with  certain images. This is indicated by an error message in the `Focus Information` section. Clicking the blue link icon provides more information about the underlying problem. [↗](Troubleshooting_FAQ.md)

<img src="images/FAQ%20Focus%20Info%20missing.jpg"><br>

_If your camera manufacturer is supported and your camera is less than 10 years old, it is most likely that your camera model is supported._

<br>

#### I have never worked with Lightroom plugins. What do I need to install Focus Point Viewer?

The installation of Focus Point Viewer follows the same procedure as most third party plugins. The User Manual covers a [compact description](Focus-Points.md#212-compact-instructions) for users that are familiar with that procedure, as well as [detailed description](Focus-Points.md#213-detailed-instructions) for users that have no practical experience with installing plugins.

_Although plugin installation may seem complicated at first, it's not difficult if you follow the instructions._  

<br>

#### Why am I getting a security alert by Windows Defender and VirusTotal?

Security software such as Windows Defender or VirusTotal may flag an alert that the plugin contains potentially dangerous files. All known incidents relating to these alerts involve the precompiled AutoHotkey script executables intended to run the plugin via a keyboard shortcut, without the need to install the AutoHotkey utility. It is a widely known issue that the Ahk2Exe compiler can trigger virus protection alarms, and this has been brought to the attention of the developers. [↗](https://github.com/AutoHotkey/Ahk2Exe/issues/119)

In the past, MalwareBytes also blocked the plugin site on GitHub for the same reason. This block has been removed by MalwareBytes upon request. [↗ ](https://forums.malwarebytes.com/topic/334869-focus-points-plugin-for-lightroom-classic-website-blocked-after-new-release/)

If you're still suspicious and want to be absolutely sure, delete the `.exe` files from the directory `focuspoints.lrplugin\ahk` and use AutoHotkey instead to run the `.ahk` script files, if you want to use a keyboard shortcut to run the plugin. [↗](Focus-Points.md#create-your-own-custom-keyboard-shortcuts) 

_The plugin package is safe and does not contain any infected or dangerous files._ 

 


<br>

#### Is there anything I need to do after installation, or can I start using it right away?

V3.4 works well with its default settings. There are only a few options you may want to adjust before using the plugin. [↗](V4-Quick-Setup-Guide.md#v3x-quick-setup-guide)

V4 introduces the Second Screen and Display modes. To use these features effectively, you must adapt their settings to your intended workflow. [↗](V4-Quick-Setup-Guide.md#v4-quick-setup-guide)

_If you're feeling impatient, you can skip the V3.4 documentation and get started right away. For V4, it is recommended that you at least skim the Quick Start Guide._ 

<br>

#### Is the plugin only compatible with RAW images?

In general, displaying autofocus points and straightening images works with all image files containing the full set of metadata recorded by the camera. This applies to both RAW and JPG files straight out of the camera. [↗](Focus-Points.md#principle-of-operation)

DNG files created or converted from RAW can still contain relevant metadata. However, this depends on the individual application used to create the DNG file. [↗](Focus-Points.md#supported-dng-files)

For instance, DNG converted from Fuji RAF is missing essential information. [↗](#why-doesnt-the-focus-point-viewer-display-focus-points-for-fuji-dng-files)

_The plugin is compatible with all JPG and RAW files straight out of camera. It is also likely to work with DNG files but this depends on the camera model and the application._

<br>

#### How can I set up a hotkey to open Focus Point Viewer? 

Yes. There are different ways to do this on Windows and macOS. [↗](Focus-Points.md#how-to-use-a-keyboard-shortcut-to-run-the-plugin)

_You can setup custom keyboard shortcuts to run Focus Point Viewer, Metadata Viewer and Straighten Images on both Windows and macOS._ 

<br>

#### I'm used to working in Lightroom using keyboard shortcuts. Does Focus Point Viewer support this way of working?

To simplify operation of the plugin, keyboard shortcuts are supported. These shortcuts can be used to perform all actions associated with the user interface, meaning you can operate the plugin entirely with the keyboard and never need to touch the mouse. [↗](Focus-Points.md#keyboard-shortcuts)

Since Lightroom doesn't support the use of keyboard shortcuts in plugins, Focus Point Viewer uses a "trick" to implement keyboard shortcuts. This approach has certain limitations. [↗](Focus-Points.md#important-technical-note-on-keyboard-shortcuts-)

_The Focus Point Viewer features can be controlled entirely using the keyboard._

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

_A workaround is available on Windows for this limitation of the Lightroom SDK._

<br>

#### Why is Focus Point Viewer always in front on Windows?

When running Lightroom in screen mode `Normal` or `Full Screen with Menubar`, Focus Point Viewer is always in front of all other open windows. This can be annoying if you are using Lightroom and the plugin in interactive mode on the same screen and want to switch between them.

By using Lightroom screen mode `Full Screen` and Focus Point Viewer `Interactive` you can at least bring Lightroom to the front until a different photo is selected.

**See also:** [Known Limitations 4)](V4-New-Features.md#4-focus-point-viewer-is-always-in-front-in-second-screen-mode-on-windows) for background information.

_There is a very limited workaround for Windows, macOS is not affected._ 

<br>

#### Why does Lightroom display an 'Export file' progress bar even though I have chosen `Preview Image` display mode?

Apart from an explicit choice of `Export Image`, Focus Point Viewer can choose this method in two situations:

1. In `Develop` module  
Lightroom cannot always generate or update previews quickly enough while you are working in `Develop` module. (that's also why Lightroom's `Build Previews` command is not accessible in `Develop`)
2. If a `Preview Image` timeout has been specified  
  In order to reduce long opening times of Focus Point Viewer (which is basically waiting for a preview to become available), you can specify a timeout after which Focus Point Viewer no longer waits for a preview but uses `Export` instead. [↗](Focus-Points.md#how-to-reduce-long-wait-times-when-opening-the-plugin-window-on-windows)

_The plugin can decide to use 'Export Image' based on the situation, if this display mode is to be preferred over 'Preview Image'._

<br>

#### Why do the Left and Right Arrow keys sometimes stop working in Lightroom when Focus Point Viewer is running in `Follow Lightroom` mode?

Observed on Windows only.

When using the left and right arrow keys to navigate in filmstrip view while the Focus Point Viewer is open in 'Follow' mode, the arrow keys may stop working after some time. 

The Ctrl+Left Arrow and Ctrl+Right Arrow keys continue to work and perform the same function.

_Switching to another application and then back to Lightroom restores normal behavior._

<br>

#### Why do I have to click twice to open a photo in Focus Point Viewer from Grid view, while a single click is enough in Filmstrip view on macOS?

_This is normal macOS behavior when any application is active and you click in the grid._   
  
<br>

#### Why do empty margins appear on the right or bottom of the Focus Point Viewer window when I change its size in 'Second Screen' mode?  

The Focus Point Viewer keeps a fixed layout so it does not resize when switching between landscape and portrait photos on a secondary screen. Choosing a smaller size for the plugin window can result in empty margins. Simply resize the window once to remove them. [↗](V4-New-Features.md#13-configuration)  

_The Focus Point Viewer cannot remember the last window position used and automatically resize to fit the displayed contents at the same time._

<br>

#### The plugin window exceeds the dimensions of my screen. How can this be avoided?

If you are experiencing this problem, it is highly likely that you are using Windows and have set a scale factor in the Display settings. A typical example would be a screen with a high resolution but a relatively small area, such as a laptop with a 4K display.

Lightroom SDK apps, such as Focus Point Viewer, are unaware of this scale factor. You can adjust a setting to tell the plugin about it. [↗](Focus-Points.md#screen-scaling)

_This can happen in Windows, but the plugin provides a setting that can be used to correct it._

<br>

#### Is there anything I can do to reduce how long it takes to open the plugin window?

In general, the time taken to open Focus Point Viewer generally depends on the following factors:
- The hardware used (CPU/GPU and disk speed).
- Lightroom performance.
- The size of the image.
- The number of focus points in the photo (in some cases).

For a given setup, the display mode used by Focus Point Viewer can make a difference.<br>

**V3.x:**<br>
On macOS, Focus Point Viewer uses `Direct View` which is the fastet way to display an image.<br> 
On Windows, `Preview Image` is used since `Direct View` is limited by the Lightroom SDK. `Preview Image` requires a preview of the photo, which can have a significant impact. See [How to reduce long wait times when opening the plugin window on Windows](Focus-Points.md#how-to-reduce-long-wait-times-when-opening-the-plugin-window-on-windows) for a detailed explanation what you can do to improve speed. 

**V4:**<br>
V4 provides extended support for Display Modes. [↗](V4-New-Features.md#2-display-modes)  
On macOS, Focus Point Viewer uses `Direct View` which is the fastet way to display an image.<br>
On Windows, you can now also select the 'Direct View' option, but the presentation [↗](V4-New-Features.md#21-changing-the-active-display-mode-on-the-fly) in this mode is limited. [↗](V4-New-Features.md#sup5sup-direct-view-corner-icons-do-not-seamlessly-blend-with-the-photo-when-used-on-windows)      
If visual appearance is more important than speed in your workflow, the right choice for you is `Preview Image`.  See [How to reduce long wait times when opening the plugin window on Windows](Focus-Points.md#how-to-reduce-long-wait-times-when-opening-the-plugin-window-on-windows) for a detailed explanation what you can do to improve speed.

_If you're not using an outdated setup, the plugin can open a photo in between 0.5 and 1 second, unless a preview is not yet available in Lightroom._ 

<br>

#### Does the display mode affect how long it takes to open the plugin window?

Yes, it does. The various display modes offered in V4 differ in terms of both the appearance of the markings and performance.. `Direct View` renders the displayed image entirely in memory and therefore provides the fastest display. [↗](V4-New-Features.md#2-display-modes)

_`Direct View` is the fastest display mode and is therefore the recommended choice for workflows where speed is important._

<br>

#### Why does `Preview Image` sometimes revert to Export?

`Preview Image` fallback can be configured in the plugin settings to reduce the time it takes to open the plugin window. The waiting time for a preview to become available in Lightroom is limited to a certain threshold, after which the image will be created by Export. [↗](Focus-Points.md#how-to-reduce-long-wait-times-when-opening-the-plugin-window-on-windows)

_The plugin can decide to use 'Export Image' based on the situation, if this display mode is to be preferred over 'Preview Image'._

<br>

#### Why doesn't the Focus Point Viewer display focus points for Fuji DNG files?

The autofocus point information (x/y coordinates) recorded by Fujifilm cameras relates to the size of the preview image inside the RAF file, not the original RAW image size. The size of the preview image is stored in the tags `ExifImageHeight` and `ExifImageWidth`. 

Neither the standalone Adobe DNG Converter nor the Lightroom integration retains these tags when converting RAF to DNG. In fact, the converter creates custom-sized preview images and embeds them in the DNG file. Consequently, the DNG file in Lightroom contains all the AF information (e.g. the positions of the autofocus point, face and subject detection), but this cannot be linked to the photo because the plugin does not know what the original preview image size was.

_Creating a DNG file from a RAF file involves generating new preview images, which typically differ in dimension from the original embedded preview image. Since the original preview dimensions have been lost, the plugin can no longer link the autofocus information to the original photo._
`
