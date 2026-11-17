# Understanding Focus Results

## Success, Warning, and Error Messages

This document explains the various Focus Point Viewer messages displayed at the top of the `Focus Information` section. These messages indicate whether the plugin was successful in detecting and visualizing focus points:

* [Focus achieved](#focus-achieved)
* [Focus points outside cropped image area](#focus-points-outside-cropped-image-area)
* [Focus points may be misaligned due to Transform](#focus-points-may-be-misaligned-due-to-transform-settings)
* [Subject detected, but focus not achieved](#subject-detected-but-focus-not-achieved)
* [Focus points selected, but focus not achieved](#focus-points-selected-but-focus-not-achieved)
* [No focus points recorded](#no-focus-points-recorded)
* [Focus point recorded in manual focus mode](#focus-point-recorded-in-manual-focus-mode)
* [Manual focus, no AF points recorded](#manual-focus-no-af-points-recorded)
* [Focus info missing from file](#focus-info-missing-from-file)
* [Camera model not supported](#camera-model-not-supported)
* [Camera maker not supported](#camera-maker-not-supported)
* [No camera-specific metadata found](#no-camera-specific-metadata-found)
* [Severe error encountered](#severe-error-encountered)

Special topics:

* [Back-Button Focus (BBF)](#back-button-focus-bbf)
* [Focus and Recompose](#focus-and-recompose)

Appendix:
* [Overview of messages and their meanings](#overview-of-messages-and-their-meanings)

<br>

**Important:** Focus Point Viewer visualizes information recorded by the camera. It does not independently determine whether the subject is sharp or whether the photograph is technically in focus. The displayed focus points and status messages should therefore be interpreted in the context of the camera's autofocus system and the circumstances in which the photo was taken.
<br><br>

### "Focus achieved"

Information about the active focus points has been detected in the photo metadata. When the shot was taken, the camera reported successful autofocus acquisition for one or more focus points.

Depending on how a particular camera records its metadata, the "Focus achieved" message may or may not be displayed for shots taken using **Back-Button Focus** (BBF). For further information, see [Back-Button Focus (BBF)](#back-button-focus-bbf).

If the photo has been taken using the **Focus and Recompose** technique, the displayed focus point does NOT correspond to the spot where the autofocus has focused. In this case, the focus point display is misleading. See  [Focus and Recompose](#focus-and-recompose) for further explanation.

<img src="images/Understanding 1.jpg" alt="Understanding 1" style="width: 1000px;"/>
<br><br>

### "Focus points outside cropped image area"

Active focus points have been detected, but they are either partially or completely outside the visible cropped image area.

**Note:** This message is not triggered by face or subject detection frames, only focus points. 

**Example:** Cropped image (focus point outside visible crop):

<img src="images/Understanding 2a.jpg" alt="Understanding 2a" style="width: 1000px;"/>

Original image with focus point:

<img src="images/Understanding 2b.jpg" alt="Understanding 2b" style="width: 1000px;"/>
<br><br>

### "Focus points may be misaligned due to Transform settings"

The focus point information recorded by the camera refers to the original image. The plugin can correctly position focus points when the photo has been cropped, rotated, or flipped using Lightroom's Crop tool. However, it cannot compensate for Transform or Upright operations. As a result, the displayed focus points may no longer accurately correspond to their actual positions in the transformed image.

**Example:** Original photo. Autofocus point and bird head detection is positioned on the bird's head:   

<img src="images/Understanding 3a.jpg" alt="Understanding 3a" style="width: 1000px;"/>

The photo has been processed with Transform, Upright 'Auto'. Transform operations change the geometry of the image content, so the focus point and subject detection frames may no longer be properly aligned with the subject features (such as the bird's body and head) that triggered autofocus:

<img src="images/Understanding 3b.jpg" alt="Understanding 3b" style="width: 1000px;"/>

The actual error depends on the type and degree of transformation. A small Transform adjustment might produce only a very small displacement, while a strong perspective correction can produce a substantial one.

If accurate focus point positioning is important, always check the photo with Transform operations disabled.
<br><br>

### "Subject detected, but focus not achieved"

The camera has detected a subject or a face, but has not recorded information identifying which AF points, if any, were in focus when the shot was taken. This typically indicates that focus was not achieved.

The exact reason for this depends on the specific camera model and the way the camera manufacturer has designed the AF system to work.

One possible reason for this situation is that the AF system has not been able to complete its task. For example, the camera may have been set to "Release Priority", allowing the shutter to be released even though autofocus had not yet completed its task. 

**Example:** A face has been detected but the `AF Search` tag in `Focus Information` shows `Not Ready`: 

<img src="images/Understanding 4.jpg" alt="Understanding 4" style="width: 1000px;"/>
<br><br>

### "Focus points selected, but focus not achieved"

One or more focus points have been selected, but focus was not achieved.

Information about AF points "in focus" is not available in the metadata; it was not recorded by the camera.

The camera has not recorded information identifying which AF points, if any, were in focus when the shot was taken.

One possible reason for this situation is that the AF system has not been able to complete its task. For example, the camera may have been set to "Release Priority", allowing the shutter to be released even though autofocus had not yet completed its task. 

Another typical reason is that the photo was taken using **Back-Button Focus**. Some cameras (e.g., Canon and OM System) record the focus point used when the photographer presses the AF button as the "selected focus point". Releasing the shutter button does not necessarily record any additional focus information. If the camera has been moved between focusing and releasing the shutter button, the displayed selected focus point may no longer correspond to the actual location where autofocus was performed.

<img src="images/Understanding 5.jpg" alt="Understanding 5" style="width: 1000px;"/>
<br><br>


### "No focus points recorded"

The camera has not recorded any information about focus points. The absence of this information typically means that focus was not achieved.

This is a more general case of the situations [Subject detected, but focus not achieved](#subject-detected-but-focus-not-achieved) and [Focus points selected, but focus not achieved](#focus-points-selected-but-focus-not-achieved). Not all cameras record information about detected subjects or the focus points selected when taking a shot.

<img src="images/Understanding 6.jpg" alt="Understanding 6" style="width: 1000px;"/>
<br><br>


### "Focus point recorded in manual focus mode"

Some cameras, including certain Fujifilm and Hasselblad models, record focus information even when manual focus mode is selected.

Unlike autofocus-determined focus points, the focus point displayed for a photo taken in manual focus mode (AF-M for Fujifilm, MF for Hasselblad) does not necessarily indicate a sharp area of the image. Instead, it represents an area selected by the photographer that can be used with various manual-focus assistance functions.

Depending on the camera, the selected focus area can be used with functions such as:

- Fujifilm: Focus Check<sup>1</sup> or Instant AF<sup>2</sup>.
- Hasselblad: Auto Zoom<sup>1</sup> or Focus Indicator<sup>3</sup>.

These functions can help the photographer achieve focus at the selected location, but this is not necessarily what happens. At least on Fujifilm cameras, the currently selected focus area is recorded regardless of whether the photographer actually used it to focus the image.

**Important:** A focus point recorded in manual focus mode does not necessarily indicate where the photographer actually focused. It may simply represent the area selected for manual-focus assistance, regardless of whether that area was used to achieve focus.

**In manual focus mode, you need to recall the circumstances in which the image was captured in order to make sense of the focus point information.**

<sup>1</sup> **Focus magnifier:** The EVF or camera display automatically zooms in on the selected focus area when the focus ring is rotated in manual focus mode.

<sup>2</sup> **Instant AF:** Fujifilm's Instant AF temporarily activates the autofocus system while the camera is in manual focus mode. By pressing a designated button (typically AF-ON or AE-L/AF-L), the camera performs autofocus on the selected subject and then returns to manual focus when the button is released.

<sup>3</sup> **Focus Indicator:** The Hasselblad Focus Indicator appears in the EVF or on the camera display. It indicates whether the subject is in focus and, if not, which direction to turn the focus ring. Depending on the camera model, it may also provide visual or haptic confirmation when focus is achieved.

<img src="images/Understanding 7.jpg" alt="Understanding 7" style="width: 1000px;"/>
<br><br>


### "Manual focus, no AF points recorded"
This is a special but very common case of "No focus points recorded". The photo was taken using manual focus (MF), no autofocus (AF) information is available in the metadata.

<img src="images/Understanding 8.jpg" alt="Understanding 8" style="width: 1000px;"/>
<br><br>


### "Focus info missing from file"

Camera information is available, but the required original focus metadata is missing.

The selected photo does not contain the original camera metadata needed to process and visualize focus information. This error message typically occurs when you try to view focus points for an image that was processed outside of Lightroom (for example, in Photoshop).

Why is this happening?
The plugin requires the original camera metadata to process and visualize focus information. Much of this information, along with other camera-specific settings, is stored in the MakerNotes section of the EXIF metadata.

Lightroom does not preserve the original MakerNotes when creating rendered files. Consequently, when an image is exported to another application such as Photoshop and subsequently re-imported into Lightroom as a TIFF, the original MakerNotes and the focus information they contain are generally no longer available. The plugin therefore lacks the information needed to visualize the focus points.

For more details and concrete examples, see [Scope and Limitations](Focus-Points.md#1-scope-and-limitations).  

For example, this image was imported into Lightroom as a RAW file and then edited in Photoshop. The re-imported TIFF file is missing the MakerNotes and focus information, so the plugin does not have the data it needs to work.

<img src="images/Understanding 9.jpg" alt="Understanding 9" style="width: 1000px;"/>
<br><br>


### "Camera model not supported"

The selected photo was taken with a camera model that is not supported by the plugin.

This message may appear for older camera models that use different structures for storing AF-related information than their successors. It may also appear for newer models whose AF-related metadata has not yet been decoded by ExifTool.

**Example:** Photo taken with the original Canon 1D from 2001:

<img src="images/Understanding 10.jpg" alt="Understanding 10" style="width: 1000px;"/>
<br><br>


### "Camera maker not supported"

The camera manufacturer is known, but its metadata format is not supported.

Adding at least basic support for a camera manufacturer is often relatively straightforward, provided that the relevant AF metadata is available and can be decoded by ExifTool. This is not always the case, for example with some manufacturers such as Sigma and Samsung.

<img src="images/Understanding 11.jpg" alt="Understanding 11" style="width: 1000px;"/>
<br><br>


### "No camera-specific metadata found"

The camera make and model cannot be identified from the available metadata.

The selected photo does not contain information identifying the camera used. Both the camera make and model are unknown. This is typically the case when an image has been exported from Lightroom (or another application) without including camera metadata.

**Example:** The plugin cannot process this photo and can only display it:

<img src="images/Understanding 12.jpg" alt="Understanding 12" style="width: 1000px;"/>
<br><br>


### "Severe error encountered"

This message is displayed when something serious and unexpected happens during the process of reading focus information from the metadata, processing it, and displaying the visualization elements.

Possible causes include installation problems, unexpected metadata, or situations that are not properly handled by the plugin code. The log file may give some indication of what the problem is, but usually it is not something a user can fix.

If you encounter this problem and cannot resolve it yourself, please visit the plugin's [GitHub issue tracker](https://github.com/FocusPointsLrC/Focus-Points/issues) and create a new issue describing the problem. You will need a free GitHub account to do so. Please include the plugin log file if possible, as it may help identify the cause of the error.
<br><br>

## Special Topics

### Back-Button Focus (BBF)

Back-Button Focus is a technique that separates autofocus activation from the shutter release. Instead of activating autofocus by half-pressing the shutter button, the photographer uses a separate button, usually located on the back of the camera, to initiate autofocus.

The photographer presses the AF button to focus on the subject and then releases it. Pressing the shutter button to take the picture does not trigger autofocus again. This allows the photographer to lock focus and take one or more pictures without having to refocus each time.

Depending on the camera manufacturer, the focus information recorded in the metadata may not reflect this sequence of events. Some cameras (e.g., Canon and OM System) record the focus point used when autofocus was activated, even if the shutter is released later without triggering autofocus again.

Consequently, the displayed focus point may not correspond to the location where the subject was positioned when the picture was taken. Furthermore, depending on how the camera records focus information, the plugin may not be able to determine whether focus was successfully achieved.

**Example:**

<img src="images/Understanding 13.jpg" alt="Understanding 13" style="width: 1000px;"/>
<br><br>

### Focus and Recompose

Focus and Recompose is a photographic technique in which the photographer first focuses on a subject and then moves the camera to change the composition before taking the picture.

This is commonly done when using a single, centrally positioned autofocus point. The photographer places the focus point over the subject, activates autofocus (usually by half-pressing the shutter button or using Back-Button Focus), and holds focus while recomposing the image.

The camera records the position of the autofocus point used to acquire focus. However, if the photographer subsequently recomposes the image, the subject may appear at a different position in the final photograph. The plugin displays the recorded AF point at its original position, which may no longer correspond to the subject's location.

**Important:** Focus and Recompose can also affect actual focus accuracy. When the camera is rotated to recompose the image, the plane of focus changes its orientation relative to the subject. Depending on the subject distance, aperture, and amount of recomposition, this can result in the subject no longer being perfectly in focus.

**Example:**

<img src="images/Understanding 14.jpg" alt="Understanding 14" style="width: 1000px;"/>
<br><br>

## Appendix 

### Overview of messages and their meanings

| Focus Result Message | Type | Meaning |
|---|:-:|---|
| **Focus achieved** | Success | The camera reported successful autofocus acquisition for one or more focus points. |
| **Focus points outside cropped image area** | Warning | Active focus points are partially or completely outside the visible cropped image area. |
| **Focus points may be misaligned due to Transform** | Warning | Transform or Upright operations may have changed the image geometry, causing focus points and subject detection frames to be incorrectly positioned. |
| **Subject detected, but focus not achieved** | Warning | A subject or face was detected, but the camera did not record successful focus acquisition. |
| **Focus points selected, but focus not achieved** | Warning | One or more focus points were selected, but the camera did not record successful focus acquisition. |
| **No focus points recorded** | Warning | The camera did not record any focus point information. This typically means that focus was not achieved. |
| **Focus point recorded in manual focus mode** | Warning | The camera recorded a focus area in manual focus mode. This may simply be an area selected for manual-focus assistance, not necessarily where the photographer actually focused. |
| **Manual focus, no AF points recorded** | Warning | The photo was taken in manual focus mode, and no autofocus information is available in the metadata. |
| **Focus info missing from file** | Error | The original camera metadata required to process and visualize focus information is missing. |
| **Camera model not supported** | Error | The camera model is not supported by the plugin. |
| **Camera maker not supported** | Error | The camera manufacturer is known, but its AF metadata format is not supported by the plugin. |
| **No camera-specific metadata found** | Error | The camera make and model cannot be identified from the available metadata. |
| **Severe error encountered** | Error | An unexpected error occurred while reading, processing, or displaying focus information. |
