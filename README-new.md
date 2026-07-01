# Introduction

<img src="docs/images/ReadMe 1.jpg" alt="Focus Points for Lightroom Classic" style="width:1000px;"/>

### See where your camera focused.

Focus Points is a plugin for Adobe Lightroom Classic that displays the autofocus point used when a photograph was taken.

But the focus point is only part of the story.

Modern cameras record much more than the final image. They also record autofocus information, subject detection, camera settings, lens information and many other details that provide valuable context when reviewing a photograph. Lightroom Classic makes only part of this information available.

**Focus Points brings this information together in a single view, allowing you to review each photograph with the information your camera actually recorded.**

---

### Use Focus Points to...

- See where your camera focused.
- Review autofocus areas, detected faces and subjects.
- Inspect the information recorded by your camera.
- Search image metadata.
- Straighten images using recorded roll-angle information.
- Rate, flag and label photographs while reviewing them.

---

### Why Focus Points?

Every photograph tells two stories.

The first is the image itself.

The second is the information your camera recorded while capturing it.

Modern cameras continuously analyse the scene before and during exposure. Depending on the camera model they record information such as the autofocus point, selected focus area, detected faces or subjects, camera orientation, focus distance, lens configuration and many other details.

Most of this information is either hidden or unavailable in Lightroom Classic.

Focus Points makes this information accessible, allowing you to review every photograph together with the data your camera actually recorded.

Whether you are analysing why a photograph is perfectly sharp, trying to understand why it isn't, or simply exploring how your camera behaves in different situations, Focus Points provides the information in one place.

---

## Supported Cameras

Focus Points supports cameras from

**Canon • Nikon • Sony • Fuji • Olympus / OM System • Panasonic • Pentax • Ricoh • Apple**

Support depends on the information recorded by each camera model. For a detailed compatibility overview please see << link to user manual >>.

---

## Documentation

The documentation is organised by purpose.

📘 **User Manual**

Learn how Focus Points works, how to interpret the information displayed by the plugin and how to get the best results with your camera.

🔧 **Troubleshooting Guide**

Solutions to common installation, configuration and camera-specific issues.

📝 **Release Notes**

New features, improvements and known limitations for each release.

💬 **GitHub Discussions**

Questions, ideas and feedback from the community.



The project documentation is organised into separate documents so each can focus on a single purpose.

| Document | Description |
|----------|-------------|
| **README** | Project overview and installation |
| **User Manual** | Complete feature documentation and camera-specific information |
| **Troubleshooting Guide** | Solutions to installation, compatibility and operational issues |
| **Release Notes** | New features, bug fixes and compatibility changes |

If you are new to Focus Points, reading the first chapters of the User Manual is strongly recommended.

---

## Features

### Focus Point Viewer

<img src="docs/images/ReadMe 2.jpg" alt="Focus Point Viewer" style="width:900px;"/>

The Focus Point Viewer displays the selected photograph together with autofocus information recorded by the camera.

Depending on camera support, the viewer can display

- active autofocus point
- user-selected autofocus point or autofocus area
- inactive autofocus points
- detected faces
- detected subjects
- crop mode

The exact information available depends on the camera model and the metadata recorded for the image.

For a complete explanation of the different markers and their meaning, see the User Manual.


### Metadata Viewer

The integrated Metadata Viewer displays camera metadata that is not normally available in Lightroom Classic.

Unlike Lightroom's Metadata panel, the Metadata Viewer reads the information directly from the original image file and provides access to camera-specific metadata, including manufacturer-specific information where available.

Features include

- live search
- filtering by tag name or value
- metadata group display
- direct access to EXIF, XMP and camera-specific metadata

The Metadata Viewer is particularly useful when analysing camera behaviour, comparing photographs or exploring newly supported camera models.


### Straighten Images

Many modern cameras record the camera's roll angle when a photograph is taken.

Focus Points can use this information to automatically straighten one or more selected photographs by applying the corresponding crop angle in Lightroom Classic.

This is particularly useful when reviewing action, wildlife or sports photography where manually straightening a large number of images would be time-consuming.

Version 3.4 also introduces interactive straightening directly from the Focus Point Viewer, allowing you to preview the result immediately and undo the adjustment if required.

Availability depends on camera support for roll-angle metadata. See the compatibility section below for supported camera models.

---

## Contributing

Bug reports, feature requests and camera samples are always welcome.

If you discover a camera that is not yet supported or notice incorrect autofocus information, please open a GitHub Issue or start a GitHub Discussion.

Camera support has grown over many years thanks to photographs and metadata provided by users around the world.

Every contribution helps improve support for future releases.

---

## Acknowledgements

Focus Points began as the open-source project created by **Whizzbang Inc.**

Since then it has evolved through contributions from many members of the Lightroom community.

Special thanks go to **Phil Harvey**, creator of **ExifTool**. Without ExifTool, much of the camera-specific metadata displayed by Focus Points would not be accessible.

Special thanks also go to **John R. Ellis** for providing the algorithm used to preserve aspect ratio while rotating photographs—functionality available in Lightroom itself but not exposed through the Lightroom SDK.

Additional contributors can be found on the project's GitHub Contributors page.

---

# License

Original work

© Whizzbang Inc.

Ongoing maintenance and modifications

© 2026 Karsten Gieselmann

Licensed under the Apache License, Version 2.0.

This plugin also contains components licensed under GPLv2.

See the accompanying LICENSE files for details.
