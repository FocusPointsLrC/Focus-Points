--[[
  Copyright 2016 Whizzbang Inc

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

--[[----------------------------------------------------------------------------
  FocusPointDialog.lua

  Purpose of this module:
  Entry point for 'Show Focus Point' menu command.
  Main control of data processing and user dialog.
------------------------------------------------------------------------------]]
local FocusPointDialog = {}

-- Imported LR namespaces
local LrPrefs          = import  'LrPrefs'
local LrView           = import  'LrView'

-- Required Lua definitions
local FocusPointPrefs  = require 'FocusPointPrefs'
local GlobalDefs       = require 'GlobalDefs'
local Log              = require 'Log'
local _strict          = require 'strict'
local Utils            = require 'Utils'

GlobalDefs.currentPhoto = nil

local previewWidth, previewHeight

--[[----------------------------------------------------------------------------
  public int width, int height
  calculatePhotoViewDimens(table photo)

  Calculates the dimensions of the view element for the current photo. This involves:
  - Cropped dimensions of the image
  - LR application window size (the plugin window cannot go bigger)
  - Scaling factor corresponding to user-defined plugin windows size S..XXL
  - On Windows: Display scaling factor (Auto or user-defined)
------------------------------------------------------------------------------]]
function FocusPointDialog.calculatePhotoViewDimens(photo)
  local prefs = LrPrefs.prefsForPlugin( nil )

  -- Retrieve photo dimensions
  local dimens = photo:getFormattedMetadata("croppedDimensions")
  local w, h = Utils.parseDimens(dimens)
  Log.logInfo("FocusPointDialog", string.format(
    "Image: %s (%s x %s)", photo:getFormattedMetadata('fileName'), w, h))

  -- Take user-defined plugin window size into account
  local windowSize    = FocusPointPrefs.getPluginWindowSize()  -- sizing factor for S..XXL
  local contentWidth  = GlobalDefs.appWidth  * windowSize
  local contentHeight = GlobalDefs.appHeight * windowSize

  -- Take Windows scaling factor into account
  if WIN_ENV then
    local displayScalingLevel = FocusPointPrefs.getDisplayScaleFactor()
    contentWidth  = contentWidth  * displayScalingLevel
    contentHeight = contentHeight * displayScalingLevel
  end

  -- Now do the math how the photo fits into the width/height limits
  local photoWidth = 0
  local photoHeight = 0
  if (w > h) then
    photoWidth = math.min(  (w), contentWidth)
    photoHeight = h/w * photoWidth
    if photoHeight > contentHeight then
        photoHeight = math.min(h, contentHeight)
        photoWidth = w/h * photoHeight
    end
  else
    photoHeight = math.min(h, contentHeight)
    photoWidth = w/h * photoHeight
    if photoWidth > contentWidth then
        photoWidth = math.min(w, contentWidth)
        photoHeight = h/w * photoWidth
    end
  end

  if prefs.secondScreenMode then
    previewHeight = photoHeight
    previewWidth  = photoHeight * prefs.previewAspectRatio
  end

  return math.floor(photoWidth), math.floor(photoHeight)
end

--[[----------------------------------------------------------------------------
  public table
  createDialog(_photo, photoView, infoView, kbdShortcutInput, controlPanel)

  Creates the view container for the entire dialog.
  ----------------------------------------------------------------------------]]
function FocusPointDialog.createDialog(_photo, photoView, infoView, kbdShortcutInput)
  local prefs = LrPrefs.prefsForPlugin( nil )
  local f = LrView.osFactory()

  local function previewPanel()
    if prefs.secondScreenMode then
      -- Place photo in the center of the preview area, which has a fixed aspect ratio.
      return f:row {
        width  = previewWidth,
        heigth = previewHeight,
        f:spacer { fill_horizontal = 1 },
        photoView,
        f:spacer { fill_horizontal = 1 },
      }
    else
      -- Preview area has the same dimensions as the photo
      return f:row {
        f:spacer {}, photoView, f:spacer {},
      }
    end
  end

  return f:view {
    f:row {
      f:spacer {}, kbdShortcutInput,
    },
    f:row {
      previewPanel(),
      f:column { fill_vertical = 1, infoView },
    },
  }
end

return FocusPointDialog -- ok
