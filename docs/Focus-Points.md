# User Manual

## Content

### [Scope and Limitations](#1-scope-and-limitations)

### [Overview and Basic Operation](#2-overview-and-basic-operation)

*  [Installation](#21-installation)
*  [Focus Point Viewer](#22-focus-point-viewer)<br>
   - [Photo View](#photo-view), [Info View](#info-view), [Navigation Controls](#navigation-controls), [Flagging Controls](#flagging-controls), [Straightening Control](#straightening-control), [User Messages](#user-messages), [Plugin Status](#plugin-status), [Keyboard Shortcuts](#keyboard-shortcuts) 
*  [Metadata Viewer](#23-metadata-viewer)
*  [Straighten Images](#24-straighten-images)
   - [Operation](#operation), [Customization](#customization), [Keyboard Shortcut](#keyboard-shortcut), [General Remarks](#general-remarks) 
*  [Configuration and Settings](#25-configuration-and-settings)
   - [Screen Scaling](#screen-scaling), [User Interface](#user-interface-settings), [Viewing Options](#viewing-options), [Logging](#logging), [Straightening Options](#straightening-options), [Update Check](#update-check)

### [Display of Focus Points](#3-display-of-focus-points)

* Camera-maker specific sections for:<br> [Canon](#31-canon), [Nikon](#32-nikon), [Sony](#33-sony), [Fujifilm](#34-fujifilm), [Olympus](#35-olympus), [OM System](#36-om-system),  [Panasonic](#37-panasonic), [Leica](#38-leica), [Hasselblad](#39-hasselblad), [Pentax](#310-pentax), [Ricoh](#311-ricoh), [Apple](#312-apple)

### [Status Messages and Warnings](Understanding-Focus-Results.md)

### [Compatibility](Compatibility.md)

* [Cameras that support display of autofocus points](Compatibility.md#cameras-that-support-display-of-autofocus-points)
* [Cameras that support Straighten Images](Compatibility.md#cameras-that-support-straighten-images)
* [Features not supported in earlier versions of Lightroom](Compatibility.md#features-not-supported-in-earlier-versions-of-lightroom)

### [Special Topics](#4-special-topics)

* [How to use a keyboard shortcut to run the plugin](#how-to-use-a-keyboard-shortcut-to-run-the-plugin)
* [How to reduce long wait times when opening the plugin window on Windows](#how-to-reduce-long-wait-times-when-opening-the-plugin-window-on-windows)
* [How to create a debug log file](#how-to-create-a-debug-log-file)

<br>

# 1. Scope and Limitations

Focus Points is a plugin for Adobe Lightroom Classic<sup>1</sup> on Windows and macOS. It allows you to:

- See which autofocus point was used when a photograph was taken<sup>2</sup>.
- Review user-selected autofocus points and areas<sup>3,4</sup>.
- Visualize faces and subjects detected by the camera<sup>3,5</sup>.
- Inspect and search image metadata, including camera-specific information.
- Rate, flag and label photographs directly within the plugin interface<sup>7</sup>.
- Straighten photographs using the camera's recorded roll angle<sup>3,6,7</sup>.

<sup>1</sup> Focus Points is compatible with Lightroom Classic, LR5.7 and LR6 perpetual licenses and LrC subscriptions.<br>
&nbsp;&nbsp;&nbsp;LR5.7 does not support tagging photos within the plugin UI or straightening images by applying compensation for camera roll angle.<br>
<sup>2</sup> For Canon, Nikon, Sony, Fujifilm, Olympus/OM, Panasonic, Leica, Pentax, Ricoh, Apple.<br>
&nbsp;&nbsp;&nbsp;Check the [list of supported cameras](Compatibility.md#cameras-that-support-display-of-autofocus-points) to see if your camera is supported.<br>
<sup>3</sup> Depending on the presence of metadata.<br> 
<sup>4</sup> Currently supported for Pentax and OM System.<br> 
<sup>5</sup> Currently supported for Fujifilm, OM System (subjects, faces) and Sony, Olympus, Pentax (faces).<br> 
<sup>6</sup> Currently supported for Canon, Nikon, Fujifilm, Olympus/OM, Panasonic, Leica, Pentax, Ricoh.<br>
<sup>7</sup> Not for LR5.<br>

Feature availability depends on the camera model and the information recorded in the image metadata. Not every camera supports every feature.

For a detailed overview, see the [camera compatibility list](Compatibility.md).

**If you are new to Focus Points, it is recommended that you read chapters 1 and 2, followed by the section in chapter 3 that applies to your camera.**
<br>
<br>

### Principle of operation

Focus Points uses [ExifTool](https://exiftool.org/) to retrieve metadata directly from image files. Autofocus-related information is extracted and processed to identify and visualize focus points, faces and subjects detected by the camera.

For this to work, the original image file (or a derivative that preserves the relevant metadata) must contain the camera manufacturer's proprietary metadata, commonly referred to as *MakerNotes*. These records contain camera-specific information that is essential for displaying autofocus information.

<u>Note:</u> ExifTool is part of the plugin package and does not need to be installed separately.

Although Focus Points operates within Lightroom Classic, it cannot retrieve camera-specific MakerNotes information from the Lightroom catalog. This information is generally not exposed through the Lightroom SDK.

When a photograph is sent to an external editor using Lightroom's *Edit In* command, Lightroom typically creates an intermediate JPEG or TIFF file. Such files generally do not retain the original camera-specific MakerNotes required for autofocus analysis.

Consequently, photographs returned from external editors may no longer contain the information needed to display focus points.

**Examples of image files for which focus point information is unavailable:**
- Photo edited in Photoshop and returned as PSD or TIF
- Photo transferred as TIFF/JPG to a 3rd party editor (`Photo → Edit In`) and returned as TIF,<br> e.g. Topaz, NIK, Photomatix
- DNG files created by Lightroom's Photo Merge (HDR, Panorama)
- Photos exported to disk that have been re-imported in Lightroom
- Smart Preview but the original image file is not present 

External applications launched from Lightroom that use the original RAW file as input (typically through the *Plug-in Extras* menu) may preserve the information required by Focus Points.

In this case, Lightroom passes the image file's path to the external application rather than creating and passing a new image file. If the application leaves the original MakerNotes intact, Focus Points can still access the required information.

<span id="supported-dng-files"></span>
**Examples of DNG files that may retain the required camera metadata:**

- DNG files converted from RAW by Adobe's DNG Converter (standalone app, or inside Lightroom)
- DNG files created by DxO PhotoLab, Luminar Neo, Topaz Photo AI
- DNG files created by Lightroom's Enhance feature, e.g. AI Denoise (prior to LrC 14.4)

Whether autofocus information is available depends on the camera model and the metadata preserved during conversion. For example, focus point information is not available in Fujifilm DNG files.

**Situations where focus point information may be misleading:**

* <u>[Focus and Recompose](Understanding-Focus-Results.md#focus-and-recompose)</u>: When you focus on your subject and then recompose by moving the camera, the recorded focus point generally reflects its original position when focus was acquired. It does not move with the subject during recomposition. 
* <u>[Back-Button Focus](Understanding-Focus-Results.md#back-button-focus-bbf)</u>: This is similar to Focus and Recompose because the underlying principle is the same. 

<br>

# 2. Overview and Basic Operation
This section will explain how to install, configure, and use the plugin.


## 2.1 Installation

### Quick Installation

1. Download the latest [Focus Points release](https://github.com/FocusPointsLrC/Focus-Points/releases/latest).

2. Extract the downloaded ZIP file. You will find a folder named `focuspoints.lrplugin`.

3. **New installation:** Move the `focuspoints.lrplugin` folder to a location of your choice.

   **Updating an existing installation:**
   - Close Lightroom Classic.
   - Remove or rename the existing `focuspoints.lrplugin` folder.
   - Move the new `focuspoints.lrplugin` folder to the same location.

4. Open Lightroom Classic and select `File → Plug-in Manager`.

5. Click `Add`, browse to the `focuspoints.lrplugin` folder and select it.<br>On Windows, click `Select Folder`; on macOS, click `Add Plug-in`.



### Detailed Instructions

1. Download the [latest release](https://github.com/FocusPointsLrC/Focus-Points/releases/latest) of the plugin package.<br>
A file named `Focus-Points-[plugin_version].zip` will be downloaded to your computer.


2. Unzip the downloaded file. Inside the extracted content locate the plugin folder `focuspoints.lrplugin`.<br>
On macOS, the ZIP file is usually extracted automatically, depending on your system settings.


3. Find the folder where you want to keep your Lightroom plugins.<br>
If you don't already have a dedicated folder for your plugins, you can use Lightroom Classic's default plug-in location:

   1. Open Lightroom Classic and go to `File → Plug-in Manager`.
   2. Click `Add`.

   The folder-selection dialog opens at Lightroom Classic's default plug-in location. You can use this location or navigate to another folder of your choice.<br>
   You can also create a separate folder for your Lightroom plugins, for example, `Documents\Lightroom Plugins` (Windows) or a folder in your user account on macOS.<br><br>

4. To **update an existing installation**, first remove or rename the folder containing the previous version of Focus Points. This must be done at the operating system level. Removing a plugin through Lightroom's Plug-in Manager only removes it from Lightroom's list of installed plugins; the actual files remain on disk.<br>
 Renaming the folder rather than deleting it allows you to revert to the previous version if the update causes problems.<br>
**Important:** Copying the downloaded files over those in the existing folder is not recommended!


5. Move the downloaded plugin folder `focuspoints.lrplugin` to the folder where you keep your Lightroom plugins.<br> 


6. Open Lightroom and go to `File → Plug-in Manager`.<br>
**New installation**:<br>
_Windows_: Click the `Add` button and select the plugin.<br>
_MAC_: In case of you'd copied the plugin to the default LR-plugin location, the new plugin is already listed - activate it. Otherwise, click on the `Add` button and select the plugin.<br>
**Update installation**:<br>
If Lightroom Classic was left running while the plugin files were replaced, select Focus Points in Plug-in Manager and click `Reload Plug-in`.


Once the plugin has been installed, choose one or more photos and select:

Library module:<br>
`Library → Plug-in Extras → Show Focus Point`

Develop module:<br>
`File → Plug-in Extras → Show Focus Point`

See [How to use a keyboard shortcut to run the plugin](#how-to-use-a-keyboard-shortcut-to-run-the-plugin) to learn how to invoke the plugin using a hotkey.

If you have never used Lightroom plugins before and are looking for some basic information, a video tutorial would be a good place to start. For example, [How to Install & Remove Lightroom Plug-ins (11:30)](https://www.youtube.com/watch?v=DFFA8nKBsJw). 

<br>

## 2.2 Focus Point Viewer
Once the plugin is installed, you can run it with one or more photos selected:

Library module:<br>
`Library → Plug-in Extras → Show Focus Point`

Develop module:<br>
`File → Plug-in Extras → Show Focus Point`

### User Interface

The Focus Point Viewer window is divided into three main areas:

- **Photo View (1)** on the left displays the photo with visualized autofocus points, detected faces and subjects, and other relevant information.
- **Info View (2+3)** on the right displays image, shooting and focus information that can help you evaluate the photo and its focus results.
- **Control Bar (4+5+6)** at the bottom provides controls for navigating between photos, flagging and rating images, and straightening them.

<img src="images/User%20Interface.jpg" alt="User Interface" style="width: 1000px;"/>

The window cannot be resized dynamically. However, you can customize its size using the [Size of plugin window](#size-of-plugin-window) setting or using `<` and `>` keyboard shortcuts. 

For more detailed information, see the following sections:

1. [Photo View](#photo-view)
2. [Info View](#info-view)
3. [User Messages](#user-messages)
3. [Plugin Status](#plugin-status)
4. [Navigation Controls](#navigation-controls)
5. [Flagging Controls](#flagging-controls)
6.  [Straightening Control](#straightening-control)
7. [Keyboard Shortcuts](#keyboard-shortcuts)
8. [Check the FAQ](#got-a-question-check-the-faq)
9. [Buy me a coffee](#buy-me-a-coffee)


### Photo View

The plugin uses different colors and shapes to visualize autofocus (AF) points, detected faces and subjects, and the camera's crop area. These elements are highlighted by markers displayed over the photo:<br>

<img src="images/BasicOperation1.jpg" alt="BasicOperation1" style="width: 1000px;"/>

The table below summarizes the elements the plugin can display and the corresponding marker shapes and colors. On Windows, markers are displayed as solid frames; on macOS, they are displayed using corner markers*.

|                                       MAC                                       |                                         WIN                                         |       Color       | Meaning                                                                               |
|:-------------------------------------------------------------------------------:|:-----------------------------------------------------------------------------------:|:-----------------:|---------------------------------------------------------------------------------------|
|    <img src="images/af_infocus.png" alt="infocus" style="width: 20px;"/>    |    <img src="images/af_infocus_win.png" alt="infocus" style="width: 20px;"/>    |  red<sup>1</sup>  | Active AF point — focus area, using the dimensions reported by the camera                        |
| <img src="images/af_infocusdot.png" alt="infocusdot" style="width: 20px;"/> | <img src="images/af_infocusdot_win.png" alt="infocusdot" style="width: 20px;"/> | red<sup>1,2</sup> | Active AF point — focus location<sup>3</sup>, using pixel coordinates reported by the camera |
|   <img src="images/af_selected.png" alt="selected" style="width: 29px;"/>   |   <img src="images/af_selected_win.png" alt="selected" style="width: 29px;"/>   |       white       | User-selected AF point                                                                |
|   <img src="images/af_inactive.png" alt="inactive" style="width: 20px;"/>   |   <img src="images/af_inactive_win.png" alt="inactive" style="width: 20px;"/>   |       gray        | Inactive AF point — part of the DSLR AF point array, but not used for the image<sup>3</sup>      |
|       <img src="images/af_face.png" alt="face" style="width: 20px;"/>       |       <img src="images/af_face_win.png" alt="face" style="width: 20px;"/>       |      yellow       | Face or subject detected by the camera                                  |
|       <img src="images/af_crop.png" alt="crop" style="width: 20px;"/>       |       <img src="images/af_crop_win.png" alt="crop" style="width: 20px;"/>       |       black       | Area of the image used by the camera in crop mode                           |

<sup>1</sup> The color of active AF points can be changed to red, green, or blue in [Viewing Options](#viewing-options).<br>
<sup>2</sup> The shape and size of focus-pixel markers can be configured in [Viewing Options](#viewing-options).<br>
<sup>3</sup>  The meaning may vary depending on the camera manufacturer. See the camera-specific chapters for details.


\* *Technical note:* Windows and macOS use different methods to render overlays, which is why the display of focus points and other elements differs between the two platforms. On macOS, markers for focus points, face and subject detection, and crop areas are displayed using corner markers. On Windows, all markers are displayed as solid frames.

This difference is due to limitations of the Lightroom SDK: its overlay methods work on macOS but not on Windows. On Windows, the plugin uses ImageMagick (`mogrify`) to draw the markers.

Providing the same rendering method on both platforms, ideally with a user-selectable option, is planned for V4. However, this depends on an Adobe fix and on finding a practical way to integrate ImageMagick into the macOS version. Both aspects are still being investigated. 


### Info View

The text pane to the right of the Photo View is divided into three sections:

- Image Information
- Shooting Information
- Focus Information

Image Information and Shooting Information are largely based on data from the Lightroom catalog and are therefore generally available for every photo. Depending on the information available in the camera's MakerNotes, these sections may also include various camera-specific details, such as crop mode, drive mode, shot number, etc. This information can be useful when evaluating focus results.

Focus Information is only available if the original image file contains the metadata required by the plugin. See [Scope and Limitations](#1-scope-and-limitations) for more details.

Two buttons at the bottom of the window allow you to move forward and backward through the selected photos. These buttons are inactive if the plugin was launched with only one photo selected in Lightroom.

A link to this User Manual provides quick access to the operating instructions.

You can close the window by clicking `Exit` or pressing `Enter`, `Esc`, or `Space`.

#### Focus Distance, Depth of Field, Hyperfocal Distance

Most camera makers include subject or focus distance information in their MakerNotes. Sony, Fujifilm, and Pentax do not, so this section is not relevant for photos taken with their cameras.

ExifTool uses the focus distance information to calculate the depth of field (DoF). This can help you assess whether the lens was stopped down sufficiently to capture the desired portion of the subject acceptably sharply—that is, whether it is within the zone of focus.

ExifTool also calculates the hyperfocal distance. This can help you determine whether the autofocus was set to the appropriate distance for photos that should be sharp from front to back, such as landscapes.

Note that focus distance values are not highly accurate. Cameras are not designed to measure distances. The values recorded in the EXIF data are byproducts of the focusing process, derived from control information used to move the lens to a certain distance. The number of focus steps can be translated into an approximate distance, but the accuracy—and therefore the usefulness—of this information depends on several factors.

Typically, focus distance values are less accurate at short focal lengths. They are also likely to be inaccurate under extreme conditions, such as macro photography or focusing at infinity. The equipment itself also plays a role.

**Technical note:** ExifTool creates the pseudo tags `DepthOfField` and `HyperfocalDistance`, which can be seen in the ExifTool output. For its DoF calculation, it uses the standard circle of confusion value for the respective sensor. In this context, the term “sharpness” refers to the ability of the human eye to recognize and resolve details when an image is viewed at full size, i.e., not enlarged. This is also known as “pixel peeping”.

<img src="images/BasicOperation5.jpg" alt="Basic Operation 5" style="width: 1000px;"/>

Example: The DoF in this capture is only about 2 cm. With the chosen aperture of f/1.8, the eyes will therefore be outside the zone of sharpness if the shot is focused on the front whiskers.



### User Messages

The first line of text in the `Focus Information` section contains a message summarizing whether the plugin was successful in its task to detect and visualize focus points. This can be a success message (in green letters), a warning (orange) or an error message (red):

|  Type   | Message                                                                                                       |
|:-------:|---------------------------------------------------------------------------------------------------------------|
| Success | Focus points detected                                                                                         |
| Warning | [No focus points recorded](Troubleshooting_FAQ.md#no-focus-points-recorded)                                   |
| Warning | [Focus point recorded in manual focus mode](Troubleshooting_FAQ.md#focus-point-recorded-in-manual-focus-mode) |
| Warning | [Manual focus, no AF points recorded](Troubleshooting_FAQ.md#manual-focus-no-af-points-recorded)              |
|  Error  | [Focus info missing from file](Troubleshooting_FAQ.md#focus-info-missing-from-file)                           |
|  Error  | [Camera model not supported](Troubleshooting_FAQ.md#camera-model-not-supported)                               |
|  Error  | [Camera maker not supported](Troubleshooting_FAQ.md#camera-maker-not-supported)                               |
|  Error  | [No camera-specific metadata found](Troubleshooting_FAQ.md#no-camera-specific-metadata-found)                 |
|  Error  | [Severe error encountered](Troubleshooting_FAQ.md#severe-error-encountered)                                   |




Click on the message to learn what it means and how to deal with it in case of an error or warning.

You can also access this information from the plugin window by clicking the link icon 🔗 next to the message:

<img src="images/BasicOperation6.jpg" alt="BasicOperation6" style="width: 850px;"/>


### Plugin Status

If errors or warnings were encountered while processing the autofocus metadata, a status message is displayed at the bottom of the text pane. You can click the `Check log` button to open the log file for more details. The log file contains detailed information about the metadata processing, such as relevant tags that were found or not found.<br>
See [Logging](#logging) how to set up and customize logging. 

For the image above, where the focus information is reported as "missing from file," the log file looks like this:

<img src="images/BasicOperation3.jpg" alt="BasicOperation3" style="width: 750px;"/>

There are two warnings and one error:
The tag `CameraSettingsVersion` has not been found which means that this file does not contain a makernotes section with AF information (which is required for the plugin to work). The image file was not created in-camera but by an application. In this case, it is a JPG file exported from (and created! by) Lightroom.


### Navigation Controls

Use the `Next image` and `Previous image` buttons to scroll through the photos.

In Lightroom, if only one photo is selected in the filmstrip, `Next image` will advance to the next photo in the _filmstrip_, and `Previous image` will advance to the previous photo in the _filmstrip_. There is no wrap-around when the beginning or end of the film strip is reached.

To run the plugin on a specific series of photos, select those photos in Lightroom _before_ running the plugin. In this case, `Next image` will advance to the next photo in the selection, and `Previous image` will advance to the previous photo in the selection. A wrap-around occurs when the beginning or end of the film strip is reached.


<u>Note</u>: _Filmstrip_ navigation uses the 'LrSelection' namespace, which is only available in SDK version 6.0 and above. Therefore, this feature is not available on LR5.7.

### Flagging Controls

Users for whom focus point accuracy is critical when selecting shots now have the ability to flag, reject, rate or color images directly within the plugin. The user interface has been updated to include the relevant controls: 


<img src="images/README TaggingControlsWIN.jpg" alt="Screenshot" style="width: 800px;"/> Windows

<img src="images/README TaggingControlsMAC.jpg" alt="Screenshot" style="width: 800px;"/> macOS

Tagging can be performed using the same logic and [keyboard shortcuts](#keyboard-shortcuts) as in Lightroom. Pressing the Shift key during tagging moves the plugin to the next photo.

**Notes / Restrictions:**

- Although the plugin allows you to set the flag status, rating and color label of a photo, these changes are **not** reflected in the plugin's user interface. Any changes to the flag status, rating or color will be acknowledged immediately with a standard message in Lightroom, and these changes will be reflected in the filmstrip for the selected photo. **It is recommended that you adjust the sizes of the plugin window and Lightroom's filmstrip when using tagging, so that both are visible at the same time.**

- Use of `Shift` + `0`-`9` keyboard shortcuts require that the plugin is aware which international keyboard layout is currently used. This is necessary because the plugin cannot recognize key codes; it can only work with text input. See [Keyboard Shortcuts](#keyboard-shortcuts).<br>
The keyboard layout in use can be configured in the plugin settings, under the `User Interface`' section, [Keyboard Layout](#keyboard-layout) setting.
  
- The LR SDK does not support clickable images, so all control elements must be text or text buttons. As the plugin UI displays all Unicode 'star symbol' characters as small, hardly recognizable stars, the rating controls are represented by numbers 1–5 instead.

- The display of tagging controls and related keyboard shortcut operation can be disabled in the plugin settings, under section `User Interface`.

- Note: Tagging features use the 'LrSelection' namespace, which is only available in SDK version 6.0 and above. Therefore, these features is not available on LR5.7 (which is still in use by a few plugin users!).


### Straightening Control

You can level the image currently displayed in the Focus Point Viewer. You can immediately review the result and undo the operation if necessary. This is the interactive counterpart of the batch ['Straighten Images'](#24-straighten-images) function. The same options and restrictions apply.

**How the Straighten Control Works**

1. Images supported by this feature have two relevant angle values associated with them:  
   - Roll Angle – the horizontal tilt of the camera at the time the image was captured.
   - Crop Angle – the rotation angle currently applied to the image in Lightroom.

2. Both angles are measured in degrees. A negative value indicates rotation to the left, while a positive value indicates rotation to the right.

3. If the camera was tilted by x° when the image was captured, applying a Crop Angle of −x° compensates for that tilt and displays the image as if the camera had been held level. 

4. When Roll Angle and Crop Angle do not balance each other, the values are shown in red. In this state, the `Straighten` button rotates the image by the opposite of the Roll Angle, resulting in a level image.

5. When Roll Angle and Crop Angle are balanced, i.e., their values cancel each other, their values are highlighted in green. In this state, the `Straighten` button changes to `Reset`. Clicking `Reset` restores the crop settings that were in effect before the image was straightened.<br><br>


**Example: Straighten a photo that was not taken level**  

The user opens a photo in the Focus Point Viewer. The red text displayed in the 'Straighten' control indicates that the roll and crop angles are not balanced. This means that the image was not taken level and the tilt has not been corrected. The `Straighten` button can be used to rotate the image resulting in a level image:

<img src="images/Straighten Control 1.jpg" alt="Straighten Control 1" style="width: 1000px;"/>

The result of the straightening process is displayed in a refreshed window. The text is now displayed in green, indicating that Roll Angle and Crop Angle are balanced. The image is now level:

<img src="images/Straighten Control 2.jpg" alt="Straighten Control 2" style="width: 1000px;"/>

If the result is not satisfactory, it can be undone using the `Reset` button, which returns the image to its original state.

The performed edits are recorded in Lightroom's History panel:

<img src="images/Straighten Control 3.jpg" alt="Straighten Control 3" style="width: 600px;"/><br><br>

**Example: Straighten a photo with `Upright Level` setting already applied**  

Lightroom provides various options for 'straightening' a photo. To automatically straighten a photo with respect to a horizontal tilt, apply the `Upright Level` option. This can be done either individually or during import. 

While this works quite well for photos with clear reference points representing the horizon, it can produce unexpected results for photos lacking these.

The `Upright Level` tool was applied to this photo of a bird on a pole, attempting to straighten it: 

<img src="images/Straighten Control 4.jpg" alt="Straighten Control 4" style="width: 1000px;"/>

The text `Transform` right next to the `Crop` angle indicates that `Transform` settings have been applied to this photo. A `Transform` setting can be one of the six Upright tools, or any of the individual `Transform` settings below: 

<img src="images/Straighten Control 9.jpg" alt="Straighten Control 9"/>

Clearly, the `Upright Level` result is not satisfactory. The tool used the fence wire as a reference, even though it is not one.  
Can Focus Point Viewer's Straighten tool do a better job?

<img src="images/Straighten Control 5.jpg" alt="Straighten Control 5" style="width: 1000px;"/>

After pressing the `Straighten` button, a warning will appear asking you to confirm whether you want to overwrite the existing `Transform` settings. These settings will not be permanently deleted, but can be restored via the `Reset` button if desired.  

<img src="images/Straighten Control 6.jpg" alt="Straighten Control 6" style="width: 1000px;"/>

Applying a roll angle compensation to straighten this image gives a much better result compared to using Lightroom's Upright tool. The History panel provides a detailed list of the steps taken to straighten the image, and allows you to undo this change by selecting `Reset`. 

<img src="images/Straighten Control 7.jpg" alt="Straighten Control 7"/><br><br>


**Example: Roll Angle information is not present in metadata**

For images that cannot be straightened because Roll Angle information is unavailable, the text is displayed in black and the control is disabled. Hovering the mouse pointer over the text displays a tooltip explaining the reason (e.g. unsupported camera model or missing Roll Angle information).

<img src="images/Straighten Control 8.jpg" alt="Straighten Control 8" style="width: 1000px;"/>
<br><br>

### Keyboard Shortcuts

To simplify operation of the plugin, keyboard shortcuts are supported. These shortcuts can be used to perform all actions associated with the user interface, meaning you can operate the plugin entirely with the keyboard and never need to touch the mouse.

| Action                                      | Keyboard shortcuts |
|---------------------------------------------|--------------------|
| **Navigation**                              | &nbsp;             | 
| Previous image                              | `-`                |
| Next image                                  | `+`, `Spacebar`    |
| **Flagging**                                | &nbsp;             |
| Flag photo as a pick                        | `P`                |
| Flag photo as a pick and go to next photo   | `Shift`+`P`        |
| Flag photo as a reject                      | `X`                |
| Flag photo as a reject and go to next photo | `Shift`+`X`        |
| Unflag photo                                | `U`                |
| Unflag photo and go to next photo           | `Shift`+`U`        |
| **Rating**                                  | &nbsp;             |
| Set star rating                             | `1`-`5`            |
| Set star rating and go to next photo        | `Shift`+`1`-`5`    |
| **Color**                                   | &nbsp;             |
| Assign a red label                          | `6`                |
| Assign a yellow label                       | `7`                |
| Assign a green label                        | `8`                |
| Assign a blue label                         | `9`                |
| Assign a color label and go to next photo   | `Shift`+`6`-`9`    |
| **Straighten**                              | &nbsp;             |
| Straighten image                            | `S`                |
| Reset crop (Undo straightening)             | `R`                |
| **Screen Modes (V4 only)**                  | &nbsp;             |
| Direct View                                 | `D`                |
| Preview Image                               | `V`                |
| Export Image                                | `E`                | 
| **Miscellaneous**                           | &nbsp;             |
| Downsize Window by one size                 | `<`                |
| Upsize Window by one size                   | `>`                |
| Open User Manual                            | `M`                |
| Open Frequently Asked Questions (FAQ)       | `H`                |
| Understanding Focus Results                 | `?`, `F`           |
| Check Log                                   | `L`                |
| Close                                       | `C `               |


#### IMPORTANT Technical Note on keyboard shortcuts: 

The Lightroom SDK does not support the native handling of keyboard events in modal dialogs, so the plugin uses a "trick" to implement keyboard shortcuts. This approach has certain limitations, which are described here for a better understanding.

Due to limitations in the LR SDK, the plugin can only work with text input and cannot recognize key codes. Keyboard shortcuts entered by the user, such as 'P' for 'Set as Pick' or '+' for 'Next Image', are collected as text in a designated input field. If the character entered corresponds to a defined shortcut, the related action is performed. 

**Arrow keys, Function keys, Esc, Return, etc. do not change text input, so the choice of hotkeys is limited to text (i.e. printable ASCII characters).**

This approach is effective as long as the keyboard focus remains on the input field.

In Windows, only pressing the Tab key or clicking on the photo will remove the focus from the input field. As a result, further keyboard input will not be recognized. Mouse operation does not remove the focus.

On macOS, clicking on any control (such as a button, link or tagging icon) removes the focus from the input field. Given the large number of different controls, it is difficult to perform operations using keyboard shortcuts and the mouse simultaneously on the same image.

By default, the input field is visible to indicate when it has lost focus. To continue working with keyboard shortcuts, you need to click the field again.

You can configure the size of the text input field, including the labeling, in the [plugin settings](#text-input-field-for-keyboard-shortcuts).


### Got a question? Check the FAQ!

If you have a question or encounter an issue while working with Focus Point Viewer, you can access the [Frequently Asked Questions (FAQs)](V4-FAQ.md) to find an answer with a single click.

### Buy me a coffee
Several of you have asked how you can show your appreciation for the work I have done to significantly improve the plugin over the past year and months. If you care about this issue, you can now show your [support via Ko-fi](https://ko-fi.com/focuspoints)*. Simply click the link next to the coffee cup.

*Ko-fi is a well-established service that enables users to support creators through voluntary donations.
Payments are processed securely via PayPal or credit/debit card, and no account or subscription is required.

<br>                               

## 2.3 Metadata Viewer

The Metadata Viewer enables you to interactively explore all the information recorded by the camera when the picture was taken. This goes far beyond what Lightroom or even the Focus Point Viewer covers. In short, it contains all the information that ExifTool knows.

Library Module:<br>
`Library → Plug-in Extras → Show Metadata`

Develop Module:<br>
`File → Plug-in Extras → Show Metadata`

Metadata can be filtered by group, key or value search terms. The filter accepts pattern matching with the well-known "magic characters":

 | Char  | Meaning                                        |
 |:-----:|------------------------------------------------|
 |   .   | any character                                  |
 |   +   | one or more repetitions of previous character  |
 |   *   | zero or more repetitions of previous character |
 |   ^   | start of string                                |
 |   $   | end of string                                  |

Note:
The plugin is written in the Lua programming language and uses Lua string.find() for filtering. This function supports "Lua patterns", so you can use even more [sophisticated pattern matching](https://www.lua.org/pil/20.2.html). However, for filtering a simple EXIF data output, basic pattern matching should be more than sufficient.

For further processing as text, the full metadata (retrieved via 'exiftool -a -u -sort <file>') can also be opened in a text editor.

Let's look at an example how to use it - a shot of a White-tailed Eagle: 

<img src="images/metadata1.jpg" alt="Metadata 1" style="width: 1000px;"/>

I can still remember that, when I took the shot, the eagle was quite close by and not flying very high. But I want to know exactly what the heigth was.

My OM-1 camera records the roll and pitch angles, which define the tilt of the camera in the horizontal and vertical planes. We are looking for the pitch angle. We can either scroll through the entire list of metadata and search for the relevant tag:

<img src="images/metadata2.jpg" alt="Metadata 2" style="width: 800px;"/>

Or we filter the list by showing only tags than contain 'angle'

<img src="images/metadata3.jpg" alt="Metadata 3" style="width: 800px;"/>

The pitch angle is 4.1°, which means that it's height was approximately 50m * sin(4.1°) ~ 3.60m. Quite close for such a majestic bird!

<br>

## 2.4 Straighten Images

To straighten a selection of photos in **batch mode**, run

Library Module:<br>
`Library → Plug-in Extras → Straighten Images`

Develop Module:<br>
`File → Plug-in Extras → Straighten Images`

This function reads the camera's roll angle from the metadata of selected photos one by one and applies the corresponding crop rotation to compensate for the camera's tilt.

Manually straightening individual images is not difficult, and Lightroom also supports automatic straightening using the `Transform` tool. However, Straighten Images is particularly useful for straightening a series of photos taken in burst mode, such as wildlife, sports or action shots. This is particularly useful when the scene lacks clear horizontal or vertical reference lines for you—or Lightroom's `Upright` tool—to use when straightening the image.

As this function relies on the presence of the `RollAngle` tag in metadata, its application is limited to [certain cameras that record this information](Compatibility.md#cameras-that-support-straighten-images).

**Note:** The Straighten Images feature is not available for LR5, since version 5.x of the Lightroom SDK does not yet support the required functionality.


### Example

The photo has a roll angle of 2.5°. Applying a crop angle of −2.5° compensates for the tilt. Please note that a non-zero crop angle will change the crop of the photo. Straightening the photo will result in the corners being lost.

Using the Straighten Images tool produces the same result as entering the roll angle compensation manually in Lightroom's 'Crop & Straighten' tool. You can then modify or even revert the compensation as desired.

<img src="images/Straighten%201.jpg" alt="User Interface" style="width: 1000px;"/>


### Operation

To use Straighten Images, select the photos you want to straighten and open Plug-in Extras > Straighten Images.

The plugin then processes all the selected photos, retrieving `RollAngle` information from their metadata if available, and applies the relevant correction by adjusting the crop angle of each photo. The standard progress bar in the top-left corner of Lightroom shows the progress of the operation. You can interrupt the process by clicking the 'x' icon to the right of the progress bar.

<img src="images/Straighten%202.jpg" alt="User Interface" style="width: 1000px;"/>

By default, the plugin notifies you of successful completion of the process with a 'bezel' — a brief pop-up window — upon completion.

<img src="images/Straighten%203.jpg" alt="User Interface" style="width: 1000px;"/>

If any of the selected photos cannot be straightened, a dialog will provide a summary. You can configure the conditions that trigger this window.

<img src="images/Straighten%204.jpg" alt="User Interface" style="width: 1000px;"/>

If you need more detailed information, click `See details` to open the log file:

<img src="images/Straighten%205.jpg" alt="User Interface" style="width: 1000px;"/>


### Customization

Various options allow you to customize and fine-tune the process of Straighten Images:

<img src="images/Straighten%206.jpg" alt="User Interface"/>

For a detailed explanation of these settings, see [Straightening Options](#straightening-options)


### Keyboard Shortcut

The FocusPointsHotkey script files and precompiled executables have been extended by a third keyboard shortcut `Ctrl NumpadSub`.


### General Remarks

The quality of the result of straightening depends essentially on two factors:

- Precision of roll angle measurement by the camera
- Accuracy of the camera's level gauge adjustment

The benefits of straightening photos of man-made structures can be limited. In such cases, accurate leveling is often required, as well as compensation for vertical tilt.

Conversely, the Straighten Images feature is extremely useful for genres such as nature, wildlife, sports and action photography. It is not uncommon to find that there is no clear reference information to help you straighten images manually. This feature is also useful for burst shoots, such as photographing birds in flight, when it is easy to tilt the camera while tracking your subject.

The plugin generally produces better and more reliable level correction results than Lightroom's `Upright` tool. This is because it responds directly to horizontal camera imbalance. `Upright` looks for straight lines in a photo and uses them as a reference point to straighten the image. However, if there are structures in an image that are not actually straight, the result will be incorrect.

Lightroom `Upright Level`:
<img src="images/Straighten%207.jpg" alt="User Interface" style="width: 1000px;"/>

Focus Point Viewer's Straighten Images function:
<img src="images/Straighten%208.jpg" alt="User Interface" style="width: 1000px;"/>

<br>

## 2.5 Configuration and Settings

Selecting 'Focus Point Viewer' from the list of installed plugins (`Library → File → Plug-in Manager`) opens the plugin's settings page:

<img src="images/Plugin Options.jpg" alt="Plugin Options" style="width: 750px;"/>

The plugin settings are organized into sections. If you are unsure about the meaning of a particular setting or group of settings, click the `[?]` symbol to view its description in this manual. If `[?]` is located near the  border of the settings window, it represents a group of settings; otherwise, it refers to a single setting. 


### Screen Scaling

 **_Display scale factor_**. Windows only. Default setting: `Auto`

The drawing routines used on Windows are not aware of any display scale factor that may have been applied to the Windows configuration (_Settings → Display → Scale_). In order to avoid that the plugin window gets bigger than the screen size, the plugin has to reverse this scaling when calculating the size of the dialog window.

 The `Auto` setting causes the plugin to scale its windows in sync with a system scale factor. Optionally, a predefined fixed scale value can be selected, which avoids a registry access via an external command (REG.EXE) on each call of the plugin. The meaning of the predefined values 100%, 125%, 150%, etc. is the same as in the Windows Settings dialog. I.e. to undo a system-wide zoom of 150%, the same value '150%' must be selected from the drop-down list.


### User Interface Settings

This section is new in version 3.2. It contains several settings that can be used to customize the appearance and functionality of the plugin's user interface.

<span id="size-of-plugin-window"></span>
**_Size of plugin window_**. Default setting: `L`<br>
This setting allows you to customize the size of the plugin window. You can choose from six options ranging from 3XL to S. 

<img src="images/README WindowSize.jpg" alt="Screenshot" style="width: 600px;"/>

In the Focus Point dialog, this setting corresponds to 90% (3XL) to 40% (S), in increments of 10%, of the size of the Lightroom application window used to display the photo. Please note that the text pane to the right of the photo and the bottom row of user controls are not included in this percentage.

In the Metadata Viewer, this setting determines the height of the dialog. The width is determined by the header line, which includes the two filter entry fields and the hint text. 

<u>Note</u>: Windows users already had the option to adjust the size of the focus points window using the screen scaling option specific to Windows. This setting remains as it is.

<span id="text-input-field-for-keyboard-shortcuts"></span>
**_Appearance of text input field for keyboard shortcuts_**. Default setting: `Regular`<br>
To make keyboard shortcuts more transparent and intuitive to use, the text input field that captures them is now visible by default. For a more detailed explanation, see xxx.
This setting can be used to customize the appearance of the input field:

<img src="images/README%20TextInputSetting.jpg" alt="Screenshot" style="width: 600px;"/>

- Invisible. This is self-explaining
- Small. A narrow input field without labeling
- Regular. An input field that can display a minimum of 10 characters, along with a label containing a link to the 'Keyboard Shortcuts' section of the user manual.

<span id="truncate-or-wrap-long-strings"></span>
**_Truncate or wrap long strings_**. Default setting: `On`, `32` characters<br>
This setting enables you to specify whether long strings, such as metadata values or file names, should be truncated in the display. You can choose the truncation limit, which can be set between 10 and 100 characters. A truncated string is marked with the symbol '...' at the end. The full text can be seen in the tooltip that appears when you hover over a truncated string with the mouse.

<span id="enable-controls-for-straightening"></span>
**_Enable controls for straightening_**. Default setting: `On`<br>
If you don't need the controls for straightening photos in the Focus Point viewer, and you want to avoid overloading the navigation bar, use this setting to hide the straightening controls and disable the related keyboard shortcuts. 

<span id="enable-controls-for-tagging"></span>
**_Enable controls for tagging_**. Default setting: `On`<br>
If you don't need the controls for flagging, rating or coloring photos in the Focus Point viewer, and you want to avoid overloading the navigation bar, use this setting to hide the tagging controls and disable the related keyboard shortcuts. 

<span id="keyboard-layout"></span>
**_Keyboard layout_**. Default setting: empty<br>
The keyboard shortcuts for flagging, rating and coloring are the same as those used in Lightroom, including the `Shift` combinations that perform an action and advance to the next photo. Since the plugin cannot recognize key codes and can only work with text input, using the `Shift` + `0`-`9` keyboard shortcuts requires the plugin to be aware of the currently used international keyboard layout.<br>
The predefined options cover a large percentage of the available layouts, and more can be added on request. In this specific context, it is important to note that the term 'layout' refers only to the codes produced by the `0`–`9` keys in the top row, and not to the entire keyboard.
<br><br>
<img src="images/README KeyboardLayoutSettings.jpg" alt="Screenshot" style="width: 600px;"/>
<br>

**_Preview Image_**<br>
These two settings determine how the image displayed by the Focus Point Viewer (i.e. the photo with markings overlaid) is produced on a Windows PC. Generating a preview image can significantly impact the time taken to open the plugin window. Tweaking these settings can optimize the time required for preview generation.

See [How to reduce long wait times when opening the plugin window on Windows](#how-to-reduce-long-wait-times-when-opening-the-plugin-window-on-windows) for a detailed explanation of the settings and the context in which they are used.


### Viewing Options

<span id="size-of-focus box"></span>
**_Size of focus box for 'focus pixel' points_**. Default setting: `Red`<br>
Depending on the camera maker and model, focus points may have a dimension (width and height) or they may be represented by a 'focus pixel'. For focus points that have a dimension, a box with the specified width and height is displayed. For 'focus pixel' points you can choose how to display them: small box or medium/large with a center dot.

**_Color of in-focus points_**. Default setting: `Medium`<br> You can choose between three different colors for the presentation of focus point boxes: red, green and blue.

### Logging

**_Level of information to be logged_**. Default setting: `Auto`

Logging involves recording the events and messages produced by the plugin while it is running. You can think of the log as a digital journal or 'black box flight recorder' — it keeps a detailed, chronologically ordered record of what happened, when it happened and the state that the plugin was in.

The logging feature in Focus Point Viewer is used for various purposes:

1. Provide additional information to explain error messages and warnings in more detail, for instance:<br>
   - why focus points cannot be displayed for a photo
     * [No focus points recorded](Troubleshooting_FAQ.md#no-focus-points-recorded)
     * [Focus info missing from file](Troubleshooting_FAQ.md#focus-info-missing-from-file)
   - when [straightening images in batch mode](#24-straighten-images)

   ⇒ Recommended logging level: `Auto`

2. Provide details on the time it takes to open the dialog. You can use this information to tweak settings that [control preview image generation](#how-to-reduce-long-wait-times-when-opening-the-plugin-window-on-windows)<br>
   ⇒ Recommended logging level: `Auto` or `Info`
 
3. Gather information to help the developer figure out what went wrong if the plugin does not work as expected:
   - [Severe error encountered](Troubleshooting_FAQ.md#severe-error-encountered)
   - the plugin reports an unexpected error
   
   ⇒ Recommended logging level: `Debug`
   
Log messages are categorized by log level (severity). Selecting a logging level causes messages at that level and at higher severity levels to be written to the log file. The available levels, from lowest to highest, are:

   | Level     | Information logged                                                              |
   |-----------|---------------------------------------------------------------------------------|
   | None      | No logging output. No log file created.                                         |
   | Error     | Error messages.                                                                 |
   | Warning   | Errors + warnings                                                               |
   | Info      | Errors + warnings + information on progress and intermediate results            |
   | Debug     | Errors + warnings + information + debug information. No noticeable slowdown.    |
   | Full      | Full debug information, including complete EXIF data. May slow down the plugin. |
   | Auto*     | Same as 'Info'. Recommended setting. No noticeable slowdown.                    |

\* * With `Auto`, logging starts with an empty log file for each image. Therefore, the log file will contain information only for the current or most recently processed photo. With all other logging levels, the log file is emptied when the plugin starts executing.

With `Auto`, the `Check log` button is displayed only if errors or warnings occurred:

<img src="images/Logging%20-%20Errors%20encountered.jpg" alt="User Interface"/> <img src="images/Logging%20-%20Warnings%20encountered.jpg" alt="User Interface"/>

For all other logging levels, the `Check log` button is always displayed:

<img src="images/Logging%20-%20Information%20collected.jpg" alt="User Interface"/>

The log file is named `FocusPoints.log` and is located in Lightroom's `LrClassicLogs` folder. You can open the file directly in an application associated with `.log` files (e.g. a text editor) by clicking the `Check log` button.  

Alternatively, you can locate the file in the plugin settings. Clicking the `Show file` button will open an Explorer or Finder dialog with the file selected: 

<img src="images/Logging%20-%20Plugin%20log.jpg" alt="User Interface"/>

<br>

### Straightening Options

These settings control how [Straighten Images](#24-straighten-images) operates:

<img src="images/Settings%20-%20Straightening%20Options.jpg" alt="User Interface"/>

**_Overwrite existing crop angle setting_**. Default setting: `Off`<br>
Roll angle compensation will be applied, even if the photo has already been rotated using Lightroom's Crop & Straighten tool. The straightening angle replaces the rotation (crop) angle rather than being added to it. If `Display warning` is selected, a dialogue box will appear in interactive mode to confirm the overwrite.

**_Overwrite existing `Transform` settings_**. Default setting: `Off`<br>
Roll angle compensation will be applied, even if the photo has `Transform` settings, such as `Upright`, applied. If `Display warning` is selected, a dialogue box will appear in interactive mode to confirm the overwrite.

**_Apply straightening only for angles between x and y_**. Default setting: `Off`<br>
Roll angle compensation will only be applied for angles within the range of x to y degrees.  
You can use this option to define a threshold to prevent small, often invisible, corrections from triggering Lightroom cropping. You can also set an upper limit for straightening angles. For example, if a photo has been taken with the camera tilted 25° horizontally, this is likely to be a deliberate creative choice rather than an unintended tilt. The lower and upper limits apply to both camera directions. (In Lightroom's Crop & Straighten tool, positive values rotate the image clockwise and negative values rotate it counterclockwise).
  
Example:  
Applying straightening only for angles between 0.2° and 10° means that no straightening (and cropping) will occur for angles between -0.2° and 0.2°, or for angles outside the range of -10° to 10°.  

**_Apply calibration offset_**. Default setting: `Off`<br>
If you are straightening photos captured using an improperly calibrated level gauge, you can specify a calibration offset in degrees here. This offset will be added to the roll angle compensation to compensate for the incorrect calibration of the level gauge. 

**_Condition to open the summary dialog when straightening is complete_**. Default setting: `Skipped Images`<br>
Select the minimum severity level that opens the summary dialog at the end of the straightening process. The dropdown list shows the available conditions in ascending order of criticality.

Example:  
The default setting, 'Skipped Images', will trigger the summary to show for skipped images, as well as warnings and errors that occurred during the process. Selecting the 'Errors' setting will only show the summary for errors that occurred, but not for warnings or skipped images.


### Update Check

The plugin checks for an updated version that is available to download.
If so, this will be highlighted, and you can click the `Open URL` button to access the latest version's release notice. Follow the [installation instructions](#21-installation) to install the update.

The availability of an update will be indicated:
- on the plugin's settings page (see above)
- in the 'Plug-in status' section of the text pane (provided the `Display message` checkbox is selected)
- in the log file

<img src="images/UpdateAvailable1.jpg" alt="Update Available" style="width: 1000px;"/><br>

<img src="images/UpdateAvailable2.jpg" alt="Update Available" style="width: 1000px;"/>


<br>

# 3. Display of Focus Points
The subchapters in this section describe in more detail which features are supported by the plugin for individual camera makers and specific lines or models. In this context, "feature" means visualization of:

* User-selected focus points/areas
* Focus point(s) used by the camera to produce a sharp image
* Detected faces
* Detected subjects (animals, airplanes, cars, trains, etc.)
* Inactive AF points (to visualize the complete AF layout of DSLRs)

The plugin uses different colors to visualize these elements (see [User Interface](#user-interface)).

The extent to which these features can be supported for a given camera model ultimately depends on a) the availability of the corresponding data in the EXIF makernotes and b) the fact whether this information is known to ExifTool.

Even if certain data is recorded by a camera manufacturer, this does not mean that it is "available". _Makernotes_ is a proprietary metadata section that contains manufacturer-specific information that is not standardized across different brands. Camera makers can use this information to diagnose camera issues, for instance.

The Focus Points plugin fully relies on what [ExifTool](https://exiftool.org/) is able to decode and display. Which in turn doesn't fall from the sky, but it's a collaborative effort by camera owners worlwide that are willing to contribute and [go where no man has gone before](https://exiftool.org/#boldly) and decode the unknown.


## 3.1 Canon

Supported features:

|                                     MAC                                     |                                       WIN                                       |      Color      | Meaning                                                              |
|:---------------------------------------------------------------------------:|:-------------------------------------------------------------------------------:|:---------------:|----------------------------------------------------------------------|
|  <img src="images/af_infocus.png" alt="infocus" style="width: 20px;"/>      |  <img src="images/af_infocus_win.png" alt="infocus" style="width: 20px;"/>      | red<sup>1</sup> | Active AF point. Focus area, dimensions reported by the camera       |
|   <img src="images/af_selected.png" alt="selected" style="width: 29px;"/>   |   <img src="images/af_selected_win.png" alt="selected" style="width: 29px;"/>   |       white     | User-selected AF point<sup>2</sup>                                                |
|       <img src="images/af_face.png" alt="face" style="width: 20px;"/>       |       <img src="images/af_face_win.png" alt="face" style="width: 20px;"/>       |      yellow     | Subject part detected and tracked by the camera (Mirrorless)                             |
| <img src="images/af_inactive.png" alt="inactive" style="width: 20px;"/>     | <img src="images/af_inactive_win.png" alt="inactive" style="width: 20px;"/>     |      gray       | Inactive AF point. Part of DSLR AF points but not used for the image |

<sup>1</sup> Active AF point color can be chosen from red, green, blue in [Viewing Options](#viewing-options).<br>
<sup>2</sup> User-selected AF point will be displayed for shots taken with Back-Button Focus (BBF)

Canon focus point information in EXIF metadata always refers to an area within the frame. Focus point areas are specified by their coordinates (x,y, height, width). Therefore, for Canon focus points, you can select the color of the box, but not the size.

Canon metadata does not include face or subject detection details, so you won't see any detection frames. This does not mean that this information is not present in the file - it just has not yet been decoded by the maintainers and active supporters of ExifTool.

Unlike other manufacturers, Canon does not give a single value for the focus distance, but rather a pair of values for the lower and upper range.

### 3.1.1 Canon DSLR

Like Nikon, Canon DSLRs support both PDAF and CAF. The position and size of the PDAF focus points are determined by the individual sensor AF layout of the camera model.

<img src="images/Canon 1.jpg" alt="Canon 1" style="width: 1000px;"/><br>
5D Mark IV. PDAF-focused shot with Servo AF Preset "Case 1" and multiple focus points used.<br><br>

<img src="images/Canon 2.jpg" alt="Canon 2" style="width: 1000px;"/><br>
CAF-focused shot using the 'green' color for in-focus points for better visibility.<br><br>

### 3.1.2 Canon Mirrorless

As with Nikon, Canon mirrorless models feature a hybrid autofocus system. However, in terms of focusing information stored in EXIF, the cooperation of PDAF and CAF is transparent. You can find the x, y positions of the focus point area(s) used to focus the shot as well as their width and height always in the same format.

<img src= "images/Canon 3.jpg" alt="Canon 3" style="width: 1000px;"/><br>
R3. AI Servo AF with Case A preset and subject detection 'Animals'<br><br> 

<img src= "images/Canon 5.jpg" alt="Canon 5" style="width: 1000px;"/><br>
R5 Mark II. AI Servo AF with Case A preset and subject detection 'Auto'<br><br> 

<img src= "images/Canon 6.jpg" alt="Canon 6" style="width: 1000px;"/><br>
R1. AI Servo AF with Action Priority "On" and Sport Events "Basketball".<br><br> 

<img src= "images/Canon 4.jpg" alt="Canon 4" style="width: 1000px;"/><br>
R1. When capturing flat subjects, focus point display for Canon R-series can be funny sometimes. 

<br>

## 3.2 Nikon

Supported features:

|                                       MAC                                       |                                         WIN                                         |       Color       | Meaning                                                              |
|:-------------------------------------------------------------------------------:|:-----------------------------------------------------------------------------------:|:-----------------:|----------------------------------------------------------------------|
|    <img src="images/af_infocus.png" alt="infocus" style="width: 20px;"/>    |    <img src="images/af_infocus_win.png" alt="infocus" style="width: 20px;"/>    |  red<sup>1</sup>  | Active AF point. Focus area, dimensions reported by the camera       |
| <img src="images/af_infocusdot.png" alt="infocusdot" style="width: 20px;"/> | <img src="images/af_infocusdot_win.png" alt="infocusdot" style="width: 20px;"/> | red<sup>1,2</sup> | Primary AF-Point                                                     |
|   <img src="images/af_inactive.png" alt="inactive" style="width: 20px;"/>   |   <img src="images/af_inactive_win.png" alt="inactive" style="width: 20px;"/>   |       gray        | Inactive AF point. Part of DSLR AF points but not used for the image |

<sup>1</sup> Active AF point color can be chosen from red, green, blue in [Viewing Options](#viewing-options).<br>

The logic for interpreting Nikon-specific autofocus data has been adapted to match the focus point display of NX Studio and Capture NX-D. While this is not rocket science for the Nikon Z, it has been a challenge for Nikon DSLRs. Nikon stores different types of focus point information in different places, making it difficult to find the relevant information and name it consistently. I would like to take this opportunity to thank [Warren Hatch](https://www.warrenhatchimages.com/) for his great support in deciphering and correctly interpreting the Nikon AF information!

Nikon focus point information in EXIF metadata always refers to an area within the frame. For CAF results, this is the coordinates (x,y, height, width). For PDAF results it's the name(s) of the focus points (e.g. A1, C6, E4) that the plugin maps to the corresponding pixel coordinates. Thus, for Nikon focus points, you can select the color of the box but not its size.

Nikon metadata does not include face or subject detection data, so you won't see any corresponding detection frames. This does not mean that this information is not present in the file - it just has not yet been decoded by the maintainers and active supporters of ExifTool.


### 3.2.1 Nikon DSLR


Nikon DSLRs typically have two autofocus systems. A high-performance phase-detection autofocus (PDAF) and a slower contrast autofocus when using Live View.

The position and size of the PDAF focus points are determined by the camera model's individual sensor AF layout. PDAF points cover only a portion of the frame. For DSLRs with limited focus coverage, the full matrix of focus points is displayed along with the in-focus point.

Examples:

<img src="images/Nikon 8.jpg" alt="Nikon 8" style="width: 1000px;"/><br>
 D7500, Single Area shot. The AF point in focus is highlighted within the matrix of 51 AF points.<br><br>

<img src="images/Nikon 1.jpg" alt="Nikon 1" style="width: 1000px;"/><br>
 D850, Single Area shot. The AF point in focus is highlighted within the matrix of 55 user-selectable AF points (out of a total of 153).<br><br>

<img src="images/Nikon 3.jpg" alt="Nikon 3" style="width: 1000px;"/><br>
D850, Group Area shot.<br><br>

<img src="images/Nikon 9.jpg" alt="Nikon 9" style="width: 1000px;"/><br>
D3S, Dynamic Area (3D tracking) shot.<br><br>

<img src="images/Nikon 7.jpg" alt="Nikon 7" style="width: 1000px;"/><br>
D6, Dynamic Area (3D tracking) shot. Multiple AF points were used to focus the image; the primary AF point is indicated by a center dot.<br><br>

<img src="images/Nikon 2.jpg" alt="Nikon 2" style="width: 1000px;"/><br>
D500, Live View shot. In Contrast AF modes, the focus "point" is an area that varies in size depending on the shooting conditions.<br><br>

<img src="images/Nikon 6.jpg" alt="Nikon 6" style="width: 1000px;"/><br>
D780, Live View shot, with several of the sensor based 81 AF areas engaged. The primary AF area is indicated by a center dot.<br><br>


### 3.2.2 Nikon Mirrorless

Nikon's mirrorless cameras feature a hybrid autofocus system that uses both PDAF and CAF to achieve fast and accurate focusing. While earlier models like the Z6 produced a fair amount of images with PDAF results, these images become rare in modern cameras like the Z9, as CAF technology becomes more powerful.

Early Z models had an 81-point (9x9) PDAF, which grew to 493 points (27x15) on the Z8/Z9. Unlike DSLRs, information about inactive (unused) focus points is less useful here, so it is not displayed.

Examples:

<img src="images/Nikon 4.jpg" alt="Nikon 4" style="width: 1000px;"/><br>
Z9, subject detection "People".<br><br>

<img src="images/Nikon 10.jpg" alt="Nikon 10" style="width: 1000px;"/><br>
Z5 II, no subject detection.<br><br>

<img src="images/Nikon 5.jpg" alt="Nikon 5" style="width: 1000px;"/><br>
Z7. The first Nikon mirrorless models tended to determine the focus point using the PDAF grid, especially for "flat" scenes.

<br> 


## 3.3 Sony

Supported features:

|                                       MAC                                       |                                         WIN                                         |       Color       | Meaning                                                                   |
|:-------------------------------------------------------------------------------:|:-----------------------------------------------------------------------------------:|:-----------------:|---------------------------------------------------------------------------|
|    <img src="images/af_infocus.png" alt="infocus" style="width: 20px;"/>    |    <img src="images/af_infocus_win.png" alt="infocus" style="width: 20px;"/>    |  red<sup>1</sup>  | Active AF point. Focus area, dimensions reported by the camera            |
| <img src="images/af_infocusdot.png" alt="infocusdot" style="width: 20px;"/> | <img src="images/af_infocusdot_win.png" alt="infocusdot" style="width: 20px;"/> | red<sup>1,2</sup> | Active AF point. Focus location, pixel coordinates reported by the camera |
|   <img src="images/af_inactive.png" alt="inactive" style="width: 20px;"/>   |   <img src="images/af_inactive_win.png" alt="inactive" style="width: 20px;"/>   |       gray        | Focal plane phase detect AF-point used during focusing                    |
|       <img src="images/af_face.png" alt="face" style="width: 20px;"/>       |       <img src="images/af_face_win.png" alt="face" style="width: 20px;"/>       |      yellow       | Face detected by the camera in this area                                  |

<sup>1</sup> Active AF point color can be chosen from red, green, blue in [Viewing Options](#viewing-options).<br>
<sup>2</sup> 'Focus-pixel' shape and size can be chosen from different options (small box or medium/large with center dot) in [Viewing Options](#viewing-options).

In Sony models, the focus point of an image is specified by the (x, y) coordinates in the `FocusLocation` tag. Newer models also support a `FocusFrameSize` tag, which specifies the size of the focus area. Custom focus frame size settings in the plugin's settings only apply when the focus frame size is not available in the metadata. In this case, medium and large focus boxes will display a center dot.

<img src= "images/Sony 1a.jpg" alt="Sony 1a.jpg" style="width: 1000px;"/><br>
α9. The focus point recorded by the camera corresponds to the center dot. The box is only there to make the dot more visible.<br><br>

<img src= "images/Sony 1b.jpg" alt="Sony 1b.jpg" style="width: 1000px;"/><br>
α9 II. If the focal plane phase detection autofocus points have been engaged during the focusing process, they will be displayed in grey.<br><br>


<img src= "images/Sony 2.jpg" alt="Sony 2" style="width: 1000px;"/><br>
α9 III. When focus frame size is given in metadata, the focus box cannot be changed in size (since this is determined by the camera) and the box will not have a center dot.<br><br>


Sony supports face detection on almost all of their mirrorless (alpha) and also compact (RX series) camera. The plugin can display the yellow face detection frames even on images taken with cameras 14 years back where it's not possible to detect focus points using EXIF data.

<img src= "images/Sony 5.jpg" alt="Sony 5" style="width: 750px;"/><br>
α6600 Detected face indicated by a yellow frame. Detected eye in focus indicated by a red dot.<br><br>

<img src= "images/Sony 3.jpg" alt="Sony 3" style="width: 1000px;"/><br>
α7 IV. Two face detected, one eye in focus.<br><br>

<img src= "images/Sony 6.jpg" alt="Sony 6" style="width: 750px;"/><br>
RX10 IV. Detected face indicated by a yellow frame. Detected eye in focus indicated by a red dot.<br><br>


In contrast to Canon and Nikon, there is not much that you can find in the EXIF maker notes for Sony's AF menu settings. This is why the focus information section is rather empty. Sony also lacks a focus distance tag, meaning there is no Depth of Field section.

<img src= "images/Sony 4.jpg" alt="Sony 4" style="width: 750px;"/><br>
α1 II. The number of known* AF settings entries is small compared to a Canon R5 Mark II.<br>

\* not "known" means that information may be present in metadata but has not been identified and decoded yet.



## 3.4 Fujifilm

Supported features:

|                                       MAC                                       |                                         WIN                                         |       Color       | Meaning                                                                   |
|:-------------------------------------------------------------------------------:|:-----------------------------------------------------------------------------------:|:-----------------:|---------------------------------------------------------------------------|
| <img src="images/af_infocusdot.png" alt="infocusdot" style="width: 20px;"/> | <img src="images/af_infocusdot_win.png" alt="infocusdot" style="width: 20px;"/> | red<sup>1,2</sup> | Active AF point. Focus location, pixel coordinates reported by the camera |
|       <img src="images/af_face.png" alt="face" style="width: 20px;"/>       |       <img src="images/af_face_win.png" alt="face" style="width: 20px;"/>       |      yellow       | Face, subject or detail detected by the camera in this area               |
|       <img src="images/af_crop.png" alt="crop" style="width: 20px;"/>       |       <img src="images/af_crop_win.png" alt="crop" style="width: 20px;"/>       |       black       | Part of the image that is used by the camera in 'crop mode'               |

<sup>1</sup> Active AF point color can be chosen from red, green, blue in [Viewing Options](#viewing-options).<br>
<sup>2</sup> 'Focus-pixel' shape and size can be chosen from different options (small box or medium/large with center dot) in [Viewing Options](#viewing-options).

Fujifilm metadata contains information on both face and subject recognition. Whether the detected subject is a person, an animal, a bicycle, a car, an airplane, or a train, and whether the detected eye is a real eye or a cockpit, all the information for visualizing a detected subject and its parts is stored in the same place and format.

Fujifilm focus points are 'focus pixel' points with no dimension. For better visualization, you can change the size and color of the focus box in the plugin's settings.

<img src="images/Fuji 1.jpg" alt="Fuji 1" style="width: 1000px;"/><br>
GFX100 II shot with face detection. Heads, faces and eyes are detected for both people (indicated by yellow frames). The focus point is slightly off the detected eye; this can also be seen in shots taken with OM system cameras. It seems that the subject detection analysis performed on a 2D image on the sensor is more accurate than what the 3D autofocus can achieve.<br><br> 

<img src="images/Fuji 3.jpg" alt="Fuji 2" style="width: 1000px;"/><br>
X-H2S shot with subject detection. The bird's head and eye were detected.<br><br>

<img src="images/Fuji 2.jpg" alt="Fuji 2" style="width: 1000px;"/><br>
X-T5 shot with subject detection. 4 birds were detected, with different level of details. In addition to the coordinates of the detected elements these are also listed in `SubjectElementTypes`.<br><br>

<img src="images/Fuji 4.jpg" alt="Fuji 2" style="width: 1000px;"/><br>
X-T5 shot with face detection. Fuji provides comprehensive information on camera and AF settings in the photo's metadata.<br><br>

<img src="images/Fuji 5.jpg" alt="Fuji 2" style="width: 750px;"/><br>
Finepix X100 shot with face detection. The plugin supports also compact FinePix models after 2007 .<br><br>


## 3.5 Olympus

Supported features:

|                                       MAC                                       |                                         WIN                                         |       Color       | Meaning                                                                   |
|:-------------------------------------------------------------------------------:|:-----------------------------------------------------------------------------------:|:-----------------:|---------------------------------------------------------------------------|
|    <img src="images/af_infocus.png" alt="infocus" style="width: 20px;"/>    |    <img src="images/af_infocus_win.png" alt="infocus" style="width: 20px;"/>    |  red<sup>1</sup>  | Active AF point. Focus area, dimensions reported by the camera            |
| <img src="images/af_infocusdot.png" alt="infocusdot" style="width: 20px;"/> | <img src="images/af_infocusdot_win.png" alt="infocusdot" style="width: 20px;"/> | red<sup>1,2</sup> | Active AF point. Focus location, pixel coordinates reported by the camera |
|       <img src="images/af_face.png" alt="face" style="width: 20px;"/>       |       <img src="images/af_face_win.png" alt="face" style="width: 20px;"/>       |      yellow       | Face or eye detected by the camera in this area                           |

<sup>1</sup> Active AF point color can be chosen from red, green, blue in [Viewing Options](#viewing-options).<br>
<sup>2</sup> 'Focus-pixel' shape and size can be chosen from different options (small box or medium/large with center dot) in [Viewing Options](#viewing-options).

Since 2008, Olympus has been using the same format for storing autofocus information in EXIF for all of its mirrorless cameras (starting with the E-M5 in 2012) as well as the last E-System models (E-5, E-420, E-520, E-620). Therefore, the focus point display is the same for all these models. The `AFPointSelected` tag contains the pixel coordinates of the focus point. The size and color of the focus box can be adjusted in the plugin's settings.

Earlier E-System models used the `AFAreas` tag, which gives a fixed size area that is displayed without a center point.

Examples:

<img src="images/Olympus 1.jpg" alt="Olympus 1" style="width: 750px;"/><br>
This is the typical display for all Olympus cameras from 2008 (E-420, E-520) to 2019 (E-M1X). A single focus point is reported as the focus position.<br><br>

<img src="images/Olympus 2.jpg" alt="Olympus 2" style="width: 750px;"/><br>
By tweaking the AF-Point settings, the focus point display can be adjusted to look like Olympus / OM shooters are used to from the OM Workspace application.<br><br>

Olympus makernotes also contains information on face detection:

<img src="images/Olympus 3.jpg" alt="Olympus 3" style="width: 1000px;"/><br>
E-M1 Mark III shot with face detection and Both Eyes priority.<br>

Olympus cameras store two sets of recognized faces (a maximum of eight faces per set). The exact position of a face may differ between the two sets, or a face present in one set may not be present in the other. Since it is neither possible to deduce which set has "better" information, nor to combine the information of the two sets (at least not with reasonable effort), all faces in both sets are visualized by yellow face detection frames.<br><br>

<img src="images/Olympus 5.jpg" alt="Olympus 5" style="width: 750px;"/><br>
A typical example of a situation where no focus point is displayed.
Focus Information shows that the `AFSearch` tag has a value of "Not Ready", which means that the camera was unable to lock focus when the shutter was pressed. A typical use case is when shooting with release priority or using the back button focus.<br><br>

<img src="images/Olympus 4.jpg" alt="Olympus 4" style="width: 1000px;"/>
The plugin is compatible with the entire E-System. While the benefit of supporting the focus point display for the old DSLR models is questionable<sup>3</sup> due to their very limited number of AF points (e.g. the E-1 has only 3 AF points), the implementation effort was small since the pre-2008 E-System models follow a very similar logic as the mirrorless models. Instead of using `AFPointSelected`, the focus area stored in `AFAreas` can be used to visualize the focus point/area.

<sup>3</sup> Using autofocus with a camera that has few focus points usually results in a two-step process: 1. focus on the desired point, then 2. hold the shutter button halfway down and pan the camera to achieve the desired composition. While this can produce great results, it's impossible to reconstruct the actual focus point. However, the focus point indicator can be useful for action shots, as "focus and pan" is not the best way to capture such scenes.

## 3.6 OM System

Supported features:

|                                       MAC                                       |                                         WIN                                         |       Color       | Meaning                                                                   |
|:-------------------------------------------------------------------------------:|:-----------------------------------------------------------------------------------:|:-----------------:|---------------------------------------------------------------------------|
|    <img src="images/af_infocus.png" alt="infocus" style="width: 20px;"/>    |    <img src="images/af_infocus_win.png" alt="infocus" style="width: 20px;"/>    |  red<sup>1</sup>  | Active AF point. Focus area, dimensions reported by the camera            |
| <img src="images/af_infocusdot.png" alt="infocusdot" style="width: 20px;"/> | <img src="images/af_infocusdot_win.png" alt="infocusdot" style="width: 20px;"/> | red<sup>1,2</sup> | Active AF point. Focus location, pixel coordinates reported by the camera |
|   <img src="images/af_selected.png" alt="selected" style="width: 29px;"/>   |   <img src="images/af_selected_win.png" alt="selected" style="width: 29px;"/>   |       white       | User-selected AF point<sup>3</sup>                                                    |
|       <img src="images/af_face.png" alt="face" style="width: 20px;"/>       |       <img src="images/af_face_win.png" alt="face" style="width: 20px;"/>       |      yellow       | Face, subject or detail detected by the camera in this area               |

<sup>1</sup> Active AF point color can be chosen from red, green, blue in [Viewing Options](#viewing-options).<br>
<sup>2</sup> 'Focus-pixel' shape and size can be chosen from different options (small box or medium/large with center dot) in [Viewing Options](#viewing-options).<br>
<sup>3</sup> User-selected AF point will be displayed for shots taken with Back-Button Focus (BBF)

OM System has its own chapter in this user documentation. This is mainly because previously unknown metadata tags have been identified and decoded: `AFSelection`, `AFFocusArea` and `SubjectDetectionArea`.

With this information, it is possible to visualize not only the AF area selected by the user and the point of focus, but also the frames used to detect the subject. These frames are the same frames that you can see in the viewfinder or on the camera display when shooting with Subject Detection enabled.

### 3.6.1 OM System - AF Selection

The AF area selected by the user is highlighted in white. The focus area is displayed in the color specified in the plugin settings. The size of the focus area cannot be selected, as the dimensions are set by the camera.

Here are some examples for visualization of in-focus vs selected AF points (subject detection mode OFF): 

<img src="images/OM System 4.jpg" alt="OM System 4" style="width: 750px;"/><br>
"Single" AF Area selected<br><br>

<img src="images/OM System 2.jpg" alt="OM System 2" style="width: 1000px;"/><br>
"Small" AF Area selected<br><br>

<img src="images/OM System 1.jpg" alt="OM System 1" style="width: 750px;"/><br>
"Medium" AF Area selected<br><br>

<img src="images/OM System 3.jpg" alt="OM System 3" style="width: 1000px;"/><br>
"Custom" AF Area selected<br><br>

### 3.6.2 OM System - Subject Detection

The plugin visualizes the subject detection frames as they appear in the viewfinder/on-camera display at the time of capture, according to the available subject detection modes:

<img src="images/OM System 5.jpg" alt="User Interface (Multi-image)" style="width: 650px;"/>

The subject and subject detail detection frames are displayed in yellow. The focus area is displayed in the color specified in the plugin settings. The size of the focus area cannot be selected, as the dimensions are set by the camera. The focus area has a center because the center of this area coincides with the coordinates specified by the `AFPointSelected` tag.

**Birds:**

<img src="images/OM System 6.jpg" alt="OM System 6" style="width: 1000px;"/><br>
Body and head detected, focus is on the head.<br><br>

<img src="images/OM System 7.jpg" alt="OM System 7" style="width: 1000px;"/><br>
Body and head eye detected, focus is on the eye.<br><br>

<img src="images/OM System 20.jpg" alt="OM System 20" style="width: 750px;"/><br>
Body and eye detected, focus is on the eye.<br><br>

**Dogs & Cats:**

<img src="images/OM System 8.jpg" alt="OM System 8" style="width: 1000px;"/><br>
Body and head detected, focus is on the head<br><br>

<img src="images/OM System 9.jpg" alt="OM System 9" style="width: 1000px;"/>
Same subject and scene, better detection - head and eye detected, focus is on the eye<br><br>


**Motorsports:**

<img src="images/OM System 10.jpg" alt="OM System 10" style="width: 1000px;"/><br>
Racing car found, chassis and driver detected. Focus is on the driver.<br><br>

<img src="images/OM System 11.jpg" alt="OM System 11" style="width: 1000px;"/><br>
Motorcycle found, vehicle and driver detected. Focus is on the driver.<br><br>

<img src="images/OM System 12.jpg" alt="OM System 12" style="width: 1000px;"/><br>
Car found, chassis and front detected. Focus is on the front.<br><br>

<img src="images/OM System 13.jpg" alt="OM System 13" style="width: 1000px;"/><br>
The cart is detected as racing car, chassis and driver detected. Focus is on the driver.<br><br>


**Airplanes**

<img src="images/OM System 14.jpg" alt="OM System 14" style="width: 1000px;"/>
<img src="images/OM System 15.jpg" alt="OM System 15" style="width: 1000px;"/>
<img src="images/OM System 16.jpg" alt="OM System 16" style="width: 1000px;"/>
<img src="images/OM System 17.jpg" alt="OM System 17" style="width: 1000px;"/>

**Trains**

<img src="images/OM System 18.jpg" alt="OM System 18" style="width: 1000px;"/><br>
Train and driver compartment detected, focus is on the driver compartment.<br><br>

**Human**

<img src="images/OM System 19.jpg" alt="OM System 19" style="width: 1000px;"/>


## 3.7 Panasonic

Supported features:

|                                       MAC                                       |                                         WIN                                         |       Color       | Meaning                                                                   |
|:-------------------------------------------------------------------------------:|:-----------------------------------------------------------------------------------:|:-----------------:|---------------------------------------------------------------------------|
|    <img src="images/af_infocus.png" alt="infocus" style="width: 20px;"/>    |    <img src="images/af_infocus_win.png" alt="infocus" style="width: 20px;"/>    |  red<sup>1</sup>  | Active AF point. Focus area, dimensions reported by the camera            |
| <img src="images/af_infocusdot.png" alt="infocusdot" style="width: 20px;"/> | <img src="images/af_infocusdot_win.png" alt="infocusdot" style="width: 20px;"/> | red<sup>1,2</sup> | Active AF point. Focus location, pixel coordinates reported by the camera |
|       <img src="images/af_face.png" alt="face" style="width: 20px;"/>       |       <img src="images/af_face_win.png" alt="face" style="width: 20px;"/>       |      yellow       | Face or subject detected by the camera in this area                       |

<sup>1</sup> Active AF point color can be chosen from red, green, blue in [Viewing Options](#viewing-options).<br>
<sup>2</sup> 'Focus-pixel' shape and size can be chosen from different options (small box or medium/large with center dot) in [Viewing Options](#viewing-options).<br>

Similar to Olympus, Panasonic hasn't changed the basic logic of focus point data in ages. Since 2008 to be exact. They use the same logic and format in all their cameras. As a result, Panasonic cameras are widely supported across all model lines, from mirrorless to bridge to compact.

<img src="images/Panasonic 1.jpg" alt="Panasonic 1" style="width: 1000px;"/>

While the focus point given by `AFPointPosition` metadata tag has no dimensions, recent Lumix models support an `AFAreaSize` tag in addition. This tag gives the size of the area used to find focus in subject detection modes. Whenever `AFAreaSize` exists, `AFPointPosition` represents the center of this area.

<img src="images/Panasonic 2.jpg" alt="Panasonic 2" style="width: 1000px;"/>

Panasonic also supports face detection identification in EXIF metadata. This information is available for recent mirrorless models, for compact cameras I have seen an ZS20 (2012 model!) image that used the same logic and notation for face detection frames.

<img src="images/Panasonic 3.jpg" alt="Panasonic 3" style="width: 750px;"/>

Panasonic doesn't support a "focus distance" specification in the metadata, so there is not much to go on other than the focus mode and AF area mode listed in the focus information section.


## 3.8 Leica

Supported features:

|                                       MAC                                       |                                         WIN                                         |       Color       | Meaning                                                                   |
|:-------------------------------------------------------------------------------:|:-----------------------------------------------------------------------------------:|:-----------------:|---------------------------------------------------------------------------|
| <img src="images/af_infocusdot.png" alt="infocusdot" style="width: 20px;"/> | <img src="images/af_infocusdot_win.png" alt="infocusdot" style="width: 20px;"/> | red<sup>1,2</sup> | Active AF point. Focus location, pixel coordinates reported by the camera |
|       <img src="images/af_face.png" alt="face" style="width: 20px;"/>       |       <img src="images/af_face_win.png" alt="face" style="width: 20px;"/>       |      yellow       | Face or subject detected by the camera in this area                       |

<sup>1</sup> Active AF point color can be chosen from red, green, blue in [Viewing Options](#viewing-options).<br>
<sup>2</sup> 'Focus-pixel' shape and size can be chosen from different options (small box or medium/large with center dot) in [Viewing Options](#viewing-options).<br>

Although the plugin can display AF metadata for many Leica cameras dating back to the beginning of the century, only a few cameras are supported for focus point display:

- Latest SL and Q series, with new firmware (Leica metadata)
- Older C, C-Lux, V-Lux, D-Lux series (Panasonic metadata)

The information available depends on the camera model.

| Camera Model | Introduced | Focus Points | Focus Mode | AF Mode | Focus Range | AF Detection | Straighten | 
|:-------------|:---------------:|:---------------------------:|:-------------------:|:----------------:|:--------------------:|:--------------------:|:--------------------:|
| SL3-P        | 2026 | ✓³ | ✓ | ✓ | ✓ | ✓³ | ✓ |
| SL3 / SL3-S    | 2024 | ✓² | ✓ | ✓ | ✓ | ✓² | ✓ |
| Q3 / Q3M / Q3 43  | 2023 | ✓¹ | ✓ | ✓ | ✓ | ✓¹ | ✓ |
| SL2-S        | 2020 | - | ✓ | ✓ | ✓ | - | - |
| SL2          | 2019 | - | ✓ | ✓ | ✓ | - | - |
| Q2           | 2019 | - | ✓ | ✓ | ✓ | - | - |
| CL           | 2017 | - | ✓ | ✓ | ✓ | - | - |
| TL2          | 2017 | - | ✓ | ✓ | ✓ | ✓| - |
| TL           | 2016 | - | ✓ | ✓ | ✓ | - | - |
| SL           | 2015 | - | ✓ | ✓ | ✓ | - | - |
| Q            | 2015 | - | ✓ | ✓ | ✓ | - | - |
| C⁴           | 2013 | ✓ | ✓ | ✓ | - | - | - |
| C-Lux⁴       | 2006 | ✓ | ✓ | ✓ | - | - | - |
| V-Lux⁴       | 2006 | ✓ | ✓ | ✓ | - | - | - |
| D-Lux⁴       | 2003 | ✓ | ✓ | ✓ | - | - | - |


**Legend:**

✓ Supported<br>
— Not supported<br>

1. Starting with firmware version 4.1
2. Starting with firmware version 4.2
3. Starting with firmware version 4.2 
4. Identical to Panasonic counterpart or based on a shared platform.

**Focus Mode:** AF-S, AF-C, MF, etc.
**AF Mode:** Spot, Field, Zone, Tracking, Face Detection, etc.

Examples:

<img src="images/Leica 1.jpg" alt="Leica 1" style="width: 1000px;"/>
Q3 - Displaying all available information
<br><br>

<img src="images/Leica 2.jpg" alt="Leica 2" style="width: 1000px;"/>
SL2-S - Displaying basic information (no focus points, Focus Mode, AF Mode)
<br><br>

<img src="images/Leica 3.jpg" alt="Leica 3" style="width: 750px;"/><br>
The Leica D-Lux 8 shares a platform with the Lumix LX series, and therefore has a similar focus point display to Panasonic cameras. 
<br>


## 3.9 Hasselblad

Supported features:

|                                     MAC                                     |                                       WIN                                       |      Color      | Meaning                                                              |
|:---------------------------------------------------------------------------:|:-------------------------------------------------------------------------------:|:---------------:|----------------------------------------------------------------------|
|  <img src="images/af_infocus.png" alt="infocus" style="width: 20px;"/>  |  <img src="images/af_infocus_win.png" alt="infocus" style="width: 20px;"/>  | red<sup>1</sup> | Active AF point. Focus area, dimensions reported by the camera       |

<sup>1</sup> Active AF point color can be chosen from red, green, blue in [Viewing Options](#viewing-options).<br>

The plugin supports displaying focus points and related autofocus information for the following Hasselblad cameras:

- X2D II 100C
- X2D 100C
- CFV 100C/907X
- X1D II 50C
- X1D 50C
- CFV II 50C/907X

The available information varies by camera model.

Image straightening is not supported because it is currently unclear whether Hasselblad cameras record RollAngle information and, if so, where this information is stored in the image metadata.

| Camera Model | Introduced | Focus Points | Focus Mode¹ | Focus Point Mode² | MF Assist Status³ | Tracking Status⁴ | Subject Detection Status⁵ |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| X2D II 100C | 2025 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| CFV 100C/907X | 2024 | ✓ | ✓ | – | * | – | – |
| X2D 100C | 2022 | ✓ | ✓ | – | * | – | – |
| CFV II 50C/907X | 2020 | ✓ | ✓ | – | – | – | – |
| X1D II 50C | 2019 | ✓ | ✓ | – | – | – | – |
| X1D 50C | 2016 | ✓ | ✓ | – | – | – | – |

**Legend:**

✓ Supported<br>
– Not supported<br>
\* Insufficient test images to decode the information<br>

¹ AF-S, AF-C, MF

² Spot, Expanded Spot, Custom, Wide

³ On, Off

⁴ On, Off (Ready), On (Active)

⁵ Subject Detected (the specific subject type selected – Human, Cat/Dog, or Vehicle – is not available in the metadata).
<br>

Examples


<img src="images/Hasselblad 1.jpg" alt="Hasselblad 1" style="width: 1000px;"/>
This photo, taken with the X2D II 100C, displays all the available focus information.
<br><br>

<img src="images/Hasselblad 5.jpg" alt="Hasselblad 5" style="width: 1000px;"/>
This X2D II 100C photo was taken using manual focus. The displayed focus point corresponds to the area of the 'Focus Indicator' chosen by the photographer as MF Assist function. 
<br><br>

<img src="images/Hasselblad 6.jpg" alt="Hasselblad 6" style="width: 1000px;"/>
CFV 100C/907X – basic information (focus point, focus mode)
<br><br>

<img src="images/Hasselblad 7.jpg" alt="Hasselblad 7" style="width: 1000px;"/>
X2D 100C – basic information (focus point, focus mode)
<br><br>

<img src="images/Hasselblad 2.jpg" alt="Hasselblad 2" style="width: 1000px;"/>
X1D II 50C – basic information (focus point, focus mode)
<br><br>

<img src="images/Hasselblad 3.jpg" alt="Hasselblad 3" style="width: 1000px;"/>
This X2D II 100C photo was taken using manual focus. The displayed focus point corresponds to the area where MF Assist 'Auto Zoom' would be if enabled if selected. 

<img src="images/Hasselblad 4.jpg" alt="Hasselblad 4" style="width: 1000px;"/>
X1D – basic information (focus point, focus mode)
<br><br>





## 3.10 Pentax

Supported features:

|                                     MAC                                     |                                       WIN                                       |      Color      | Meaning                                                              |
|:---------------------------------------------------------------------------:|:-------------------------------------------------------------------------------:|:---------------:|----------------------------------------------------------------------|
|  <img src="images/af_infocus.png" alt="infocus" style="width: 20px;"/>  |  <img src="images/af_infocus_win.png" alt="infocus" style="width: 20px;"/>  | red<sup>1</sup> | Active AF point. Focus area, dimensions reported by the camera       |
| <img src="images/af_selected.png" alt="selected" style="width: 29px;"/> | <img src="images/af_selected_win.png" alt="selected" style="width: 29px;"/> |      white      | User-selected AF point                                               |
| <img src="images/af_inactive.png" alt="inactive" style="width: 20px;"/> | <img src="images/af_inactive_win.png" alt="inactive" style="width: 20px;"/> |      gray       | Inactive AF point. Part of DSLR AF points but not used for the image |
|     <img src="images/af_face.png" alt="face" style="width: 20px;"/>     |     <img src="images/af_face_win.png" alt="face" style="width: 20px;"/>     |     yellow      | Face or eye detected by the camera in this area                      |

<sup>1</sup> Active AF point color can be chosen from red, green, blue in [Viewing Options](#viewing-options).<br>

Pentax is not only on par with other camera manufacturers and models in terms of supported features, it is even ahead of the "Big Three", Canon, Nikon and Sony.

While working on Pentax support, a lot of effort was put into finding and decoding relevant metadata tags for newer models (like the K-3 III) and fixing tags that were already supported by ExifTool but not properly decoded for models like the K-Sx, K-70 and KP.

With the Pentax additions to ExifTool versions 13.30 to 13.34, Pentax metadata now supports visualization of:
* User-selected focus points/areas
* Focus point(s) used by the camera
* Detected faces
* Inactive AF points (to visualize the complete AF layout)

The exact level of support depends on the camera model, as not all models support all features (e.g. face detection is not available on K-5 and even older models)

Here are some examples:

<img src="images/Pentax 1.jpg" alt="Pentax 1" style="width: 1000px;"/><br>
K-3 III image taken with viewfinder, selected focusing area "Auto Area" (all 101 AF points) and "Subject Recognition" on.<br><br>

<img src="images/Pentax 4.jpg" alt="Pentax 4" style="width: 1000px;"/><br>
K-3 III image taken with viewfinder, "Zone Select" focus area (21 AF points) selected, AF-C and "Continuous" drive mode. Action settings and AF-C control settings (AF hold, focus sensitivity, point tracking) for the shot are listed in "Focus Information".<br><br>

<img src="images/Pentax 6.jpg" alt="Pentax 6" style="width: 1000px;"/><br>
K-3 III image taken with viewfinder using "Expanded Area M" (5 selected AF points plus 60 peripheral AF points). The selected AF points are displayed in white, and the peripheral points are displayed in gray.<br><br>

<img src="images/Pentax 5.jpg" alt="Pentax 5" style="width: 1000px;"/><br>
K-3 III image taken with Live View using "Auto Area"<br><br>

<img src="images/Pentax 2.jpg" alt="Pentax 2" style="width: 1000px;"/><br>
K-3 III image taken with Live View using "Face Detection". The K-3 III records two sets of face detection information. Since there is no way to decide which set has "better" information, both sets are displayed.<br><br>

<img src="images/Pentax 3.jpg" alt="Pentax 3" style="width: 1000px;"/><br>
K-3 III image taken with Live View using "Face Detection". The K-3 III can detect up to 10 faces. Double images occur because two independent sets of face detection information are recorded. In this image, some faces are part of only one set. If more than 4 faces are detected in an image, the plugin will not display the eye information to avoid optical clutter.<br><br>

<img src="images/Pentax 7.jpg" alt="Pentax 7" style="width: 1000px;"/><br>
KP image taken with viewfinder using "Expanded Area (S)" (9 AF points). The AF point in focus is displayed in red, the selected AF points are displayed in white, and the remaining (inactive) AF points are displayed in gray.<br><br>

<img src="images/Pentax 8.jpg" alt="Pentax 8" style="width: 1000px;"/><br>
K-3 image taken with viewfinder using "Expanded Area (S)" (9 AF points). The AF point in focus is displayed in red, the selected AF points are displayed in white.<br><br>

<img src="images/Pentax 9.jpg" alt="Pentax 9" style="width: 750px;"/><br>
K-01 image taken with viewfinder using "Multiple AF Points".<br><br>

<img src="images/Pentax 10.jpg" alt="Pentax 10" style="width: 750px;"/><br>
Support for Pentax DSLRs dates back to the *ist D models introduced in 2003. However, due to the established focus-and-pan method on older DSLRs with only a few AF points, the use of the plugin for these cameras will be limited.<br><br>

## 3.11 Ricoh

Supported features:

|                                    MAC                                    |                                      WIN                                      |      Color      | Meaning                                                        |
|:-------------------------------------------------------------------------:|:-----------------------------------------------------------------------------:|:---------------:|----------------------------------------------------------------|
| <img src="images/af_infocus.png" alt="infocus" style="width: 20px;"/> | <img src="images/af_infocus_win.png" alt="infocus" style="width: 20px;"/> | red<sup>1</sup> | Active AF point. Focus area, dimensions reported by the camera |
|    <img src="images/af_face.png" alt="face" style="width: 20px;"/>    |    <img src="images/af_face_win.png" alt="face" style="width: 20px;"/>    |     yellow      | Face or eye detected by the camera in this area                |

<sup>1</sup> Active AF point color can be chosen from red, green, blue in [Viewing Options](#viewing-options).<br>

Starting with the GR III, Ricoh's GR models use the same metadata structures as the latest Pentax models (K-3 III), so support for these cameras is a by-product of adding support for the K-3 III.

Examples:

<img src="images/Ricoh 1.jpg" alt="Ricoh 1" style="width: 1000px;"/><br>
Single focus point selected and used to focus the image.<br><br>

<img src="images/Ricoh 2.jpg" alt="Ricoh 2" style="width: 1000px;"/><br>
Multiple focus points from "Auto Area" selection used to focus the image.<br><br>

<img src="images/Ricoh 3.jpg" alt="Ricoh 3" style="width: 750px;"/><br>
Detection of multiple faces and eyes.


## 3.12 Apple

Supported features:

|                                    MAC                                    |                                      WIN                                      |      Color      | Meaning                                                        |
|:-------------------------------------------------------------------------:|:-----------------------------------------------------------------------------:|:---------------:|----------------------------------------------------------------|
| <img src="images/af_infocus.png" alt="infocus" style="width: 20px;"/> | <img src="images/af_infocus_win.png" alt="infocus" style="width: 20px;"/> | red<sup>1</sup> | Active AF point. Focus area, dimensions reported by the camera |
|    <img src="images/af_face.png" alt="face" style="width: 20px;"/>    |    <img src="images/af_face_win.png" alt="face" style="width: 20px;"/>    |     yellow      | Face detected by the camera<sup>2</sup> in this area           |

<sup>1</sup> Active AF point color can be chosen from red, green, blue in [Viewing Options](#viewing-options).<br>
<sup>2</sup> Face detection is not done while the shot is being taken, but by Apple's Photos app.


Apple maintains a very simple logic to store the focused subject areas in EXIF metadata. This hasn't changed since early models (at least iPhone 5).

The makernotes section is rather short; older models do not even have an "Apple" section. Apart from the focus area, there is no relevant information to be displayed:

<img src="images/Apple 2.jpg" alt="Apple 2" style="width: 1000px;"/>

For modern Apple devices there are some interesting tags to extend the Shooting information section. However, the number of AF-relevant tags is limited. ExifTool can decode tags like `AFPerformance`, `AFMeasuredDepth` or `AFConfidence`, but their meaning is not documented and therefore the associated values are meaningless.

<img src="images/Apple 1.jpg" alt="Apple 1" style="width: 1000px;"/>

Face detection for an image exported from Apple Photos:

<img src="images/Apple 3.jpg" alt="Apple 3" style="width: 1000px;"/>

<br>

# 4 Special Topics


## How to use a keyboard shortcut to run the plugin

Although the plugin supports multi-image operation by selecting multiple images in Lightroom before launching the plugin, it can be tedious to navigate Lightroom's menu structure each time you want to use the plugin. Launching the plugin with a single key press is much more convenient. 

Unfortunately, Lightroom itself does not provide a way to assign keyboard shortcuts to these commands.

    Plugins such as [Any Shortcut](https://johnrellis.com/lightroom/anyshortcut.htm) and [Keyboard Tamer](https://www.photographers-toolbox.com/products/keyboardtamer.php) can assign shortcuts only to commands that belong to Lightroom's built-in menus. Commands that Lightroom creates dynamically — such as entries under _Plug-in Extras_, _Edit in_, _Export with Preset_ — cannot be assigned shortcuts. Focus Point Viewer falls into this category.

However, at the system level, there are ways to automate the startup of the plugin.

### Windows

On Windows, you can use the free [AutoHotkey](https://www.autohotkey.com/) utility together with a small script to assign the command `File → Plug-in Extras → Show Focus Point` to a key. The same applies to `Show Metadata` and `Straighten Images`.

The plugin comes with a ready-to-run, compiled AutoHotkey script that defines the following shortcuts:<br>
\-  `NumPad *` as a shortcut for `Show Focus Point`<br>
\-  `NumPad /` as a shortcut for `Show Metadata`<br>
\-`^NumPad -` as a shortcut for `Straighten Images`

The AutoHotkey script mimics a user selecting menu items in order to run a plugin function. This is why it depends on the Lightroom version — LR5/6 have different window titles to LrC — and, of course, the user interface language. For example, the menu item _File -> Plug-in Extras_ has a different name in the German or French versions.

The plugin package currently contains the following scripts to support different Lightroom versions:

| Script               | Version       |
|----------------------|---------------| 
| FocusPointsHotkey    | LrC (English) |                      
| FocusPointsHotkey_de | LrC (German)  |
| FocusPointsHotkey_fr | LrC (French)  |
| FocusPointsHotkey_LR | LR5/6         |

These scripts can be found in the `ahk` subfolder of the focuspoints.lrplugin folder.  
There is a precompiled executable (`.exe`) for each script, as well as the corresponding `.ahk` source file. You can use the source files as a starting point to create your own custom shortcuts if you do not like the predefined keys. 

#### Activate the predefined keyboard shortcuts:

1. Go to the `focuspoints.lrplugin\ahk` folder.
2. Choose the script that matches your Lightroom version and language.
3. Double-click the corresponding executable. An active script is indicated by a green<img src="images/autohotkey_icon.jpg" alt="autohotkey_icon" style="width: 36px;"/>icon in the system tray.
4. Drag the executable to your Windows `Startup` folder, to make the shortcuts available each time you start Windows.

-----

#### Create your own custom keyboard shortcuts:

You can use [FocusPointsHotkey.ahk](../focuspoints.lrplugin/ahk/FocusPointsHotkey.ahk) (or the corresponding .ahk file for your setup) as a starting point to create your own custom shortcuts:

1. Download AutoHotkey v2 from https://www.autohotkey.com/ and install it on your system.

2. Open the script file [FocusPointsHotkey.ahk](../focuspoints.lrplugin/ahk/FocusPointsHotkey.ahk) in a text editor. 

3. To define different shortcut keys:
   * Replace `NumpadMult`, `NumpadDiv`, `^NumPad -` with the keys you want to use.
   * See [Hotkeys](https://www.autohotkey.com/docs/v2/Hotkeys.htm) and [List of Keys](https://www.autohotkey.com/docs/v2/KeyList.htm) for hotkey syntax.<br>

    **Example:**<br>
    If you want to assign the plugin functions to `Win-F`, `Win-M`, `Win-S` you have to replace `NumpadMult` by `#f`, `NumpadDiv` by `#m` and `^NumPad -` by `#s`. If you prefer a `Ctrl-Shift` combination instead of `Win` the hotkey names are `^+f`, `^+m`, `^+s`.<br>Save your changes to the file. 

4. Double-click `FocusPointsHotkey.ahk` to run the script. In case you didn't introduce any errors, a green<img src="images/autohotkey_icon.jpg" alt="autohotkey_icon" style=" width: 36px;"/>icon in the system tray indicates that the script is active.

5. To make the shortcuts available permanently, place `FocusPointsHotkey.ahk` in your Windows `Startup` folder.<br>


Note:
* Redefining keyboard shortcuts overrides the existing meaning of the corresponding keys in Lightroom. For example, if you set `^f` (Ctrl-F) as the keyboard shortcut for the plugin, it will override the 'Find' command in the 'Library' module. 


* The `MenuSelect` command used in the script uses the _exact names_ of the menu items to identify the command to be run. If these menu names change in a future Lightroom release, the script must be updated accordingly.

For example, in LrC 14.5 (German UI), the menu item `Zusatzmoduloptionen` was renamed to `Plug-in-Extras`, causing the script to stop working until it was updated.

<br>

-----

### macOS

On macOS, you can use the system-wide feature in 

`System Settings → Keyboard → Keyboard Shortcuts → App Shortcuts` 

to assign your own shortcut to almost any menu item in any app. Here’s how you can do it for a Lightroom plugin to be added:

Example for:<br>
\- `F12` as a shortcut for `Show Focus Point`<br>
\- `F11` as a shortcut for `Show Metadata`

Note: `NumPad *` and `NumPad /` may not work because macOS sometimes treats NumPad symbols (* / + -) the same as the normal keyboard symbols, so for this example we will use function keys. 

**Steps:**

1. Go to `Settings → Keyboard → Keyboard Shortcuts → App Shortcuts`.
2. Click `+`.
   - Application: `Adobe Lightroom Classic`
   - Menu Title: "&nbsp;&nbsp;&nbsp;Show Focus Point" (with **3 spaces** before the actual text!)
   - Keyboard Shortcut: Press `F12` (or your desired shortcut)<br>
3. Repeat 2. for `Show Metadata` and `F11`.
4. Restart Lightroom Classic if the shortcuts don’t show immediately.

Note:<br> 
Of course, you can use any other keys you like. Just note, that if you assign the same shortcut to two different items, macOS picks one unpredictably.

<br>

## How to reduce long wait times when opening the plugin window on Windows

Until V3.3, the time taken for the plugin window to appear in Windows has mainly been determined by the time taken to **obtain a preview of the current photo**. If a preview is available in Lightroom, this can be obtained instantly. Otherwise, it can take several seconds for the plugin window to appear.

The time required for preview generation depends on image size and system performance. For RAW files this can range from less than one second to several seconds. The plugin window size also impacts the rendering time: the more space it occupies on the screen, the longer it takes to create the image to be displayed.

The following chart compares the typical plug-in start-up time for different camera models when using different methods to create the image displayed in [Photo View](#photo-view). Direct View is the display mode used on macOS.

<img src="images/Performance%20Control%201.jpg" alt="Performance Control 1" style="width: 1000px;"/>

If the plugin window takes more than a second to open, the main reason for the delay is usually the time taken for Lightroom to make a usable preview available. However, if the plugin window takes considerably longer than one to two seconds to open, it is usually quicker not to wait for the preview to become available, but to instead generate the image file using Lightroom's Export function.

<span id="performance-control"></span>
V3.4 introduces the **'Performance Control'** feature, which enables you to customize the process used to create the image displayed in Photo View.

Once the configured waiting time for a preview has elapsed, the image will be created for display using Lightroom's Export function rather than waiting for the preview to become available. Depending on the camera model, it can take much longer for Lightroom to generate a preview than it takes to create an image via Export. For example, consider Z8/Z9 in the chart. Switching to Export Image after a short timeout can significantly reduce the time required for the plugin window to appear in these cases.

The plugin settings allow you to configure when the plugin should stop waiting for a preview and switch to Lightroom Export.

<img src="images/Performance%20Control%202.jpg" alt="Performance Control 2" style="width: 600px;"/>

The first setting controls whether a fallback from preview acquisition to export is enabled, along with the corresponding waiting time for the preview. If this duration is set to zero, the plugin bypasses the preview stage and proceeds directly to export.

The second setting determines whether a progress indicator is displayed to notify the user that the plugin is waiting for an image to be created. This indicator appears after the configured time period has elapsed and disappears when the plugin window is opened. The progress indicator is useful when the waiting time exceeds 1–2 seconds, as it shows that the plugin has started or is still active.

The optimum values for the preview acquisition timeout and the progress indicator display depend largely on the hardware setup and the type of image files. These, in turn, depend on the camera manufacturer and model. As such, there is no one-fits-all recommendation, and each user must determine the optimal timeout value for their specific environment. The default values timeout = 0.5s and progress indicator delay = 0.5 should be a good starting point.

To help you find reasonable settings that ensure good overall performance, the log file provides information about how long it takes to create and display the plugin window.

**Example**

Let's look at an example of a photo taken with the Nikon Z9:

<img src="images/Performance%20Control%203.jpg" alt="Performance Control 3" style="width: 1000px;"/>

 We open the same photo three times in the plugin window, each time under different conditions and with different performance settings. The resulting log file shows: 
 - how quickly a preview could be obtained; 
 - whether a waiting timeout was reached;
 - how long it took the plugin window to open.

<img src="images/Performance%20Control%204.jpg" alt="Performance Control 4" style="width: 1000px;"/>

1. Section highlighted in blue (correlates with the blue bars in the chart)  
   A preview of the image is already available because Lightroom created it when the image was imported. The preview can be obtained instantly — the time taken to open the dialogue is less than one second.

2. Section highlighted in red (the red bars in the chart)  
  Straightening the image causes a refresh of the plugin window. Straightening, cropping or transforming an image invalidates Lightroom's existing preview, forcing it to regenerate. With the 'Use temporary export' setting disabled, the plugin waits for the preview to become available. This takes 6.8 seconds. The plugin window does not open until 7.63 seconds have elapsed.

3. Section highlighted in orange (the orange bars in the chart).
It's the same image, and there is no preview available. This time, the 'Use temporary export' setting has been enabled with a timeout of 0.5 seconds. After 0.6 seconds, the plugin stops acquiring the preview and uses Export instead. The plugin window opens after 3.5 seconds, which is less than half the time.

**How can you use this information to determine the optimal settings for your setup?**

Check for your images, how long it takes typically to **obtain a preview that is already available**. Add a small buffer to this number and enter it as the **timeout value**.

If you have a very powerful CPU/GPU but are exporting to a slow hard drive (i.e. non-SSD), it may be useful to experiment with higher timeout values.

<br>

## How to create a debug log file

When you report an issue with Focus Point Viewer, you may be asked to provide a `Debug` log file. The logging feature is described in detail in the [Logging section](#logging). 

Here are the steps to generate a debug log file and send it to the developer:

1. Open the plugin settings and locate the `Logging` section. Select `Debug` as the logging level:

   <img src="images/Logging%20-%20Debug.jpg" alt="Logging Debug"/>

2. Run the plugin and reproduce the problem you want to have recorded in the log file.
3. Open the plugin settings again. In the `Logging` section, click `Show file`. This brings Finder (macOS) or File Explorer (Windows) to the foreground and highlights the log file.
4. Attach the log file to an email and send it to the developer at [focuspoints.plugin@gmail.com](mailto:focuspoints.plugin@gmail.com) 
