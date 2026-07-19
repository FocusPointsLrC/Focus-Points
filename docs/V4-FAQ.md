# V4 – Frequently Asked Questions (FAQ)

Version 4 is the largest update since the project was revived. It fundamentally changes how Focus Point Viewer integrates with Lightroom. You can now keep the viewer open while continuing to work in Lightroom, choose between multiple rendering methods depending on your workflow, and benefit from significantly faster image display.

These new capabilities also introduce new interactions between the plugin and Lightroom. As a result, you may occasionally notice behavior that differs from what you would normally expect from a native Lightroom feature. In most cases, this is due to limitations of the Lightroom SDK rather than the plugin itself.

This FAQ explains the most common questions about Focus Point Viewer in Second Screen mode, the reasons behind certain behaviors, and the available workarounds where applicable.



## Browse by topic

### Display modes

* [`Direct View`: grey boxes around AF corner markers (Windows)](#why-does-direct-view-display-grey-boxes-around-the-af-corner-markings-on-windows-is-my-gpu-the-cause)

* [`Preview Image` / `Export Image`: why unavailable on macOS?](#why-are-the-preview-image-and-export-image-display-modes-unavailable-on-macos)

### Second Screen mode

* [Window switches back to the primary screen (macOS)](#how-can-i-stop-focus-point-viewer-from-switching-back-to-the-primary-screen-on-macos)

* [Viewer becomes the active window in `Follow` mode](#how-can-i-prevent-focus-point-viewer-from-automatically-becoming-the-active-window-whenever-a-new-photo-is-loaded-in-follow-mode)

* [Keyboard input after opening in `Interactive` mode (Windows)](#why-doesnt-focus-point-viewer-accept-keyboard-input-immediately-after-opening-in-interactive-mode-on-windows)

* [Window always stays on top (Windows)](#why-does-the-focus-point-viewer-window-always-stay-on-top-in-windows)

* [Arrow keys stop working in filmstrip (`Follow` mode, Windows)](#why-do-the-left-and-right-arrow-keys-sometimes-stop-working-in-lightroom-when-focus-point-viewer-is-running-in-follow-mode)

* [Double-click required in Grid view (macOS)](#why-do-i-have-to-click-twice-to-open-a-photo-in-focus-point-viewer-from-grid-view-while-a-single-click-is-enough-in-filmstrip-view)
  
* [Empty margins after resizing](#why-do-empty-margins-appear-on-the-right-or-bottom-of-the-focus-points-viewer-window-when-i-change-its-size-in-second-screen-mode-)  

### General

* [Keyboard shortcut to open Focus Point Viewer](#how-can-i-set-up-a-hotkey-to-open-the-focus-points-viewer-) 

<br>

## Q&A

<br>


#### Why does `Direct View` display grey boxes around the AF corner markings on Windows? Is my GPU the cause?

`Direct View` on Windows produces corner markings with rectangular artifacts around the overlay images:

<img src="images/Display%20Modes.jpg" alt="Direct View on Windows" style="width:600px;"/><br>

This is due to inconsistent behavior of the underlying Lightroom SDK function when using transparent PNG overlays in overlapping layouts on Windows vs macOS. 

_See [Known Limitations 5)](V4-New-Features.md#5-direct-view-corner-icons-do-not-seamlessly-blend-with-the-photo-when-used-on-windows) for more details, workaround and what you can do to get this issue fixed._

<br>

#### Why are the `Preview Image` and `Export Image` display modes unavailable on macOS?

The availability of `Preview Image` and `Export Image` display modes on macOS requires the integration of the third-party tool (ImageMagick) which is used on Windows to draw rectangular markings onto the image file.

_This is not yet available in V4 PRE 1, but it is planned for an upcoming pre-release._ 

<br>


#### How can I stop Focus Point Viewer from switching back to the primary screen on macOS?

The Focus Point Viewer remembers its size and position when you close and reopen the window. However, on macOS, it doesn't remember which screen the window was opened on. If you drag the window to a secondary display, it will switch back to the primary display when you open another photo.     

_See [Known Limitations 1)](V4-New-Features.md#1-focus-point-viewer-does-not-remember-its-position-on-a-secondary-monitor-on-macos) for more details and what you can do to get this issue fixed._

<br>

#### How can I prevent Focus Point Viewer from automatically becoming the active window whenever a new photo is loaded in `Follow` mode?

_See [Known Limitations 2)](V4-New-Features.md#sup2sup-focus-point-viewer-always-becomes-the-active-window-when-opened) for more details, workaround on Windows and what you can do to get this issue fixed._


<br>

#### Why doesn't Focus Point Viewer accept keyboard input immediately after opening in `Interactive` mode on Windows?

See [Known Limitations 3)](V4-New-Features.md#3-keyboard-shortcuts-do-not-work-immediately-after-opening-focus-point-viewer-in-interactive-mode-on-windows) for more details, workaround and what you can do to get this issue fixed.


<br>

#### Why does the Focus Point Viewer window always stay on top in Windows?

See [Known Limitations 4)](V4-New-Features.md#4-focus-point-viewer-windows-is-always-on-top-in-second-screen-mode-on-windows) for more details and what you can do to get this issue fixed.

This behavior on Windows is the result of a bug ("Floating dialogs always in back, never in front") that Adobe fixed in LrC 15.1.

<br>

#### Why do the Left and Right Arrow keys sometimes stop working in Lightroom when Focus Point Viewer is running in `Follow` mode?

<br>

#### Why do I have to click twice to open a photo in Focus Point Viewer from Grid view, while a single click is enough in Filmstrip view?
  
<br>

#### Why do empty margins appear on the right or bottom of the Focus Points Viewer window when I change its size in 'Second Screen' mode?  

<br>

#### How can I set up a hotkey to open the Focus Points Viewer? 

