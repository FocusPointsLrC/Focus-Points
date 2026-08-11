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

  Delegate functions for Leica cameras (Q2, Q3, SL2, SL3, CL) with phase-detection AF.
  M-series cameras (M10, M11) are manual focus only and are not supported.

  AF position is read from MakerNotes tag "Panasonic Leica 5 0x044d" which contains
  normalized X,Y coordinates (0.0–1.0) of the AF point center. Reverse-engineered
  from Leica Q3 DNG files using ExifTool 13.59 (2026-08-11).
------------------------------------------------------------------------------]]
local LeicaDelegates = {}

-- Imported LR namespaces
local LrView               = import 'LrView'

-- Required Lua definitions
local DefaultDelegates     = require 'DefaultDelegates'
local DefaultPointRenderer = require 'DefaultPointRenderer'
local ExifUtils            = require 'ExifUtils'
local FocusInfo            = require 'FocusInfo'
local Log                  = require 'Log'
local Utils                = require 'Utils'

-- Tag indicating Leica MakerNotes are present (unique to Leica)
local metaKeyMakerNotes    = "Film Mode"

-- AF position: normalized X Y center of the focus point (0.0–1.0)
local metaKeyAfPoint       = "Panasonic Leica 5 0x044d"

-- Face detection
local metaKeyFacesDetected = "Faces Detected"

-- Focus / shooting info
local metaKeyFocusDistance = "Focus Distance"

--[[----------------------------------------------------------------------------
  local function
  addInfo(string title, string key, table props, table metadata)

  Helper to create a single row for the info panel. Returns nil if the tag
  has no meaningful value (n/a, none, or missing).
------------------------------------------------------------------------------]]
local function addInfo(title, key, props, metadata)
  if not key then return nil end
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

  Returns false for Leica M-series (manual focus only). All other Leica models
  with phase-detection AF (Q2, Q3, SL2, SL3, CL, etc.) return true.
------------------------------------------------------------------------------]]
function LeicaDelegates.modelSupported(model)
  if string.find(model, "leica m", 1, true) then
    Log.logInfo("Leica", "M-series camera detected — manual focus only, not supported")
    return false
  end
  return true
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

  Returns true if the photo was taken with manual focus. For Leica M-series
  this is always true. For other models, the absence of the AF point tag
  indicates manual focus was used.
------------------------------------------------------------------------------]]
function LeicaDelegates.manualFocusUsed(_photo, metadata)
  if string.find(DefaultDelegates.cameraModel, "leica m", 1, true) then
    return true
  end
  return ExifUtils.findValue(metadata, metaKeyAfPoint) == nil
end

--[[----------------------------------------------------------------------------
  public table
  getAfPoints(table photo, table metadata)

  Returns focus point data for rendering. Reads the AF center position from
  "Panasonic Leica 5 0x044d" which contains two space-separated normalized
  floats: X Y (each in range 0.0–1.0, origin at top-left).
------------------------------------------------------------------------------]]
function LeicaDelegates.getAfPoints(photo, metadata)

  local orgPhotoWidth, orgPhotoHeight = DefaultPointRenderer.getNormalizedDimensions(photo, metadata)

  local afPoint = ExifUtils.findValue(metadata, metaKeyAfPoint)
  if not afPoint then
    Log.logWarn("Leica", string.format("Tag '%s' not found", metaKeyAfPoint))
    return nil
  end

  Log.logInfo("Leica", string.format("Tag '%s' found: '%s'", metaKeyAfPoint, afPoint))

  local focusX = Utils.get_nth_Word(afPoint, 1, " ")
  local focusY = Utils.get_nth_Word(afPoint, 2, " ")

  if not (focusX and focusY) then
    Log.logError("Leica", string.format("Could not extract (x,y) from '%s': '%s'", metaKeyAfPoint, afPoint))
    return nil
  end

  local x = math.floor(tonumber(orgPhotoWidth)  * tonumber(focusX))
  local y = math.floor(tonumber(orgPhotoHeight) * tonumber(focusY))

  Log.logInfo("Leica", string.format("Focus point at [x=%d, y=%d]", x, y))

  FocusInfo.focusPointsDetected = true

  return DefaultPointRenderer.createFocusFrame(x, y)
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
function LeicaDelegates.getShootingInfo(_photo, _props, _metadata)
  return nil
end

--[[----------------------------------------------------------------------------
  public table
  getFocusInfo(table photo, table props, table metadata)

  Returns the "Focus Information" section with focus distance and face detection.
------------------------------------------------------------------------------]]
function LeicaDelegates.getFocusInfo(_photo, props, metadata)
  local f = LrView.osFactory()

  local focusInfo = f:column {
    fill = 1,
    spacing = 2,
    addInfo("Focus Distance",  metaKeyFocusDistance, props, metadata),
    addInfo("Faces Detected",  metaKeyFacesDetected, props, metadata),
  }
  return focusInfo
end

return LeicaDelegates
