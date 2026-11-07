--[[
  Copyright © 2026 Yves Pralong

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

  Modified file — original work © Whizzbang Inc, ongoing maintenance © 2026 Karsten Gieselmann
--]]

--[[----------------------------------------------------------------------------
  LeicaDelegates.lua

  Delegate functions for Leica cameras with phase-detection AF.
  In order to include the relevant tags in metadata, the camera needs to support Exif 3.0.
  M-series cameras (M10, M11) are manual focus only and are not supported.
  https://github.com/FocusPointsLrC/Focus-Points/discussions/413

  Reverse-engineered from 93+ Leica Q3 DNG files (2026-08-12/19), covering all AF
  modes: Spot, Field, Zone, Multi-Field, Tracking; all detection modes; Macro; portrait
  orientation (Rotate 90 CW and 270 CW); AF-C on moving subjects; and failed
  detection. Validated with ExifTool 13.59.

  Key MakerNotes tags (group "Panasonic Leica 5", accessed via -u exiftool flag):

  0x044d  AF point center, two normalized floats X Y (0.0–1.0, top-left origin).
          Always in sensor (landscape) coordinates regardless of camera orientation.
          Sentinel value -1/1024 (-0.0009765625) for both X and Y indicates MF or
          failed subject detection.
          Special case: FocusDistance = 65.535 m means focus at infinity (AF-C).

  0x0404  4-byte AF configuration [b0, b1, b2, b3]:
            b3 (word 4) = Focus mode  : 0=MF, 1=AF-S, 2=AF-C, 4=iAF
            b2 (word 3) = Detection   : 0=none, 1=People, 2=Face+Eye, 3=Animal, 4=Animal+Eye
            b1 (word 2) = Macro mode  : 0=normal, 1=Macro
            b0 (word 1) = Area mode   : 0=MF, 9=Tracking, 15=Spot or Field, 16=Zone or Multi-Field

  0x041e  AF area selector, single int: 0=Tracking, 1=Spot, 2=Zone, 4=Field or Multi-Field.
          Used together with 0x0404 b0 to distinguish Spot from Field (both b0=15), and
          Zone from Multi-Field (both b0=16).

  Note: The Q3 stores only ONE AF point per photo regardless of area mode. Field, Zone
  and Multi-Field modes record the final focus position within the zone, not the zone size.
------------------------------------------------------------------------------]]
local LeicaDelegates = {}

-- List of supported models
local modelsWithLeicaMetadata = {
  "cl",
  "q", "q2", "q3", "q3 43",
  "sl", "sl2", "sl2-s", "sl3", "sl3-s", "sl3-p",
  "t", "tl", "tl2",
}

local modelsWithPanasonicMetadata = {
  "c", "cam-dc25", "c-lux", "d-lux", "v-lux"
}

-- Imported LR namespaces
local LrView                  = import 'LrView'

-- Required Lua definitions
local DefaultDelegates        = require 'DefaultDelegates'
local DefaultPointRenderer    = require 'DefaultPointRenderer'
local ExifUtils               = require 'ExifUtils'
local FocusInfo               = require 'FocusInfo'
local Log                     = require 'Log'
local Utils                   = require 'Utils'

-- Tag indicating Leica MakerNotes are present (unique to Leica)
local metaKeyMakerNotes       = "Film Mode"

-- AF-relevant tags
local metaKeyFocusMode        = "Focus Mode"
local metaKeyFocusRange       = "Focus Range"
local metaKeyAfMode           = "AF Mode"
local metaKeyAfModeSelector   = "AF Mode Selector"
local metaKeyAfDetection      = "AF Detection"
local metaKeyAfPointPosition  = "AF Point Position"
local metaKeyFacesDetected    = "Faces Detected"

-- Focus distance and optics
local metaKeyFocusDistance    = "Focus Distance"
local metaKeyDepthOfField     = "Depth Of Field"
local metaKeyHyperfocalDist   = "Hyperfocal Distance"

-- Image and Shooting Information relevant tags
local metaKeyFilmMode         = "Film Mode"
local metaKeySoftware         = "Software"

-- Relevant metadata values
local metaValAfSpotField       = "Spot/Field"
local metaValAfZoneMultiField  = "Zone/Multi-Field"
local metaValSpot              = "Spot"
local metaValZone              = "Zone"
local metaValField             = "Field"
local metaValMultiField        = "Multi-Field"
local metaValFieldOrMultiField = "Field or Multi-Field"

