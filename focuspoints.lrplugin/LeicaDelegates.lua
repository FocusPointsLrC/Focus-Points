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

  Reverse-engineered from Leica Q3 DNG files using ExifTool 13.59 (2026-08-12).

  Key MakerNotes tags (group "Panasonic Leica 5", accessed via -u exiftool flag):

  0x044d  AF point center, two normalized floats X Y (0.0–1.0, top-left origin).
          Sentinel value -1/1024 (-0.0009765625) for both X and Y indicates MF.

  0x0404  4-byte AF configuration [b0, b1, b2, b3]:
            b3 (word 4) = Focus mode  : 0=MF, 1=AF-S, 2=AF-C, 4=iAF
            b2 (word 3) = Detection   : 0=none, 1=People, 2=Face+Eye, 3=Animal, 4=Animal+Eye
            b1 (word 2) = Macro mode  : 0=normal, 1=Macro
            b0 (word 1) = Area mode   : 0=MF, 9=Tracking, 15=Spot or Large, 16=Multi Zone

  0x041e  AF area selector, single int: 0=Tracking, 1=Spot, 4=Large or Multi Zone.
          Used together with 0x0404 b0 to distinguish Spot from Large (both have b0=15).
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

-- AF configuration: [area_byte, 0, detection_byte, focus_mode_byte]
local metaKeyAfConfig      = "Panasonic Leica 5 0x0404"

-- AF area selector: 0=Tracking, 1=Spot, 4=Large/Multi Zone
local metaKeyAfArea        = "Panasonic Leica 5 0x041e"

-- Focus distance and optics
local metaKeyFocusDistance  = "Focus Distance"
local metaKeyDepthOfField   = "Depth Of Field"
local metaKeyHyperfocalDist = "Hyperfocal Distance"

-- Human-readable lookup tables for 0x0404 bytes
local FOCUS_MODE_NAMES = { [1] = "AF-S", [2] = "AF-C", [4] = "iAF" }
local DETECTION_NAMES  = { [1] = "People", [2] = "Face + Eye", [3] = "Animal", [4] = "Animal + Eye" }

--[[----------------------------------------------------------------------------
  local function
  parseAfConfig(table metadata) -> int b0, int b1, int b2, int b3

  Parse tag 0x0404 into its four bytes.
  Returns 0,0,0,0 if the tag is absent.
------------------------------------------------------------------------------]]
local function parseAfConfig(metadata)
  local config = ExifUtils.findValue(metadata, metaKeyAfConfig)
  if not config then return 0, 0, 0, 0 end
  local b0 = tonumber(Utils.get_nth_Word(config, 1, " ")) or 0
  local b1 = tonumber(Utils.get_nth_Word(config, 2, " ")) or 0
  local b2 = tonumber(Utils.get_nth_Word(config, 3, " ")) or 0
  local b3 = tonumber(Utils.get_nth_Word(config, 4, " ")) or 0
  return b0, b1, b2, b3
end

--[[----------------------------------------------------------------------------
  local function
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

  Returns true if the photo was taken with manual focus.
  Primary check: byte 3 of 0x0404 == 0 (MF mode).
  Fallback (older firmware / tag absent): sentinel value -1/1024 in 0x044d.
------------------------------------------------------------------------------]]
function LeicaDelegates.manualFocusUsed(_photo, metadata)
  if string.find(DefaultDelegates.cameraModel, "leica m", 1, true) then
    return true
  end
  local _, _, _, b3 = parseAfConfig(metadata)
  if b3 ~= 0 then
    -- AF mode byte is known and non-zero → autofocus was used
    return false
  end
  -- b3 == 0 could mean MF or missing tag; confirm via 0x044d sentinel
  local afPoint = ExifUtils.findValue(metadata, metaKeyAfPoint)
  if not afPoint then return true end
  local x = tonumber(Utils.get_nth_Word(afPoint, 1, " "))
  return (x == nil or x < 0)
end

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

  local result = DefaultPointRenderer.createFocusFrame(x, y)

  -- When subject detection was active, render the AF point as a face/subject box (yellow)
  local _, _, b2, _ = parseAfConfig(metadata)
  if b2 > 0 then
    Log.logInfo("Leica", string.format("Subject detection active (mode %d) — rendering as face point", b2))
    result.points[1].pointType = DefaultDelegates.POINTTYPE_FACE
  end

  return result
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

  Returns the "Focus Information" panel content.
  Displays: Focus Distance, Focus Mode, AF Area, Detection (when active).
------------------------------------------------------------------------------]]
function LeicaDelegates.getFocusInfo(_photo, props, metadata)
  local f = LrView.osFactory()

  local b0, b1, b2, b3 = parseAfConfig(metadata)

  -- Determine AF Area string
  local areaStr
  if b0 == 9 then
    areaStr = "Tracking"
  elseif b0 == 16 then
    areaStr = "Multi Zone"
  elseif b0 == 15 then
    local areaTag = ExifUtils.findValue(metadata, metaKeyAfArea)
    areaStr = (tonumber(areaTag) == 1) and "Spot" or "Large"
  end

  return f:column {
    fill = 1,
    spacing = 2,
    addInfo("Focus Distance",    metaKeyFocusDistance,  props, metadata),
    addInfo("Depth of Field",    metaKeyDepthOfField,   props, metadata),
    addInfo("Hyperfocal Distance", metaKeyHyperfocalDist, props, metadata),
    b3 > 0 and FocusInfo.addRow("Focus Mode", FOCUS_MODE_NAMES[b3] or ("mode " .. b3)) or FocusInfo.emptyRow(),
    areaStr         and FocusInfo.addRow("AF Area",    areaStr)                           or FocusInfo.emptyRow(),
    b2 > 0          and FocusInfo.addRow("Detection",  DETECTION_NAMES[b2] or ("type " .. b2)) or FocusInfo.emptyRow(),
    b1 == 1         and FocusInfo.addRow("Focus Range", "Macro")                          or FocusInfo.emptyRow(),
  }
end

return LeicaDelegates
