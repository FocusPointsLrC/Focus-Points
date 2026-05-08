# Focus Points for Lightroom Classic

<img src="docs/images/ReadMe 1.jpg" alt="Screenshot" style="width: 800px;"/>

A plugin for Lightroom Classic<sup>1</sup> on Windows and macOS: 
- Show which focus point was active when the picture was taken <sup>2</sup>
- Display user-selected autofocus points/area <sup>3,4</sup>
- Visualize faces and subjects detected by the camera <sup>3,5</sup>
- Tagging (flagging, rating and coloring) of photos within the plugin UI <sup>7</sup>
- Display and search (EXIF) metadata of the selected image 
- Straightening images by applying compensation for camera roll angle<sup>3,6,7</sup>

<sup>1</sup> LR5.7 and LR6 perpetual licenses and LrC subscriptions.<br>
<sup>2</sup> For Canon, Nikon, Sony, Fuji, Olympus/OM, Panasonic, Pentax, Ricoh, Apple. See full [list of supported cameras](#supported-cameras).<br>
<sup>3</sup> Depending on the presence of metadata.<br> 
<sup>4</sup> Currently supported for Pentax and OM System.<br> 
<sup>5</sup> Currently supported for Fuji, OM System (subjects, faces) and Sony, Olympus, Pentax (faces).<br> 
<sup>6</sup> Currently supported for Canon, Nikon, Fuji, Olympus/OM, Panasonic, Pentax, Ricoh.<br>
<sup>7</sup> Not for LR5.<br>

## Current Release: [V3.3 updated April 9, 2026](https://github.com/musselwhizzle/Focus-Points/releases/latest)

**[Download the latest release](https://github.com/musselwhizzle/Focus-Points/releases/latest)**  or see detailed **[installation instructions](#installation)**.

If you have any questions, comments or suggestions for improving this plugin, please share your feedback in **[Focus-Points Discusssions](https://github.com/musselwhizzle/Focus-Points/discussions)**.

To understand the principles of this plugin, how to use it and how to interpret the results, please refer to the **[User Manual](docs/Focus-Points.md)**. **It is recommended that you read chapters 1, 2 and the part of chapter 3 that applies to your camera**.


### New features and changes:

* **User Interface**
  * Straighten images by making use of RollAngle metadata information [#365](https://github.com/musselwhizzle/Focus-Points/issues/365). <br>
  Supported for:
    - Canon 
      - R5 (FW 1.5), R5m2
      - R6m2 (FW 1.4), R6m3
      - R7 (FW 1.3), R8 (FW 1.2), R10??
    - Nikon (D5, D500 and later models)
    - Fuji (XT-5 and later models)
    - Olympus/OM (EM-1/5/10 III and later models)
    - Panasonic (Lumix G6 and later models)
    - Pentax (K-7 and later models)
    - Ricoh (GR III and later models)  
    
    Not supported for LR5.
  
    Please refer to the [User Manual](docs/Focus-Points.md#24-straighten-images) for a description of this feature.
  
* **Bugfixes**
  * Ricoh GR DNG images can cause plug-in to crash [#367](https://github.com/musselwhizzle/Focus-Points/issues/367)
  * Next/Previous button issue (no function when clicked) [#368](https://github.com/musselwhizzle/Focus-Points/issues/368)
  * FATAL error calling 'mogrify.exe' [#370](https://github.com/musselwhizzle/Focus-Points/issues/370)
  * Straighten Images stops with "Internal Error" for non-numeric RollAngle values [#372](https://github.com/musselwhizzle/Focus-Points/issues/372)
    
* **Camera Support:**
  * Ricoh GR IV Monochrome
  * in addition to the cameras supported by V3.2. [See here for full list](#supported-cameras).
  
* **Other**
  * ExifTool 13.55 (April 7, 2026)
  * ImageMagick 7.1.2-17 
  * New plugin landing page and documentation without confusing Github details [#363](https://github.com/musselwhizzle/Focus-Points/issues/363)<br>
  [https://musselwhizzle.github.io/Focus-Points/](https://musselwhizzle.github.io/Focus-Points/)



## Installation

1. Download the [latest release](https://github.com/musselwhizzle/Focus-Points/releases/latest) of the plugin package.<br>
A file named `Focus-Points-[plugin_version].zip` will be downloaded to your computer.


2. Unzip the downloaded file. Inside the extracted content locate the plugin folder `focuspoints.lrplugin`.<br>
_MAC users_: According to your macOS preferences the zip file will be automatically unzipped.


3. Find the folder where you keep your Lightroom plugins.<br> If you don't know where this is, open Lightroom, go to `File → Plug-in Manager` and click `Add`. This will open a "Select Folder" dialog in Lightroom's default folder for plugins. 


4. To **update an existing installation**, first remove the folder containing the version of the plugin you want to update. You can delete the folder or rename it, for example, `to focuspoints.lrplugin.303` (for version 3.03). This allows you to easily revert to the previous version if the update causes issues.<br>
<u>Note</u>: It is necessary to remove the plugin folder at OS level because deleting a plugin in Lightroom's Plug-in Manager only removes it from Lightroom's list of known plugins. The plugin folder and its contents on disk remain as they are.<br>
Important: Copying the downloaded files over those in the existing folder is not recommended!


5. Move the downloaded plugin folder `focuspoints.lrplugin` to the folder where you keep your Lightroom plugins.<br> 
_MAC users_: if you have to navigate into the content of the `adobe lightroom classic.app`, use the control-click and choose  `show package content`.


6. Open Lightroom and go to `File → Plug-in Manager`.<br>
**New installation**:<br>
_Windows_: Click the `Add` button and select the plugin.<br>
_MAC_: In case of you'd copied the plugin to the default LR-plugin location, the new plugin is already listed - activate it. Otherwise, click on the `Add` button and select the plugin.<br>
**Update installation**:<br>
Select the plug-in and click `Reload plug-in` (only applies if Lightroom is open during the installation of the update.)


Once the plugin has been installed, choose one or more photos and select:
* `Library → Plug-in Extras → Show Focus Point`, or  
* `File → Plug-in Extras → Show Focus Point`

See [How to use a keyboard shortcut to run the plugin](docs/Focus-Points.md#how-to-use-a-keyboard-shortcut-to-run-the-plugin) to learn how to invoke the plugin using a hotkey.

If you have never used Lightroom plugins before and are looking for some basic information, a video tutorial would be a good place to start. For example, [Plugin Installation (5:16)](https://www.youtube.com/watch?app=desktop&v=dxB4eVcNPuU) or [How to Install & Remove Lightroom Plug-ins (11:30)](https://www.youtube.com/watch?v=DFFA8nKBsJw). 


## Supported AF Points

The plugin uses different colors to visualize AF points, detected faces, subjects and details. Visualization means that the respecive area is highlighted by a rectangular marker. On Windows this is a solid frame. On macOS, the frame is indicated by corner symbols. The reason for this OS-specific difference is explained in the [User Manual](docs/Focus-Points.md#photo-view).

|                                     MAC                                      |                                       WIN                                        |       Color       | Meaning                                                                               |
|:----------------------------------------------------------------------------:|:--------------------------------------------------------------------------------:|:-----------------:|---------------------------------------------------------------------------------------|
|    <img src="docs/images/af_infocus.png" alt="infocus" style="width: 20px;"/>    |    <img src="docs/images/af_infocus_win.png" alt="infocus" style="width: 20px;"/>    |  red<sup>1</sup>  | Active AF point. Focus area, dimensions reported by the camera                        |
| <img src="docs/images/af_infocusdot.png" alt="infocusdot" style="width: 20px;"/> | <img src="docs/images/af_infocusdot_win.png" alt="infocusdot" style="width: 20px;"/> | red<sup>1,2</sup> | Active AF point. Focus location<sup>3</sup>, pixel coordinates reported by the camera |
|   <img src="docs/images/af_selected.png" alt="selected" style="width: 29px;"/>   |   <img src="docs/images/af_selected_win.png" alt="selected" style="width: 29px;"/>   |       white       | User-selected AF point                                                                |   
|   <img src="docs/images/af_inactive.png" alt="inactive" style="width: 20px;"/>   |   <img src="docs/images/af_inactive_win.png" alt="inactive" style="width: 20px;"/>   |       gray        | Inactive AF point. Part of DSLR AF points but not used for the image<sup>3</sup>      |   
|       <img src="docs/images/af_face.png" alt="face" style="width: 20px;"/>       |       <img src="docs/images/af_face_win.png" alt="face" style="width: 20px;"/>       |      yellow       | Face or subject detected by the camera in this area                                   |  
|       <img src="docs/images/af_crop.png" alt="crop" style="width: 20px;"/>       |       <img src="docs/images/af_crop_win.png" alt="crop" style="width: 20px;"/>       |       black       | Part of the image that is used by the camera in 'crop mode'                           |

<sup>1</sup> AF point color can be chosen from red, green, blue in [Configuration and Settings](docs/Focus-Points.md#24-configuration-and-settings).<br>
<sup>2</sup> 'Focus-pixel' shape and size can be chosen from different options (small box or medium/large with center dot) in [Configuration and Settings](docs/Focus-Points.md#24-configuration-and-settings).<br>
<sup>3</sup> The meaning may vary depending on the camera manufacturer. See the camera-specific chapters in the [User Manual](docs/Focus-Points.md) for a detailed explanation.


On macOS, the focus point display of title photo looks like this:

<img src="docs/images/ReadMe 2.jpg" alt="Screenshot" style="width: 800px;"/>


Please note that not all cameras store the necessary information to support these features in the photo's metadata. For example, cameras from Canon and Nikon do not store any information on face or subject recognition (at least as far as is known), so visualization is not possible. 

See [chapter 3](docs/Focus-Points.md#3-display-of-focus-points) of the user manual for detailed information on which types of visualization are supported for which cameras.


## Metadata viewer

The plugin also features a metadata viewer with live search: 
  
* `Library → Plug-in Extras → Show Metadata`, or  
* `File → Plug-in Extras → Show Metadata`

The Metadata Viewer is useful for viewing information that is neither visible in Lightroom's Metadata panel nor in the Information pane of the focus windows. The information is retrieved directly from the image file on disk, giving a complete picture of the metadata written by the camera. Metadata can be filtered by key or value. The filter accepts pattern matching with common 'magic characters':

 | Char  | Meaning                                        | 
 |:-----:|------------------------------------------------|
 |   .   | any character                                  | 
 |   +   | one or more repetitions of previous character  |
 |   *   | zero or more repetitions of previous character |                                            
 |   ^   | start of line/string                           |
 |   $   | end of line/string                             |              


<img src="docs/images/metadata1.jpg" alt="Screenshot" style="width: 200px;"/>         <img src="docs/images/metadata2.jpg" alt="Screenshot" style="width: 200px;"/>         <img src="docs/images/metadata3.jpg" alt="Screenshot" style="width: 200px;"/>

<br>

## Straighten Images

Straightening images is a new plugin function in V3.3:

- `Library → Plug-in Extras → Straighten Images`, or
- `File → Plug-in Extras → Straighten Images`

This function reads the camera roll angle from the metadata of the selected photos, one by one, and applies compensation by rotating the photos accordingly.

Straightening individual images manually is not difficult, and Lightroom also supports automatic straightening using the Transform tool. However, the Straighten Image feature can come in handy for straightening a series of photos taken in burst mode, such as wildlife, sports or action shots. This is particularly useful when the captured scenes lack clear reference information to help you (or the Transform tool) straighten the images.

As this function relies on the presence of the `RollAngle` tag in metadata, its application is currently limited to

- Canon 
  - R5 (FW 1.5), R5m2
  - R6m2 (FW 1.4), R6m3
  - R7 (FW 1.3), R8 (FW 1.2), R10??
- Nikon (D5, D500 and later models)
- Fuji (XT-5 and later models)<sup>1</sup>
- Olympus/OM (EM-1/5/10 III and later models)
- Panasonic (Lumix G6 and later models)
- Pentax (K-7 and later models)<sup>2</sup>
- Ricoh (GR III and later models)<sup>2</sup>

<sup>1</sup> Fuji represents roll angle information within the range of -1° to +1° as `RollAngle=0`. <br>
<sup>2</sup> Pentax and Ricoh also record roll angle information for the specified models. However, when used to straighten photos, the results are typically not as precise as those provided by other brands.

Unfortunately, it seems that Sony does not record roll angle information in photo metadata. Even a deep analysis of a series of custom-made A7RV test images did not reveal any evidence of its presence.

Straighten Images is not available for LR5, since version 5.x of the Lightroom SDK does not yet supported the  required functionality.

### Example

The photo has a roll angle of 2.5°. Applying a crop angle of -2.5° compensates for the tilt. Please note that a non-zero crop angle will change the crop of the photo. Straightening the photo will result in the corners being lost.

Using the 'Straighten Images' tool produces the same result as entering the roll angle compensation manually in Lightroom's 'Crop & Straighten' tool. You can then modify or even revert the compensation as desired.

<img src="docs/images/Straighten%201.jpg" alt="User Interface" style="width: 1000px;"/>

Please refer to the [relevant section](https://musselwhizzle.github.io/Focus-Points/docs/Focus-Points.html#24-straighten-images) of the User Manual to learn how to use and customise this feature.  


## Supported Cameras

* Canon
  * Mirrorless: entire R-series
  * DSLR: all EOS models after 2004 (starting with EOS-1D Mark II)
  * Compact: Powershot models after 2004

 
* Nikon
  * Mirrorless: entire Z-series
  * DSLR: all D models with 39 or more autofocus points (from D3/D300 in 2007 to D6/D780 in 2020)
  * Compact: CoolPix models not supported

  
* Sony
  * Full-frame: α7, α9, α1 bodies beginning 2018 (with α7 III / α7R II) 
  * APS-C: α6100, α6300, α6400, α6500, α6600, α6700, ..
  * Compact: RX series, beginning 2015 (with RX10 II and RX100 IV)
  * Face detection
  

* Fuji
  * Mirroless: X-series (from X100 in 2011 up to X-H2S today), GFX-series
  * Compact: FinePix models after 2007  
  * Face and subject detection


* Olympus / OM System
  * DSLR: entire E-series
  * Mirrorless: entire E-M series, OM-1, OM-3, OM-5
  * Olympus: Face detection
  * OM System: Face and subject detection


* Panasonic
  * Mirrorless: entire LUMIX G and S series
  * Compact: FZ, TZ/ZS, LX series - models after 2008
  * Face detection
  

* Pentax 
  * DSLR: all models with 11 or more autofocus points (from *istD in 2003 to K-3 III Mono in 2023)
  * Face detection
  

* Ricoh
  * GR III, GR IIIx, GR IV including HDF versions
  * Face detection


* Apple
  * iPhone (starting from at least iPhone 5)
  * Face/pet detection frames (visualizing "Person & Pets" information from Apple's Photos App)



## Special Thanks

There's been a lot of man-hours put into this effort so far. All volunteer. So help me in thanking the individuals who have worked hard on this. First off, thanks for Phil Harvey for providing the 3rd party library ExifTool. The following is a list of the individual contributors on this project. These guys have fixed bugs, added camera support, added face detection, added support for your iphone, and many other cool features. (If you are a dev, and I've missed you, please feel free to update this file or add your real name):

rderimay, philmoz, project802, jandhollander, DeziderMesko, StefLedof, roguephysicist, ropma, capricorn8 (Karsten Gieselmann)

<a href="https://github.com/musselwhizzle/Focus-Points/graphs/contributors">Full list can be seen here.</a>

Special thanks go to [John R. Ellis](https://johnrellis.com/) for providing the code that mimics a rectangular crop while rotating a photo and preserving its aspect ratio. This is something that Lightroom's Crop & Straighten Tool can do, but the SDK cannot.
John is a renowned SDK expert and the creator of [numerous amazing Lightroom plugins](https://johnrellis.com/lightroom/allplugins.htm), including the Debugging Toolkit, without which this plugin wouldn't exist.


## Licenses

    Copyright 2016 Whizzbang Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

This plugin contains code from AutoHotkey (GPLv2).
See [LICENSE.txt](focuspoints.lrplugin/ahk/License.txt) for details.
