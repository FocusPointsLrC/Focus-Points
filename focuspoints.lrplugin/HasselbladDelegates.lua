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

  @TODO Add the Hasselblad AF specs
------------------------------------------------------------------------------]]
local HasselbladDelegates = {}

-- Imported LR namespaces
local LrView               = import  'LrView'

-- Required Lua definitions
local DefaultDelegates     = require 'DefaultDelegates'
local DefaultPointRenderer = require 'DefaultPointRenderer'
local ExifUtils            = require 'ExifUtils'
local FocusInfo            = require 'FocusInfo'
local Log                  = require 'Log'
local Utils                = require 'Utils'

-- List of supported models is sorted by date / Pentax version
-- to potentially support handling of changes in tag usage across models / Pentax versions
local supportedModels = {
    ["x2d ii 100c"]           = "100c",
    ["x2d 100c"]              = "100c",
    ["cfv 100c/907x"]         = "100c",
    ["hasselblad x1d ii 50c"] = "50c",
    ["hasselblad x1d"]        = "50c",
}

-- AF-relevant tags
local metaKeyFocusMode                   = "Focus Mode"
local metaKeyFocusPointMode              = "Focus Point Mode"
local metaKeyAfPosition                  = "Focus Area"

-- Tag indicating that makernotes / AF section exists
local metaKeyMakerNotes                  = metaKeyFocusMode

-- Relevant metadata values
local metaValueOn                        = "On"
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

local getSensorGeometry

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

  -- Get photo dimensions for proper scaling
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
  elseif count == 0 then
    Log.logError("Hasselblad",
      string.format("No focus points recorded in '%s' tag", metaKeyAfPosition))
    return nil
  elseif not (cx and cy and w and h) then
    Log.logError("Hasselblad",
      string.format("Could not extract (x,y,w,h) information from '%s' tag", metaKeyAfPosition))
    return nil
  end
  if count ~= 1 then
    Log.logWarn("Hasselblad",
      string.format("Unexpected situation encountered: number of focus points = '%s'", count))
    return nil
  end

  local cameraModel = photo:getFormattedMetadata("cameraModel")
  local _, geometry = getSensorGeometry(string.lower(cameraModel))

  local imgX = (geometry.offsetX + cx * geometry.width  / 10000) * geometry.width  / geometry.imageWidth
  local imgY = (geometry.offsetY + cy * geometry.height / 10000) * geometry.height / geometry.imageHeight
  local boxW =                      w * geometry.width  / 10000 *  geometry.width  / geometry.imageWidth
  local boxH =                      h * geometry.height / 10000 *  geometry.height / geometry.imageHeight

  Log.logInfo("Hasselblad",
    string.format("Focus point detected at [x=%s, y=%s, w=%s, h=%s]", imgX, imgY, boxW, boxH))

  FocusInfo.focusPointsDetected = true

  result = DefaultPointRenderer.createFocusFrame(imgX, imgY, boxW, boxH)

  return result
end

function getSensorGeometry(cameraModel)
    local sensorId = supportedModels[string.lower(cameraModel or "")]
    return sensorId, sensorId and sensorGeometries[sensorId]
end


--[[----------------------------------------------------------------------------
  private table
  addInfo(string title, string key, table props, table metadata)

  Helper to create a single row for the info panel. Returns an empty row if
  the tag has no meaningful value.
------------------------------------------------------------------------------]]
local function addInfo(title, key, props, metadata)
  if not key then return FocusInfo.emptyRow() end
  local value = ExifUtils.findValue(metadata, key)
  if not value then
    props[key] = ExifUtils.metaValueNA
    return FocusInfo.emptyRow()
  end
  props[key] = value
  return FocusInfo.addRow(title, value)
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

  -- Create the "Focus Information" section
  local focusInfo = f:column {
      fill = 1,
      spacing = 2,
      addInfo("Focus Mode",        metaKeyFocusMode         , props, metadata),
      addInfo("Focus Point Mode",  metaKeyFocusPointMode    , props, metadata),
      }
  return focusInfo
end

return HasselbladDelegates
