--[[
  Original work © Whizzbang Inc
  Ongoing maintenance and modifications © 2026 Karsten Gieselmann

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
--]]

return {
  LrSdkVersion = 5.0,
  LrSdkMinimumVersion = 5.0,

	LrToolkitIdentifier = 'com.thewhizzbang.focuspoint',
	LrPluginName = "Focus Point Viewer",

	LrLibraryMenuItems = {
    {
      title = "Show Focus Point",
      file = "FocusPoint.lua",
      enabledWhen = "photosSelected"
    },
    {
      title = "Show Metadata",
      file = "Metadata.lua",
      enabledWhen = "photosSelected"
    },
    {
      title = "Straighten Images",
      file = "StraightenImages.lua",
      enabledWhen = "photosSelected"
    },
  },

  LrExportMenuItems = {
    {
      title = "Show Focus Point",
      file = "FocusPoint.lua",
      enabledWhen = "photosSelected"
    },
    {
      title = "Show Metadata",
      file = "Metadata.lua",
      enabledWhen = "photosSelected"
    },
    {
      title = "Straighten Images",
      file = "StraightenImages.lua",
      enabledWhen = "photosSelected"
    },
  },

  VERSION = {
      major      = 3,
      minor      = 4,
      revision   = 3,
      build      = 0,
      display    = "3.4.3",
      -- custom additions:
      channel    = "release",
      branch     = "master",
      rawBaseUrl = "https://raw.githubusercontent.com/focuspointslrc/Focus-Points/",
  },

  LrPluginInfoProvider = 'FocusPointsInfoProvider.lua',

  LrInitPlugin = 'FocusPointsInitialize.lua',
}
