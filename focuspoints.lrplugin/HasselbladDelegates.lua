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

--[[----------------------------------------------------------------------------
  HasselbladDelegates.lua

  Purpose of this module:
  A collection of delegate functions to be passed into the DefaultPointRenderer when
  the camera is Hasselblad:

  - funcModelSupported:    Does this plugin support the camera model?
  - funcMakerNotesFound:   Does the photo metadata include maker notes?
  - funcManualFocusUsed:   Was the current photo taken using manual focus?
  - funcGetAfPoints:       Provide data for visualizing focus points, faces etc.
  - funcGetImageInfo:      Provide specific information to be added to the 'Image Information' section.
  - funcGetShootingInfo:   Provide specific information to be added to the 'Shooting Information' section.
  - funcGetFocusInfo:      Provide the information to be entered into the 'Focus Information' section.

  Implementation of Hasselblad AF specs decoded by @nurps:
  https://github.com/FocusPointsLrC/Focus-Points/issues/315#issuecomment-4229482977
  
------------------------------------------------------------------------------]]
local HasselbladDelegates = {}

-- List of supported models
local supportedModels = {
    ["x2d ii 100c"]           = "100c",
    ["x2d 100c"]              = "100c",
    ["cfv 100c/907x"]         = "100c",
    ["x1d ii 50c"]            = "50c",
    ["x1d-50c"]               = "50c",
    ["x1d"]                   = "50c",
    ["cfv ii 50c/907x"]       = "50c",
}

-- Imported LR namespaces
local LrView               = import  'LrView'

-- Required Lua definitions
local DefaultDelegates     = require 'DefaultDelegates'
local DefaultPointRenderer = require 'DefaultPointRenderer'
local ExifUtils            = require 'ExifUtils'
local FocusInfo            = require 'FocusInfo'
local Log                  = require 'Log'
local Utils                = require 'Utils'

-- AF-relevant tags
local metaKeyAfPosition                  = "Focus Area"
local metaKeyFocusMode                   = "Focus Mode"
local metaKeyMfAssist                    = "MF Assist"
local metaKeyFocusPointMode              = "Focus Point Mode"
local metaKeyTracking                    = "Tracking"
local metaKeySubjectDetection            = "Subject Detection"

-- Tag indicating that makernotes / AF section exists
local metaKeyMakerNotes                  = metaKeyFocusMode

-- Relevant metadata values
local metaValueOn                        = "On"
local metaValueOnReady                   = "On (Ready)"
local metaValueOnActive                  = "On (Active)"
local metaValueOff                       = "Off"

local sensorGeometries = {
    ["100c"] = {
        offsetX = 128,
        offsetY = 96,
        width   = 11656,
        height  = 8742,
        imageWidth  = 11904,
        imageHeight = 8842,
    },
    ["50c"] = {
        offsetX = 50,
        offsetY = 100,
        width   = 8272,
        height  = 6200,
        imageWidth  = 8384,
        imageHeight = 6304,
    },
}

-- Helper function to retrieve the sensor geometry data for a given camera model
local function getSensorGeometry(cameraModel)
  local modelId  = string.lower(cameraModel):gsub("^hasselblad ", "")
  local sensorId = supportedModels[string.lower(modelId or "")]
  return sensorId, sensorId and sensorGeometries[sensorId]
end


-- Default focus area sizes in the various FocusModes / FocusPointModes
-- this information is used to determine MF Focus Assist, Arbitrary Tracking and Subject Detected status
local defaultBoxSizes = {
    ["x2d ii 100c"] = {
        boxMfAssistON   = {w=750, h=1000 },
        boxMfAssistOFF  = {w=322, h= 434 },
        boxTrackingON   = {w=945, h=1239 },
        boxTrackingOFF  = {w=967, h=1304 },
        defaultBoxSizes = { {w=322,h=434}, {w=476,h=666}, {w=967,h=1304}, {w=945,h=1239}, {w=933,h=833}, {w=625,h=625} }
    }
}

-- Helper function to check whether a given focus box has a default size
local function isDefaultBoxSize(boxSizes, w, h)
  for _, size in ipairs(boxSizes) do
    if size.w == w and size.h == h then
      return true
    end
  end
  return false
end


-- This information is displayed in the 'Focus Information' area. It is derived, not EXIF tags.
local mfAssistStatus
local trackingStatus
local detectionStatus

-- Forward references
local getFocusInformation


