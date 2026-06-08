--[[
  Copyright © 2026 Karsten Gieselmann

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
  Straighten.lua

  Purpose of this module:
  Utility functions to 'Straighten Image'
  For use with both batch-mode processing and individual straightening via the UI
------------------------------------------------------------------------------]]
local Straighten = {}

-- Imported LR namespaces
local LrApplication         = import  'LrApplication'
local LrPrefs               = import  'LrPrefs'

-- Required Lua definitions
local Crop                  = require 'Crop'
local ExifUtils             = require 'ExifUtils'

-- List of camera makers that in principle support a RollAngle tag with consistent information
-- Some only for recent models e.g. Nikon, others since decades e.g. Canon, Olympus/OM
local supportedMakes = {
  'canon', 'nikon', 'nikon corporation', 'fujifilm', 'olympus', 'om digital solutions',
  'pentax', 'ricoh', 'panasonic'
}

local function makeSupported(make)
  -- Check whether 'make' is listed in 'supportedMakes"
  for _, m in ipairs(supportedMakes) do
    if (m == make) then
      return true
    end
  end
  return false
end

local prefs   = LrPrefs.prefsForPlugin( nil )

-- @TODO Create file headers for documentation !!

function Straighten.calculateStraightenAngle(rollAngle)
    -- Compute correction with respect to the nearest multiple of 90°
    -- Required because Lightroom handles roll angles of +/-90° as vertical orientation with '0' rotation
    if not rollAngle then return nil end
    -- Normalize to range [-180, 180)
    local rollAngle = ((rollAngle + 180) % 360) - 180
    -- Find nearest multiple of 90°
    local baseOrientation = math.floor((rollAngle / 90) + 0.5) * 90
    -- Compute residual correction
    if prefs.straightenApplyBias then
      return baseOrientation - rollAngle + prefs.straightenBias
    else
      return baseOrientation - rollAngle
    end
  end


function Straighten.getRollAngleCW(photo, metadata)
  -- Retrieve the 'RollAngle' tag from the photo's metadata and return its value in clockwise (CW) degrees.
  -- Some camera makers record the camera roll angle clockwise (CW), while others record it counterclockwise (CCW).
  local SUCCESS = 0
  local WARNING = 1
  local ERROR   = 2
  local make = photo:getFormattedMetadata("cameraMake")
  local rollAngleValue, rollAngle, rc

  if not makeSupported(string.lower(make)) then
    return 0, WARNING, string.format("%s not supported", make)
  else
    -- Try to retrieve roll angle information from metadata (in memory or on disk)
    if metadata then
      rollAngleValue = ExifUtils.findValue(metadata, "Roll Angle")
    else
      rollAngleValue, rc = ExifUtils.getBinaryValue(photo, "RollAngle")
      if rc ~= 0 then
        return 0, ERROR, "Unable to read metadata (ExifTool rc=" .. rc .. ")"
      end
    end

    -- Normalize roll angle information
    if rollAngleValue then
      rollAngle = tonumber(rollAngleValue)
      if rollAngle then
        make = string.lower(make)
        if  make == 'fujifilm' or (string.find(make, "nikon", 1, true)) then
          -- makes that record angle value clockwise
          rollAngle = rollAngle *  1
        else
          -- makes that record angle value counterclockwise
          rollAngle = rollAngle * -1
        end
        return rollAngle, SUCCESS, string.format("RollAngle %7.2f°. ", rollAngle)
      else
        return 0, WARNING, string.format(
          "Invalid RollAngle information found in metadata: %s", rollAngleValue)
      end
    else
      return 0, WARNING, "RollAngle information not available"
    end
  end
end

function Straighten.straightenImage(photo, angle, text)
  local crop = Crop.ofPhoto(photo)
  if crop then
    crop = Crop.adjustAngle (crop, angle)
    local catalog = LrApplication.activeCatalog()
    catalog:withWriteAccessDo("Straighten Images", function()
      Crop.apply (crop, photo, text or "Straighten Image")
    end)
    return true
  else
    return false
  end
end

function Straighten.hasTransform(settings)
  -- Returns whether an Upright or Transform operation has been performed on the photo
  return
    (settings.PerspectiveUpright    or 0) ~=   0 or
    (settings.PerspectiveVertical   or 0) ~=   0 or
    (settings.PerspectiveHorizontal or 0) ~=   0 or
    (settings.PerspectiveRotate     or 0) ~=   0 or
    (settings.PerspectiveAspect     or 0) ~=   0 or
    (settings.PerspectiveScale      or 0) ~= 100 or
    (settings.PerspectiveX          or 0) ~=   0 or
    (settings.PerspectiveY          or 0) ~=   0
end


return Straighten
