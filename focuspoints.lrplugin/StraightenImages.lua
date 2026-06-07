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
  StraightenImages.lua

  Purpose of this module:
  Entry point for 'Straighten Image' menu command.
  Main control of data processing and user dialog.
------------------------------------------------------------------------------]]
local StraightenImages = {}

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
local FocusPointPrefs       = require 'FocusPointPrefs'
local Log                   = require 'Log'
local Utils                 = require 'Utils'
local Straighten            = require 'Straighten'

local prefs   = LrPrefs.prefsForPlugin( nil )

--[[----------------------------------------------------------------------------
  private void
  straightenImages

  Invoked when 'Focus Point Viewer -> Straighten Images' is selected.
  Reads the 'RollAngle' tag from the selected photo's metadata
  and applies an according correction via Lightroom's CropAngle setting
------------------------------------------------------------------------------]]
local function straightenImages()

  local catalog = LrApplication.activeCatalog()

  local stats = {
    processed = 0,
    corrected = 0,
    noactreq  = 0,
    skipped   = 0,
    warnings  = 0,
    errors    = 0,
  }

  -- Return codes for 'getRollAngle' task
  local WARNING = 1
  local ERROR   = 2


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
    local photoTransformed = Straighten.hasTransform(settings)

    -- Retrieve RollAngle information from metadata, normalize and apply correction
    local rollAngle, status, message = Straighten.getRollAngleCW(photo)

    repeat  -- until true to support implementation of 'Pythonic' control flow with break statements

      if status == 1 then   -- WARNING occured
        Log.logWarn("Straighten", fileInfo .. message)
        stats.warnings = stats.warnings + 1
        break
      end

      if status == 2 then   -- ERROR occured
        Log.logError("Straighten", fileInfo .. message)
        stats.errors = stats.errors + 1
        break
      end

      -- status == 0           SUCCESS
      local rollInfo = message
      local straightenAngle = Straighten.calculateStraightenAngle(rollAngle)
      local straightenInfo = string.format("Straightening correction of %6.2f°", straightenAngle)

      if straightenAngle == 0 then
        Log.logInfo("Straighten", fileInfo .. rollInfo ..
          "Nothing to do")
        stats.noactreq = stats.noactreq + 1
        break
      end

      if Utils.floatsEqual(cropAngle, -straightenAngle) then
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
      if Straighten.straightenImage(photo, straightenAngle) then
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

return StraightenImages