--[[----------------------------------------------------------------------------
  public table
  getAfPoints(table photo, table metadata)

  Retrieve the autofocus points from the metadata of the photo.
------------------------------------------------------------------------------]]
function HasselbladDelegates.getAfPoints(photo, metadata)

  local result = {
    pointTemplates = DefaultDelegates.pointTemplates,
    points = {
    }
  }

  -- Reset status information
  mfAssistStatus  = nil
  trackingStatus  = nil
  detectionStatus = nil

  -- Get the photo dimensions to ensure the focus points are scaled properly for cropped output formats
  local orgPhotoWidth, orgPhotoHeight = DefaultPointRenderer.getNormalizedDimensions(photo, metadata)
  orgPhotoWidth  = tonumber(orgPhotoWidth)
  orgPhotoHeight = tonumber(orgPhotoHeight)

  -- Retrieve the relevant tag containing AF point information
  local focusPoint = ExifUtils.findValue(metadata, metaKeyAfPosition)
  if focusPoint then
    Log.logInfo("Hasselblad",
      string.format("Tag '%s' found: '%s'",
        metaKeyAfPosition, focusPoint))
  else
    -- no focus points found - handled on upper layers
    Log.logWarn("Hasselblad",
      string.format("Tag '%s' not found", metaKeyAfPosition))
    return nil
  end

  -- Extract (x,y) coordinates of center point and (w, h) dimensions of AF box
  local count = tonumber(Utils.get_nth_Word(focusPoint, 1, " "))
  local cx    = tonumber(Utils.get_nth_Word(focusPoint, 2, " "))
  local cy    = tonumber(Utils.get_nth_Word(focusPoint, 3, " "))
  local w     = tonumber(Utils.get_nth_Word(focusPoint, 4, " "))
  local h     = tonumber(Utils.get_nth_Word(focusPoint, 5, " "))

  -- Validate tag information
  if not count then
    Log.logError("Hasselblad",
      string.format("Invalid information found in '%s' tag", metaKeyAfPosition))
    return nil
  elseif not (cx and cy and w and h) then
    Log.logError("Hasselblad",
      string.format("Could not extract (x,y,w,h) information from '%s' tag", metaKeyAfPosition))
    return nil
  elseif count == 0 or w == 0 or h == 0 then
    Log.logWarn("Hasselblad",
      string.format("No focus points recorded in '%s' tag", metaKeyAfPosition))
    return nil
  end
  if count ~= 1 then
    Log.logWarn("Hasselblad",
      string.format("Unexpected situation encountered: number of focus points = '%s'", count))
    return nil
  end

  -- Obtain the sensor geometry of the camera used, as this is essential for normalizing the coordinates
  local cameraModel = photo:getFormattedMetadata("cameraModel")
  local _, geometry = getSensorGeometry(cameraModel)

  -- Convert AF coordinates to full-frame image pixels, then shift them into
  -- the centered crop's coordinate system for in-camera crop-format images.
  -- Lightroom develop crops retain full-frame dimensions and are applied later.
  local cropLeft = math.max(0, (geometry.width  - orgPhotoWidth)  / 2)
  local cropTop  = math.max(0, (geometry.height - orgPhotoHeight) / 2)
  local imgX = (geometry.offsetX + cx * geometry.width  / 10000) * geometry.width  / geometry.imageWidth - cropLeft
  local imgY = (geometry.offsetY + cy * geometry.height / 10000) * geometry.height / geometry.imageHeight - cropTop
  local boxW =                      w * geometry.width  / 10000 *  geometry.width  / geometry.imageWidth
  local boxH =                      h * geometry.height / 10000 *  geometry.height / geometry.imageHeight

  -- Determine various status information (we only use it later but we can easily access all the necessary data here)
  mfAssistStatus, trackingStatus, detectionStatus = getFocusInformation(cameraModel, w, h)

  -- Create focus frame and log success message
  Log.logInfo("Hasselblad",
    string.format("Focus point detected at [x=%s, y=%s, w=%s, h=%s]", imgX, imgY, boxW, boxH))

  FocusInfo.focusPointsDetected = true

  result = DefaultPointRenderer.createFocusFrame(imgX, imgY, boxW, boxH)

  return result
end


--[[----------------------------------------------------------------------------
  private string mfAssist, string statusTracking, string statusSubjectDetect
  getFocusInformation(string cameraModel, int w, int h))

  Use the size of the focus area to determine various status information.
  The status of MF Assist and Arbitrary Tracking, as well as whether a subject
  has been detected or not, determines the size of the AF box. These typical
  (or default) AF box sizes depend on the camera model used.
------------------------------------------------------------------------------]]
function getFocusInformation(cameraModel, w, h)
  local mfAssist, statusTracking, statusSubjectDetect

  local modelId  = string.lower(cameraModel):gsub("^hasselblad ", "")
  local boxSizes = defaultBoxSizes[modelId]

  -- Check whether this model has known default AF box sizes
  if boxSizes then

    -- MF Focus Assist setting
    if w == boxSizes.boxMfAssistON.w and h == boxSizes.boxMfAssistON.h then
      mfAssist = "Focus Indicator"
    else
      mfAssist = ExifUtils.metaValueNA
    end

    -- Arbitraty Tracking status
    if w == boxSizes.boxTrackingON.w and h == boxSizes.boxTrackingON.h then
      statusTracking = metaValueOnReady
    elseif w == boxSizes.boxTrackingOFF.w and h == boxSizes.boxTrackingOFF.h then
      statusTracking = ExifUtils.metaValueNA
    else
      statusTracking = metaValueOnActive
    end

    -- Has a subject been detected?
    if isDefaultBoxSize(boxSizes, w, h) then
      statusSubjectDetect = metaValueOff
    else
      statusSubjectDetect = "Subject Detected"
    end
  end

  return mfAssist, statusTracking, statusSubjectDetect
