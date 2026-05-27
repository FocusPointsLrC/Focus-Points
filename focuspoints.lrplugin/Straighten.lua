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
  Entry point for 'Straighten Image' menu command.
  Main control of data processing and user dialog.
------------------------------------------------------------------------------]]
local Straighten = {}

-- Imported LR namespaces
local LrApplication         = import  'LrApplication'
local LrColor               = import  'LrColor'
local LrDialogs             = import  'LrDialogs'
local LrPrefs               = import  'LrPrefs'
local LrProgressScope       = import  'LrProgressScope'
local LrTasks               = import  'LrTasks'
local LrView                = import  'LrView'

-- Required Lua definitions
local Crop                  = require 'Crop'
local ExifUtils             = require 'ExifUtils'
local FocusPointPrefs       = require 'FocusPointPrefs'
local Log                   = require 'Log'
local Utils                 = require 'Utils'
local _strict               = require 'strict'

-- List of camera makers that in principle support a RollAngle tag with consistent information
-- Some only for recent models e.g. Nikon, others since decades e.g. Canon, Olympus/OM
local supportedMakes = {
  'canon', 'nikon', 'nikon corporation', 'fujifilm', 'olympus', 'om digital solutions',
  'pentax', 'ricoh', 'panasonic'
}

--[[----------------------------------------------------------------------------
  private void
  straightenImages

  Invoked when 'Focus Point Viewer -> Straighten Images' is selected.
  Reads the 'RollAngle' tag from the selected photo's metadata
  and applies an according correction via Lightroom's CropAngle setting
------------------------------------------------------------------------------]]
local function straightenImages()

  local catalog = LrApplication.activeCatalog()
  local prefs   = LrPrefs.prefsForPlugin( nil )

  -- Return codes for 'getRollAngle' task
  local SUCCESS = 0
  local WARNING = 1
  local ERROR   = 2

  local stats = {
    processed = 0,
    corrected = 0,
    noactreq  = 0,
    skipped   = 0,
    warnings  = 0,
    errors    = 0,
  }

  local function showSummaryDialog(message, severity, logFileName)

    local f = LrView.osFactory()

    local function summaryMessage(severity)
      -- Construct summary message
      if severity == "critical" then
        return f:static_text {
          title = "Straightening completed with errors",
          font = "<system/bold>",
          text_color = LrColor("red")
        }
      elseif severity == "warning" then
        return f:static_text {
          title = "Straightening completed with warnings",
          font = "<system/bold>",
          text_color = LrColor("orange")
        }
      else
        return f:static_text {
          title = "Straightening completed, some images were skipped",
          font = "<system/bold>",
          text_color = LrColor("blue")
        }
      end
    end

    -- Bring up the dialog window to display summary information
    local result = LrDialogs.presentModalDialog{
      title = "Straighten Images",
      contents = f:column {
        spacing = f:control_spacing(),
        summaryMessage(severity),
        f:static_text {
          title = message,
          width_in_chars = 40,
          height_in_lines = 6,
        },
      },
      actionVerb = "See details",
      cancelVerb = "Close",
    }

    -- 'ok' corresponds to 'See details' -> open the log file
    if result == "ok" then
        Utils.openFileInApp(logFileName)
    end
  end

  local function showSummary(stats, logFileName)
    -- Determine severity and compose details message
    local message = string.format(
      "%d photos processed\n%d straightened\n%d no action required\n%d skipped",
        stats.processed,
        stats.corrected,
      stats.noactreq,
        stats.skipped
    )
    local severity = "info"
    if stats.errors > 0 then
      message = message .. string.format(
        "\n\n%d error(s), %d warning(s) occurred.", stats.errors, stats.warnings)
      severity = "critical"
    elseif stats.warnings > 0 then
      message = message .. string.format(
        "\n\n%d warning(s) occurred.", stats.warnings)
      severity = "warning"
    end

    -- Depending on the user setting, bring up summary dialog with details or just a plain 'completed' message
    local cond = prefs.straightenSummaryCondition
    if (cond == 'ALWAYS')
    or (cond == 'SKIPPED'  and (stats.skipped  > 0 or stats.warnings > 0 or stats.errors > 0))
    or (cond == 'WARNINGS' and (stats.warnings > 0 or stats.errors   > 0))
    or (cond == 'ERRORS'   and (stats.errors   > 0)) then
      showSummaryDialog(message, severity, logFileName)
    else
      LrDialogs.showBezel("Straightening completed")
    end
  end

  local function makeSupported(make)
    -- Check whether 'make' is listed in 'supportedMakes"
    for _, m in ipairs(supportedMakes) do
      if (m == make) then
        return true
      end
    end
    return false
  end

  local function calculateStraightenAngle(rollAngle)
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

  local function getRollAngleCW(photo)
    -- Retrieve the 'RollAngle' tag from the photo's metadata and return its value in clockwise (CW) degrees.
    -- Some camera makers record the camera roll angle clockwise (CW), while others record it counterclockwise (CCW).
    local make = photo:getFormattedMetadata("cameraMake")

    if not makeSupported(string.lower(make)) then
      return 0, WARNING, string.format("%s not supported", make)
    else
      local result, rc = ExifUtils.getBinaryValue(photo, "RollAngle")
      if rc == 0 then
        if result then
          local rollAngle = tonumber(result)
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
              "Invalid RollAngle information found in metadata: %s", result)
          end
        else
          return 0, WARNING, "No RollAngle information found in metadata"
        end
      else
        return 0, ERROR, "Unable to read metadata (ExifTool rc=" .. rc .. ")"
      end
    end
  end

  local function straightenImage(photo, angle)
    local crop = Crop.ofPhoto(photo)
    if crop then
      crop = Crop.adjustAngle (crop, angle)
    catalog:withWriteAccessDo("Straighten Images", function()
        Crop.apply (crop, photo, "Straighten Image")
    end)
      return true
    else
      return false
    end
  end

  local function hasTransform(settings)
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
  local function floatsEqual(a, b, epsilon)
    epsilon = epsilon or 1e-4
    return math.abs(a - b) < epsilon
  end
  -- Get selected photos
  local selectedPhotos = catalog:getTargetPhotos()

  -- To avoid nil pointer errors in case of "dirty" installation (copy new over old files)
  FocusPointPrefs.InitializePrefs(prefs)

  -- Initialize logging, log system level information
  Log.initialize()

  -- Get logging ready
  Log.logInfo("Straighten", string.rep("=", 72))
  Log.resetErrorsWarnings()

  -- Initialize Lightroom's progress bar
  local progress = LrProgressScope {
    title = "Straightening photos...",
    caption = "Preparing...",
  }
  progress:setCancelable(true)

  -- Process all selected photos
  for i, photo in ipairs(selectedPhotos) do

    -- Stop on cancellation
    if progress:isCanceled() then
        progress:done()
        return
    end

    -- Update progress bar
    progress:setPortionComplete(i - 1, #selectedPhotos)
    progress:setCaption(string.format("Processing %d of %d", i, #selectedPhotos))

    -- Proceed to next photo
    local filename = photo:getFormattedMetadata( "fileName" )
    local fileInfo = filename .. ":  " .. string.rep(" ", 20 - #filename)
    stats.processed = stats.processed + 1

    -- Retrieve existing crop angle of photo
    local settings = photo:getDevelopSettings()
    local cropAngle = settings.CropAngle or 0
    local photoTransformed = hasTransform(settings)

    -- Retrieve RollAngle information from metadata, normalize and apply correction
    local rollAngle, status, message = getRollAngleCW(photo)
    repeat  -- until true to support implementation of 'Pythonic' control flow with break statements
      if status == WARNING then
        Log.logWarn("Straighten", fileInfo .. message)
        stats.warnings = stats.warnings + 1
        break
      end
      if status == ERROR then
        Log.logError("Straighten", fileInfo .. message)
        stats.errors = stats.errors + 1
        break
      end
      -- status == SUCCESS
      local rollInfo = message
      local straightenAngle = calculateStraightenAngle(rollAngle)
      local straightenInfo = string.format("Straightening correction of %6.2f°", straightenAngle)

      if straightenAngle == 0 then
        Log.logInfo("Straighten", fileInfo .. rollInfo ..
          "Nothing to do")
        stats.noactreq = stats.noactreq + 1
        break
              end
      if floatsEqual(cropAngle, -straightenAngle) then
        Log.logInfo("Straighten", fileInfo .. rollInfo .. straightenInfo ..
          " not applied (photo already straightened)")
        stats.noactreq = stats.noactreq + 1
        break
              end

      if photoTransformed then
        Log.logInfo("Straighten", fileInfo .. rollInfo .. straightenInfo ..
          " not applied (Transform applied already)")
            stats.skipped = stats.skipped + 1
        break
          end

      if cropAngle ~= 0 and not prefs.overwriteCropAngle then
        Log.logInfo("Straighten", fileInfo .. rollInfo .. straightenInfo ..
          " not applied (non-zero crop angle exists)")
          stats.skipped = stats.skipped + 1
        break
        end

      if prefs.straightenLimits and
        ((math.abs(straightenAngle) < prefs.straightenLimitLow) or
         (math.abs(straightenAngle) > prefs.straightenLimitHigh)) then
        Log.logInfo("Straighten", fileInfo .. rollInfo .. straightenInfo ..
          " not applied (value exceeds user-defined limits)")
          stats.skipped = stats.skipped + 1
        break
        end

      if cropAngle ~= 0 then
        -- Reset existing crop before "overwriting" crop angle
        catalog:withWriteAccessDo("Straighten Images", function()
          Crop.photoReset(photo)
        end)
      end

      -- All preconditions have been met, so apply the crop finally !!
      if straightenImage(photo, straightenAngle) then
        Log.logInfo("Straighten", fileInfo .. rollInfo .. straightenInfo ..
          " applied")
        stats.corrected = stats.corrected + 1
      else
        Log.logError("Straighten", fileInfo .. rollInfo .. straightenInfo ..
          " could not be applied (error occured)")
      stats.errors = stats.errors + 1
    end

    until true
  end

  -- Finish progress bar
  progress:setPortionComplete(#selectedPhotos, #selectedPhotos)
  progress:done()

  -- Display summary
  showSummary(stats, Log.getLogFileName())

end

LrTasks.startAsyncTask( straightenImages )

return Straighten