--[[----------------------------------------------------------------------------
  public table
  getAfPoints(table photo, table metadata)

  Returns focus point data for rendering.

  The AF center is read from 0x044d (two normalized floats X Y, 0.0–1.0).
  When subject/face/animal detection is active (0x0404 byte 2 > 0), the point
  is rendered as POINTTYPE_FACE (yellow) because 0x044d is where the camera
  focused on the detected subject.
------------------------------------------------------------------------------]]
function LeicaDelegates.getAfPoints(photo, metadata)

  local orgPhotoWidth, orgPhotoHeight = DefaultPointRenderer.getNormalizedDimensions(photo, metadata)

  local afPoint = ExifUtils.findValue(metadata, metaKeyAfPointPosition)
  if not afPoint then
    Log.logWarn("Leica",
      string.format("Tag '%s' not found", metaKeyAfPointPosition))
    return nil
  end

  Log.logInfo("Leica",
    string.format("Tag '%s' found: '%s'", metaKeyAfPointPosition, afPoint))

  local focusX = Utils.get_nth_Word(afPoint, 1, " ")
  local focusY = Utils.get_nth_Word(afPoint, 2, " ")

  if not (focusX and focusY) then
    Log.logError("Leica",
      string.format("Could not extract (x,y) from '%s': '%s'", metaKeyAfPointPosition, afPoint))
    return nil
  end

  local fx = tonumber(focusX)
  local fy = tonumber(focusY)

  -- Sentinel -1/1024 means MF — should not reach here, but guard anyway
  if fx == nil or fx < 0 or fy == nil or fy < 0 then
    Log.logInfo("Leica", "Sentinel coordinates in 0x044d — manual focus, skipping AF point")
    return nil
  end

  local x = math.floor(orgPhotoWidth  * fx)
  local y = math.floor(orgPhotoHeight * fy)

  Log.logInfo("Leica", string.format("Focus point at [x=%d, y=%d]", x, y))

  FocusInfo.focusPointsDetected = true

  return DefaultPointRenderer.createFocusFrame(x, y)
end

--[[----------------------------------------------------------------------------
  private string
  getExactAfMode(string afMode, afModeSelector)

  For compound AF metering mode settings, apply the mode selector to identify
  the exact mode that was used to capture the photo
------------------------------------------------------------------------------]]
local function getAfExactMode(afMode, afModeSelector)
  local result = afMode
  if afMode == metaValAfSpotField then
    if afModeSelector == metaValFieldOrMultiField then
      result = metaValField
    else
      result = afModeSelector
    end
  elseif afMode == metaValAfZoneMultiField then
    if afModeSelector == metaValFieldOrMultiField then
      result = metaValMultiField
    else
      result = afModeSelector
    end
  end
  return result
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
    if type(key) == "string" then
      value = ExifUtils.findValue(metadata, key)
    else
      -- type(key) == "table"
      value = ExifUtils.findFirstMatchingValue(metadata, key)
    end

    if not value then
      props[key] = ExifUtils.metaValueNA

    elseif key == metaKeyAfMode and title ~= "- Setting" then
      -- simplify compound AF mode setting, if applicable
      local modeSelector = ExifUtils.findValue(metadata, metaKeyAfModeSelector)
      if modeSelector then
        props[key] = getAfExactMode(value, modeSelector)
      else
        props[key] = value
      end

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

  if title == "- Setting" or title == " - Selector" then
    -- Special handling of output for AF Mode information in cases where AF mode selector is relevant
    -- This is only prelimininary for testing and will be removed from production code
    local originalAfMode = ExifUtils.findValue(metadata, key)
    if not (originalAfMode == metaValAfSpotField or originalAfMode == metaValAfZoneMultiField) then
      return FocusInfo.emptyRow()
    else
      -- add row as composed
      return result
    end
  elseif key == metaKeyAfDetection and props[key]:match("^Human") then
    -- add information on related tag
    return f:column { fill = 1, spacing = 2, result,
      addInfo("Faces Detected", metaKeyFacesDetected, props, metadata)
    }
  elseif key == metaKeyFilmMode and props[key]:match("^%s*$") then
    -- empty (all blanks) FilmModes tag won't be displayed
    return FocusInfo.emptyRow()
  elseif key == metaKeySoftware and props[key]:match("Adobe") then
    -- Adobe Software can overwrite the original 'Software' value containing the firmware version
    -- In this case, the information will not be printed
    return FocusInfo.emptyRow()
  else
    -- add row as composed
    return result
  end
end

--[[----------------------------------------------------------------------------
  private string
  extractModelType(string modelName)

  Extracts the series/model type from the module name. Examples:
  LEICA SL3-P       -> SL3-P
  LEICA D-LUX 8     -> D-LUX
  D-LUX (Typ 109)   -> D-LUX
  LEICA X (Typ 113) -> X
------------------------------------------------------------------------------]]
local function extractModelType(str)
    -- ^%s*           : Start of string, ignoring leading whitespace
    -- (?:Leica%s+)?  : Matched via Lua's optional capture logic below:
    -- Matching optional "Leica " prefix, then capturing the next word token [%w%-]+
    local modelType = str:match("^%s*[%f[%w]Leica%s+]*([%w%-]+)")
    -- Handles case-insensitive check for "Leica" at the start
    if str:match("^%s*[Ll][Ee][Ii][Cc][Aa]%s+") then
      return str:match("^%s*%a+%s+([%w%-]+)")
    else
      return str:match("^%s*([%w%-]+)")
    end
