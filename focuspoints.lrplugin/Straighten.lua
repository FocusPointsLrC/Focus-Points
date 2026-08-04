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

-- Straighten.getRollAngleCW() return codes
Straighten.SUCCESS = 0
Straighten.WARNING = 1
Straighten.ERROR   = 2

--[[
   List of camera makers that in principle support a RollAngle tag with consistent information
   Some only for recent models e.g. Nikon, others since decades e.g. Canon, Olympus/OM
--]]
local supportedMakes = {
  'canon', 'nikon', 'nikon corporation', 'fujifilm', 'olympus', 'om digital solutions',
  'pentax', 'ricoh', 'panasonic'
}

local function makeSupported(make)
  -- Helper to check whether 'make' is listed in 'supportedMakes"
  for _, m in ipairs(supportedMakes) do
    if (m == make) then
      return true
    end
  end
  return false
end

local prefs   = LrPrefs.prefsForPlugin( nil )


--[[----------------------------------------------------------------------------
  public float
  calculateStraightenAngle(float rollAngle)

  Calculate the roll angle compensation with respect to the nearest multiple of 90°.
  This is necessary because Lightroom translates roll angles of ±90° into
  vertical orientation with '0' rotation.
------------------------------------------------------------------------------]]
function Straighten.calculateStraightenAngle(rollAngle)
    if not rollAngle then return nil end
    -- Normalize to range [-180, 180)
    rollAngle = ((rollAngle + 180) % 360) - 180
    -- Find nearest multiple of 90°
    local baseOrientation = math.floor((rollAngle / 90) + 0.5) * 90
    -- Compute residual correction
    if prefs.straightenApplyBias then
      return baseOrientation - rollAngle + prefs.straightenBias
    else
      return baseOrientation - rollAngle
    end
  end

--[[----------------------------------------------------------------------------
  public int rollAngle, int result, string message
  getRollAngleCW(table photo, table metadata)

  Retrieve the 'RollAngle' tag from the photo's metadata and return its value
  in clockwise (CW) degrees. Some camera makers record the camera roll angle
  clockwise (CW), while others record it counterclockwise (CCW).

  Return values:
  1. normalized roll angle value
  2. result of operation (Straighten.SUCCESS/WARNING/ERROR)
  3. message what went wrong if not SUCCESS
------------------------------------------------------------------------------]]
function Straighten.getRollAngleCW(photo, metadata)

  local make = photo:getFormattedMetadata("cameraMake")
  local rollAngleValue, rollAngle, rc

  -- Is there any usable metadata in the photo?
  if not make then
    return 0, Straighten.WARNING, string.format("No metadata available", make)
  end

  local lowerMake = string.lower(make)
  if not makeSupported(lowerMake) then
    return 0, Straighten.WARNING, string.format("%s not supported", make)
  else
    -- Try to retrieve roll angle information from metadata (in memory or on disk)
    if metadata then
      rollAngleValue = ExifUtils.findValue(metadata, "Roll Angle")
    else
      rollAngleValue, rc = ExifUtils.getBinaryValue(photo, "RollAngle")
      if rc ~= 0 then
        return 0, Straighten.ERROR, "Unable to read metadata (ExifTool rc=" .. rc .. ")"
      end
    end

    -- Normalize roll angle information
    if rollAngleValue then
      rollAngle = tonumber(rollAngleValue)
      if rollAngle then
        if  lowerMake == 'fujifilm' or (string.find(lowerMake, "nikon", 1, true)) then
          -- makes that record angle value clockwise
          rollAngle = rollAngle *  1
        else
          -- makes that record angle value counterclockwise
          rollAngle = rollAngle * -1
        end
        return rollAngle, Straighten.SUCCESS, string.format("RollAngle %7.2f°. ", rollAngle)
      else
        return 0, Straighten.WARNING, string.format(
          "Invalid RollAngle information found in metadata: %s", rollAngleValue)
      end
    else
      return 0, Straighten.WARNING, "RollAngle information not available"
    end
  end
end


--[[----------------------------------------------------------------------------
  public boolean
  straightenImage(table photo, float angle, string text)

  Straightens the photo by applying the given angle.
  This action will be recorded as step 'text' in the History panel.
  Returns whether the operation was successful or not.
------------------------------------------------------------------------------]]
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

--[[----------------------------------------------------------------------------
  public boolean
  hasTransform(LrPhoto photo)

  Returns whether an Upright or Transform operation has been performed on the photo
------------------------------------------------------------------------------]]
function Straighten.hasTransform(photo)
  local settings = photo:getDevelopSettings()
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

--[[----------------------------------------------------------------------------
  public table
  getTransformSettings(LrPhoto photo)

  Get Transform settings for the photo
------------------------------------------------------------------------------]]
function Straighten.getTransformSettings(photo)
  local settings = photo:getDevelopSettings()
  local transformSettings = {}

  transformSettings.PerspectiveUpright    = settings.PerspectiveUpright
  transformSettings.PerspectiveVertical   = settings.PerspectiveVertical
  transformSettings.PerspectiveHorizontal = settings.PerspectiveHorizontal
  transformSettings.PerspectiveRotate     = settings.PerspectiveRotate
  transformSettings.PerspectiveAspect     = settings.PerspectiveAspect
  transformSettings.PerspectiveScale      = settings.PerspectiveScale
  transformSettings.PerspectiveX          = settings.PerspectiveX
  transformSettings.PerspectiveY          = settings.PerspectiveY

  return transformSettings
end

--[[----------------------------------------------------------------------------
  public table
  applyTransformSettings(LrPhoto photo, table settings)

  Apply Transform settings to the photo
------------------------------------------------------------------------------]]
function Straighten.applyTransformSettings(photo, settings, title)
  local transformSettings = {}

  transformSettings.PerspectiveUpright    = settings.PerspectiveUpright
  transformSettings.PerspectiveVertical   = settings.PerspectiveVertical
  transformSettings.PerspectiveHorizontal = settings.PerspectiveHorizontal
  transformSettings.PerspectiveRotate     = settings.PerspectiveRotate
  transformSettings.PerspectiveAspect     = settings.PerspectiveAspect
  transformSettings.PerspectiveScale      = settings.PerspectiveScale
  transformSettings.PerspectiveX          = settings.PerspectiveX
  transformSettings.PerspectiveY          = settings.PerspectiveY

  photo:applyDevelopSettings(transformSettings, title)

end





return Straighten
