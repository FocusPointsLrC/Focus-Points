# Understanding Focus Results

## Success, Warning and Error Messages

This document explains the various Focus Point Viewer messages displayed at the top of the `Focus Information` section. These messages summarize whether the plugin was successful in detecting and visualising focus points. These messages can be success messages (green), warnings (orange) or error messages (red).

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

<br>

### "Focus achieved"

Information about the active focus points has been detected in the photo metadata. When the shot was taken, the camera autofocus achieved focus for one or more autofocus points.

Depending on how metadata is recorded by a particular camera, 'Focus achieved' might or might NOT be displayed for shots taken with **Back-Button Focus** (BBF). For further information, see [Back Button Focus (BBF)](#back-button-focus-bbf).

If the photo has been taken using the **Focus and Recompose** technique, the displayed focus point does NOT correspond to the spot where the autofocus has focused. See  [Focus-and-Recompose](#focus-and-recompose) for further explanation.

<img src="images/Understanding 1.jpg" alt="Understanding 1" style="width: 1000px;"/>
<br><br>

### "Focus points outside cropped image area"

Active focus points have been detected, but they are invisible or partially invisible because they are located outside the cropped image area.

**Note:** This message is not triggered by face or subject detection frames, only focus points. 

Cropped image (focus point outside visible crop):

<img src="images/Understanding 2a.jpg" alt="Understanding 2a" style="width: 1000px;"/>

Original image with focus point:

<img src="images/Understanding 2b.jpg" alt="Understanding 2b" style="width: 1000px;"/>
<br><br>

### "Focus points may be misaligned due to Transform settings"

The focus point information recorded by the camera refers to the original image. While the plugin can retain the original focus point location if the photo has been cropped, rotated, or flipped in Lightroom, this is not possible for photos to which Transform or Upright operations have been applied. As a result, the displayed focus point may not accurately match its actual position in the transformed image.

This photo has been processed with Transform, Upright 'Auto'. Note that the frames for autofocus point and bird head detection are slightly off:

<img src="images/Understanding 3a.jpg" alt="Understanding 3a" style="width: 1000px;"/>

Transform operations change the geometry of the image content, so the focus point and subject detection frames may no longer be properly aligned with the subject features (such as the bird's body and head) that triggered autofocus:

<img src="images/Understanding 3b.jpg" alt="Understanding 3b" style="width: 1000px;"/>

The actual error depends on the type and degree of transformation. A small Transform adjustment might produce only a very small displacement, while a strong perspective correction can produce a substantial one.

If precision of focus point display matters, you should always check this on a photo without Transform operations applied.
<br><br>

### "Subject detected, but focus not achieved"

The camera has detected a subject or a face but focus was not achieved.

Information about AF points "in focus" is not available in the metadata; it was not recorded by the camera.

The exact reason for this behavior may depend on the specific camera model and the way the camera manufacturer has designed the AF system to work.

A common potential reason for this situation is that the AF system has not been able completed its task. For instance, if the shot was taken with "Release Priority" and the autofocus was "not ready" yet. 


<img src="images/Understanding 4.jpg" alt="Understanding 4" style="width: 1000px;"/>
<br><br>

### "Focus points selected, but focus not achieved"

A focus point has been selected focus was not achieved.

Information about AF points "in focus" is not available in the metadata; it was not recorded by the camera.

The exact reason for this behavior may depend on the specific camera model and the way the camera manufacturer has designed the AF system to work.

A common potential reason for this situation is that the AF system has not been able completed its task. For instance, if the shot was taken with "Release Priority" and the autofocus was "not ready" yet.

Another typical reason is that the photo has been taken using **Back-Button Focus.** Some cameras (e.g. Canon, OM System) record the focus point that was used to focus the shot (using the AF-button) as "selected focus point". Releasing the shutter button does not record any further focus points. If the camera has been moved between focusing and releasing the shutter button, the displayed selected focus point will NOT correspond to the spot where the autofocus has focused.  

<img src="images/Understanding 5.jpg" alt="Understanding 5" style="width: 1000px;"/>
<br><br>


### "No focus points recorded"

The camera has not recorded any focus points, neither selected ones nor such that are in focus.

to be added

<img src="images/Understanding 6.jpg" alt="Understanding 6" style="width: 1000px;"/>
<br><br>


<a id="focus-point-recorded-in-manual-focus-mode"></a>
### "Focus point recorded in manual focus mode"

Fujifilm cameras store focus information when using the manual focus mode (AF-M). 

Unlike autofocus-determined focus points, manual focus points do not necessarily indicate the sharpest parts of an image. Instead, they **represent the center of the focus area** selected by the camera user (single point / zone / wide).

When the photographer uses the selected focus area to focus the image and this area is small (single point), the displayed focus point will probably correspond to a sharp part of the image. Otherwise, the displayed focus point may end up over an unsharp part of the image.

In manual focus mode, you need to recall the circumstances in which the image was captured in order to make sense of the focus point information.

<img src="images/Understanding 7.jpg" alt="Understanding 7" style="width: 1000px;"/>
<br><br>


### "Manual focus, no AF points recorded"
This is a special but very typical case of "No focus points recorded". The photo was taken with manual focus (MF), so there is no autofocus (AF) information in the metadata.

<img src="images/Understanding 8.jpg" alt="Understanding 7" style="width: 1000px;"/>
<br><br>


### "Focus info missing from file"

The selected photo lacks the metadata needed to process and visualize focus information. This error message typically occurs when you try to view focus points for an image that was processed outside of Lightroom (for example, in Photoshop).

Why is this happening?
The plugin requires the metadata of original, out-of-camera JPGs or RAW files in order to work. Focus information, along with many other camera-specific settings, is stored in _makernotes_, a manufacturer-specific section of the EXIF metadata.
Lightroom does not retain or even read makernotes when importing files. Therefore, if a separate file is created from the original image (e.g. by exporting to another application such as Photoshop), this information will not be present in the file and the plugin will not have the necessary inputs to work.


For more details and concrete examples, see [Scope and Limitations](Focus-Points.md#1-scope-and-limitations).  

For example, this image was imported into Lightroom as a RAW file and then edited in Photoshop. The re-imported TIFF file is missing the makernotes and focus information, so the plugin does not have the data it needs to work.

<img src="images/Understanding 9.jpg" alt="Understanding 9" style="width: 1000px;"/>

The log file reveals whether intact metadata is available or not by indicating which tag has not been found:

<img src="images/Troubleshooting 7.jpg" alt="User Interface (Multi-image)" style="width: 800px;"/>
<br><br>


### "Camera model not supported"

The selected photo was taken by a camera that the plugin cannot handle.

This message may be displayed for older camera models that do not use the same structures to store AF-related information as their successor models. It can also be displayed for newer models where the AF related information has not yet been decoded by ExifTool.

Example for the original Canon 1D from 2001:

<img src="images/Understanding 10.jpg" alt="Understanding 10" style="width: 1000px;"/>
<br><br>


### "Camera maker not supported"

The selected photo was taken with a camera from a manufacturer that the plugin cannot handle.

While it is not difficult to add at least basic support for a camera brand, this requires that the relevant AF metadata be available. This means they have to be "known" by exifool, which is not the case for Leica, Hasselblad, Sigma, Samsung phones and others.

<img src="images/Understanding 11.jpg" alt="Understanding 11" style="width: 1000px;"/>
<br><br>


### "No camera-specific metadata found"

The selected photo does not include information about the camera used. The make and model of the camera are both unknown, as is usually the case when an image file is exported from Lightroom (or any other program) without metadata. 

Clearly, the plugin is unable to perform any actions on this photo other than display it.

<img src="images/Understanding 12.jpg" alt="Understanding 12" style="width: 1000px;"/>
<br><br>


### "Severe error encountered"

This message is displayed when something serious and unexpected happens during the process of reading focus information from the metadata, processing it, and displaying the visualization elements.

This can be anything from installation problems, unexpected metadata, or simply that the programmer did not handle a particular situation properly in the plugin code. The log file may give some indication of what the problem is, but usually it is not something a user can fix.

If you encounter this problem and cannot fix it yourself, please go to the plugin home page on Github, sign up for a free account if you don't already have one, and [create a new issue](https://github.com/FocusPointsLrC/Focus-Points/issues) that describes the problem. This way you can help make the plugin better and more reliable!


### Back Button Focus (BBF)

to be added


### Focus and Recompose

to be added