end

--[[----------------------------------------------------------------------------
  public boolean
  modelSupported(string model)

  Returns true if the camera model is supported and uses Leica metadata
------------------------------------------------------------------------------]]
function LeicaDelegates.modelSupported(currentModel)
  local model = string.match(string.lower(currentModel), "leica%s+([%w%s%-]+)")
  for _, m in ipairs(modelsWithLeicaMetadata) do
    if m == model then
      return true
    end
  end
  return false
end

--[[----------------------------------------------------------------------------
  public boolean
  hasPanasonicMetadata(string model)

  Returns true if the camera model is supported and uses Panasonic metadata
------------------------------------------------------------------------------]]
function LeicaDelegates.hasPanasonicMetadata(currentModel)
  local model = extractModelType(string.lower(currentModel))
  for _, m in ipairs(modelsWithPanasonicMetadata) do
    if m == model then
      return true
    end
  end
  return false
end

--[[----------------------------------------------------------------------------
  public boolean
  makerNotesFound(table photo, table metadata)

  Check if Leica MakerNotes are present by looking for the "Film Mode" tag
  which is unique to Leica MakerNotes.
------------------------------------------------------------------------------]]
function LeicaDelegates.makerNotesFound(_photo, metadata)
  local result = ExifUtils.findValue(metadata, metaKeyMakerNotes)
  if not result then
    Log.logWarn("Leica", string.format("Tag '%s' not found — MakerNotes absent", metaKeyMakerNotes))
  end
  return (result ~= nil)
end

--[[----------------------------------------------------------------------------
  public boolean
  manualFocusUsed(table photo, table metadata)

  Returns true if the photo was taken with manual focus.
  Primary check: byte 3 of 0x0404 == 0 (MF mode).
  Fallback (older firmware / tag absent): sentinel value -1/1024 in 0x044d.
------------------------------------------------------------------------------]]
function LeicaDelegates.manualFocusUsed(_photo, metadata)
  local focusMode = ExifUtils.findValue(metadata, metaKeyFocusMode)
  local afPoint =   ExifUtils.findValue(metadata, metaKeyAfPointPosition)
  return focusMode and focusMode == "MF" or
           afPoint and   afPoint == "n/a"
end

--[[----------------------------------------------------------------------------
  public table
  getImageInfo(table photo, table props, table metadata)
------------------------------------------------------------------------------]]
function LeicaDelegates.getImageInfo(_photo, _props, _metadata)
  return nil
end

--[[----------------------------------------------------------------------------
  public table
  getShootingInfo(table photo, table props, table metadata)
------------------------------------------------------------------------------]]
function LeicaDelegates.getShootingInfo(_photo, props, metadata)
  local f = LrView.osFactory()
  local shootingInfo = f:column {
    fill = 1,
    spacing = 2,
    addInfo("Film Mode",             metaKeyFilmMode, props, metadata),
    addInfo("Body Firmware Version", metaKeySoftware, props, metadata),
  }
  return shootingInfo
end

--[[----------------------------------------------------------------------------
  public table
  getFocusInfo(table photo, table props, table metadata)

  Returns the "Focus Information" panel content.
  Displays: Focus Distance, Focus Mode, AF Area, Detection (when active).
------------------------------------------------------------------------------]]
function LeicaDelegates.getFocusInfo(_photo, props, metadata)
  local f = LrView.osFactory()
  local focusInfo = f:column {
    fill = 1,
    spacing = 2,
    addInfo("Focus Mode",          metaKeyFocusMode,        props, metadata),
    addInfo("Focus Range",         metaKeyFocusRange,       props, metadata),
    addInfo("AF Mode",             metaKeyAfMode,           props, metadata),
    --[[ for prelimininary use until AF modes are settled
    addInfo("- Setting",           metaKeyAfMode,           props, metadata),
    addInfo("- Selector",          metaKeyAfModeSelector,   props, metadata),
    --]]
    addInfo("AF Detection",        metaKeyAfDetection,      props, metadata),
    FocusInfo.addSpace(),
    FocusInfo.addSeparator(),
    FocusInfo.addSpace(),
    addInfo("Focus Distance",      metaKeyFocusDistance,    props, metadata),
    addInfo("Depth of Field",      metaKeyDepthOfField,     props, metadata),
    addInfo("Hyperfocal Distance", metaKeyHyperfocalDist,   props, metadata),
  }
  return focusInfo
end

return LeicaDelegates