end


--[[----------------------------------------------------------------------------
  private table
  addInfo(string title, string key, table props, table metadata)

  Helper to create a single row for the info panel. Returns an empty row if
  the tag has no meaningful value.
------------------------------------------------------------------------------]]
local function addInfo(title, key, props, metadata)
  local f = LrView.osFactory()

  -- Helper function to create and populate the property corresponding to metadata key
  local function populateInfo(key)
    local value

    -- Handle pseudo-keys (entries that do not exist in EXIF but which are derived)
    if key == metaKeyMfAssist then
      value = mfAssistStatus
    elseif key == metaKeyTracking then
      value = trackingStatus
    elseif key == metaKeySubjectDetection then
      value = detectionStatus
    -- Handle keys that are present in EXIF
    elseif type(key) == "string" then
      value = ExifUtils.findValue(metadata, key)
    else
      -- type(key) == "table"
      value = ExifUtils.findFirstMatchingValue(metadata, key)
    end

    if not value then
      props[key] = ExifUtils.metaValueNA
    else
      -- everything else is the default case!
      props[key] = value
    end
  end

  -- Avoid issues with implicite followers that do not exist for all models
  if not key then return nil end

  -- Create and populate property with designated value
  populateInfo(key)

  -- Check if there is (meaningful) content to add
  if not props[key] or Utils.arrayKeyOf({"N/A", "Off"}, props[key]) then
    -- we won't display any "empty" entries - return empty row
    return FocusInfo.emptyRow()
  end

  -- compose the row to be added
  local result = FocusInfo.addRow(title, props[key])

  if key == metaKeyFocusMode and props[key] == "MF" then
    -- add Focus Assist status
    return f:column { fill = 1, spacing = 2, result,
      addInfo("MF Assist", metaKeyMfAssist, props, metadata)
    }
  elseif key == metaKeyFocusPointMode and props[key] == "Expanded Spot" and props[metaKeyFocusMode] == "AF-C" then
    -- add Tracking status
    return f:column { fill = 1, spacing = 2, result,
      addInfo("Arbitrary Tracking", metaKeyTracking, props, metadata)
    }
  else
    -- add row as composed
    return result
  end
end

--[[----------------------------------------------------------------------------
  public boolean
  modelSupported(string model)

  Indicate whether the given camera model is supported or not.
------------------------------------------------------------------------------]]
function HasselbladDelegates.modelSupported(cameraModel)
  local _, geometry = getSensorGeometry((string.lower(cameraModel)))
  return geometry ~= nil
end

--[[----------------------------------------------------------------------------
  public boolean
  makerNotesFound(table photo, table metadata)

  Check if the metadata for the current photo includes a 'Makernotes' section.
------------------------------------------------------------------------------]]
function HasselbladDelegates.makerNotesFound(_photo, metadata)

  local makerNotes = ExifUtils.findValue(metadata, metaKeyMakerNotes)
  if not makerNotes then
    Log.logWarn("Hasselblad",
      string.format("Tag '%s' not found", metaKeyMakerNotes))
  end
  return (makerNotes ~= nil)
end

--[[----------------------------------------------------------------------------
  public boolean
  manualFocusUsed(table photo, table metadata)

  Indicate whether the photo was taken using manual focus.
------------------------------------------------------------------------------]]
function HasselbladDelegates.manualFocusUsed(_photo, metadata)
  local focusMode = ExifUtils.findValue(metadata, metaKeyFocusMode)
  return (focusMode == "MF")
end

--[[----------------------------------------------------------------------------
  public table
  function getImageInfo(table photo, table props, table metadata)

  Called by FocusInfo.createInfoView to append maker-specific entries to the
  'Image Information' section, if applicable; otherwise, returns an empty column.
------------------------------------------------------------------------------]]
function HasselbladDelegates.getImageInfo(_photo, _props, _metadata)
  local imageInfo
  return imageInfo
end

--[[----------------------------------------------------------------------------
  public table
  function getShootingInfo(table photo, table props, table metadata)

  Called by FocusInfo.createInfoView to append maker-specific entries to the
  'Shooting Information' section, if applicable; otherwise, returns an empty column.
------------------------------------------------------------------------------]]
function HasselbladDelegates.getShootingInfo(_photo, props, metadata)
  local shootingInfo
  return shootingInfo
end

--[[----------------------------------------------------------------------------
  public table
  function getFocusInfo(table photo, table props, table metadata)

  Called by FocusInfo.createInfoView to fetch the items in the 'Focus Information'
  section (which is entirely maker-specific).
------------------------------------------------------------------------------]]
function HasselbladDelegates.getFocusInfo(_photo, props, metadata)
  local f = LrView.osFactory()
  local focusInfo = f:column {
    fill = 1,
    spacing = 2,
    addInfo("Focus Mode",        metaKeyFocusMode         , props, metadata),
    addInfo("Focus Point Mode",  metaKeyFocusPointMode    , props, metadata),
    addInfo("Subject Detection", metaKeySubjectDetection  , props, metadata),
  }
  return focusInfo
end

return HasselbladDelegates
